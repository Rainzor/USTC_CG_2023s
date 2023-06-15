#define _CRT_SECURE_NO_WARNINGS
#define _SCL_SECURE_NO_WARNINGS

#define FREEGLUT_STATIC
#include "gl_core_3_3.h"
#include <GL/glut.h>
#include <GL/freeglut_ext.h>

#define TW_STATIC
#include <AntTweakBar.h>
#include <windows.h>
#include <commdlg.h>

#include <ctime>
#include <memory>
#include <vector>
#include <string>
#include <cstdlib>
#include <iostream>

#include "objloader.h"
#include "glprogram.h"
#include "MyImage.h"
#include "VAOImage.h"
#include "VAOMesh.h"
#include "trackball.h"

#include "laplacian.h"

#include "matlab_utils.h"


GLProgram MyMesh::prog, MyMesh::pickProg, MyMesh::pointSetProg;
GLTexture MyMesh::colormapTex;

MyMesh M;

//添加图形类
MyImage img(std::string("bricks2.png"), 4);


int viewport[4] = { 0, 0, 1280, 960 };
int actPrimType = MyMesh::PE_VERTEX;
std::vector<float> x;
std::vector<int> f;
std::vector<float> uv;
bool showATB = true;
bool isCot = false;
enum Mode {
    Uniform,Cotangent
}mode;
bool isPerceptive = true;
using MatX3f = Eigen::Matrix<float, Eigen::Dynamic, 3, Eigen::RowMajor>;
using MatX3i = Eigen::Matrix<int, Eigen::Dynamic, 3, Eigen::RowMajor>;
MatX3f meshX;
MatX3i meshF;
void textureMapping() {
    using namespace Eigen;

    //运行matlab脚本
    matlabEval("parameterization;");   // TODO: finish the script

    Matrix<float, Dynamic, Dynamic, RowMajor> uv_mat;
    matlab2eigen("single(uv)", uv_mat, true);
    int c = uv_mat.cols();
    int r = uv_mat.rows();
    uv.resize(c*r);
    for (int i = 0; i < r; i++) {
        for (int j = 0; j < c; j++)
			uv[i*c + j] = uv_mat(i, j)*4;//利用重复映射模式，让贴图显式更加密集
	}

    M.upload(x.data(), x.size() / 3, f.data(), f.size() / 3, uv.data());
    M.tex.setImage(img);//filepath 要和exe文件搭配好，否则可能无法运行
}




void deform_preprocess()
{
    eigen2matlab("x", meshX.cast<double>());
    eigen2matlab("t", (meshF.array()+1).cast<double>().matrix());
    if (isCot == false) {
        scalar2matlab("isCot", double(0));
        std::cout << "Uniform Weight\n";
    }
    else {
        scalar2matlab("isCot", double(1));
        std::cout << "Cotangent Weight\n";
    }
}

void meshDeform()
{
    using namespace Eigen;

    std::vector<int> P2PVtxIds = M.getConstrainVertexIds();
    std::vector<float> p2pDsts = M.getConstrainVertexCoords();

    vector2matlab("P2PVtxIds", P2PVtxIds);
    eigen2matlab("p2pDsts", Map<MatX3f>(p2pDsts.data(), P2PVtxIds.size(), 3));
    matlabEval("P2PVtxIds = double(P2PVtxIds+1);");   // change index to matlab 1-based
    matlabEval("laplacian_mesh_editing;");   // run deformation script, TODO: finish the script

    Matrix<float, Dynamic, Dynamic, RowMajor> y;
    matlab2eigen("single(y)", y, true);
    if (y.cols() > 3)  y = y.leftCols(3);
    if (y.rows() == 0 || y.cols() != 3) return;

    M.upload(y.data(), y.rows(), nullptr, 0, nullptr);
}

int mousePressButton;
int mouseButtonDown;
int mousePos[2];
bool msaa = true;
using vec4 = Eigen::Vector4d;
float myRotation[4] = {1, 0, 0, 0}; //BONUS: interactively specify the rotation for the Laplacian coordinates at the handles

void display()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    if (msaa) glEnable(GL_MULTISAMPLE);
    else glDisable(GL_MULTISAMPLE);

    glViewport(0, 0, viewport[2], viewport[3]);
    M.draw(viewport,isPerceptive);

    if (showATB) TwDraw();
    glutSwapBuffers();

    //glFinish();
}

void onKeyboard(unsigned char code, int x, int y)
{
    if (!TwEventKeyboardGLUT(code, x, y)) {
        switch (code) {
        case 17:
            exit(0);
        case 'f':
            glutFullScreenToggle();
            break;
        case ' ':
            showATB = !showATB;
            break;
        }
    }

    glutPostRedisplay();
}

void onMouseButton(int button, int updown, int x, int y)
{
    if (!showATB || !TwEventMouseButtonGLUT(button, updown, x, y)) {
        mousePressButton = button;
        mouseButtonDown = updown;

        if (updown == GLUT_DOWN) {
            if (button == GLUT_LEFT_BUTTON) {
                if (glutGetModifiers()&GLUT_ACTIVE_CTRL) {
                }
                else {
                    int r = M.pick(x, y, viewport, M.PE_VERTEX, M.PO_ADD);
                }
            }
            else if (button == GLUT_RIGHT_BUTTON) {
                M.pick(x, y, viewport, M.PE_VERTEX, M.PO_REMOVE);
            }
        }
        else { // updown == GLUT_UP
            if (button == GLUT_LEFT_BUTTON);
        }

        mousePos[0] = x;
        mousePos[1] = y;
    }

    glutPostRedisplay();
}


void onMouseMove(int x, int y)
{
    if (!showATB || !TwEventMouseMotionGLUT(x, y)) {
        if (mouseButtonDown == GLUT_DOWN) {
            if (mousePressButton == GLUT_MIDDLE_BUTTON) {
                M.moveInScreen(mousePos[0], mousePos[1], x, y, viewport);
            }
            else if (mousePressButton == GLUT_LEFT_BUTTON) {
                if (!M.moveCurrentVertex(x, y, viewport)) {
                    meshDeform();
                }
                else {
                    const float s[2] = { 2.f / viewport[2], 2.f / viewport[3] };
                    auto r = Quat<float>(M.mQRotate)*Quat<float>::trackball(x*s[0] - 1, 1 - y*s[1], s[0]*mousePos[0] - 1, 1 - s[1]*mousePos[1]);
                    std::copy_n(r.q, 4, M.mQRotate);
                }
            }
        }
    }

    mousePos[0] = x; mousePos[1] = y;

    glutPostRedisplay();
}


void onMouseWheel(int wheel_number, int direction, int x, int y)
{
    M.mMeshScale *= direction > 0 ? 1.1f : 0.9f;
    glutPostRedisplay();
}

int initGL(int argc, char **argv)
{
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_MULTISAMPLE);
    glutInitWindowSize(960, 960);
    glutInitWindowPosition(200, 50);
    glutCreateWindow(argv[0]);

    // !Load the OpenGL functions. after the opengl context has been created
    if (ogl_LoadFunctions() == ogl_LOAD_FAILED)
        return -1;

    glClearColor(1.f, 1.f, 1.f, 0.f);

    glutReshapeFunc([](int w, int h) { viewport[2] = w; viewport[3] = h; TwWindowSize(w, h); });
    glutDisplayFunc(display);
    glutKeyboardFunc(onKeyboard);
    glutMouseFunc(onMouseButton);
    glutMotionFunc(onMouseMove);
    glutMouseWheelFunc(onMouseWheel);
    glutCloseFunc([]() {exit(0); });
    return 0;
}


void createTweakbar() {
    TwBar* bar = TwGetBarByName("MeshViewer");
    //TwBar* texturebar = TwGetBarByName("Texture");
    if (bar)    TwDeleteBar(bar);

    //Create a tweak bar
    bar = TwNewBar("MeshViewer");
    //texturebar = TwNewBar("Texture");

    TwDefine(" MeshViewer size='220 180' color='0 128 255' text=dark alpha=128 position='5 5'"); // change default tweak bar size and color
    //TwDefine(" Bonus size='220 150' color='128 0 255' text=dark alpha=128 position='5 250'");

    TwAddButton(
        bar, "Change mode", [](void* a) {
            isCot = !isCot;
            deform_preprocess();
            textureMapping();
            //meshDeform();
        },
        &isCot, "");



    TwAddVarRO(bar, "#Vertex", TW_TYPE_INT32, &M.nVertex, " group='Mesh View'");
    TwAddVarRO(bar, "#Face", TW_TYPE_INT32, &M.nFace, " group='Mesh View'");

    TwAddVarRW(bar, "Point Size", TW_TYPE_FLOAT, &M.pointSize, " group='Mesh View' ");
    TwAddVarRW(bar, "Vertex Color", TW_TYPE_COLOR4F, M.vertexColor.data(), " group='Mesh View' help='mesh vertex color' ");


    TwAddVarRW(bar, "Edge Width", TW_TYPE_FLOAT, &M.edgeWidth, " group='Mesh View' ");
    TwAddVarRW(bar, "Edge Color", TW_TYPE_COLOR4F, M.edgeColor.data(), " group='Mesh View' help='mesh edge color' ");

    TwAddVarRW(bar, "Face Color", TW_TYPE_COLOR4F, M.faceColor.data(), " group='Mesh View' help='mesh face color' ");

    TwDefine(" MeshViewer/'Mesh View' opened=false ");

    //TwAddVarRW(bonusbar, "Rotation", TW_TYPE_QUAT4F, myRotation, " group='Modeling' open help='can be used to specify the rotation for current handle' ");
    //TwAddButton(
    //    bonusbar, "Update", [](void* a) {
    //        meshDeform();
    //    },
    //    &isCot, "");
    TwAddButton(
        bar, "Texture Mapping", [](void* a) {
            M.showTexture = !M.showTexture;
        },
        nullptr, "group='Texture'");
    TwAddButton(
        bar, "Project Mode", [](void* a) {
            isPerceptive = !isPerceptive;
            M.draw(viewport, isPerceptive);
            if (isPerceptive)
                printf("Projection label=Perceptive\n");
			else
                printf("Projection label=Orthographic\n");
        },
        nullptr, "group='Project'");
    TwAddButton(
        bar, "Load OBJ", [](void* a) {
            // Open file dialog box to let user choose a file
            OPENFILENAMEA ofn;
            char szFile[MAX_PATH] = { 0 };
            ZeroMemory(&ofn, sizeof(ofn));
            ofn.lStructSize = sizeof(ofn);
            ofn.hwndOwner = NULL;
            ofn.lpstrFilter = "OBJ Files (*.obj)\0*.obj\0All Files (*.*)\0*.*\0";
            ofn.lpstrFile = szFile;
            ofn.nMaxFile = sizeof(szFile);
            ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
            ofn.lpstrDefExt = "obj";
            if (GetOpenFileNameA(&ofn)) {
                // Load OBJ file and update the mesh
                x.clear();
                f.clear();
                readObj(ofn.lpstrFile, x, f);
                meshX = Eigen::Map<MatX3f>(x.data(), x.size() / 3, 3);
                meshF = Eigen::Map<MatX3i>(f.data(), f.size() / 3, 3);

                M.upload(x.data(), x.size() / 3, f.data(), f.size() / 3, nullptr);
                deform_preprocess();
                meshDeform();
            }
        },
        nullptr, " group='File' ");
}

int main(int argc, char *argv[])
{
    if (initGL(argc, argv)) {
        fprintf(stderr, "!Failed to initialize OpenGL!Exit...");
        exit(-1);
    }

    MyMesh::buildShaders();

    const char* meshpath = argc > 1 ? argv[1] : "cube.obj";
    readObj(meshpath, x, f);

    meshX = Eigen::Map<MatX3f>(x.data(), x.size() / 3, 3);
    meshF = Eigen::Map<MatX3i>(f.data(), f.size() / 3, 3);

    //M.upload(x.data(), x.size() / 3, f.data(), f.size() / 3, nullptr);

    //////////////////////////////////////////////////////////////////////////
    TwInit(TW_OPENGL_CORE, NULL);
    //Send 'glutGetModifers' function pointer to AntTweakBar;
    //required because the GLUT key event functions do not report key modifiers states.
    TwGLUTModifiersFunc(glutGetModifiers);
    glutSpecialFunc([](int key, int x, int y) { TwEventSpecialGLUT(key, x, y); glutPostRedisplay(); }); // important for special keys like UP/DOWN/LEFT/RIGHT ...
    TwCopyStdStringToClientFunc([](std::string& dst, const std::string& src) {dst = src; });

    createTweakbar();

    //////////////////////////////////////////////////////////////////////////
    atexit([] { TwDeleteAllBars();  TwTerminate(); }); 

    glutTimerFunc(1, [](int) {
        getMatEngine().connect(" "); 
        deform_preprocess();
        textureMapping();
        M.showTexture = false;
    }, 
        0);


    //////////////////////////////////////////////////////////////////////////
    glutMainLoop();

    return 0;
}

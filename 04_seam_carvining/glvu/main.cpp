//   Copyright © 2021, Renjie Chen @ USTC

#define _CRT_SECURE_NO_WARNINGS
#define _SCL_SECURE_NO_WARNINGS

#define FREEGLUT_STATIC
#include "gl_core_3_3.h"
#include <GL/glut.h>
#include <GL/freeglut_ext.h>

#define TW_STATIC
#include <AntTweakBar.h>

#include <vector>
#include <string>
#include <iostream>
#include "glprogram.h"
#include "MyImage.h"
#include "VAOImage.h"
#include "VAOMesh.h"


GLProgram MyMesh::prog;

MyMesh M;
int viewport[4] = { 0, 0, 1280, 960 };

bool showATB = true;

std::string imagefile = "boy.png";
std::string saliencyfile = "boy_saliency.png";
std::string localglobalfile = "local_global.png";

MyImage img;
int resize_width, resize_height;

int mousePressButton;
int mouseButtonDown;
int mousePos[2];
bool show;

enum SeamCarvingType { GIVEN,
                       L1NORM,
                       LOCALGLOBAL };
SeamCarvingType type = GIVEN;

void display()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glViewport(0, 0, viewport[2], viewport[3]);
    M.draw(viewport);

    if (showATB) TwDraw();
    glutSwapBuffers();
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
        }
    }

    mousePos[0] = x; mousePos[1] = y;

    glutPostRedisplay();
}


void onMouseWheel(int wheel_number, int direction, int x, int y)
{
    if (glutGetModifiers() & GLUT_ACTIVE_CTRL) {
    }
    else
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

void uploadImage(const MyImage& img)
{
    int w = img.width();
    int h = img.height();
    float x[] = { 0, 0, 0, w, 0, 0, w, h, 0, 0, h, 0 };
    M.upload(x, 4, nullptr, 0, nullptr);

    M.tex.setImage(img);
    M.tex.setClamping(GL_CLAMP_TO_EDGE);
}


void readImage(const std::string& file)
{
    int w0 = img.width(), h0 = img.height();
    img = MyImage(file);
    uploadImage(img);
    resize_width = img.width();
    resize_height = img.height();

    if (w0 != img.width() || h0 != img.height()) M.updateBBox();
}




MyImage seamCarving(const MyImage& img, int w, int h,bool show=false)
{
    // TODO
    int com = img.dim(), wid = img.width(), hei = img.height();

    if(wid==w && hei==h) return img;
    MyImage new_img = img;
    new_img.saliencyInit(Mode::SFile,saliencyfile);
    if (hei == h) {
        new_img.changeWidth(w,show);
    }else if(wid==w){
        new_img.changeHeight(h,show);
    }
    else {
        new_img.changeWidth(w,show);
        new_img.changeHeight(h,show);
    }
    
    return new_img;
    //return img.rescale(w, h);
}

MyImage seamCarvingL1(const MyImage& img, int w, int h, bool show = false) {
    // TODO
    int com = img.dim(), wid = img.width(), hei = img.height();

    if (wid == w && hei == h) return img;
    MyImage new_img = img;
    new_img.saliencyInit(Mode::SL1);
    if (hei == h) {
        new_img.changeWidth(w,show);
    }else if(wid==w){
        new_img.changeHeight(h,show);
    }
    else {
        new_img.changeWidth(w,show);
        new_img.changeHeight(h,show);
    }
    return new_img;
    //return img.rescale(w, h);
}

MyImage seamCarvingLocalGloal(const MyImage& img, int w, int h, bool show = false) {
    // TODO
    int com = img.dim(), wid = img.width(), hei = img.height();

    if (wid == w && hei == h)
        return img;
    MyImage new_img = img;
    new_img.saliencyInit(Mode::SFile, localglobalfile);
    if (hei == h) {
        new_img.changeWidth(w, show);
    } else if (wid == w) {
        new_img.changeHeight(h, show);
    } else {
        new_img.changeWidth(w, show);
        new_img.changeHeight(h, show);
    }
    return new_img;
    // return img.rescale(w, h);
}

void createTweakbar()
{
    //Create a tweak bar
    TwBar *bar = TwNewBar("Image Viewer");
    TwDefine(" 'Image Viewer' size='250 180' color='0 128 255' text=dark alpha=128 position='5 5'"); // change default tweak bar size and color

    TwAddVarRW(bar, "Scale", TW_TYPE_FLOAT, &M.mMeshScale, " min=0 step=0.1");

    TwAddVarRW(bar, "Image filename", TW_TYPE_STDSTRING, &imagefile, " ");//图像文件名输入框
    TwAddButton(bar, "Read Image", [](void*) { readImage(imagefile); show=false;}, nullptr, "");//读取图像的按钮

    TwAddVarRW(bar, "Resize Width", TW_TYPE_INT32, &resize_width, "group='Seam Carving' min=1 ");//输入修改图像的宽度
    TwAddVarRW(bar, "Resize Height", TW_TYPE_INT32, &resize_height, "group='Seam Carving' min=1 ");//输入修改图像的高度

    TwAddVarRW(bar, "Show Path", TW_TYPE_BOOLCPP, &show, "");  // 增加一个类似于click的选项，来控制变量show的布尔值


    TwEnumVal types[] = {{GIVEN, "Given img"}, {L1NORM, "L1 Norm"}, {LOCALGLOBAL, "Local Global"}};
    TwType typeEnum = TwDefineEnum("SeamCarvingType", types, 3);
    TwAddVarRW(bar, "Seam Carving Type", typeEnum, &type, "");

    TwAddButton(
        bar, "Run Seam Carving", [](void* img) {  // 匿名函数，只能是一个参数且是void*
            MyImage newimg;
            switch (type) {
                case GIVEN:
                    newimg = seamCarving(*(const MyImage*)img, resize_width, resize_height, show);
                    break;
                case L1NORM:
                    newimg = seamCarvingL1(*(const MyImage*)img, resize_width, resize_height,show);
                    break;
                case LOCALGLOBAL:
                    newimg = seamCarvingLocalGloal(*(const MyImage*)img, resize_width, resize_height,show);
                    break;
            }
            uploadImage(newimg);  // 上传图像改变图像格式
        },
        &img, "");

    /*TwAddButton(bar, "Run Seam Carving by Given img", [](void* img) {//匿名函数，只能是一个参数且是void*
        MyImage newimg = seamCarving(*(const MyImage*)img, resize_width, resize_height,show);//调用seamCarving函数，修改图像
        uploadImage(newimg);//上传图像改变图像格式
        }, 
        &img, "");
    TwAddButton(bar, "Run Seam Carving by L1 Norm", [](void* img) {
        MyImage newimg = seamCarvingL1(*(const MyImage*)img, resize_width, resize_height);
        uploadImage(newimg);//上传图像改变图像格式
        },
        &img, "");
    TwAddButton(bar, "Run Seam Carving by LocalGloal", [](void* img) {
        MyImage newimg = seamCarvingLocalGloal(*(const MyImage*)img, resize_width, resize_height);
        uploadImage(newimg);//上传图像改变图像格式
        },
        &img, "");
    */
}


int main(int argc, char *argv[])
{
    SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE), { 100, 5000 });

    if (initGL(argc, argv)) {
        fprintf(stderr, "!Failed to initialize OpenGL!Exit...");
        exit(-1);
    }

    MyMesh::buildShaders();


    float x[] = { 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0 };
    float uv[] = { 0, 0, 1, 0, 1, 1, 0, 1 };
    int t[] = { 0, 1, 2, 2, 3, 0 };

    M.upload(x, 4, t, 2, uv);

    //-----------------------------------------------------------------------------------
    TwInit(TW_OPENGL_CORE, NULL);
    //Send 'glutGetModifers' function pointer to AntTweakBar;
    //required because the GLUT key event functions do not report key modifiers states.
    TwGLUTModifiersFunc(glutGetModifiers);
    glutSpecialFunc([](int key, int x, int y) { TwEventSpecialGLUT(key, x, y); glutPostRedisplay(); }); // important for special keys like UP/DOWN/LEFT/RIGHT ...
    TwCopyStdStringToClientFunc([](std::string& dst, const std::string& src) {dst = src; });


    createTweakbar();//初始化界面

    //-------------------------------------------------------------------------------
    atexit([] { TwDeleteAllBars();  TwTerminate(); });  // Called after glutMainLoop ends

    glutTimerFunc(1, [](int) { readImage(imagefile); },  0);//调用readImage函数，读取图片


    //////////////////////////////////////////////////////////////////////////
    glutMainLoop();

    return 0;
}


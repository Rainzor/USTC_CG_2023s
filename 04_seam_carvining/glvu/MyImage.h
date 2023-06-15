//   Copyright © 2021, Renjie Chen @ USTC

#pragma once

#include <float.h>
#include <sys/stat.h>
#include <algorithm>
#include <cassert>
#include <string>
#include <vector>
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include <stb_image_resize.h>

//    int x,y,n;
//    unsigned char *data = stbi_load(filename, &x, &y, &n, 0);
//    // ... process data if not NULL ...
//    // ... x = width, y = height, n = # 8-bit components per pixel ...
//    // ... replace '0' with '1'..'4' to force that many components per pixel
//    // ... but 'n' will always be the number that it would have been if you said 0
//    stbi_image_free(data)
using std::vector;
int themin(double x1, double x2, double x3) {
    if (x2 >= 0 && (x1 >= x2 || x1 <= 0)) {
        if (x2 >= x3 && x3 >= 0)
            return 1;
        else
            return 0;
    }
    if (x1 >= x3 && x3 >= 0)
        return 1;
    return -1;
}

enum Mode { SL1,
            SFile };

class MyImage {
   private:
    std::vector<BYTE> pixels;
    vector<vector<double>> salience_map;
    int w, h, comp;

   private:
    // 初始化显著图像：读取已知图像
    void saliencyFileInit(std::string filename) {
        MyImage salience_img(filename);
        salience_map.resize(h);
        for (int k = 0; k < h; k++) {
            salience_map[k].resize(w);
            for (int l = 0; l < w; l++) {
                salience_map[k][l] = salience_img.gray(k, l);
            }
        }
    }
    // 初始化显著图像：按照L1
    void saliencyL1Init() {
        salience_map.clear();
        salience_map.resize(h);
        for (int k = 0; k < h; k++) {
            salience_map[k].resize(w);
            for (int l = 0; l < w; l++) {
                double energy_x = 0;
                double energy_y = 0;
                if (k > 0 && k < h - 1) {
                    energy_x = (gray(k - 1, l) - gray(k + 1, l)) / 2;
                } else if (k == 0) {
                    energy_x = gray(k + 1, l) - gray(k, l);
                } else {
                    energy_x = gray(k, l) - gray(k - 1, l);
                }

                if (l > 0 && l < w - 1) {
                    energy_y = (gray(k, l - 1) - gray(k, l + 1)) / 2;
                } else if (l == 0) {
                    energy_y = gray(k, l + 1) - gray(k, l);
                } else {
                    energy_y = gray(k, l) - gray(k, l - 1);
                }
                salience_map[k][l] = abs(energy_x) + abs(energy_y);
            }
        }
    }

    // 获取所有最优竖直缝隙
    void findPath(vector<vector<int>>& paths, int k = 1, double punish = 50) {
        if (salience_map.empty()) {
            saliencyInit();
        }
        paths.clear();
        vector<vector<int8_t>> direc_map(h);                    // 记录方向
        vector<vector<double>> salience_map_cur(salience_map);  // 记录能量

        for (int i = 0; i < h; i++) {
            direc_map[i].resize(w);
            if (i == 0) {
                for (int j = 0; j < w; j++) {
                    direc_map[i][j] = 0;  // 第一行的方向为0，但不被使用
                }
            }
        }
        for (int l = 0; l < k; l++) {
            // energy 一开始被初始化为 当前salience_map_cur
            vector<vector<double>> energy(salience_map_cur);
            paths.push_back(vector<int>(h));

            for (int i = 1; i < h; i++) {  // 从第二行开始,动态规划
                int index;
                for (int j = 1; j < w - 1; j++) {
                    // 找到上一行最小值的横坐标相对偏移量
                    index = themin(energy[i - 1][j - 1], energy[i - 1][j], energy[i - 1][j + 1]);
                    // 记录路径,即到达该点的上一点的方向
                    direc_map[i][j] = index;
                    energy[i][j] += energy[i - 1][j + index];
                }

                index = themin(DBL_MAX, energy[i - 1][0], energy[i - 1][1]);
                direc_map[i][0] = index;
                energy[i][0] += energy[i - 1][index];

                index = themin(energy[i - 1][w - 2], energy[i - 1][w - 1], DBL_MAX);
                direc_map[i][w - 1] = index;
                energy[i][w - 1] += energy[i - 1][index + w - 1];
            }

            // 找到最后一行最小值的横坐标
            int min_index = 0;
            for (int j = 1; j < w; j++) {
                if (energy[h - 1][j] < energy[h - 1][min_index]) {
                    min_index = j;
                }
            }
            // 建立一条路径并给路径上的显著值加上惩罚，防止路径交叉
            // 路径是从下往上的建立的,path[h-1]是最后一行的横坐标
            for (int i = h - 1; i >= 0; i--) {
                paths[l][i] = min_index;
                salience_map_cur[i][min_index] += punish;
                min_index += direc_map[i][min_index];
            }
        }
    }

    // 减少图像宽度
    void decreaseWidth(int k = 1, bool show = false) {
        vector<vector<int>> paths;
        findPath(paths, k);
        std::vector<int> indices(paths.size());
        int min_index = 0;

        for (int i = 0; i < indices.size(); ++i) {
            indices[i] = i;
        }

        std::sort(indices.begin(), indices.end(),
                  [&](int i, int j) { return paths[i][h - 1] > paths[j][h - 1]; });
        if (show) {
            // 显示路径,不改变图像
            for (int l = 0; l < k; l++) {
                vector<int>& path = paths[indices[l]];
                for (int i = h - 1; i >= 0; i--) {
                    int path_pos = path[i];
                    int pos = comp * (i * w + path_pos);
                    for (int j = 0; j < comp; j++) {
                        pixels[pos + j] = (j == 0 || j == 4) ? 255 - l * 2 : l * 2;
                    }
                }
            }
        } else {
            for (int l = 0; l < k; l++) {
                vector<int>& path = paths[indices[l]];

                for (int i = h - 1; i >= 0; i--) {
                    int path_pos = path[i];
                    int pos = comp * (i * w + path_pos);
                    pixels.erase(pixels.begin() + pos, pixels.begin() + pos + comp);
                    salience_map[i].erase(salience_map[i].begin() + path_pos);
                }
                w--;
            }
        }
    }

    void increaseWidth(int k = 1, bool show = false) {
        vector<vector<int>> paths;
        findPath(paths, k);
        std::vector<int> indices(paths.size());
        int min_index = 0;

        for (int i = 0; i < indices.size(); ++i) {
            indices[i] = i;
        }

        std::sort(indices.begin(), indices.end(),
                  [&](int i, int j) { return paths[i][h - 1] > paths[j][h - 1]; });

        if (show) {
            // 显示路径,不改变图像
            for (int l = 0; l < k; l++) {
                vector<int>& path = paths[indices[l]];
                for (int i = h - 1; i >= 0; i--) {
                    int path_pos = path[i];
                    int pos = comp * (i * w + path_pos);
                    for (int j = 0; j < comp; j++) {
                        pixels[pos + j] = (j == 0 || j == 4) ? 255 - l * 2 : l * 2;
                    }
                }
            }
        } else {
            for (int l = 0; l < k; l++) {
                vector<int>& path = paths[indices[l]];
                for (int i = h - 1; i >= 0; i--) {
                    int path_pos = path[i];
                    int pos = comp * (i * w + path_pos);
                    for (int j = 0; j < comp; j++) {
                        pixels.insert(pixels.begin() + pos + j + comp, pixels[pos + j]);
                        //// 显示路径,且改变图像
                        // BYTE new_pixel = (j == 0 || j == 4) ? 255 : 0;
                        // pixels.insert(pixels.begin() + pos + j, new_pixel);
                    }
                    salience_map[i].insert(salience_map[i].begin() + path_pos, salience_map[i][path_pos]);
                }
                w++;
            }
        }
    }

    // 减少图像高度
    void decreaseHeight(int k = 1, bool show = false) {
        transposeInplace();
        decreaseWidth(k, show);
        transposeInplace();
    }

    // 增加图像高度
    void increaseHeight(int k = 1, bool show = false) {
        transposeInplace();
        increaseWidth(k, show);
        transposeInplace();
    }

   public:
    MyImage()
        : w(0), h(0), comp(0) {}
    ~MyImage() {}

    MyImage(const std::string& filename, int ncomp = 4)
        : w(0), h(0), comp(0) {
        stbi_set_flip_vertically_on_load(true);
        BYTE* data = stbi_load(filename.data(), &w, &h, &comp, ncomp);

        if (data) {
            pixels = std::vector<BYTE>(data, data + w * h * comp);
            stbi_image_free(data);
        } else {
            fprintf(stderr, "failed to load image file %s!\n", filename.c_str());
            struct stat info;
            if (stat(filename.c_str(), &info))
                fprintf(stderr, "file doesn't exist!\n");
        }
    }

    MyImage(BYTE* data, int ww, int hh, int pitch, int ncomp = 3)
        : w(ww), h(hh), comp(ncomp) {
        if (pitch == w * comp)
            pixels = std::vector<BYTE>(data, data + pitch * h);
        else {
            pixels.resize(w * comp * h);
            for (int i = 0; i < h; i++)
                std::copy_n(data + pitch * i, pitch, pixels.data() + i * w * comp);
        }
    }

    static int alignment() { return 1; }  // OpenGL only supports 1,2,4,8, do not use 8, it is buggy

    inline bool empty() const { return pixels.empty(); }

    inline BYTE* data() { return pixels.data(); }
    inline const BYTE* data() const { return pixels.data(); }
    inline int width() const { return w; }
    inline int height() const { return h; }
    inline int dim() const { return comp; }
    inline int pitch() const { return w * comp; }

    // 获取像素值
    void getPixel(BYTE output[], int i, int j, int c = 3) {
        double alpha = 1;
        if (c < 4) {
            if (comp == 4) {
                alpha = pixels[comp * (i * w + j) + 3] / 255;
            }
            for (size_t k = 0; k < c; k++) {
                output[k] = pixels[comp * (i * w + j) + k] * alpha;
            }
        } else {
            for (size_t k = 0; k < c; k++) {
                output[k] = pixels[comp * (i * w + j) + k];
            }
        }
    }

    inline BYTE red(int i, int j) const {
        return pixels[comp * (i * w + j)];
    }

    inline BYTE green(int i, int j) const {
        return pixels[comp * (i * w + j) + 1];
    }

    inline BYTE blue(int i, int j) const {
        return pixels[comp * (i * w + j) + 2];
    }

    inline BYTE alpha(int i, int j) const {
        return comp == 4 ? pixels[comp * (i * w + j) + 3] : 255;
    }

    inline BYTE color(int i, int j, int k) const {
        return k < comp ? pixels[comp * (i * w + j) + k] : 0;
    }

    // 索引
    BYTE& operator()(int i, int j, int k) {
        return pixels[comp * (i * w + j) + k];
    }

    // 获取灰度值
    double gray(int i, int j) {
        BYTE pixel[3];
        double result = 0;
        double alpha = 1;
        if (comp == 4) {
            alpha = pixels[comp * (i * w + j) + 3] / 255;
        }
        for (size_t k = 0; k < 3; k++) {
            result += pixels[comp * (i * w + j) + k] * alpha;
        }
        return result / 3;
    }
    // 默认L1范数形式定义显著图像
    void saliencyInit(Mode m = SL1, std::string filename = "") {
        switch (m) {
            case SFile: {
                if (filename.empty()) {
                    assert(false);
                }
                saliencyFileInit(filename);
                break;
            }
            default: {
                saliencyL1Init();
                break;
            }
        }
    }

    // 图像转置
    void transposeInplace() {
        vector<BYTE> pixels_new(w * h * comp);
        for (int i = 0; i < h; i++) {
            for (int j = 0; j < w; j++) {
                for (int k = 0; k < comp; k++) {
                    pixels_new[comp * (j * h + i) + k] = pixels[comp * (i * w + j) + k];
                }
            }
        }
        pixels = pixels_new;
        if (!salience_map.empty()) {
            vector<vector<double>> salience_map_new(w);
            for (int i = 0; i < w; i++) {
                salience_map_new[i].resize(h);
                for (int j = 0; j < h; j++) {
                    salience_map_new[i][j] = salience_map[j][i];
                }
            }
            salience_map = salience_map_new;
        }
        std::swap(w, h);
    }

    // 改变图像宽度
    void changeWidth(int new_w,bool show = false) {
        if (new_w == w)
            return;
        if (new_w <= 0)
            assert(false);

        if (new_w < w) {
            for (int i = 0; i < w - new_w; i++)
                decreaseWidth(1,show);
        } else if (new_w > w) {
            int increase = new_w - w;
            // for (int i = 0; i < increase; i++)//重影现象
            //     increaseWidth(1, show);
            while (increase > 32) {
                increaseWidth(increase / 4 * 3,show);
                increase = increase - increase / 4 * 3;
            }
            increaseWidth(increase,show);
        }
    }

    // 改变图像高度
    void changeHeight(int new_h,bool show = false) {
        if (new_h == h)
            return;
        if (new_h <= 0)
            assert(false);

        if (new_h < h) {
            for (int i = 0; i < h - new_h; i++)
                decreaseHeight(1, show);
        } else if (new_h > h) {
            int increase = new_h - h;
            while (increase > 32) {
                increaseHeight(increase / 4 * 3, show);
                increase = increase - increase / 4 * 3;
            }
            increaseHeight(increase, show);
        }
    }

    MyImage rescale(int ww, int hh) const {
        std::vector<BYTE> data(ww * comp * hh);
        // 第三方库
        stbir_resize_uint8(pixels.data(), w, h, w * comp,
                           data.data(), ww, hh, ww * comp, comp);

        return MyImage(data.data(), ww, hh, ww * comp, comp);
    }

    MyImage resizeCanvas(int ww, int hh) {
        std::vector<BYTE> data(ww * comp * hh, 255);
        for (int i = 0; i < h; i++)
            std::copy_n(pixels.data() + i * w * comp, w * comp, data.data() + i * ww * comp);

        return MyImage(data.data(), ww, hh, ww * comp, comp);
    }

    inline void write(const std::string& filename, bool vflip = true) const {
        if (filename.size() < 4 || !_strcmpi(filename.data() + filename.size() - 4, ".png")) {
            stbi_write_png(filename.data(), w, h, comp, pixels.data() + (vflip ? w * comp * (h - 1) : 0), w * comp * (vflip ? -1 : 1));
        } else {
            fprintf(stderr, "only png file format(%s) is supported for writing!\n", filename.c_str());
        }
    }

    inline std::vector<BYTE> bits(int align = 1) const {
        const int pitch = (w * comp + align - 1) / align * align;

        std::vector<BYTE> data(pitch * h);
        for (int i = 0; i < h; i++)
            std::copy_n(pixels.data() + i * w * comp, w * comp, data.data() + i * pitch);

        return data;
    }
};

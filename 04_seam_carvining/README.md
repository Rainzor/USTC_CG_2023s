# README

本次实验，在已给框架中修改添加了一下函数

#### main.cpp

- 修改了 `MyImage seamCarving(const MyImage& img, int w, int h,bool show=false)` 函数

  该函数主要是使用给定的图像，利用 Seam Carve 算法实现图像大小的调整

- 修改了 `void createTweakbar()`

  添加了显示路径的选项、以及使用其他显著图像方法作为参考调整图像

- 添加了 `MyImage seamCarvingL1(const MyImage& img, int w, int h, bool show = false)`函数

  该函数主要是利用 **L1 Norm** 方法度量显著图像
  
- 添加了 `MyImage seamCarvingLocalGloal(const MyImage& img, int w, int h, bool show = false) `函数

  该函数主要是利用 *Context-Aware Saliency  Detection. CVPR2010.* 论文中的方法得到的显著图像来参考
  
#### MyImage.h

##### Members：

- 添加 `vector<vector<double>> salience_map` 成员变量，作为显著图像

##### private:

- 添加 `void findPath(vector<vector<int>>& paths, int k = 1, double punish = 50)`函数：获取所有最优竖直缝隙

- 添加 `void decreaseWidth(int k = 1, bool show = false) ` ：减少指定宽度

- 添加 `void increaseWidth(int k = 1, bool show = false)` ：增加指定宽度

- 添加  `void decreaseHeight(int k = 1, bool show = false) ` ：减少指定高度

- 添加 `void increaseHeight(int k = 1, bool show = false)` ：增加指定高度

- 添加 `void saliencyFileInit(std::string filename)` ：读取指定显著图像

- 添加 `void saliencyL1Init() `：利用 **L1 Norm** 构造显著图像

##### public:

- 添加 `void transposeInplace()`：图像转置，辅助修改高度函数
- 添加 `void changeWidth(int new_w,bool show = false)`：修改图像到指定宽度
- 添加 `void changeHeight(int new_h,bool show = false) `：修改图像到指定高度

​    

  
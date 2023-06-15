# README

本次实验，在已给框架中修改添加了一下函数：

- 修改 `blendImagePoisson.m` ，以实现图像融合的核心算法，内部包含两个函数
  - `getDiv` 函数，获取线性方程做 $Ax=b$ 中的右值 $b$
  - `blendImage` 函数，利用解出的 $x$，来对图像进行填充
- 修改 `toolPasteCB.m`、`toolMarkCB.m` ，实现传递中间变量，用户实时交互
- 创建 `preprocess.m` , 在用户第一次进行图像粘贴时，预分解矩阵和掩码图，以辅助加速实时交互效果的实现
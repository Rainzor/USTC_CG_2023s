#pragma once
#include <vector>

#include <Eigen/Core>
#include <Eigen/Sparse>

template<class MatF, class MatI> 
auto Laplacian(const MatF &X, const MatI &T)
{
    std::vector<Eigen::Triplet<double>> ijv;

    // TODO 1: compute ijv triplet for the sparse Laplacian


    //////////////////////////////////////////////////////////////////
    int nv = X.rows();
    Eigen::SparseMatrix<double, Eigen::ColMajor> M(nv, nv);

    M.setFromTriplets(ijv.cbegin(), ijv.cend());

    return M;
}



#include <Eigen/Eigen>
#include <chrono>
#include <cstdio>
#include <iostream>
#include <random>
// todo 5: change the class in to a template class
template <typename T>
class Matrix {
   private:
    int rows, cols, size;
    T* data;
    T* data_transpose;
    void clear() {
        if (data != nullptr)
            delete[] data;
        if (data_transpose != nullptr)
            delete[] data_transpose;
    }

   public:
    // default constructor
    // https://en.cppreference.com/w/cpp/language/constructor
    Matrix() {
        /*.todo 1..*/
        rows = 0;
        cols = 0;
        size = 0;
        data = nullptr;
        data_transpose = nullptr;
    }

    // constructor with initilizer list
    Matrix(int r, int c)
        : rows(r), cols(c), size(r * c) {
        /*.todo 1..*/
        // construct a matrix with r rows and c columns
        // and initialize all the entries to zero
        data = new T[r * c];
        for (int i = 0; i < r * c; i++) {
            data[i] = 0;
        }
        data_transpose = nullptr;
    }
    //
    Matrix(int r, int c, T* d)
        : rows(r), cols(c), size(r * c) {
        data = new T[r * c];
        memcpy(data, d, sizeof(T) * r * c);
        data_transpose = nullptr;
    }

    ////// copy constructor
    Matrix(const Matrix& rhs) {
        clear();
        rows = rhs.rows;
        cols = rhs.cols;
        size = rhs.size;
        data = new T[rows * cols];
        memcpy(data, rhs.data, sizeof(T) * rows * cols);
        data_transpose = nullptr;
    }

    //// desctructor
    //// https://en.cppreference.com/w/cpp/language/destructor
    ~Matrix() {
        /*.todo 2..*/
        // free the memory
        clear();
    }

    int nrow() const { return rows; }
    int ncol() const { return cols; }
    void setZeros(int r, int c) {
        rows = r;
        cols = c;
        size = r * c;
        if (data != nullptr)
            delete[] data;
        data = new T[r * c];
        for (int i = 0; i < r * c; i++) {
            data[i] = 0;
        }
    }
    //// operator overloding
    T& operator()(int r, int c) const {
        /* todo 3: particular entry of the matrix*/
        if (r >= rows || c >= cols)
            throw std::out_of_range("out of range");
        return data[r * cols + c];
    }
    T& operator[](int n) { /* todo 3: particular entry of the matrix*/

        if (n >= size)
            throw std::out_of_range("out of range");
        return data[n];
    }

    Matrix col(int c) { /* todo 4: particular column of the matrix*/
        if (c >= cols)
            throw std::out_of_range("out of range");

        if (data_transpose == nullptr) {
            data_transpose = new T[rows * cols];
            for (int i = 0; i < rows; i++)
                for (int j = 0; j < cols; j++)
                    data_transpose[j * rows + i] = data[i * cols + j];
        }
        Matrix res(rows, 1, data_transpose + c * rows);
        return res;
    }
    Matrix row(int r) { /* todo 4: particular row of the matrix*/
        if (r >= rows)
            throw std::out_of_range("out of range");
        Matrix res(1, cols, data + r * cols);
        return res;
    }
    Matrix submat(int startRow, int startCol, int numRows, int numCols) const { /* todo 4: return a sub-matrix specified by the input parameters*/
        if (startRow < 0 || startRow >= rows)
            throw std::out_of_range("start row out of range");
        if (startCol < 0 || startCol >= cols)
            throw std::out_of_range("start col out of range");
        if (numRows <= 0 || numRows > rows)
            throw std::out_of_range("num rows out of range");
        if (numCols <= 0 || numCols > cols)
            throw std::out_of_range("num cols out of range");
        if (startRow + numRows > rows)
            throw std::out_of_range("start row + num rows out of range");
        if (startCol + numCols > cols)
            throw std::out_of_range("start col + num cols out of range");

        Matrix sub(numRows, numCols);
        for (int i = 0; i < numRows; i++)
            for (int j = 0; j < numCols; j++)
                sub(i, j) = data[(startRow + i) * cols + (startCol + j)];
        return sub;
    }

    // constant alias
    Matrix& operator=(const Matrix& rhs) { /*.todo 3..*/
        if (this == &rhs)
            return *this;
        clear();
        rows = rhs.rows;
        cols = rhs.cols;
        size = rhs.size;
        data = new T[rows * cols];
        memcpy(data, rhs.data, sizeof(T) * rows * cols);

        return *this;
    }

    Matrix operator+(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");
        Matrix res(rows, cols);
        for (int i = 0; i < rows * cols; i++)
            res.data[i] = data[i] + rhs.data[i];
        return res;
    }
    Matrix operator-(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");
        Matrix res(rows, cols);
        for (int i = 0; i < rows * cols; i++)
            res.data[i] = data[i] - rhs.data[i];
        return res;
    }

    // 矩阵乘法运算
    Matrix operator*(const Matrix& rhs) { /*.todo 3..*/
        if (cols != rhs.nrow())
            throw std::out_of_range("matrix size not match");
        Matrix res(rows, rhs.cols);
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < rhs.cols; j++)
                for (int k = 0; k < cols; k++)
                    res(i, j) += data[i * cols + k] * rhs.data[k * rhs.cols + j];
        return res;
    }

    // 按位除法运算
    Matrix operator/(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");
        Matrix res(rows, cols);
        for (int i = 0; i < rows * cols; i++){
            if (rhs.data[i] == 0)
                throw "Division by zero condition!";
            res.data[i] = data[i] / rhs.data[i];
        }

        return res;
    }

    Matrix operator+=(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");

        for (int i = 0; i < rows * cols; i++)
            data[i] += rhs.data[i];
        if (data_transpose != nullptr)
            delete[] data_transpose;
        return *this;
    }
    Matrix operator-=(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");
        for (int i = 0; i < rows * cols; i++)
            data[i] -= rhs.data[i];
        if (data_transpose != nullptr)
            delete[] data_transpose;
        return *this;
    }
    // 矩阵乘法
    Matrix operator*=(const Matrix& rhs) { /*.todo 3..*/
        if (cols != rhs.rows)
            throw std::out_of_range("matrix size not match");
        Matrix res(rows, rhs.cols);
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < rhs.cols; j++)
                for (int k = 0; k < cols; k++)
                    res(i, j) += data[i * cols + k] * rhs.data[k * rhs.cols + j];
        delete[] data;
        if (data_transpose != nullptr)
            delete[] data_transpose;
        *this = res;
        return *this;
    }

    // 按位除法
    Matrix operator/=(const Matrix& rhs) { /*.todo 3..*/
        if (rows != rhs.rows || cols != rhs.cols)
            throw std::out_of_range("matrix size not match");
        for (int i = 0; i < rows * cols; i++){
            if(rhs.data[i]==0)
                throw "Division by zero condition!";
            data[i] /= rhs.data[i];
        }
        if (data_transpose != nullptr)
            delete[] data_transpose;
        return *this;
    }

    // 矩阵与标量运算
    Matrix operator+(T v) { /*.todo 3..*/
        Matrix res(rows, cols);
        for (int i = 0; i < rows * cols; i++)
            res.data[i] = data[i] + v;
        return res;
    }
    Matrix operator-(T v) {
        return *this + (-v);
    }
    Matrix operator*(T v) { /*.todo 3..*/
        Matrix res(rows, cols);
        for (int i = 0; i < rows * cols; i++)
            res.data[i] = data[i] * v;
        return res;
    }
    Matrix operator/(T v) { /*.todo 3..*/
        if(v==0)
            throw "Division by zero condition!";
        return *this * (1.0 / v);
    }

    Matrix operator+=(T v) { /*.todo 3..*/
        for (int i = 0; i < rows * cols; i++)
            data[i] += v;
        if (data_transpose != nullptr)
            delete[] data_transpose;
        return *this;
    }
    Matrix operator-=(T v) { /*.todo 3..*/
        return *this += (-v);
    }
    Matrix operator*=(T v) { /*.todo 3..*/
        for (int i = 0; i < rows * cols; i++)
            data[i] *= v;
        if (data_transpose != nullptr)
            delete[] data_transpose;
        return *this;
    }
    Matrix operator/=(T v) { /*.todo 3..*/
        return *this *= (1.0 / v);
    }

    void print() const {
        printf("this matrix has size (%d x %d)\n", rows, cols);
        printf("the entries are:\n");
        /* todo 4: print all the entries of the matrix */
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                std::cout << data[i * cols + j] << " ";
            }
            std::cout << std::endl;
        }
    }
};

//// BONUS: write a sparse matrix class
// RowMajor Sparse Matrix Class
template <typename T>
struct Triplet {
    int row{}, col{};
    T value;
    Triplet(int row, int col, T value);
    Triplet() = default;  // 提供默认构造函数
};

template<typename T>
Triplet<T>::Triplet(int row, int col, T value)
        : row(row), col(col), value(value) {
}

template <typename T>
class SparseMatrix {
   public:
    SparseMatrix(int rows, int cols)
        : rows(rows), cols(cols) {}

    // 添加一个元素
    void insert(int row, int col, T value) {
        triplets.emplace_back(row, col, value);
    }

    // 转置矩阵
    SparseMatrix<T> transpose() const {
        SparseMatrix<T> result(cols, rows);
        for (const auto& t : triplets) {
            result.insert(t.col, t.row, t.value);
        }
        return result;
    }
    // 就地转置
    void transposeInplace() const {
        SparseMatrix<T> result(cols, rows);
        for (const auto& t : triplets) {
            result.insert(t.col, t.row, t.value);
        }
        triplets.assign(result.triplets);
        makeCompressed();
    }
    // 返回第r行的三元组
    std::vector<Triplet<T>> row_triple(int r) const {
        if (r >= rows)
            throw std::out_of_range("out of range");
        int start = outer_starts[r];
        int end = outer_starts[r + 1];
        std::vector<Triplet<T>> row_triplets(end - start);
        row_triplets.assign(triplets.begin() + start, triplets.begin() + end);
        return row_triplets;
    }

    // 压缩矩阵
    void makeCompressed() {
        // 先按行排序
        std::sort(triplets.begin(), triplets.end(),
                  [](const Triplet<T>& t1, const Triplet<T>& t2) {
                      return t1.row < t2.row || (t1.row == t2.row && t1.col < t2.col);
                  });
        // 统计每一行的元素个数
        row_nnz.resize(rows, 0);
        for (const auto& t : triplets) {
            ++row_nnz[t.row];
        }
        col_nnz.resize(cols, 0);
        for (const auto& t : triplets) {
            ++col_nnz[t.col];
        }
        // 计算每一行的起始位置
        outer_starts.resize(rows + 1, 0);
        for (int i = 0; i < rows; ++i) {
            outer_starts[i + 1] = outer_starts[i] + row_nnz[i];
        }
        // 将三元组按行存储到压缩矩阵中
        inner_indices.resize(triplets.size());
        values.resize(triplets.size());
        for (const auto& t : triplets) {
            int index = outer_starts[t.row]++;
            inner_indices[index] = t.col;
            values[index] = t.value;
        }

        // 恢复每一行的起始位置
        for (int i = rows; i > 0; --i) {
            outer_starts[i] = outer_starts[i - 1];
        }
        outer_starts[0] = 0;
    }

    // 从三元组构造稀疏矩阵
    void setFromTriplets(const std::vector<Triplet<T>>& t) {
        // 保存三元组并按行排序
        this->triplets.assign(t.begin(), t.end());
        makeCompressed();
    }

    // 矩阵赋值
    SparseMatrix<T>& operator=(const SparseMatrix<T>& rhs) {
        if (this == &rhs)
            return *this;
        rows = rhs.rows;
        cols = rhs.cols;

        triplets.assign(rhs.triplets.begin(), rhs.triplets.end());
        outer_starts.assign(rhs.outer_starts.begin(), rhs.outer_starts.end());
        inner_indices.assign(rhs.inner_indices.begin(), rhs.inner_indices.end());
        row_nnz.assign(rhs.row_nnz.begin(), rhs.row_nnz.end());
        col_nnz.assign(rhs.col_nnz.begin(), rhs.col_nnz.end());
        values.assign(rhs.values.begin(), rhs.values.end());
        return *this;
    }

    // 矩阵乘法
    SparseMatrix<T> operator*(const SparseMatrix<T>& rhs) const {
        if (cols != rhs.rows) {
            throw std::invalid_argument("Matrix size not match!");
        }
        SparseMatrix<T> result(rows, rhs.cols);
        // 对右矩阵进行转置，并按行压缩

        SparseMatrix<T> transp_rhs = rhs.transpose();
        transp_rhs.makeCompressed();

        for (int i = 0; i < rows; i++) {  // 遍历左矩阵的每一行
            for (int j = 0; j < rhs.cols; j++) { // 遍历右矩阵的每一列
                std::vector<Triplet<T>> row_triplets = row_triple(i);
                std::vector<Triplet<T>> col_triplets = transp_rhs.row_triple(j);
                int k = 0, l = 0;
                T sum = 0;
                while (k < row_triplets.size() && l < col_triplets.size()) {
                    if (row_triplets[k].col < col_triplets[l].col) {
                        ++k;
                    } else if (row_triplets[k].col > col_triplets[l].col) {
                        ++l;
                    } else {
                        sum += row_triplets[k].value * col_triplets[l].value;
                        ++k;
                        ++l;
                    }
                }
                if (sum != 0) {
                    result.insert(i, j, sum);
                }
            }
        }
        return result;
    }

    // 矩阵索引
    T operator()(int row, int col) {
        if (row < 0 || row >= rows || col < 0 || col >= cols) {
            throw std::invalid_argument("Matrix index out of range!");
        }

        int start = outer_starts[row];
        int end = outer_starts[row + 1] - 1;
        for (int i = start; i <= end; ++i) {
            if (inner_indices[i] == col) {
                return values[i];
            }
        }

        return 0;
    }

    // output
    void printSparse() const {
        printf("this matrix has size (%d x %d)\n", rows, cols);
        printf("the entries are:\n");
        for (auto t : triplets) {
            std::cout << "(" << t.row << ", " << t.col << ") " << t.value << std::endl;
        }
    }
    void print() const {
        printf("this matrix has size (%d x %d)\n", rows, cols);
        printf("the entries are:\n");
        int cur_trip = 0;
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                if (cur_trip < triplets.size() && triplets[cur_trip].row == i && triplets[cur_trip].col == j) {
                    std::cout << triplets[cur_trip].value << " ";
                    cur_trip++;
                } else {
                    std::cout << 0 << " ";
                }
            }
            std::cout << std::endl;
        }
    }

   private:
    int rows, cols;
    std::vector<Triplet<T>> triplets;
    std::vector<int> outer_starts;
    std::vector<int> inner_indices;
    std::vector<int> row_nnz;
    std::vector<int> col_nnz;
    std::vector<T> values;
};

int main() {
    using namespace std::chrono;
    using std::cout;
    /////////////////////////////////////////////////////////
    //Matrix 函数基本运算检验
    Matrix<double> A(3, 3), B(3, 3);
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3; j++){
            A(i, j) = i * 3 + j;
            B(i,j) = i*3+j+1;
        }
    try
    {
        cout << A(3, 0) << std::endl;
    } catch (std::out_of_range& ex) {
        std::cerr << "Error: " << ex.what() << std::endl;
    } catch (std::exception& ex) {
        std::cerr << "Error: " << ex.what() << std::endl;
    }

    Matrix<double> C;

    cout<<"A Matrix:"<<std::endl;
    A.print();

    cout << std::endl << "B Matrix:" << std::endl;
    B.print();

    cout << std::endl << "A sub Matrix:" << std::endl;
    A.submat(0,0,2,2).print();
    
    cout << std::endl << "A+B = " << std::endl;
    C=A+B;
    C.print();

    cout << std::endl << "A-B = " << std::endl;
    C=A-B;
    C.print();

    cout << std::endl << "AxB = " << std::endl;
    C= A*B;
    C.print();

    cout << std::endl << "A/B = " << std::endl;
    C= A/B;
    C.print();

    /////////////////////////////////////////////////////////
    //Sparse Matrix 函数基本运算检验
    SparseMatrix<double> A_s(8, 8);
    std::vector<Triplet<double>> triplets = {{0, 0, 1.0}, {1, 1, 2.0}, {2, 2, 3.0}, {0, 2, 4.0}, {3, 3, 5.0}, {4, 4, 6.0}, {5, 5, 7.0}, {6, 6, 8.0}, {7, 7, 9.0}};
    A_s.setFromTriplets(triplets);
    std::cout << std::endl<<"A Sparse Mat:"<<std::endl;
    A_s.printSparse();
    SparseMatrix<double> B_s(8, 8);
    triplets = {{0, 0, 1.0}, {1, 1, 2.0}, {2, 2, 3.0}, {0, 2, 4.0}, {3, 3, 5.0}, {4, 4, 6.0}, {5, 5, 7.0}, {6, 6, 8.0}, {7, 7, 9.0}};
    B_s.setFromTriplets(triplets);
    std::cout << std::endl<<"B Sparse Mat:"<<std::endl;
    B_s.print();

    SparseMatrix<double> C_s = A_s * B_s;
    C_s.makeCompressed();
    std::cout << std::endl<<"AxB="<<std::endl;
    C_s.print();

    /////////////////////////////////////////////////////////
    // 与Eigen库比较

    A.setZeros(1000, 1000);
    B.setZeros(1000, 1000);
    //// todo 6: fill A anb B with random numbers

    // 创建一个随机数生成器对象，使用当前时间作为种子
    std::default_random_engine generator(std::chrono::system_clock::now().time_since_epoch().count());

    // 创建一个均匀分布的整数分布器，范围为[0, 99]
    std::uniform_int_distribution<int> distribution(0, 99);

    for (int i = 0; i < A.nrow(); i++)
        for (int j = 0; j < A.ncol(); j++) {
            A(i, j) = distribution(generator);
            B(i, j) = distribution(generator);
        }

    //// todo 7: benchmark with runtime, using std::chrono
    //// https://en.cppreference.com/w/cpp/chrono
    auto start = high_resolution_clock::now();
    C = A * B;
    // C.print();
    auto end = high_resolution_clock::now();
    auto duration = duration_cast<milliseconds>(end - start);
    std::cout << std::endl
              << "My Matrix Multi time(1000x1000):" << duration.count() << " ms" << std::endl;

    // todo 8: use Eigen and compare
    Eigen::MatrixXd A_eigen(1000, 1000), B_eigen(1000, 1000);
    for (int i = 0; i < A_eigen.rows(); i++)
        for (int j = 0; j < A_eigen.cols(); j++) {
            A_eigen(i, j) = distribution(generator);
            B_eigen(i, j) = distribution(generator);
        }
    start = high_resolution_clock::now();
    Eigen::MatrixXd C_eigen = A_eigen * B_eigen;
    // std::cout << C_eigen << std::endl;
    end = high_resolution_clock::now();
    duration = duration_cast<milliseconds>(end - start);
    std::cout << "Eigen Matrix Multi time(1000x1000):" << duration.count() << " ms" << std::endl;
    return 0;
}
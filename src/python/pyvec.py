from __future__ import division
from operator import mul


class Vector(object):
    """Pure python Vector implementation"""

    def __init__(self, data):
        self.data = data

    def __repr__(self):
        return repr(self.data)

    def __add__(self, other):
        return Vector(map(lambda x, y: x+y, self.data, other.data))

    def __sub__(self, other):
        return Vector(map(lambda x, y: x-y, self.data, other.data))

    def __mul__(self, other):
        if isinstance(other, Vector):
            return sum(map(mul, self.data, other.data))
        else:
            return Vector(map(lambda x:x*other, self.data))

    def __rmul__(self, other):
        return self*other

    def __abs__(self):
        return pow(sum(map(lambda x: x*x, self.data)), 0.5)

    def norm(self, p=2):
        return pow(sum(map(lambda x: x**p, self.data)), 1/p)

    def __neg__(self):
        return [-x for x in self.data]

    def __getitem__(self, index):
        return self.data[index]

    def __setitem__(self, index, val):
        self.data[index] = val

    def __len__(self):
        return len(self.data)

    @staticmethod
    def zeros(size):
        return Vector([0.0]*size)

    @staticmethod
    def ones(size):
        return Vector([1.0]*size)


def perf_compare():
    import timeit
    setupMyVec = (""
    "from __main__ import Vector\n"
    "import random\n"
    "random.seed('slartibartfast')\n"
    "xl = [random.random() for i in range(100)]\n"
    "yl = [random.random() for i in range(100)]\n"
    "x = Vector(xl)\n"
    "y = Vector(yl)\n")

    setupNumPy = (""
    "import numpy as np\n"
    "from numpy.linalg import norm\n"
    "import random\n"
    "random.seed('slartibartfast')\n"
    "xl = [random.random() for i in range(100)]\n"
    "yl = [random.random() for i in range(100)]\n"
    "x = np.array(xl)\n"
    "y = np.array(yl)\n")

    rep_count, num_executes = 20, 1000

    myDot = min(timeit.Timer('x*y', setup=setupMyVec).repeat(rep_count, num_executes))
    npDot = min(timeit.Timer('np.dot(x,y)', setup=setupNumPy).repeat(rep_count, num_executes))
    myNorm = min(timeit.Timer('x.norm()', setup=setupMyVec).repeat(rep_count, num_executes))
    npNorm = min(timeit.Timer('norm(x)', setup=setupNumPy).repeat(rep_count, num_executes))
    myZ = min(timeit.Timer('z = Vector.zeros(len(x))', setup=setupMyVec).repeat(rep_count, num_executes))
    npZ = min(timeit.Timer('z = np.zeros(x.shape)', setup=setupNumPy).repeat(rep_count, num_executes))

    print "Dot:"
    print "MyVec:", myDot
    print "Numpy:", npDot
    print "%.2f%%" % (100*myDot/npDot)

    print "Norm:"
    print "MyVec:", myNorm
    print "Numpy:", npNorm
    print "%.2f%%" % (100*myNorm/npNorm)

    print "Zeros:"
    print "MyVec:", myZ
    print "Numpy:", npZ
    print "%.2f%%" % (100*myZ/npZ)


def simple_tests():
    x = Vector([1,1,1,1])
    y = Vector([1,2,3,4])
    z = Vector.zeros(4)
    o = Vector.ones(4)

    tests = [
             "x",
             "y",
             "z",
             "o",
             "-o",
             "x+y",
             "x-y",
             "x*y",
             "y*3.0",
             "3*y",
             "abs(x)",
             "x.norm()",
             "x.norm(3)",
             "x.norm(1e20)",
            ]

    for test in tests:
        print test, ":", eval(test)


if __name__ == '__main__':
    # simple_tests()
    perf_compare()
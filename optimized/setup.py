from setuptools import setup
from Cython.Build import cythonize
import numpy

setup(
    ext_modules=cythonize([
            "C:/Users/ywang/Downloads/cython/cython/ray_tracing.pyx",
            "C:/Users/ywang/Downloads/cython/cython/process_rays.pyx",          ], language_level=3),
    include_dirs=[numpy.get_include()],
    extra_compile_args=["-fopenmp"],
    extra_link_args=["-fopenmp"]
)

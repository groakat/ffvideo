import os
import platform
from distutils.core import setup, Extension

try:
    from Cython.Distutils import build_ext
    sources = ["ffvideo/ffvideo.pyx"]
    cmdclass = {'build_ext': build_ext}
except ImportError:
    sources = ["ffvideo/ffvideo.c"]
    cmdclass = {}

def read(fn):
    return open(os.path.join(os.path.dirname(__file__), fn)).read()

VERSION = "0.0.13"

if platform.system() == 'Linux':
    include_dirs = ["/usr/include/ffmpeg"]
    library_dirs = []
elif platform.system() == 'Darwin':
    include_dirs = ['/usr/local/Cellar/ffmpeg/2.3/include/']
    library_dirs = ['/usr/local/Cellar/ffmpeg/2.3/lib/']
else:
    import os
    include_dirs = [os.environ['LIBRARY_INC']]
    library_dirs = [os.environ['LIBRARY_LIB']]

setup(
    name="FFVideo",
    version=VERSION,
    description="FFVideo is a python extension makes possible to access to decoded frames at two format: PIL.Image or numpy.ndarray.",
    long_description=read("README.txt"),
    ext_modules=[
        Extension("ffvideo", sources,
                  include_dirs=include_dirs,
                  libraries=["avformat", "avcodec", "swscale", "avutil"],
                  library_dirs=library_dirs)
    ],
    cmdclass=cmdclass,
    author="Zakhar Zibarov",
    author_email="zakhar.zibarov@gmail.com",
    url="http://bitbucket.org/zakhar/ffvideo/",
)


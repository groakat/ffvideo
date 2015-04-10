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

VERSION = "0.0.14"

if platform.system() == 'Linux':
        #include_dirs = ["/home/peter/ffmpeg_build_shared/lib/", "/usr/include/ffmpeg"]
        #library_dirs = ["/home/peter/ffmpeg_build_shared/include/"]                
    #p = os.environ['PATH']
    #include_dirs = [os.path.join(x, '..', 'include') for x in p.split(':')]
    #library_dirs = [os.path.join(x, '..', 'lib') for x in p.split(':')]
    try:
        # for build with conda
        include_dirs = [os.path.join(os.environ['PREFIX'],
                         'include')]
        library_dirs = [os.path.join(os.environ['PREFIX'],
                         'lib')]
    except KeyError:     
        p = os.environ['PATH']
        include_dirs = [os.path.join(x, '..', 'include') for x in p.split(':')]
        library_dirs = [os.path.join(x, '..', 'lib') for x in p.split(':')]
        
elif platform.system() == 'Darwin':
    p = os.environ['PATH']
    include_dirs = [os.path.join(x, '..', 'include') for x in p.split(':')]
    library_dirs = [os.path.join(x, '..', 'lib') for x in p.split(':')]
    try:
        # for build with conda
        include_dirs += [os.path.join(os.environ['PREFIX'],
                         'include')]
        library_dirs += [os.path.join(os.environ['PREFIX'],
                         'lib')]
    except KeyError:
        pass
else:
    try:
        include_dirs = [os.environ['LIBRARY_INC']]
        print("include", os.environ['LIBRARY_INC'])
    except KeyError:
        print("include KEYERROR")
        include_dirs = []
    try:
        library_dirs = [os.environ['LIBRARY_LIB']]
        print("library", os.environ['LIBRARY_LIB'])
    except KeyError:
        print("lib KEYERROR")
        library_dirs = []

LIBPATH = '/Users/peter/anaconda/lib/'

setup(
    name="FFVideo",
    version=VERSION,
    description="FFVideo is a python extension makes possible to access to decoded frames at two format: PIL.Image or numpy.ndarray.",
    long_description=read("README.txt"),
    ext_modules=[
        Extension("ffvideo", sources,
                  include_dirs=include_dirs,
                  libraries=["avformat", "avcodec", "swscale", "avutil"],
                  #libraries=[LIBPATH + "libavformat",LIBPATH +  "libavcodec",LIBPATH +  "libswscale",
                  #                LIBPATH + "libavutil", LIBPATH + "libavdevice", 
                  #                LIBPATH + "libavformat", LIBPATH + "libpostproc",
                  #                LIBPATH + "libswresample", LIBPATH + "libswscale"],
                  library_dirs=library_dirs,
                  #language='c++',
                  #extra_objects=[LIBPATH + "libavformat.a",LIBPATH +  "libavcodec.a",LIBPATH +  "libswscale.a",
                  #                LIBPATH + "libavutil.a", LIBPATH + "libavdevice.a", 
                  #                LIBPATH + "libavformat.a", LIBPATH + "libpostproc.a",
                  #                LIBPATH + "libswresample.a", LIBPATH + "libswscale.a"]
                  )
    ],
    cmdclass=cmdclass,
    author="Zakhar Zibarov, Peter Rennert",
    author_email="zakhar.zibarov@gmail.com, p.rennert@cs.ucl.ac.uk",
    url="http://bitbucket.org/zakhar/ffvideo/",
)


ctypedef signed long long int64_t
ctypedef unsigned char uint8_t

cdef enum:
    SEEK_SET = 0
    SEEK_CUR = 1
    SEEK_END = 2

cdef extern from "libavutil/rational.h":
    struct AVRational:
        int num
        int den

    double av_q2d(AVRational  a)
    AVRational av_mul_q (AVRational b, AVRational c)
    AVRational av_div_q (AVRational b, AVRational c)

cdef extern from "libavutil/mathematics.h":
    int64_t av_rescale(int64_t a, int64_t b, int64_t c)
    int64_t av_rescale_q(int64_t a, AVRational bq, AVRational cq)

cdef extern from "libavutil/avutil.h":
    cdef enum PixelFormat:
        PIX_FMT_NONE= -1,
        AV_PIX_FMT_YUV420P,   #< Planar YUV 4:2:0 (1 Cr & Cb sample per 2x2 Y samples)
        AV_PIX_FMT_YUV422,    #< Packed pixel, Y0 Cb Y1 Cr
        AV_PIX_FMT_RGB24,     #< Packed pixel, 3 bytes per pixel, RGBRGB...
        AV_PIX_FMT_BGR24,     #< Packed pixel, 3 bytes per pixel, BGRBGR...
        AV_PIX_FMT_YUV422P,   #< Planar YUV 4:2:2 (1 Cr & Cb sample per 2x1 Y samples)
        AV_PIX_FMT_YUV444P,   #< Planar YUV 4:4:4 (1 Cr & Cb sample per 1x1 Y samples)
        AV_PIX_FMT_RGBA32,    #< Packed pixel, 4 bytes per pixel, BGRABGRA..., stored in cpu endianness
        AV_PIX_FMT_YUV410P,   #< Planar YUV 4:1:0 (1 Cr & Cb sample per 4x4 Y samples)
        AV_PIX_FMT_YUV411P,   #< Planar YUV 4:1:1 (1 Cr & Cb sample per 4x1 Y samples)
        AV_PIX_FMT_RGB565,    #< always stored in cpu endianness
        AV_PIX_FMT_RGB555,    #< always stored in cpu endianness, most significant bit to 1
        AV_PIX_FMT_GRAY8,
        AV_PIX_FMT_MONOWHITE, #< 0 is white
        AV_PIX_FMT_MONOBLACK, #< 0 is black
        AV_PIX_FMT_PAL8,      #< 8 bit with RGBA palette
        AV_PIX_FMT_YUVJ420P,  #< Planar YUV 4:2:0 full scale (jpeg)
        AV_PIX_FMT_YUVJ422P,  #< Planar YUV 4:2:2 full scale (jpeg)
        AV_PIX_FMT_YUVJ444P,  #< Planar YUV 4:4:4 full scale (jpeg)
        AV_PIX_FMT_XVMC_MPEG2_MC,#< XVideo Motion Acceleration via common packet passing(xvmc_render.h)
        AV_PIX_FMT_XVMC_MPEG2_IDCT,
        AV_PIX_FMT_UYVY422,   #< Packed pixel, Cb Y0 Cr Y1
        AV_PIX_FMT_UYVY411,   #< Packed pixel, Cb Y0 Y1 Cr Y2 Y3
        AV_PIX_FMT_NB,

    struct AVDictionaryEntry:
        char *key
        char *value

    struct AVDictionary:
        int count
        AVDictionaryEntry *elems

    void av_free(void *) nogil
    void av_freep(void *) nogil

cdef extern from "libavutil/log.h":
    int AV_LOG_VERBOSE
    int AV_LOG_ERROR
    void av_log_set_level(int)

cdef extern from "libavcodec/avcodec.h":
    # use an unamed enum for defines
    cdef enum:
        AVSEEK_FLAG_BACKWARD = 1 #< seek backward
        AVSEEK_FLAG_BYTE     = 2 #< seeking based on position in bytes
        AVSEEK_FLAG_ANY      = 4 #< seek to any frame, even non keyframes
        AVSEEK_FLAG_FRAME    = 8 #< seeking based on frame number

        CODEC_CAP_TRUNCATED = 0x0008
        CODEC_FLAG_TRUNCATED = 0x00010000 # input bitstream might be truncated at a random location instead of only at frame boundaries
        AV_TIME_BASE = 1000000
        FF_I_TYPE = 1 # Intra
        FF_P_TYPE = 2 # Predicted
        FF_B_TYPE = 3 # Bi-dir predicted
        FF_S_TYPE = 4 # S(GMC)-VOP MPEG4
        FF_SI_TYPE = 5
        FF_SP_TYPE = 6

    cdef int CODEC_FLAG_GRAY
    cdef AVRational AV_TIME_BASE_Q
    cdef int64_t AV_NOPTS_VALUE

    enum AVDiscard:
        # we leave some space between them for extensions (drop some keyframes for intra only or drop just some bidir frames)
        AVDISCARD_NONE   = -16 # discard nothing
        AVDISCARD_DEFAULT=   0 # discard useless packets like 0 size packets in avi
        AVDISCARD_NONREF =   8 # discard all non reference
        AVDISCARD_BIDIR  =  16 # discard all bidirectional frames
        AVDISCARD_NONKEY =  32 # discard all frames except keyframes
        AVDISCARD_ALL    =  48 # discard all

    enum AVMediaType:
        AVMEDIA_TYPE_UNKNOWN = -1
        AVMEDIA_TYPE_VIDEO = 0
        AVMEDIA_TYPE_AUDIO = 1
        AVMEDIA_TYPE_DATA = 2
        AVMEDIA_TYPE_SUBTITLE = 3
        AVMEDIA_TYPE_ATTACHMENT = 4
        AVMEDIA_TYPE_NB = 5

    struct AVCodecContext:
        int max_b_frames
        int codec_type
        int codec_id
        int flags
        int width
        int height
        AVPixelFormat pix_fmt
        int frame_number
        int hurry_up
        int skip_idct
        int skip_frame
        AVRational time_base

    struct AVCodec:
        char *name
        int type
        int id
        int priv_data_size
        int capabilities
        AVCodec *next
        AVRational *supported_framerates #array of supported framerates, or NULL if any, array is terminated by {0,0}
        int *pix_fmts       #array of supported pixel formats, or NULL if unknown, array is terminanted by -1

    struct AVPacket:
        int64_t pts                            #< presentation time stamp in time_base units
        int64_t dts                            #< decompression time stamp in time_base units
        char *data
        int   size
        int   stream_index
        int   flags
        int   duration                      #< presentation duration in time_base units (0 if not available)
        void  *priv
        int64_t pos                            #< byte position in stream, -1 if unknown

    struct AVFrame:
        uint8_t *data[4]
        int linesize[4]
        int64_t pts
        int coded_picture_number
        int display_picture_number
        int pict_type
        int key_frame
        int repeat_pict

    struct AVPicture:
        uint8_t *data[4]
        int linesize[4]
        
    enum AVPixelFormat:
        AV_PIX_FMT_NONE = -1,
        AV_PIX_FMT_YUV420P,   #< planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
        AV_PIX_FMT_YUYV422,   #< packed YUV 4:2:2, 16bpp, Y0 Cb Y1 Cr
        AV_PIX_FMT_RGB24,     #< packed RGB 8:8:8, 24bpp, RGBRGB...
        AV_PIX_FMT_BGR24,     #< packed RGB 8:8:8, 24bpp, BGRBGR...
        AV_PIX_FMT_YUV422P,   #< planar YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
        AV_PIX_FMT_YUV444P,   #< planar YUV 4:4:4, 24bpp, (1 Cr & Cb sample per 1x1 Y samples)
        AV_PIX_FMT_YUV410P,   #< planar YUV 4:1:0,  9bpp, (1 Cr & Cb sample per 4x4 Y samples)
        AV_PIX_FMT_YUV411P,   #< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples)
        AV_PIX_FMT_GRAY8,     #<        Y        ,  8bpp
        AV_PIX_FMT_MONOWHITE, #<        Y        ,  1bpp, 0 is white, 1 is black, in each byte pixels are ordered from the msb to the lsb
        AV_PIX_FMT_MONOBLACK, #<        Y        ,  1bpp, 0 is black, 1 is white, in each byte pixels are ordered from the msb to the lsb
        AV_PIX_FMT_PAL8,      #< 8 bit with PIX_FMT_RGB32 palette
        AV_PIX_FMT_YUVJ420P,  #< planar YUV 4:2:0, 12bpp, full scale (JPEG), deprecated in favor of PIX_FMT_YUV420P and setting color_range
        AV_PIX_FMT_YUVJ422P,  #< planar YUV 4:2:2, 16bpp, full scale (JPEG), deprecated in favor of PIX_FMT_YUV422P and setting color_range
        AV_PIX_FMT_YUVJ444P,  #< planar YUV 4:4:4, 24bpp, full scale (JPEG), deprecated in favor of PIX_FMT_YUV444P and setting color_range
        AV_PIX_FMT_XVMC_MPEG2_MC,#< XVideo Motion Acceleration via common packet passing
        AV_PIX_FMT_XVMC_MPEG2_IDCT,
        AV_PIX_FMT_UYVY422,   #< packed YUV 4:2:2, 16bpp, Cb Y0 Cr Y1
        AV_PIX_FMT_UYYVYY411, #< packed YUV 4:1:1, 12bpp, Cb Y0 Y1 Cr Y2 Y3
        AV_PIX_FMT_BGR8,      #< packed RGB 3:3:2,  8bpp, (msb)2B 3G 3R(lsb)
        AV_PIX_FMT_BGR4,      #< packed RGB 1:2:1 bitstream,  4bpp, (msb)1B 2G 1R(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
        AV_PIX_FMT_BGR4_BYTE, #< packed RGB 1:2:1,  8bpp, (msb)1B 2G 1R(lsb)
        AV_PIX_FMT_RGB8,      #< packed RGB 3:3:2,  8bpp, (msb)2R 3G 3B(lsb)
        AV_PIX_FMT_RGB4,      #< packed RGB 1:2:1 bitstream,  4bpp, (msb)1R 2G 1B(lsb), a byte contains two pixels, the first pixel in the byte is the one composed by the 4 msb bits
        AV_PIX_FMT_RGB4_BYTE, #< packed RGB 1:2:1,  8bpp, (msb)1R 2G 1B(lsb)
        AV_PIX_FMT_NV12,      #< planar YUV 4:2:0, 12bpp, 1 plane for Y and 1 plane for the UV components, which are interleaved (first byte U and the following byte V)
        AV_PIX_FMT_NV21,      #< as above, but U and V bytes are swapped

        AV_PIX_FMT_ARGB,      #< packed ARGB 8:8:8:8, 32bpp, ARGBARGB...
        AV_PIX_FMT_RGBA,      #< packed RGBA 8:8:8:8, 32bpp, RGBARGBA...
        AV_PIX_FMT_ABGR,      #< packed ABGR 8:8:8:8, 32bpp, ABGRABGR...
        AV_PIX_FMT_BGRA,      #< packed BGRA 8:8:8:8, 32bpp, BGRABGRA...

        AV_PIX_FMT_GRAY16BE,  #<        Y        , 16bpp, big-endian
        AV_PIX_FMT_GRAY16LE,  #<        Y        , 16bpp, little-endian
        AV_PIX_FMT_YUV440P,   #< planar YUV 4:4:0 (1 Cr & Cb sample per 1x2 Y samples)
        AV_PIX_FMT_YUVJ440P,  #< planar YUV 4:4:0 full scale (JPEG), deprecated in favor of PIX_FMT_YUV440P and setting color_range
        AV_PIX_FMT_YUVA420P,  #< planar YUV 4:2:0, 20bpp, (1 Cr & Cb sample per 2x2 Y & A samples)
        AV_PIX_FMT_VDPAU_H264,#< H.264 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_VDPAU_MPEG1,#< MPEG-1 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_VDPAU_MPEG2,#< MPEG-2 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_VDPAU_WMV3,#< WMV3 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_VDPAU_VC1, #< VC-1 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_RGB48BE,   #< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as big-endian
        AV_PIX_FMT_RGB48LE,   #< packed RGB 16:16:16, 48bpp, 16R, 16G, 16B, the 2-byte value for each R/G/B component is stored as little-endian

        AV_PIX_FMT_RGB565BE,  #< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), big-endian
        AV_PIX_FMT_RGB565LE,  #< packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian
        AV_PIX_FMT_RGB555BE,  #< packed RGB 5:5:5, 16bpp, (msb)1A 5R 5G 5B(lsb), big-endian, most significant bit to 0
        AV_PIX_FMT_RGB555LE,  #< packed RGB 5:5:5, 16bpp, (msb)1A 5R 5G 5B(lsb), little-endian, most significant bit to 0

        AV_PIX_FMT_BGR565BE,  #< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), big-endian
        AV_PIX_FMT_BGR565LE,  #< packed BGR 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), little-endian
        AV_PIX_FMT_BGR555BE,  #< packed BGR 5:5:5, 16bpp, (msb)1A 5B 5G 5R(lsb), big-endian, most significant bit to 1
        AV_PIX_FMT_BGR555LE,  #< packed BGR 5:5:5, 16bpp, (msb)1A 5B 5G 5R(lsb), little-endian, most significant bit to 1

        AV_PIX_FMT_VAAPI_MOCO, #< HW acceleration through VA API at motion compensation entry-point, Picture.data[3] contains a vaapi_render_state struct which contains macroblocks as well as various fields extracted from headers
        AV_PIX_FMT_VAAPI_IDCT, #< HW acceleration through VA API at IDCT entry-point, Picture.data[3] contains a vaapi_render_state struct which contains fields extracted from headers
        AV_PIX_FMT_VAAPI_VLD,  #< HW decoding through VA API, Picture.data[3] contains a vaapi_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers

        AV_PIX_FMT_YUV420P16LE,  #< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
        AV_PIX_FMT_YUV420P16BE,  #< planar YUV 4:2:0, 24bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
        AV_PIX_FMT_YUV422P16LE,  #< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_YUV422P16BE,  #< planar YUV 4:2:2, 32bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
        AV_PIX_FMT_YUV444P16LE,  #< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
        AV_PIX_FMT_YUV444P16BE,  #< planar YUV 4:4:4, 48bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
        AV_PIX_FMT_VDPAU_MPEG4,  #< MPEG4 HW decoding with VDPAU, data[0] contains a vdpau_render_state struct which contains the bitstream of the slices as well as various fields extracted from headers
        AV_PIX_FMT_DXVA2_VLD,    #< HW decoding through DXVA2, Picture.data[3] contains a LPDIRECT3DSURFACE9 pointer

        AV_PIX_FMT_RGB444LE,  #< packed RGB 4:4:4, 16bpp, (msb)4A 4R 4G 4B(lsb), little-endian, most significant bits to 0
        AV_PIX_FMT_RGB444BE,  #< packed RGB 4:4:4, 16bpp, (msb)4A 4R 4G 4B(lsb), big-endian, most significant bits to 0
        AV_PIX_FMT_BGR444LE,  #< packed BGR 4:4:4, 16bpp, (msb)4A 4B 4G 4R(lsb), little-endian, most significant bits to 1
        AV_PIX_FMT_BGR444BE,  #< packed BGR 4:4:4, 16bpp, (msb)4A 4B 4G 4R(lsb), big-endian, most significant bits to 1
        AV_PIX_FMT_YA8,       #< 8bit gray, 8bit alpha

        AV_PIX_FMT_Y400A = AV_PIX_FMT_YA8, #< alias for AV_PIX_FMT_YA8
        AV_PIX_FMT_GRAY8A= AV_PIX_FMT_YA8, #< alias for AV_PIX_FMT_YA8

        AV_PIX_FMT_BGR48BE,   #< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as big-endian
        AV_PIX_FMT_BGR48LE,   #< packed RGB 16:16:16, 48bpp, 16B, 16G, 16R, the 2-byte value for each R/G/B component is stored as little-endian

        ##
        # The following 12 formats have the disadvantage of needing 1 format for each bit depth.
        # Notice that each 9/10 bits sample is stored in 16 bits with extra padding.
        # If you want to support multiple bit depths, then using AV_PIX_FMT_YUV420P16* with the bpp stored separately is better.
        ##
        AV_PIX_FMT_YUV420P9BE, #< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
        AV_PIX_FMT_YUV420P9LE, #< planar YUV 4:2:0, 13.5bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
        AV_PIX_FMT_YUV420P10BE,#< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
        AV_PIX_FMT_YUV420P10LE,#< planar YUV 4:2:0, 15bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
        AV_PIX_FMT_YUV422P10BE,#< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
        AV_PIX_FMT_YUV422P10LE,#< planar YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_YUV444P9BE, #< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
        AV_PIX_FMT_YUV444P9LE, #< planar YUV 4:4:4, 27bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
        AV_PIX_FMT_YUV444P10BE,#< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
        AV_PIX_FMT_YUV444P10LE,#< planar YUV 4:4:4, 30bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
        AV_PIX_FMT_YUV422P9BE, #< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
        AV_PIX_FMT_YUV422P9LE, #< planar YUV 4:2:2, 18bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_VDA_VLD,    #< hardware decoding through VDA

        AV_PIX_FMT_RGBA64BE,  #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_RGBA64LE,  #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
        AV_PIX_FMT_BGRA64BE,  #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_BGRA64LE,  #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
        AV_PIX_FMT_GBRP,      #< planar GBR 4:4:4 24bpp
        AV_PIX_FMT_GBRP9BE,   #< planar GBR 4:4:4 27bpp, big-endian
        AV_PIX_FMT_GBRP9LE,   #< planar GBR 4:4:4 27bpp, little-endian
        AV_PIX_FMT_GBRP10BE,  #< planar GBR 4:4:4 30bpp, big-endian
        AV_PIX_FMT_GBRP10LE,  #< planar GBR 4:4:4 30bpp, little-endian
        AV_PIX_FMT_GBRP16BE,  #< planar GBR 4:4:4 48bpp, big-endian
        AV_PIX_FMT_GBRP16LE,  #< planar GBR 4:4:4 48bpp, little-endian

        ##
        # duplicated pixel formats for compatibility with libav.
        # FFmpeg supports these formats since May 8 2012 and Jan 28 2012 (commits f9ca1ac7 and 143a5c55)
        # Libav added them Oct 12 2012 with incompatible values (commit 6d5600e85)
        ##
        AV_PIX_FMT_YUVA422P_LIBAV,  #< planar YUV 4:2:2 24bpp, (1 Cr & Cb sample per 2x1 Y & A samples)
        AV_PIX_FMT_YUVA444P_LIBAV,  #< planar YUV 4:4:4 32bpp, (1 Cr & Cb sample per 1x1 Y & A samples)

        AV_PIX_FMT_YUVA420P9BE,  #< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), big-endian
        AV_PIX_FMT_YUVA420P9LE,  #< planar YUV 4:2:0 22.5bpp, (1 Cr & Cb sample per 2x2 Y & A samples), little-endian
        AV_PIX_FMT_YUVA422P9BE,  #< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), big-endian
        AV_PIX_FMT_YUVA422P9LE,  #< planar YUV 4:2:2 27bpp, (1 Cr & Cb sample per 2x1 Y & A samples), little-endian
        AV_PIX_FMT_YUVA444P9BE,  #< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), big-endian
        AV_PIX_FMT_YUVA444P9LE,  #< planar YUV 4:4:4 36bpp, (1 Cr & Cb sample per 1x1 Y & A samples), little-endian
        AV_PIX_FMT_YUVA420P10BE, #< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA420P10LE, #< planar YUV 4:2:0 25bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
        AV_PIX_FMT_YUVA422P10BE, #< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA422P10LE, #< planar YUV 4:2:2 30bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
        AV_PIX_FMT_YUVA444P10BE, #< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA444P10LE, #< planar YUV 4:4:4 40bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)
        AV_PIX_FMT_YUVA420P16BE, #< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA420P16LE, #< planar YUV 4:2:0 40bpp, (1 Cr & Cb sample per 2x2 Y & A samples, little-endian)
        AV_PIX_FMT_YUVA422P16BE, #< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA422P16LE, #< planar YUV 4:2:2 48bpp, (1 Cr & Cb sample per 2x1 Y & A samples, little-endian)
        AV_PIX_FMT_YUVA444P16BE, #< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, big-endian)
        AV_PIX_FMT_YUVA444P16LE, #< planar YUV 4:4:4 64bpp, (1 Cr & Cb sample per 1x1 Y & A samples, little-endian)

        AV_PIX_FMT_VDPAU,     #< HW acceleration through VDPAU, Picture.data[3] contains a VdpVideoSurface

        AV_PIX_FMT_XYZ12LE,      #< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as little-endian, the 4 lower bits are set to 0
        AV_PIX_FMT_XYZ12BE,      #< packed XYZ 4:4:4, 36 bpp, (msb) 12X, 12Y, 12Z (lsb), the 2-byte value for each X/Y/Z is stored as big-endian, the 4 lower bits are set to 0
        AV_PIX_FMT_NV16,         #< interleaved chroma YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
        AV_PIX_FMT_NV20LE,       #< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_NV20BE,       #< interleaved chroma YUV 4:2:2, 20bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian

        ##
        # duplicated pixel formats for compatibility with libav.
        # FFmpeg supports these formats since Sat Sep 24 06:01:45 2011 +0200 (commits 9569a3c9f41387a8c7d1ce97d8693520477a66c3)
        # also see Fri Nov 25 01:38:21 2011 +0100 92afb431621c79155fcb7171d26f137eb1bee028
        # Libav added them Sun Mar 16 23:05:47 2014 +0100 with incompatible values (commit 1481d24c3a0abf81e1d7a514547bd5305232be30)
        ##
        AV_PIX_FMT_RGBA64BE_LIBAV,     #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_RGBA64LE_LIBAV,     #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
        AV_PIX_FMT_BGRA64BE_LIBAV,     #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_BGRA64LE_LIBAV,     #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian

        AV_PIX_FMT_YVYU422,   #< packed YUV 4:2:2, 16bpp, Y0 Cr Y1 Cb

        AV_PIX_FMT_VDA,          #< HW acceleration through VDA, data[3] contains a CVPixelBufferRef

        AV_PIX_FMT_YA16BE,       #< 16bit gray, 16bit alpha (big-endian)
        AV_PIX_FMT_YA16LE,       #< 16bit gray, 16bit alpha (little-endian)


        AV_PIX_FMT_RGBA64BE=0x123,  #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_RGBA64LE,  #< packed RGBA 16:16:16:16, 64bpp, 16R, 16G, 16B, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
        AV_PIX_FMT_BGRA64BE,  #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as big-endian
        AV_PIX_FMT_BGRA64LE,  #< packed RGBA 16:16:16:16, 64bpp, 16B, 16G, 16R, 16A, the 2-byte value for each R/G/B/A component is stored as little-endian
        AV_PIX_FMT_0RGB=0x123+4,      #< packed RGB 8:8:8, 32bpp, 0RGB0RGB...
        AV_PIX_FMT_RGB0,      #< packed RGB 8:8:8, 32bpp, RGB0RGB0...
        AV_PIX_FMT_0BGR,      #< packed BGR 8:8:8, 32bpp, 0BGR0BGR...
        AV_PIX_FMT_BGR0,      #< packed BGR 8:8:8, 32bpp, BGR0BGR0...
        AV_PIX_FMT_YUVA444P,  #< planar YUV 4:4:4 32bpp, (1 Cr & Cb sample per 1x1 Y & A samples)
        AV_PIX_FMT_YUVA422P,  #< planar YUV 4:2:2 24bpp, (1 Cr & Cb sample per 2x1 Y & A samples)

        AV_PIX_FMT_YUV420P12BE, #< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
        AV_PIX_FMT_YUV420P12LE, #< planar YUV 4:2:0,18bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
        AV_PIX_FMT_YUV420P14BE, #< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), big-endian
        AV_PIX_FMT_YUV420P14LE, #< planar YUV 4:2:0,21bpp, (1 Cr & Cb sample per 2x2 Y samples), little-endian
        AV_PIX_FMT_YUV422P12BE, #< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
        AV_PIX_FMT_YUV422P12LE, #< planar YUV 4:2:2,24bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_YUV422P14BE, #< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), big-endian
        AV_PIX_FMT_YUV422P14LE, #< planar YUV 4:2:2,28bpp, (1 Cr & Cb sample per 2x1 Y samples), little-endian
        AV_PIX_FMT_YUV444P12BE, #< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
        AV_PIX_FMT_YUV444P12LE, #< planar YUV 4:4:4,36bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
        AV_PIX_FMT_YUV444P14BE, #< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), big-endian
        AV_PIX_FMT_YUV444P14LE, #< planar YUV 4:4:4,42bpp, (1 Cr & Cb sample per 1x1 Y samples), little-endian
        AV_PIX_FMT_GBRP12BE,    #< planar GBR 4:4:4 36bpp, big-endian
        AV_PIX_FMT_GBRP12LE,    #< planar GBR 4:4:4 36bpp, little-endian
        AV_PIX_FMT_GBRP14BE,    #< planar GBR 4:4:4 42bpp, big-endian
        AV_PIX_FMT_GBRP14LE,    #< planar GBR 4:4:4 42bpp, little-endian
        AV_PIX_FMT_GBRAP,       #< planar GBRA 4:4:4:4 32bpp
        AV_PIX_FMT_GBRAP16BE,   #< planar GBRA 4:4:4:4 64bpp, big-endian
        AV_PIX_FMT_GBRAP16LE,   #< planar GBRA 4:4:4:4 64bpp, little-endian
        AV_PIX_FMT_YUVJ411P,    #< planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples) full scale (JPEG), deprecated in favor of PIX_FMT_YUV411P and setting color_range

        AV_PIX_FMT_BAYER_BGGR8,    #< bayer, BGBG..(odd line), GRGR..(even line), 8-bit samples */
        AV_PIX_FMT_BAYER_RGGB8,    #< bayer, RGRG..(odd line), GBGB..(even line), 8-bit samples */
        AV_PIX_FMT_BAYER_GBRG8,    #< bayer, GBGB..(odd line), RGRG..(even line), 8-bit samples */
        AV_PIX_FMT_BAYER_GRBG8,    #< bayer, GRGR..(odd line), BGBG..(even line), 8-bit samples */
        AV_PIX_FMT_BAYER_BGGR16LE, #< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, little-endian */
        AV_PIX_FMT_BAYER_BGGR16BE, #< bayer, BGBG..(odd line), GRGR..(even line), 16-bit samples, big-endian */
        AV_PIX_FMT_BAYER_RGGB16LE, #< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, little-endian */
        AV_PIX_FMT_BAYER_RGGB16BE, #< bayer, RGRG..(odd line), GBGB..(even line), 16-bit samples, big-endian */
        AV_PIX_FMT_BAYER_GBRG16LE, #< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, little-endian */
        AV_PIX_FMT_BAYER_GBRG16BE, #< bayer, GBGB..(odd line), RGRG..(even line), 16-bit samples, big-endian */
        AV_PIX_FMT_BAYER_GRBG16LE, #< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, little-endian */
        AV_PIX_FMT_BAYER_GRBG16BE, #< bayer, GRGR..(odd line), BGBG..(even line), 16-bit samples, big-endian */
        AV_PIX_FMT_XVMC,#< XVideo Motion Acceleration via common packet passing

        AV_PIX_FMT_NB,        #< number of pixel formats, DO NOT USE THIS if you want to link with shared libav* because the number of formats might differ between versions

    AVCodec *avcodec_find_decoder(int id)
    int avcodec_open2(AVCodecContext *avctx, AVCodec *codec, AVDictionary **options)
    int avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr, AVPacket *avpkt) nogil
    int avpicture_fill(AVPicture *picture, void *ptr, int pix_fmt, int width, int height) nogil
    AVFrame *av_frame_alloc()
    int avpicture_get_size(int pix_fmt, int width, int height)
    int avpicture_layout(AVPicture* src, int pix_fmt, int width, int height,
                     unsigned char *dest, int dest_size)
#    int img_convert(AVPicture *dst, int dst_pix_fmt,
#                AVPicture *src, int pix_fmt,
#                int width, int height)

    void avcodec_flush_buffers(AVCodecContext *avctx)
    int avcodec_close (AVCodecContext *avctx)
    
    void av_init_packet(AVPacket *pkt)
    
    void av_image_copy (uint8_t *dst_data[4], int dst_linesizes[4], 
                        const uint8_t *src_data[4], const int src_linesizes[4],  AVPixelFormat pix_fmt, int width, int height)

cdef extern from "libavformat/avformat.h":
    struct AVFrac:
        int64_t val, num, den

    void av_register_all()

    struct AVCodecParserContext:
        pass

    struct AVIndexEntry:
        pass

    struct AVStream:
        int index    #/* stream index in AVFormatContext */
        int id       #/* format specific stream id */
        AVCodecContext *codec #/* codec context */
        # real base frame rate of the stream.
        # for example if the timebase is 1/90000 and all frames have either
        # approximately 3600 or 1800 timer ticks then r_frame_rate will be 50/1
        AVRational r_frame_rate
        void *priv_data
        # internal data used in avformat_find_stream_info()
        int64_t codec_info_duration
        int codec_info_nb_frames
        # encoding: PTS generation when outputing stream
        AVFrac pts
        # this is the fundamental unit of time (in seconds) in terms
        # of which frame timestamps are represented. for fixed-fps content,
        # timebase should be 1/framerate and timestamp increments should be
        # identically 1.
        AVRational time_base
        int pts_wrap_bits # number of bits in pts (used for wrapping control)
        # ffmpeg.c private use
        int stream_copy   # if TRUE, just copy stream
        int discard       # < selects which packets can be discarded at will and dont need to be demuxed
        # FIXME move stuff to a flags field?
        # quality, as it has been removed from AVCodecContext and put in AVVideoFrame
        # MN:dunno if thats the right place, for it
        float quality
        # decoding: position of the first frame of the component, in
        # AV_TIME_BASE fractional seconds.
        int64_t start_time
        # decoding: duration of the stream, in AV_TIME_BASE fractional
        # seconds.
        int64_t duration
        char language[4] # ISO 639 3-letter language code (empty string if undefined)
        # av_read_frame() support
        int need_parsing                  # < 1->full parsing needed, 2->only parse headers dont repack
        AVCodecParserContext *parser
        int64_t cur_dts
        int last_IP_duration
        int64_t last_IP_pts
        # av_seek_frame() support
        AVIndexEntry *index_entries # only used if the format does not support seeking natively
        int nb_index_entries
        int index_entries_allocated_size
        int64_t nb_frames                 # < number of frames in this stream if known or 0

    struct ByteIOContext:
        pass

    struct AVInputFormat:
        pass

    struct AVFormatContext:
        int nb_streams
        AVStream **streams
        int64_t timestamp
        int64_t start_time
        AVStream *cur_st
        AVPacket cur_pkt
        ByteIOContext pb
        # decoding: total file size. 0 if unknown
        int64_t file_size
        int64_t duration
        # decoding: total stream bitrate in bit/s, 0 if not
        # available. Never set it directly if the file_size and the
        # duration are known as ffmpeg can compute it automatically. */
        int bit_rate
        # av_seek_frame() support
        int64_t data_offset    # offset of the first packet
        int index_built
        int flags

    int avformat_open_input(AVFormatContext **ic_ptr, char *filename,
                       AVInputFormat *fmt,
                       AVDictionary **options)
    int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options)

    void av_dump_format(AVFormatContext *ic,
                 int index,
                 char *url,
                 int is_output)
    void av_free_packet(AVPacket *pkt)
    int av_read_packet(AVFormatContext *s, AVPacket *pkt) nogil
    int av_read_frame(AVFormatContext *s, AVPacket *pkt) nogil
    int av_seek_frame(AVFormatContext *s, int stream_index, int64_t timestamp, int flags) nogil
    int av_seek_frame_binary(AVFormatContext *s, int stream_index, int64_t target_ts, int flags) nogil

    void av_parser_close(AVCodecParserContext *s)

    int av_index_search_timestamp(AVStream *st, int64_t timestamp, int flags)
    void avformat_close_input(AVFormatContext **s)

cdef extern from "libavformat/avio.h":
    int url_ferror(ByteIOContext *s)
    int url_feof(ByteIOContext *s)

cdef extern from "libswscale/swscale.h":
    int SWS_FAST_BILINEAR
    int SWS_BILINEAR
    int SWS_BICUBIC

    struct SwsVector:
        double *coeff
        int length

    struct SwsFilter:
        SwsVector *lumH
        SwsVector *lumV
        SwsVector *chrH
        SwsVector *chrV

    struct SwsContext:
        pass

    void sws_freeContext(SwsContext *swsContext) nogil

    SwsContext *sws_getContext(int srcW, int srcH, int srcFormat, int dstW, int dstH, int dstFormat, int flags,
                    SwsFilter *srcFilter, SwsFilter *dstFilter, double *param) nogil

    int sws_scale(SwsContext *context, uint8_t* src[], int srcStride[], int srcSliceY,
                    int srcSliceH, uint8_t* dst[], int dstStride[]) nogil

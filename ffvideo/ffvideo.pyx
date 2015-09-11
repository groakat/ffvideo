# ffvideo.pyx
#
# Copyright (C) 2009 Zakhar Zibarov <zakhar.zibarov@gmail.com>
# Copyright (C) 2006-2007 James Evans <jaevans@users.sf.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

from ffmpeg cimport *


import numpy
cimport numpy


cdef extern from "Python.h":
    object PyBuffer_New(int)
    object PyBuffer_FromObject(object, int, int)
    int PyObject_AsCharBuffer(object, char **, Py_ssize_t *) except -1

av_register_all()
av_log_set_level(AV_LOG_ERROR);

class FFVideoError(Exception):
    pass

class DecoderError(FFVideoError):
    pass

class FFVideoValueError(FFVideoError, ValueError):
    pass

class NoMoreData(StopIteration):
    pass

FAST_BILINEAR = SWS_FAST_BILINEAR
BILINEAR = SWS_BILINEAR
BICUBIC = SWS_BICUBIC

SEEK_BACKWARD = AVSEEK_FLAG_BACKWARD    #< seek backward
SEEK_BYTE = AVSEEK_FLAG_BYTE            #< seeking based on position in bytes
SEEK_ANY = AVSEEK_FLAG_ANY              #< seek to any frame, even non keyframes
SEEK_FRAME = AVSEEK_FLAG_FRAME          #< seeking based on frame number


FRAME_MODES = {
    'RGB': AV_PIX_FMT_RGB24,
    'L': AV_PIX_FMT_GRAY8,
    'YUV420P': AV_PIX_FMT_YUV420P
}

cdef class VideoStream:
    """Class represents video stream"""

    cdef AVFormatContext *format_ctx
    cdef AVCodecContext *codec_ctx
    cdef AVCodec *codec
    cdef AVPacket packet

    cdef int streamno
    cdef AVStream *stream

    cdef int frameno
    cdef AVFrame *frame
    cdef int64_t _frame_pts

    cdef int64_t last_pts
    cdef int64_t skipped_pts
    
    cdef uint8_t *video_dst_data[4]
    cdef int      video_dst_linesize[4]

    cdef object __frame_mode
    cdef int got_frame
    cdef int flushing_cache

    # public
    cdef readonly object filename
    cdef readonly object codec_name

    cdef readonly int bitrate # the average bitrate 
    cdef readonly double framerate
    cdef readonly double duration
    cdef readonly int width
    cdef readonly int height

    cdef readonly int frame_width
    cdef readonly int frame_height
    cdef readonly int frame_offset

    cdef public int scale_mode
    cdef public int seek_mode
    cdef public int exact_seek

    cdef public int ffmpeg_frame_mode

    property frame_mode:
        def __set__(self, mode):
            if mode not in FRAME_MODES:
                raise FFVideoValueError("Not supported frame mode")
            self.__frame_mode = mode
            self.ffmpeg_frame_mode = FRAME_MODES[mode]

        def __get__(self):
            return self.__frame_mode

    property frame_size:
        def __set__(self, size):
            try:
                fw, fh = size
            except (TypeError, ValueError), e:
                raise FFVideoValueError("frame_size must be a tuple (int, int)")
            if fw is None and fh is None:
                raise FFVideoValueError("both width and height cannot be None")

            if fw is None:
                self.frame_width = round(fh * <float>self.width / self.height / 2.0) * 2
                self.frame_height = round(fh / 2.0) * 2
            elif fh is None:
                self.frame_width = round(fw / 2.0) * 2
                self.frame_height = round(fw * <float>self.height / self.width / 2.0) * 2
            else:
                self.frame_width = round(fw / 2.0) * 2
                self.frame_height = round(fh / 2.0) * 2

        def __get__(self):
            return (self.frame_width, self.frame_height)

    def __cinit__(self, filename, frame_size=None, frame_mode='RGB',
                  scale_mode=BICUBIC, seek_mode=SEEK_BACKWARD, exact_seek=True):
        self.format_ctx = NULL
        self.codec_ctx = NULL
        self.frame = av_frame_alloc()
        self.duration = 0
        self.width = 0
        self.height = 0
        self.frameno = 0
        self.streamno = -1
        self.flushing_cache = 0
        self.last_pts = 0
        self.skipped_pts = 0
        #self.video_dst_data = {NULL}

    def __init__(self, filename, frame_size=None, frame_mode='RGB',
                 scale_mode=BICUBIC, seek_mode=SEEK_BACKWARD, exact_seek=True):
        cdef int ret
        cdef int i


        self.filename = filename

        self.frame_mode = frame_mode
        self.scale_mode = scale_mode
        self.seek_mode = seek_mode
        self.exact_seek = exact_seek
        self.frame_size = (-1,-1)

        self.got_frame = 0
        self.flushing_cache = 0
        self.last_pts = 0
        self.skipped_pts = 0
        
        self.initVideoStream()
        
    def initVideoStream(self):
        av_register_all()
        
        self.frame_offset = 0
        
        
        

        ret = avformat_open_input(&self.format_ctx, self.filename, NULL, NULL)
        if ret != 0:
            raise DecoderError("Unable to open file %s" % self.filename)

        ret = avformat_find_stream_info(self.format_ctx, NULL)
        if ret < 0:
            raise DecoderError("Unable to find stream info: %d" % ret)

        for i in xrange(self.format_ctx.nb_streams):
            if self.format_ctx.streams[i].codec.codec_type == AVMEDIA_TYPE_VIDEO:
                self.streamno = i
                break
        else:
            raise DecoderError("Unable to find video stream")

        self.stream = self.format_ctx.streams[self.streamno]
        self.codec_ctx = self.stream.codec
        
        # ret = av_image_alloc(video_dst_data, video_dst_linesize,
        #                     video_dec_ctx->width, video_dec_ctx->height,
        #                     video_dec_ctx->pix_fmt, 1);
        # ?
        
        self.frame = av_frame_alloc()
        
        av_init_packet(&self.packet)
        
        self.packet.data = NULL;
        self.packet.size = 0;
        self.got_frame = 0;
        
        
        
        
        
        self.framerate = av_q2d(self.stream.r_frame_rate)

        if self.stream.duration == 0 or self.stream.duration == AV_NOPTS_VALUE:
            self.duration = self.format_ctx.duration / <double>AV_TIME_BASE
        else:
            self.duration = self.stream.duration * av_q2d(self.stream.time_base)

        self.codec = avcodec_find_decoder(self.codec_ctx.codec_id)

        if self.codec == NULL:
            raise DecoderError("Unable to get decoder")

        if self.frame_mode in ('L', 'F'):
            self.codec_ctx.flags |= CODEC_FLAG_GRAY

        self.width = self.codec_ctx.width
        self.height = self.codec_ctx.height

        # Open codec
        ret = avcodec_open2(self.codec_ctx, self.codec, NULL)
        if ret < 0:
            raise DecoderError("Unable to open codec")

        # for some videos, avcodec_open2 will set these to 0,
        # so we'll only be using it if it is not 0, otherwise,
        # we rely on the resolution provided by the header;
        if self.codec_ctx.width != 0 and self.codec_ctx.height !=0:
            self.width = self.codec_ctx.width
            self.height = self.codec_ctx.height

        if self.width <= 0 or self.height <= 0:
            raise DecoderError("Video width/height is 0; cannot decode")

        #if self.frame_size is None:
        self.frame_size = (self.width, self.height)

        self.codec_name = self.codec.name
        self.bitrate = self.format_ctx.bit_rate

        # self.__decode_next_frame()

    def __dealloc__(self):
        # print "__dealloc__"
        if self.packet.data:
            av_free_packet(&self.packet)


        # print "__dealloc__ frame"
        av_free(self.frame)

        # print "__dealloc__ end frame"

        if self.codec:
            avcodec_close(self.codec_ctx)
            self.codec_ctx = NULL
        if self.format_ctx:
            avformat_close_input(&self.format_ctx)

        # print "end __dealloc__"

    def dump(self):
        print "max_b_frames=%s" % self.codec_ctx.max_b_frames
        av_log_set_level(AV_LOG_VERBOSE);
        av_dump_format(self.format_ctx, 0, self.filename, 0);
        av_log_set_level(AV_LOG_ERROR);

    def __decode_packet(self, int cached):        
        #print "__decode_packet"
        cdef int ret = 0
        cdef int decoded = self.packet.size
        self.got_frame = 0
        
        if self.packet.stream_index == self.streamno:
            #print "Enter loop"
            with nogil:
                ret = avcodec_decode_video2(self.codec_ctx, self.frame,
                                            &self.got_frame, &self.packet)
                                
            if self.got_frame:
                # av_image_copy is not necessary, but I left it in,
                # because it is in
                # https://www.ffmpeg.org/doxygen/2.1/doc_2examples_2demuxing_8c-example.html
                
                
                av_image_copy(self.video_dst_data, 
                            self.video_dst_linesize,
                            <const uint8_t **> self.frame.data, 
                            self.frame.linesize,
                            self.codec_ctx.pix_fmt, 
                            self.codec_ctx.width, 
                            self.codec_ctx.height)
                
                # print "ret top", ret
                # self.packet.data += ret #self.packet.size
                # print "packet size before decrement top", self.packet.size 
                # self.packet.size -= ret#self.packet.size
                
                #print "self.got_frame"
                #break

            
            # if ret <= 0:
            #     # 
            #     #print "ret <= 0"
            #     #break              
            #     pass
            # else:
            #     # getting over packages that are headers or something
            #     # like that.
            #     #print "else"
            #     self.frame_offset += 1
            #     print "ret", ret
            #     self.packet.data += self.packet.size
            #     print "packet size before decrement", self.packet.size 
            #     self.packet.size -= self.packet.size
                               
        return decoded
    
    def __decode_next_frame(self):
        cdef int ret
        cdef int frame_finished = 0
        cdef int64_t pts
        cdef AVPacket orig_pkt

        orig_pkt = self.packet  
        self.got_frame = 0
        self.last_pts = int(self.frame.pts)


        if not self.flushing_cache:
            if self.packet.size > 0:
                continue_decoding = 1
            else:
                continue_decoding = av_read_frame(self.format_ctx, &self.packet) >= 0


            if continue_decoding:

                while not self.got_frame:
                    ret = self.__decode_packet(0)

                    if not self.got_frame:
                        self.skipped_pts += av_rescale(1,
                                              self.stream.r_frame_rate.den*AV_TIME_BASE,
                                              self.stream.r_frame_rate.num)
                        if not av_read_frame(self.format_ctx, &self.packet) >= 0:
                            break

                if ret > 0:
                    self.packet.data += ret
                    self.packet.size -= ret

                    if self.packet.pts == AV_NOPTS_VALUE:
                        pts = self.packet.dts   
                    else:
                        pts = self.packet.pts

                    self.frame.pts = av_rescale_q(pts-self.stream.start_time,
                                                  self.stream.time_base, AV_TIME_BASE_Q) - \
                                     self.skipped_pts
                    # print 'pts middle', self.frame.pts
                    self.frame.display_picture_number = <int>av_q2d(
                        av_mul_q(av_mul_q(AVRational(pts - self.stream.start_time, 1),
                                          self.stream.r_frame_rate),
                                 self.stream.time_base)
                    )

                    self.last_pts = int(self.frame.pts)
                    av_free_packet(&orig_pkt)
                    return self.frame.pts
            
                else:# self.packet.size <= 0:
                    # av_free_packet(&orig_pkt)
                    pass

            # flush cached frames
            self.packet.data = NULL
            self.packet.size = 0;
            self.flushing_cache = 1

        self.__decode_packet(1)

        if not self.got_frame:
            av_free_packet(&orig_pkt)
            raise NoMoreData("Unable to read frame. Reached probably end of stream")

        else:
            if self.packet.pts == AV_NOPTS_VALUE:
                pts = self.packet.dts   
            else:
                pts = self.packet.pts

            if pts <= 0:
                pts  = self.last_pts + av_rescale(1,
                                      self.stream.r_frame_rate.den*AV_TIME_BASE,
                                      self.stream.r_frame_rate.num)

                self.frame.pts = pts
            else:
                self.frame.pts = av_rescale_q(pts-self.stream.start_time,
                                              self.stream.time_base, AV_TIME_BASE_Q) - \
                                 self.skipped_pts
                    
            self.frame.display_picture_number = <int>av_q2d(
                av_mul_q(av_mul_q(AVRational(pts - self.stream.start_time, 1),
                                  self.stream.r_frame_rate),
                         self.stream.time_base)
            )

            self.last_pts = int(self.frame.pts)
            av_free_packet(&orig_pkt)
            return self.frame.pts


   

    def dump_next_frame(self):
        pts = self.__decode_next_frame()
        print "pts=%d, frameno=%d" % (pts, self.frameno)
        print "f.pts=%s, " % (self.frame.pts,)
        print "codec_ctx.frame_number=%s" % self.codec_ctx.frame_number
        print "f.coded_picture_number=%s, f.display_picture_number=%s" % \
              (self.frame.coded_picture_number, self.frame.display_picture_number)

    def current(self):        

        #################
        # all of this method needs to go into the VideoFrame constructor, so that the 
        # scaled frame can be handled / freed by it rather than from the outside
        cdef AVFrame *scaled_frame
        cdef Py_ssize_t buflen
        cdef char *data_ptr
        cdef SwsContext *img_convert_ctx

        scaled_frame = av_frame_alloc()
        if scaled_frame == NULL:
            raise MemoryError("Unable to allocate new frame")

        buflen = avpicture_get_size(self.ffmpeg_frame_mode,
                                    self.frame_width, self.frame_height)
        data = PyBuffer_New(buflen)
        PyObject_AsCharBuffer(data, &data_ptr, &buflen)

        with nogil:
            avpicture_fill(<AVPicture *>scaled_frame, <uint8_t *>data_ptr,
                       self.ffmpeg_frame_mode, self.frame_width, self.frame_height)

            img_convert_ctx = sws_getContext(
                self.width, self.height, self.codec_ctx.pix_fmt,
                self.frame_width, self.frame_height, self.ffmpeg_frame_mode,
                self.scale_mode, NULL, NULL, NULL)
            
            sws_scale(img_convert_ctx,
                self.frame.data, self.frame.linesize, 0, self.height,
                scaled_frame.data, scaled_frame.linesize)

            sws_freeContext(img_convert_ctx)
            # av_free(scaled_frame)


        if self.frame_mode == 'RGB':
            shape = (self.height, self.width, 3)
        elif self.frame_mode == 'L':
            shape = (self.height, self.width)
        array = numpy.ndarray(buffer=data, dtype=numpy.uint8, shape=shape).copy()

        with nogil:            
            av_free(scaled_frame)

        vf = VideoFrame(array, self.frame_size, self.frame_mode,
                          timestamp=<double>self.frame.pts/<double>AV_TIME_BASE,
                          frameno=self.frame.display_picture_number)


        # with nogil:

        return vf


    def get_frame_no(self, frameno):
        cdef int64_t gpts = av_rescale(frameno,
                                      self.stream.r_frame_rate.den*AV_TIME_BASE,
                                      self.stream.r_frame_rate.num)
        return self.get_frame_at_pts(gpts)

    def get_frame_at_sec(self, float timestamp):
        return self.get_frame_at_pts(<int64_t>(timestamp * AV_TIME_BASE))

    def get_frame_at_pts(self, int64_t pts):
        av_free(self.frame)
        
        self.frame = av_frame_alloc()
        
        cdef int ret
        cdef int64_t stream_pts

        self.flushing_cache = 0
        self.skipped_pts = 0
        # print 'seek to pts:', pts

        stream_pts = av_rescale_q(pts, AV_TIME_BASE_Q, self.stream.time_base) + \
                    self.stream.start_time
        ret = av_seek_frame(self.format_ctx, self.streamno, stream_pts,
                            self.seek_mode)
        if ret < 0:
            raise FFVideoError("Unable to seek: %d" % ret)
        avcodec_flush_buffers(self.codec_ctx)

        # if we hurry it we can get bad frames later in the GOP
        # self.codec_ctx.skip_idct = AVDISCARD_BIDIR
        # self.codec_ctx.skip_frame = AVDISCARD_BIDIR

        # self.codec_ctx.hurry_up = 1
        hurried_frames = 0
        while self.__decode_next_frame() < pts:
            if self.frame.pts < 0:
                self.get_frame_at_pts(pts - av_rescale(1,
                                      self.stream.r_frame_rate.den*AV_TIME_BASE,
                                      self.stream.r_frame_rate.num))

        # self.codec_ctx.hurry_up = 0

        # self.codec_ctx.skip_idct = AVDISCARD_DEFAULT
        # self.codec_ctx.skip_frame = AVDISCARD_DEFAULT

        return self.current()

    def __iter__(self):
        # rewind
        self.flushing_cache = 0
        self.skipped_pts = 0


        # av_free(self.frame)

        ret = av_seek_frame(self.format_ctx, self.streamno,
                            self.stream.start_time, self.seek_mode)
        if ret < 0:
            raise FFVideoError("Unable to rewind: %d" % ret)
        avcodec_flush_buffers(self.codec_ctx)
        return self

    def __next__(self):
        try:
            ret = self.__decode_next_frame()
        except (NoMoreData), e:
            raise StopIteration(e)
                
        return self.current()

    def __getitem__(self, frameno):
        return self.get_frame_no(frameno)

    def __repr__(self):
        return "<VideoStream '%s':%.4f>" % (self.filename, <double>self.frame.pts/<double>AV_TIME_BASE)


cdef class VideoFrame:
    cdef readonly int width
    cdef readonly int height
    cdef readonly object size
    cdef readonly object mode

    cdef readonly int frameno
    cdef readonly double timestamp

    cdef numpy.ndarray array

    # cdef readonly object data


    def __init__(self, array, size, mode, timestamp=0, frameno=0):
        # self.data = data
        self.array = array
        self.width, self.height = size
        self.size = size
        self.mode = mode
        self.timestamp = timestamp
        self.frameno = frameno




    def set_data(self, data):
        self.data = data


    def __dealloc__(self):
        # av_free(self.scaled_frame)
        pass

    # def image(self):
    #     if self.mode not in ('RGB', 'L', 'F'):
    #         raise FFVideoError('Cannot represent this color mode into PIL Image')

    #     try:
    #         import Image
    #     except ImportError:
    #         from PIL import Image
    #     return Image.frombuffer(self.mode, self.size, self.data, 'raw', self.mode, 0, 1)
        # return 'lalala'

    def ndarray(self):
        if self.mode not in ('RGB', 'L'):
            raise FFVideoError('Cannot represent this color mode into PIL Image')

        return self.array
        # return "lalala"
        # import numpy
        # if self.mode == 'RGB':
        #     shape = (self.height, self.width, 3)
        # elif self.mode == 'L':
        #     shape = (self.height, self.width)
        # return numpy.ndarray(buffer=self.data, dtype=numpy.uint8, shape=shape)




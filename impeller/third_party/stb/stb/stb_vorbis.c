// Ogg Vorbis audio decoder - v1.09 - public domain
// http://nothings.org/stb_vorbis/
//
// Original version written by Sean Barrett in 2007.
//
// Originally sponsored by RAD Game Tools. Seeking sponsored
// by Phillip Bennefall, Marc Andersen, Aaron Baker, Elias Software,
// Aras Pranckevicius, and Sean Barrett.
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.
//
// No warranty for any purpose is expressed or implied by the author (nor
// by RAD Game Tools). Report bugs and send enhancements to the author.
//
// Limitations:
//
//   - floor 0 not supported (used in old ogg vorbis files pre-2004)
//   - lossless sample-truncation at beginning ignored
//   - cannot concatenate multiple vorbis streams
//   - sample positions are 32-bit, limiting seekable 192Khz
//       files to around 6 hours (Ogg supports 64-bit)
//
// Feature contributors:
//    Dougall Johnson (sample-exact seeking)
//
// Bugfix/warning contributors:
//    Terje Mathisen     Niklas Frykholm     Andy Hill
//    Casey Muratori     John Bolton         Gargaj
//    Laurent Gomila     Marc LeBlanc        Ronny Chevalier
//    Bernhard Wodo      Evan Balster        alxprd@github
//    Tom Beaumont       Ingo Leitgeb        Nicolas Guillemot
//    Phillip Bennefall  Rohit               Thiago Goulart
//    manxorist@github   saga musix
//
// Partial history:
//    1.09    - 2016/04/04 - back out 'truncation of last frame' fix from previous version
//    1.08    - 2016/04/02 - warnings; setup memory leaks; truncation of last frame
//    1.07    - 2015/01/16 - fixes for crashes on invalid files; warning fixes; const
//    1.06    - 2015/08/31 - full, correct support for seeking API (Dougall Johnson)
//                           some crash fixes when out of memory or with corrupt files
//                           fix some inappropriately signed shifts
//    1.05    - 2015/04/19 - don't define __forceinline if it's redundant
//    1.04    - 2014/08/27 - fix missing const-correct case in API
//    1.03    - 2014/08/07 - warning fixes
//    1.02    - 2014/07/09 - declare qsort comparison as explicitly _cdecl in Windows
//    1.01    - 2014/06/18 - fix stb_vorbis_get_samples_float (interleaved was correct)
//    1.0     - 2014/05/26 - fix memory leaks; fix warnings; fix bugs in >2-channel;
//                           (API change) report sample rate for decode-full-file funcs
//
// See end of file for full version history.


//////////////////////////////////////////////////////////////////////////////
//
//  HEADER BEGINS HERE
//

#ifndef STB_VORBIS_INCLUDE_STB_VORBIS_H
#define STB_VORBIS_INCLUDE_STB_VORBIS_H

#if defined(STB_VORBIS_NO_CRT) && !defined(STB_VORBIS_NO_STDIO)
#define STB_VORBIS_NO_STDIO 1
#endif

#ifndef STB_VORBIS_NO_STDIO
#include <stdio.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

///////////   THREAD SAFETY

// Individual stb_vorbis* handles are not thread-safe; you cannot decode from
// them from multiple threads at the same time. However, you can have multiple
// stb_vorbis* handles and decode from them independently in multiple thrads.


///////////   MEMORY ALLOCATION

// normally stb_vorbis uses malloc() to allocate memory at startup,
// and alloca() to allocate temporary memory during a frame on the
// stack. (Memory consumption will depend on the amount of setup
// data in the file and how you set the compile flags for speed
// vs. size. In my test files the maximal-size usage is ~150KB.)
//
// You can modify the wrapper functions in the source (setup_malloc,
// setup_temp_malloc, temp_malloc) to change this behavior, or you
// can use a simpler allocation model: you pass in a buffer from
// which stb_vorbis will allocate _all_ its memory (including the
// temp memory). "open" may fail with a VORBIS_outofmem if you
// do not pass in enough data; there is no way to determine how
// much you do need except to succeed (at which point you can
// query get_info to find the exact amount required. yes I know
// this is lame).
//
// If you pass in a non-NULL buffer of the type below, allocation
// will occur from it as described above. Otherwise just pass NULL
// to use malloc()/alloca()

typedef struct
{
   char *alloc_buffer;
   int   alloc_buffer_length_in_bytes;
} stb_vorbis_alloc;


///////////   FUNCTIONS USEABLE WITH ALL INPUT MODES

typedef struct stb_vorbis stb_vorbis;

typedef struct
{
   unsigned int sample_rate;
   int channels;

   unsigned int setup_memory_required;
   unsigned int setup_temp_memory_required;
   unsigned int temp_memory_required;

   int max_frame_size;
} stb_vorbis_info;

// get general information about the file
extern stb_vorbis_info stb_vorbis_get_info(stb_vorbis *f);

// get the last error detected (clears it, too)
extern int stb_vorbis_get_error(stb_vorbis *f);

// close an ogg vorbis file and free all memory in use
extern void stb_vorbis_close(stb_vorbis *f);

// this function returns the offset (in samples) from the beginning of the
// file that will be returned by the next decode, if it is known, or -1
// otherwise. after a flush_pushdata() call, this may take a while before
// it becomes valid again.
// NOT WORKING YET after a seek with PULLDATA API
extern int stb_vorbis_get_sample_offset(stb_vorbis *f);

// returns the current seek point within the file, or offset from the beginning
// of the memory buffer. In pushdata mode it returns 0.
extern unsigned int stb_vorbis_get_file_offset(stb_vorbis *f);

///////////   PUSHDATA API

#ifndef STB_VORBIS_NO_PUSHDATA_API

// this API allows you to get blocks of data from any source and hand
// them to stb_vorbis. you have to buffer them; stb_vorbis will tell
// you how much it used, and you have to give it the rest next time;
// and stb_vorbis may not have enough data to work with and you will
// need to give it the same data again PLUS more. Note that the Vorbis
// specification does not bound the size of an individual frame.

extern stb_vorbis *stb_vorbis_open_pushdata(
         const unsigned char * datablock, int datablock_length_in_bytes,
         int *datablock_memory_consumed_in_bytes,
         int *error,
         const stb_vorbis_alloc *alloc_buffer);
// create a vorbis decoder by passing in the initial data block containing
//    the ogg&vorbis headers (you don't need to do parse them, just provide
//    the first N bytes of the file--you're told if it's not enough, see below)
// on success, returns an stb_vorbis *, does not set error, returns the amount of
//    data parsed/consumed on this call in *datablock_memory_consumed_in_bytes;
// on failure, returns NULL on error and sets *error, does not change *datablock_memory_consumed
// if returns NULL and *error is VORBIS_need_more_data, then the input block was
//       incomplete and you need to pass in a larger block from the start of the file

extern int stb_vorbis_decode_frame_pushdata(
         stb_vorbis *f,
         const unsigned char *datablock, int datablock_length_in_bytes,
         int *channels,             // place to write number of float * buffers
         float ***output,           // place to write float ** array of float * buffers
         int *samples               // place to write number of output samples
     );
// decode a frame of audio sample data if possible from the passed-in data block
//
// return value: number of bytes we used from datablock
//
// possible cases:
//     0 bytes used, 0 samples output (need more data)
//     N bytes used, 0 samples output (resynching the stream, keep going)
//     N bytes used, M samples output (one frame of data)
// note that after opening a file, you will ALWAYS get one N-bytes,0-sample
// frame, because Vorbis always "discards" the first frame.
//
// Note that on resynch, stb_vorbis will rarely consume all of the buffer,
// instead only datablock_length_in_bytes-3 or less. This is because it wants
// to avoid missing parts of a page header if they cross a datablock boundary,
// without writing state-machiney code to record a partial detection.
//
// The number of channels returned are stored in *channels (which can be
// NULL--it is always the same as the number of channels reported by
// get_info). *output will contain an array of float* buffers, one per
// channel. In other words, (*output)[0][0] contains the first sample from
// the first channel, and (*output)[1][0] contains the first sample from
// the second channel.

extern void stb_vorbis_flush_pushdata(stb_vorbis *f);
// inform stb_vorbis that your next datablock will not be contiguous with
// previous ones (e.g. you've seeked in the data); future attempts to decode
// frames will cause stb_vorbis to resynchronize (as noted above), and
// once it sees a valid Ogg page (typically 4-8KB, as large as 64KB), it
// will begin decoding the _next_ frame.
//
// if you want to seek using pushdata, you need to seek in your file, then
// call stb_vorbis_flush_pushdata(), then start calling decoding, then once
// decoding is returning you data, call stb_vorbis_get_sample_offset, and
// if you don't like the result, seek your file again and repeat.
#endif


//////////   PULLING INPUT API

#ifndef STB_VORBIS_NO_PULLDATA_API
// This API assumes stb_vorbis is allowed to pull data from a source--
// either a block of memory containing the _entire_ vorbis stream, or a
// FILE * that you or it create, or possibly some other reading mechanism
// if you go modify the source to replace the FILE * case with some kind
// of callback to your code. (But if you don't support seeking, you may
// just want to go ahead and use pushdata.)

#if !defined(STB_VORBIS_NO_STDIO) && !defined(STB_VORBIS_NO_INTEGER_CONVERSION)
extern int stb_vorbis_decode_filename(const char *filename, int *channels, int *sample_rate, short **output);
#endif
#if !defined(STB_VORBIS_NO_INTEGER_CONVERSION)
extern int stb_vorbis_decode_memory(const unsigned char *mem, int len, int *channels, int *sample_rate, short **output);
#endif
// decode an entire file and output the data interleaved into a malloc()ed
// buffer stored in *output. The return value is the number of samples
// decoded, or -1 if the file could not be opened or was not an ogg vorbis file.
// When you're done with it, just free() the pointer returned in *output.

extern stb_vorbis * stb_vorbis_open_memory(const unsigned char *data, int len,
                                  int *error, const stb_vorbis_alloc *alloc_buffer);
// create an ogg vorbis decoder from an ogg vorbis stream in memory (note
// this must be the entire stream!). on failure, returns NULL and sets *error

#ifndef STB_VORBIS_NO_STDIO
extern stb_vorbis * stb_vorbis_open_filename(const char *filename,
                                  int *error, const stb_vorbis_alloc *alloc_buffer);
// create an ogg vorbis decoder from a filename via fopen(). on failure,
// returns NULL and sets *error (possibly to VORBIS_file_open_failure).

extern stb_vorbis * stb_vorbis_open_file(FILE *f, int close_handle_on_close,
                                  int *error, const stb_vorbis_alloc *alloc_buffer);
// create an ogg vorbis decoder from an open FILE *, looking for a stream at
// the _current_ seek point (ftell). on failure, returns NULL and sets *error.
// note that stb_vorbis must "own" this stream; if you seek it in between
// calls to stb_vorbis, it will become confused. Morever, if you attempt to
// perform stb_vorbis_seek_*() operations on this file, it will assume it
// owns the _entire_ rest of the file after the start point. Use the next
// function, stb_vorbis_open_file_section(), to limit it.

extern stb_vorbis * stb_vorbis_open_file_section(FILE *f, int close_handle_on_close,
                int *error, const stb_vorbis_alloc *alloc_buffer, unsigned int len);
// create an ogg vorbis decoder from an open FILE *, looking for a stream at
// the _current_ seek point (ftell); the stream will be of length 'len' bytes.
// on failure, returns NULL and sets *error. note that stb_vorbis must "own"
// this stream; if you seek it in between calls to stb_vorbis, it will become
// confused.
#endif

extern int stb_vorbis_seek_frame(stb_vorbis *f, unsigned int sample_number);
extern int stb_vorbis_seek(stb_vorbis *f, unsigned int sample_number);
// these functions seek in the Vorbis file to (approximately) 'sample_number'.
// after calling seek_frame(), the next call to get_frame_*() will include
// the specified sample. after calling stb_vorbis_seek(), the next call to
// stb_vorbis_get_samples_* will start with the specified sample. If you
// do not need to seek to EXACTLY the target sample when using get_samples_*,
// you can also use seek_frame().

extern void stb_vorbis_seek_start(stb_vorbis *f);
// this function is equivalent to stb_vorbis_seek(f,0)

extern unsigned int stb_vorbis_stream_length_in_samples(stb_vorbis *f);
extern float        stb_vorbis_stream_length_in_seconds(stb_vorbis *f);
// these functions return the total length of the vorbis stream

extern int stb_vorbis_get_frame_float(stb_vorbis *f, int *channels, float ***output);
// decode the next frame and return the number of samples. the number of
// channels returned are stored in *channels (which can be NULL--it is always
// the same as the number of channels reported by get_info). *output will
// contain an array of float* buffers, one per channel. These outputs will
// be overwritten on the next call to stb_vorbis_get_frame_*.
//
// You generally should not intermix calls to stb_vorbis_get_frame_*()
// and stb_vorbis_get_samples_*(), since the latter calls the former.

#ifndef STB_VORBIS_NO_INTEGER_CONVERSION
extern int stb_vorbis_get_frame_short_interleaved(stb_vorbis *f, int num_c, short *buffer, int num_shorts);
extern int stb_vorbis_get_frame_short            (stb_vorbis *f, int num_c, short **buffer, int num_samples);
#endif
// decode the next frame and return the number of *samples* per channel.
// Note that for interleaved data, you pass in the number of shorts (the
// size of your array), but the return value is the number of samples per
// channel, not the total number of samples.
//
// The data is coerced to the number of channels you request according to the
// channel coercion rules (see below). You must pass in the size of your
// buffer(s) so that stb_vorbis will not overwrite the end of the buffer.
// The maximum buffer size needed can be gotten from get_info(); however,
// the Vorbis I specification implies an absolute maximum of 4096 samples
// per channel.

// Channel coercion rules:
//    Let M be the number of channels requested, and N the number of channels present,
//    and Cn be the nth channel; let stereo L be the sum of all L and center channels,
//    and stereo R be the sum of all R and center channels (channel assignment from the
//    vorbis spec).
//        M    N       output
//        1    k      sum(Ck) for all k
//        2    *      stereo L, stereo R
//        k    l      k > l, the first l channels, then 0s
//        k    l      k <= l, the first k channels
//    Note that this is not _good_ surround etc. mixing at all! It's just so
//    you get something useful.

extern int stb_vorbis_get_samples_float_interleaved(stb_vorbis *f, int channels, float *buffer, int num_floats);
extern int stb_vorbis_get_samples_float(stb_vorbis *f, int channels, float **buffer, int num_samples);
// gets num_samples samples, not necessarily on a frame boundary--this requires
// buffering so you have to supply the buffers. DOES NOT APPLY THE COERCION RULES.
// Returns the number of samples stored per channel; it may be less than requested
// at the end of the file. If there are no more samples in the file, returns 0.

#ifndef STB_VORBIS_NO_INTEGER_CONVERSION
extern int stb_vorbis_get_samples_short_interleaved(stb_vorbis *f, int channels, short *buffer, int num_shorts);
extern int stb_vorbis_get_samples_short(stb_vorbis *f, int channels, short **buffer, int num_samples);
#endif
// gets num_samples samples, not necessarily on a frame boundary--this requires
// buffering so you have to supply the buffers. Applies the coercion rules above
// to produce 'channels' channels. Returns the number of samples stored per channel;
// it may be less than requested at the end of the file. If there are no more
// samples in the file, returns 0.

#endif

////////   ERROR CODES

enum STBVorbisError
{
   VORBIS__no_error,

   VORBIS_need_more_data=1,             // not a real error

   VORBIS_invalid_api_mixing,           // can't mix API modes
   VORBIS_outofmem,                     // not enough memory
   VORBIS_feature_not_supported,        // uses floor 0
   VORBIS_too_many_channels,            // STB_VORBIS_MAX_CHANNELS is too small
   VORBIS_file_open_failure,            // fopen() failed
   VORBIS_seek_without_length,          // can't seek in unknown-length file

   VORBIS_unexpected_eof=10,            // file is truncated?
   VORBIS_seek_invalid,                 // seek past EOF

   // decoding errors (corrupt/invalid stream) -- you probably
   // don't care about the exact details of these

   // vorbis errors:
   VORBIS_invalid_setup=20,
   VORBIS_invalid_stream,

   // ogg errors:
   VORBIS_missing_capture_pattern=30,
   VORBIS_invalid_stream_structure_version,
   VORBIS_continued_packet_flag_invalid,
   VORBIS_incorrect_stream_serial_number,
   VORBIS_invalid_first_page,
   VORBIS_bad_packet_type,
   VORBIS_cant_find_last_page,
   VORBIS_seek_failed
};


#ifdef __cplusplus
}
#endif

#endif // STB_VORBIS_INCLUDE_STB_VORBIS_H
//
//  HEADER ENDS HERE
//
//////////////////////////////////////////////////////////////////////////////

#ifndef STB_VORBIS_HEADER_ONLY

// global configuration settings (e.g. set these in the project/makefile),
// or just set them in this file at the top (although ideally the first few
// should be visible when the header file is compiled too, although it's not
// crucial)

// STB_VORBIS_NO_PUSHDATA_API
//     does not compile the code for the various stb_vorbis_*_pushdata()
//     functions
// #define STB_VORBIS_NO_PUSHDATA_API

// STB_VORBIS_NO_PULLDATA_API
//     does not compile the code for the non-pushdata APIs
// #define STB_VORBIS_NO_PULLDATA_API

// STB_VORBIS_NO_STDIO
//     does not compile the code for the APIs that use FILE *s internally
//     or externally (implied by STB_VORBIS_NO_PULLDATA_API)
// #define STB_VORBIS_NO_STDIO

// STB_VORBIS_NO_INTEGER_CONVERSION
//     does not compile the code for converting audio sample data from
//     float to integer (implied by STB_VORBIS_NO_PULLDATA_API)
// #define STB_VORBIS_NO_INTEGER_CONVERSION

// STB_VORBIS_NO_FAST_SCALED_FLOAT
//      does not use a fast float-to-int trick to accelerate float-to-int on
//      most platforms which requires endianness be defined correctly.
//#define STB_VORBIS_NO_FAST_SCALED_FLOAT


// STB_VORBIS_MAX_CHANNELS [number]
//     globally define this to the maximum number of channels you need.
//     The spec does not put a restriction on channels except that
//     the count is stored in a byte, so 255 is the hard limit.
//     Reducing this saves about 16 bytes per value, so using 16 saves
//     (255-16)*16 or around 4KB. Plus anything other memory usage
//     I forgot to account for. Can probably go as low as 8 (7.1 audio),
//     6 (5.1 audio), or 2 (stereo only).
#ifndef STB_VORBIS_MAX_CHANNELS
#define STB_VORBIS_MAX_CHANNELS    16  // enough for anyone?
#endif

// STB_VORBIS_PUSHDATA_CRC_COUNT [number]
//     after a flush_pushdata(), stb_vorbis begins scanning for the
//     next valid page, without backtracking. when it finds something
//     that looks like a page, it streams through it and verifies its
//     CRC32. Should that validation fail, it keeps scanning. But it's
//     possible that _while_ streaming through to check the CRC32 of
//     one candidate page, it sees another candidate page. This #define
//     determines how many "overlapping" candidate pages it can search
//     at once. Note that "real" pages are typically ~4KB to ~8KB, whereas
//     garbage pages could be as big as 64KB, but probably average ~16KB.
//     So don't hose ourselves by scanning an apparent 64KB page and
//     missing a ton of real ones in the interim; so minimum of 2
#ifndef STB_VORBIS_PUSHDATA_CRC_COUNT
#define STB_VORBIS_PUSHDATA_CRC_COUNT  4
#endif

// STB_VORBIS_FAST_HUFFMAN_LENGTH [number]
//     sets the log size of the huffman-acceleration table.  Maximum
//     supported value is 24. with larger numbers, more decodings are O(1),
//     but the table size is larger so worse cache missing, so you'll have
//     to probe (and try multiple ogg vorbis files) to find the sweet spot.
#ifndef STB_VORBIS_FAST_HUFFMAN_LENGTH
#define STB_VORBIS_FAST_HUFFMAN_LENGTH   10
#endif

// STB_VORBIS_FAST_BINARY_LENGTH [number]
//     sets the log size of the binary-search acceleration table. this
//     is used in similar fashion to the fast-huffman size to set initial
//     parameters for the binary search

// STB_VORBIS_FAST_HUFFMAN_INT
//     The fast huffman tables are much more efficient if they can be
//     stored as 16-bit results instead of 32-bit results. This restricts
//     the codebooks to having only 65535 possible outcomes, though.
//     (At least, accelerated by the huffman table.)
#ifndef STB_VORBIS_FAST_HUFFMAN_INT
#define STB_VORBIS_FAST_HUFFMAN_SHORT
#endif

// STB_VORBIS_NO_HUFFMAN_BINARY_SEARCH
//     If the 'fast huffman' search doesn't succeed, then stb_vorbis falls
//     back on binary searching for the correct one. This requires storing
//     extra tables with the huffman codes in sorted order. Defining this
//     symbol trades off space for speed by forcing a linear search in the
//     non-fast case, except for "sparse" codebooks.
// #define STB_VORBIS_NO_HUFFMAN_BINARY_SEARCH

// STB_VORBIS_DIVIDES_IN_RESIDUE
//     stb_vorbis precomputes the result of the scalar residue decoding
//     that would otherwise require a divide per chunk. you can trade off
//     space for time by defining this symbol.
// #define STB_VORBIS_DIVIDES_IN_RESIDUE

// STB_VORBIS_DIVIDES_IN_CODEBOOK
//     vorbis VQ codebooks can be encoded two ways: with every case explicitly
//     stored, or with all elements being chosen from a small range of values,
//     and all values possible in all elements. By default, stb_vorbis expands
//     this latter kind out to look like the former kind for ease of decoding,
//     because otherwise an integer divide-per-vector-element is required to
//     unpack the index. If you define STB_VORBIS_DIVIDES_IN_CODEBOOK, you can
//     trade off storage for speed.
//#define STB_VORBIS_DIVIDES_IN_CODEBOOK

#ifdef STB_VORBIS_CODEBOOK_SHORTS
#error "STB_VORBIS_CODEBOOK_SHORTS is no longer supported as it produced incorrect results for some input formats"
#endif

// STB_VORBIS_DIVIDE_TABLE
//     this replaces small integer divides in the floor decode loop with
//     table lookups. made less than 1% difference, so disabled by default.

// STB_VORBIS_NO_INLINE_DECODE
//     disables the inlining of the scalar codebook fast-huffman decode.
//     might save a little codespace; useful for debugging
// #define STB_VORBIS_NO_INLINE_DECODE

// STB_VORBIS_NO_DEFER_FLOOR
//     Normally we only decode the floor without synthesizing the actual
//     full curve. We can instead synthesize the curve immediately. This
//     requires more memory and is very likely slower, so I don't think
//     you'd ever want to do it except for debugging.
// #define STB_VORBIS_NO_DEFER_FLOOR




//////////////////////////////////////////////////////////////////////////////

#ifdef STB_VORBIS_NO_PULLDATA_API
   #define STB_VORBIS_NO_INTEGER_CONVERSION
   #define STB_VORBIS_NO_STDIO
#endif

#if defined(STB_VORBIS_NO_CRT) && !defined(STB_VORBIS_NO_STDIO)
   #define STB_VORBIS_NO_STDIO 1
#endif

#ifndef STB_VORBIS_NO_INTEGER_CONVERSION
#ifndef STB_VORBIS_NO_FAST_SCALED_FLOAT

   // only need endianness for fast-float-to-int, which we don't
   // use for pushdata

   #ifndef STB_VORBIS_BIG_ENDIAN
     #define STB_VORBIS_ENDIAN  0
   #else
     #define STB_VORBIS_ENDIAN  1
   #endif

#endif
#endif


#ifndef STB_VORBIS_NO_STDIO
#include <stdio.h>
#endif

#ifndef STB_VORBIS_NO_CRT
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#if !(defined(__APPLE__) || defined(MACOSX) || defined(macintosh) || defined(Macintosh))
#include <malloc.h>
#if defined(__linux__) || defined(__linux) || defined(__EMSCRIPTEN__)
#include <alloca.h>
#endif
#endif
#else // STB_VORBIS_NO_CRT
#define NULL 0
#define malloc(s)   0
#define free(s)     ((void) 0)
#define realloc(s)  0
#endif // STB_VORBIS_NO_CRT

#include <limits.h>

#ifdef __MINGW32__
   // eff you mingw:
   //     "fixed":
   //         http://sourceforge.net/p/mingw-w64/mailman/message/32882927/
   //     "no that broke the build, reverted, who cares about C":
   //         http://sourceforge.net/p/mingw-w64/mailman/message/32890381/
   #ifdef __forceinline
   #undef __forceinline
   #endif
   #define __forceinline
#elif !defined(_MSC_VER)
   #if __GNUC__
      #define __forceinline inline
   #else
      #define __forceinline
   #endif
#endif

#if STB_VORBIS_MAX_CHANNELS > 256
#error "Value of STB_VORBIS_MAX_CHANNELS outside of allowed range"
#endif

#if STB_VORBIS_FAST_HUFFMAN_LENGTH > 24
#error "Value of STB_VORBIS_FAST_HUFFMAN_LENGTH outside of allowed range"
#endif


#if 0
#include <crtdbg.h>
#define CHECK(f)   _CrtIsValidHeapPointer(f->channel_buffers[1])
#else
#define CHECK(f)   ((void) 0)
#endif

#define MAX_BLOCKSIZE_LOG  13   // from specification
#define MAX_BLOCKSIZE      (1 << MAX_BLOCKSIZE_LOG)


typedef unsigned char  uint8;
typedef   signed char   int8;
typedef unsigned short uint16;
typedef   signed short  int16;
typedef unsigned int   uint32;
typedef   signed int    int32;

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

typedef float codetype;

// @NOTE
//
// Some arrays below are tagged "//varies", which means it's actually
// a variable-sized piece of data, but rather than malloc I assume it's
// small enough it's better to just allocate it all together with the
// main thing
//
// Most of the variables are specified with the smallest size I could pack
// them into. It might give better performance to make them all full-sized
// integers. It should be safe to freely rearrange the structures or change
// the sizes larger--nothing relies on silently truncating etc., nor the
// order of variables.

#define FAST_HUFFMAN_TABLE_SIZE   (1 << STB_VORBIS_FAST_HUFFMAN_LENGTH)
#define FAST_HUFFMAN_TABLE_MASK   (FAST_HUFFMAN_TABLE_SIZE - 1)

typedef struct
{
   int dimensions, entries;
   uint8 *codeword_lengths;
   float  minimum_value;
   float  delta_value;
   uint8  value_bits;
   uint8  lookup_type;
   uint8  sequence_p;
   uint8  sparse;
   uint32 lookup_values;
   codetype *multiplicands;
   uint32 *codewords;
   #ifdef STB_VORBIS_FAST_HUFFMAN_SHORT
    int16  fast_huffman[FAST_HUFFMAN_TABLE_SIZE];
   #else
    int32  fast_huffman[FAST_HUFFMAN_TABLE_SIZE];
   #endif
   uint32 *sorted_codewords;
   int    *sorted_values;
   int     sorted_entries;
} Codebook;

typedef struct
{
   uint8 order;
   uint16 rate;
   uint16 bark_map_size;
   uint8 amplitude_bits;
   uint8 amplitude_offset;
   uint8 number_of_books;
   uint8 book_list[16]; // varies
} Floor0;

typedef struct
{
   uint8 partitions;
   uint8 partition_class_list[32]; // varies
   uint8 class_dimensions[16]; // varies
   uint8 class_subclasses[16]; // varies
   uint8 class_masterbooks[16]; // varies
   int16 subclass_books[16][8]; // varies
   uint16 Xlist[31*8+2]; // varies
   uint8 sorted_order[31*8+2];
   uint8 neighbors[31*8+2][2];
   uint8 floor1_multiplier;
   uint8 rangebits;
   int values;
} Floor1;

typedef union
{
   Floor0 floor0;
   Floor1 floor1;
} Floor;

typedef struct
{
   uint32 begin, end;
   uint32 part_size;
   uint8 classifications;
   uint8 classbook;
   uint8 **classdata;
   int16 (*residue_books)[8];
} Residue;

typedef struct
{
   uint8 magnitude;
   uint8 angle;
   uint8 mux;
} MappingChannel;

typedef struct
{
   uint16 coupling_steps;
   MappingChannel *chan;
   uint8  submaps;
   uint8  submap_floor[15]; // varies
   uint8  submap_residue[15]; // varies
} Mapping;

typedef struct
{
   uint8 blockflag;
   uint8 mapping;
   uint16 windowtype;
   uint16 transformtype;
} Mode;

typedef struct
{
   uint32  goal_crc;    // expected crc if match
   int     bytes_left;  // bytes left in packet
   uint32  crc_so_far;  // running crc
   int     bytes_done;  // bytes processed in _current_ chunk
   uint32  sample_loc;  // granule pos encoded in page
} CRCscan;

typedef struct
{
   uint32 page_start, page_end;
   uint32 last_decoded_sample;
} ProbedPage;

struct stb_vorbis
{
  // user-accessible info
   unsigned int sample_rate;
   int channels;

   unsigned int setup_memory_required;
   unsigned int temp_memory_required;
   unsigned int setup_temp_memory_required;

  // input config
#ifndef STB_VORBIS_NO_STDIO
   FILE *f;
   uint32 f_start;
   int close_on_free;
#endif

   uint8 *stream;
   uint8 *stream_start;
   uint8 *stream_end;

   uint32 stream_len;

   uint8  push_mode;

   uint32 first_audio_page_offset;

   ProbedPage p_first, p_last;

  // memory management
   stb_vorbis_alloc alloc;
   int setup_offset;
   int temp_offset;

  // run-time results
   int eof;
   enum STBVorbisError error;

  // user-useful data

  // header info
   int blocksize[2];
   int blocksize_0, blocksize_1;
   int codebook_count;
   Codebook *codebooks;
   int floor_count;
   uint16 floor_types[64]; // varies
   Floor *floor_config;
   int residue_count;
   uint16 residue_types[64]; // varies
   Residue *residue_config;
   int mapping_count;
   Mapping *mapping;
   int mode_count;
   Mode mode_config[64];  // varies

   uint32 total_samples;

  // decode buffer
   float *channel_buffers[STB_VORBIS_MAX_CHANNELS];
   float *outputs        [STB_VORBIS_MAX_CHANNELS];

   float *previous_window[STB_VORBIS_MAX_CHANNELS];
   int previous_length;

   #ifndef STB_VORBIS_NO_DEFER_FLOOR
   int16 *finalY[STB_VORBIS_MAX_CHANNELS];
   #else
   float *floor_buffers[STB_VORBIS_MAX_CHANNELS];
   #endif

   uint32 current_loc; // sample location of next frame to decode
   int    current_loc_valid;

  // per-blocksize precomputed data
   
   // twiddle factors
   float *A[2],*B[2],*C[2];
   float *window[2];
   uint16 *bit_reverse[2];

  // current page/packet/segment streaming info
   uint32 serial; // stream serial number for verification
   int last_page;
   int segment_count;
   uint8 segments[255];
   uint8 page_flag;
   uint8 bytes_in_seg;
   uint8 first_decode;
   int next_seg;
   int last_seg;  // flag that we're on the last segment
   int last_seg_which; // what was the segment number of the last seg?
   uint32 acc;
   int valid_bits;
   int packet_bytes;
   int end_seg_with_known_loc;
   uint32 known_loc_for_packet;
   int discard_samples_deferred;
   uint32 samples_output;

  // push mode scanning
   int page_crc_tests; // only in push_mode: number of tests active; -1 if not searching
#ifndef STB_VORBIS_NO_PUSHDATA_API
   CRCscan scan[STB_VORBIS_PUSHDATA_CRC_COUNT];
#endif

  // sample-access
   int channel_buffer_start;
   int channel_buffer_end;
};

#if defined(STB_VORBIS_NO_PUSHDATA_API)
   #define IS_PUSH_MODE(f)   FALSE
#elif defined(STB_VORBIS_NO_PULLDATA_API)
   #define IS_PUSH_MODE(f)   TRUE
#else
   #define IS_PUSH_MODE(f)   ((f)->push_mode)
#endif

typedef struct stb_vorbis vorb;

static int error(vorb *f, enum STBVorbisError e)
{
   f->error = e;
   if (!f->eof && e != VORBIS_need_more_data) {
      f->error=e; // breakpoint for debugging
   }
   return 0;
}


// these functions are used for allocating temporary memory
// while decoding. if you can afford the stack space, use
// alloca(); otherwise, provide a temp buffer and it will
// allocate out of those.

#define array_size_required(count,size)  (count*(sizeof(void *)+(size)))

#define temp_alloc(f,size)              (f->alloc.alloc_buffer ? setup_temp_malloc(f,size) : alloca(size))
#ifdef dealloca
#define temp_free(f,p)                  (f->alloc.alloc_buffer ? 0 : dealloca(size))
#else
#define temp_free(f,p)                  0
#endif
#define temp_alloc_save(f)              ((f)->temp_offset)
#define temp_alloc_restore(f,p)         ((f)->temp_offset = (p))

#define temp_block_array(f,count,size)  make_block_array(temp_alloc(f,array_size_required(count,size)), count, size)

// given a sufficiently large block of memory, make an array of pointers to subblocks of it
static void *make_block_array(void *mem, int count, int size)
{
   int i;
   void ** p = (void **) mem;
   char *q = (char *) (p + count);
   for (i=0; i < count; ++i) {
      p[i] = q;
      q += size;
   }
   return p;
}

static void *setup_malloc(vorb *f, int sz)
{
   sz = (sz+3) & ~3;
   f->setup_memory_required += sz;
   if (f->alloc.alloc_buffer) {
      void *p = (char *) f->alloc.alloc_buffer + f->setup_offset;
      if (f->setup_offset + sz > f->temp_offset) return NULL;
      f->setup_offset += sz;
      return p;
   }
   return sz ? malloc(sz) : NULL;
}

static void setup_free(vorb *f, void *p)
{
   if (f->alloc.alloc_buffer) return; // do nothing; setup mem is a stack
   free(p);
}

static void *setup_temp_malloc(vorb *f, int sz)
{
   sz = (sz+3) & ~3;
   if (f->alloc.alloc_buffer) {
      if (f->temp_offset - sz < f->setup_offset) return NULL;
      f->temp_offset -= sz;
      return (char *) f->alloc.alloc_buffer + f->temp_offset;
   }
   return malloc(sz);
}

static void setup_temp_free(vorb *f, void *p, int sz)
{
   if (f->alloc.alloc_buffer) {
      f->temp_offset += (sz+3)&~3;
      return;
   }
   free(p);
}

#define CRC32_POLY    0x04c11db7   // from spec

static uint32 crc_table[256];
static void crc32_init(void)
{
   int i,j;
   uint32 s;
   for(i=0; i < 256; i++) {
      for (s=(uint32) i << 24, j=0; j < 8; ++j)
         s = (s << 1) ^ (s >= (1U<<31) ? CRC32_POLY : 0);
      crc_table[i] = s;
   }
}

static __forceinline uint32 crc32_update(uint32 crc, uint8 byte)
{
   return (crc << 8) ^ crc_table[byte ^ (crc >> 24)];
}


// used in setup, and for huffman that doesn't go fast path
static unsigned int bit_reverse(unsigned int n)
{
  n = ((n & 0xAAAAAAAA) >>  1) | ((n & 0x55555555) << 1);
  n = ((n & 0xCCCCCCCC) >>  2) | ((n & 0x33333333) << 2);
  n = ((n & 0xF0F0F0F0) >>  4) | ((n & 0x0F0F0F0F) << 4);
  n = ((n & 0xFF00FF00) >>  8) | ((n & 0x00FF00FF) << 8);
  return (n >> 16) | (n << 16);
}

static float square(float x)
{
   return x*x;
}

// this is a weird definition of log2() for which log2(1) = 1, log2(2) = 2, log2(4) = 3
// as required by the specification. fast(?) implementation from stb.h
// @OPTIMIZE: called multiple times per-packet with "constants"; move to setup
static int ilog(int32 n)
{
   static signed char log2_4[16] = { 0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4 };

   // 2 compares if n < 16, 3 compares otherwise (4 if signed or n > 1<<29)
   if (n < (1 << 14))
        if (n < (1 <<  4))        return     0 + log2_4[n      ];
        else if (n < (1 <<  9))      return  5 + log2_4[n >>  5];
             else                     return 10 + log2_4[n >> 10];
   else if (n < (1 << 24))
             if (n < (1 << 19))      return 15 + log2_4[n >> 15];
             else                     return 20 + log2_4[n >> 20];
        else if (n < (1 << 29))      return 25 + log2_4[n >> 25];
             else if (n < (1 << 31)) return 30 + log2_4[n >> 30];
                  else                return 0; // signed n returns 0
}

#ifndef M_PI
  #define M_PI  3.14159265358979323846264f  // from CRC
#endif

// code length assigned to a value with no huffman encoding
#define NO_CODE   255

/////////////////////// LEAF SETUP FUNCTIONS //////////////////////////
//
// these functions are only called at setup, and only a few times
// per file

static float float32_unpack(uint32 x)
{
   // from the specification
   uint32 mantissa = x & 0x1fffff;
   uint32 sign = x & 0x80000000;
   uint32 exp = (x & 0x7fe00000) >> 21;
   double res = sign ? -(double)mantissa : (double)mantissa;
   return (float) ldexp((float)res, exp-788);
}


// zlib & jpeg huffman tables assume that the output symbols
// can either be arbitrarily arranged, or have monotonically
// increasing frequencies--they rely on the lengths being sorted;
// this makes for a very simple generation algorithm.
// vorbis allows a huffman table with non-sorted lengths. This
// requires a more sophisticated construction, since symbols in
// order do not map to huffman codes "in order".
static void add_entry(Codebook *c, uint32 huff_code, int symbol, int count, int len, uint32 *values)
{
   if (!c->sparse) {
      c->codewords      [symbol] = huff_code;
   } else {
      c->codewords       [count] = huff_code;
      c->codeword_lengths[count] = len;
      values             [count] = symbol;
   }
}

static int compute_codewords(Codebook *c, uint8 *len, int n, uint32 *values)
{
   int i,k,m=0;
   uint32 available[32];

   memset(available, 0, sizeof(available));
   // find the first entry
   for (k=0; k < n; ++k) if (len[k] < NO_CODE) break;
   if (k == n) { assert(c->sorted_entries == 0); return TRUE; }
   // add to the list
   add_entry(c, 0, k, m++, len[k], values);
   // add all available leaves
   for (i=1; i <= len[k]; ++i)
      available[i] = 1U << (32-i);
   // note that the above code treats the first case specially,
   // but it's really the same as the following code, so they
   // could probably be combined (except the initial code is 0,
   // and I use 0 in available[] to mean 'empty')
   for (i=k+1; i < n; ++i) {
      uint32 res;
      int z = len[i], y;
      if (z == NO_CODE) continue;
      // find lowest available leaf (should always be earliest,
      // which is what the specification calls for)
      // note that this property, and the fact we can never have
      // more than one free leaf at a given level, isn't totally
      // trivial to prove, but it seems true and the assert never
      // fires, so!
      while (z > 0 && !available[z]) --z;
      if (z == 0) { return FALSE; }
      res = available[z];
      assert(z >= 0 && z < 32);
      available[z] = 0;
      add_entry(c, bit_reverse(res), i, m++, len[i], values);
      // propogate availability up the tree
      if (z != len[i]) {
         assert(len[i] >= 0 && len[i] < 32);
         for (y=len[i]; y > z; --y) {
            assert(available[y] == 0);
            available[y] = res + (1 << (32-y));
         }
      }
   }
   return TRUE;
}

// accelerated huffman table allows fast O(1) match of all symbols
// of length <= STB_VORBIS_FAST_HUFFMAN_LENGTH
static void compute_accelerated_huffman(Codebook *c)
{
   int i, len;
   for (i=0; i < FAST_HUFFMAN_TABLE_SIZE; ++i)
      c->fast_huffman[i] = -1;

   len = c->sparse ? c->sorted_entries : c->entries;
   #ifdef STB_VORBIS_FAST_HUFFMAN_SHORT
   if (len > 32767) len = 32767; // largest possible value we can encode!
   #endif
   for (i=0; i < len; ++i) {
      if (c->codeword_lengths[i] <= STB_VORBIS_FAST_HUFFMAN_LENGTH) {
         uint32 z = c->sparse ? bit_reverse(c->sorted_codewords[i]) : c->codewords[i];
         // set table entries for all bit combinations in the higher bits
         while (z < FAST_HUFFMAN_TABLE_SIZE) {
             c->fast_huffman[z] = i;
             z += 1 << c->codeword_lengths[i];
         }
      }
   }
}

#ifdef _MSC_VER
#define STBV_CDECL __cdecl
#else
#define STBV_CDECL
#endif

static int STBV_CDECL uint32_compare(const void *p, const void *q)
{
   uint32 x = * (uint32 *) p;
   uint32 y = * (uint32 *) q;
   return x < y ? -1 : x > y;
}

static int include_in_sort(Codebook *c, uint8 len)
{
   if (c->sparse) { assert(len != NO_CODE); return TRUE; }
   if (len == NO_CODE) return FALSE;
   if (len > STB_VORBIS_FAST_HUFFMAN_LENGTH) return TRUE;
   return FALSE;
}

// if the fast table above doesn't work, we want to binary
// search them... need to reverse the bits
static void compute_sorted_huffman(Codebook *c, uint8 *lengths, uint32 *values)
{
   int i, len;
   // build a list of all the entries
   // OPTIMIZATION: don't include the short ones, since they'll be caught by FAST_HUFFMAN.
   // this is kind of a frivolous optimization--I don't see any performance improvement,
   // but it's like 4 extra lines of code, so.
   if (!c->sparse) {
      int k = 0;
      for (i=0; i < c->entries; ++i)
         if (include_in_sort(c, lengths[i])) 
            c->sorted_codewords[k++] = bit_reverse(c->codewords[i]);
      assert(k == c->sorted_entries);
   } else {
      for (i=0; i < c->sorted_entries; ++i)
         c->sorted_codewords[i] = bit_reverse(c->codewords[i]);
   }

   qsort(c->sorted_codewords, c->sorted_entries, sizeof(c->sorted_codewords[0]), uint32_compare);
   c->sorted_codewords[c->sorted_entries] = 0xffffffff;

   len = c->sparse ? c->sorted_entries : c->entries;
   // now we need to indicate how they correspond; we could either
   //   #1: sort a different data structure that says who they correspond to
   //   #2: for each sorted entry, search the original list to find who corresponds
   //   #3: for each original entry, find the sorted entry
   // #1 requires extra storage, #2 is slow, #3 can use binary search!
   for (i=0; i < len; ++i) {
      int huff_len = c->sparse ? lengths[values[i]] : lengths[i];
      if (include_in_sort(c,huff_len)) {
         uint32 code = bit_reverse(c->codewords[i]);
         int x=0, n=c->sorted_entries;
         while (n > 1) {
            // invariant: sc[x] <= code < sc[x+n]
            int m = x + (n >> 1);
            if (c->sorted_codewords[m] <= code) {
               x = m;
               n -= (n>>1);
            } else {
               n >>= 1;
            }
         }
         assert(c->sorted_codewords[x] == code);
         if (c->sparse) {
            c->sorted_values[x] = values[i];
            c->codeword_lengths[x] = huff_len;
         } else {
            c->sorted_values[x] = i;
         }
      }
   }
}

// only run while parsing the header (3 times)
static int vorbis_validate(uint8 *data)
{
   static uint8 vorbis[6] = { 'v', 'o', 'r', 'b', 'i', 's' };
   return memcmp(data, vorbis, 6) == 0;
}

// called from setup only, once per code book
// (formula implied by specification)
static int lookup1_values(int entries, int dim)
{
   int r = (int) floor(exp((float) log((float) entries) / dim));
   if ((int) floor(pow((float) r+1, dim)) <= entries)   // (int) cast for MinGW warning;
      ++r;                                              // floor() to avoid _ftol() when non-CRT
   assert(pow((float) r+1, dim) > entries);
   assert((int) floor(pow((float) r, dim)) <= entries); // (int),floor() as above
   return r;
}

// called twice per file
static void compute_twiddle_factors(int n, float *A, float *B, float *C)
{
   int n4 = n >> 2, n8 = n >> 3;
   int k,k2;

   for (k=k2=0; k < n4; ++k,k2+=2) {
      A[k2  ] = (float)  cos(4*k*M_PI/n);
      A[k2+1] = (float) -sin(4*k*M_PI/n);
      B[k2  ] = (float)  cos((k2+1)*M_PI/n/2) * 0.5f;
      B[k2+1] = (float)  sin((k2+1)*M_PI/n/2) * 0.5f;
   }
   for (k=k2=0; k < n8; ++k,k2+=2) {
      C[k2  ] = (float)  cos(2*(k2+1)*M_PI/n);
      C[k2+1] = (float) -sin(2*(k2+1)*M_PI/n);
   }
}

static void compute_window(int n, float *window)
{
   int n2 = n >> 1, i;
   for (i=0; i < n2; ++i)
      window[i] = (float) sin(0.5 * M_PI * square((float) sin((i - 0 + 0.5) / n2 * 0.5 * M_PI)));
}

static void compute_bitreverse(int n, uint16 *rev)
{
   int ld = ilog(n) - 1; // ilog is off-by-one from normal definitions
   int i, n8 = n >> 3;
   for (i=0; i < n8; ++i)
      rev[i] = (bit_reverse(i) >> (32-ld+3)) << 2;
}

static int init_blocksize(vorb *f, int b, int n)
{
   int n2 = n >> 1, n4 = n >> 2, n8 = n >> 3;
   f->A[b] = (float *) setup_malloc(f, sizeof(float) * n2);
   f->B[b] = (float *) setup_malloc(f, sizeof(float) * n2);
   f->C[b] = (float *) setup_malloc(f, sizeof(float) * n4);
   if (!f->A[b] || !f->B[b] || !f->C[b]) return error(f, VORBIS_outofmem);
   compute_twiddle_factors(n, f->A[b], f->B[b], f->C[b]);
   f->window[b] = (float *) setup_malloc(f, sizeof(float) * n2);
   if (!f->window[b]) return error(f, VORBIS_outofmem);
   compute_window(n, f->window[b]);
   f->bit_reverse[b] = (uint16 *) setup_malloc(f, sizeof(uint16) * n8);
   if (!f->bit_reverse[b]) return error(f, VORBIS_outofmem);
   compute_bitreverse(n, f->bit_reverse[b]);
   return TRUE;
}

static void neighbors(uint16 *x, int n, int *plow, int *phigh)
{
   int low = -1;
   int high = 65536;
   int i;
   for (i=0; i < n; ++i) {
      if (x[i] > low  && x[i] < x[n]) { *plow  = i; low = x[i]; }
      if (x[i] < high && x[i] > x[n]) { *phigh = i; high = x[i]; }
   }
}

// this has been repurposed so y is now the original index instead of y
typedef struct
{
   uint16 x,y;
} Point;

static int STBV_CDECL point_compare(const void *p, const void *q)
{
   Point *a = (Point *) p;
   Point *b = (Point *) q;
   return a->x < b->x ? -1 : a->x > b->x;
}

//
/////////////////////// END LEAF SETUP FUNCTIONS //////////////////////////


#if defined(STB_VORBIS_NO_STDIO)
   #define USE_MEMORY(z)    TRUE
#else
   #define USE_MEMORY(z)    ((z)->stream)
#endif

static uint8 get8(vorb *z)
{
   if (USE_MEMORY(z)) {
      if (z->stream >= z->stream_end) { z->eof = TRUE; return 0; }
      return *z->stream++;
   }

   #ifndef STB_VORBIS_NO_STDIO
   {
   int c = fgetc(z->f);
   if (c == EOF) { z->eof = TRUE; return 0; }
   return c;
   }
   #endif
}

static uint32 get32(vorb *f)
{
   uint32 x;
   x = get8(f);
   x += get8(f) << 8;
   x += get8(f) << 16;
   x += (uint32) get8(f) << 24;
   return x;
}

static int getn(vorb *z, uint8 *data, int n)
{
   if (USE_MEMORY(z)) {
      if (z->stream+n > z->stream_end) { z->eof = 1; return 0; }
      memcpy(data, z->stream, n);
      z->stream += n;
      return 1;
   }

   #ifndef STB_VORBIS_NO_STDIO   
   if (fread(data, n, 1, z->f) == 1)
      return 1;
   else {
      z->eof = 1;
      return 0;
   }
   #endif
}

static void skip(vorb *z, int n)
{
   if (USE_MEMORY(z)) {
      z->stream += n;
      if (z->stream >= z->stream_end) z->eof = 1;
      return;
   }
   #ifndef STB_VORBIS_NO_STDIO
   {
      long x = ftell(z->f);
      fseek(z->f, x+n, SEEK_SET);
   }
   #endif
}

static int set_file_offset(stb_vorbis *f, unsigned int loc)
{
   #ifndef STB_VORBIS_NO_PUSHDATA_API
   if (f->push_mode) return 0;
   #endif
   f->eof = 0;
   if (USE_MEMORY(f)) {
      if (f->stream_start + loc >= f->stream_end || f->stream_start + loc < f->stream_start) {
         f->stream = f->stream_end;
         f->eof = 1;
         return 0;
      } else {
         f->stream = f->stream_start + loc;
         return 1;
      }
   }
   #ifndef STB_VORBIS_NO_STDIO
   if (loc + f->f_start < loc || loc >= 0x80000000) {
      loc = 0x7fffffff;
      f->eof = 1;
   } else {
      loc += f->f_start;
   }
   if (!fseek(f->f, loc, SEEK_SET))
      return 1;
   f->eof = 1;
   fseek(f->f, f->f_start, SEEK_END);
   return 0;
   #endif
}


static uint8 ogg_page_header[4] = { 0x4f, 0x67, 0x67, 0x53 };

static int capture_pattern(vorb *f)
{
   if (0x4f != get8(f)) return FALSE;
   if (0x67 != get8(f)) return FALSE;
   if (0x67 != get8(f)) return FALSE;
   if (0x53 != get8(f)) return FALSE;
   return TRUE;
}

#define PAGEFLAG_continued_packet   1
#define PAGEFLAG_first_page         2
#define PAGEFLAG_last_page          4

static int start_page_no_capturepattern(vorb *f)
{
   uint32 loc0,loc1,n;
   // stream structure version
   if (0 != get8(f)) return error(f, VORBIS_invalid_stream_structure_version);
   // header flag
   f->page_flag = get8(f);
   // absolute granule position
   loc0 = get32(f); 
   loc1 = get32(f);
   // @TODO: validate loc0,loc1 as valid positions?
   // stream serial number -- vorbis doesn't interleave, so discard
   get32(f);
   //if (f->serial != get32(f)) return error(f, VORBIS_incorrect_stream_serial_number);
   // page sequence number
   n = get32(f);
   f->last_page = n;
   // CRC32
   get32(f);
   // page_segments
   f->segment_count = get8(f);
   if (!getn(f, f->segments, f->segment_count))
      return error(f, VORBIS_unexpected_eof);
   // assume we _don't_ know any the sample position of any segments
   f->end_seg_with_known_loc = -2;
   if (loc0 != ~0U || loc1 != ~0U) {
      int i;
      // determine which packet is the last one that will complete
      for (i=f->segment_count-1; i >= 0; --i)
         if (f->segments[i] < 255)
            break;
      // 'i' is now the index of the _last_ segment of a packet that ends
      if (i >= 0) {
         f->end_seg_with_known_loc = i;
         f->known_loc_for_packet   = loc0;
      }
   }
   if (f->first_decode) {
      int i,len;
      ProbedPage p;
      len = 0;
      for (i=0; i < f->segment_count; ++i)
         len += f->segments[i];
      len += 27 + f->segment_count;
      p.page_start = f->first_audio_page_offset;
      p.page_end = p.page_start + len;
      p.last_decoded_sample = loc0;
      f->p_first = p;
   }
   f->next_seg = 0;
   return TRUE;
}

static int start_page(vorb *f)
{
   if (!capture_pattern(f)) return error(f, VORBIS_missing_capture_pattern);
   return start_page_no_capturepattern(f);
}

static int start_packet(vorb *f)
{
   while (f->next_seg == -1) {
      if (!start_page(f)) return FALSE;
      if (f->page_flag & PAGEFLAG_continued_packet)
         return error(f, VORBIS_continued_packet_flag_invalid);
   }
   f->last_seg = FALSE;
   f->valid_bits = 0;
   f->packet_bytes = 0;
   f->bytes_in_seg = 0;
   // f->next_seg is now valid
   return TRUE;
}

static int maybe_start_packet(vorb *f)
{
   if (f->next_seg == -1) {
      int x = get8(f);
      if (f->eof) return FALSE; // EOF at page boundary is not an error!
      if (0x4f != x      ) return error(f, VORBIS_missing_capture_pattern);
      if (0x67 != get8(f)) return error(f, VORBIS_missing_capture_pattern);
      if (0x67 != get8(f)) return error(f, VORBIS_missing_capture_pattern);
      if (0x53 != get8(f)) return error(f, VORBIS_missing_capture_pattern);
      if (!start_page_no_capturepattern(f)) return FALSE;
      if (f->page_flag & PAGEFLAG_continued_packet) {
         // set up enough state that we can read this packet if we want,
         // e.g. during recovery
         f->last_seg = FALSE;
         f->bytes_in_seg = 0;
         return error(f, VORBIS_continued_packet_flag_invalid);
      }
   }
   return start_packet(f);
}

static int next_segment(vorb *f)
{
   int len;
   if (f->last_seg) return 0;
   if (f->next_seg == -1) {
      f->last_seg_which = f->segment_count-1; // in case start_page fails
      if (!start_page(f)) { f->last_seg = 1; return 0; }
      if (!(f->page_flag & PAGEFLAG_continued_packet)) return error(f, VORBIS_continued_packet_flag_invalid);
   }
   len = f->segments[f->next_seg++];
   if (len < 255) {
      f->last_seg = TRUE;
      f->last_seg_which = f->next_seg-1;
   }
   if (f->next_seg >= f->segment_count)
      f->next_seg = -1;
   assert(f->bytes_in_seg == 0);
   f->bytes_in_seg = len;
   return len;
}

#define EOP    (-1)
#define INVALID_BITS  (-1)

static int get8_packet_raw(vorb *f)
{
   if (!f->bytes_in_seg) {  // CLANG!
      if (f->last_seg) return EOP;
      else if (!next_segment(f)) return EOP;
   }
   assert(f->bytes_in_seg > 0);
   --f->bytes_in_seg;
   ++f->packet_bytes;
   return get8(f);
}

static int get8_packet(vorb *f)
{
   int x = get8_packet_raw(f);
   f->valid_bits = 0;
   return x;
}

static void flush_packet(vorb *f)
{
   while (get8_packet_raw(f) != EOP);
}

// @OPTIMIZE: this is the secondary bit decoder, so it's probably not as important
// as the huffman decoder?
static uint32 get_bits(vorb *f, int n)
{
   uint32 z;

   if (f->valid_bits < 0) return 0;
   if (f->valid_bits < n) {
      if (n > 24) {
         // the accumulator technique below would not work correctly in this case
         z = get_bits(f, 24);
         z += get_bits(f, n-24) << 24;
         return z;
      }
      if (f->valid_bits == 0) f->acc = 0;
      while (f->valid_bits < n) {
         int z = get8_packet_raw(f);
         if (z == EOP) {
            f->valid_bits = INVALID_BITS;
            return 0;
         }
         f->acc += z << f->valid_bits;
         f->valid_bits += 8;
      }
   }
   if (f->valid_bits < 0) return 0;
   z = f->acc & ((1 << n)-1);
   f->acc >>= n;
   f->valid_bits -= n;
   return z;
}

// @OPTIMIZE: primary accumulator for huffman
// expand the buffer to as many bits as possible without reading off end of packet
// it might be nice to allow f->valid_bits and f->acc to be stored in registers,
// e.g. cache them locally and decode locally
static __forceinline void prep_huffman(vorb *f)
{
   if (f->valid_bits <= 24) {
      if (f->valid_bits == 0) f->acc = 0;
      do {
         int z;
         if (f->last_seg && !f->bytes_in_seg) return;
         z = get8_packet_raw(f);
         if (z == EOP) return;
         f->acc += (unsigned) z << f->valid_bits;
         f->valid_bits += 8;
      } while (f->valid_bits <= 24);
   }
}

enum
{
   VORBIS_packet_id = 1,
   VORBIS_packet_comment = 3,
   VORBIS_packet_setup = 5
};

static int codebook_decode_scalar_raw(vorb *f, Codebook *c)
{
   int i;
   prep_huffman(f);

   if (c->codewords == NULL && c->sorted_codewords == NULL)
      return -1;

   // cases to use binary search: sorted_codewords && !c->codewords
   //                             sorted_codewords && c->entries > 8
   if (c->entries > 8 ? c->sorted_codewords!=NULL : !c->codewords) {
      // binary search
      uint32 code = bit_reverse(f->acc);
      int x=0, n=c->sorted_entries, len;

      while (n > 1) {
         // invariant: sc[x] <= code < sc[x+n]
         int m = x + (n >> 1);
         if (c->sorted_codewords[m] <= code) {
            x = m;
            n -= (n>>1);
         } else {
            n >>= 1;
         }
      }
      // x is now the sorted index
      if (!c->sparse) x = c->sorted_values[x];
      // x is now sorted index if sparse, or symbol otherwise
      len = c->codeword_lengths[x];
      if (f->valid_bits >= len) {
         f->acc >>= len;
         f->valid_bits -= len;
         return x;
      }

      f->valid_bits = 0;
      return -1;
   }

   // if small, linear search
   assert(!c->sparse);
   for (i=0; i < c->entries; ++i) {
      if (c->codeword_lengths[i] == NO_CODE) continue;
      if (c->codewords[i] == (f->acc & ((1 << c->codeword_lengths[i])-1))) {
         if (f->valid_bits >= c->codeword_lengths[i]) {
            f->acc >>= c->codeword_lengths[i];
            f->valid_bits -= c->codeword_lengths[i];
            return i;
         }
         f->valid_bits = 0;
         return -1;
      }
   }

   error(f, VORBIS_invalid_stream);
   f->valid_bits = 0;
   return -1;
}

#ifndef STB_VORBIS_NO_INLINE_DECODE

#define DECODE_RAW(var, f,c)                                  \
   if (f->valid_bits < STB_VORBIS_FAST_HUFFMAN_LENGTH)        \
      prep_huffman(f);                                        \
   var = f->acc & FAST_HUFFMAN_TABLE_MASK;                    \
   var = c->fast_huffman[var];                                \
   if (var >= 0) {                                            \
      int n = c->codeword_lengths[var];                       \
      f->acc >>= n;                                           \
      f->valid_bits -= n;                                     \
      if (f->valid_bits < 0) { f->valid_bits = 0; var = -1; } \
   } else {                                                   \
      var = codebook_decode_scalar_raw(f,c);                  \
   }

#else

static int codebook_decode_scalar(vorb *f, Codebook *c)
{
   int i;
   if (f->valid_bits < STB_VORBIS_FAST_HUFFMAN_LENGTH)
      prep_huffman(f);
   // fast huffman table lookup
   i = f->acc & FAST_HUFFMAN_TABLE_MASK;
   i = c->fast_huffman[i];
   if (i >= 0) {
      f->acc >>= c->codeword_lengths[i];
      f->valid_bits -= c->codeword_lengths[i];
      if (f->valid_bits < 0) { f->valid_bits = 0; return -1; }
      return i;
   }
   return codebook_decode_scalar_raw(f,c);
}

#define DECODE_RAW(var,f,c)    var = codebook_decode_scalar(f,c);

#endif

#define DECODE(var,f,c)                                       \
   DECODE_RAW(var,f,c)                                        \
   if (c->sparse) var = c->sorted_values[var];

#ifndef STB_VORBIS_DIVIDES_IN_CODEBOOK
  #define DECODE_VQ(var,f,c)   DECODE_RAW(var,f,c)
#else
  #define DECODE_VQ(var,f,c)   DECODE(var,f,c)
#endif






// CODEBOOK_ELEMENT_FAST is an optimization for the CODEBOOK_FLOATS case
// where we avoid one addition
#define CODEBOOK_ELEMENT(c,off)          (c->multiplicands[off])
#define CODEBOOK_ELEMENT_FAST(c,off)     (c->multiplicands[off])
#define CODEBOOK_ELEMENT_BASE(c)         (0)

static int codebook_decode_start(vorb *f, Codebook *c)
{
   int z = -1;

   // type 0 is only legal in a scalar context
   if (c->lookup_type == 0)
      error(f, VORBIS_invalid_stream);
   else {
      DECODE_VQ(z,f,c);
      if (c->sparse) assert(z < c->sorted_entries);
      if (z < 0) {  // check for EOP
         if (!f->bytes_in_seg)
            if (f->last_seg)
               return z;
         error(f, VORBIS_invalid_stream);
      }
   }
   return z;
}

static int codebook_decode(vorb *f, Codebook *c, float *output, int len)
{
   int i,z = codebook_decode_start(f,c);
   if (z < 0) return FALSE;
   if (len > c->dimensions) len = c->dimensions;

#ifdef STB_VORBIS_DIVIDES_IN_CODEBOOK
   if (c->lookup_type == 1) {
      float last = CODEBOOK_ELEMENT_BASE(c);
      int div = 1;
      for (i=0; i < len; ++i) {
         int off = (z / div) % c->lookup_values;
         float val = CODEBOOK_ELEMENT_FAST(c,off) + last;
         output[i] += val;
         if (c->sequence_p) last = val + c->minimum_value;
         div *= c->lookup_values;
      }
      return TRUE;
   }
#endif

   z *= c->dimensions;
   if (c->sequence_p) {
      float last = CODEBOOK_ELEMENT_BASE(c);
      for (i=0; i < len; ++i) {
         float val = CODEBOOK_ELEMENT_FAST(c,z+i) + last;
         output[i] += val;
         last = val + c->minimum_value;
      }
   } else {
      float last = CODEBOOK_ELEMENT_BASE(c);
      for (i=0; i < len; ++i) {
         output[i] += CODEBOOK_ELEMENT_FAST(c,z+i) + last;
      }
   }

   return TRUE;
}

static int codebook_decode_step(vorb *f, Codebook *c, float *output, int len, int step)
{
   int i,z = codebook_decode_start(f,c);
   float last = CODEBOOK_ELEMENT_BASE(c);
   if (z < 0) return FALSE;
   if (len > c->dimensions) len = c->dimensions;

#ifdef STB_VORBIS_DIVIDES_IN_CODEBOOK
   if (c->lookup_type == 1) {
      int div = 1;
      for (i=0; i < len; ++i) {
         int off = (z / div) % c->lookup_values;
         float val = CODEBOOK_ELEMENT_FAST(c,off) + last;
         output[i*step] += val;
         if (c->sequence_p) last = val;
         div *= c->lookup_values;
      }
      return TRUE;
   }
#endif

   z *= c->dimensions;
   for (i=0; i < len; ++i) {
      float val = CODEBOOK_ELEMENT_FAST(c,z+i) + last;
      output[i*step] += val;
      if (c->sequence_p) last = val;
   }

   return TRUE;
}

static int codebook_decode_deinterleave_repeat(vorb *f, Codebook *c, float **outputs, int ch, int *c_inter_p, int *p_inter_p, int len, int total_decode)
{
   int c_inter = *c_inter_p;
   int p_inter = *p_inter_p;
   int i,z, effective = c->dimensions;

   // type 0 is only legal in a scalar context
   if (c->lookup_type == 0)   return error(f, VORBIS_invalid_stream);

   while (total_decode > 0) {
      float last = CODEBOOK_ELEMENT_BASE(c);
      DECODE_VQ(z,f,c);
      #ifndef STB_VORBIS_DIVIDES_IN_CODEBOOK
      assert(!c->sparse || z < c->sorted_entries);
      #endif
      if (z < 0) {
         if (!f->bytes_in_seg)
            if (f->last_seg) return FALSE;
         return error(f, VORBIS_invalid_stream);
      }

      // if this will take us off the end of the buffers, stop short!
      // we check by computing the length of the virtual interleaved
      // buffer (len*ch), our current offset within it (p_inter*ch)+(c_inter),
      // and the length we'll be using (effective)
      if (c_inter + p_inter*ch + effective > len * ch) {
         effective = len*ch - (p_inter*ch - c_inter);
      }

   #ifdef STB_VORBIS_DIVIDES_IN_CODEBOOK
      if (c->lookup_type == 1) {
         int div = 1;
         for (i=0; i < effective; ++i) {
            int off = (z / div) % c->lookup_values;
            float val = CODEBOOK_ELEMENT_FAST(c,off) + last;
            if (outputs[c_inter])
               outputs[c_inter][p_inter] += val;
            if (++c_inter == ch) { c_inter = 0; ++p_inter; }
            if (c->sequence_p) last = val;
            div *= c->lookup_values;
         }
      } else
   #endif
      {
         z *= c->dimensions;
         if (c->sequence_p) {
            for (i=0; i < effective; ++i) {
               float val = CODEBOOK_ELEMENT_FAST(c,z+i) + last;
               if (outputs[c_inter])
                  outputs[c_inter][p_inter] += val;
               if (++c_inter == ch) { c_inter = 0; ++p_inter; }
               last = val;
            }
         } else {
            for (i=0; i < effective; ++i) {
               float val = CODEBOOK_ELEMENT_FAST(c,z+i) + last;
               if (outputs[c_inter])
                  outputs[c_inter][p_inter] += val;
               if (++c_inter == ch) { c_inter = 0; ++p_inter; }
            }
         }
      }

      total_decode -= effective;
   }
   *c_inter_p = c_inter;
   *p_inter_p = p_inter;
   return TRUE;
}

static int predict_point(int x, int x0, int x1, int y0, int y1)
{
   int dy = y1 - y0;
   int adx = x1 - x0;
   // @OPTIMIZE: force int division to round in the right direction... is this necessary on x86?
   int err = abs(dy) * (x - x0);
   int off = err / adx;
   return dy < 0 ? y0 - off : y0 + off;
}

// the following table is block-copied from the specification
static float inverse_db_table[256] =
{
  1.0649863e-07f, 1.1341951e-07f, 1.2079015e-07f, 1.2863978e-07f, 
  1.3699951e-07f, 1.4590251e-07f, 1.5538408e-07f, 1.6548181e-07f, 
  1.7623575e-07f, 1.8768855e-07f, 1.9988561e-07f, 2.1287530e-07f, 
  2.2670913e-07f, 2.4144197e-07f, 2.5713223e-07f, 2.7384213e-07f, 
  2.9163793e-07f, 3.1059021e-07f, 3.3077411e-07f, 3.5226968e-07f, 
  3.7516214e-07f, 3.9954229e-07f, 4.2550680e-07f, 4.5315863e-07f, 
  4.8260743e-07f, 5.1396998e-07f, 5.4737065e-07f, 5.8294187e-07f, 
  6.2082472e-07f, 6.6116941e-07f, 7.0413592e-07f, 7.4989464e-07f, 
  7.9862701e-07f, 8.5052630e-07f, 9.0579828e-07f, 9.6466216e-07f, 
  1.0273513e-06f, 1.0941144e-06f, 1.1652161e-06f, 1.2409384e-06f, 
  1.3215816e-06f, 1.4074654e-06f, 1.4989305e-06f, 1.5963394e-06f, 
  1.7000785e-06f, 1.8105592e-06f, 1.9282195e-06f, 2.0535261e-06f, 
  2.1869758e-06f, 2.3290978e-06f, 2.4804557e-06f, 2.6416497e-06f, 
  2.8133190e-06f, 2.9961443e-06f, 3.1908506e-06f, 3.3982101e-06f, 
  3.6190449e-06f, 3.8542308e-06f, 4.1047004e-06f, 4.3714470e-06f, 
  4.6555282e-06f, 4.9580707e-06f, 5.2802740e-06f, 5.6234160e-06f, 
  5.9888572e-06f, 6.3780469e-06f, 6.7925283e-06f, 7.2339451e-06f, 
  7.7040476e-06f, 8.2047000e-06f, 8.7378876e-06f, 9.3057248e-06f, 
  9.9104632e-06f, 1.0554501e-05f, 1.1240392e-05f, 1.1970856e-05f, 
  1.2748789e-05f, 1.3577278e-05f, 1.4459606e-05f, 1.5399272e-05f, 
  1.6400004e-05f, 1.7465768e-05f, 1.8600792e-05f, 1.9809576e-05f, 
  2.1096914e-05f, 2.2467911e-05f, 2.3928002e-05f, 2.5482978e-05f, 
  2.7139006e-05f, 2.8902651e-05f, 3.0780908e-05f, 3.2781225e-05f, 
  3.4911534e-05f, 3.7180282e-05f, 3.9596466e-05f, 4.2169667e-05f, 
  4.4910090e-05f, 4.7828601e-05f, 5.0936773e-05f, 5.4246931e-05f, 
  5.7772202e-05f, 6.1526565e-05f, 6.5524908e-05f, 6.9783085e-05f, 
  7.4317983e-05f, 7.9147585e-05f, 8.4291040e-05f, 8.9768747e-05f, 
  9.5602426e-05f, 0.00010181521f, 0.00010843174f, 0.00011547824f, 
  0.00012298267f, 0.00013097477f, 0.00013948625f, 0.00014855085f, 
  0.00015820453f, 0.00016848555f, 0.00017943469f, 0.00019109536f, 
  0.00020351382f, 0.00021673929f, 0.00023082423f, 0.00024582449f, 
  0.00026179955f, 0.00027881276f, 0.00029693158f, 0.00031622787f, 
  0.00033677814f, 0.00035866388f, 0.00038197188f, 0.00040679456f, 
  0.00043323036f, 0.00046138411f, 0.00049136745f, 0.00052329927f, 
  0.00055730621f, 0.00059352311f, 0.00063209358f, 0.00067317058f, 
  0.00071691700f, 0.00076350630f, 0.00081312324f, 0.00086596457f, 
  0.00092223983f, 0.00098217216f, 0.0010459992f,  0.0011139742f, 
  0.0011863665f,  0.0012634633f,  0.0013455702f,  0.0014330129f, 
  0.0015261382f,  0.0016253153f,  0.0017309374f,  0.0018434235f, 
  0.0019632195f,  0.0020908006f,  0.0022266726f,  0.0023713743f, 
  0.0025254795f,  0.0026895994f,  0.0028643847f,  0.0030505286f, 
  0.0032487691f,  0.0034598925f,  0.0036847358f,  0.0039241906f, 
  0.0041792066f,  0.0044507950f,  0.0047400328f,  0.0050480668f, 
  0.0053761186f,  0.0057254891f,  0.0060975636f,  0.0064938176f, 
  0.0069158225f,  0.0073652516f,  0.0078438871f,  0.0083536271f, 
  0.0088964928f,  0.009474637f,   0.010090352f,   0.010746080f, 
  0.011444421f,   0.012188144f,   0.012980198f,   0.013823725f, 
  0.014722068f,   0.015678791f,   0.016697687f,   0.017782797f, 
  0.018938423f,   0.020169149f,   0.021479854f,   0.022875735f, 
  0.024362330f,   0.025945531f,   0.027631618f,   0.029427276f, 
  0.031339626f,   0.033376252f,   0.035545228f,   0.037855157f, 
  0.040315199f,   0.042935108f,   0.045725273f,   0.048696758f, 
  0.051861348f,   0.055231591f,   0.058820850f,   0.062643361f, 
  0.066714279f,   0.071049749f,   0.075666962f,   0.080584227f, 
  0.085821044f,   0.091398179f,   0.097337747f,   0.10366330f, 
  0.11039993f,    0.11757434f,    0.12521498f,    0.13335215f, 
  0.14201813f,    0.15124727f,    0.16107617f,    0.17154380f, 
  0.18269168f,    0.19456402f,    0.20720788f,    0.22067342f, 
  0.23501402f,    0.25028656f,    0.26655159f,    0.28387361f, 
  0.30232132f,    0.32196786f,    0.34289114f,    0.36517414f, 
  0.38890521f,    0.41417847f,    0.44109412f,    0.46975890f, 
  0.50028648f,    0.53279791f,    0.56742212f,    0.60429640f, 
  0.64356699f,    0.68538959f,    0.72993007f,    0.77736504f, 
  0.82788260f,    0.88168307f,    0.9389798f,     1.0f
};


// @OPTIMIZE: if you want to replace this bresenham line-drawing routine,
// note that you must produce bit-identical output to decode correctly;
// this specific sequence of operations is specified in the spec (it's
// drawing integer-quantized frequency-space lines that the encoder
// expects to be exactly the same)
//     ... also, isn't the whole point of Bresenham's algorithm to NOT
// have to divide in the setup? sigh.
#ifndef STB_VORBIS_NO_DEFER_FLOOR
#define LINE_OP(a,b)   a *= b
#else
#define LINE_OP(a,b)   a = b
#endif

#ifdef STB_VORBIS_DIVIDE_TABLE
#define DIVTAB_NUMER   32
#define DIVTAB_DENOM   64
int8 integer_divide_table[DIVTAB_NUMER][DIVTAB_DENOM]; // 2KB
#endif

static __forceinline void draw_line(float *output, int x0, int y0, int x1, int y1, int n)
{
   int dy = y1 - y0;
   int adx = x1 - x0;
   int ady = abs(dy);
   int base;
   int x=x0,y=y0;
   int err = 0;
   int sy;

#ifdef STB_VORBIS_DIVIDE_TABLE
   if (adx < DIVTAB_DENOM && ady < DIVTAB_NUMER) {
      if (dy < 0) {
         base = -integer_divide_table[ady][adx];
         sy = base-1;
      } else {
         base =  integer_divide_table[ady][adx];
         sy = base+1;
      }
   } else {
      base = dy / adx;
      if (dy < 0)
         sy = base - 1;
      else
         sy = base+1;
   }
#else
   base = dy / adx;
   if (dy < 0)
      sy = base - 1;
   else
      sy = base+1;
#endif
   ady -= abs(base) * adx;
   if (x1 > n) x1 = n;
   if (x < x1) {
      LINE_OP(output[x], inverse_db_table[y]);
      for (++x; x < x1; ++x) {
         err += ady;
         if (err >= adx) {
            err -= adx;
            y += sy;
         } else
            y += base;
         LINE_OP(output[x], inverse_db_table[y]);
      }
   }
}

static int residue_decode(vorb *f, Codebook *book, float *target, int offset, int n, int rtype)
{
   int k;
   if (rtype == 0) {
      int step = n / book->dimensions;
      for (k=0; k < step; ++k)
         if (!codebook_decode_step(f, book, target+offset+k, n-offset-k, step))
            return FALSE;
   } else {
      for (k=0; k < n; ) {
         if (!codebook_decode(f, book, target+offset, n-k))
            return FALSE;
         k += book->dimensions;
         offset += book->dimensions;
      }
   }
   return TRUE;
}

static void decode_residue(vorb *f, float *residue_buffers[], int ch, int n, int rn, uint8 *do_not_decode)
{
   int i,j,pass;
   Residue *r = f->residue_config + rn;
   int rtype = f->residue_types[rn];
   int c = r->classbook;
   int classwords = f->codebooks[c].dimensions;
   int n_read = r->end - r->begin;
   int part_read = n_read / r->part_size;
   int temp_alloc_point = temp_alloc_save(f);
   #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
   uint8 ***part_classdata = (uint8 ***) temp_block_array(f,f->channels, part_read * sizeof(**part_classdata));
   #else
   int **classifications = (int **) temp_block_array(f,f->channels, part_read * sizeof(**classifications));
   #endif

   CHECK(f);

   for (i=0; i < ch; ++i)
      if (!do_not_decode[i])
         memset(residue_buffers[i], 0, sizeof(float) * n);

   if (rtype == 2 && ch != 1) {
      for (j=0; j < ch; ++j)
         if (!do_not_decode[j])
            break;
      if (j == ch)
         goto done;

      for (pass=0; pass < 8; ++pass) {
         int pcount = 0, class_set = 0;
         if (ch == 2) {
            while (pcount < part_read) {
               int z = r->begin + pcount*r->part_size;
               int c_inter = (z & 1), p_inter = z>>1;
               if (pass == 0) {
                  Codebook *c = f->codebooks+r->classbook;
                  int q;
                  DECODE(q,f,c);
                  if (q == EOP) goto done;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  part_classdata[0][class_set] = r->classdata[q];
                  #else
                  for (i=classwords-1; i >= 0; --i) {
                     classifications[0][i+pcount] = q % r->classifications;
                     q /= r->classifications;
                  }
                  #endif
               }
               for (i=0; i < classwords && pcount < part_read; ++i, ++pcount) {
                  int z = r->begin + pcount*r->part_size;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  int c = part_classdata[0][class_set][i];
                  #else
                  int c = classifications[0][pcount];
                  #endif
                  int b = r->residue_books[c][pass];
                  if (b >= 0) {
                     Codebook *book = f->codebooks + b;
                     #ifdef STB_VORBIS_DIVIDES_IN_CODEBOOK
                     if (!codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, r->part_size))
                        goto done;
                     #else
                     // saves 1%
                     if (!codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, r->part_size))
                        goto done;
                     #endif
                  } else {
                     z += r->part_size;
                     c_inter = z & 1;
                     p_inter = z >> 1;
                  }
               }
               #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
               ++class_set;
               #endif
            }
         } else if (ch == 1) {
            while (pcount < part_read) {
               int z = r->begin + pcount*r->part_size;
               int c_inter = 0, p_inter = z;
               if (pass == 0) {
                  Codebook *c = f->codebooks+r->classbook;
                  int q;
                  DECODE(q,f,c);
                  if (q == EOP) goto done;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  part_classdata[0][class_set] = r->classdata[q];
                  #else
                  for (i=classwords-1; i >= 0; --i) {
                     classifications[0][i+pcount] = q % r->classifications;
                     q /= r->classifications;
                  }
                  #endif
               }
               for (i=0; i < classwords && pcount < part_read; ++i, ++pcount) {
                  int z = r->begin + pcount*r->part_size;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  int c = part_classdata[0][class_set][i];
                  #else
                  int c = classifications[0][pcount];
                  #endif
                  int b = r->residue_books[c][pass];
                  if (b >= 0) {
                     Codebook *book = f->codebooks + b;
                     if (!codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, r->part_size))
                        goto done;
                  } else {
                     z += r->part_size;
                     c_inter = 0;
                     p_inter = z;
                  }
               }
               #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
               ++class_set;
               #endif
            }
         } else {
            while (pcount < part_read) {
               int z = r->begin + pcount*r->part_size;
               int c_inter = z % ch, p_inter = z/ch;
               if (pass == 0) {
                  Codebook *c = f->codebooks+r->classbook;
                  int q;
                  DECODE(q,f,c);
                  if (q == EOP) goto done;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  part_classdata[0][class_set] = r->classdata[q];
                  #else
                  for (i=classwords-1; i >= 0; --i) {
                     classifications[0][i+pcount] = q % r->classifications;
                     q /= r->classifications;
                  }
                  #endif
               }
               for (i=0; i < classwords && pcount < part_read; ++i, ++pcount) {
                  int z = r->begin + pcount*r->part_size;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  int c = part_classdata[0][class_set][i];
                  #else
                  int c = classifications[0][pcount];
                  #endif
                  int b = r->residue_books[c][pass];
                  if (b >= 0) {
                     Codebook *book = f->codebooks + b;
                     if (!codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, r->part_size))
                        goto done;
                  } else {
                     z += r->part_size;
                     c_inter = z % ch;
                     p_inter = z / ch;
                  }
               }
               #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
               ++class_set;
               #endif
            }
         }
      }
      goto done;
   }
   CHECK(f);

   for (pass=0; pass < 8; ++pass) {
      int pcount = 0, class_set=0;
      while (pcount < part_read) {
         if (pass == 0) {
            for (j=0; j < ch; ++j) {
               if (!do_not_decode[j]) {
                  Codebook *c = f->codebooks+r->classbook;
                  int temp;
                  DECODE(temp,f,c);
                  if (temp == EOP) goto done;
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  part_classdata[j][class_set] = r->classdata[temp];
                  #else
                  for (i=classwords-1; i >= 0; --i) {
                     classifications[j][i+pcount] = temp % r->classifications;
                     temp /= r->classifications;
                  }
                  #endif
               }
            }
         }
         for (i=0; i < classwords && pcount < part_read; ++i, ++pcount) {
            for (j=0; j < ch; ++j) {
               if (!do_not_decode[j]) {
                  #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
                  int c = part_classdata[j][class_set][i];
                  #else
                  int c = classifications[j][pcount];
                  #endif
                  int b = r->residue_books[c][pass];
                  if (b >= 0) {
                     float *target = residue_buffers[j];
                     int offset = r->begin + pcount * r->part_size;
                     int n = r->part_size;
                     Codebook *book = f->codebooks + b;
                     if (!residue_decode(f, book, target, offset, n, rtype))
                        goto done;
                  }
               }
            }
         }
         #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
         ++class_set;
         #endif
      }
   }
  done:
   CHECK(f);
   #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
   temp_free(f,part_classdata);
   #else
   temp_free(f,classifications);
   #endif
   temp_alloc_restore(f,temp_alloc_point);
}


#if 0
// slow way for debugging
void inverse_mdct_slow(float *buffer, int n)
{
   int i,j;
   int n2 = n >> 1;
   float *x = (float *) malloc(sizeof(*x) * n2);
   memcpy(x, buffer, sizeof(*x) * n2);
   for (i=0; i < n; ++i) {
      float acc = 0;
      for (j=0; j < n2; ++j)
         // formula from paper:
         //acc += n/4.0f * x[j] * (float) cos(M_PI / 2 / n * (2 * i + 1 + n/2.0)*(2*j+1));
         // formula from wikipedia
         //acc += 2.0f / n2 * x[j] * (float) cos(M_PI/n2 * (i + 0.5 + n2/2)*(j + 0.5));
         // these are equivalent, except the formula from the paper inverts the multiplier!
         // however, what actually works is NO MULTIPLIER!?!
         //acc += 64 * 2.0f / n2 * x[j] * (float) cos(M_PI/n2 * (i + 0.5 + n2/2)*(j + 0.5));
         acc += x[j] * (float) cos(M_PI / 2 / n * (2 * i + 1 + n/2.0)*(2*j+1));
      buffer[i] = acc;
   }
   free(x);
}
#elif 0
// same as above, but just barely able to run in real time on modern machines
void inverse_mdct_slow(float *buffer, int n, vorb *f, int blocktype)
{
   float mcos[16384];
   int i,j;
   int n2 = n >> 1, nmask = (n << 2) -1;
   float *x = (float *) malloc(sizeof(*x) * n2);
   memcpy(x, buffer, sizeof(*x) * n2);
   for (i=0; i < 4*n; ++i)
      mcos[i] = (float) cos(M_PI / 2 * i / n);

   for (i=0; i < n; ++i) {
      float acc = 0;
      for (j=0; j < n2; ++j)
         acc += x[j] * mcos[(2 * i + 1 + n2)*(2*j+1) & nmask];
      buffer[i] = acc;
   }
   free(x);
}
#elif 0
// transform to use a slow dct-iv; this is STILL basically trivial,
// but only requires half as many ops
void dct_iv_slow(float *buffer, int n)
{
   float mcos[16384];
   float x[2048];
   int i,j;
   int n2 = n >> 1, nmask = (n << 3) - 1;
   memcpy(x, buffer, sizeof(*x) * n);
   for (i=0; i < 8*n; ++i)
      mcos[i] = (float) cos(M_PI / 4 * i / n);
   for (i=0; i < n; ++i) {
      float acc = 0;
      for (j=0; j < n; ++j)
         acc += x[j] * mcos[((2 * i + 1)*(2*j+1)) & nmask];
      buffer[i] = acc;
   }
}

void inverse_mdct_slow(float *buffer, int n, vorb *f, int blocktype)
{
   int i, n4 = n >> 2, n2 = n >> 1, n3_4 = n - n4;
   float temp[4096];

   memcpy(temp, buffer, n2 * sizeof(float));
   dct_iv_slow(temp, n2);  // returns -c'-d, a-b'

   for (i=0; i < n4  ; ++i) buffer[i] = temp[i+n4];            // a-b'
   for (   ; i < n3_4; ++i) buffer[i] = -temp[n3_4 - i - 1];   // b-a', c+d'
   for (   ; i < n   ; ++i) buffer[i] = -temp[i - n3_4];       // c'+d
}
#endif

#ifndef LIBVORBIS_MDCT
#define LIBVORBIS_MDCT 0
#endif

#if LIBVORBIS_MDCT
// directly call the vorbis MDCT using an interface documented
// by Jeff Roberts... useful for performance comparison
typedef struct 
{
  int n;
  int log2n;
  
  float *trig;
  int   *bitrev;

  float scale;
} mdct_lookup;

extern void mdct_init(mdct_lookup *lookup, int n);
extern void mdct_clear(mdct_lookup *l);
extern void mdct_backward(mdct_lookup *init, float *in, float *out);

mdct_lookup M1,M2;

void inverse_mdct(float *buffer, int n, vorb *f, int blocktype)
{
   mdct_lookup *M;
   if (M1.n == n) M = &M1;
   else if (M2.n == n) M = &M2;
   else if (M1.n == 0) { mdct_init(&M1, n); M = &M1; }
   else { 
      if (M2.n) __asm int 3;
      mdct_init(&M2, n);
      M = &M2;
   }

   mdct_backward(M, buffer, buffer);
}
#endif


// the following were split out into separate functions while optimizing;
// they could be pushed back up but eh. __forceinline showed no change;
// they're probably already being inlined.
static void imdct_step3_iter0_loop(int n, float *e, int i_off, int k_off, float *A)
{
   float *ee0 = e + i_off;
   float *ee2 = ee0 + k_off;
   int i;

   assert((n & 3) == 0);
   for (i=(n>>2); i > 0; --i) {
      float k00_20, k01_21;
      k00_20  = ee0[ 0] - ee2[ 0];
      k01_21  = ee0[-1] - ee2[-1];
      ee0[ 0] += ee2[ 0];//ee0[ 0] = ee0[ 0] + ee2[ 0];
      ee0[-1] += ee2[-1];//ee0[-1] = ee0[-1] + ee2[-1];
      ee2[ 0] = k00_20 * A[0] - k01_21 * A[1];
      ee2[-1] = k01_21 * A[0] + k00_20 * A[1];
      A += 8;

      k00_20  = ee0[-2] - ee2[-2];
      k01_21  = ee0[-3] - ee2[-3];
      ee0[-2] += ee2[-2];//ee0[-2] = ee0[-2] + ee2[-2];
      ee0[-3] += ee2[-3];//ee0[-3] = ee0[-3] + ee2[-3];
      ee2[-2] = k00_20 * A[0] - k01_21 * A[1];
      ee2[-3] = k01_21 * A[0] + k00_20 * A[1];
      A += 8;

      k00_20  = ee0[-4] - ee2[-4];
      k01_21  = ee0[-5] - ee2[-5];
      ee0[-4] += ee2[-4];//ee0[-4] = ee0[-4] + ee2[-4];
      ee0[-5] += ee2[-5];//ee0[-5] = ee0[-5] + ee2[-5];
      ee2[-4] = k00_20 * A[0] - k01_21 * A[1];
      ee2[-5] = k01_21 * A[0] + k00_20 * A[1];
      A += 8;

      k00_20  = ee0[-6] - ee2[-6];
      k01_21  = ee0[-7] - ee2[-7];
      ee0[-6] += ee2[-6];//ee0[-6] = ee0[-6] + ee2[-6];
      ee0[-7] += ee2[-7];//ee0[-7] = ee0[-7] + ee2[-7];
      ee2[-6] = k00_20 * A[0] - k01_21 * A[1];
      ee2[-7] = k01_21 * A[0] + k00_20 * A[1];
      A += 8;
      ee0 -= 8;
      ee2 -= 8;
   }
}

static void imdct_step3_inner_r_loop(int lim, float *e, int d0, int k_off, float *A, int k1)
{
   int i;
   float k00_20, k01_21;

   float *e0 = e + d0;
   float *e2 = e0 + k_off;

   for (i=lim >> 2; i > 0; --i) {
      k00_20 = e0[-0] - e2[-0];
      k01_21 = e0[-1] - e2[-1];
      e0[-0] += e2[-0];//e0[-0] = e0[-0] + e2[-0];
      e0[-1] += e2[-1];//e0[-1] = e0[-1] + e2[-1];
      e2[-0] = (k00_20)*A[0] - (k01_21) * A[1];
      e2[-1] = (k01_21)*A[0] + (k00_20) * A[1];

      A += k1;

      k00_20 = e0[-2] - e2[-2];
      k01_21 = e0[-3] - e2[-3];
      e0[-2] += e2[-2];//e0[-2] = e0[-2] + e2[-2];
      e0[-3] += e2[-3];//e0[-3] = e0[-3] + e2[-3];
      e2[-2] = (k00_20)*A[0] - (k01_21) * A[1];
      e2[-3] = (k01_21)*A[0] + (k00_20) * A[1];

      A += k1;

      k00_20 = e0[-4] - e2[-4];
      k01_21 = e0[-5] - e2[-5];
      e0[-4] += e2[-4];//e0[-4] = e0[-4] + e2[-4];
      e0[-5] += e2[-5];//e0[-5] = e0[-5] + e2[-5];
      e2[-4] = (k00_20)*A[0] - (k01_21) * A[1];
      e2[-5] = (k01_21)*A[0] + (k00_20) * A[1];

      A += k1;

      k00_20 = e0[-6] - e2[-6];
      k01_21 = e0[-7] - e2[-7];
      e0[-6] += e2[-6];//e0[-6] = e0[-6] + e2[-6];
      e0[-7] += e2[-7];//e0[-7] = e0[-7] + e2[-7];
      e2[-6] = (k00_20)*A[0] - (k01_21) * A[1];
      e2[-7] = (k01_21)*A[0] + (k00_20) * A[1];

      e0 -= 8;
      e2 -= 8;

      A += k1;
   }
}

static void imdct_step3_inner_s_loop(int n, float *e, int i_off, int k_off, float *A, int a_off, int k0)
{
   int i;
   float A0 = A[0];
   float A1 = A[0+1];
   float A2 = A[0+a_off];
   float A3 = A[0+a_off+1];
   float A4 = A[0+a_off*2+0];
   float A5 = A[0+a_off*2+1];
   float A6 = A[0+a_off*3+0];
   float A7 = A[0+a_off*3+1];

   float k00,k11;

   float *ee0 = e  +i_off;
   float *ee2 = ee0+k_off;

   for (i=n; i > 0; --i) {
      k00     = ee0[ 0] - ee2[ 0];
      k11     = ee0[-1] - ee2[-1];
      ee0[ 0] =  ee0[ 0] + ee2[ 0];
      ee0[-1] =  ee0[-1] + ee2[-1];
      ee2[ 0] = (k00) * A0 - (k11) * A1;
      ee2[-1] = (k11) * A0 + (k00) * A1;

      k00     = ee0[-2] - ee2[-2];
      k11     = ee0[-3] - ee2[-3];
      ee0[-2] =  ee0[-2] + ee2[-2];
      ee0[-3] =  ee0[-3] + ee2[-3];
      ee2[-2] = (k00) * A2 - (k11) * A3;
      ee2[-3] = (k11) * A2 + (k00) * A3;

      k00     = ee0[-4] - ee2[-4];
      k11     = ee0[-5] - ee2[-5];
      ee0[-4] =  ee0[-4] + ee2[-4];
      ee0[-5] =  ee0[-5] + ee2[-5];
      ee2[-4] = (k00) * A4 - (k11) * A5;
      ee2[-5] = (k11) * A4 + (k00) * A5;

      k00     = ee0[-6] - ee2[-6];
      k11     = ee0[-7] - ee2[-7];
      ee0[-6] =  ee0[-6] + ee2[-6];
      ee0[-7] =  ee0[-7] + ee2[-7];
      ee2[-6] = (k00) * A6 - (k11) * A7;
      ee2[-7] = (k11) * A6 + (k00) * A7;

      ee0 -= k0;
      ee2 -= k0;
   }
}

static __forceinline void iter_54(float *z)
{
   float k00,k11,k22,k33;
   float y0,y1,y2,y3;

   k00  = z[ 0] - z[-4];
   y0   = z[ 0] + z[-4];
   y2   = z[-2] + z[-6];
   k22  = z[-2] - z[-6];

   z[-0] = y0 + y2;      // z0 + z4 + z2 + z6
   z[-2] = y0 - y2;      // z0 + z4 - z2 - z6

   // done with y0,y2

   k33  = z[-3] - z[-7];

   z[-4] = k00 + k33;    // z0 - z4 + z3 - z7
   z[-6] = k00 - k33;    // z0 - z4 - z3 + z7

   // done with k33

   k11  = z[-1] - z[-5];
   y1   = z[-1] + z[-5];
   y3   = z[-3] + z[-7];

   z[-1] = y1 + y3;      // z1 + z5 + z3 + z7
   z[-3] = y1 - y3;      // z1 + z5 - z3 - z7
   z[-5] = k11 - k22;    // z1 - z5 + z2 - z6
   z[-7] = k11 + k22;    // z1 - z5 - z2 + z6
}

static void imdct_step3_inner_s_loop_ld654(int n, float *e, int i_off, float *A, int base_n)
{
   int a_off = base_n >> 3;
   float A2 = A[0+a_off];
   float *z = e + i_off;
   float *base = z - 16 * n;

   while (z > base) {
      float k00,k11;

      k00   = z[-0] - z[-8];
      k11   = z[-1] - z[-9];
      z[-0] = z[-0] + z[-8];
      z[-1] = z[-1] + z[-9];
      z[-8] =  k00;
      z[-9] =  k11 ;

      k00    = z[ -2] - z[-10];
      k11    = z[ -3] - z[-11];
      z[ -2] = z[ -2] + z[-10];
      z[ -3] = z[ -3] + z[-11];
      z[-10] = (k00+k11) * A2;
      z[-11] = (k11-k00) * A2;

      k00    = z[-12] - z[ -4];  // reverse to avoid a unary negation
      k11    = z[ -5] - z[-13];
      z[ -4] = z[ -4] + z[-12];
      z[ -5] = z[ -5] + z[-13];
      z[-12] = k11;
      z[-13] = k00;

      k00    = z[-14] - z[ -6];  // reverse to avoid a unary negation
      k11    = z[ -7] - z[-15];
      z[ -6] = z[ -6] + z[-14];
      z[ -7] = z[ -7] + z[-15];
      z[-14] = (k00+k11) * A2;
      z[-15] = (k00-k11) * A2;

      iter_54(z);
      iter_54(z-8);
      z -= 16;
   }
}

static void inverse_mdct(float *buffer, int n, vorb *f, int blocktype)
{
   int n2 = n >> 1, n4 = n >> 2, n8 = n >> 3, l;
   int ld;
   // @OPTIMIZE: reduce register pressure by using fewer variables?
   int save_point = temp_alloc_save(f);
   float *buf2 = (float *) temp_alloc(f, n2 * sizeof(*buf2));
   float *u=NULL,*v=NULL;
   // twiddle factors
   float *A = f->A[blocktype];

   // IMDCT algorithm from "The use of multirate filter banks for coding of high quality digital audio"
   // See notes about bugs in that paper in less-optimal implementation 'inverse_mdct_old' after this function.

   // kernel from paper


   // merged:
   //   copy and reflect spectral data
   //   step 0

   // note that it turns out that the items added together during
   // this step are, in fact, being added to themselves (as reflected
   // by step 0). inexplicable inefficiency! this became obvious
   // once I combined the passes.

   // so there's a missing 'times 2' here (for adding X to itself).
   // this propogates through linearly to the end, where the numbers
   // are 1/2 too small, and need to be compensated for.

   {
      float *d,*e, *AA, *e_stop;
      d = &buf2[n2-2];
      AA = A;
      e = &buffer[0];
      e_stop = &buffer[n2];
      while (e != e_stop) {
         d[1] = (e[0] * AA[0] - e[2]*AA[1]);
         d[0] = (e[0] * AA[1] + e[2]*AA[0]);
         d -= 2;
         AA += 2;
         e += 4;
      }

      e = &buffer[n2-3];
      while (d >= buf2) {
         d[1] = (-e[2] * AA[0] - -e[0]*AA[1]);
         d[0] = (-e[2] * AA[1] + -e[0]*AA[0]);
         d -= 2;
         AA += 2;
         e -= 4;
      }
   }

   // now we use symbolic names for these, so that we can
   // possibly swap their meaning as we change which operations
   // are in place

   u = buffer;
   v = buf2;

   // step 2    (paper output is w, now u)
   // this could be in place, but the data ends up in the wrong
   // place... _somebody_'s got to swap it, so this is nominated
   {
      float *AA = &A[n2-8];
      float *d0,*d1, *e0, *e1;

      e0 = &v[n4];
      e1 = &v[0];

      d0 = &u[n4];
      d1 = &u[0];

      while (AA >= A) {
         float v40_20, v41_21;

         v41_21 = e0[1] - e1[1];
         v40_20 = e0[0] - e1[0];
         d0[1]  = e0[1] + e1[1];
         d0[0]  = e0[0] + e1[0];
         d1[1]  = v41_21*AA[4] - v40_20*AA[5];
         d1[0]  = v40_20*AA[4] + v41_21*AA[5];

         v41_21 = e0[3] - e1[3];
         v40_20 = e0[2] - e1[2];
         d0[3]  = e0[3] + e1[3];
         d0[2]  = e0[2] + e1[2];
         d1[3]  = v41_21*AA[0] - v40_20*AA[1];
         d1[2]  = v40_20*AA[0] + v41_21*AA[1];

         AA -= 8;

         d0 += 4;
         d1 += 4;
         e0 += 4;
         e1 += 4;
      }
   }

   // step 3
   ld = ilog(n) - 1; // ilog is off-by-one from normal definitions

   // optimized step 3:

   // the original step3 loop can be nested r inside s or s inside r;
   // it's written originally as s inside r, but this is dumb when r
   // iterates many times, and s few. So I have two copies of it and
   // switch between them halfway.

   // this is iteration 0 of step 3
   imdct_step3_iter0_loop(n >> 4, u, n2-1-n4*0, -(n >> 3), A);
   imdct_step3_iter0_loop(n >> 4, u, n2-1-n4*1, -(n >> 3), A);

   // this is iteration 1 of step 3
   imdct_step3_inner_r_loop(n >> 5, u, n2-1 - n8*0, -(n >> 4), A, 16);
   imdct_step3_inner_r_loop(n >> 5, u, n2-1 - n8*1, -(n >> 4), A, 16);
   imdct_step3_inner_r_loop(n >> 5, u, n2-1 - n8*2, -(n >> 4), A, 16);
   imdct_step3_inner_r_loop(n >> 5, u, n2-1 - n8*3, -(n >> 4), A, 16);

   l=2;
   for (; l < (ld-3)>>1; ++l) {
      int k0 = n >> (l+2), k0_2 = k0>>1;
      int lim = 1 << (l+1);
      int i;
      for (i=0; i < lim; ++i)
         imdct_step3_inner_r_loop(n >> (l+4), u, n2-1 - k0*i, -k0_2, A, 1 << (l+3));
   }

   for (; l < ld-6; ++l) {
      int k0 = n >> (l+2), k1 = 1 << (l+3), k0_2 = k0>>1;
      int rlim = n >> (l+6), r;
      int lim = 1 << (l+1);
      int i_off;
      float *A0 = A;
      i_off = n2-1;
      for (r=rlim; r > 0; --r) {
         imdct_step3_inner_s_loop(lim, u, i_off, -k0_2, A0, k1, k0);
         A0 += k1*4;
         i_off -= 8;
      }
   }

   // iterations with count:
   //   ld-6,-5,-4 all interleaved together
   //       the big win comes from getting rid of needless flops
   //         due to the constants on pass 5 & 4 being all 1 and 0;
   //       combining them to be simultaneous to improve cache made little difference
   imdct_step3_inner_s_loop_ld654(n >> 5, u, n2-1, A, n);

   // output is u

   // step 4, 5, and 6
   // cannot be in-place because of step 5
   {
      uint16 *bitrev = f->bit_reverse[blocktype];
      // weirdly, I'd have thought reading sequentially and writing
      // erratically would have been better than vice-versa, but in
      // fact that's not what my testing showed. (That is, with
      // j = bitreverse(i), do you read i and write j, or read j and write i.)

      float *d0 = &v[n4-4];
      float *d1 = &v[n2-4];
      while (d0 >= v) {
         int k4;

         k4 = bitrev[0];
         d1[3] = u[k4+0];
         d1[2] = u[k4+1];
         d0[3] = u[k4+2];
         d0[2] = u[k4+3];

         k4 = bitrev[1];
         d1[1] = u[k4+0];
         d1[0] = u[k4+1];
         d0[1] = u[k4+2];
         d0[0] = u[k4+3];
         
         d0 -= 4;
         d1 -= 4;
         bitrev += 2;
      }
   }
   // (paper output is u, now v)


   // data must be in buf2
   assert(v == buf2);

   // step 7   (paper output is v, now v)
   // this is now in place
   {
      float *C = f->C[blocktype];
      float *d, *e;

      d = v;
      e = v + n2 - 4;

      while (d < e) {
         float a02,a11,b0,b1,b2,b3;

         a02 = d[0] - e[2];
         a11 = d[1] + e[3];

         b0 = C[1]*a02 + C[0]*a11;
         b1 = C[1]*a11 - C[0]*a02;

         b2 = d[0] + e[ 2];
         b3 = d[1] - e[ 3];

         d[0] = b2 + b0;
         d[1] = b3 + b1;
         e[2] = b2 - b0;
         e[3] = b1 - b3;

         a02 = d[2] - e[0];
         a11 = d[3] + e[1];

         b0 = C[3]*a02 + C[2]*a11;
         b1 = C[3]*a11 - C[2]*a02;

         b2 = d[2] + e[ 0];
         b3 = d[3] - e[ 1];

         d[2] = b2 + b0;
         d[3] = b3 + b1;
         e[0] = b2 - b0;
         e[1] = b1 - b3;

         C += 4;
         d += 4;
         e -= 4;
      }
   }

   // data must be in buf2


   // step 8+decode   (paper output is X, now buffer)
   // this generates pairs of data a la 8 and pushes them directly through
   // the decode kernel (pushing rather than pulling) to avoid having
   // to make another pass later

   // this cannot POSSIBLY be in place, so we refer to the buffers directly

   {
      float *d0,*d1,*d2,*d3;

      float *B = f->B[blocktype] + n2 - 8;
      float *e = buf2 + n2 - 8;
      d0 = &buffer[0];
      d1 = &buffer[n2-4];
      d2 = &buffer[n2];
      d3 = &buffer[n-4];
      while (e >= v) {
         float p0,p1,p2,p3;

         p3 =  e[6]*B[7] - e[7]*B[6];
         p2 = -e[6]*B[6] - e[7]*B[7]; 

         d0[0] =   p3;
         d1[3] = - p3;
         d2[0] =   p2;
         d3[3] =   p2;

         p1 =  e[4]*B[5] - e[5]*B[4];
         p0 = -e[4]*B[4] - e[5]*B[5]; 

         d0[1] =   p1;
         d1[2] = - p1;
         d2[1] =   p0;
         d3[2] =   p0;

         p3 =  e[2]*B[3] - e[3]*B[2];
         p2 = -e[2]*B[2] - e[3]*B[3]; 

         d0[2] =   p3;
         d1[1] = - p3;
         d2[2] =   p2;
         d3[1] =   p2;

         p1 =  e[0]*B[1] - e[1]*B[0];
         p0 = -e[0]*B[0] - e[1]*B[1]; 

         d0[3] =   p1;
         d1[0] = - p1;
         d2[3] =   p0;
         d3[0] =   p0;

         B -= 8;
         e -= 8;
         d0 += 4;
         d2 += 4;
         d1 -= 4;
         d3 -= 4;
      }
   }

   temp_free(f,buf2);
   temp_alloc_restore(f,save_point);
}

#if 0
// this is the original version of the above code, if you want to optimize it from scratch
void inverse_mdct_naive(float *buffer, int n)
{
   float s;
   float A[1 << 12], B[1 << 12], C[1 << 11];
   int i,k,k2,k4, n2 = n >> 1, n4 = n >> 2, n8 = n >> 3, l;
   int n3_4 = n - n4, ld;
   // how can they claim this only uses N words?!
   // oh, because they're only used sparsely, whoops
   float u[1 << 13], X[1 << 13], v[1 << 13], w[1 << 13];
   // set up twiddle factors

   for (k=k2=0; k < n4; ++k,k2+=2) {
      A[k2  ] = (float)  cos(4*k*M_PI/n);
      A[k2+1] = (float) -sin(4*k*M_PI/n);
      B[k2  ] = (float)  cos((k2+1)*M_PI/n/2);
      B[k2+1] = (float)  sin((k2+1)*M_PI/n/2);
   }
   for (k=k2=0; k < n8; ++k,k2+=2) {
      C[k2  ] = (float)  cos(2*(k2+1)*M_PI/n);
      C[k2+1] = (float) -sin(2*(k2+1)*M_PI/n);
   }

   // IMDCT algorithm from "The use of multirate filter banks for coding of high quality digital audio"
   // Note there are bugs in that pseudocode, presumably due to them attempting
   // to rename the arrays nicely rather than representing the way their actual
   // implementation bounces buffers back and forth. As a result, even in the
   // "some formulars corrected" version, a direct implementation fails. These
   // are noted below as "paper bug".

   // copy and reflect spectral data
   for (k=0; k < n2; ++k) u[k] = buffer[k];
   for (   ; k < n ; ++k) u[k] = -buffer[n - k - 1];
   // kernel from paper
   // step 1
   for (k=k2=k4=0; k < n4; k+=1, k2+=2, k4+=4) {
      v[n-k4-1] = (u[k4] - u[n-k4-1]) * A[k2]   - (u[k4+2] - u[n-k4-3])*A[k2+1];
      v[n-k4-3] = (u[k4] - u[n-k4-1]) * A[k2+1] + (u[k4+2] - u[n-k4-3])*A[k2];
   }
   // step 2
   for (k=k4=0; k < n8; k+=1, k4+=4) {
      w[n2+3+k4] = v[n2+3+k4] + v[k4+3];
      w[n2+1+k4] = v[n2+1+k4] + v[k4+1];
      w[k4+3]    = (v[n2+3+k4] - v[k4+3])*A[n2-4-k4] - (v[n2+1+k4]-v[k4+1])*A[n2-3-k4];
      w[k4+1]    = (v[n2+1+k4] - v[k4+1])*A[n2-4-k4] + (v[n2+3+k4]-v[k4+3])*A[n2-3-k4];
   }
   // step 3
   ld = ilog(n) - 1; // ilog is off-by-one from normal definitions
   for (l=0; l < ld-3; ++l) {
      int k0 = n >> (l+2), k1 = 1 << (l+3);
      int rlim = n >> (l+4), r4, r;
      int s2lim = 1 << (l+2), s2;
      for (r=r4=0; r < rlim; r4+=4,++r) {
         for (s2=0; s2 < s2lim; s2+=2) {
            u[n-1-k0*s2-r4] = w[n-1-k0*s2-r4] + w[n-1-k0*(s2+1)-r4];
            u[n-3-k0*s2-r4] = w[n-3-k0*s2-r4] + w[n-3-k0*(s2+1)-r4];
            u[n-1-k0*(s2+1)-r4] = (w[n-1-k0*s2-r4] - w[n-1-k0*(s2+1)-r4]) * A[r*k1]
                                - (w[n-3-k0*s2-r4] - w[n-3-k0*(s2+1)-r4]) * A[r*k1+1];
            u[n-3-k0*(s2+1)-r4] = (w[n-3-k0*s2-r4] - w[n-3-k0*(s2+1)-r4]) * A[r*k1]
                                + (w[n-1-k0*s2-r4] - w[n-1-k0*(s2+1)-r4]) * A[r*k1+1];
         }
      }
      if (l+1 < ld-3) {
         // paper bug: ping-ponging of u&w here is omitted
         memcpy(w, u, sizeof(u));
      }
   }

   // step 4
   for (i=0; i < n8; ++i) {
      int j = bit_reverse(i) >> (32-ld+3);
      assert(j < n8);
      if (i == j) {
         // paper bug: original code probably swapped in place; if copying,
         //            need to directly copy in this case
         int i8 = i << 3;
         v[i8+1] = u[i8+1];
         v[i8+3] = u[i8+3];
         v[i8+5] = u[i8+5];
         v[i8+7] = u[i8+7];
      } else if (i < j) {
         int i8 = i << 3, j8 = j << 3;
         v[j8+1] = u[i8+1], v[i8+1] = u[j8 + 1];
         v[j8+3] = u[i8+3], v[i8+3] = u[j8 + 3];
         v[j8+5] = u[i8+5], v[i8+5] = u[j8 + 5];
         v[j8+7] = u[i8+7], v[i8+7] = u[j8 + 7];
      }
   }
   // step 5
   for (k=0; k < n2; ++k) {
      w[k] = v[k*2+1];
   }
   // step 6
   for (k=k2=k4=0; k < n8; ++k, k2 += 2, k4 += 4) {
      u[n-1-k2] = w[k4];
      u[n-2-k2] = w[k4+1];
      u[n3_4 - 1 - k2] = w[k4+2];
      u[n3_4 - 2 - k2] = w[k4+3];
   }
   // step 7
   for (k=k2=0; k < n8; ++k, k2 += 2) {
      v[n2 + k2 ] = ( u[n2 + k2] + u[n-2-k2] + C[k2+1]*(u[n2+k2]-u[n-2-k2]) + C[k2]*(u[n2+k2+1]+u[n-2-k2+1]))/2;
      v[n-2 - k2] = ( u[n2 + k2] + u[n-2-k2] - C[k2+1]*(u[n2+k2]-u[n-2-k2]) - C[k2]*(u[n2+k2+1]+u[n-2-k2+1]))/2;
      v[n2+1+ k2] = ( u[n2+1+k2] - u[n-1-k2] + C[k2+1]*(u[n2+1+k2]+u[n-1-k2]) - C[k2]*(u[n2+k2]-u[n-2-k2]))/2;
      v[n-1 - k2] = (-u[n2+1+k2] + u[n-1-k2] + C[k2+1]*(u[n2+1+k2]+u[n-1-k2]) - C[k2]*(u[n2+k2]-u[n-2-k2]))/2;
   }
   // step 8
   for (k=k2=0; k < n4; ++k,k2 += 2) {
      X[k]      = v[k2+n2]*B[k2  ] + v[k2+1+n2]*B[k2+1];
      X[n2-1-k] = v[k2+n2]*B[k2+1] - v[k2+1+n2]*B[k2  ];
   }

   // decode kernel to output
   // determined the following value experimentally
   // (by first figuring out what made inverse_mdct_slow work); then matching that here
   // (probably vorbis encoder premultiplies by n or n/2, to save it on the decoder?)
   s = 0.5; // theoretically would be n4

   // [[[ note! the s value of 0.5 is compensated for by the B[] in the current code,
   //     so it needs to use the "old" B values to behave correctly, or else
   //     set s to 1.0 ]]]
   for (i=0; i < n4  ; ++i) buffer[i] = s * X[i+n4];
   for (   ; i < n3_4; ++i) buffer[i] = -s * X[n3_4 - i - 1];
   for (   ; i < n   ; ++i) buffer[i] = -s * X[i - n3_4];
}
#endif

static float *get_window(vorb *f, int len)
{
   len <<= 1;
   if (len == f->blocksize_0) return f->window[0];
   if (len == f->blocksize_1) return f->window[1];
   assert(0);
   return NULL;
}

#ifndef STB_VORBIS_NO_DEFER_FLOOR
typedef int16 YTYPE;
#else
typedef int YTYPE;
#endif
static int do_floor(vorb *f, Mapping *map, int i, int n, float *target, YTYPE *finalY, uint8 *step2_flag)
{
   int n2 = n >> 1;
   int s = map->chan[i].mux, floor;
   floor = map->submap_floor[s];
   if (f->floor_types[floor] == 0) {
      return error(f, VORBIS_invalid_stream);
   } else {
      Floor1 *g = &f->floor_config[floor].floor1;
      int j,q;
      int lx = 0, ly = finalY[0] * g->floor1_multiplier;
      for (q=1; q < g->values; ++q) {
         j = g->sorted_order[q];
         #ifndef STB_VORBIS_NO_DEFER_FLOOR
         if (finalY[j] >= 0)
         #else
         if (step2_flag[j])
         #endif
         {
            int hy = finalY[j] * g->floor1_multiplier;
            int hx = g->Xlist[j];
            if (lx != hx)
               draw_line(target, lx,ly, hx,hy, n2);
            CHECK(f);
            lx = hx, ly = hy;
         }
      }
      if (lx < n2) {
         // optimization of: draw_line(target, lx,ly, n,ly, n2);
         for (j=lx; j < n2; ++j)
            LINE_OP(target[j], inverse_db_table[ly]);
         CHECK(f);
      }
   }
   return TRUE;
}

// The meaning of "left" and "right"
//
// For a given frame:
//     we compute samples from 0..n
//     window_center is n/2
//     we'll window and mix the samples from left_start to left_end with data from the previous frame
//     all of the samples from left_end to right_start can be output without mixing; however,
//        this interval is 0-length except when transitioning between short and long frames
//     all of the samples from right_start to right_end need to be mixed with the next frame,
//        which we don't have, so those get saved in a buffer
//     frame N's right_end-right_start, the number of samples to mix with the next frame,
//        has to be the same as frame N+1's left_end-left_start (which they are by
//        construction)

static int vorbis_decode_initial(vorb *f, int *p_left_start, int *p_left_end, int *p_right_start, int *p_right_end, int *mode)
{
   Mode *m;
   int i, n, prev, next, window_center;
   f->channel_buffer_start = f->channel_buffer_end = 0;

  retry:
   if (f->eof) return FALSE;
   if (!maybe_start_packet(f))
      return FALSE;
   // check packet type
   if (get_bits(f,1) != 0) {
      if (IS_PUSH_MODE(f))
         return error(f,VORBIS_bad_packet_type);
      while (EOP != get8_packet(f));
      goto retry;
   }

   if (f->alloc.alloc_buffer)
      assert(f->alloc.alloc_buffer_length_in_bytes == f->temp_offset);

   i = get_bits(f, ilog(f->mode_count-1));
   if (i == EOP) return FALSE;
   if (i >= f->mode_count) return FALSE;
   *mode = i;
   m = f->mode_config + i;
   if (m->blockflag) {
      n = f->blocksize_1;
      prev = get_bits(f,1);
      next = get_bits(f,1);
   } else {
      prev = next = 0;
      n = f->blocksize_0;
   }

// WINDOWING

   window_center = n >> 1;
   if (m->blockflag && !prev) {
      *p_left_start = (n - f->blocksize_0) >> 2;
      *p_left_end   = (n + f->blocksize_0) >> 2;
   } else {
      *p_left_start = 0;
      *p_left_end   = window_center;
   }
   if (m->blockflag && !next) {
      *p_right_start = (n*3 - f->blocksize_0) >> 2;
      *p_right_end   = (n*3 + f->blocksize_0) >> 2;
   } else {
      *p_right_start = window_center;
      *p_right_end   = n;
   }

   return TRUE;
}

static int vorbis_decode_packet_rest(vorb *f, int *len, Mode *m, int left_start, int left_end, int right_start, int right_end, int *p_left)
{
   Mapping *map;
   int i,j,k,n,n2;
   int zero_channel[256];
   int really_zero_channel[256];

// WINDOWING

   n = f->blocksize[m->blockflag];
   map = &f->mapping[m->mapping];

// FLOORS
   n2 = n >> 1;

   CHECK(f);

   for (i=0; i < f->channels; ++i) {
      int s = map->chan[i].mux, floor;
      zero_channel[i] = FALSE;
      floor = map->submap_floor[s];
      if (f->floor_types[floor] == 0) {
         return error(f, VORBIS_invalid_stream);
      } else {
         Floor1 *g = &f->floor_config[floor].floor1;
         if (get_bits(f, 1)) {
            short *finalY;
            uint8 step2_flag[256];
            static int range_list[4] = { 256, 128, 86, 64 };
            int range = range_list[g->floor1_multiplier-1];
            int offset = 2;
            finalY = f->finalY[i];
            finalY[0] = get_bits(f, ilog(range)-1);
            finalY[1] = get_bits(f, ilog(range)-1);
            for (j=0; j < g->partitions; ++j) {
               int pclass = g->partition_class_list[j];
               int cdim = g->class_dimensions[pclass];
               int cbits = g->class_subclasses[pclass];
               int csub = (1 << cbits)-1;
               int cval = 0;
               if (cbits) {
                  Codebook *c = f->codebooks + g->class_masterbooks[pclass];
                  DECODE(cval,f,c);
               }
               for (k=0; k < cdim; ++k) {
                  int book = g->subclass_books[pclass][cval & csub];
                  cval = cval >> cbits;
                  if (book >= 0) {
                     int temp;
                     Codebook *c = f->codebooks + book;
                     DECODE(temp,f,c);
                     finalY[offset++] = temp;
                  } else
                     finalY[offset++] = 0;
               }
            }
            if (f->valid_bits == INVALID_BITS) goto error; // behavior according to spec
            step2_flag[0] = step2_flag[1] = 1;
            for (j=2; j < g->values; ++j) {
               int low, high, pred, highroom, lowroom, room, val;
               low = g->neighbors[j][0];
               high = g->neighbors[j][1];
               //neighbors(g->Xlist, j, &low, &high);
               pred = predict_point(g->Xlist[j], g->Xlist[low], g->Xlist[high], finalY[low], finalY[high]);
               val = finalY[j];
               highroom = range - pred;
               lowroom = pred;
               if (highroom < lowroom)
                  room = highroom * 2;
               else
                  room = lowroom * 2;
               if (val) {
                  step2_flag[low] = step2_flag[high] = 1;
                  step2_flag[j] = 1;
                  if (val >= room)
                     if (highroom > lowroom)
                        finalY[j] = val - lowroom + pred;
                     else
                        finalY[j] = pred - val + highroom - 1;
                  else
                     if (val & 1)
                        finalY[j] = pred - ((val+1)>>1);
                     else
                        finalY[j] = pred + (val>>1);
               } else {
                  step2_flag[j] = 0;
                  finalY[j] = pred;
               }
            }

#ifdef STB_VORBIS_NO_DEFER_FLOOR
            do_floor(f, map, i, n, f->floor_buffers[i], finalY, step2_flag);
#else
            // defer final floor computation until _after_ residue
            for (j=0; j < g->values; ++j) {
               if (!step2_flag[j])
                  finalY[j] = -1;
            }
#endif
         } else {
           error:
            zero_channel[i] = TRUE;
         }
         // So we just defer everything else to later

         // at this point we've decoded the floor into buffer
      }
   }
   CHECK(f);
   // at this point we've decoded all floors

   if (f->alloc.alloc_buffer)
      assert(f->alloc.alloc_buffer_length_in_bytes == f->temp_offset);

   // re-enable coupled channels if necessary
   memcpy(really_zero_channel, zero_channel, sizeof(really_zero_channel[0]) * f->channels);
   for (i=0; i < map->coupling_steps; ++i)
      if (!zero_channel[map->chan[i].magnitude] || !zero_channel[map->chan[i].angle]) {
         zero_channel[map->chan[i].magnitude] = zero_channel[map->chan[i].angle] = FALSE;
      }

   CHECK(f);
// RESIDUE DECODE
   for (i=0; i < map->submaps; ++i) {
      float *residue_buffers[STB_VORBIS_MAX_CHANNELS];
      int r;
      uint8 do_not_decode[256];
      int ch = 0;
      for (j=0; j < f->channels; ++j) {
         if (map->chan[j].mux == i) {
            if (zero_channel[j]) {
               do_not_decode[ch] = TRUE;
               residue_buffers[ch] = NULL;
            } else {
               do_not_decode[ch] = FALSE;
               residue_buffers[ch] = f->channel_buffers[j];
            }
            ++ch;
         }
      }
      r = map->submap_residue[i];
      decode_residue(f, residue_buffers, ch, n2, r, do_not_decode);
   }

   if (f->alloc.alloc_buffer)
      assert(f->alloc.alloc_buffer_length_in_bytes == f->temp_offset);
   CHECK(f);

// INVERSE COUPLING
   for (i = map->coupling_steps-1; i >= 0; --i) {
      int n2 = n >> 1;
      float *m = f->channel_buffers[map->chan[i].magnitude];
      float *a = f->channel_buffers[map->chan[i].angle    ];
      for (j=0; j < n2; ++j) {
         float a2,m2;
         if (m[j] > 0)
            if (a[j] > 0)
               m2 = m[j], a2 = m[j] - a[j];
            else
               a2 = m[j], m2 = m[j] + a[j];
         else
            if (a[j] > 0)
               m2 = m[j], a2 = m[j] + a[j];
            else
               a2 = m[j], m2 = m[j] - a[j];
         m[j] = m2;
         a[j] = a2;
      }
   }
   CHECK(f);

   // finish decoding the floors
#ifndef STB_VORBIS_NO_DEFER_FLOOR
   for (i=0; i < f->channels; ++i) {
      if (really_zero_channel[i]) {
         memset(f->channel_buffers[i], 0, sizeof(*f->channel_buffers[i]) * n2);
      } else {
         do_floor(f, map, i, n, f->channel_buffers[i], f->finalY[i], NULL);
      }
   }
#else
   for (i=0; i < f->channels; ++i) {
      if (really_zero_channel[i]) {
         memset(f->channel_buffers[i], 0, sizeof(*f->channel_buffers[i]) * n2);
      } else {
         for (j=0; j < n2; ++j)
            f->channel_buffers[i][j] *= f->floor_buffers[i][j];
      }
   }
#endif

// INVERSE MDCT
   CHECK(f);
   for (i=0; i < f->channels; ++i)
      inverse_mdct(f->channel_buffers[i], n, f, m->blockflag);
   CHECK(f);

   // this shouldn't be necessary, unless we exited on an error
   // and want to flush to get to the next packet
   flush_packet(f);

   if (f->first_decode) {
      // assume we start so first non-discarded sample is sample 0
      // this isn't to spec, but spec would require us to read ahead
      // and decode the size of all current frames--could be done,
      // but presumably it's not a commonly used feature
      f->current_loc = -n2; // start of first frame is positioned for discard
      // we might have to discard samples "from" the next frame too,
      // if we're lapping a large block then a small at the start?
      f->discard_samples_deferred = n - right_end;
      f->current_loc_valid = TRUE;
      f->first_decode = FALSE;
   } else if (f->discard_samples_deferred) {
      if (f->discard_samples_deferred >= right_start - left_start) {
         f->discard_samples_deferred -= (right_start - left_start);
         left_start = right_start;
         *p_left = left_start;
      } else {
         left_start += f->discard_samples_deferred;
         *p_left = left_start;
         f->discard_samples_deferred = 0;
      }
   } else if (f->previous_length == 0 && f->current_loc_valid) {
      // we're recovering from a seek... that means we're going to discard
      // the samples from this packet even though we know our position from
      // the last page header, so we need to update the position based on
      // the discarded samples here
      // but wait, the code below is going to add this in itself even
      // on a discard, so we don't need to do it here...
   }

   // check if we have ogg information about the sample # for this packet
   if (f->last_seg_which == f->end_seg_with_known_loc) {
      // if we have a valid current loc, and this is final:
      if (f->current_loc_valid && (f->page_flag & PAGEFLAG_last_page)) {
         uint32 current_end = f->known_loc_for_packet - (n-right_end);
         // then let's infer the size of the (probably) short final frame
         if (current_end < f->current_loc + (right_end-left_start)) {
            if (current_end < f->current_loc) {
               // negative truncation, that's impossible!
               *len = 0;
            } else {
               *len = current_end - f->current_loc;
            }
            *len += left_start;
            if (*len > right_end) *len = right_end; // this should never happen
            f->current_loc += *len;
            return TRUE;
         }
      }
      // otherwise, just set our sample loc
      // guess that the ogg granule pos refers to the _middle_ of the
      // last frame?
      // set f->current_loc to the position of left_start
      f->current_loc = f->known_loc_for_packet - (n2-left_start);
      f->current_loc_valid = TRUE;
   }
   if (f->current_loc_valid)
      f->current_loc += (right_start - left_start);

   if (f->alloc.alloc_buffer)
      assert(f->alloc.alloc_buffer_length_in_bytes == f->temp_offset);
   *len = right_end;  // ignore samples after the window goes to 0
   CHECK(f);

   return TRUE;
}

static int vorbis_decode_packet(vorb *f, int *len, int *p_left, int *p_right)
{
   int mode, left_end, right_end;
   if (!vorbis_decode_initial(f, p_left, &left_end, p_right, &right_end, &mode)) return 0;
   return vorbis_decode_packet_rest(f, len, f->mode_config + mode, *p_left, left_end, *p_right, right_end, p_left);
}

static int vorbis_finish_frame(stb_vorbis *f, int len, int left, int right)
{
   int prev,i,j;
   // we use right&left (the start of the right- and left-window sin()-regions)
   // to determine how much to return, rather than inferring from the rules
   // (same result, clearer code); 'left' indicates where our sin() window
   // starts, therefore where the previous window's right edge starts, and
   // therefore where to start mixing from the previous buffer. 'right'
   // indicates where our sin() ending-window starts, therefore that's where
   // we start saving, and where our returned-data ends.

   // mixin from previous window
   if (f->previous_length) {
      int i,j, n = f->previous_length;
      float *w = get_window(f, n);
      for (i=0; i < f->channels; ++i) {
         for (j=0; j < n; ++j)
            f->channel_buffers[i][left+j] =
               f->channel_buffers[i][left+j]*w[    j] +
               f->previous_window[i][     j]*w[n-1-j];
      }
   }

   prev = f->previous_length;

   // last half of this data becomes previous window
   f->previous_length = len - right;

   // @OPTIMIZE: could avoid this copy by double-buffering the
   // output (flipping previous_window with channel_buffers), but
   // then previous_window would have to be 2x as large, and
   // channel_buffers couldn't be temp mem (although they're NOT
   // currently temp mem, they could be (unless we want to level
   // performance by spreading out the computation))
   for (i=0; i < f->channels; ++i)
      for (j=0; right+j < len; ++j)
         f->previous_window[i][j] = f->channel_buffers[i][right+j];

   if (!prev)
      // there was no previous packet, so this data isn't valid...
      // this isn't entirely true, only the would-have-overlapped data
      // isn't valid, but this seems to be what the spec requires
      return 0;

   // truncate a short frame
   if (len < right) right = len;

   f->samples_output += right-left;

   return right - left;
}

static void vorbis_pump_first_frame(stb_vorbis *f)
{
   int len, right, left;
   if (vorbis_decode_packet(f, &len, &left, &right))
      vorbis_finish_frame(f, len, left, right);
}

#ifndef STB_VORBIS_NO_PUSHDATA_API
static int is_whole_packet_present(stb_vorbis *f, int end_page)
{
   // make sure that we have the packet available before continuing...
   // this requires a full ogg parse, but we know we can fetch from f->stream

   // instead of coding this out explicitly, we could save the current read state,
   // read the next packet with get8() until end-of-packet, check f->eof, then
   // reset the state? but that would be slower, esp. since we'd have over 256 bytes
   // of state to restore (primarily the page segment table)

   int s = f->next_seg, first = TRUE;
   uint8 *p = f->stream;

   if (s != -1) { // if we're not starting the packet with a 'continue on next page' flag
      for (; s < f->segment_count; ++s) {
         p += f->segments[s];
         if (f->segments[s] < 255)               // stop at first short segment
            break;
      }
      // either this continues, or it ends it...
      if (end_page)
         if (s < f->segment_count-1)             return error(f, VORBIS_invalid_stream);
      if (s == f->segment_count)
         s = -1; // set 'crosses page' flag
      if (p > f->stream_end)                     return error(f, VORBIS_need_more_data);
      first = FALSE;
   }
   for (; s == -1;) {
      uint8 *q; 
      int n;

      // check that we have the page header ready
      if (p + 26 >= f->stream_end)               return error(f, VORBIS_need_more_data);
      // validate the page
      if (memcmp(p, ogg_page_header, 4))         return error(f, VORBIS_invalid_stream);
      if (p[4] != 0)                             return error(f, VORBIS_invalid_stream);
      if (first) { // the first segment must NOT have 'continued_packet', later ones MUST
         if (f->previous_length)
            if ((p[5] & PAGEFLAG_continued_packet))  return error(f, VORBIS_invalid_stream);
         // if no previous length, we're resynching, so we can come in on a continued-packet,
         // which we'll just drop
      } else {
         if (!(p[5] & PAGEFLAG_continued_packet)) return error(f, VORBIS_invalid_stream);
      }
      n = p[26]; // segment counts
      q = p+27;  // q points to segment table
      p = q + n; // advance past header
      // make sure we've read the segment table
      if (p > f->stream_end)                     return error(f, VORBIS_need_more_data);
      for (s=0; s < n; ++s) {
         p += q[s];
         if (q[s] < 255)
            break;
      }
      if (end_page)
         if (s < n-1)                            return error(f, VORBIS_invalid_stream);
      if (s == n)
         s = -1; // set 'crosses page' flag
      if (p > f->stream_end)                     return error(f, VORBIS_need_more_data);
      first = FALSE;
   }
   return TRUE;
}
#endif // !STB_VORBIS_NO_PUSHDATA_API

static int start_decoder(vorb *f)
{
   uint8 header[6], x,y;
   int len,i,j,k, max_submaps = 0;
   int longest_floorlist=0;

   // first page, first packet

   if (!start_page(f))                              return FALSE;
   // validate page flag
   if (!(f->page_flag & PAGEFLAG_first_page))       return error(f, VORBIS_invalid_first_page);
   if (f->page_flag & PAGEFLAG_last_page)           return error(f, VORBIS_invalid_first_page);
   if (f->page_flag & PAGEFLAG_continued_packet)    return error(f, VORBIS_invalid_first_page);
   // check for expected packet length
   if (f->segment_count != 1)                       return error(f, VORBIS_invalid_first_page);
   if (f->segments[0] != 30)                        return error(f, VORBIS_invalid_first_page);
   // read packet
   // check packet header
   if (get8(f) != VORBIS_packet_id)                 return error(f, VORBIS_invalid_first_page);
   if (!getn(f, header, 6))                         return error(f, VORBIS_unexpected_eof);
   if (!vorbis_validate(header))                    return error(f, VORBIS_invalid_first_page);
   // vorbis_version
   if (get32(f) != 0)                               return error(f, VORBIS_invalid_first_page);
   f->channels = get8(f); if (!f->channels)         return error(f, VORBIS_invalid_first_page);
   if (f->channels > STB_VORBIS_MAX_CHANNELS)       return error(f, VORBIS_too_many_channels);
   f->sample_rate = get32(f); if (!f->sample_rate)  return error(f, VORBIS_invalid_first_page);
   get32(f); // bitrate_maximum
   get32(f); // bitrate_nominal
   get32(f); // bitrate_minimum
   x = get8(f);
   {
      int log0,log1;
      log0 = x & 15;
      log1 = x >> 4;
      f->blocksize_0 = 1 << log0;
      f->blocksize_1 = 1 << log1;
      if (log0 < 6 || log0 > 13)                       return error(f, VORBIS_invalid_setup);
      if (log1 < 6 || log1 > 13)                       return error(f, VORBIS_invalid_setup);
      if (log0 > log1)                                 return error(f, VORBIS_invalid_setup);
   }

   // framing_flag
   x = get8(f);
   if (!(x & 1))                                    return error(f, VORBIS_invalid_first_page);

   // second packet!
   if (!start_page(f))                              return FALSE;

   if (!start_packet(f))                            return FALSE;
   do {
      len = next_segment(f);
      skip(f, len);
      f->bytes_in_seg = 0;
   } while (len);

   // third packet!
   if (!start_packet(f))                            return FALSE;

   #ifndef STB_VORBIS_NO_PUSHDATA_API
   if (IS_PUSH_MODE(f)) {
      if (!is_whole_packet_present(f, TRUE)) {
         // convert error in ogg header to write type
         if (f->error == VORBIS_invalid_stream)
            f->error = VORBIS_invalid_setup;
         return FALSE;
      }
   }
   #endif

   crc32_init(); // always init it, to avoid multithread race conditions

   if (get8_packet(f) != VORBIS_packet_setup)       return error(f, VORBIS_invalid_setup);
   for (i=0; i < 6; ++i) header[i] = get8_packet(f);
   if (!vorbis_validate(header))                    return error(f, VORBIS_invalid_setup);

   // codebooks

   f->codebook_count = get_bits(f,8) + 1;
   f->codebooks = (Codebook *) setup_malloc(f, sizeof(*f->codebooks) * f->codebook_count);
   if (f->codebooks == NULL)                        return error(f, VORBIS_outofmem);
   memset(f->codebooks, 0, sizeof(*f->codebooks) * f->codebook_count);
   for (i=0; i < f->codebook_count; ++i) {
      uint32 *values;
      int ordered, sorted_count;
      int total=0;
      uint8 *lengths;
      Codebook *c = f->codebooks+i;
      CHECK(f);
      x = get_bits(f, 8); if (x != 0x42)            return error(f, VORBIS_invalid_setup);
      x = get_bits(f, 8); if (x != 0x43)            return error(f, VORBIS_invalid_setup);
      x = get_bits(f, 8); if (x != 0x56)            return error(f, VORBIS_invalid_setup);
      x = get_bits(f, 8);
      c->dimensions = (get_bits(f, 8)<<8) + x;
      x = get_bits(f, 8);
      y = get_bits(f, 8);
      c->entries = (get_bits(f, 8)<<16) + (y<<8) + x;
      ordered = get_bits(f,1);
      c->sparse = ordered ? 0 : get_bits(f,1);

      if (c->dimensions == 0 && c->entries != 0)    return error(f, VORBIS_invalid_setup);

      if (c->sparse)
         lengths = (uint8 *) setup_temp_malloc(f, c->entries);
      else
         lengths = c->codeword_lengths = (uint8 *) setup_malloc(f, c->entries);

      if (!lengths) return error(f, VORBIS_outofmem);

      if (ordered) {
         int current_entry = 0;
         int current_length = get_bits(f,5) + 1;
         while (current_entry < c->entries) {
            int limit = c->entries - current_entry;
            int n = get_bits(f, ilog(limit));
            if (current_entry + n > (int) c->entries) { return error(f, VORBIS_invalid_setup); }
            memset(lengths + current_entry, current_length, n);
            current_entry += n;
            ++current_length;
         }
      } else {
         for (j=0; j < c->entries; ++j) {
            int present = c->sparse ? get_bits(f,1) : 1;
            if (present) {
               lengths[j] = get_bits(f, 5) + 1;
               ++total;
               if (lengths[j] == 32)
                  return error(f, VORBIS_invalid_setup);
            } else {
               lengths[j] = NO_CODE;
            }
         }
      }

      if (c->sparse && total >= c->entries >> 2) {
         // convert sparse items to non-sparse!
         if (c->entries > (int) f->setup_temp_memory_required)
            f->setup_temp_memory_required = c->entries;

         c->codeword_lengths = (uint8 *) setup_malloc(f, c->entries);
         if (c->codeword_lengths == NULL) return error(f, VORBIS_outofmem);
         memcpy(c->codeword_lengths, lengths, c->entries);
         setup_temp_free(f, lengths, c->entries); // note this is only safe if there have been no intervening temp mallocs!
         lengths = c->codeword_lengths;
         c->sparse = 0;
      }

      // compute the size of the sorted tables
      if (c->sparse) {
         sorted_count = total;
      } else {
         sorted_count = 0;
         #ifndef STB_VORBIS_NO_HUFFMAN_BINARY_SEARCH
         for (j=0; j < c->entries; ++j)
            if (lengths[j] > STB_VORBIS_FAST_HUFFMAN_LENGTH && lengths[j] != NO_CODE)
               ++sorted_count;
         #endif
      }

      c->sorted_entries = sorted_count;
      values = NULL;

      CHECK(f);
      if (!c->sparse) {
         c->codewords = (uint32 *) setup_malloc(f, sizeof(c->codewords[0]) * c->entries);
         if (!c->codewords)                  return error(f, VORBIS_outofmem);
      } else {
         unsigned int size;
         if (c->sorted_entries) {
            c->codeword_lengths = (uint8 *) setup_malloc(f, c->sorted_entries);
            if (!c->codeword_lengths)           return error(f, VORBIS_outofmem);
            c->codewords = (uint32 *) setup_temp_malloc(f, sizeof(*c->codewords) * c->sorted_entries);
            if (!c->codewords)                  return error(f, VORBIS_outofmem);
            values = (uint32 *) setup_temp_malloc(f, sizeof(*values) * c->sorted_entries);
            if (!values)                        return error(f, VORBIS_outofmem);
         }
         size = c->entries + (sizeof(*c->codewords) + sizeof(*values)) * c->sorted_entries;
         if (size > f->setup_temp_memory_required)
            f->setup_temp_memory_required = size;
      }

      if (!compute_codewords(c, lengths, c->entries, values)) {
         if (c->sparse) setup_temp_free(f, values, 0);
         return error(f, VORBIS_invalid_setup);
      }

      if (c->sorted_entries) {
         // allocate an extra slot for sentinels
         c->sorted_codewords = (uint32 *) setup_malloc(f, sizeof(*c->sorted_codewords) * (c->sorted_entries+1));
         if (c->sorted_codewords == NULL) return error(f, VORBIS_outofmem);
         // allocate an extra slot at the front so that c->sorted_values[-1] is defined
         // so that we can catch that case without an extra if
         c->sorted_values    = ( int   *) setup_malloc(f, sizeof(*c->sorted_values   ) * (c->sorted_entries+1));
         if (c->sorted_values == NULL) return error(f, VORBIS_outofmem);
         ++c->sorted_values;
         c->sorted_values[-1] = -1;
         compute_sorted_huffman(c, lengths, values);
      }

      if (c->sparse) {
         setup_temp_free(f, values, sizeof(*values)*c->sorted_entries);
         setup_temp_free(f, c->codewords, sizeof(*c->codewords)*c->sorted_entries);
         setup_temp_free(f, lengths, c->entries);
         c->codewords = NULL;
      }

      compute_accelerated_huffman(c);

      CHECK(f);
      c->lookup_type = get_bits(f, 4);
      if (c->lookup_type > 2) return error(f, VORBIS_invalid_setup);
      if (c->lookup_type > 0) {
         uint16 *mults;
         c->minimum_value = float32_unpack(get_bits(f, 32));
         c->delta_value = float32_unpack(get_bits(f, 32));
         c->value_bits = get_bits(f, 4)+1;
         c->sequence_p = get_bits(f,1);
         if (c->lookup_type == 1) {
            c->lookup_values = lookup1_values(c->entries, c->dimensions);
         } else {
            c->lookup_values = c->entries * c->dimensions;
         }
         if (c->lookup_values == 0) return error(f, VORBIS_invalid_setup);
         mults = (uint16 *) setup_temp_malloc(f, sizeof(mults[0]) * c->lookup_values);
         if (mults == NULL) return error(f, VORBIS_outofmem);
         for (j=0; j < (int) c->lookup_values; ++j) {
            int q = get_bits(f, c->value_bits);
            if (q == EOP) { setup_temp_free(f,mults,sizeof(mults[0])*c->lookup_values); return error(f, VORBIS_invalid_setup); }
            mults[j] = q;
         }

#ifndef STB_VORBIS_DIVIDES_IN_CODEBOOK
         if (c->lookup_type == 1) {
            int len, sparse = c->sparse;
            float last=0;
            // pre-expand the lookup1-style multiplicands, to avoid a divide in the inner loop
            if (sparse) {
               if (c->sorted_entries == 0) goto skip;
               c->multiplicands = (codetype *) setup_malloc(f, sizeof(c->multiplicands[0]) * c->sorted_entries * c->dimensions);
            } else
               c->multiplicands = (codetype *) setup_malloc(f, sizeof(c->multiplicands[0]) * c->entries        * c->dimensions);
            if (c->multiplicands == NULL) { setup_temp_free(f,mults,sizeof(mults[0])*c->lookup_values); return error(f, VORBIS_outofmem); }
            len = sparse ? c->sorted_entries : c->entries;
            for (j=0; j < len; ++j) {
               unsigned int z = sparse ? c->sorted_values[j] : j;
               unsigned int div=1;
               for (k=0; k < c->dimensions; ++k) {
                  int off = (z / div) % c->lookup_values;
                  float val = mults[off];
                  val = mults[off]*c->delta_value + c->minimum_value + last;
                  c->multiplicands[j*c->dimensions + k] = val;
                  if (c->sequence_p)
                     last = val;
                  if (k+1 < c->dimensions) {
                     if (div > UINT_MAX / (unsigned int) c->lookup_values) {
                        setup_temp_free(f, mults,sizeof(mults[0])*c->lookup_values);
                        return error(f, VORBIS_invalid_setup);
                     }
                     div *= c->lookup_values;
                  }
               }
            }
            c->lookup_type = 2;
         }
         else
#endif
         {
            float last=0;
            CHECK(f);
            c->multiplicands = (codetype *) setup_malloc(f, sizeof(c->multiplicands[0]) * c->lookup_values);
            if (c->multiplicands == NULL) { setup_temp_free(f, mults,sizeof(mults[0])*c->lookup_values); return error(f, VORBIS_outofmem); }
            for (j=0; j < (int) c->lookup_values; ++j) {
               float val = mults[j] * c->delta_value + c->minimum_value + last;
               c->multiplicands[j] = val;
               if (c->sequence_p)
                  last = val;
            }
         }
#ifndef STB_VORBIS_DIVIDES_IN_CODEBOOK
        skip:;
#endif
         setup_temp_free(f, mults, sizeof(mults[0])*c->lookup_values);

         CHECK(f);
      }
      CHECK(f);
   }

   // time domain transfers (notused)

   x = get_bits(f, 6) + 1;
   for (i=0; i < x; ++i) {
      uint32 z = get_bits(f, 16);
      if (z != 0) return error(f, VORBIS_invalid_setup);
   }

   // Floors
   f->floor_count = get_bits(f, 6)+1;
   f->floor_config = (Floor *)  setup_malloc(f, f->floor_count * sizeof(*f->floor_config));
   if (f->floor_config == NULL) return error(f, VORBIS_outofmem);
   for (i=0; i < f->floor_count; ++i) {
      f->floor_types[i] = get_bits(f, 16);
      if (f->floor_types[i] > 1) return error(f, VORBIS_invalid_setup);
      if (f->floor_types[i] == 0) {
         Floor0 *g = &f->floor_config[i].floor0;
         g->order = get_bits(f,8);
         g->rate = get_bits(f,16);
         g->bark_map_size = get_bits(f,16);
         g->amplitude_bits = get_bits(f,6);
         g->amplitude_offset = get_bits(f,8);
         g->number_of_books = get_bits(f,4) + 1;
         for (j=0; j < g->number_of_books; ++j)
            g->book_list[j] = get_bits(f,8);
         return error(f, VORBIS_feature_not_supported);
      } else {
         Point p[31*8+2];
         Floor1 *g = &f->floor_config[i].floor1;
         int max_class = -1; 
         g->partitions = get_bits(f, 5);
         for (j=0; j < g->partitions; ++j) {
            g->partition_class_list[j] = get_bits(f, 4);
            if (g->partition_class_list[j] > max_class)
               max_class = g->partition_class_list[j];
         }
         for (j=0; j <= max_class; ++j) {
            g->class_dimensions[j] = get_bits(f, 3)+1;
            g->class_subclasses[j] = get_bits(f, 2);
            if (g->class_subclasses[j]) {
               g->class_masterbooks[j] = get_bits(f, 8);
               if (g->class_masterbooks[j] >= f->codebook_count) return error(f, VORBIS_invalid_setup);
            }
            for (k=0; k < 1 << g->class_subclasses[j]; ++k) {
               g->subclass_books[j][k] = get_bits(f,8)-1;
               if (g->subclass_books[j][k] >= f->codebook_count) return error(f, VORBIS_invalid_setup);
            }
         }
         g->floor1_multiplier = get_bits(f,2)+1;
         g->rangebits = get_bits(f,4);
         g->Xlist[0] = 0;
         g->Xlist[1] = 1 << g->rangebits;
         g->values = 2;
         for (j=0; j < g->partitions; ++j) {
            int c = g->partition_class_list[j];
            for (k=0; k < g->class_dimensions[c]; ++k) {
               g->Xlist[g->values] = get_bits(f, g->rangebits);
               ++g->values;
            }
         }
         // precompute the sorting
         for (j=0; j < g->values; ++j) {
            p[j].x = g->Xlist[j];
            p[j].y = j;
         }
         qsort(p, g->values, sizeof(p[0]), point_compare);
         for (j=0; j < g->values; ++j)
            g->sorted_order[j] = (uint8) p[j].y;
         // precompute the neighbors
         for (j=2; j < g->values; ++j) {
            int low,hi;
            neighbors(g->Xlist, j, &low,&hi);
            g->neighbors[j][0] = low;
            g->neighbors[j][1] = hi;
         }

         if (g->values > longest_floorlist)
            longest_floorlist = g->values;
      }
   }

   // Residue
   f->residue_count = get_bits(f, 6)+1;
   f->residue_config = (Residue *) setup_malloc(f, f->residue_count * sizeof(f->residue_config[0]));
   if (f->residue_config == NULL) return error(f, VORBIS_outofmem);
   memset(f->residue_config, 0, f->residue_count * sizeof(f->residue_config[0]));
   for (i=0; i < f->residue_count; ++i) {
      uint8 residue_cascade[64];
      Residue *r = f->residue_config+i;
      f->residue_types[i] = get_bits(f, 16);
      if (f->residue_types[i] > 2) return error(f, VORBIS_invalid_setup);
      r->begin = get_bits(f, 24);
      r->end = get_bits(f, 24);
      if (r->end < r->begin) return error(f, VORBIS_invalid_setup);
      r->part_size = get_bits(f,24)+1;
      r->classifications = get_bits(f,6)+1;
      r->classbook = get_bits(f,8);
      if (r->classbook >= f->codebook_count) return error(f, VORBIS_invalid_setup);
      for (j=0; j < r->classifications; ++j) {
         uint8 high_bits=0;
         uint8 low_bits=get_bits(f,3);
         if (get_bits(f,1))
            high_bits = get_bits(f,5);
         residue_cascade[j] = high_bits*8 + low_bits;
      }
      r->residue_books = (short (*)[8]) setup_malloc(f, sizeof(r->residue_books[0]) * r->classifications);
      if (r->residue_books == NULL) return error(f, VORBIS_outofmem);
      for (j=0; j < r->classifications; ++j) {
         for (k=0; k < 8; ++k) {
            if (residue_cascade[j] & (1 << k)) {
               r->residue_books[j][k] = get_bits(f, 8);
               if (r->residue_books[j][k] >= f->codebook_count) return error(f, VORBIS_invalid_setup);
            } else {
               r->residue_books[j][k] = -1;
            }
         }
      }
      // precompute the classifications[] array to avoid inner-loop mod/divide
      // call it 'classdata' since we already have r->classifications
      r->classdata = (uint8 **) setup_malloc(f, sizeof(*r->classdata) * f->codebooks[r->classbook].entries);
      if (!r->classdata) return error(f, VORBIS_outofmem);
      memset(r->classdata, 0, sizeof(*r->classdata) * f->codebooks[r->classbook].entries);
      for (j=0; j < f->codebooks[r->classbook].entries; ++j) {
         int classwords = f->codebooks[r->classbook].dimensions;
         int temp = j;
         r->classdata[j] = (uint8 *) setup_malloc(f, sizeof(r->classdata[j][0]) * classwords);
         if (r->classdata[j] == NULL) return error(f, VORBIS_outofmem);
         for (k=classwords-1; k >= 0; --k) {
            r->classdata[j][k] = temp % r->classifications;
            temp /= r->classifications;
         }
      }
   }

   f->mapping_count = get_bits(f,6)+1;
   f->mapping = (Mapping *) setup_malloc(f, f->mapping_count * sizeof(*f->mapping));
   if (f->mapping == NULL) return error(f, VORBIS_outofmem);
   memset(f->mapping, 0, f->mapping_count * sizeof(*f->mapping));
   for (i=0; i < f->mapping_count; ++i) {
      Mapping *m = f->mapping + i;      
      int mapping_type = get_bits(f,16);
      if (mapping_type != 0) return error(f, VORBIS_invalid_setup);
      m->chan = (MappingChannel *) setup_malloc(f, f->channels * sizeof(*m->chan));
      if (m->chan == NULL) return error(f, VORBIS_outofmem);
      if (get_bits(f,1))
         m->submaps = get_bits(f,4)+1;
      else
         m->submaps = 1;
      if (m->submaps > max_submaps)
         max_submaps = m->submaps;
      if (get_bits(f,1)) {
         m->coupling_steps = get_bits(f,8)+1;
         for (k=0; k < m->coupling_steps; ++k) {
            m->chan[k].magnitude = get_bits(f, ilog(f->channels-1));
            m->chan[k].angle = get_bits(f, ilog(f->channels-1));
            if (m->chan[k].magnitude >= f->channels)        return error(f, VORBIS_invalid_setup);
            if (m->chan[k].angle     >= f->channels)        return error(f, VORBIS_invalid_setup);
            if (m->chan[k].magnitude == m->chan[k].angle)   return error(f, VORBIS_invalid_setup);
         }
      } else
         m->coupling_steps = 0;

      // reserved field
      if (get_bits(f,2)) return error(f, VORBIS_invalid_setup);
      if (m->submaps > 1) {
         for (j=0; j < f->channels; ++j) {
            m->chan[j].mux = get_bits(f, 4);
            if (m->chan[j].mux >= m->submaps)                return error(f, VORBIS_invalid_setup);
         }
      } else
         // @SPECIFICATION: this case is missing from the spec
         for (j=0; j < f->channels; ++j)
            m->chan[j].mux = 0;

      for (j=0; j < m->submaps; ++j) {
         get_bits(f,8); // discard
         m->submap_floor[j] = get_bits(f,8);
         m->submap_residue[j] = get_bits(f,8);
         if (m->submap_floor[j] >= f->floor_count)      return error(f, VORBIS_invalid_setup);
         if (m->submap_residue[j] >= f->residue_count)  return error(f, VORBIS_invalid_setup);
      }
   }

   // Modes
   f->mode_count = get_bits(f, 6)+1;
   for (i=0; i < f->mode_count; ++i) {
      Mode *m = f->mode_config+i;
      m->blockflag = get_bits(f,1);
      m->windowtype = get_bits(f,16);
      m->transformtype = get_bits(f,16);
      m->mapping = get_bits(f,8);
      if (m->windowtype != 0)                 return error(f, VORBIS_invalid_setup);
      if (m->transformtype != 0)              return error(f, VORBIS_invalid_setup);
      if (m->mapping >= f->mapping_count)     return error(f, VORBIS_invalid_setup);
   }

   flush_packet(f);

   f->previous_length = 0;

   for (i=0; i < f->channels; ++i) {
      f->channel_buffers[i] = (float *) setup_malloc(f, sizeof(float) * f->blocksize_1);
      f->previous_window[i] = (float *) setup_malloc(f, sizeof(float) * f->blocksize_1/2);
      f->finalY[i]          = (int16 *) setup_malloc(f, sizeof(int16) * longest_floorlist);
      if (f->channel_buffers[i] == NULL || f->previous_window[i] == NULL || f->finalY[i] == NULL) return error(f, VORBIS_outofmem);
      #ifdef STB_VORBIS_NO_DEFER_FLOOR
      f->floor_buffers[i]   = (float *) setup_malloc(f, sizeof(float) * f->blocksize_1/2);
      if (f->floor_buffers[i] == NULL) return error(f, VORBIS_outofmem);
      #endif
   }

   if (!init_blocksize(f, 0, f->blocksize_0)) return FALSE;
   if (!init_blocksize(f, 1, f->blocksize_1)) return FALSE;
   f->blocksize[0] = f->blocksize_0;
   f->blocksize[1] = f->blocksize_1;

#ifdef STB_VORBIS_DIVIDE_TABLE
   if (integer_divide_table[1][1]==0)
      for (i=0; i < DIVTAB_NUMER; ++i)
         for (j=1; j < DIVTAB_DENOM; ++j)
            integer_divide_table[i][j] = i / j;
#endif

   // compute how much temporary memory is needed

   // 1.
   {
      uint32 imdct_mem = (f->blocksize_1 * sizeof(float) >> 1);
      uint32 classify_mem;
      int i,max_part_read=0;
      for (i=0; i < f->residue_count; ++i) {
         Residue *r = f->residue_config + i;
         int n_read = r->end - r->begin;
         int part_read = n_read / r->part_size;
         if (part_read > max_part_read)
            max_part_read = part_read;
      }
      #ifndef STB_VORBIS_DIVIDES_IN_RESIDUE
      classify_mem = f->channels * (sizeof(void*) + max_part_read * sizeof(uint8 *));
      #else
      classify_mem = f->channels * (sizeof(void*) + max_part_read * sizeof(int *));
      #endif

      f->temp_memory_required = classify_mem;
      if (imdct_mem > f->temp_memory_required)
         f->temp_memory_required = imdct_mem;
   }

   f->first_decode = TRUE;

   if (f->alloc.alloc_buffer) {
      assert(f->temp_offset == f->alloc.alloc_buffer_length_in_bytes);
      // check if there's enough temp memory so we don't error later
      if (f->setup_offset + sizeof(*f) + f->temp_memory_required > (unsigned) f->temp_offset)
         return error(f, VORBIS_outofmem);
   }

   f->first_audio_page_offset = stb_vorbis_get_file_offset(f);

   return TRUE;
}

static void vorbis_deinit(stb_vorbis *p)
{
   int i,j;
   if (p->residue_config) {
      for (i=0; i < p->residue_count; ++i) {
         Residue *r = p->residue_config+i;
         if (r->classdata) {
            for (j=0; j < p->codebooks[r->classbook].entries; ++j)
               setup_free(p, r->classdata[j]);
            setup_free(p, r->classdata);
         }
         setup_free(p, r->residue_books);
      }
   }

   if (p->codebooks) {
      CHECK(p);
      for (i=0; i < p->codebook_count; ++i) {
         Codebook *c = p->codebooks + i;
         setup_free(p, c->codeword_lengths);
         setup_free(p, c->multiplicands);
         setup_free(p, c->codewords);
         setup_free(p, c->sorted_codewords);
         // c->sorted_values[-1] is the first entry in the array
         setup_free(p, c->sorted_values ? c->sorted_values-1 : NULL);
      }
      setup_free(p, p->codebooks);
   }
   setup_free(p, p->floor_config);
   setup_free(p, p->residue_config);
   if (p->mapping) {
      for (i=0; i < p->mapping_count; ++i)
         setup_free(p, p->mapping[i].chan);
      setup_free(p, p->mapping);
   }
   CHECK(p);
   for (i=0; i < p->channels && i < STB_VORBIS_MAX_CHANNELS; ++i) {
      setup_free(p, p->channel_buffers[i]);
      setup_free(p, p->previous_window[i]);
      #ifdef STB_VORBIS_NO_DEFER_FLOOR
      setup_free(p, p->floor_buffers[i]);
      #endif
      setup_free(p, p->finalY[i]);
   }
   for (i=0; i < 2; ++i) {
      setup_free(p, p->A[i]);
      setup_free(p, p->B[i]);
      setup_free(p, p->C[i]);
      setup_free(p, p->window[i]);
      setup_free(p, p->bit_reverse[i]);
   }
   #ifndef STB_VORBIS_NO_STDIO
   if (p->close_on_free) fclose(p->f);
   #endif
}

void stb_vorbis_close(stb_vorbis *p)
{
   if (p == NULL) return;
   vorbis_deinit(p);
   setup_free(p,p);
}

static void vorbis_init(stb_vorbis *p, const stb_vorbis_alloc *z)
{
   memset(p, 0, sizeof(*p)); // NULL out all malloc'd pointers to start
   if (z) {
      p->alloc = *z;
      p->alloc.alloc_buffer_length_in_bytes = (p->alloc.alloc_buffer_length_in_bytes+3) & ~3;
      p->temp_offset = p->alloc.alloc_buffer_length_in_bytes;
   }
   p->eof = 0;
   p->error = VORBIS__no_error;
   p->stream = NULL;
   p->codebooks = NULL;
   p->page_crc_tests = -1;
   #ifndef STB_VORBIS_NO_STDIO
   p->close_on_free = FALSE;
   p->f = NULL;
   #endif
}

int stb_vorbis_get_sample_offset(stb_vorbis *f)
{
   if (f->current_loc_valid)
      return f->current_loc;
   else
      return -1;
}

stb_vorbis_info stb_vorbis_get_info(stb_vorbis *f)
{
   stb_vorbis_info d;
   d.channels = f->channels;
   d.sample_rate = f->sample_rate;
   d.setup_memory_required = f->setup_memory_required;
   d.setup_temp_memory_required = f->setup_temp_memory_required;
   d.temp_memory_required = f->temp_memory_required;
   d.max_frame_size = f->blocksize_1 >> 1;
   return d;
}

int stb_vorbis_get_error(stb_vorbis *f)
{
   int e = f->error;
   f->error = VORBIS__no_error;
   return e;
}

static stb_vorbis * vorbis_alloc(stb_vorbis *f)
{
   stb_vorbis *p = (stb_vorbis *) setup_malloc(f, sizeof(*p));
   return p;
}

#ifndef STB_VORBIS_NO_PUSHDATA_API

void stb_vorbis_flush_pushdata(stb_vorbis *f)
{
   f->previous_length = 0;
   f->page_crc_tests  = 0;
   f->discard_samples_deferred = 0;
   f->current_loc_valid = FALSE;
   f->first_decode = FALSE;
   f->samples_output = 0;
   f->channel_buffer_start = 0;
   f->channel_buffer_end = 0;
}

static int vorbis_search_for_page_pushdata(vorb *f, uint8 *data, int data_len)
{
   int i,n;
   for (i=0; i < f->page_crc_tests; ++i)
      f->scan[i].bytes_done = 0;

   // if we have room for more scans, search for them first, because
   // they may cause us to stop early if their header is incomplete
   if (f->page_crc_tests < STB_VORBIS_PUSHDATA_CRC_COUNT) {
      if (data_len < 4) return 0;
      data_len -= 3; // need to look for 4-byte sequence, so don't miss
                     // one that straddles a boundary
      for (i=0; i < data_len; ++i) {
         if (data[i] == 0x4f) {
            if (0==memcmp(data+i, ogg_page_header, 4)) {
               int j,len;
               uint32 crc;
               // make sure we have the whole page header
               if (i+26 >= data_len || i+27+data[i+26] >= data_len) {
                  // only read up to this page start, so hopefully we'll
                  // have the whole page header start next time
                  data_len = i;
                  break;
               }
               // ok, we have it all; compute the length of the page
               len = 27 + data[i+26];
               for (j=0; j < data[i+26]; ++j)
                  len += data[i+27+j];
               // scan everything up to the embedded crc (which we must 0)
               crc = 0;
               for (j=0; j < 22; ++j)
                  crc = crc32_update(crc, data[i+j]);
               // now process 4 0-bytes
               for (   ; j < 26; ++j)
                  crc = crc32_update(crc, 0);
               // len is the total number of bytes we need to scan
               n = f->page_crc_tests++;
               f->scan[n].bytes_left = len-j;
               f->scan[n].crc_so_far = crc;
               f->scan[n].goal_crc = data[i+22] + (data[i+23] << 8) + (data[i+24]<<16) + (data[i+25]<<24);
               // if the last frame on a page is continued to the next, then
               // we can't recover the sample_loc immediately
               if (data[i+27+data[i+26]-1] == 255)
                  f->scan[n].sample_loc = ~0;
               else
                  f->scan[n].sample_loc = data[i+6] + (data[i+7] << 8) + (data[i+ 8]<<16) + (data[i+ 9]<<24);
               f->scan[n].bytes_done = i+j;
               if (f->page_crc_tests == STB_VORBIS_PUSHDATA_CRC_COUNT)
                  break;
               // keep going if we still have room for more
            }
         }
      }
   }

   for (i=0; i < f->page_crc_tests;) {
      uint32 crc;
      int j;
      int n = f->scan[i].bytes_done;
      int m = f->scan[i].bytes_left;
      if (m > data_len - n) m = data_len - n;
      // m is the bytes to scan in the current chunk
      crc = f->scan[i].crc_so_far;
      for (j=0; j < m; ++j)
         crc = crc32_update(crc, data[n+j]);
      f->scan[i].bytes_left -= m;
      f->scan[i].crc_so_far = crc;
      if (f->scan[i].bytes_left == 0) {
         // does it match?
         if (f->scan[i].crc_so_far == f->scan[i].goal_crc) {
            // Houston, we have page
            data_len = n+m; // consumption amount is wherever that scan ended
            f->page_crc_tests = -1; // drop out of page scan mode
            f->previous_length = 0; // decode-but-don't-output one frame
            f->next_seg = -1;       // start a new page
            f->current_loc = f->scan[i].sample_loc; // set the current sample location
                                    // to the amount we'd have decoded had we decoded this page
            f->current_loc_valid = f->current_loc != ~0U;
            return data_len;
         }
         // delete entry
         f->scan[i] = f->scan[--f->page_crc_tests];
      } else {
         ++i;
      }
   }

   return data_len;
}

// return value: number of bytes we used
int stb_vorbis_decode_frame_pushdata(
         stb_vorbis *f,                   // the file we're decoding
         const uint8 *data, int data_len, // the memory available for decoding
         int *channels,                   // place to write number of float * buffers
         float ***output,                 // place to write float ** array of float * buffers
         int *samples                     // place to write number of output samples
     )
{
   int i;
   int len,right,left;

   if (!IS_PUSH_MODE(f)) return error(f, VORBIS_invalid_api_mixing);

   if (f->page_crc_tests >= 0) {
      *samples = 0;
      return vorbis_search_for_page_pushdata(f, (uint8 *) data, data_len);
   }

   f->stream     = (uint8 *) data;
   f->stream_end = (uint8 *) data + data_len;
   f->error      = VORBIS__no_error;

   // check that we have the entire packet in memory
   if (!is_whole_packet_present(f, FALSE)) {
      *samples = 0;
      return 0;
   }

   if (!vorbis_decode_packet(f, &len, &left, &right)) {
      // save the actual error we encountered
      enum STBVorbisError error = f->error;
      if (error == VORBIS_bad_packet_type) {
         // flush and resynch
         f->error = VORBIS__no_error;
         while (get8_packet(f) != EOP)
            if (f->eof) break;
         *samples = 0;
         return (int) (f->stream - data);
      }
      if (error == VORBIS_continued_packet_flag_invalid) {
         if (f->previous_length == 0) {
            // we may be resynching, in which case it's ok to hit one
            // of these; just discard the packet
            f->error = VORBIS__no_error;
            while (get8_packet(f) != EOP)
               if (f->eof) break;
            *samples = 0;
            return (int) (f->stream - data);
         }
      }
      // if we get an error while parsing, what to do?
      // well, it DEFINITELY won't work to continue from where we are!
      stb_vorbis_flush_pushdata(f);
      // restore the error that actually made us bail
      f->error = error;
      *samples = 0;
      return 1;
   }

   // success!
   len = vorbis_finish_frame(f, len, left, right);
   for (i=0; i < f->channels; ++i)
      f->outputs[i] = f->channel_buffers[i] + left;

   if (channels) *channels = f->channels;
   *samples = len;
   *output = f->outputs;
   return (int) (f->stream - data);
}

stb_vorbis *stb_vorbis_open_pushdata(
         const unsigned char *data, int data_len, // the memory available for decoding
         int *data_used,              // only defined if result is not NULL
         int *error, const stb_vorbis_alloc *alloc)
{
   stb_vorbis *f, p;
   vorbis_init(&p, alloc);
   p.stream     = (uint8 *) data;
   p.stream_end = (uint8 *) data + data_len;
   p.push_mode  = TRUE;
   if (!start_decoder(&p)) {
      if (p.eof)
         *error = VORBIS_need_more_data;
      else
         *error = p.error;
      return NULL;
   }
   f = vorbis_alloc(&p);
   if (f) {
      *f = p;
      *data_used = (int) (f->stream - data);
      *error = 0;
      return f;
   } else {
      vorbis_deinit(&p);
      return NULL;
   }
}
#endif // STB_VORBIS_NO_PUSHDATA_API

unsigned int stb_vorbis_get_file_offset(stb_vorbis *f)
{
   #ifndef STB_VORBIS_NO_PUSHDATA_API
   if (f->push_mode) return 0;
   #endif
   if (USE_MEMORY(f)) return (unsigned int) (f->stream - f->stream_start);
   #ifndef STB_VORBIS_NO_STDIO
   return (unsigned int) (ftell(f->f) - f->f_start);
   #endif
}

#ifndef STB_VORBIS_NO_PULLDATA_API
//
// DATA-PULLING API
//

static uint32 vorbis_find_page(stb_vorbis *f, uint32 *end, uint32 *last)
{
   for(;;) {
      int n;
      if (f->eof) return 0;
      n = get8(f);
      if (n == 0x4f) { // page header candidate
         unsigned int retry_loc = stb_vorbis_get_file_offset(f);
         int i;
         // check if we're off the end of a file_section stream
         if (retry_loc - 25 > f->stream_len)
            return 0;
         // check the rest of the header
         for (i=1; i < 4; ++i)
            if (get8(f) != ogg_page_header[i])
               break;
         if (f->eof) return 0;
         if (i == 4) {
            uint8 header[27];
            uint32 i, crc, goal, len;
            for (i=0; i < 4; ++i)
               header[i] = ogg_page_header[i];
            for (; i < 27; ++i)
               header[i] = get8(f);
            if (f->eof) return 0;
            if (header[4] != 0) goto invalid;
            goal = header[22] + (header[23] << 8) + (header[24]<<16) + (header[25]<<24);
            for (i=22; i < 26; ++i)
               header[i] = 0;
            crc = 0;
            for (i=0; i < 27; ++i)
               crc = crc32_update(crc, header[i]);
            len = 0;
            for (i=0; i < header[26]; ++i) {
               int s = get8(f);
               crc = crc32_update(crc, s);
               len += s;
            }
            if (len && f->eof) return 0;
            for (i=0; i < len; ++i)
               crc = crc32_update(crc, get8(f));
            // finished parsing probable page
            if (crc == goal) {
               // we could now check that it's either got the last
               // page flag set, OR it's followed by the capture
               // pattern, but I guess TECHNICALLY you could have
               // a file with garbage between each ogg page and recover
               // from it automatically? So even though that paranoia
               // might decrease the chance of an invalid decode by
               // another 2^32, not worth it since it would hose those
               // invalid-but-useful files?
               if (end)
                  *end = stb_vorbis_get_file_offset(f);
               if (last) {
                  if (header[5] & 0x04)
                     *last = 1;
                  else
                     *last = 0;
               }
               set_file_offset(f, retry_loc-1);
               return 1;
            }
         }
        invalid:
         // not a valid page, so rewind and look for next one
         set_file_offset(f, retry_loc);
      }
   }
}


#define SAMPLE_unknown  0xffffffff

// seeking is implemented with a binary search, which narrows down the range to
// 64K, before using a linear search (because finding the synchronization
// pattern can be expensive, and the chance we'd find the end page again is
// relatively high for small ranges)
//
// two initial interpolation-style probes are used at the start of the search
// to try to bound either side of the binary search sensibly, while still
// working in O(log n) time if they fail.

static int get_seek_page_info(stb_vorbis *f, ProbedPage *z)
{
   uint8 header[27], lacing[255];
   int i,len;

   // record where the page starts
   z->page_start = stb_vorbis_get_file_offset(f);

   // parse the header
   getn(f, header, 27);
   if (header[0] != 'O' || header[1] != 'g' || header[2] != 'g' || header[3] != 'S')
      return 0;
   getn(f, lacing, header[26]);

   // determine the length of the payload
   len = 0;
   for (i=0; i < header[26]; ++i)
      len += lacing[i];

   // this implies where the page ends
   z->page_end = z->page_start + 27 + header[26] + len;

   // read the last-decoded sample out of the data
   z->last_decoded_sample = header[6] + (header[7] << 8) + (header[8] << 16) + (header[9] << 24);

   // restore file state to where we were
   set_file_offset(f, z->page_start);
   return 1;
}

// rarely used function to seek back to the preceeding page while finding the
// start of a packet
static int go_to_page_before(stb_vorbis *f, unsigned int limit_offset)
{
   unsigned int previous_safe, end;

   // now we want to seek back 64K from the limit
   if (limit_offset >= 65536 && limit_offset-65536 >= f->first_audio_page_offset)
      previous_safe = limit_offset - 65536;
   else
      previous_safe = f->first_audio_page_offset;

   set_file_offset(f, previous_safe);

   while (vorbis_find_page(f, &end, NULL)) {
      if (end >= limit_offset && stb_vorbis_get_file_offset(f) < limit_offset)
         return 1;
      set_file_offset(f, end);
   }

   return 0;
}

// implements the search logic for finding a page and starting decoding. if
// the function succeeds, current_loc_valid will be true and current_loc will
// be less than or equal to the provided sample number (the closer the
// better).
static int seek_to_sample_coarse(stb_vorbis *f, uint32 sample_number)
{
   ProbedPage left, right, mid;
   int i, start_seg_with_known_loc, end_pos, page_start;
   uint32 delta, stream_length, padding;
   double offset, bytes_per_sample;
   int probe = 0;

   // find the last page and validate the target sample
   stream_length = stb_vorbis_stream_length_in_samples(f);
   if (stream_length == 0)            return error(f, VORBIS_seek_without_length);
   if (sample_number > stream_length) return error(f, VORBIS_seek_invalid);

   // this is the maximum difference between the window-center (which is the
   // actual granule position value), and the right-start (which the spec
   // indicates should be the granule position (give or take one)).
   padding = ((f->blocksize_1 - f->blocksize_0) >> 2);
   if (sample_number < padding)
      sample_number = 0;
   else
      sample_number -= padding;

   left = f->p_first;
   while (left.last_decoded_sample == ~0U) {
      // (untested) the first page does not have a 'last_decoded_sample'
      set_file_offset(f, left.page_end);
      if (!get_seek_page_info(f, &left)) goto error;
   }

   right = f->p_last;
   assert(right.last_decoded_sample != ~0U);

   // starting from the start is handled differently
   if (sample_number <= left.last_decoded_sample) {
      stb_vorbis_seek_start(f);
      return 1;
   }

   while (left.page_end != right.page_start) {
      assert(left.page_end < right.page_start);
      // search range in bytes
      delta = right.page_start - left.page_end;
      if (delta <= 65536) {
         // there's only 64K left to search - handle it linearly
         set_file_offset(f, left.page_end);
      } else {
         if (probe < 2) {
            if (probe == 0) {
               // first probe (interpolate)
               double data_bytes = right.page_end - left.page_start;
               bytes_per_sample = data_bytes / right.last_decoded_sample;
               offset = left.page_start + bytes_per_sample * (sample_number - left.last_decoded_sample);
            } else {
               // second probe (try to bound the other side)
               double error = ((double) sample_number - mid.last_decoded_sample) * bytes_per_sample;
               if (error >= 0 && error <  8000) error =  8000;
               if (error <  0 && error > -8000) error = -8000;
               offset += error * 2;
            }

            // ensure the offset is valid
            if (offset < left.page_end)
               offset = left.page_end;
            if (offset > right.page_start - 65536)
               offset = right.page_start - 65536;

            set_file_offset(f, (unsigned int) offset);
         } else {
            // binary search for large ranges (offset by 32K to ensure
            // we don't hit the right page)
            set_file_offset(f, left.page_end + (delta / 2) - 32768);
         }

         if (!vorbis_find_page(f, NULL, NULL)) goto error;
      }

      for (;;) {
         if (!get_seek_page_info(f, &mid)) goto error;
         if (mid.last_decoded_sample != ~0U) break;
         // (untested) no frames end on this page
         set_file_offset(f, mid.page_end);
         assert(mid.page_start < right.page_start);
      }

      // if we've just found the last page again then we're in a tricky file,
      // and we're close enough.
      if (mid.page_start == right.page_start)
         break;

      if (sample_number < mid.last_decoded_sample)
         right = mid;
      else
         left = mid;

      ++probe;
   }

   // seek back to start of the last packet
   page_start = left.page_start;
   set_file_offset(f, page_start);
   if (!start_page(f)) return error(f, VORBIS_seek_failed);
   end_pos = f->end_seg_with_known_loc;
   assert(end_pos >= 0);

   for (;;) {
      for (i = end_pos; i > 0; --i)
         if (f->segments[i-1] != 255)
            break;

      start_seg_with_known_loc = i;

      if (start_seg_with_known_loc > 0 || !(f->page_flag & PAGEFLAG_continued_packet))
         break;

      // (untested) the final packet begins on an earlier page
      if (!go_to_page_before(f, page_start))
         goto error;

      page_start = stb_vorbis_get_file_offset(f);
      if (!start_page(f)) goto error;
      end_pos = f->segment_count - 1;
   }

   // prepare to start decoding
   f->current_loc_valid = FALSE;
   f->last_seg = FALSE;
   f->valid_bits = 0;
   f->packet_bytes = 0;
   f->bytes_in_seg = 0;
   f->previous_length = 0;
   f->next_seg = start_seg_with_known_loc;

   for (i = 0; i < start_seg_with_known_loc; i++)
      skip(f, f->segments[i]);

   // start decoding (optimizable - this frame is generally discarded)
   vorbis_pump_first_frame(f);
   return 1;

error:
   // try to restore the file to a valid state
   stb_vorbis_seek_start(f);
   return error(f, VORBIS_seek_failed);
}

// the same as vorbis_decode_initial, but without advancing
static int peek_decode_initial(vorb *f, int *p_left_start, int *p_left_end, int *p_right_start, int *p_right_end, int *mode)
{
   int bits_read, bytes_read;

   if (!vorbis_decode_initial(f, p_left_start, p_left_end, p_right_start, p_right_end, mode))
      return 0;

   // either 1 or 2 bytes were read, figure out which so we can rewind
   bits_read = 1 + ilog(f->mode_count-1);
   if (f->mode_config[*mode].blockflag)
      bits_read += 2;
   bytes_read = (bits_read + 7) / 8;

   f->bytes_in_seg += bytes_read;
   f->packet_bytes -= bytes_read;
   skip(f, -bytes_read);
   if (f->next_seg == -1)
      f->next_seg = f->segment_count - 1;
   else
      f->next_seg--;
   f->valid_bits = 0;

   return 1;
}

int stb_vorbis_seek_frame(stb_vorbis *f, unsigned int sample_number)
{
   uint32 max_frame_samples;

   if (IS_PUSH_MODE(f)) return error(f, VORBIS_invalid_api_mixing);

   // fast page-level search
   if (!seek_to_sample_coarse(f, sample_number))
      return 0;

   assert(f->current_loc_valid);
   assert(f->current_loc <= sample_number);

   // linear search for the relevant packet
   max_frame_samples = (f->blocksize_1*3 - f->blocksize_0) >> 2;
   while (f->current_loc < sample_number) {
      int left_start, left_end, right_start, right_end, mode, frame_samples;
      if (!peek_decode_initial(f, &left_start, &left_end, &right_start, &right_end, &mode))
         return error(f, VORBIS_seek_failed);
      // calculate the number of samples returned by the next frame
      frame_samples = right_start - left_start;
      if (f->current_loc + frame_samples > sample_number) {
         return 1; // the next frame will contain the sample
      } else if (f->current_loc + frame_samples + max_frame_samples > sample_number) {
         // there's a chance the frame after this could contain the sample
         vorbis_pump_first_frame(f);
      } else {
         // this frame is too early to be relevant
         f->current_loc += frame_samples;
         f->previous_length = 0;
         maybe_start_packet(f);
         flush_packet(f);
      }
   }
   // the next frame will start with the sample
   assert(f->current_loc == sample_number);
   return 1;
}

int stb_vorbis_seek(stb_vorbis *f, unsigned int sample_number)
{
   if (!stb_vorbis_seek_frame(f, sample_number))
      return 0;

   if (sample_number != f->current_loc) {
      int n;
      uint32 frame_start = f->current_loc;
      stb_vorbis_get_frame_float(f, &n, NULL);
      assert(sample_number > frame_start);
      assert(f->channel_buffer_start + (int) (sample_number-frame_start) <= f->channel_buffer_end);
      f->channel_buffer_start += (sample_number - frame_start);
   }

   return 1;
}

void stb_vorbis_seek_start(stb_vorbis *f)
{
   if (IS_PUSH_MODE(f)) { error(f, VORBIS_invalid_api_mixing); return; }
   set_file_offset(f, f->first_audio_page_offset);
   f->previous_length = 0;
   f->first_decode = TRUE;
   f->next_seg = -1;
   vorbis_pump_first_frame(f);
}

unsigned int stb_vorbis_stream_length_in_samples(stb_vorbis *f)
{
   unsigned int restore_offset, previous_safe;
   unsigned int end, last_page_loc;

   if (IS_PUSH_MODE(f)) return error(f, VORBIS_invalid_api_mixing);
   if (!f->total_samples) {
      unsigned int last;
      uint32 lo,hi;
      char header[6];

      // first, store the current decode position so we can restore it
      restore_offset = stb_vorbis_get_file_offset(f);

      // now we want to seek back 64K from the end (the last page must
      // be at most a little less than 64K, but let's allow a little slop)
      if (f->stream_len >= 65536 && f->stream_len-65536 >= f->first_audio_page_offset)
         previous_safe = f->stream_len - 65536;
      else
         previous_safe = f->first_audio_page_offset;

      set_file_offset(f, previous_safe);
      // previous_safe is now our candidate 'earliest known place that seeking
      // to will lead to the final page'

      if (!vorbis_find_page(f, &end, &last)) {
         // if we can't find a page, we're hosed!
         f->error = VORBIS_cant_find_last_page;
         f->total_samples = 0xffffffff;
         goto done;
      }

      // check if there are more pages
      last_page_loc = stb_vorbis_get_file_offset(f);

      // stop when the last_page flag is set, not when we reach eof;
      // this allows us to stop short of a 'file_section' end without
      // explicitly checking the length of the section
      while (!last) {
         set_file_offset(f, end);
         if (!vorbis_find_page(f, &end, &last)) {
            // the last page we found didn't have the 'last page' flag
            // set. whoops!
            break;
         }
         previous_safe = last_page_loc+1;
         last_page_loc = stb_vorbis_get_file_offset(f);
      }

      set_file_offset(f, last_page_loc);

      // parse the header
      getn(f, (unsigned char *)header, 6);
      // extract the absolute granule position
      lo = get32(f);
      hi = get32(f);
      if (lo == 0xffffffff && hi == 0xffffffff) {
         f->error = VORBIS_cant_find_last_page;
         f->total_samples = SAMPLE_unknown;
         goto done;
      }
      if (hi)
         lo = 0xfffffffe; // saturate
      f->total_samples = lo;

      f->p_last.page_start = last_page_loc;
      f->p_last.page_end   = end;
      f->p_last.last_decoded_sample = lo;

     done:
      set_file_offset(f, restore_offset);
   }
   return f->total_samples == SAMPLE_unknown ? 0 : f->total_samples;
}

float stb_vorbis_stream_length_in_seconds(stb_vorbis *f)
{
   return stb_vorbis_stream_length_in_samples(f) / (float) f->sample_rate;
}



int stb_vorbis_get_frame_float(stb_vorbis *f, int *channels, float ***output)
{
   int len, right,left,i;
   if (IS_PUSH_MODE(f)) return error(f, VORBIS_invalid_api_mixing);

   if (!vorbis_decode_packet(f, &len, &left, &right)) {
      f->channel_buffer_start = f->channel_buffer_end = 0;
      return 0;
   }

   len = vorbis_finish_frame(f, len, left, right);
   for (i=0; i < f->channels; ++i)
      f->outputs[i] = f->channel_buffers[i] + left;

   f->channel_buffer_start = left;
   f->channel_buffer_end   = left+len;

   if (channels) *channels = f->channels;
   if (output)   *output = f->outputs;
   return len;
}

#ifndef STB_VORBIS_NO_STDIO

stb_vorbis * stb_vorbis_open_file_section(FILE *file, int close_on_free, int *error, const stb_vorbis_alloc *alloc, unsigned int length)
{
   stb_vorbis *f, p;
   vorbis_init(&p, alloc);
   p.f = file;
   p.f_start = (uint32) ftell(file);
   p.stream_len   = length;
   p.close_on_free = close_on_free;
   if (start_decoder(&p)) {
      f = vorbis_alloc(&p);
      if (f) {
         *f = p;
         vorbis_pump_first_frame(f);
         return f;
      }
   }
   if (error) *error = p.error;
   vorbis_deinit(&p);
   return NULL;
}

stb_vorbis * stb_vorbis_open_file(FILE *file, int close_on_free, int *error, const stb_vorbis_alloc *alloc)
{
   unsigned int len, start;
   start = (unsigned int) ftell(file);
   fseek(file, 0, SEEK_END);
   len = (unsigned int) (ftell(file) - start);
   fseek(file, start, SEEK_SET);
   return stb_vorbis_open_file_section(file, close_on_free, error, alloc, len);
}

stb_vorbis * stb_vorbis_open_filename(const char *filename, int *error, const stb_vorbis_alloc *alloc)
{
   FILE *f = fopen(filename, "rb");
   if (f) 
      return stb_vorbis_open_file(f, TRUE, error, alloc);
   if (error) *error = VORBIS_file_open_failure;
   return NULL;
}
#endif // STB_VORBIS_NO_STDIO

stb_vorbis * stb_vorbis_open_memory(const unsigned char *data, int len, int *error, const stb_vorbis_alloc *alloc)
{
   stb_vorbis *f, p;
   if (data == NULL) return NULL;
   vorbis_init(&p, alloc);
   p.stream = (uint8 *) data;
   p.stream_end = (uint8 *) data + len;
   p.stream_start = (uint8 *) p.stream;
   p.stream_len = len;
   p.push_mode = FALSE;
   if (start_decoder(&p)) {
      f = vorbis_alloc(&p);
      if (f) {
         *f = p;
         vorbis_pump_first_frame(f);
         return f;
      }
   }
   if (error) *error = p.error;
   vorbis_deinit(&p);
   return NULL;
}

#ifndef STB_VORBIS_NO_INTEGER_CONVERSION
#define PLAYBACK_MONO     1
#define PLAYBACK_LEFT     2
#define PLAYBACK_RIGHT    4

#define L  (PLAYBACK_LEFT  | PLAYBACK_MONO)
#define C  (PLAYBACK_LEFT  | PLAYBACK_RIGHT | PLAYBACK_MONO)
#define R  (PLAYBACK_RIGHT | PLAYBACK_MONO)

static int8 channel_position[7][6] =
{
   { 0 },
   { C },
   { L, R },
   { L, C, R },
   { L, R, L, R },
   { L, C, R, L, R },
   { L, C, R, L, R, C },
};


#ifndef STB_VORBIS_NO_FAST_SCALED_FLOAT
   typedef union {
      float f;
      int i;
   } float_conv;
   typedef char stb_vorbis_float_size_test[sizeof(float)==4 && sizeof(int) == 4];
   #define FASTDEF(x) float_conv x
   // add (1<<23) to convert to int, then divide by 2^SHIFT, then add 0.5/2^SHIFT to round
   #define MAGIC(SHIFT) (1.5f * (1 << (23-SHIFT)) + 0.5f/(1 << SHIFT))
   #define ADDEND(SHIFT) (((150-SHIFT) << 23) + (1 << 22))
   #define FAST_SCALED_FLOAT_TO_INT(temp,x,s) (temp.f = (x) + MAGIC(s), temp.i - ADDEND(s))
   #define check_endianness()  
#else
   #define FAST_SCALED_FLOAT_TO_INT(temp,x,s) ((int) ((x) * (1 << (s))))
   #define check_endianness()
   #define FASTDEF(x)
#endif

static void copy_samples(short *dest, float *src, int len)
{
   int i;
   check_endianness();
   for (i=0; i < len; ++i) {
      FASTDEF(temp);
      int v = FAST_SCALED_FLOAT_TO_INT(temp, src[i],15);
      if ((unsigned int) (v + 32768) > 65535)
         v = v < 0 ? -32768 : 32767;
      dest[i] = v;
   }
}

static void compute_samples(int mask, short *output, int num_c, float **data, int d_offset, int len)
{
   #define BUFFER_SIZE  32
   float buffer[BUFFER_SIZE];
   int i,j,o,n = BUFFER_SIZE;
   check_endianness();
   for (o = 0; o < len; o += BUFFER_SIZE) {
      memset(buffer, 0, sizeof(buffer));
      if (o + n > len) n = len - o;
      for (j=0; j < num_c; ++j) {
         if (channel_position[num_c][j] & mask) {
            for (i=0; i < n; ++i)
               buffer[i] += data[j][d_offset+o+i];
         }
      }
      for (i=0; i < n; ++i) {
         FASTDEF(temp);
         int v = FAST_SCALED_FLOAT_TO_INT(temp,buffer[i],15);
         if ((unsigned int) (v + 32768) > 65535)
            v = v < 0 ? -32768 : 32767;
         output[o+i] = v;
      }
   }
}

static void compute_stereo_samples(short *output, int num_c, float **data, int d_offset, int len)
{
   #define BUFFER_SIZE  32
   float buffer[BUFFER_SIZE];
   int i,j,o,n = BUFFER_SIZE >> 1;
   // o is the offset in the source data
   check_endianness();
   for (o = 0; o < len; o += BUFFER_SIZE >> 1) {
      // o2 is the offset in the output data
      int o2 = o << 1;
      memset(buffer, 0, sizeof(buffer));
      if (o + n > len) n = len - o;
      for (j=0; j < num_c; ++j) {
         int m = channel_position[num_c][j] & (PLAYBACK_LEFT | PLAYBACK_RIGHT);
         if (m == (PLAYBACK_LEFT | PLAYBACK_RIGHT)) {
            for (i=0; i < n; ++i) {
               buffer[i*2+0] += data[j][d_offset+o+i];
               buffer[i*2+1] += data[j][d_offset+o+i];
            }
         } else if (m == PLAYBACK_LEFT) {
            for (i=0; i < n; ++i) {
               buffer[i*2+0] += data[j][d_offset+o+i];
            }
         } else if (m == PLAYBACK_RIGHT) {
            for (i=0; i < n; ++i) {
               buffer[i*2+1] += data[j][d_offset+o+i];
            }
         }
      }
      for (i=0; i < (n<<1); ++i) {
         FASTDEF(temp);
         int v = FAST_SCALED_FLOAT_TO_INT(temp,buffer[i],15);
         if ((unsigned int) (v + 32768) > 65535)
            v = v < 0 ? -32768 : 32767;
         output[o2+i] = v;
      }
   }
}

static void convert_samples_short(int buf_c, short **buffer, int b_offset, int data_c, float **data, int d_offset, int samples)
{
   int i;
   if (buf_c != data_c && buf_c <= 2 && data_c <= 6) {
      static int channel_selector[3][2] = { {0}, {PLAYBACK_MONO}, {PLAYBACK_LEFT, PLAYBACK_RIGHT} };
      for (i=0; i < buf_c; ++i)
         compute_samples(channel_selector[buf_c][i], buffer[i]+b_offset, data_c, data, d_offset, samples);
   } else {
      int limit = buf_c < data_c ? buf_c : data_c;
      for (i=0; i < limit; ++i)
         copy_samples(buffer[i]+b_offset, data[i]+d_offset, samples);
      for (   ; i < buf_c; ++i)
         memset(buffer[i]+b_offset, 0, sizeof(short) * samples);
   }
}

int stb_vorbis_get_frame_short(stb_vorbis *f, int num_c, short **buffer, int num_samples)
{
   float **output;
   int len = stb_vorbis_get_frame_float(f, NULL, &output);
   if (len > num_samples) len = num_samples;
   if (len)
      convert_samples_short(num_c, buffer, 0, f->channels, output, 0, len);
   return len;
}

static void convert_channels_short_interleaved(int buf_c, short *buffer, int data_c, float **data, int d_offset, int len)
{
   int i;
   check_endianness();
   if (buf_c != data_c && buf_c <= 2 && data_c <= 6) {
      assert(buf_c == 2);
      for (i=0; i < buf_c; ++i)
         compute_stereo_samples(buffer, data_c, data, d_offset, len);
   } else {
      int limit = buf_c < data_c ? buf_c : data_c;
      int j;
      for (j=0; j < len; ++j) {
         for (i=0; i < limit; ++i) {
            FASTDEF(temp);
            float f = data[i][d_offset+j];
            int v = FAST_SCALED_FLOAT_TO_INT(temp, f,15);//data[i][d_offset+j],15);
            if ((unsigned int) (v + 32768) > 65535)
               v = v < 0 ? -32768 : 32767;
            *buffer++ = v;
         }
         for (   ; i < buf_c; ++i)
            *buffer++ = 0;
      }
   }
}

int stb_vorbis_get_frame_short_interleaved(stb_vorbis *f, int num_c, short *buffer, int num_shorts)
{
   float **output;
   int len;
   if (num_c == 1) return stb_vorbis_get_frame_short(f,num_c,&buffer, num_shorts);
   len = stb_vorbis_get_frame_float(f, NULL, &output);
   if (len) {
      if (len*num_c > num_shorts) len = num_shorts / num_c;
      convert_channels_short_interleaved(num_c, buffer, f->channels, output, 0, len);
   }
   return len;
}

int stb_vorbis_get_samples_short_interleaved(stb_vorbis *f, int channels, short *buffer, int num_shorts)
{
   float **outputs;
   int len = num_shorts / channels;
   int n=0;
   int z = f->channels;
   if (z > channels) z = channels;
   while (n < len) {
      int k = f->channel_buffer_end - f->channel_buffer_start;
      if (n+k >= len) k = len - n;
      if (k)
         convert_channels_short_interleaved(channels, buffer, f->channels, f->channel_buffers, f->channel_buffer_start, k);
      buffer += k*channels;
      n += k;
      f->channel_buffer_start += k;
      if (n == len) break;
      if (!stb_vorbis_get_frame_float(f, NULL, &outputs)) break;
   }
   return n;
}

int stb_vorbis_get_samples_short(stb_vorbis *f, int channels, short **buffer, int len)
{
   float **outputs;
   int n=0;
   int z = f->channels;
   if (z > channels) z = channels;
   while (n < len) {
      int k = f->channel_buffer_end - f->channel_buffer_start;
      if (n+k >= len) k = len - n;
      if (k)
         convert_samples_short(channels, buffer, n, f->channels, f->channel_buffers, f->channel_buffer_start, k);
      n += k;
      f->channel_buffer_start += k;
      if (n == len) break;
      if (!stb_vorbis_get_frame_float(f, NULL, &outputs)) break;
   }
   return n;
}

#ifndef STB_VORBIS_NO_STDIO
int stb_vorbis_decode_filename(const char *filename, int *channels, int *sample_rate, short **output)
{
   int data_len, offset, total, limit, error;
   short *data;
   stb_vorbis *v = stb_vorbis_open_filename(filename, &error, NULL);
   if (v == NULL) return -1;
   limit = v->channels * 4096;
   *channels = v->channels;
   if (sample_rate)
      *sample_rate = v->sample_rate;
   offset = data_len = 0;
   total = limit;
   data = (short *) malloc(total * sizeof(*data));
   if (data == NULL) {
      stb_vorbis_close(v);
      return -2;
   }
   for (;;) {
      int n = stb_vorbis_get_frame_short_interleaved(v, v->channels, data+offset, total-offset);
      if (n == 0) break;
      data_len += n;
      offset += n * v->channels;
      if (offset + limit > total) {
         short *data2;
         total *= 2;
         data2 = (short *) realloc(data, total * sizeof(*data));
         if (data2 == NULL) {
            free(data);
            stb_vorbis_close(v);
            return -2;
         }
         data = data2;
      }
   }
   *output = data;
   stb_vorbis_close(v);
   return data_len;
}
#endif // NO_STDIO

int stb_vorbis_decode_memory(const uint8 *mem, int len, int *channels, int *sample_rate, short **output)
{
   int data_len, offset, total, limit, error;
   short *data;
   stb_vorbis *v = stb_vorbis_open_memory(mem, len, &error, NULL);
   if (v == NULL) return -1;
   limit = v->channels * 4096;
   *channels = v->channels;
   if (sample_rate)
      *sample_rate = v->sample_rate;
   offset = data_len = 0;
   total = limit;
   data = (short *) malloc(total * sizeof(*data));
   if (data == NULL) {
      stb_vorbis_close(v);
      return -2;
   }
   for (;;) {
      int n = stb_vorbis_get_frame_short_interleaved(v, v->channels, data+offset, total-offset);
      if (n == 0) break;
      data_len += n;
      offset += n * v->channels;
      if (offset + limit > total) {
         short *data2;
         total *= 2;
         data2 = (short *) realloc(data, total * sizeof(*data));
         if (data2 == NULL) {
            free(data);
            stb_vorbis_close(v);
            return -2;
         }
         data = data2;
      }
   }
   *output = data;
   stb_vorbis_close(v);
   return data_len;
}
#endif // STB_VORBIS_NO_INTEGER_CONVERSION

int stb_vorbis_get_samples_float_interleaved(stb_vorbis *f, int channels, float *buffer, int num_floats)
{
   float **outputs;
   int len = num_floats / channels;
   int n=0;
   int z = f->channels;
   if (z > channels) z = channels;
   while (n < len) {
      int i,j;
      int k = f->channel_buffer_end - f->channel_buffer_start;
      if (n+k >= len) k = len - n;
      for (j=0; j < k; ++j) {
         for (i=0; i < z; ++i)
            *buffer++ = f->channel_buffers[i][f->channel_buffer_start+j];
         for (   ; i < channels; ++i)
            *buffer++ = 0;
      }
      n += k;
      f->channel_buffer_start += k;
      if (n == len)
         break;
      if (!stb_vorbis_get_frame_float(f, NULL, &outputs))
         break;
   }
   return n;
}

int stb_vorbis_get_samples_float(stb_vorbis *f, int channels, float **buffer, int num_samples)
{
   float **outputs;
   int n=0;
   int z = f->channels;
   if (z > channels) z = channels;
   while (n < num_samples) {
      int i;
      int k = f->channel_buffer_end - f->channel_buffer_start;
      if (n+k >= num_samples) k = num_samples - n;
      if (k) {
         for (i=0; i < z; ++i)
            memcpy(buffer[i]+n, f->channel_buffers[i]+f->channel_buffer_start, sizeof(float)*k);
         for (   ; i < channels; ++i)
            memset(buffer[i]+n, 0, sizeof(float) * k);
      }
      n += k;
      f->channel_buffer_start += k;
      if (n == num_samples)
         break;
      if (!stb_vorbis_get_frame_float(f, NULL, &outputs))
         break;
   }
   return n;
}
#endif // STB_VORBIS_NO_PULLDATA_API

/* Version history
    1.09    - 2016/04/04 - back out 'avoid discarding last frame' fix from previous version
    1.08    - 2016/04/02 - fixed multiple warnings; fix setup memory leaks;
                           avoid discarding last frame of audio data
    1.07    - 2015/01/16 - fixed some warnings, fix mingw, const-correct API
                           some more crash fixes when out of memory or with corrupt files 
    1.06    - 2015/08/31 - full, correct support for seeking API (Dougall Johnson)
                           some crash fixes when out of memory or with corrupt files
    1.05    - 2015/04/19 - don't define __forceinline if it's redundant
    1.04    - 2014/08/27 - fix missing const-correct case in API
    1.03    - 2014/08/07 - Warning fixes
    1.02    - 2014/07/09 - Declare qsort compare function _cdecl on windows
    1.01    - 2014/06/18 - fix stb_vorbis_get_samples_float
    1.0     - 2014/05/26 - fix memory leaks; fix warnings; fix bugs in multichannel
                           (API change) report sample rate for decode-full-file funcs
    0.99996 - bracket #include <malloc.h> for macintosh compilation by Laurent Gomila
    0.99995 - use union instead of pointer-cast for fast-float-to-int to avoid alias-optimization problem
    0.99994 - change fast-float-to-int to work in single-precision FPU mode, remove endian-dependence
    0.99993 - remove assert that fired on legal files with empty tables
    0.99992 - rewind-to-start
    0.99991 - bugfix to stb_vorbis_get_samples_short by Bernhard Wodo
    0.9999 - (should have been 0.99990) fix no-CRT support, compiling as C++
    0.9998 - add a full-decode function with a memory source
    0.9997 - fix a bug in the read-from-FILE case in 0.9996 addition
    0.9996 - query length of vorbis stream in samples/seconds
    0.9995 - bugfix to another optimization that only happened in certain files
    0.9994 - bugfix to one of the optimizations that caused significant (but inaudible?) errors
    0.9993 - performance improvements; runs in 99% to 104% of time of reference implementation
    0.9992 - performance improvement of IMDCT; now performs close to reference implementation
    0.9991 - performance improvement of IMDCT
    0.999 - (should have been 0.9990) performance improvement of IMDCT
    0.998 - no-CRT support from Casey Muratori
    0.997 - bugfixes for bugs found by Terje Mathisen
    0.996 - bugfix: fast-huffman decode initialized incorrectly for sparse codebooks; fixing gives 10% speedup - found by Terje Mathisen
    0.995 - bugfix: fix to 'effective' overrun detection - found by Terje Mathisen
    0.994 - bugfix: garbage decode on final VQ symbol of a non-multiple - found by Terje Mathisen
    0.993 - bugfix: pushdata API required 1 extra byte for empty page (failed to consume final page if empty) - found by Terje Mathisen
    0.992 - fixes for MinGW warning
    0.991 - turn fast-float-conversion on by default
    0.990 - fix push-mode seek recovery if you seek into the headers
    0.98b - fix to bad release of 0.98
    0.98 - fix push-mode seek recovery; robustify float-to-int and support non-fast mode
    0.97 - builds under c++ (typecasting, don't use 'class' keyword)
    0.96 - somehow MY 0.95 was right, but the web one was wrong, so here's my 0.95 rereleased as 0.96, fixes a typo in the clamping code
    0.95 - clamping code for 16-bit functions
    0.94 - not publically released
    0.93 - fixed all-zero-floor case (was decoding garbage)
    0.92 - fixed a memory leak
    0.91 - conditional compiles to omit parts of the API and the infrastructure to support them: STB_VORBIS_NO_PULLDATA_API, STB_VORBIS_NO_PUSHDATA_API, STB_VORBIS_NO_STDIO, STB_VORBIS_NO_INTEGER_CONVERSION
    0.90 - first public release
*/

#endif // STB_VORBIS_HEADER_ONLY

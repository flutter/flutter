/* ioapi.h -- IO base function header for compress/uncompress .zip
   part of the MiniZip project - ( http://www.winimage.com/zLibDll/minizip.html )

         Copyright (C) 1998-2010 Gilles Vollant (minizip) ( http://www.winimage.com/zLibDll/minizip.html )

         Modifications for Zip64 support
         Copyright (C) 2009-2010 Mathias Svensson ( http://result42.com )

         For more info read MiniZip_info.txt

         Changes

    Oct-2009 - Defined ZPOS64_T to fpos_t on windows and u_int64_t on linux. (might need to find a better why for this)
    Oct-2009 - Change to fseeko64, ftello64 and fopen64 so large files would work on linux.
               More if/def section may be needed to support other platforms
    Oct-2009 - Defined fxxxx64 calls to normal fopen/ftell/fseek so they would compile on windows.
                          (but you should use iowin32.c for windows instead)

*/

#ifndef _ZLIBIOAPI64_H
#define _ZLIBIOAPI64_H

#if (!defined(_WIN32)) && (!defined(WIN32)) && (!defined(__APPLE__))

  // Linux needs this to support file operation on files larger then 4+GB
  // But might need better if/def to select just the platforms that needs them.

        #ifndef __USE_FILE_OFFSET64
                #define __USE_FILE_OFFSET64
        #endif
        #ifndef __USE_LARGEFILE64
                #define __USE_LARGEFILE64
        #endif
        #ifndef _LARGEFILE64_SOURCE
                #define _LARGEFILE64_SOURCE
        #endif
        #ifndef _FILE_OFFSET_BIT
                #define _FILE_OFFSET_BIT 64
        #endif

#endif

#include <stdio.h>
#include <stdlib.h>
#include "third_party/zlib/zlib.h"

#if defined(USE_FILE32API)
#define fopen64 fopen
#define ftello64 ftell
#define fseeko64 fseek
#else
#ifdef __FreeBSD__
#define fopen64 fopen
#define ftello64 ftello
#define fseeko64 fseeko
#endif
#ifdef _MSC_VER
 #define fopen64 fopen
 #if (_MSC_VER >= 1400) && (!(defined(NO_MSCVER_FILE64_FUNC)))
  #define ftello64 _ftelli64
  #define fseeko64 _fseeki64
 #else // old MSC
  #define ftello64 ftell
  #define fseeko64 fseek
 #endif
#endif
#endif

/*
#ifndef ZPOS64_T
  #ifdef _WIN32
                #define ZPOS64_T fpos_t
  #else
    #include <stdint.h>
    #define ZPOS64_T uint64_t
  #endif
#endif
*/

#ifdef HAVE_MINIZIP64_CONF_H
#include "mz64conf.h"
#endif

/* a type choosen by DEFINE */
#ifdef HAVE_64BIT_INT_CUSTOM
typedef  64BIT_INT_CUSTOM_TYPE ZPOS64_T;
#else
#ifdef HAS_STDINT_H
#include "stdint.h"
typedef uint64_t ZPOS64_T;
#else

/* Maximum unsigned 32-bit value used as placeholder for zip64 */
#define MAXU32 0xffffffff

#if defined(_MSC_VER) || defined(__BORLANDC__)
typedef unsigned __int64 ZPOS64_T;
#else
typedef unsigned long long int ZPOS64_T;
#endif
#endif
#endif



#ifdef __cplusplus
extern "C" {
#endif


#define ZLIB_FILEFUNC_SEEK_CUR (1)
#define ZLIB_FILEFUNC_SEEK_END (2)
#define ZLIB_FILEFUNC_SEEK_SET (0)

#define ZLIB_FILEFUNC_MODE_READ      (1)
#define ZLIB_FILEFUNC_MODE_WRITE     (2)
#define ZLIB_FILEFUNC_MODE_READWRITEFILTER (3)

#define ZLIB_FILEFUNC_MODE_EXISTING (4)
#define ZLIB_FILEFUNC_MODE_CREATE   (8)


#ifndef ZCALLBACK
 #if (defined(WIN32) || defined(_WIN32) || defined (WINDOWS) || defined (_WINDOWS)) && defined(CALLBACK) && defined (USEWINDOWS_CALLBACK)
   #define ZCALLBACK CALLBACK
 #else
   #define ZCALLBACK
 #endif
#endif




typedef voidpf   (ZCALLBACK *open_file_func)      OF((voidpf opaque, const char* filename, int mode));
typedef uLong    (ZCALLBACK *read_file_func)      OF((voidpf opaque, voidpf stream, void* buf, uLong size));
typedef uLong    (ZCALLBACK *write_file_func)     OF((voidpf opaque, voidpf stream, const void* buf, uLong size));
typedef int      (ZCALLBACK *close_file_func)     OF((voidpf opaque, voidpf stream));
typedef int      (ZCALLBACK *testerror_file_func) OF((voidpf opaque, voidpf stream));

typedef long     (ZCALLBACK *tell_file_func)      OF((voidpf opaque, voidpf stream));
typedef long     (ZCALLBACK *seek_file_func)      OF((voidpf opaque, voidpf stream, uLong offset, int origin));


/* here is the "old" 32 bits structure structure */
typedef struct zlib_filefunc_def_s
{
    open_file_func      zopen_file;
    read_file_func      zread_file;
    write_file_func     zwrite_file;
    tell_file_func      ztell_file;
    seek_file_func      zseek_file;
    close_file_func     zclose_file;
    testerror_file_func zerror_file;
    voidpf              opaque;
} zlib_filefunc_def;

typedef ZPOS64_T (ZCALLBACK *tell64_file_func)    OF((voidpf opaque, voidpf stream));
typedef long     (ZCALLBACK *seek64_file_func)    OF((voidpf opaque, voidpf stream, ZPOS64_T offset, int origin));
typedef voidpf   (ZCALLBACK *open64_file_func)    OF((voidpf opaque, const void* filename, int mode));

typedef struct zlib_filefunc64_def_s
{
    open64_file_func    zopen64_file;
    read_file_func      zread_file;
    write_file_func     zwrite_file;
    tell64_file_func    ztell64_file;
    seek64_file_func    zseek64_file;
    close_file_func     zclose_file;
    testerror_file_func zerror_file;
    voidpf              opaque;
} zlib_filefunc64_def;

void fill_fopen64_filefunc OF((zlib_filefunc64_def* pzlib_filefunc_def));
void fill_fopen_filefunc OF((zlib_filefunc_def* pzlib_filefunc_def));

/* now internal definition, only for zip.c and unzip.h */
typedef struct zlib_filefunc64_32_def_s
{
    zlib_filefunc64_def zfile_func64;
    open_file_func      zopen32_file;
    tell_file_func      ztell32_file;
    seek_file_func      zseek32_file;
} zlib_filefunc64_32_def;


#define ZREAD64(filefunc,filestream,buf,size)     ((*((filefunc).zfile_func64.zread_file))   ((filefunc).zfile_func64.opaque,filestream,buf,size))
#define ZWRITE64(filefunc,filestream,buf,size)    ((*((filefunc).zfile_func64.zwrite_file))  ((filefunc).zfile_func64.opaque,filestream,buf,size))
//#define ZTELL64(filefunc,filestream)            ((*((filefunc).ztell64_file)) ((filefunc).opaque,filestream))
//#define ZSEEK64(filefunc,filestream,pos,mode)   ((*((filefunc).zseek64_file)) ((filefunc).opaque,filestream,pos,mode))
#define ZCLOSE64(filefunc,filestream)             ((*((filefunc).zfile_func64.zclose_file))  ((filefunc).zfile_func64.opaque,filestream))
#define ZERROR64(filefunc,filestream)             ((*((filefunc).zfile_func64.zerror_file))  ((filefunc).zfile_func64.opaque,filestream))

voidpf call_zopen64 OF((const zlib_filefunc64_32_def* pfilefunc,const void*filename,int mode));
long    call_zseek64 OF((const zlib_filefunc64_32_def* pfilefunc,voidpf filestream, ZPOS64_T offset, int origin));
ZPOS64_T call_ztell64 OF((const zlib_filefunc64_32_def* pfilefunc,voidpf filestream));

void    fill_zlib_filefunc64_32_def_from_filefunc32(zlib_filefunc64_32_def* p_filefunc64_32,const zlib_filefunc_def* p_filefunc32);

#define ZOPEN64(filefunc,filename,mode)         (call_zopen64((&(filefunc)),(filename),(mode)))
#define ZTELL64(filefunc,filestream)            (call_ztell64((&(filefunc)),(filestream)))
#define ZSEEK64(filefunc,filestream,pos,mode)   (call_zseek64((&(filefunc)),(filestream),(pos),(mode)))

#ifdef __cplusplus
}
#endif

#endif

/* iowin32.h -- IO base function header for compress/uncompress .zip
     Version 1.1, February 14h, 2010
     part of the MiniZip project - ( http://www.winimage.com/zLibDll/minizip.html )

         Copyright (C) 1998-2010 Gilles Vollant (minizip) ( http://www.winimage.com/zLibDll/minizip.html )

         Modifications for Zip64 support
         Copyright (C) 2009-2010 Mathias Svensson ( http://result42.com )

         For more info read MiniZip_info.txt

*/

#include <windows.h>


#ifdef __cplusplus
extern "C" {
#endif

void fill_win32_filefunc OF((zlib_filefunc_def* pzlib_filefunc_def));
void fill_win32_filefunc64 OF((zlib_filefunc64_def* pzlib_filefunc_def));
void fill_win32_filefunc64A OF((zlib_filefunc64_def* pzlib_filefunc_def));
void fill_win32_filefunc64W OF((zlib_filefunc64_def* pzlib_filefunc_def));

#ifdef __cplusplus
}
#endif

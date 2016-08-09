// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/zip_internal.h"

#include <algorithm>

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/utf_string_conversions.h"
#include "base/time/time.h"

#if defined(USE_SYSTEM_MINIZIP)
#include <minizip/ioapi.h>
#include <minizip/unzip.h>
#include <minizip/zip.h>
#else
#include "third_party/zlib/contrib/minizip/unzip.h"
#include "third_party/zlib/contrib/minizip/zip.h"
#if defined(OS_WIN)
#include "third_party/zlib/contrib/minizip/iowin32.h"
#elif defined(OS_POSIX)
#include "third_party/zlib/contrib/minizip/ioapi.h"
#endif  // defined(OS_POSIX)
#endif  // defined(USE_SYSTEM_MINIZIP)

namespace {

#if defined(OS_WIN)
typedef struct {
  HANDLE hf;
  int error;
} WIN32FILE_IOWIN;

// This function is derived from third_party/minizip/iowin32.c.
// Its only difference is that it treats the char* as UTF8 and
// uses the Unicode version of CreateFile.
void* ZipOpenFunc(void *opaque, const char* filename, int mode) {
  DWORD desired_access = 0, creation_disposition = 0;
  DWORD share_mode = 0, flags_and_attributes = 0;
  HANDLE file = 0;
  void* ret = NULL;

  if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER) == ZLIB_FILEFUNC_MODE_READ) {
    desired_access = GENERIC_READ;
    creation_disposition = OPEN_EXISTING;
    share_mode = FILE_SHARE_READ;
  } else if (mode & ZLIB_FILEFUNC_MODE_EXISTING) {
    desired_access = GENERIC_WRITE | GENERIC_READ;
    creation_disposition = OPEN_EXISTING;
  } else if (mode & ZLIB_FILEFUNC_MODE_CREATE) {
    desired_access = GENERIC_WRITE | GENERIC_READ;
    creation_disposition = CREATE_ALWAYS;
  }

  base::string16 filename16 = base::UTF8ToUTF16(filename);
  if ((filename != NULL) && (desired_access != 0)) {
    file = CreateFile(filename16.c_str(), desired_access, share_mode,
        NULL, creation_disposition, flags_and_attributes, NULL);
  }

  if (file == INVALID_HANDLE_VALUE)
    file = NULL;

  if (file != NULL) {
    WIN32FILE_IOWIN file_ret;
    file_ret.hf = file;
    file_ret.error = 0;
    ret = malloc(sizeof(WIN32FILE_IOWIN));
    if (ret == NULL)
      CloseHandle(file);
    else
      *(static_cast<WIN32FILE_IOWIN*>(ret)) = file_ret;
  }
  return ret;
}
#endif

#if defined(OS_POSIX)
// Callback function for zlib that opens a file stream from a file descriptor.
// Since we do not own the file descriptor, dup it so that we can fdopen/fclose
// a file stream.
void* FdOpenFileFunc(void* opaque, const char* filename, int mode) {
  FILE* file = NULL;
  const char* mode_fopen = NULL;

  if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER) == ZLIB_FILEFUNC_MODE_READ)
    mode_fopen = "rb";
  else if (mode & ZLIB_FILEFUNC_MODE_EXISTING)
    mode_fopen = "r+b";
  else if (mode & ZLIB_FILEFUNC_MODE_CREATE)
    mode_fopen = "wb";

  if ((filename != NULL) && (mode_fopen != NULL)) {
    int fd = dup(*static_cast<int*>(opaque));
    if (fd != -1)
      file = fdopen(fd, mode_fopen);
  }

  return file;
}

int FdCloseFileFunc(void* opaque, void* stream) {
  fclose(static_cast<FILE*>(stream));
  free(opaque); // malloc'ed in FillFdOpenFileFunc()
  return 0;
}

// Fills |pzlib_filecunc_def| appropriately to handle the zip file
// referred to by |fd|.
void FillFdOpenFileFunc(zlib_filefunc_def* pzlib_filefunc_def, int fd) {
  fill_fopen_filefunc(pzlib_filefunc_def);
  pzlib_filefunc_def->zopen_file = FdOpenFileFunc;
  pzlib_filefunc_def->zclose_file = FdCloseFileFunc;
  int* ptr_fd = static_cast<int*>(malloc(sizeof(fd)));
  *ptr_fd = fd;
  pzlib_filefunc_def->opaque = ptr_fd;
}
#endif  // defined(OS_POSIX)

#if defined(OS_WIN)
// Callback function for zlib that opens a file stream from a Windows handle.
// Does not take ownership of the handle.
void* HandleOpenFileFunc(void* opaque, const char* filename, int mode) {
  WIN32FILE_IOWIN file_ret;
  file_ret.hf = static_cast<HANDLE>(opaque);
  file_ret.error = 0;
  if (file_ret.hf == INVALID_HANDLE_VALUE)
    return NULL;

  void* ret = malloc(sizeof(WIN32FILE_IOWIN));
  if (ret != NULL)
    *(static_cast<WIN32FILE_IOWIN*>(ret)) = file_ret;
  return ret;
}

int HandleCloseFileFunc(void* opaque, void* stream) {
  free(stream); // malloc'ed in HandleOpenFileFunc()
  return 0;
}
#endif

// A struct that contains data required for zlib functions to extract files from
// a zip archive stored in memory directly. The following I/O API functions
// expect their opaque parameters refer to this struct.
struct ZipBuffer {
  const char* data;  // weak
  size_t length;
  size_t offset;
};

// Opens the specified file. When this function returns a non-NULL pointer, zlib
// uses this pointer as a stream parameter while compressing or uncompressing
// data. (Returning NULL represents an error.) This function initializes the
// given opaque parameter and returns it because this parameter stores all
// information needed for uncompressing data. (This function does not support
// writing compressed data and it returns NULL for this case.)
void* OpenZipBuffer(void* opaque, const char* /*filename*/, int mode) {
  if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER) != ZLIB_FILEFUNC_MODE_READ) {
    NOTREACHED();
    return NULL;
  }
  ZipBuffer* buffer = static_cast<ZipBuffer*>(opaque);
  if (!buffer || !buffer->data || !buffer->length)
    return NULL;
  buffer->offset = 0;
  return opaque;
}

// Reads compressed data from the specified stream. This function copies data
// refered by the opaque parameter and returns the size actually copied.
uLong ReadZipBuffer(void* opaque, void* /*stream*/, void* buf, uLong size) {
  ZipBuffer* buffer = static_cast<ZipBuffer*>(opaque);
  DCHECK_LE(buffer->offset, buffer->length);
  size_t remaining_bytes = buffer->length - buffer->offset;
  if (!buffer || !buffer->data || !remaining_bytes)
    return 0;
  size = std::min(size, static_cast<uLong>(remaining_bytes));
  memcpy(buf, &buffer->data[buffer->offset], size);
  buffer->offset += size;
  return size;
}

// Writes compressed data to the stream. This function always returns zero
// because this implementation is only for reading compressed data.
uLong WriteZipBuffer(void* /*opaque*/,
                     void* /*stream*/,
                     const void* /*buf*/,
                     uLong /*size*/) {
  NOTREACHED();
  return 0;
}

// Returns the offset from the beginning of the data.
long GetOffsetOfZipBuffer(void* opaque, void* /*stream*/) {
  ZipBuffer* buffer = static_cast<ZipBuffer*>(opaque);
  if (!buffer)
    return -1;
  return static_cast<long>(buffer->offset);
}

// Moves the current offset to the specified position.
long SeekZipBuffer(void* opaque, void* /*stream*/, uLong offset, int origin) {
  ZipBuffer* buffer = static_cast<ZipBuffer*>(opaque);
  if (!buffer)
    return -1;
  if (origin == ZLIB_FILEFUNC_SEEK_CUR) {
    buffer->offset = std::min(buffer->offset + static_cast<size_t>(offset),
                              buffer->length);
    return 0;
  }
  if (origin == ZLIB_FILEFUNC_SEEK_END) {
    buffer->offset = (buffer->length > offset) ? buffer->length - offset : 0;
    return 0;
  }
  if (origin == ZLIB_FILEFUNC_SEEK_SET) {
    buffer->offset = std::min(buffer->length, static_cast<size_t>(offset));
    return 0;
  }
  NOTREACHED();
  return -1;
}

// Closes the input offset and deletes all resources used for compressing or
// uncompressing data. This function deletes the ZipBuffer object referred by
// the opaque parameter since zlib deletes the unzFile object and it does not
// use this object any longer.
int CloseZipBuffer(void* opaque, void* /*stream*/) {
  if (opaque)
    free(opaque);
  return 0;
}

// Returns the last error happened when reading or writing data. This function
// always returns zero, which means there are not any errors.
int GetErrorOfZipBuffer(void* /*opaque*/, void* /*stream*/) {
  return 0;
}

// Returns a zip_fileinfo struct with the time represented by |file_time|.
zip_fileinfo TimeToZipFileInfo(const base::Time& file_time) {
  base::Time::Exploded file_time_parts;
  file_time.LocalExplode(&file_time_parts);

  zip_fileinfo zip_info = {};
  if (file_time_parts.year >= 1980) {
    // This if check works around the handling of the year value in
    // contrib/minizip/zip.c in function zip64local_TmzDateToDosDate
    // It assumes that dates below 1980 are in the double digit format.
    // Hence the fail safe option is to leave the date unset. Some programs
    // might show the unset date as 1980-0-0 which is invalid.
    zip_info.tmz_date.tm_year = file_time_parts.year;
    zip_info.tmz_date.tm_mon = file_time_parts.month - 1;
    zip_info.tmz_date.tm_mday = file_time_parts.day_of_month;
    zip_info.tmz_date.tm_hour = file_time_parts.hour;
    zip_info.tmz_date.tm_min = file_time_parts.minute;
    zip_info.tmz_date.tm_sec = file_time_parts.second;
  }

  return zip_info;
}
}  // namespace

namespace zip {
namespace internal {

unzFile OpenForUnzipping(const std::string& file_name_utf8) {
  zlib_filefunc_def* zip_func_ptrs = NULL;
#if defined(OS_WIN)
  zlib_filefunc_def zip_funcs;
  fill_win32_filefunc(&zip_funcs);
  zip_funcs.zopen_file = ZipOpenFunc;
  zip_func_ptrs = &zip_funcs;
#endif
  return unzOpen2(file_name_utf8.c_str(), zip_func_ptrs);
}

#if defined(OS_POSIX)
unzFile OpenFdForUnzipping(int zip_fd) {
  zlib_filefunc_def zip_funcs;
  FillFdOpenFileFunc(&zip_funcs, zip_fd);
  // Passing dummy "fd" filename to zlib.
  return unzOpen2("fd", &zip_funcs);
}
#endif

#if defined(OS_WIN)
unzFile OpenHandleForUnzipping(HANDLE zip_handle) {
  zlib_filefunc_def zip_funcs;
  fill_win32_filefunc(&zip_funcs);
  zip_funcs.zopen_file = HandleOpenFileFunc;
  zip_funcs.zclose_file = HandleCloseFileFunc;
  zip_funcs.opaque = zip_handle;
  return unzOpen2("fd", &zip_funcs);
}
#endif

// static
unzFile PrepareMemoryForUnzipping(const std::string& data) {
  if (data.empty())
    return NULL;

  ZipBuffer* buffer = static_cast<ZipBuffer*>(malloc(sizeof(ZipBuffer)));
  if (!buffer)
    return NULL;
  buffer->data = data.data();
  buffer->length = data.length();
  buffer->offset = 0;

  zlib_filefunc_def zip_functions;
  zip_functions.zopen_file = OpenZipBuffer;
  zip_functions.zread_file = ReadZipBuffer;
  zip_functions.zwrite_file = WriteZipBuffer;
  zip_functions.ztell_file = GetOffsetOfZipBuffer;
  zip_functions.zseek_file = SeekZipBuffer;
  zip_functions.zclose_file = CloseZipBuffer;
  zip_functions.zerror_file = GetErrorOfZipBuffer;
  zip_functions.opaque = static_cast<void*>(buffer);
  return unzOpen2(NULL, &zip_functions);
}

zipFile OpenForZipping(const std::string& file_name_utf8, int append_flag) {
  zlib_filefunc_def* zip_func_ptrs = NULL;
#if defined(OS_WIN)
  zlib_filefunc_def zip_funcs;
  fill_win32_filefunc(&zip_funcs);
  zip_funcs.zopen_file = ZipOpenFunc;
  zip_func_ptrs = &zip_funcs;
#endif
  return zipOpen2(file_name_utf8.c_str(),
                  append_flag,
                  NULL,  // global comment
                  zip_func_ptrs);
}

#if defined(OS_POSIX)
zipFile OpenFdForZipping(int zip_fd, int append_flag) {
  zlib_filefunc_def zip_funcs;
  FillFdOpenFileFunc(&zip_funcs, zip_fd);
  // Passing dummy "fd" filename to zlib.
  return zipOpen2("fd", append_flag, NULL, &zip_funcs);
}
#endif

zip_fileinfo GetFileInfoForZipping(const base::FilePath& path) {
  base::Time file_time;
  base::File::Info file_info;
  if (base::GetFileInfo(path, &file_info))
    file_time = file_info.last_modified;
  return TimeToZipFileInfo(file_time);
}

bool ZipOpenNewFileInZip(zipFile zip_file,
                         const std::string& str_path,
                         const zip_fileinfo* file_info) {
  // Section 4.4.4 http://www.pkware.com/documents/casestudies/APPNOTE.TXT
  // Setting the Language encoding flag so the file is told to be in utf-8.
  const uLong LANGUAGE_ENCODING_FLAG = 0x1 << 11;

  if (ZIP_OK != zipOpenNewFileInZip4(
                    zip_file,  // file
                    str_path.c_str(),  // filename
                    file_info,  // zipfi
                    NULL,  // extrafield_local,
                    0u,  // size_extrafield_local
                    NULL,  // extrafield_global
                    0u,  // size_extrafield_global
                    NULL,  // comment
                    Z_DEFLATED,  // method
                    Z_DEFAULT_COMPRESSION,  // level
                    0,  // raw
                    -MAX_WBITS,  // windowBits
                    DEF_MEM_LEVEL,  // memLevel
                    Z_DEFAULT_STRATEGY,  // strategy
                    NULL,  // password
                    0,  // crcForCrypting
                    0,  // versionMadeBy
                    LANGUAGE_ENCODING_FLAG)) {  // flagBase
    DLOG(ERROR) << "Could not open zip file entry " << str_path;
    return false;
  }
  return true;
}

}  // namespace internal
}  // namespace zip

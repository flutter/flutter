// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// This file contains common implementations of the interfaces defined in
// zero_copy_stream.h which are only included in the full (non-lite)
// protobuf library.  These implementations include Unix file descriptors
// and C++ iostreams.  See also:  zero_copy_stream_impl_lite.h

#ifndef GOOGLE_PROTOBUF_IO_ZERO_COPY_STREAM_IMPL_H__
#define GOOGLE_PROTOBUF_IO_ZERO_COPY_STREAM_IMPL_H__

#include <string>
#include <iosfwd>
#include <google/protobuf/io/zero_copy_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl_lite.h>
#include <google/protobuf/stubs/common.h>


namespace google {
namespace protobuf {
namespace io {


// ===================================================================

// A ZeroCopyInputStream which reads from a file descriptor.
//
// FileInputStream is preferred over using an ifstream with IstreamInputStream.
// The latter will introduce an extra layer of buffering, harming performance.
// Also, it's conceivable that FileInputStream could someday be enhanced
// to use zero-copy file descriptors on OSs which support them.
class LIBPROTOBUF_EXPORT FileInputStream : public ZeroCopyInputStream {
 public:
  // Creates a stream that reads from the given Unix file descriptor.
  // If a block_size is given, it specifies the number of bytes that
  // should be read and returned with each call to Next().  Otherwise,
  // a reasonable default is used.
  explicit FileInputStream(int file_descriptor, int block_size = -1);
  ~FileInputStream();

  // Flushes any buffers and closes the underlying file.  Returns false if
  // an error occurs during the process; use GetErrno() to examine the error.
  // Even if an error occurs, the file descriptor is closed when this returns.
  bool Close();

  // By default, the file descriptor is not closed when the stream is
  // destroyed.  Call SetCloseOnDelete(true) to change that.  WARNING:
  // This leaves no way for the caller to detect if close() fails.  If
  // detecting close() errors is important to you, you should arrange
  // to close the descriptor yourself.
  void SetCloseOnDelete(bool value) { copying_input_.SetCloseOnDelete(value); }

  // If an I/O error has occurred on this file descriptor, this is the
  // errno from that error.  Otherwise, this is zero.  Once an error
  // occurs, the stream is broken and all subsequent operations will
  // fail.
  int GetErrno() { return copying_input_.GetErrno(); }

  // implements ZeroCopyInputStream ----------------------------------
  bool Next(const void** data, int* size);
  void BackUp(int count);
  bool Skip(int count);
  int64 ByteCount() const;

 private:
  class LIBPROTOBUF_EXPORT CopyingFileInputStream : public CopyingInputStream {
   public:
    CopyingFileInputStream(int file_descriptor);
    ~CopyingFileInputStream();

    bool Close();
    void SetCloseOnDelete(bool value) { close_on_delete_ = value; }
    int GetErrno() { return errno_; }

    // implements CopyingInputStream ---------------------------------
    int Read(void* buffer, int size);
    int Skip(int count);

   private:
    // The file descriptor.
    const int file_;
    bool close_on_delete_;
    bool is_closed_;

    // The errno of the I/O error, if one has occurred.  Otherwise, zero.
    int errno_;

    // Did we try to seek once and fail?  If so, we assume this file descriptor
    // doesn't support seeking and won't try again.
    bool previous_seek_failed_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CopyingFileInputStream);
  };

  CopyingFileInputStream copying_input_;
  CopyingInputStreamAdaptor impl_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(FileInputStream);
};

// ===================================================================

// A ZeroCopyOutputStream which writes to a file descriptor.
//
// FileOutputStream is preferred over using an ofstream with
// OstreamOutputStream.  The latter will introduce an extra layer of buffering,
// harming performance.  Also, it's conceivable that FileOutputStream could
// someday be enhanced to use zero-copy file descriptors on OSs which
// support them.
class LIBPROTOBUF_EXPORT FileOutputStream : public ZeroCopyOutputStream {
 public:
  // Creates a stream that writes to the given Unix file descriptor.
  // If a block_size is given, it specifies the size of the buffers
  // that should be returned by Next().  Otherwise, a reasonable default
  // is used.
  explicit FileOutputStream(int file_descriptor, int block_size = -1);
  ~FileOutputStream();

  // Flushes any buffers and closes the underlying file.  Returns false if
  // an error occurs during the process; use GetErrno() to examine the error.
  // Even if an error occurs, the file descriptor is closed when this returns.
  bool Close();

  // Flushes FileOutputStream's buffers but does not close the
  // underlying file. No special measures are taken to ensure that
  // underlying operating system file object is synchronized to disk.
  bool Flush();

  // By default, the file descriptor is not closed when the stream is
  // destroyed.  Call SetCloseOnDelete(true) to change that.  WARNING:
  // This leaves no way for the caller to detect if close() fails.  If
  // detecting close() errors is important to you, you should arrange
  // to close the descriptor yourself.
  void SetCloseOnDelete(bool value) { copying_output_.SetCloseOnDelete(value); }

  // If an I/O error has occurred on this file descriptor, this is the
  // errno from that error.  Otherwise, this is zero.  Once an error
  // occurs, the stream is broken and all subsequent operations will
  // fail.
  int GetErrno() { return copying_output_.GetErrno(); }

  // implements ZeroCopyOutputStream ---------------------------------
  bool Next(void** data, int* size);
  void BackUp(int count);
  int64 ByteCount() const;

 private:
  class LIBPROTOBUF_EXPORT CopyingFileOutputStream : public CopyingOutputStream {
   public:
    CopyingFileOutputStream(int file_descriptor);
    ~CopyingFileOutputStream();

    bool Close();
    void SetCloseOnDelete(bool value) { close_on_delete_ = value; }
    int GetErrno() { return errno_; }

    // implements CopyingOutputStream --------------------------------
    bool Write(const void* buffer, int size);

   private:
    // The file descriptor.
    const int file_;
    bool close_on_delete_;
    bool is_closed_;

    // The errno of the I/O error, if one has occurred.  Otherwise, zero.
    int errno_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CopyingFileOutputStream);
  };

  CopyingFileOutputStream copying_output_;
  CopyingOutputStreamAdaptor impl_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(FileOutputStream);
};

// ===================================================================

// A ZeroCopyInputStream which reads from a C++ istream.
//
// Note that for reading files (or anything represented by a file descriptor),
// FileInputStream is more efficient.
class LIBPROTOBUF_EXPORT IstreamInputStream : public ZeroCopyInputStream {
 public:
  // Creates a stream that reads from the given C++ istream.
  // If a block_size is given, it specifies the number of bytes that
  // should be read and returned with each call to Next().  Otherwise,
  // a reasonable default is used.
  explicit IstreamInputStream(istream* stream, int block_size = -1);
  ~IstreamInputStream();

  // implements ZeroCopyInputStream ----------------------------------
  bool Next(const void** data, int* size);
  void BackUp(int count);
  bool Skip(int count);
  int64 ByteCount() const;

 private:
  class LIBPROTOBUF_EXPORT CopyingIstreamInputStream : public CopyingInputStream {
   public:
    CopyingIstreamInputStream(istream* input);
    ~CopyingIstreamInputStream();

    // implements CopyingInputStream ---------------------------------
    int Read(void* buffer, int size);
    // (We use the default implementation of Skip().)

   private:
    // The stream.
    istream* input_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CopyingIstreamInputStream);
  };

  CopyingIstreamInputStream copying_input_;
  CopyingInputStreamAdaptor impl_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(IstreamInputStream);
};

// ===================================================================

// A ZeroCopyOutputStream which writes to a C++ ostream.
//
// Note that for writing files (or anything represented by a file descriptor),
// FileOutputStream is more efficient.
class LIBPROTOBUF_EXPORT OstreamOutputStream : public ZeroCopyOutputStream {
 public:
  // Creates a stream that writes to the given C++ ostream.
  // If a block_size is given, it specifies the size of the buffers
  // that should be returned by Next().  Otherwise, a reasonable default
  // is used.
  explicit OstreamOutputStream(ostream* stream, int block_size = -1);
  ~OstreamOutputStream();

  // implements ZeroCopyOutputStream ---------------------------------
  bool Next(void** data, int* size);
  void BackUp(int count);
  int64 ByteCount() const;

 private:
  class LIBPROTOBUF_EXPORT CopyingOstreamOutputStream : public CopyingOutputStream {
   public:
    CopyingOstreamOutputStream(ostream* output);
    ~CopyingOstreamOutputStream();

    // implements CopyingOutputStream --------------------------------
    bool Write(const void* buffer, int size);

   private:
    // The stream.
    ostream* output_;

    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CopyingOstreamOutputStream);
  };

  CopyingOstreamOutputStream copying_output_;
  CopyingOutputStreamAdaptor impl_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(OstreamOutputStream);
};

// ===================================================================

// A ZeroCopyInputStream which reads from several other streams in sequence.
// ConcatenatingInputStream is unable to distinguish between end-of-stream
// and read errors in the underlying streams, so it assumes any errors mean
// end-of-stream.  So, if the underlying streams fail for any other reason,
// ConcatenatingInputStream may do odd things.  It is suggested that you do
// not use ConcatenatingInputStream on streams that might produce read errors
// other than end-of-stream.
class LIBPROTOBUF_EXPORT ConcatenatingInputStream : public ZeroCopyInputStream {
 public:
  // All streams passed in as well as the array itself must remain valid
  // until the ConcatenatingInputStream is destroyed.
  ConcatenatingInputStream(ZeroCopyInputStream* const streams[], int count);
  ~ConcatenatingInputStream();

  // implements ZeroCopyInputStream ----------------------------------
  bool Next(const void** data, int* size);
  void BackUp(int count);
  bool Skip(int count);
  int64 ByteCount() const;


 private:
  // As streams are retired, streams_ is incremented and count_ is
  // decremented.
  ZeroCopyInputStream* const* streams_;
  int stream_count_;
  int64 bytes_retired_;  // Bytes read from previous streams.

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(ConcatenatingInputStream);
};

// ===================================================================

// A ZeroCopyInputStream which wraps some other stream and limits it to
// a particular byte count.
class LIBPROTOBUF_EXPORT LimitingInputStream : public ZeroCopyInputStream {
 public:
  LimitingInputStream(ZeroCopyInputStream* input, int64 limit);
  ~LimitingInputStream();

  // implements ZeroCopyInputStream ----------------------------------
  bool Next(const void** data, int* size);
  void BackUp(int count);
  bool Skip(int count);
  int64 ByteCount() const;


 private:
  ZeroCopyInputStream* input_;
  int64 limit_;  // Decreases as we go, becomes negative if we overshoot.

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(LimitingInputStream);
};

// ===================================================================

}  // namespace io
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_IO_ZERO_COPY_STREAM_IMPL_H__

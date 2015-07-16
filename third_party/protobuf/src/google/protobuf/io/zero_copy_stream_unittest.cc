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
// Testing strategy:  For each type of I/O (array, string, file, etc.) we
// create an output stream and write some data to it, then create a
// corresponding input stream to read the same data back and expect it to
// match.  When the data is written, it is written in several small chunks
// of varying sizes, with a BackUp() after each chunk.  It is read back
// similarly, but with chunks separated at different points.  The whole
// process is run with a variety of block sizes for both the input and
// the output.
//
// TODO(kenton):  Rewrite this test to bring it up to the standards of all
//   the other proto2 tests.  May want to wait for gTest to implement
//   "parametized tests" so that one set of tests can be used on all the
//   implementations.

#include "config.h"

#ifdef _MSC_VER
#include <io.h>
#else
#include <unistd.h>
#endif
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <sstream>

#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/io/coded_stream.h>

#if HAVE_ZLIB
#include <google/protobuf/io/gzip_stream.h>
#endif

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <google/protobuf/testing/file.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace io {
namespace {

#ifdef _WIN32
#define pipe(fds) _pipe(fds, 4096, O_BINARY)
#endif

#ifndef O_BINARY
#ifdef _O_BINARY
#define O_BINARY _O_BINARY
#else
#define O_BINARY 0     // If this isn't defined, the platform doesn't need it.
#endif
#endif

class IoTest : public testing::Test {
 protected:
  // Test helpers.

  // Helper to write an array of data to an output stream.
  bool WriteToOutput(ZeroCopyOutputStream* output, const void* data, int size);
  // Helper to read a fixed-length array of data from an input stream.
  int ReadFromInput(ZeroCopyInputStream* input, void* data, int size);
  // Write a string to the output stream.
  void WriteString(ZeroCopyOutputStream* output, const string& str);
  // Read a number of bytes equal to the size of the given string and checks
  // that it matches the string.
  void ReadString(ZeroCopyInputStream* input, const string& str);
  // Writes some text to the output stream in a particular order.  Returns
  // the number of bytes written, incase the caller needs that to set up an
  // input stream.
  int WriteStuff(ZeroCopyOutputStream* output);
  // Reads text from an input stream and expects it to match what
  // WriteStuff() writes.
  void ReadStuff(ZeroCopyInputStream* input);

  // Similar to WriteStuff, but performs more sophisticated testing.
  int WriteStuffLarge(ZeroCopyOutputStream* output);
  // Reads and tests a stream that should have been written to
  // via WriteStuffLarge().
  void ReadStuffLarge(ZeroCopyInputStream* input);

#if HAVE_ZLIB
  string Compress(const string& data, const GzipOutputStream::Options& options);
  string Uncompress(const string& data);
#endif

  static const int kBlockSizes[];
  static const int kBlockSizeCount;
};

const int IoTest::kBlockSizes[] = {-1, 1, 2, 5, 7, 10, 23, 64};
const int IoTest::kBlockSizeCount = GOOGLE_ARRAYSIZE(IoTest::kBlockSizes);

bool IoTest::WriteToOutput(ZeroCopyOutputStream* output,
                           const void* data, int size) {
  const uint8* in = reinterpret_cast<const uint8*>(data);
  int in_size = size;

  void* out;
  int out_size;

  while (true) {
    if (!output->Next(&out, &out_size)) {
      return false;
    }
    EXPECT_GT(out_size, 0);

    if (in_size <= out_size) {
      memcpy(out, in, in_size);
      output->BackUp(out_size - in_size);
      return true;
    }

    memcpy(out, in, out_size);
    in += out_size;
    in_size -= out_size;
  }
}

#define MAX_REPEATED_ZEROS 100

int IoTest::ReadFromInput(ZeroCopyInputStream* input, void* data, int size) {
  uint8* out = reinterpret_cast<uint8*>(data);
  int out_size = size;

  const void* in;
  int in_size = 0;

  int repeated_zeros = 0;

  while (true) {
    if (!input->Next(&in, &in_size)) {
      return size - out_size;
    }
    EXPECT_GT(in_size, -1);
    if (in_size == 0) {
      repeated_zeros++;
    } else {
      repeated_zeros = 0;
    }
    EXPECT_LT(repeated_zeros, MAX_REPEATED_ZEROS);

    if (out_size <= in_size) {
      memcpy(out, in, out_size);
      if (in_size > out_size) {
        input->BackUp(in_size - out_size);
      }
      return size;  // Copied all of it.
    }

    memcpy(out, in, in_size);
    out += in_size;
    out_size -= in_size;
  }
}

void IoTest::WriteString(ZeroCopyOutputStream* output, const string& str) {
  EXPECT_TRUE(WriteToOutput(output, str.c_str(), str.size()));
}

void IoTest::ReadString(ZeroCopyInputStream* input, const string& str) {
  scoped_array<char> buffer(new char[str.size() + 1]);
  buffer[str.size()] = '\0';
  EXPECT_EQ(ReadFromInput(input, buffer.get(), str.size()), str.size());
  EXPECT_STREQ(str.c_str(), buffer.get());
}

int IoTest::WriteStuff(ZeroCopyOutputStream* output) {
  WriteString(output, "Hello world!\n");
  WriteString(output, "Some te");
  WriteString(output, "xt.  Blah blah.");
  WriteString(output, "abcdefg");
  WriteString(output, "01234567890123456789");
  WriteString(output, "foobar");

  EXPECT_EQ(output->ByteCount(), 68);

  int result = output->ByteCount();
  return result;
}

// Reads text from an input stream and expects it to match what WriteStuff()
// writes.
void IoTest::ReadStuff(ZeroCopyInputStream* input) {
  ReadString(input, "Hello world!\n");
  ReadString(input, "Some text.  ");
  ReadString(input, "Blah ");
  ReadString(input, "blah.");
  ReadString(input, "abcdefg");
  EXPECT_TRUE(input->Skip(20));
  ReadString(input, "foo");
  ReadString(input, "bar");

  EXPECT_EQ(input->ByteCount(), 68);

  uint8 byte;
  EXPECT_EQ(ReadFromInput(input, &byte, 1), 0);
}

int IoTest::WriteStuffLarge(ZeroCopyOutputStream* output) {
  WriteString(output, "Hello world!\n");
  WriteString(output, "Some te");
  WriteString(output, "xt.  Blah blah.");
  WriteString(output, string(100000, 'x'));  // A very long string
  WriteString(output, string(100000, 'y'));  // A very long string
  WriteString(output, "01234567890123456789");

  EXPECT_EQ(output->ByteCount(), 200055);

  int result = output->ByteCount();
  return result;
}

// Reads text from an input stream and expects it to match what WriteStuff()
// writes.
void IoTest::ReadStuffLarge(ZeroCopyInputStream* input) {
  ReadString(input, "Hello world!\nSome text.  ");
  EXPECT_TRUE(input->Skip(5));
  ReadString(input, "blah.");
  EXPECT_TRUE(input->Skip(100000 - 10));
  ReadString(input, string(10, 'x') + string(100000 - 20000, 'y'));
  EXPECT_TRUE(input->Skip(20000 - 10));
  ReadString(input, "yyyyyyyyyy01234567890123456789");

  EXPECT_EQ(input->ByteCount(), 200055);

  uint8 byte;
  EXPECT_EQ(ReadFromInput(input, &byte, 1), 0);
}

// ===================================================================

TEST_F(IoTest, ArrayIo) {
  const int kBufferSize = 256;
  uint8 buffer[kBufferSize];

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      int size;
      {
        ArrayOutputStream output(buffer, kBufferSize, kBlockSizes[i]);
        size = WriteStuff(&output);
      }
      {
        ArrayInputStream input(buffer, size, kBlockSizes[j]);
        ReadStuff(&input);
      }
    }
  }
}

TEST_F(IoTest, TwoSessionWrite) {
  // Test that two concatenated write sessions read correctly

  static const char* strA = "0123456789";
  static const char* strB = "WhirledPeas";
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  char* temp_buffer = new char[40];

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      ArrayOutputStream* output =
          new ArrayOutputStream(buffer, kBufferSize, kBlockSizes[i]);
      CodedOutputStream* coded_output = new CodedOutputStream(output);
      coded_output->WriteVarint32(strlen(strA));
      coded_output->WriteRaw(strA, strlen(strA));
      delete coded_output;  // flush
      int64 pos = output->ByteCount();
      delete output;
      output = new ArrayOutputStream(
          buffer + pos, kBufferSize - pos, kBlockSizes[i]);
      coded_output = new CodedOutputStream(output);
      coded_output->WriteVarint32(strlen(strB));
      coded_output->WriteRaw(strB, strlen(strB));
      delete coded_output;  // flush
      int64 size = pos + output->ByteCount();
      delete output;

      ArrayInputStream* input =
          new ArrayInputStream(buffer, size, kBlockSizes[j]);
      CodedInputStream* coded_input = new CodedInputStream(input);
      uint32 insize;
      EXPECT_TRUE(coded_input->ReadVarint32(&insize));
      EXPECT_EQ(strlen(strA), insize);
      EXPECT_TRUE(coded_input->ReadRaw(temp_buffer, insize));
      EXPECT_EQ(0, memcmp(temp_buffer, strA, insize));

      EXPECT_TRUE(coded_input->ReadVarint32(&insize));
      EXPECT_EQ(strlen(strB), insize);
      EXPECT_TRUE(coded_input->ReadRaw(temp_buffer, insize));
      EXPECT_EQ(0, memcmp(temp_buffer, strB, insize));

      delete coded_input;
      delete input;
    }
  }

  delete [] temp_buffer;
  delete [] buffer;
}

#if HAVE_ZLIB
TEST_F(IoTest, GzipIo) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      for (int z = 0; z < kBlockSizeCount; z++) {
        int gzip_buffer_size = kBlockSizes[z];
        int size;
        {
          ArrayOutputStream output(buffer, kBufferSize, kBlockSizes[i]);
          GzipOutputStream::Options options;
          options.format = GzipOutputStream::GZIP;
          if (gzip_buffer_size != -1) {
            options.buffer_size = gzip_buffer_size;
          }
          GzipOutputStream gzout(&output, options);
          WriteStuff(&gzout);
          gzout.Close();
          size = output.ByteCount();
        }
        {
          ArrayInputStream input(buffer, size, kBlockSizes[j]);
          GzipInputStream gzin(
              &input, GzipInputStream::GZIP, gzip_buffer_size);
          ReadStuff(&gzin);
        }
      }
    }
  }
  delete [] buffer;
}

TEST_F(IoTest, GzipIoWithFlush) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  // We start with i = 4 as we want a block size > 6. With block size <= 6
  // Flush() fills up the entire 2K buffer with flush markers and the test
  // fails. See documentation for Flush() for more detail.
  for (int i = 4; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      for (int z = 0; z < kBlockSizeCount; z++) {
        int gzip_buffer_size = kBlockSizes[z];
        int size;
        {
          ArrayOutputStream output(buffer, kBufferSize, kBlockSizes[i]);
          GzipOutputStream::Options options;
          options.format = GzipOutputStream::GZIP;
          if (gzip_buffer_size != -1) {
            options.buffer_size = gzip_buffer_size;
          }
          GzipOutputStream gzout(&output, options);
          WriteStuff(&gzout);
          EXPECT_TRUE(gzout.Flush());
          gzout.Close();
          size = output.ByteCount();
        }
        {
          ArrayInputStream input(buffer, size, kBlockSizes[j]);
          GzipInputStream gzin(
              &input, GzipInputStream::GZIP, gzip_buffer_size);
          ReadStuff(&gzin);
        }
      }
    }
  }
  delete [] buffer;
}

TEST_F(IoTest, GzipIoContiguousFlushes) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];

  int block_size = kBlockSizes[4];
  int gzip_buffer_size = block_size;
  int size;

  ArrayOutputStream output(buffer, kBufferSize, block_size);
  GzipOutputStream::Options options;
  options.format = GzipOutputStream::GZIP;
  if (gzip_buffer_size != -1) {
    options.buffer_size = gzip_buffer_size;
  }
  GzipOutputStream gzout(&output, options);
  WriteStuff(&gzout);
  EXPECT_TRUE(gzout.Flush());
  EXPECT_TRUE(gzout.Flush());
  gzout.Close();
  size = output.ByteCount();

  ArrayInputStream input(buffer, size, block_size);
  GzipInputStream gzin(
      &input, GzipInputStream::GZIP, gzip_buffer_size);
  ReadStuff(&gzin);

  delete [] buffer;
}

TEST_F(IoTest, GzipIoReadAfterFlush) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];

  int block_size = kBlockSizes[4];
  int gzip_buffer_size = block_size;
  int size;
  ArrayOutputStream output(buffer, kBufferSize, block_size);
  GzipOutputStream::Options options;
  options.format = GzipOutputStream::GZIP;
  if (gzip_buffer_size != -1) {
    options.buffer_size = gzip_buffer_size;
  }

  GzipOutputStream gzout(&output, options);
  WriteStuff(&gzout);
  EXPECT_TRUE(gzout.Flush());
  size = output.ByteCount();

  ArrayInputStream input(buffer, size, block_size);
  GzipInputStream gzin(
      &input, GzipInputStream::GZIP, gzip_buffer_size);
  ReadStuff(&gzin);

  gzout.Close();

  delete [] buffer;
}

TEST_F(IoTest, ZlibIo) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      for (int z = 0; z < kBlockSizeCount; z++) {
        int gzip_buffer_size = kBlockSizes[z];
        int size;
        {
          ArrayOutputStream output(buffer, kBufferSize, kBlockSizes[i]);
          GzipOutputStream::Options options;
          options.format = GzipOutputStream::ZLIB;
          if (gzip_buffer_size != -1) {
            options.buffer_size = gzip_buffer_size;
          }
          GzipOutputStream gzout(&output, options);
          WriteStuff(&gzout);
          gzout.Close();
          size = output.ByteCount();
        }
        {
          ArrayInputStream input(buffer, size, kBlockSizes[j]);
          GzipInputStream gzin(
              &input, GzipInputStream::ZLIB, gzip_buffer_size);
          ReadStuff(&gzin);
        }
      }
    }
  }
  delete [] buffer;
}

TEST_F(IoTest, ZlibIoInputAutodetect) {
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  int size;
  {
    ArrayOutputStream output(buffer, kBufferSize);
    GzipOutputStream::Options options;
    options.format = GzipOutputStream::ZLIB;
    GzipOutputStream gzout(&output, options);
    WriteStuff(&gzout);
    gzout.Close();
    size = output.ByteCount();
  }
  {
    ArrayInputStream input(buffer, size);
    GzipInputStream gzin(&input, GzipInputStream::AUTO);
    ReadStuff(&gzin);
  }
  {
    ArrayOutputStream output(buffer, kBufferSize);
    GzipOutputStream::Options options;
    options.format = GzipOutputStream::GZIP;
    GzipOutputStream gzout(&output, options);
    WriteStuff(&gzout);
    gzout.Close();
    size = output.ByteCount();
  }
  {
    ArrayInputStream input(buffer, size);
    GzipInputStream gzin(&input, GzipInputStream::AUTO);
    ReadStuff(&gzin);
  }
  delete [] buffer;
}

string IoTest::Compress(const string& data,
                        const GzipOutputStream::Options& options) {
  string result;
  {
    StringOutputStream output(&result);
    GzipOutputStream gzout(&output, options);
    WriteToOutput(&gzout, data.data(), data.size());
  }
  return result;
}

string IoTest::Uncompress(const string& data) {
  string result;
  {
    ArrayInputStream input(data.data(), data.size());
    GzipInputStream gzin(&input);
    const void* buffer;
    int size;
    while (gzin.Next(&buffer, &size)) {
      result.append(reinterpret_cast<const char*>(buffer), size);
    }
  }
  return result;
}

TEST_F(IoTest, CompressionOptions) {
  // Some ad-hoc testing of compression options.

  string golden;
  File::ReadFileToStringOrDie(
    TestSourceDir() + "/google/protobuf/testdata/golden_message",
    &golden);

  GzipOutputStream::Options options;
  string gzip_compressed = Compress(golden, options);

  options.compression_level = 0;
  string not_compressed = Compress(golden, options);

  // Try zlib compression for fun.
  options = GzipOutputStream::Options();
  options.format = GzipOutputStream::ZLIB;
  string zlib_compressed = Compress(golden, options);

  // Uncompressed should be bigger than the original since it should have some
  // sort of header.
  EXPECT_GT(not_compressed.size(), golden.size());

  // Higher compression levels should result in smaller sizes.
  EXPECT_LT(zlib_compressed.size(), not_compressed.size());

  // ZLIB format should differ from GZIP format.
  EXPECT_TRUE(zlib_compressed != gzip_compressed);

  // Everything should decompress correctly.
  EXPECT_TRUE(Uncompress(not_compressed) == golden);
  EXPECT_TRUE(Uncompress(gzip_compressed) == golden);
  EXPECT_TRUE(Uncompress(zlib_compressed) == golden);
}

TEST_F(IoTest, TwoSessionWriteGzip) {
  // Test that two concatenated gzip streams can be read correctly

  static const char* strA = "0123456789";
  static const char* strB = "QuickBrownFox";
  const int kBufferSize = 2*1024;
  uint8* buffer = new uint8[kBufferSize];
  char* temp_buffer = new char[40];

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      ArrayOutputStream* output =
          new ArrayOutputStream(buffer, kBufferSize, kBlockSizes[i]);
      GzipOutputStream* gzout = new GzipOutputStream(output);
      CodedOutputStream* coded_output = new CodedOutputStream(gzout);
      int32 outlen = strlen(strA) + 1;
      coded_output->WriteVarint32(outlen);
      coded_output->WriteRaw(strA, outlen);
      delete coded_output;  // flush
      delete gzout;  // flush
      int64 pos = output->ByteCount();
      delete output;
      output = new ArrayOutputStream(
          buffer + pos, kBufferSize - pos, kBlockSizes[i]);
      gzout = new GzipOutputStream(output);
      coded_output = new CodedOutputStream(gzout);
      outlen = strlen(strB) + 1;
      coded_output->WriteVarint32(outlen);
      coded_output->WriteRaw(strB, outlen);
      delete coded_output;  // flush
      delete gzout;  // flush
      int64 size = pos + output->ByteCount();
      delete output;

      ArrayInputStream* input =
          new ArrayInputStream(buffer, size, kBlockSizes[j]);
      GzipInputStream* gzin = new GzipInputStream(input);
      CodedInputStream* coded_input = new CodedInputStream(gzin);
      uint32 insize;
      EXPECT_TRUE(coded_input->ReadVarint32(&insize));
      EXPECT_EQ(strlen(strA) + 1, insize);
      EXPECT_TRUE(coded_input->ReadRaw(temp_buffer, insize));
      EXPECT_EQ(0, memcmp(temp_buffer, strA, insize))
          << "strA=" << strA << " in=" << temp_buffer;

      EXPECT_TRUE(coded_input->ReadVarint32(&insize));
      EXPECT_EQ(strlen(strB) + 1, insize);
      EXPECT_TRUE(coded_input->ReadRaw(temp_buffer, insize));
      EXPECT_EQ(0, memcmp(temp_buffer, strB, insize))
          << " out_block_size=" << kBlockSizes[i]
          << " in_block_size=" << kBlockSizes[j]
          << " pos=" << pos
          << " size=" << size
          << " strB=" << strB << " in=" << temp_buffer;

      delete coded_input;
      delete gzin;
      delete input;
    }
  }

  delete [] temp_buffer;
  delete [] buffer;
}
#endif

// There is no string input, only string output.  Also, it doesn't support
// explicit block sizes.  So, we'll only run one test and we'll use
// ArrayInput to read back the results.
TEST_F(IoTest, StringIo) {
  string str;
  {
    StringOutputStream output(&str);
    WriteStuff(&output);
  }
  {
    ArrayInputStream input(str.data(), str.size());
    ReadStuff(&input);
  }
}


// To test files, we create a temporary file, write, read, truncate, repeat.
TEST_F(IoTest, FileIo) {
  string filename = TestTempDir() + "/zero_copy_stream_test_file";

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      // Make a temporary file.
      int file =
        open(filename.c_str(), O_RDWR | O_CREAT | O_TRUNC | O_BINARY, 0777);
      ASSERT_GE(file, 0);

      {
        FileOutputStream output(file, kBlockSizes[i]);
        WriteStuff(&output);
        EXPECT_EQ(0, output.GetErrno());
      }

      // Rewind.
      ASSERT_NE(lseek(file, 0, SEEK_SET), (off_t)-1);

      {
        FileInputStream input(file, kBlockSizes[j]);
        ReadStuff(&input);
        EXPECT_EQ(0, input.GetErrno());
      }

      close(file);
    }
  }
}

#if HAVE_ZLIB
TEST_F(IoTest, GzipFileIo) {
  string filename = TestTempDir() + "/zero_copy_stream_test_file";

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      // Make a temporary file.
      int file =
        open(filename.c_str(), O_RDWR | O_CREAT | O_TRUNC | O_BINARY, 0777);
      ASSERT_GE(file, 0);
      {
        FileOutputStream output(file, kBlockSizes[i]);
        GzipOutputStream gzout(&output);
        WriteStuffLarge(&gzout);
        gzout.Close();
        output.Flush();
        EXPECT_EQ(0, output.GetErrno());
      }

      // Rewind.
      ASSERT_NE(lseek(file, 0, SEEK_SET), (off_t)-1);

      {
        FileInputStream input(file, kBlockSizes[j]);
        GzipInputStream gzin(&input);
        ReadStuffLarge(&gzin);
        EXPECT_EQ(0, input.GetErrno());
      }

      close(file);
    }
  }
}
#endif

// MSVC raises various debugging exceptions if we try to use a file
// descriptor of -1, defeating our tests below.  This class will disable
// these debug assertions while in scope.
class MsvcDebugDisabler {
 public:
#if defined(_MSC_VER) && _MSC_VER >= 1400
  MsvcDebugDisabler() {
    old_handler_ = _set_invalid_parameter_handler(MyHandler);
    old_mode_ = _CrtSetReportMode(_CRT_ASSERT, 0);
  }
  ~MsvcDebugDisabler() {
    old_handler_ = _set_invalid_parameter_handler(old_handler_);
    old_mode_ = _CrtSetReportMode(_CRT_ASSERT, old_mode_);
  }

  static void MyHandler(const wchar_t *expr,
                        const wchar_t *func,
                        const wchar_t *file,
                        unsigned int line,
                        uintptr_t pReserved) {
    // do nothing
  }

  _invalid_parameter_handler old_handler_;
  int old_mode_;
#else
  // Dummy constructor and destructor to ensure that GCC doesn't complain
  // that debug_disabler is an unused variable.
  MsvcDebugDisabler() {}
  ~MsvcDebugDisabler() {}
#endif
};

// Test that FileInputStreams report errors correctly.
TEST_F(IoTest, FileReadError) {
  MsvcDebugDisabler debug_disabler;

  // -1 = invalid file descriptor.
  FileInputStream input(-1);

  const void* buffer;
  int size;
  EXPECT_FALSE(input.Next(&buffer, &size));
  EXPECT_EQ(EBADF, input.GetErrno());
}

// Test that FileOutputStreams report errors correctly.
TEST_F(IoTest, FileWriteError) {
  MsvcDebugDisabler debug_disabler;

  // -1 = invalid file descriptor.
  FileOutputStream input(-1);

  void* buffer;
  int size;

  // The first call to Next() succeeds because it doesn't have anything to
  // write yet.
  EXPECT_TRUE(input.Next(&buffer, &size));

  // Second call fails.
  EXPECT_FALSE(input.Next(&buffer, &size));

  EXPECT_EQ(EBADF, input.GetErrno());
}

// Pipes are not seekable, so File{Input,Output}Stream ends up doing some
// different things to handle them.  We'll test by writing to a pipe and
// reading back from it.
TEST_F(IoTest, PipeIo) {
  int files[2];

  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      // Need to create a new pipe each time because ReadStuff() expects
      // to see EOF at the end.
      ASSERT_EQ(pipe(files), 0);

      {
        FileOutputStream output(files[1], kBlockSizes[i]);
        WriteStuff(&output);
        EXPECT_EQ(0, output.GetErrno());
      }
      close(files[1]);  // Send EOF.

      {
        FileInputStream input(files[0], kBlockSizes[j]);
        ReadStuff(&input);
        EXPECT_EQ(0, input.GetErrno());
      }
      close(files[0]);
    }
  }
}

// Test using C++ iostreams.
TEST_F(IoTest, IostreamIo) {
  for (int i = 0; i < kBlockSizeCount; i++) {
    for (int j = 0; j < kBlockSizeCount; j++) {
      {
        stringstream stream;

        {
          OstreamOutputStream output(&stream, kBlockSizes[i]);
          WriteStuff(&output);
          EXPECT_FALSE(stream.fail());
        }

        {
          IstreamInputStream input(&stream, kBlockSizes[j]);
          ReadStuff(&input);
          EXPECT_TRUE(stream.eof());
        }
      }

      {
        stringstream stream;

        {
          OstreamOutputStream output(&stream, kBlockSizes[i]);
          WriteStuffLarge(&output);
          EXPECT_FALSE(stream.fail());
        }

        {
          IstreamInputStream input(&stream, kBlockSizes[j]);
          ReadStuffLarge(&input);
          EXPECT_TRUE(stream.eof());
        }
      }
    }
  }
}

// To test ConcatenatingInputStream, we create several ArrayInputStreams
// covering a buffer and then concatenate them.
TEST_F(IoTest, ConcatenatingInputStream) {
  const int kBufferSize = 256;
  uint8 buffer[kBufferSize];

  // Fill the buffer.
  ArrayOutputStream output(buffer, kBufferSize);
  WriteStuff(&output);

  // Now split it up into multiple streams of varying sizes.
  ASSERT_EQ(68, output.ByteCount());  // Test depends on this.
  ArrayInputStream input1(buffer     , 12);
  ArrayInputStream input2(buffer + 12,  7);
  ArrayInputStream input3(buffer + 19,  6);
  ArrayInputStream input4(buffer + 25, 15);
  ArrayInputStream input5(buffer + 40,  0);
  // Note:  We want to make sure we have a stream boundary somewhere between
  // bytes 42 and 62, which is the range that it Skip()ed by ReadStuff().  This
  // tests that a bug that existed in the original code for Skip() is fixed.
  ArrayInputStream input6(buffer + 40, 10);
  ArrayInputStream input7(buffer + 50, 18);  // Total = 68 bytes.

  ZeroCopyInputStream* streams[] =
    {&input1, &input2, &input3, &input4, &input5, &input6, &input7};

  // Create the concatenating stream and read.
  ConcatenatingInputStream input(streams, GOOGLE_ARRAYSIZE(streams));
  ReadStuff(&input);
}

// To test LimitingInputStream, we write our golden text to a buffer, then
// create an ArrayInputStream that contains the whole buffer (not just the
// bytes written), then use a LimitingInputStream to limit it just to the
// bytes written.
TEST_F(IoTest, LimitingInputStream) {
  const int kBufferSize = 256;
  uint8 buffer[kBufferSize];

  // Fill the buffer.
  ArrayOutputStream output(buffer, kBufferSize);
  WriteStuff(&output);

  // Set up input.
  ArrayInputStream array_input(buffer, kBufferSize);
  LimitingInputStream input(&array_input, output.ByteCount());

  ReadStuff(&input);
}

// Check that a zero-size array doesn't confuse the code.
TEST(ZeroSizeArray, Input) {
  ArrayInputStream input(NULL, 0);
  const void* data;
  int size;
  EXPECT_FALSE(input.Next(&data, &size));
}

TEST(ZeroSizeArray, Output) {
  ArrayOutputStream output(NULL, 0);
  void* data;
  int size;
  EXPECT_FALSE(output.Next(&data, &size));
}

}  // namespace
}  // namespace io
}  // namespace protobuf
}  // namespace google

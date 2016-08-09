// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/zip_reader.h"

#include <set>
#include <string>

#include "base/bind.h"
#include "base/files/file.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/logging.h"
#include "base/md5.h"
#include "base/path_service.h"
#include "base/run_loop.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "base/time/time.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"
#include "third_party/zlib/google/zip_internal.h"

using ::testing::Return;
using ::testing::_;

namespace {

const static std::string kQuuxExpectedMD5 = "d1ae4ac8a17a0e09317113ab284b57a6";

class FileWrapper {
 public:
  typedef enum {
    READ_ONLY,
    READ_WRITE
  } AccessMode;

  FileWrapper(const base::FilePath& path, AccessMode mode) {
    int flags = base::File::FLAG_READ;
    if (mode == READ_ONLY)
      flags |= base::File::FLAG_OPEN;
    else
      flags |= base::File::FLAG_WRITE | base::File::FLAG_CREATE_ALWAYS;

    file_.Initialize(path, flags);
  }

  ~FileWrapper() {}

  base::PlatformFile platform_file() { return file_.GetPlatformFile(); }

  base::File* file() { return &file_; }

 private:
  base::File file_;
};

// A mock that provides methods that can be used as callbacks in asynchronous
// unzip functions.  Tracks the number of calls and number of bytes reported.
// Assumes that progress callbacks will be executed in-order.
class MockUnzipListener : public base::SupportsWeakPtr<MockUnzipListener> {
 public:
  MockUnzipListener()
      : success_calls_(0),
        failure_calls_(0),
        progress_calls_(0),
        current_progress_(0) {
  }

  // Success callback for async functions.
  void OnUnzipSuccess() {
    success_calls_++;
  }

  // Failure callback for async functions.
  void OnUnzipFailure() {
    failure_calls_++;
  }

  // Progress callback for async functions.
  void OnUnzipProgress(int64 progress) {
    DCHECK(progress > current_progress_);
    progress_calls_++;
    current_progress_ = progress;
  }

  int success_calls() { return success_calls_; }
  int failure_calls() { return failure_calls_; }
  int progress_calls() { return progress_calls_; }
  int current_progress() { return current_progress_; }

 private:
  int success_calls_;
  int failure_calls_;
  int progress_calls_;

  int64 current_progress_;
};

class MockWriterDelegate : public zip::WriterDelegate {
 public:
  MOCK_METHOD0(PrepareOutput, bool());
  MOCK_METHOD2(WriteBytes, bool(const char*, int));
};

}   // namespace

namespace zip {

// Make the test a PlatformTest to setup autorelease pools properly on Mac.
class ZipReaderTest : public PlatformTest {
 protected:
  virtual void SetUp() {
    PlatformTest::SetUp();

    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
    test_dir_ = temp_dir_.path();

    ASSERT_TRUE(GetTestDataDirectory(&test_data_dir_));

    test_zip_file_ = test_data_dir_.AppendASCII("test.zip");
    evil_zip_file_ = test_data_dir_.AppendASCII("evil.zip");
    evil_via_invalid_utf8_zip_file_ = test_data_dir_.AppendASCII(
        "evil_via_invalid_utf8.zip");
    evil_via_absolute_file_name_zip_file_ = test_data_dir_.AppendASCII(
        "evil_via_absolute_file_name.zip");

    test_zip_contents_.insert(base::FilePath(FILE_PATH_LITERAL("foo/")));
    test_zip_contents_.insert(base::FilePath(FILE_PATH_LITERAL("foo/bar/")));
    test_zip_contents_.insert(
        base::FilePath(FILE_PATH_LITERAL("foo/bar/baz.txt")));
    test_zip_contents_.insert(
        base::FilePath(FILE_PATH_LITERAL("foo/bar/quux.txt")));
    test_zip_contents_.insert(
        base::FilePath(FILE_PATH_LITERAL("foo/bar.txt")));
    test_zip_contents_.insert(base::FilePath(FILE_PATH_LITERAL("foo.txt")));
    test_zip_contents_.insert(
        base::FilePath(FILE_PATH_LITERAL("foo/bar/.hidden")));
  }

  virtual void TearDown() {
    PlatformTest::TearDown();
  }

  bool GetTestDataDirectory(base::FilePath* path) {
    bool success = PathService::Get(base::DIR_SOURCE_ROOT, path);
    EXPECT_TRUE(success);
    if (!success)
      return false;
    *path = path->AppendASCII("third_party");
    *path = path->AppendASCII("zlib");
    *path = path->AppendASCII("google");
    *path = path->AppendASCII("test");
    *path = path->AppendASCII("data");
    return true;
  }

  bool CompareFileAndMD5(const base::FilePath& path,
                         const std::string expected_md5) {
    // Read the output file and compute the MD5.
    std::string output;
    if (!base::ReadFileToString(path, &output))
      return false;
    const std::string md5 = base::MD5String(output);
    return expected_md5 == md5;
  }

  // The path to temporary directory used to contain the test operations.
  base::FilePath test_dir_;
  // The path to the test data directory where test.zip etc. are located.
  base::FilePath test_data_dir_;
  // The path to test.zip in the test data directory.
  base::FilePath test_zip_file_;
  // The path to evil.zip in the test data directory.
  base::FilePath evil_zip_file_;
  // The path to evil_via_invalid_utf8.zip in the test data directory.
  base::FilePath evil_via_invalid_utf8_zip_file_;
  // The path to evil_via_absolute_file_name.zip in the test data directory.
  base::FilePath evil_via_absolute_file_name_zip_file_;
  std::set<base::FilePath> test_zip_contents_;

  base::ScopedTempDir temp_dir_;

  base::MessageLoop message_loop_;
};

TEST_F(ZipReaderTest, Open_ValidZipFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
}

TEST_F(ZipReaderTest, Open_ValidZipPlatformFile) {
  ZipReader reader;
  FileWrapper zip_fd_wrapper(test_zip_file_, FileWrapper::READ_ONLY);
  ASSERT_TRUE(reader.OpenFromPlatformFile(zip_fd_wrapper.platform_file()));
}

TEST_F(ZipReaderTest, Open_NonExistentFile) {
  ZipReader reader;
  ASSERT_FALSE(reader.Open(test_data_dir_.AppendASCII("nonexistent.zip")));
}

TEST_F(ZipReaderTest, Open_ExistentButNonZipFile) {
  ZipReader reader;
  ASSERT_FALSE(reader.Open(test_data_dir_.AppendASCII("create_test_zip.sh")));
}

// Iterate through the contents in the test zip file, and compare that the
// contents collected from the zip reader matches the expected contents.
TEST_F(ZipReaderTest, Iteration) {
  std::set<base::FilePath> actual_contents;
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  while (reader.HasMore()) {
    ASSERT_TRUE(reader.OpenCurrentEntryInZip());
    actual_contents.insert(reader.current_entry_info()->file_path());
    ASSERT_TRUE(reader.AdvanceToNextEntry());
  }
  EXPECT_FALSE(reader.AdvanceToNextEntry());  // Shouldn't go further.
  EXPECT_EQ(test_zip_contents_.size(),
            static_cast<size_t>(reader.num_entries()));
  EXPECT_EQ(test_zip_contents_.size(), actual_contents.size());
  EXPECT_EQ(test_zip_contents_, actual_contents);
}

// Open the test zip file from a file descriptor, iterate through its contents,
// and compare that they match the expected contents.
TEST_F(ZipReaderTest, PlatformFileIteration) {
  std::set<base::FilePath> actual_contents;
  ZipReader reader;
  FileWrapper zip_fd_wrapper(test_zip_file_, FileWrapper::READ_ONLY);
  ASSERT_TRUE(reader.OpenFromPlatformFile(zip_fd_wrapper.platform_file()));
  while (reader.HasMore()) {
    ASSERT_TRUE(reader.OpenCurrentEntryInZip());
    actual_contents.insert(reader.current_entry_info()->file_path());
    ASSERT_TRUE(reader.AdvanceToNextEntry());
  }
  EXPECT_FALSE(reader.AdvanceToNextEntry());  // Shouldn't go further.
  EXPECT_EQ(test_zip_contents_.size(),
            static_cast<size_t>(reader.num_entries()));
  EXPECT_EQ(test_zip_contents_.size(), actual_contents.size());
  EXPECT_EQ(test_zip_contents_, actual_contents);
}

TEST_F(ZipReaderTest, LocateAndOpenEntry_ValidFile) {
  std::set<base::FilePath> actual_contents;
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  EXPECT_EQ(target_path, reader.current_entry_info()->file_path());
}

TEST_F(ZipReaderTest, LocateAndOpenEntry_NonExistentFile) {
  std::set<base::FilePath> actual_contents;
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("nonexistent.txt"));
  ASSERT_FALSE(reader.LocateAndOpenEntry(target_path));
  EXPECT_EQ(NULL, reader.current_entry_info());
}

TEST_F(ZipReaderTest, ExtractCurrentEntryToFilePath_RegularFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryToFilePath(
      test_dir_.AppendASCII("quux.txt")));
  // Read the output file ans compute the MD5.
  std::string output;
  ASSERT_TRUE(base::ReadFileToString(test_dir_.AppendASCII("quux.txt"),
                                     &output));
  const std::string md5 = base::MD5String(output);
  EXPECT_EQ(kQuuxExpectedMD5, md5);
  // quux.txt should be larger than kZipBufSize so that we can exercise
  // the loop in ExtractCurrentEntry().
  EXPECT_LT(static_cast<size_t>(internal::kZipBufSize), output.size());
}

TEST_F(ZipReaderTest, PlatformFileExtractCurrentEntryToFilePath_RegularFile) {
  ZipReader reader;
  FileWrapper zip_fd_wrapper(test_zip_file_, FileWrapper::READ_ONLY);
  ASSERT_TRUE(reader.OpenFromPlatformFile(zip_fd_wrapper.platform_file()));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryToFilePath(
      test_dir_.AppendASCII("quux.txt")));
  // Read the output file and compute the MD5.
  std::string output;
  ASSERT_TRUE(base::ReadFileToString(test_dir_.AppendASCII("quux.txt"),
                                     &output));
  const std::string md5 = base::MD5String(output);
  EXPECT_EQ(kQuuxExpectedMD5, md5);
  // quux.txt should be larger than kZipBufSize so that we can exercise
  // the loop in ExtractCurrentEntry().
  EXPECT_LT(static_cast<size_t>(internal::kZipBufSize), output.size());
}

TEST_F(ZipReaderTest, PlatformFileExtractCurrentEntryToFile_RegularFile) {
  ZipReader reader;
  FileWrapper zip_fd_wrapper(test_zip_file_, FileWrapper::READ_ONLY);
  ASSERT_TRUE(reader.OpenFromPlatformFile(zip_fd_wrapper.platform_file()));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  base::FilePath out_path = test_dir_.AppendASCII("quux.txt");
  FileWrapper out_fd_w(out_path, FileWrapper::READ_WRITE);
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryToFile(out_fd_w.file()));
  // Read the output file and compute the MD5.
  std::string output;
  ASSERT_TRUE(base::ReadFileToString(out_path, &output));
  const std::string md5 = base::MD5String(output);
  EXPECT_EQ(kQuuxExpectedMD5, md5);
  // quux.txt should be larger than kZipBufSize so that we can exercise
  // the loop in ExtractCurrentEntry().
  EXPECT_LT(static_cast<size_t>(internal::kZipBufSize), output.size());
}

TEST_F(ZipReaderTest, ExtractCurrentEntryToFilePath_Directory) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryToFilePath(
      test_dir_.AppendASCII("foo")));
  // The directory should be created.
  ASSERT_TRUE(base::DirectoryExists(test_dir_.AppendASCII("foo")));
}

TEST_F(ZipReaderTest, ExtractCurrentEntryIntoDirectory_RegularFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryIntoDirectory(test_dir_));
  // Sub directories should be created.
  ASSERT_TRUE(base::DirectoryExists(test_dir_.AppendASCII("foo/bar")));
  // And the file should be created.
  std::string output;
  ASSERT_TRUE(base::ReadFileToString(
      test_dir_.AppendASCII("foo/bar/quux.txt"), &output));
  const std::string md5 = base::MD5String(output);
  EXPECT_EQ(kQuuxExpectedMD5, md5);
}

TEST_F(ZipReaderTest, current_entry_info_RegularFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ZipReader::EntryInfo* current_entry_info = reader.current_entry_info();

  EXPECT_EQ(target_path, current_entry_info->file_path());
  EXPECT_EQ(13527, current_entry_info->original_size());

  // The expected time stamp: 2009-05-29 06:22:20
  base::Time::Exploded exploded = {};  // Zero-clear.
  current_entry_info->last_modified().LocalExplode(&exploded);
  EXPECT_EQ(2009, exploded.year);
  EXPECT_EQ(5, exploded.month);
  EXPECT_EQ(29, exploded.day_of_month);
  EXPECT_EQ(6, exploded.hour);
  EXPECT_EQ(22, exploded.minute);
  EXPECT_EQ(20, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  EXPECT_FALSE(current_entry_info->is_unsafe());
  EXPECT_FALSE(current_entry_info->is_directory());
}

TEST_F(ZipReaderTest, current_entry_info_DotDotFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(evil_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL(
      "../levilevilevilevilevilevilevilevilevilevilevilevil"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ZipReader::EntryInfo* current_entry_info = reader.current_entry_info();
  EXPECT_EQ(target_path, current_entry_info->file_path());

  // This file is unsafe because of ".." in the file name.
  EXPECT_TRUE(current_entry_info->is_unsafe());
  EXPECT_FALSE(current_entry_info->is_directory());
}

TEST_F(ZipReaderTest, current_entry_info_InvalidUTF8File) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(evil_via_invalid_utf8_zip_file_));
  // The evil file is the 2nd file in the zip file.
  // We cannot locate by the file name ".\x80.\\evil.txt",
  // as FilePath may internally convert the string.
  ASSERT_TRUE(reader.AdvanceToNextEntry());
  ASSERT_TRUE(reader.OpenCurrentEntryInZip());
  ZipReader::EntryInfo* current_entry_info = reader.current_entry_info();

  // This file is unsafe because of invalid UTF-8 in the file name.
  EXPECT_TRUE(current_entry_info->is_unsafe());
  EXPECT_FALSE(current_entry_info->is_directory());
}

TEST_F(ZipReaderTest, current_entry_info_AbsoluteFile) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(evil_via_absolute_file_name_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("/evil.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ZipReader::EntryInfo* current_entry_info = reader.current_entry_info();
  EXPECT_EQ(target_path, current_entry_info->file_path());

  // This file is unsafe because of the absolute file name.
  EXPECT_TRUE(current_entry_info->is_unsafe());
  EXPECT_FALSE(current_entry_info->is_directory());
}

TEST_F(ZipReaderTest, current_entry_info_Directory) {
  ZipReader reader;
  ASSERT_TRUE(reader.Open(test_zip_file_));
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ZipReader::EntryInfo* current_entry_info = reader.current_entry_info();

  EXPECT_EQ(base::FilePath(FILE_PATH_LITERAL("foo/bar/")),
            current_entry_info->file_path());
  // The directory size should be zero.
  EXPECT_EQ(0, current_entry_info->original_size());

  // The expected time stamp: 2009-05-31 15:49:52
  base::Time::Exploded exploded = {};  // Zero-clear.
  current_entry_info->last_modified().LocalExplode(&exploded);
  EXPECT_EQ(2009, exploded.year);
  EXPECT_EQ(5, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(15, exploded.hour);
  EXPECT_EQ(49, exploded.minute);
  EXPECT_EQ(52, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  EXPECT_FALSE(current_entry_info->is_unsafe());
  EXPECT_TRUE(current_entry_info->is_directory());
}

// Verifies that the ZipReader class can extract a file from a zip archive
// stored in memory. This test opens a zip archive in a std::string object,
// extracts its content, and verifies the content is the same as the expected
// text.
TEST_F(ZipReaderTest, OpenFromString) {
  // A zip archive consisting of one file "test.txt", which is a 16-byte text
  // file that contains "This is a test.\n".
  const char kTestData[] =
      "\x50\x4b\x03\x04\x0a\x00\x00\x00\x00\x00\xa4\x66\x24\x41\x13\xe8"
      "\xcb\x27\x10\x00\x00\x00\x10\x00\x00\x00\x08\x00\x1c\x00\x74\x65"
      "\x73\x74\x2e\x74\x78\x74\x55\x54\x09\x00\x03\x34\x89\x45\x50\x34"
      "\x89\x45\x50\x75\x78\x0b\x00\x01\x04\x8e\xf0\x00\x00\x04\x88\x13"
      "\x00\x00\x54\x68\x69\x73\x20\x69\x73\x20\x61\x20\x74\x65\x73\x74"
      "\x2e\x0a\x50\x4b\x01\x02\x1e\x03\x0a\x00\x00\x00\x00\x00\xa4\x66"
      "\x24\x41\x13\xe8\xcb\x27\x10\x00\x00\x00\x10\x00\x00\x00\x08\x00"
      "\x18\x00\x00\x00\x00\x00\x01\x00\x00\x00\xa4\x81\x00\x00\x00\x00"
      "\x74\x65\x73\x74\x2e\x74\x78\x74\x55\x54\x05\x00\x03\x34\x89\x45"
      "\x50\x75\x78\x0b\x00\x01\x04\x8e\xf0\x00\x00\x04\x88\x13\x00\x00"
      "\x50\x4b\x05\x06\x00\x00\x00\x00\x01\x00\x01\x00\x4e\x00\x00\x00"
      "\x52\x00\x00\x00\x00\x00";
  std::string data(kTestData, arraysize(kTestData));
  ZipReader reader;
  ASSERT_TRUE(reader.OpenFromString(data));
  base::FilePath target_path(FILE_PATH_LITERAL("test.txt"));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntryToFilePath(
      test_dir_.AppendASCII("test.txt")));

  std::string actual;
  ASSERT_TRUE(base::ReadFileToString(
      test_dir_.AppendASCII("test.txt"), &actual));
  EXPECT_EQ(std::string("This is a test.\n"), actual);
}

// Verifies that the asynchronous extraction to a file works.
TEST_F(ZipReaderTest, ExtractToFileAsync_RegularFile) {
  MockUnzipListener listener;

  ZipReader reader;
  base::FilePath target_file = test_dir_.AppendASCII("quux.txt");
  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ASSERT_TRUE(reader.Open(test_zip_file_));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  reader.ExtractCurrentEntryToFilePathAsync(
      target_file,
      base::Bind(&MockUnzipListener::OnUnzipSuccess,
                 listener.AsWeakPtr()),
      base::Bind(&MockUnzipListener::OnUnzipFailure,
                 listener.AsWeakPtr()),
      base::Bind(&MockUnzipListener::OnUnzipProgress,
                 listener.AsWeakPtr()));

  EXPECT_EQ(0, listener.success_calls());
  EXPECT_EQ(0, listener.failure_calls());
  EXPECT_EQ(0, listener.progress_calls());

  base::RunLoop().RunUntilIdle();

  EXPECT_EQ(1, listener.success_calls());
  EXPECT_EQ(0, listener.failure_calls());
  EXPECT_LE(1, listener.progress_calls());

  std::string output;
  ASSERT_TRUE(base::ReadFileToString(test_dir_.AppendASCII("quux.txt"),
                                     &output));
  const std::string md5 = base::MD5String(output);
  EXPECT_EQ(kQuuxExpectedMD5, md5);

  int64 file_size = 0;
  ASSERT_TRUE(base::GetFileSize(target_file, &file_size));

  EXPECT_EQ(file_size, listener.current_progress());
}

// Verifies that the asynchronous extraction to a file works.
TEST_F(ZipReaderTest, ExtractToFileAsync_Directory) {
  MockUnzipListener listener;

  ZipReader reader;
  base::FilePath target_file = test_dir_.AppendASCII("foo");
  base::FilePath target_path(FILE_PATH_LITERAL("foo/"));
  ASSERT_TRUE(reader.Open(test_zip_file_));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  reader.ExtractCurrentEntryToFilePathAsync(
      target_file,
      base::Bind(&MockUnzipListener::OnUnzipSuccess,
                 listener.AsWeakPtr()),
      base::Bind(&MockUnzipListener::OnUnzipFailure,
                 listener.AsWeakPtr()),
      base::Bind(&MockUnzipListener::OnUnzipProgress,
                 listener.AsWeakPtr()));

  EXPECT_EQ(0, listener.success_calls());
  EXPECT_EQ(0, listener.failure_calls());
  EXPECT_EQ(0, listener.progress_calls());

  base::RunLoop().RunUntilIdle();

  EXPECT_EQ(1, listener.success_calls());
  EXPECT_EQ(0, listener.failure_calls());
  EXPECT_GE(0, listener.progress_calls());

  ASSERT_TRUE(base::DirectoryExists(target_file));
}

TEST_F(ZipReaderTest, ExtractCurrentEntryToString) {
  // test_mismatch_size.zip contains files with names from 0.txt to 7.txt with
  // sizes from 0 to 7 bytes respectively, being the contents of each file a
  // substring of "0123456" starting at '0'.
  base::FilePath test_zip_file =
      test_data_dir_.AppendASCII("test_mismatch_size.zip");

  ZipReader reader;
  std::string contents;
  ASSERT_TRUE(reader.Open(test_zip_file));

  for (size_t i = 0; i < 8; i++) {
    SCOPED_TRACE(base::StringPrintf("Processing %d.txt", static_cast<int>(i)));

    base::FilePath file_name = base::FilePath::FromUTF8Unsafe(
        base::StringPrintf("%d.txt", static_cast<int>(i)));
    ASSERT_TRUE(reader.LocateAndOpenEntry(file_name));

    if (i > 1) {
      // Off by one byte read limit: must fail.
      EXPECT_FALSE(reader.ExtractCurrentEntryToString(i - 1, &contents));
    }

    if (i > 0) {
      // Exact byte read limit: must pass.
      EXPECT_TRUE(reader.ExtractCurrentEntryToString(i, &contents));
      EXPECT_EQ(i, contents.size());
      EXPECT_EQ(0, memcmp(contents.c_str(), "0123456", i));
    }

    // More than necessary byte read limit: must pass.
    EXPECT_TRUE(reader.ExtractCurrentEntryToString(16, &contents));
    EXPECT_EQ(i, contents.size());
    EXPECT_EQ(0, memcmp(contents.c_str(), "0123456", i));
  }
  reader.Close();
}

// This test exposes http://crbug.com/430959, at least on OS X
TEST_F(ZipReaderTest, DISABLED_LeakDetectionTest) {
  for (int i = 0; i < 100000; ++i) {
    FileWrapper zip_fd_wrapper(test_zip_file_, FileWrapper::READ_ONLY);
    ZipReader reader;
    ASSERT_TRUE(reader.OpenFromPlatformFile(zip_fd_wrapper.platform_file()));
  }
}

// Test that when WriterDelegate::PrepareMock returns false, no other methods on
// the delegate are called and the extraction fails.
TEST_F(ZipReaderTest, ExtractCurrentEntryPrepareFailure) {
  testing::StrictMock<MockWriterDelegate> mock_writer;

  EXPECT_CALL(mock_writer, PrepareOutput())
      .WillOnce(Return(false));

  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ZipReader reader;

  ASSERT_TRUE(reader.Open(test_zip_file_));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_FALSE(reader.ExtractCurrentEntry(&mock_writer));
}

// Test that when WriterDelegate::WriteBytes returns false, no other methods on
// the delegate are called and the extraction fails.
TEST_F(ZipReaderTest, ExtractCurrentEntryWriteBytesFailure) {
  testing::StrictMock<MockWriterDelegate> mock_writer;

  EXPECT_CALL(mock_writer, PrepareOutput())
      .WillOnce(Return(true));
  EXPECT_CALL(mock_writer, WriteBytes(_, _))
      .WillOnce(Return(false));

  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ZipReader reader;

  ASSERT_TRUE(reader.Open(test_zip_file_));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_FALSE(reader.ExtractCurrentEntry(&mock_writer));
}

// Test that extraction succeeds when the writer delegate reports all is well.
TEST_F(ZipReaderTest, ExtractCurrentEntrySuccess) {
  testing::StrictMock<MockWriterDelegate> mock_writer;

  EXPECT_CALL(mock_writer, PrepareOutput())
      .WillOnce(Return(true));
  EXPECT_CALL(mock_writer, WriteBytes(_, _))
      .WillRepeatedly(Return(true));

  base::FilePath target_path(FILE_PATH_LITERAL("foo/bar/quux.txt"));
  ZipReader reader;

  ASSERT_TRUE(reader.Open(test_zip_file_));
  ASSERT_TRUE(reader.LocateAndOpenEntry(target_path));
  ASSERT_TRUE(reader.ExtractCurrentEntry(&mock_writer));
}

class FileWriterDelegateTest : public ::testing::Test {
 protected:
  void SetUp() override {
    ASSERT_TRUE(base::CreateTemporaryFile(&temp_file_path_));
    file_.Initialize(temp_file_path_, (base::File::FLAG_CREATE_ALWAYS |
                                       base::File::FLAG_READ |
                                       base::File::FLAG_WRITE |
                                       base::File::FLAG_TEMPORARY |
                                       base::File::FLAG_DELETE_ON_CLOSE));
    ASSERT_TRUE(file_.IsValid());
  }

  // Writes data to the file, leaving the current position at the end of the
  // write.
  void PopulateFile() {
    static const char kSomeData[] = "this sure is some data.";
    static const size_t kSomeDataLen = sizeof(kSomeData) - 1;
    ASSERT_NE(-1LL, file_.Write(0LL, kSomeData, kSomeDataLen));
  }

  base::FilePath temp_file_path_;
  base::File file_;
};

TEST_F(FileWriterDelegateTest, WriteToStartAndTruncate) {
  // Write stuff and advance.
  PopulateFile();

  // This should rewind, write, then truncate.
  static const char kSomeData[] = "short";
  static const int kSomeDataLen = sizeof(kSomeData) - 1;
  {
    FileWriterDelegate writer(&file_);
    ASSERT_TRUE(writer.PrepareOutput());
    ASSERT_TRUE(writer.WriteBytes(kSomeData, kSomeDataLen));
  }
  ASSERT_EQ(kSomeDataLen, file_.GetLength());
  char buf[kSomeDataLen] = {};
  ASSERT_EQ(kSomeDataLen, file_.Read(0LL, buf, kSomeDataLen));
  ASSERT_EQ(std::string(kSomeData), std::string(buf, kSomeDataLen));
}

}  // namespace zip

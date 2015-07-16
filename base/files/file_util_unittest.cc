// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <tchar.h>
#include <winioctl.h>
#endif

#if defined(OS_POSIX)
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#endif

#include <algorithm>
#include <fstream>
#include <set>
#include <vector>

#include "base/base_paths.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/files/scoped_temp_dir.h"
#include "base/path_service.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/test/test_file_util.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

#if defined(OS_WIN)
#include "base/win/scoped_handle.h"
#include "base/win/windows_version.h"
#endif

#if defined(OS_ANDROID)
#include "base/android/content_uri_utils.h"
#endif

// This macro helps avoid wrapped lines in the test structs.
#define FPL(x) FILE_PATH_LITERAL(x)

namespace base {

namespace {

// To test that NormalizeFilePath() deals with NTFS reparse points correctly,
// we need functions to create and delete reparse points.
#if defined(OS_WIN)
typedef struct _REPARSE_DATA_BUFFER {
  ULONG  ReparseTag;
  USHORT  ReparseDataLength;
  USHORT  Reserved;
  union {
    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      ULONG Flags;
      WCHAR PathBuffer[1];
    } SymbolicLinkReparseBuffer;
    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      WCHAR PathBuffer[1];
    } MountPointReparseBuffer;
    struct {
      UCHAR DataBuffer[1];
    } GenericReparseBuffer;
  };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;

// Sets a reparse point. |source| will now point to |target|. Returns true if
// the call succeeds, false otherwise.
bool SetReparsePoint(HANDLE source, const FilePath& target_path) {
  std::wstring kPathPrefix = L"\\??\\";
  std::wstring target_str;
  // The juction will not work if the target path does not start with \??\ .
  if (kPathPrefix != target_path.value().substr(0, kPathPrefix.size()))
    target_str += kPathPrefix;
  target_str += target_path.value();
  const wchar_t* target = target_str.c_str();
  USHORT size_target = static_cast<USHORT>(wcslen(target)) * sizeof(target[0]);
  char buffer[2000] = {0};
  DWORD returned;

  REPARSE_DATA_BUFFER* data = reinterpret_cast<REPARSE_DATA_BUFFER*>(buffer);

  data->ReparseTag = 0xa0000003;
  memcpy(data->MountPointReparseBuffer.PathBuffer, target, size_target + 2);

  data->MountPointReparseBuffer.SubstituteNameLength = size_target;
  data->MountPointReparseBuffer.PrintNameOffset = size_target + 2;
  data->ReparseDataLength = size_target + 4 + 8;

  int data_size = data->ReparseDataLength + 8;

  if (!DeviceIoControl(source, FSCTL_SET_REPARSE_POINT, &buffer, data_size,
                       NULL, 0, &returned, NULL)) {
    return false;
  }
  return true;
}

// Delete the reparse point referenced by |source|. Returns true if the call
// succeeds, false otherwise.
bool DeleteReparsePoint(HANDLE source) {
  DWORD returned;
  REPARSE_DATA_BUFFER data = {0};
  data.ReparseTag = 0xa0000003;
  if (!DeviceIoControl(source, FSCTL_DELETE_REPARSE_POINT, &data, 8, NULL, 0,
                       &returned, NULL)) {
    return false;
  }
  return true;
}

// Manages a reparse point for a test.
class ReparsePoint {
 public:
  // Creates a reparse point from |source| (an empty directory) to |target|.
  ReparsePoint(const FilePath& source, const FilePath& target) {
    dir_.Set(
      ::CreateFile(source.value().c_str(),
                   FILE_ALL_ACCESS,
                   FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                   NULL,
                   OPEN_EXISTING,
                   FILE_FLAG_BACKUP_SEMANTICS,  // Needed to open a directory.
                   NULL));
    created_ = dir_.IsValid() && SetReparsePoint(dir_.Get(), target);
  }

  ~ReparsePoint() {
    if (created_)
      DeleteReparsePoint(dir_.Get());
  }

  bool IsValid() { return created_; }

 private:
  win::ScopedHandle dir_;
  bool created_;
  DISALLOW_COPY_AND_ASSIGN(ReparsePoint);
};

#endif

#if defined(OS_POSIX)
// Provide a simple way to change the permissions bits on |path| in tests.
// ASSERT failures will return, but not stop the test.  Caller should wrap
// calls to this function in ASSERT_NO_FATAL_FAILURE().
void ChangePosixFilePermissions(const FilePath& path,
                                int mode_bits_to_set,
                                int mode_bits_to_clear) {
  ASSERT_FALSE(mode_bits_to_set & mode_bits_to_clear)
      << "Can't set and clear the same bits.";

  int mode = 0;
  ASSERT_TRUE(GetPosixFilePermissions(path, &mode));
  mode |= mode_bits_to_set;
  mode &= ~mode_bits_to_clear;
  ASSERT_TRUE(SetPosixFilePermissions(path, mode));
}
#endif  // defined(OS_POSIX)

const wchar_t bogus_content[] = L"I'm cannon fodder.";

const int FILES_AND_DIRECTORIES =
    FileEnumerator::FILES | FileEnumerator::DIRECTORIES;

// file_util winds up using autoreleased objects on the Mac, so this needs
// to be a PlatformTest
class FileUtilTest : public PlatformTest {
 protected:
  void SetUp() override {
    PlatformTest::SetUp();
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
  }

  ScopedTempDir temp_dir_;
};

// Collects all the results from the given file enumerator, and provides an
// interface to query whether a given file is present.
class FindResultCollector {
 public:
  explicit FindResultCollector(FileEnumerator* enumerator) {
    FilePath cur_file;
    while (!(cur_file = enumerator->Next()).value().empty()) {
      FilePath::StringType path = cur_file.value();
      // The file should not be returned twice.
      EXPECT_TRUE(files_.end() == files_.find(path))
          << "Same file returned twice";

      // Save for later.
      files_.insert(path);
    }
  }

  // Returns true if the enumerator found the file.
  bool HasFile(const FilePath& file) const {
    return files_.find(file.value()) != files_.end();
  }

  int size() {
    return static_cast<int>(files_.size());
  }

 private:
  std::set<FilePath::StringType> files_;
};

// Simple function to dump some text into a new file.
void CreateTextFile(const FilePath& filename,
                    const std::wstring& contents) {
  std::wofstream file;
  file.open(filename.value().c_str());
  ASSERT_TRUE(file.is_open());
  file << contents;
  file.close();
}

// Simple function to take out some text from a file.
std::wstring ReadTextFile(const FilePath& filename) {
  wchar_t contents[64];
  std::wifstream file;
  file.open(filename.value().c_str());
  EXPECT_TRUE(file.is_open());
  file.getline(contents, arraysize(contents));
  file.close();
  return std::wstring(contents);
}

#if defined(OS_WIN)
uint64 FileTimeAsUint64(const FILETIME& ft) {
  ULARGE_INTEGER u;
  u.LowPart = ft.dwLowDateTime;
  u.HighPart = ft.dwHighDateTime;
  return u.QuadPart;
}
#endif

TEST_F(FileUtilTest, FileAndDirectorySize) {
  // Create three files of 20, 30 and 3 chars (utf8). ComputeDirectorySize
  // should return 53 bytes.
  FilePath file_01 = temp_dir_.path().Append(FPL("The file 01.txt"));
  CreateTextFile(file_01, L"12345678901234567890");
  int64 size_f1 = 0;
  ASSERT_TRUE(GetFileSize(file_01, &size_f1));
  EXPECT_EQ(20ll, size_f1);

  FilePath subdir_path = temp_dir_.path().Append(FPL("Level2"));
  CreateDirectory(subdir_path);

  FilePath file_02 = subdir_path.Append(FPL("The file 02.txt"));
  CreateTextFile(file_02, L"123456789012345678901234567890");
  int64 size_f2 = 0;
  ASSERT_TRUE(GetFileSize(file_02, &size_f2));
  EXPECT_EQ(30ll, size_f2);

  FilePath subsubdir_path = subdir_path.Append(FPL("Level3"));
  CreateDirectory(subsubdir_path);

  FilePath file_03 = subsubdir_path.Append(FPL("The file 03.txt"));
  CreateTextFile(file_03, L"123");

  int64 computed_size = ComputeDirectorySize(temp_dir_.path());
  EXPECT_EQ(size_f1 + size_f2 + 3, computed_size);
}

TEST_F(FileUtilTest, NormalizeFilePathBasic) {
  // Create a directory under the test dir.  Because we create it,
  // we know it is not a link.
  FilePath file_a_path = temp_dir_.path().Append(FPL("file_a"));
  FilePath dir_path = temp_dir_.path().Append(FPL("dir"));
  FilePath file_b_path = dir_path.Append(FPL("file_b"));
  CreateDirectory(dir_path);

  FilePath normalized_file_a_path, normalized_file_b_path;
  ASSERT_FALSE(PathExists(file_a_path));
  ASSERT_FALSE(NormalizeFilePath(file_a_path, &normalized_file_a_path))
    << "NormalizeFilePath() should fail on nonexistent paths.";

  CreateTextFile(file_a_path, bogus_content);
  ASSERT_TRUE(PathExists(file_a_path));
  ASSERT_TRUE(NormalizeFilePath(file_a_path, &normalized_file_a_path));

  CreateTextFile(file_b_path, bogus_content);
  ASSERT_TRUE(PathExists(file_b_path));
  ASSERT_TRUE(NormalizeFilePath(file_b_path, &normalized_file_b_path));

  // Beacuse this test created |dir_path|, we know it is not a link
  // or junction.  So, the real path of the directory holding file a
  // must be the parent of the path holding file b.
  ASSERT_TRUE(normalized_file_a_path.DirName()
      .IsParent(normalized_file_b_path.DirName()));
}

#if defined(OS_WIN)

TEST_F(FileUtilTest, NormalizeFilePathReparsePoints) {
  // Build the following directory structure:
  //
  // temp_dir
  // |-> base_a
  // |   |-> sub_a
  // |       |-> file.txt
  // |       |-> long_name___... (Very long name.)
  // |           |-> sub_long
  // |              |-> deep.txt
  // |-> base_b
  //     |-> to_sub_a (reparse point to temp_dir\base_a\sub_a)
  //     |-> to_base_b (reparse point to temp_dir\base_b)
  //     |-> to_sub_long (reparse point to temp_dir\sub_a\long_name_\sub_long)

  FilePath base_a = temp_dir_.path().Append(FPL("base_a"));
#if defined(OS_WIN)
  // TEMP can have a lower case drive letter.
  string16 temp_base_a = base_a.value();
  ASSERT_FALSE(temp_base_a.empty());
  *temp_base_a.begin() = ToUpperASCII(*temp_base_a.begin());
  base_a = FilePath(temp_base_a);
#endif
  ASSERT_TRUE(CreateDirectory(base_a));

  FilePath sub_a = base_a.Append(FPL("sub_a"));
  ASSERT_TRUE(CreateDirectory(sub_a));

  FilePath file_txt = sub_a.Append(FPL("file.txt"));
  CreateTextFile(file_txt, bogus_content);

  // Want a directory whose name is long enough to make the path to the file
  // inside just under MAX_PATH chars.  This will be used to test that when
  // a junction expands to a path over MAX_PATH chars in length,
  // NormalizeFilePath() fails without crashing.
  FilePath sub_long_rel(FPL("sub_long"));
  FilePath deep_txt(FPL("deep.txt"));

  int target_length = MAX_PATH;
  target_length -= (sub_a.value().length() + 1);  // +1 for the sepperator '\'.
  target_length -= (sub_long_rel.Append(deep_txt).value().length() + 1);
  // Without making the path a bit shorter, CreateDirectory() fails.
  // the resulting path is still long enough to hit the failing case in
  // NormalizePath().
  const int kCreateDirLimit = 4;
  target_length -= kCreateDirLimit;
  FilePath::StringType long_name_str = FPL("long_name_");
  long_name_str.resize(target_length, '_');

  FilePath long_name = sub_a.Append(FilePath(long_name_str));
  FilePath deep_file = long_name.Append(sub_long_rel).Append(deep_txt);
  ASSERT_EQ(MAX_PATH - kCreateDirLimit, deep_file.value().length());

  FilePath sub_long = deep_file.DirName();
  ASSERT_TRUE(CreateDirectory(sub_long));
  CreateTextFile(deep_file, bogus_content);

  FilePath base_b = temp_dir_.path().Append(FPL("base_b"));
  ASSERT_TRUE(CreateDirectory(base_b));

  FilePath to_sub_a = base_b.Append(FPL("to_sub_a"));
  ASSERT_TRUE(CreateDirectory(to_sub_a));
  FilePath normalized_path;
  {
    ReparsePoint reparse_to_sub_a(to_sub_a, sub_a);
    ASSERT_TRUE(reparse_to_sub_a.IsValid());

    FilePath to_base_b = base_b.Append(FPL("to_base_b"));
    ASSERT_TRUE(CreateDirectory(to_base_b));
    ReparsePoint reparse_to_base_b(to_base_b, base_b);
    ASSERT_TRUE(reparse_to_base_b.IsValid());

    FilePath to_sub_long = base_b.Append(FPL("to_sub_long"));
    ASSERT_TRUE(CreateDirectory(to_sub_long));
    ReparsePoint reparse_to_sub_long(to_sub_long, sub_long);
    ASSERT_TRUE(reparse_to_sub_long.IsValid());

    // Normalize a junction free path: base_a\sub_a\file.txt .
    ASSERT_TRUE(NormalizeFilePath(file_txt, &normalized_path));
    ASSERT_STREQ(file_txt.value().c_str(), normalized_path.value().c_str());

    // Check that the path base_b\to_sub_a\file.txt can be normalized to exclude
    // the junction to_sub_a.
    ASSERT_TRUE(NormalizeFilePath(to_sub_a.Append(FPL("file.txt")),
                                             &normalized_path));
    ASSERT_STREQ(file_txt.value().c_str(), normalized_path.value().c_str());

    // Check that the path base_b\to_base_b\to_base_b\to_sub_a\file.txt can be
    // normalized to exclude junctions to_base_b and to_sub_a .
    ASSERT_TRUE(NormalizeFilePath(base_b.Append(FPL("to_base_b"))
                                                   .Append(FPL("to_base_b"))
                                                   .Append(FPL("to_sub_a"))
                                                   .Append(FPL("file.txt")),
                                             &normalized_path));
    ASSERT_STREQ(file_txt.value().c_str(), normalized_path.value().c_str());

    // A long enough path will cause NormalizeFilePath() to fail.  Make a long
    // path using to_base_b many times, and check that paths long enough to fail
    // do not cause a crash.
    FilePath long_path = base_b;
    const int kLengthLimit = MAX_PATH + 200;
    while (long_path.value().length() <= kLengthLimit) {
      long_path = long_path.Append(FPL("to_base_b"));
    }
    long_path = long_path.Append(FPL("to_sub_a"))
                         .Append(FPL("file.txt"));

    ASSERT_FALSE(NormalizeFilePath(long_path, &normalized_path));

    // Normalizing the junction to deep.txt should fail, because the expanded
    // path to deep.txt is longer than MAX_PATH.
    ASSERT_FALSE(NormalizeFilePath(to_sub_long.Append(deep_txt),
                                              &normalized_path));

    // Delete the reparse points, and see that NormalizeFilePath() fails
    // to traverse them.
  }

  ASSERT_FALSE(NormalizeFilePath(to_sub_a.Append(FPL("file.txt")),
                                            &normalized_path));
}

TEST_F(FileUtilTest, DevicePathToDriveLetter) {
  // Get a drive letter.
  std::wstring real_drive_letter = temp_dir_.path().value().substr(0, 2);
  StringToUpperASCII(&real_drive_letter);
  if (!isalpha(real_drive_letter[0]) || ':' != real_drive_letter[1]) {
    LOG(ERROR) << "Can't get a drive letter to test with.";
    return;
  }

  // Get the NT style path to that drive.
  wchar_t device_path[MAX_PATH] = {'\0'};
  ASSERT_TRUE(
      ::QueryDosDevice(real_drive_letter.c_str(), device_path, MAX_PATH));
  FilePath actual_device_path(device_path);
  FilePath win32_path;

  // Run DevicePathToDriveLetterPath() on the NT style path we got from
  // QueryDosDevice().  Expect the drive letter we started with.
  ASSERT_TRUE(DevicePathToDriveLetterPath(actual_device_path, &win32_path));
  ASSERT_EQ(real_drive_letter, win32_path.value());

  // Add some directories to the path.  Expect those extra path componenets
  // to be preserved.
  FilePath kRelativePath(FPL("dir1\\dir2\\file.txt"));
  ASSERT_TRUE(DevicePathToDriveLetterPath(
      actual_device_path.Append(kRelativePath),
      &win32_path));
  EXPECT_EQ(FilePath(real_drive_letter + L"\\").Append(kRelativePath).value(),
            win32_path.value());

  // Deform the real path so that it is invalid by removing the last four
  // characters.  The way windows names devices that are hard disks
  // (\Device\HardDiskVolume${NUMBER}) guarantees that the string is longer
  // than three characters.  The only way the truncated string could be a
  // real drive is if more than 10^3 disks are mounted:
  // \Device\HardDiskVolume10000 would be truncated to \Device\HardDiskVolume1
  // Check that DevicePathToDriveLetterPath fails.
  int path_length = actual_device_path.value().length();
  int new_length = path_length - 4;
  ASSERT_LT(0, new_length);
  FilePath prefix_of_real_device_path(
      actual_device_path.value().substr(0, new_length));
  ASSERT_FALSE(DevicePathToDriveLetterPath(prefix_of_real_device_path,
                                           &win32_path));

  ASSERT_FALSE(DevicePathToDriveLetterPath(
      prefix_of_real_device_path.Append(kRelativePath),
      &win32_path));

  // Deform the real path so that it is invalid by adding some characters. For
  // example, if C: maps to \Device\HardDiskVolume8, then we simulate a
  // request for the drive letter whose native path is
  // \Device\HardDiskVolume812345 .  We assume such a device does not exist,
  // because drives are numbered in order and mounting 112345 hard disks will
  // never happen.
  const FilePath::StringType kExtraChars = FPL("12345");

  FilePath real_device_path_plus_numbers(
      actual_device_path.value() + kExtraChars);

  ASSERT_FALSE(DevicePathToDriveLetterPath(
      real_device_path_plus_numbers,
      &win32_path));

  ASSERT_FALSE(DevicePathToDriveLetterPath(
      real_device_path_plus_numbers.Append(kRelativePath),
      &win32_path));
}

TEST_F(FileUtilTest, CreateTemporaryFileInDirLongPathTest) {
  // Test that CreateTemporaryFileInDir() creates a path and returns a long path
  // if it is available. This test requires that:
  // - the filesystem at |temp_dir_| supports long filenames.
  // - the account has FILE_LIST_DIRECTORY permission for all ancestor
  //   directories of |temp_dir_|.
  const FilePath::CharType kLongDirName[] = FPL("A long path");
  const FilePath::CharType kTestSubDirName[] = FPL("test");
  FilePath long_test_dir = temp_dir_.path().Append(kLongDirName);
  ASSERT_TRUE(CreateDirectory(long_test_dir));

  // kLongDirName is not a 8.3 component. So GetShortName() should give us a
  // different short name.
  WCHAR path_buffer[MAX_PATH];
  DWORD path_buffer_length = GetShortPathName(long_test_dir.value().c_str(),
                                              path_buffer, MAX_PATH);
  ASSERT_LT(path_buffer_length, DWORD(MAX_PATH));
  ASSERT_NE(DWORD(0), path_buffer_length);
  FilePath short_test_dir(path_buffer);
  ASSERT_STRNE(kLongDirName, short_test_dir.BaseName().value().c_str());

  FilePath temp_file;
  ASSERT_TRUE(CreateTemporaryFileInDir(short_test_dir, &temp_file));
  EXPECT_STREQ(kLongDirName, temp_file.DirName().BaseName().value().c_str());
  EXPECT_TRUE(PathExists(temp_file));

  // Create a subdirectory of |long_test_dir| and make |long_test_dir|
  // unreadable. We should still be able to create a temp file in the
  // subdirectory, but we won't be able to determine the long path for it. This
  // mimics the environment that some users run where their user profiles reside
  // in a location where the don't have full access to the higher level
  // directories. (Note that this assumption is true for NTFS, but not for some
  // network file systems. E.g. AFS).
  FilePath access_test_dir = long_test_dir.Append(kTestSubDirName);
  ASSERT_TRUE(CreateDirectory(access_test_dir));
  FilePermissionRestorer long_test_dir_restorer(long_test_dir);
  ASSERT_TRUE(MakeFileUnreadable(long_test_dir));

  // Use the short form of the directory to create a temporary filename.
  ASSERT_TRUE(CreateTemporaryFileInDir(
      short_test_dir.Append(kTestSubDirName), &temp_file));
  EXPECT_TRUE(PathExists(temp_file));
  EXPECT_TRUE(short_test_dir.IsParent(temp_file.DirName()));

  // Check that the long path can't be determined for |temp_file|.
  path_buffer_length = GetLongPathName(temp_file.value().c_str(),
                                       path_buffer, MAX_PATH);
  EXPECT_EQ(DWORD(0), path_buffer_length);
}

#endif  // defined(OS_WIN)

#if defined(OS_POSIX)

TEST_F(FileUtilTest, CreateAndReadSymlinks) {
  FilePath link_from = temp_dir_.path().Append(FPL("from_file"));
  FilePath link_to = temp_dir_.path().Append(FPL("to_file"));
  CreateTextFile(link_to, bogus_content);

  ASSERT_TRUE(CreateSymbolicLink(link_to, link_from))
    << "Failed to create file symlink.";

  // If we created the link properly, we should be able to read the contents
  // through it.
  std::wstring contents = ReadTextFile(link_from);
  EXPECT_EQ(bogus_content, contents);

  FilePath result;
  ASSERT_TRUE(ReadSymbolicLink(link_from, &result));
  EXPECT_EQ(link_to.value(), result.value());

  // Link to a directory.
  link_from = temp_dir_.path().Append(FPL("from_dir"));
  link_to = temp_dir_.path().Append(FPL("to_dir"));
  ASSERT_TRUE(CreateDirectory(link_to));
  ASSERT_TRUE(CreateSymbolicLink(link_to, link_from))
    << "Failed to create directory symlink.";

  // Test failures.
  EXPECT_FALSE(CreateSymbolicLink(link_to, link_to));
  EXPECT_FALSE(ReadSymbolicLink(link_to, &result));
  FilePath missing = temp_dir_.path().Append(FPL("missing"));
  EXPECT_FALSE(ReadSymbolicLink(missing, &result));
}

// The following test of NormalizeFilePath() require that we create a symlink.
// This can not be done on Windows before Vista.  On Vista, creating a symlink
// requires privilege "SeCreateSymbolicLinkPrivilege".
// TODO(skerner): Investigate the possibility of giving base_unittests the
// privileges required to create a symlink.
TEST_F(FileUtilTest, NormalizeFilePathSymlinks) {
  // Link one file to another.
  FilePath link_from = temp_dir_.path().Append(FPL("from_file"));
  FilePath link_to = temp_dir_.path().Append(FPL("to_file"));
  CreateTextFile(link_to, bogus_content);

  ASSERT_TRUE(CreateSymbolicLink(link_to, link_from))
    << "Failed to create file symlink.";

  // Check that NormalizeFilePath sees the link.
  FilePath normalized_path;
  ASSERT_TRUE(NormalizeFilePath(link_from, &normalized_path));
  EXPECT_NE(link_from, link_to);
  EXPECT_EQ(link_to.BaseName().value(), normalized_path.BaseName().value());
  EXPECT_EQ(link_to.BaseName().value(), normalized_path.BaseName().value());

  // Link to a directory.
  link_from = temp_dir_.path().Append(FPL("from_dir"));
  link_to = temp_dir_.path().Append(FPL("to_dir"));
  ASSERT_TRUE(CreateDirectory(link_to));
  ASSERT_TRUE(CreateSymbolicLink(link_to, link_from))
    << "Failed to create directory symlink.";

  EXPECT_FALSE(NormalizeFilePath(link_from, &normalized_path))
    << "Links to directories should return false.";

  // Test that a loop in the links causes NormalizeFilePath() to return false.
  link_from = temp_dir_.path().Append(FPL("link_a"));
  link_to = temp_dir_.path().Append(FPL("link_b"));
  ASSERT_TRUE(CreateSymbolicLink(link_to, link_from))
    << "Failed to create loop symlink a.";
  ASSERT_TRUE(CreateSymbolicLink(link_from, link_to))
    << "Failed to create loop symlink b.";

  // Infinite loop!
  EXPECT_FALSE(NormalizeFilePath(link_from, &normalized_path));
}
#endif  // defined(OS_POSIX)

TEST_F(FileUtilTest, DeleteNonExistent) {
  FilePath non_existent = temp_dir_.path().AppendASCII("bogus_file_dne.foobar");
  ASSERT_FALSE(PathExists(non_existent));

  EXPECT_TRUE(DeleteFile(non_existent, false));
  ASSERT_FALSE(PathExists(non_existent));
  EXPECT_TRUE(DeleteFile(non_existent, true));
  ASSERT_FALSE(PathExists(non_existent));
}

TEST_F(FileUtilTest, DeleteNonExistentWithNonExistentParent) {
  FilePath non_existent = temp_dir_.path().AppendASCII("bogus_topdir");
  non_existent = non_existent.AppendASCII("bogus_subdir");
  ASSERT_FALSE(PathExists(non_existent));

  EXPECT_TRUE(DeleteFile(non_existent, false));
  ASSERT_FALSE(PathExists(non_existent));
  EXPECT_TRUE(DeleteFile(non_existent, true));
  ASSERT_FALSE(PathExists(non_existent));
}

TEST_F(FileUtilTest, DeleteFile) {
  // Create a file
  FilePath file_name = temp_dir_.path().Append(FPL("Test DeleteFile 1.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  // Make sure it's deleted
  EXPECT_TRUE(DeleteFile(file_name, false));
  EXPECT_FALSE(PathExists(file_name));

  // Test recursive case, create a new file
  file_name = temp_dir_.path().Append(FPL("Test DeleteFile 2.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  // Make sure it's deleted
  EXPECT_TRUE(DeleteFile(file_name, true));
  EXPECT_FALSE(PathExists(file_name));
}

#if defined(OS_POSIX)
TEST_F(FileUtilTest, DeleteSymlinkToExistentFile) {
  // Create a file.
  FilePath file_name = temp_dir_.path().Append(FPL("Test DeleteFile 2.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  // Create a symlink to the file.
  FilePath file_link = temp_dir_.path().Append("file_link_2");
  ASSERT_TRUE(CreateSymbolicLink(file_name, file_link))
      << "Failed to create symlink.";

  // Delete the symbolic link.
  EXPECT_TRUE(DeleteFile(file_link, false));

  // Make sure original file is not deleted.
  EXPECT_FALSE(PathExists(file_link));
  EXPECT_TRUE(PathExists(file_name));
}

TEST_F(FileUtilTest, DeleteSymlinkToNonExistentFile) {
  // Create a non-existent file path.
  FilePath non_existent = temp_dir_.path().Append(FPL("Test DeleteFile 3.txt"));
  EXPECT_FALSE(PathExists(non_existent));

  // Create a symlink to the non-existent file.
  FilePath file_link = temp_dir_.path().Append("file_link_3");
  ASSERT_TRUE(CreateSymbolicLink(non_existent, file_link))
      << "Failed to create symlink.";

  // Make sure the symbolic link is exist.
  EXPECT_TRUE(IsLink(file_link));
  EXPECT_FALSE(PathExists(file_link));

  // Delete the symbolic link.
  EXPECT_TRUE(DeleteFile(file_link, false));

  // Make sure the symbolic link is deleted.
  EXPECT_FALSE(IsLink(file_link));
}

TEST_F(FileUtilTest, ChangeFilePermissionsAndRead) {
  // Create a file path.
  FilePath file_name = temp_dir_.path().Append(FPL("Test Readable File.txt"));
  EXPECT_FALSE(PathExists(file_name));

  const std::string kData("hello");

  int buffer_size = kData.length();
  char* buffer = new char[buffer_size];

  // Write file.
  EXPECT_EQ(static_cast<int>(kData.length()),
            WriteFile(file_name, kData.data(), kData.length()));
  EXPECT_TRUE(PathExists(file_name));

  // Make sure the file is readable.
  int32 mode = 0;
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_TRUE(mode & FILE_PERMISSION_READ_BY_USER);

  // Get rid of the read permission.
  EXPECT_TRUE(SetPosixFilePermissions(file_name, 0u));
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_FALSE(mode & FILE_PERMISSION_READ_BY_USER);
  // Make sure the file can't be read.
  EXPECT_EQ(-1, ReadFile(file_name, buffer, buffer_size));

  // Give the read permission.
  EXPECT_TRUE(SetPosixFilePermissions(file_name, FILE_PERMISSION_READ_BY_USER));
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_TRUE(mode & FILE_PERMISSION_READ_BY_USER);
  // Make sure the file can be read.
  EXPECT_EQ(static_cast<int>(kData.length()),
            ReadFile(file_name, buffer, buffer_size));

  // Delete the file.
  EXPECT_TRUE(DeleteFile(file_name, false));
  EXPECT_FALSE(PathExists(file_name));

  delete[] buffer;
}

TEST_F(FileUtilTest, ChangeFilePermissionsAndWrite) {
  // Create a file path.
  FilePath file_name = temp_dir_.path().Append(FPL("Test Readable File.txt"));
  EXPECT_FALSE(PathExists(file_name));

  const std::string kData("hello");

  // Write file.
  EXPECT_EQ(static_cast<int>(kData.length()),
            WriteFile(file_name, kData.data(), kData.length()));
  EXPECT_TRUE(PathExists(file_name));

  // Make sure the file is writable.
  int mode = 0;
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_TRUE(mode & FILE_PERMISSION_WRITE_BY_USER);
  EXPECT_TRUE(PathIsWritable(file_name));

  // Get rid of the write permission.
  EXPECT_TRUE(SetPosixFilePermissions(file_name, 0u));
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_FALSE(mode & FILE_PERMISSION_WRITE_BY_USER);
  // Make sure the file can't be write.
  EXPECT_EQ(-1, WriteFile(file_name, kData.data(), kData.length()));
  EXPECT_FALSE(PathIsWritable(file_name));

  // Give read permission.
  EXPECT_TRUE(SetPosixFilePermissions(file_name,
                                      FILE_PERMISSION_WRITE_BY_USER));
  EXPECT_TRUE(GetPosixFilePermissions(file_name, &mode));
  EXPECT_TRUE(mode & FILE_PERMISSION_WRITE_BY_USER);
  // Make sure the file can be write.
  EXPECT_EQ(static_cast<int>(kData.length()),
            WriteFile(file_name, kData.data(), kData.length()));
  EXPECT_TRUE(PathIsWritable(file_name));

  // Delete the file.
  EXPECT_TRUE(DeleteFile(file_name, false));
  EXPECT_FALSE(PathExists(file_name));
}

TEST_F(FileUtilTest, ChangeDirectoryPermissionsAndEnumerate) {
  // Create a directory path.
  FilePath subdir_path =
      temp_dir_.path().Append(FPL("PermissionTest1"));
  CreateDirectory(subdir_path);
  ASSERT_TRUE(PathExists(subdir_path));

  // Create a dummy file to enumerate.
  FilePath file_name = subdir_path.Append(FPL("Test Readable File.txt"));
  EXPECT_FALSE(PathExists(file_name));
  const std::string kData("hello");
  EXPECT_EQ(static_cast<int>(kData.length()),
            WriteFile(file_name, kData.data(), kData.length()));
  EXPECT_TRUE(PathExists(file_name));

  // Make sure the directory has the all permissions.
  int mode = 0;
  EXPECT_TRUE(GetPosixFilePermissions(subdir_path, &mode));
  EXPECT_EQ(FILE_PERMISSION_USER_MASK, mode & FILE_PERMISSION_USER_MASK);

  // Get rid of the permissions from the directory.
  EXPECT_TRUE(SetPosixFilePermissions(subdir_path, 0u));
  EXPECT_TRUE(GetPosixFilePermissions(subdir_path, &mode));
  EXPECT_FALSE(mode & FILE_PERMISSION_USER_MASK);

  // Make sure the file in the directory can't be enumerated.
  FileEnumerator f1(subdir_path, true, FileEnumerator::FILES);
  EXPECT_TRUE(PathExists(subdir_path));
  FindResultCollector c1(&f1);
  EXPECT_EQ(0, c1.size());
  EXPECT_FALSE(GetPosixFilePermissions(file_name, &mode));

  // Give the permissions to the directory.
  EXPECT_TRUE(SetPosixFilePermissions(subdir_path, FILE_PERMISSION_USER_MASK));
  EXPECT_TRUE(GetPosixFilePermissions(subdir_path, &mode));
  EXPECT_EQ(FILE_PERMISSION_USER_MASK, mode & FILE_PERMISSION_USER_MASK);

  // Make sure the file in the directory can be enumerated.
  FileEnumerator f2(subdir_path, true, FileEnumerator::FILES);
  FindResultCollector c2(&f2);
  EXPECT_TRUE(c2.HasFile(file_name));
  EXPECT_EQ(1, c2.size());

  // Delete the file.
  EXPECT_TRUE(DeleteFile(subdir_path, true));
  EXPECT_FALSE(PathExists(subdir_path));
}

#endif  // defined(OS_POSIX)

#if defined(OS_WIN)
// Tests that the Delete function works for wild cards, especially
// with the recursion flag.  Also coincidentally tests PathExists.
// TODO(erikkay): see if anyone's actually using this feature of the API
TEST_F(FileUtilTest, DeleteWildCard) {
  // Create a file and a directory
  FilePath file_name = temp_dir_.path().Append(FPL("Test DeleteWildCard.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  FilePath subdir_path = temp_dir_.path().Append(FPL("DeleteWildCardDir"));
  CreateDirectory(subdir_path);
  ASSERT_TRUE(PathExists(subdir_path));

  // Create the wildcard path
  FilePath directory_contents = temp_dir_.path();
  directory_contents = directory_contents.Append(FPL("*"));

  // Delete non-recursively and check that only the file is deleted
  EXPECT_TRUE(DeleteFile(directory_contents, false));
  EXPECT_FALSE(PathExists(file_name));
  EXPECT_TRUE(PathExists(subdir_path));

  // Delete recursively and make sure all contents are deleted
  EXPECT_TRUE(DeleteFile(directory_contents, true));
  EXPECT_FALSE(PathExists(file_name));
  EXPECT_FALSE(PathExists(subdir_path));
}

// TODO(erikkay): see if anyone's actually using this feature of the API
TEST_F(FileUtilTest, DeleteNonExistantWildCard) {
  // Create a file and a directory
  FilePath subdir_path =
      temp_dir_.path().Append(FPL("DeleteNonExistantWildCard"));
  CreateDirectory(subdir_path);
  ASSERT_TRUE(PathExists(subdir_path));

  // Create the wildcard path
  FilePath directory_contents = subdir_path;
  directory_contents = directory_contents.Append(FPL("*"));

  // Delete non-recursively and check nothing got deleted
  EXPECT_TRUE(DeleteFile(directory_contents, false));
  EXPECT_TRUE(PathExists(subdir_path));

  // Delete recursively and check nothing got deleted
  EXPECT_TRUE(DeleteFile(directory_contents, true));
  EXPECT_TRUE(PathExists(subdir_path));
}
#endif

// Tests non-recursive Delete() for a directory.
TEST_F(FileUtilTest, DeleteDirNonRecursive) {
  // Create a subdirectory and put a file and two directories inside.
  FilePath test_subdir = temp_dir_.path().Append(FPL("DeleteDirNonRecursive"));
  CreateDirectory(test_subdir);
  ASSERT_TRUE(PathExists(test_subdir));

  FilePath file_name = test_subdir.Append(FPL("Test DeleteDir.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  FilePath subdir_path1 = test_subdir.Append(FPL("TestSubDir1"));
  CreateDirectory(subdir_path1);
  ASSERT_TRUE(PathExists(subdir_path1));

  FilePath subdir_path2 = test_subdir.Append(FPL("TestSubDir2"));
  CreateDirectory(subdir_path2);
  ASSERT_TRUE(PathExists(subdir_path2));

  // Delete non-recursively and check that the empty dir got deleted
  EXPECT_TRUE(DeleteFile(subdir_path2, false));
  EXPECT_FALSE(PathExists(subdir_path2));

  // Delete non-recursively and check that nothing got deleted
  EXPECT_FALSE(DeleteFile(test_subdir, false));
  EXPECT_TRUE(PathExists(test_subdir));
  EXPECT_TRUE(PathExists(file_name));
  EXPECT_TRUE(PathExists(subdir_path1));
}

// Tests recursive Delete() for a directory.
TEST_F(FileUtilTest, DeleteDirRecursive) {
  // Create a subdirectory and put a file and two directories inside.
  FilePath test_subdir = temp_dir_.path().Append(FPL("DeleteDirRecursive"));
  CreateDirectory(test_subdir);
  ASSERT_TRUE(PathExists(test_subdir));

  FilePath file_name = test_subdir.Append(FPL("Test DeleteDirRecursive.txt"));
  CreateTextFile(file_name, bogus_content);
  ASSERT_TRUE(PathExists(file_name));

  FilePath subdir_path1 = test_subdir.Append(FPL("TestSubDir1"));
  CreateDirectory(subdir_path1);
  ASSERT_TRUE(PathExists(subdir_path1));

  FilePath subdir_path2 = test_subdir.Append(FPL("TestSubDir2"));
  CreateDirectory(subdir_path2);
  ASSERT_TRUE(PathExists(subdir_path2));

  // Delete recursively and check that the empty dir got deleted
  EXPECT_TRUE(DeleteFile(subdir_path2, true));
  EXPECT_FALSE(PathExists(subdir_path2));

  // Delete recursively and check that everything got deleted
  EXPECT_TRUE(DeleteFile(test_subdir, true));
  EXPECT_FALSE(PathExists(file_name));
  EXPECT_FALSE(PathExists(subdir_path1));
  EXPECT_FALSE(PathExists(test_subdir));
}

TEST_F(FileUtilTest, MoveFileNew) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination.
  FilePath file_name_to = temp_dir_.path().Append(
      FILE_PATH_LITERAL("Move_Test_File_Destination.txt"));
  ASSERT_FALSE(PathExists(file_name_to));

  EXPECT_TRUE(Move(file_name_from, file_name_to));

  // Check everything has been moved.
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, MoveFileExists) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination name.
  FilePath file_name_to = temp_dir_.path().Append(
      FILE_PATH_LITERAL("Move_Test_File_Destination.txt"));
  CreateTextFile(file_name_to, L"Old file content");
  ASSERT_TRUE(PathExists(file_name_to));

  EXPECT_TRUE(Move(file_name_from, file_name_to));

  // Check everything has been moved.
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_TRUE(L"Gooooooooooooooooooooogle" == ReadTextFile(file_name_to));
}

TEST_F(FileUtilTest, MoveFileDirExists) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination directory
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Destination"));
  CreateDirectory(dir_name_to);
  ASSERT_TRUE(PathExists(dir_name_to));

  EXPECT_FALSE(Move(file_name_from, dir_name_to));
}


TEST_F(FileUtilTest, MoveNew) {
  // Create a directory
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory
  FilePath txt_file_name(FILE_PATH_LITERAL("Move_Test_File.txt"));
  FilePath file_name_from = dir_name_from.Append(txt_file_name);
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Move the directory.
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Move_Test_File.txt"));

  ASSERT_FALSE(PathExists(dir_name_to));

  EXPECT_TRUE(Move(dir_name_from, dir_name_to));

  // Check everything has been moved.
  EXPECT_FALSE(PathExists(dir_name_from));
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));

  // Test path traversal.
  file_name_from = dir_name_to.Append(txt_file_name);
  file_name_to = dir_name_to.Append(FILE_PATH_LITERAL(".."));
  file_name_to = file_name_to.Append(txt_file_name);
  EXPECT_FALSE(Move(file_name_from, file_name_to));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_FALSE(PathExists(file_name_to));
  EXPECT_TRUE(internal::MoveUnsafe(file_name_from, file_name_to));
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, MoveExist) {
  // Create a directory
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Move_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Move_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Move the directory
  FilePath dir_name_exists =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Destination"));

  FilePath dir_name_to =
      dir_name_exists.Append(FILE_PATH_LITERAL("Move_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Move_Test_File.txt"));

  // Create the destination directory.
  CreateDirectory(dir_name_exists);
  ASSERT_TRUE(PathExists(dir_name_exists));

  EXPECT_TRUE(Move(dir_name_from, dir_name_to));

  // Check everything has been moved.
  EXPECT_FALSE(PathExists(dir_name_from));
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, CopyDirectoryRecursivelyNew) {
  // Create a directory.
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory.
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Create a subdirectory.
  FilePath subdir_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Subdir"));
  CreateDirectory(subdir_name_from);
  ASSERT_TRUE(PathExists(subdir_name_from));

  // Create a file under the subdirectory.
  FilePath file_name2_from =
      subdir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name2_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name2_from));

  // Copy the directory recursively.
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  FilePath subdir_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Subdir"));
  FilePath file_name2_to =
      subdir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));

  ASSERT_FALSE(PathExists(dir_name_to));

  EXPECT_TRUE(CopyDirectory(dir_name_from, dir_name_to, true));

  // Check everything has been copied.
  EXPECT_TRUE(PathExists(dir_name_from));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(subdir_name_from));
  EXPECT_TRUE(PathExists(file_name2_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_TRUE(PathExists(subdir_name_to));
  EXPECT_TRUE(PathExists(file_name2_to));
}

TEST_F(FileUtilTest, CopyDirectoryRecursivelyExists) {
  // Create a directory.
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory.
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Create a subdirectory.
  FilePath subdir_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Subdir"));
  CreateDirectory(subdir_name_from);
  ASSERT_TRUE(PathExists(subdir_name_from));

  // Create a file under the subdirectory.
  FilePath file_name2_from =
      subdir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name2_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name2_from));

  // Copy the directory recursively.
  FilePath dir_name_exists =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Destination"));

  FilePath dir_name_to =
      dir_name_exists.Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  FilePath subdir_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Subdir"));
  FilePath file_name2_to =
      subdir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));

  // Create the destination directory.
  CreateDirectory(dir_name_exists);
  ASSERT_TRUE(PathExists(dir_name_exists));

  EXPECT_TRUE(CopyDirectory(dir_name_from, dir_name_exists, true));

  // Check everything has been copied.
  EXPECT_TRUE(PathExists(dir_name_from));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(subdir_name_from));
  EXPECT_TRUE(PathExists(file_name2_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_TRUE(PathExists(subdir_name_to));
  EXPECT_TRUE(PathExists(file_name2_to));
}

TEST_F(FileUtilTest, CopyDirectoryNew) {
  // Create a directory.
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory.
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Create a subdirectory.
  FilePath subdir_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Subdir"));
  CreateDirectory(subdir_name_from);
  ASSERT_TRUE(PathExists(subdir_name_from));

  // Create a file under the subdirectory.
  FilePath file_name2_from =
      subdir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name2_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name2_from));

  // Copy the directory not recursively.
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  FilePath subdir_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Subdir"));

  ASSERT_FALSE(PathExists(dir_name_to));

  EXPECT_TRUE(CopyDirectory(dir_name_from, dir_name_to, false));

  // Check everything has been copied.
  EXPECT_TRUE(PathExists(dir_name_from));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(subdir_name_from));
  EXPECT_TRUE(PathExists(file_name2_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_FALSE(PathExists(subdir_name_to));
}

TEST_F(FileUtilTest, CopyDirectoryExists) {
  // Create a directory.
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory.
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Create a subdirectory.
  FilePath subdir_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Subdir"));
  CreateDirectory(subdir_name_from);
  ASSERT_TRUE(PathExists(subdir_name_from));

  // Create a file under the subdirectory.
  FilePath file_name2_from =
      subdir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name2_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name2_from));

  // Copy the directory not recursively.
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  FilePath subdir_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Subdir"));

  // Create the destination directory.
  CreateDirectory(dir_name_to);
  ASSERT_TRUE(PathExists(dir_name_to));

  EXPECT_TRUE(CopyDirectory(dir_name_from, dir_name_to, false));

  // Check everything has been copied.
  EXPECT_TRUE(PathExists(dir_name_from));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(subdir_name_from));
  EXPECT_TRUE(PathExists(file_name2_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_FALSE(PathExists(subdir_name_to));
}

TEST_F(FileUtilTest, CopyFileWithCopyDirectoryRecursiveToNew) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination name
  FilePath file_name_to = temp_dir_.path().Append(
      FILE_PATH_LITERAL("Copy_Test_File_Destination.txt"));
  ASSERT_FALSE(PathExists(file_name_to));

  EXPECT_TRUE(CopyDirectory(file_name_from, file_name_to, true));

  // Check the has been copied
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, CopyFileWithCopyDirectoryRecursiveToExisting) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination name
  FilePath file_name_to = temp_dir_.path().Append(
      FILE_PATH_LITERAL("Copy_Test_File_Destination.txt"));
  CreateTextFile(file_name_to, L"Old file content");
  ASSERT_TRUE(PathExists(file_name_to));

  EXPECT_TRUE(CopyDirectory(file_name_from, file_name_to, true));

  // Check the has been copied
  EXPECT_TRUE(PathExists(file_name_to));
  EXPECT_TRUE(L"Gooooooooooooooooooooogle" == ReadTextFile(file_name_to));
}

TEST_F(FileUtilTest, CopyFileWithCopyDirectoryRecursiveToExistingDirectory) {
  // Create a file
  FilePath file_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // The destination
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Destination"));
  CreateDirectory(dir_name_to);
  ASSERT_TRUE(PathExists(dir_name_to));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));

  EXPECT_TRUE(CopyDirectory(file_name_from, dir_name_to, true));

  // Check the has been copied
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, CopyDirectoryWithTrailingSeparators) {
  // Create a directory.
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory.
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Copy the directory recursively.
  FilePath dir_name_to =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));

  // Create from path with trailing separators.
#if defined(OS_WIN)
  FilePath from_path =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir\\\\\\"));
#elif defined (OS_POSIX)
  FilePath from_path =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir///"));
#endif

  EXPECT_TRUE(CopyDirectory(from_path, dir_name_to, true));

  // Check everything has been copied.
  EXPECT_TRUE(PathExists(dir_name_from));
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
}

// Sets the source file to read-only.
void SetReadOnly(const FilePath& path, bool read_only) {
#if defined(OS_WIN)
  // On Windows, it involves setting/removing the 'readonly' bit.
  DWORD attrs = GetFileAttributes(path.value().c_str());
  ASSERT_NE(INVALID_FILE_ATTRIBUTES, attrs);
  ASSERT_TRUE(SetFileAttributes(
      path.value().c_str(),
      read_only ? (attrs | FILE_ATTRIBUTE_READONLY) :
          (attrs & ~FILE_ATTRIBUTE_READONLY)));

  DWORD expected = read_only ?
      ((attrs & (FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_DIRECTORY)) |
          FILE_ATTRIBUTE_READONLY) :
      (attrs & (FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_DIRECTORY));

  // Ignore FILE_ATTRIBUTE_NOT_CONTENT_INDEXED if present.
  attrs = GetFileAttributes(path.value().c_str()) &
          ~FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
  ASSERT_EQ(expected, attrs);
#else
  // On all other platforms, it involves removing/setting the write bit.
  mode_t mode = read_only ? S_IRUSR : (S_IRUSR | S_IWUSR);
  EXPECT_TRUE(SetPosixFilePermissions(
      path, DirectoryExists(path) ? (mode | S_IXUSR) : mode));
#endif
}

bool IsReadOnly(const FilePath& path) {
#if defined(OS_WIN)
  DWORD attrs = GetFileAttributes(path.value().c_str());
  EXPECT_NE(INVALID_FILE_ATTRIBUTES, attrs);
  return attrs & FILE_ATTRIBUTE_READONLY;
#else
  int mode = 0;
  EXPECT_TRUE(GetPosixFilePermissions(path, &mode));
  return !(mode & S_IWUSR);
#endif
}

TEST_F(FileUtilTest, CopyDirectoryACL) {
  // Create source directories.
  FilePath src = temp_dir_.path().Append(FILE_PATH_LITERAL("src"));
  FilePath src_subdir = src.Append(FILE_PATH_LITERAL("subdir"));
  CreateDirectory(src_subdir);
  ASSERT_TRUE(PathExists(src_subdir));

  // Create a file under the directory.
  FilePath src_file = src.Append(FILE_PATH_LITERAL("src.txt"));
  CreateTextFile(src_file, L"Gooooooooooooooooooooogle");
  SetReadOnly(src_file, true);
  ASSERT_TRUE(IsReadOnly(src_file));

  // Make directory read-only.
  SetReadOnly(src_subdir, true);
  ASSERT_TRUE(IsReadOnly(src_subdir));

  // Copy the directory recursively.
  FilePath dst = temp_dir_.path().Append(FILE_PATH_LITERAL("dst"));
  FilePath dst_file = dst.Append(FILE_PATH_LITERAL("src.txt"));
  EXPECT_TRUE(CopyDirectory(src, dst, true));

  FilePath dst_subdir = dst.Append(FILE_PATH_LITERAL("subdir"));
  ASSERT_FALSE(IsReadOnly(dst_subdir));
  ASSERT_FALSE(IsReadOnly(dst_file));

  // Give write permissions to allow deletion.
  SetReadOnly(src_subdir, false);
  ASSERT_FALSE(IsReadOnly(src_subdir));
}

TEST_F(FileUtilTest, CopyFile) {
  // Create a directory
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("Copy_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("Copy_Test_File.txt"));
  const std::wstring file_contents(L"Gooooooooooooooooooooogle");
  CreateTextFile(file_name_from, file_contents);
  ASSERT_TRUE(PathExists(file_name_from));

  // Copy the file.
  FilePath dest_file = dir_name_from.Append(FILE_PATH_LITERAL("DestFile.txt"));
  ASSERT_TRUE(CopyFile(file_name_from, dest_file));

  // Try to copy the file to another location using '..' in the path.
  FilePath dest_file2(dir_name_from);
  dest_file2 = dest_file2.AppendASCII("..");
  dest_file2 = dest_file2.AppendASCII("DestFile.txt");
  ASSERT_FALSE(CopyFile(file_name_from, dest_file2));

  FilePath dest_file2_test(dir_name_from);
  dest_file2_test = dest_file2_test.DirName();
  dest_file2_test = dest_file2_test.AppendASCII("DestFile.txt");

  // Check expected copy results.
  EXPECT_TRUE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(dest_file));
  const std::wstring read_contents = ReadTextFile(dest_file);
  EXPECT_EQ(file_contents, read_contents);
  EXPECT_FALSE(PathExists(dest_file2_test));
  EXPECT_FALSE(PathExists(dest_file2));
}

TEST_F(FileUtilTest, CopyFileACL) {
  // While FileUtilTest.CopyFile asserts the content is correctly copied over,
  // this test case asserts the access control bits are meeting expectations in
  // CopyFile().
  FilePath src = temp_dir_.path().Append(FILE_PATH_LITERAL("src.txt"));
  const std::wstring file_contents(L"Gooooooooooooooooooooogle");
  CreateTextFile(src, file_contents);

  // Set the source file to read-only.
  ASSERT_FALSE(IsReadOnly(src));
  SetReadOnly(src, true);
  ASSERT_TRUE(IsReadOnly(src));

  // Copy the file.
  FilePath dst = temp_dir_.path().Append(FILE_PATH_LITERAL("dst.txt"));
  ASSERT_TRUE(CopyFile(src, dst));
  EXPECT_EQ(file_contents, ReadTextFile(dst));

  ASSERT_FALSE(IsReadOnly(dst));
}

// file_util winds up using autoreleased objects on the Mac, so this needs
// to be a PlatformTest.
typedef PlatformTest ReadOnlyFileUtilTest;

TEST_F(ReadOnlyFileUtilTest, ContentsEqual) {
  FilePath data_dir;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &data_dir));
  data_dir = data_dir.AppendASCII("file_util");
  ASSERT_TRUE(PathExists(data_dir));

  FilePath original_file =
      data_dir.Append(FILE_PATH_LITERAL("original.txt"));
  FilePath same_file =
      data_dir.Append(FILE_PATH_LITERAL("same.txt"));
  FilePath same_length_file =
      data_dir.Append(FILE_PATH_LITERAL("same_length.txt"));
  FilePath different_file =
      data_dir.Append(FILE_PATH_LITERAL("different.txt"));
  FilePath different_first_file =
      data_dir.Append(FILE_PATH_LITERAL("different_first.txt"));
  FilePath different_last_file =
      data_dir.Append(FILE_PATH_LITERAL("different_last.txt"));
  FilePath empty1_file =
      data_dir.Append(FILE_PATH_LITERAL("empty1.txt"));
  FilePath empty2_file =
      data_dir.Append(FILE_PATH_LITERAL("empty2.txt"));
  FilePath shortened_file =
      data_dir.Append(FILE_PATH_LITERAL("shortened.txt"));
  FilePath binary_file =
      data_dir.Append(FILE_PATH_LITERAL("binary_file.bin"));
  FilePath binary_file_same =
      data_dir.Append(FILE_PATH_LITERAL("binary_file_same.bin"));
  FilePath binary_file_diff =
      data_dir.Append(FILE_PATH_LITERAL("binary_file_diff.bin"));

  EXPECT_TRUE(ContentsEqual(original_file, original_file));
  EXPECT_TRUE(ContentsEqual(original_file, same_file));
  EXPECT_FALSE(ContentsEqual(original_file, same_length_file));
  EXPECT_FALSE(ContentsEqual(original_file, different_file));
  EXPECT_FALSE(ContentsEqual(FilePath(FILE_PATH_LITERAL("bogusname")),
                             FilePath(FILE_PATH_LITERAL("bogusname"))));
  EXPECT_FALSE(ContentsEqual(original_file, different_first_file));
  EXPECT_FALSE(ContentsEqual(original_file, different_last_file));
  EXPECT_TRUE(ContentsEqual(empty1_file, empty2_file));
  EXPECT_FALSE(ContentsEqual(original_file, shortened_file));
  EXPECT_FALSE(ContentsEqual(shortened_file, original_file));
  EXPECT_TRUE(ContentsEqual(binary_file, binary_file_same));
  EXPECT_FALSE(ContentsEqual(binary_file, binary_file_diff));
}

TEST_F(ReadOnlyFileUtilTest, TextContentsEqual) {
  FilePath data_dir;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &data_dir));
  data_dir = data_dir.AppendASCII("file_util");
  ASSERT_TRUE(PathExists(data_dir));

  FilePath original_file =
      data_dir.Append(FILE_PATH_LITERAL("original.txt"));
  FilePath same_file =
      data_dir.Append(FILE_PATH_LITERAL("same.txt"));
  FilePath crlf_file =
      data_dir.Append(FILE_PATH_LITERAL("crlf.txt"));
  FilePath shortened_file =
      data_dir.Append(FILE_PATH_LITERAL("shortened.txt"));
  FilePath different_file =
      data_dir.Append(FILE_PATH_LITERAL("different.txt"));
  FilePath different_first_file =
      data_dir.Append(FILE_PATH_LITERAL("different_first.txt"));
  FilePath different_last_file =
      data_dir.Append(FILE_PATH_LITERAL("different_last.txt"));
  FilePath first1_file =
      data_dir.Append(FILE_PATH_LITERAL("first1.txt"));
  FilePath first2_file =
      data_dir.Append(FILE_PATH_LITERAL("first2.txt"));
  FilePath empty1_file =
      data_dir.Append(FILE_PATH_LITERAL("empty1.txt"));
  FilePath empty2_file =
      data_dir.Append(FILE_PATH_LITERAL("empty2.txt"));
  FilePath blank_line_file =
      data_dir.Append(FILE_PATH_LITERAL("blank_line.txt"));
  FilePath blank_line_crlf_file =
      data_dir.Append(FILE_PATH_LITERAL("blank_line_crlf.txt"));

  EXPECT_TRUE(TextContentsEqual(original_file, same_file));
  EXPECT_TRUE(TextContentsEqual(original_file, crlf_file));
  EXPECT_FALSE(TextContentsEqual(original_file, shortened_file));
  EXPECT_FALSE(TextContentsEqual(original_file, different_file));
  EXPECT_FALSE(TextContentsEqual(original_file, different_first_file));
  EXPECT_FALSE(TextContentsEqual(original_file, different_last_file));
  EXPECT_FALSE(TextContentsEqual(first1_file, first2_file));
  EXPECT_TRUE(TextContentsEqual(empty1_file, empty2_file));
  EXPECT_FALSE(TextContentsEqual(original_file, empty1_file));
  EXPECT_TRUE(TextContentsEqual(blank_line_file, blank_line_crlf_file));
}

// We don't need equivalent functionality outside of Windows.
#if defined(OS_WIN)
TEST_F(FileUtilTest, CopyAndDeleteDirectoryTest) {
  // Create a directory
  FilePath dir_name_from =
      temp_dir_.path().Append(FILE_PATH_LITERAL("CopyAndDelete_From_Subdir"));
  CreateDirectory(dir_name_from);
  ASSERT_TRUE(PathExists(dir_name_from));

  // Create a file under the directory
  FilePath file_name_from =
      dir_name_from.Append(FILE_PATH_LITERAL("CopyAndDelete_Test_File.txt"));
  CreateTextFile(file_name_from, L"Gooooooooooooooooooooogle");
  ASSERT_TRUE(PathExists(file_name_from));

  // Move the directory by using CopyAndDeleteDirectory
  FilePath dir_name_to = temp_dir_.path().Append(
      FILE_PATH_LITERAL("CopyAndDelete_To_Subdir"));
  FilePath file_name_to =
      dir_name_to.Append(FILE_PATH_LITERAL("CopyAndDelete_Test_File.txt"));

  ASSERT_FALSE(PathExists(dir_name_to));

  EXPECT_TRUE(internal::CopyAndDeleteDirectory(dir_name_from,
                                                     dir_name_to));

  // Check everything has been moved.
  EXPECT_FALSE(PathExists(dir_name_from));
  EXPECT_FALSE(PathExists(file_name_from));
  EXPECT_TRUE(PathExists(dir_name_to));
  EXPECT_TRUE(PathExists(file_name_to));
}

TEST_F(FileUtilTest, GetTempDirTest) {
  static const TCHAR* kTmpKey = _T("TMP");
  static const TCHAR* kTmpValues[] = {
    _T(""), _T("C:"), _T("C:\\"), _T("C:\\tmp"), _T("C:\\tmp\\")
  };
  // Save the original $TMP.
  size_t original_tmp_size;
  TCHAR* original_tmp;
  ASSERT_EQ(0, ::_tdupenv_s(&original_tmp, &original_tmp_size, kTmpKey));
  // original_tmp may be NULL.

  for (unsigned int i = 0; i < arraysize(kTmpValues); ++i) {
    FilePath path;
    ::_tputenv_s(kTmpKey, kTmpValues[i]);
    GetTempDir(&path);
    EXPECT_TRUE(path.IsAbsolute()) << "$TMP=" << kTmpValues[i] <<
        " result=" << path.value();
  }

  // Restore the original $TMP.
  if (original_tmp) {
    ::_tputenv_s(kTmpKey, original_tmp);
    free(original_tmp);
  } else {
    ::_tputenv_s(kTmpKey, _T(""));
  }
}
#endif  // OS_WIN

TEST_F(FileUtilTest, CreateTemporaryFileTest) {
  FilePath temp_files[3];
  for (int i = 0; i < 3; i++) {
    ASSERT_TRUE(CreateTemporaryFile(&(temp_files[i])));
    EXPECT_TRUE(PathExists(temp_files[i]));
    EXPECT_FALSE(DirectoryExists(temp_files[i]));
  }
  for (int i = 0; i < 3; i++)
    EXPECT_FALSE(temp_files[i] == temp_files[(i+1)%3]);
  for (int i = 0; i < 3; i++)
    EXPECT_TRUE(DeleteFile(temp_files[i], false));
}

TEST_F(FileUtilTest, CreateAndOpenTemporaryFileTest) {
  FilePath names[3];
  FILE* fps[3];
  int i;

  // Create; make sure they are open and exist.
  for (i = 0; i < 3; ++i) {
    fps[i] = CreateAndOpenTemporaryFile(&(names[i]));
    ASSERT_TRUE(fps[i]);
    EXPECT_TRUE(PathExists(names[i]));
  }

  // Make sure all names are unique.
  for (i = 0; i < 3; ++i) {
    EXPECT_FALSE(names[i] == names[(i+1)%3]);
  }

  // Close and delete.
  for (i = 0; i < 3; ++i) {
    EXPECT_TRUE(CloseFile(fps[i]));
    EXPECT_TRUE(DeleteFile(names[i], false));
  }
}

TEST_F(FileUtilTest, FileToFILE) {
  File file;
  FILE* stream = FileToFILE(file.Pass(), "w");
  EXPECT_FALSE(stream);

  FilePath file_name = temp_dir_.path().Append(FPL("The file.txt"));
  file = File(file_name, File::FLAG_CREATE | File::FLAG_WRITE);
  EXPECT_TRUE(file.IsValid());

  stream = FileToFILE(file.Pass(), "w");
  EXPECT_TRUE(stream);
  EXPECT_FALSE(file.IsValid());
  EXPECT_TRUE(CloseFile(stream));
}

TEST_F(FileUtilTest, CreateNewTempDirectoryTest) {
  FilePath temp_dir;
  ASSERT_TRUE(CreateNewTempDirectory(FilePath::StringType(), &temp_dir));
  EXPECT_TRUE(PathExists(temp_dir));
  EXPECT_TRUE(DeleteFile(temp_dir, false));
}

TEST_F(FileUtilTest, CreateNewTemporaryDirInDirTest) {
  FilePath new_dir;
  ASSERT_TRUE(CreateTemporaryDirInDir(
                  temp_dir_.path(),
                  FILE_PATH_LITERAL("CreateNewTemporaryDirInDirTest"),
                  &new_dir));
  EXPECT_TRUE(PathExists(new_dir));
  EXPECT_TRUE(temp_dir_.path().IsParent(new_dir));
  EXPECT_TRUE(DeleteFile(new_dir, false));
}

#if defined(OS_POSIX)
TEST_F(FileUtilTest, GetShmemTempDirTest) {
  FilePath dir;
  EXPECT_TRUE(GetShmemTempDir(false, &dir));
  EXPECT_TRUE(DirectoryExists(dir));
}
#endif

TEST_F(FileUtilTest, GetHomeDirTest) {
#if !defined(OS_ANDROID)  // Not implemented on Android.
  // We don't actually know what the home directory is supposed to be without
  // calling some OS functions which would just duplicate the implementation.
  // So here we just test that it returns something "reasonable".
  FilePath home = GetHomeDir();
  ASSERT_FALSE(home.empty());
  ASSERT_TRUE(home.IsAbsolute());
#endif
}

TEST_F(FileUtilTest, CreateDirectoryTest) {
  FilePath test_root =
      temp_dir_.path().Append(FILE_PATH_LITERAL("create_directory_test"));
#if defined(OS_WIN)
  FilePath test_path =
      test_root.Append(FILE_PATH_LITERAL("dir\\tree\\likely\\doesnt\\exist\\"));
#elif defined(OS_POSIX)
  FilePath test_path =
      test_root.Append(FILE_PATH_LITERAL("dir/tree/likely/doesnt/exist/"));
#endif

  EXPECT_FALSE(PathExists(test_path));
  EXPECT_TRUE(CreateDirectory(test_path));
  EXPECT_TRUE(PathExists(test_path));
  // CreateDirectory returns true if the DirectoryExists returns true.
  EXPECT_TRUE(CreateDirectory(test_path));

  // Doesn't work to create it on top of a non-dir
  test_path = test_path.Append(FILE_PATH_LITERAL("foobar.txt"));
  EXPECT_FALSE(PathExists(test_path));
  CreateTextFile(test_path, L"test file");
  EXPECT_TRUE(PathExists(test_path));
  EXPECT_FALSE(CreateDirectory(test_path));

  EXPECT_TRUE(DeleteFile(test_root, true));
  EXPECT_FALSE(PathExists(test_root));
  EXPECT_FALSE(PathExists(test_path));

  // Verify assumptions made by the Windows implementation:
  // 1. The current directory always exists.
  // 2. The root directory always exists.
  ASSERT_TRUE(DirectoryExists(FilePath(FilePath::kCurrentDirectory)));
  FilePath top_level = test_root;
  while (top_level != top_level.DirName()) {
    top_level = top_level.DirName();
  }
  ASSERT_TRUE(DirectoryExists(top_level));

  // Given these assumptions hold, it should be safe to
  // test that "creating" these directories succeeds.
  EXPECT_TRUE(CreateDirectory(
      FilePath(FilePath::kCurrentDirectory)));
  EXPECT_TRUE(CreateDirectory(top_level));

#if defined(OS_WIN)
  FilePath invalid_drive(FILE_PATH_LITERAL("o:\\"));
  FilePath invalid_path =
      invalid_drive.Append(FILE_PATH_LITERAL("some\\inaccessible\\dir"));
  if (!PathExists(invalid_drive)) {
    EXPECT_FALSE(CreateDirectory(invalid_path));
  }
#endif
}

TEST_F(FileUtilTest, DetectDirectoryTest) {
  // Check a directory
  FilePath test_root =
      temp_dir_.path().Append(FILE_PATH_LITERAL("detect_directory_test"));
  EXPECT_FALSE(PathExists(test_root));
  EXPECT_TRUE(CreateDirectory(test_root));
  EXPECT_TRUE(PathExists(test_root));
  EXPECT_TRUE(DirectoryExists(test_root));
  // Check a file
  FilePath test_path =
      test_root.Append(FILE_PATH_LITERAL("foobar.txt"));
  EXPECT_FALSE(PathExists(test_path));
  CreateTextFile(test_path, L"test file");
  EXPECT_TRUE(PathExists(test_path));
  EXPECT_FALSE(DirectoryExists(test_path));
  EXPECT_TRUE(DeleteFile(test_path, false));

  EXPECT_TRUE(DeleteFile(test_root, true));
}

TEST_F(FileUtilTest, FileEnumeratorTest) {
  // Test an empty directory.
  FileEnumerator f0(temp_dir_.path(), true, FILES_AND_DIRECTORIES);
  EXPECT_EQ(FPL(""), f0.Next().value());
  EXPECT_EQ(FPL(""), f0.Next().value());

  // Test an empty directory, non-recursively, including "..".
  FileEnumerator f0_dotdot(temp_dir_.path(), false,
      FILES_AND_DIRECTORIES | FileEnumerator::INCLUDE_DOT_DOT);
  EXPECT_EQ(temp_dir_.path().Append(FPL("..")).value(),
            f0_dotdot.Next().value());
  EXPECT_EQ(FPL(""), f0_dotdot.Next().value());

  // create the directories
  FilePath dir1 = temp_dir_.path().Append(FPL("dir1"));
  EXPECT_TRUE(CreateDirectory(dir1));
  FilePath dir2 = temp_dir_.path().Append(FPL("dir2"));
  EXPECT_TRUE(CreateDirectory(dir2));
  FilePath dir2inner = dir2.Append(FPL("inner"));
  EXPECT_TRUE(CreateDirectory(dir2inner));

  // create the files
  FilePath dir2file = dir2.Append(FPL("dir2file.txt"));
  CreateTextFile(dir2file, std::wstring());
  FilePath dir2innerfile = dir2inner.Append(FPL("innerfile.txt"));
  CreateTextFile(dir2innerfile, std::wstring());
  FilePath file1 = temp_dir_.path().Append(FPL("file1.txt"));
  CreateTextFile(file1, std::wstring());
  FilePath file2_rel = dir2.Append(FilePath::kParentDirectory)
      .Append(FPL("file2.txt"));
  CreateTextFile(file2_rel, std::wstring());
  FilePath file2_abs = temp_dir_.path().Append(FPL("file2.txt"));

  // Only enumerate files.
  FileEnumerator f1(temp_dir_.path(), true, FileEnumerator::FILES);
  FindResultCollector c1(&f1);
  EXPECT_TRUE(c1.HasFile(file1));
  EXPECT_TRUE(c1.HasFile(file2_abs));
  EXPECT_TRUE(c1.HasFile(dir2file));
  EXPECT_TRUE(c1.HasFile(dir2innerfile));
  EXPECT_EQ(4, c1.size());

  // Only enumerate directories.
  FileEnumerator f2(temp_dir_.path(), true, FileEnumerator::DIRECTORIES);
  FindResultCollector c2(&f2);
  EXPECT_TRUE(c2.HasFile(dir1));
  EXPECT_TRUE(c2.HasFile(dir2));
  EXPECT_TRUE(c2.HasFile(dir2inner));
  EXPECT_EQ(3, c2.size());

  // Only enumerate directories non-recursively.
  FileEnumerator f2_non_recursive(
      temp_dir_.path(), false, FileEnumerator::DIRECTORIES);
  FindResultCollector c2_non_recursive(&f2_non_recursive);
  EXPECT_TRUE(c2_non_recursive.HasFile(dir1));
  EXPECT_TRUE(c2_non_recursive.HasFile(dir2));
  EXPECT_EQ(2, c2_non_recursive.size());

  // Only enumerate directories, non-recursively, including "..".
  FileEnumerator f2_dotdot(temp_dir_.path(), false,
                           FileEnumerator::DIRECTORIES |
                           FileEnumerator::INCLUDE_DOT_DOT);
  FindResultCollector c2_dotdot(&f2_dotdot);
  EXPECT_TRUE(c2_dotdot.HasFile(dir1));
  EXPECT_TRUE(c2_dotdot.HasFile(dir2));
  EXPECT_TRUE(c2_dotdot.HasFile(temp_dir_.path().Append(FPL(".."))));
  EXPECT_EQ(3, c2_dotdot.size());

  // Enumerate files and directories.
  FileEnumerator f3(temp_dir_.path(), true, FILES_AND_DIRECTORIES);
  FindResultCollector c3(&f3);
  EXPECT_TRUE(c3.HasFile(dir1));
  EXPECT_TRUE(c3.HasFile(dir2));
  EXPECT_TRUE(c3.HasFile(file1));
  EXPECT_TRUE(c3.HasFile(file2_abs));
  EXPECT_TRUE(c3.HasFile(dir2file));
  EXPECT_TRUE(c3.HasFile(dir2inner));
  EXPECT_TRUE(c3.HasFile(dir2innerfile));
  EXPECT_EQ(7, c3.size());

  // Non-recursive operation.
  FileEnumerator f4(temp_dir_.path(), false, FILES_AND_DIRECTORIES);
  FindResultCollector c4(&f4);
  EXPECT_TRUE(c4.HasFile(dir2));
  EXPECT_TRUE(c4.HasFile(dir2));
  EXPECT_TRUE(c4.HasFile(file1));
  EXPECT_TRUE(c4.HasFile(file2_abs));
  EXPECT_EQ(4, c4.size());

  // Enumerate with a pattern.
  FileEnumerator f5(temp_dir_.path(), true, FILES_AND_DIRECTORIES, FPL("dir*"));
  FindResultCollector c5(&f5);
  EXPECT_TRUE(c5.HasFile(dir1));
  EXPECT_TRUE(c5.HasFile(dir2));
  EXPECT_TRUE(c5.HasFile(dir2file));
  EXPECT_TRUE(c5.HasFile(dir2inner));
  EXPECT_TRUE(c5.HasFile(dir2innerfile));
  EXPECT_EQ(5, c5.size());

#if defined(OS_WIN)
  {
    // Make dir1 point to dir2.
    ReparsePoint reparse_point(dir1, dir2);
    EXPECT_TRUE(reparse_point.IsValid());

    if ((win::GetVersion() >= win::VERSION_VISTA)) {
      // There can be a delay for the enumeration code to see the change on
      // the file system so skip this test for XP.
      // Enumerate the reparse point.
      FileEnumerator f6(dir1, true, FILES_AND_DIRECTORIES);
      FindResultCollector c6(&f6);
      FilePath inner2 = dir1.Append(FPL("inner"));
      EXPECT_TRUE(c6.HasFile(inner2));
      EXPECT_TRUE(c6.HasFile(inner2.Append(FPL("innerfile.txt"))));
      EXPECT_TRUE(c6.HasFile(dir1.Append(FPL("dir2file.txt"))));
      EXPECT_EQ(3, c6.size());
    }

    // No changes for non recursive operation.
    FileEnumerator f7(temp_dir_.path(), false, FILES_AND_DIRECTORIES);
    FindResultCollector c7(&f7);
    EXPECT_TRUE(c7.HasFile(dir2));
    EXPECT_TRUE(c7.HasFile(dir2));
    EXPECT_TRUE(c7.HasFile(file1));
    EXPECT_TRUE(c7.HasFile(file2_abs));
    EXPECT_EQ(4, c7.size());

    // Should not enumerate inside dir1 when using recursion.
    FileEnumerator f8(temp_dir_.path(), true, FILES_AND_DIRECTORIES);
    FindResultCollector c8(&f8);
    EXPECT_TRUE(c8.HasFile(dir1));
    EXPECT_TRUE(c8.HasFile(dir2));
    EXPECT_TRUE(c8.HasFile(file1));
    EXPECT_TRUE(c8.HasFile(file2_abs));
    EXPECT_TRUE(c8.HasFile(dir2file));
    EXPECT_TRUE(c8.HasFile(dir2inner));
    EXPECT_TRUE(c8.HasFile(dir2innerfile));
    EXPECT_EQ(7, c8.size());
  }
#endif

  // Make sure the destructor closes the find handle while in the middle of a
  // query to allow TearDown to delete the directory.
  FileEnumerator f9(temp_dir_.path(), true, FILES_AND_DIRECTORIES);
  EXPECT_FALSE(f9.Next().value().empty());  // Should have found something
                                            // (we don't care what).
}

TEST_F(FileUtilTest, AppendToFile) {
  FilePath data_dir =
      temp_dir_.path().Append(FILE_PATH_LITERAL("FilePathTest"));

  // Create a fresh, empty copy of this directory.
  if (PathExists(data_dir)) {
    ASSERT_TRUE(DeleteFile(data_dir, true));
  }
  ASSERT_TRUE(CreateDirectory(data_dir));

  // Create a fresh, empty copy of this directory.
  if (PathExists(data_dir)) {
    ASSERT_TRUE(DeleteFile(data_dir, true));
  }
  ASSERT_TRUE(CreateDirectory(data_dir));
  FilePath foobar(data_dir.Append(FILE_PATH_LITERAL("foobar.txt")));

  std::string data("hello");
  EXPECT_FALSE(AppendToFile(foobar, data.c_str(), data.size()));
  EXPECT_EQ(static_cast<int>(data.length()),
            WriteFile(foobar, data.c_str(), data.length()));
  EXPECT_TRUE(AppendToFile(foobar, data.c_str(), data.size()));

  const std::wstring read_content = ReadTextFile(foobar);
  EXPECT_EQ(L"hellohello", read_content);
}

TEST_F(FileUtilTest, ReadFile) {
  // Create a test file to be read.
  const std::string kTestData("The quick brown fox jumps over the lazy dog.");
  FilePath file_path =
      temp_dir_.path().Append(FILE_PATH_LITERAL("ReadFileTest"));

  ASSERT_EQ(static_cast<int>(kTestData.size()),
            WriteFile(file_path, kTestData.data(), kTestData.size()));

  // Make buffers with various size.
  std::vector<char> small_buffer(kTestData.size() / 2);
  std::vector<char> exact_buffer(kTestData.size());
  std::vector<char> large_buffer(kTestData.size() * 2);

  // Read the file with smaller buffer.
  int bytes_read_small = ReadFile(
      file_path, &small_buffer[0], static_cast<int>(small_buffer.size()));
  EXPECT_EQ(static_cast<int>(small_buffer.size()), bytes_read_small);
  EXPECT_EQ(
      std::string(kTestData.begin(), kTestData.begin() + small_buffer.size()),
      std::string(small_buffer.begin(), small_buffer.end()));

  // Read the file with buffer which have exactly same size.
  int bytes_read_exact = ReadFile(
      file_path, &exact_buffer[0], static_cast<int>(exact_buffer.size()));
  EXPECT_EQ(static_cast<int>(kTestData.size()), bytes_read_exact);
  EXPECT_EQ(kTestData, std::string(exact_buffer.begin(), exact_buffer.end()));

  // Read the file with larger buffer.
  int bytes_read_large = ReadFile(
      file_path, &large_buffer[0], static_cast<int>(large_buffer.size()));
  EXPECT_EQ(static_cast<int>(kTestData.size()), bytes_read_large);
  EXPECT_EQ(kTestData, std::string(large_buffer.begin(),
                                   large_buffer.begin() + kTestData.size()));

  // Make sure the return value is -1 if the file doesn't exist.
  FilePath file_path_not_exist =
      temp_dir_.path().Append(FILE_PATH_LITERAL("ReadFileNotExistTest"));
  EXPECT_EQ(-1,
            ReadFile(file_path_not_exist,
                     &exact_buffer[0],
                     static_cast<int>(exact_buffer.size())));
}

TEST_F(FileUtilTest, ReadFileToString) {
  const char kTestData[] = "0123";
  std::string data;

  FilePath file_path =
      temp_dir_.path().Append(FILE_PATH_LITERAL("ReadFileToStringTest"));
  FilePath file_path_dangerous =
      temp_dir_.path().Append(FILE_PATH_LITERAL("..")).
      Append(temp_dir_.path().BaseName()).
      Append(FILE_PATH_LITERAL("ReadFileToStringTest"));

  // Create test file.
  ASSERT_EQ(4, WriteFile(file_path, kTestData, 4));

  EXPECT_TRUE(ReadFileToString(file_path, &data));
  EXPECT_EQ(kTestData, data);

  data = "temp";
  EXPECT_FALSE(ReadFileToString(file_path, &data, 0));
  EXPECT_EQ(0u, data.length());

  data = "temp";
  EXPECT_FALSE(ReadFileToString(file_path, &data, 2));
  EXPECT_EQ("01", data);

  data.clear();
  EXPECT_FALSE(ReadFileToString(file_path, &data, 3));
  EXPECT_EQ("012", data);

  data.clear();
  EXPECT_TRUE(ReadFileToString(file_path, &data, 4));
  EXPECT_EQ("0123", data);

  data.clear();
  EXPECT_TRUE(ReadFileToString(file_path, &data, 6));
  EXPECT_EQ("0123", data);

  EXPECT_TRUE(ReadFileToString(file_path, NULL, 6));

  EXPECT_TRUE(ReadFileToString(file_path, NULL));

  data = "temp";
  EXPECT_FALSE(ReadFileToString(file_path_dangerous, &data));
  EXPECT_EQ(0u, data.length());

  // Delete test file.
  EXPECT_TRUE(DeleteFile(file_path, false));

  data = "temp";
  EXPECT_FALSE(ReadFileToString(file_path, &data));
  EXPECT_EQ(0u, data.length());

  data = "temp";
  EXPECT_FALSE(ReadFileToString(file_path, &data, 6));
  EXPECT_EQ(0u, data.length());
}

TEST_F(FileUtilTest, TouchFile) {
  FilePath data_dir =
      temp_dir_.path().Append(FILE_PATH_LITERAL("FilePathTest"));

  // Create a fresh, empty copy of this directory.
  if (PathExists(data_dir)) {
    ASSERT_TRUE(DeleteFile(data_dir, true));
  }
  ASSERT_TRUE(CreateDirectory(data_dir));

  FilePath foobar(data_dir.Append(FILE_PATH_LITERAL("foobar.txt")));
  std::string data("hello");
  ASSERT_TRUE(WriteFile(foobar, data.c_str(), data.length()));

  Time access_time;
  // This timestamp is divisible by one day (in local timezone),
  // to make it work on FAT too.
  ASSERT_TRUE(Time::FromString("Wed, 16 Nov 1994, 00:00:00",
                               &access_time));

  Time modification_time;
  // Note that this timestamp is divisible by two (seconds) - FAT stores
  // modification times with 2s resolution.
  ASSERT_TRUE(Time::FromString("Tue, 15 Nov 1994, 12:45:26 GMT",
              &modification_time));

  ASSERT_TRUE(TouchFile(foobar, access_time, modification_time));
  File::Info file_info;
  ASSERT_TRUE(GetFileInfo(foobar, &file_info));
  EXPECT_EQ(access_time.ToInternalValue(),
            file_info.last_accessed.ToInternalValue());
  EXPECT_EQ(modification_time.ToInternalValue(),
            file_info.last_modified.ToInternalValue());
}

TEST_F(FileUtilTest, IsDirectoryEmpty) {
  FilePath empty_dir = temp_dir_.path().Append(FILE_PATH_LITERAL("EmptyDir"));

  ASSERT_FALSE(PathExists(empty_dir));

  ASSERT_TRUE(CreateDirectory(empty_dir));

  EXPECT_TRUE(IsDirectoryEmpty(empty_dir));

  FilePath foo(empty_dir.Append(FILE_PATH_LITERAL("foo.txt")));
  std::string bar("baz");
  ASSERT_TRUE(WriteFile(foo, bar.c_str(), bar.length()));

  EXPECT_FALSE(IsDirectoryEmpty(empty_dir));
}

#if defined(OS_POSIX)

// Testing VerifyPathControlledByAdmin() is hard, because there is no
// way a test can make a file owned by root, or change file paths
// at the root of the file system.  VerifyPathControlledByAdmin()
// is implemented as a call to VerifyPathControlledByUser, which gives
// us the ability to test with paths under the test's temp directory,
// using a user id we control.
// Pull tests of VerifyPathControlledByUserTest() into a separate test class
// with a common SetUp() method.
class VerifyPathControlledByUserTest : public FileUtilTest {
 protected:
  void SetUp() override {
    FileUtilTest::SetUp();

    // Create a basic structure used by each test.
    // base_dir_
    //  |-> sub_dir_
    //       |-> text_file_

    base_dir_ = temp_dir_.path().AppendASCII("base_dir");
    ASSERT_TRUE(CreateDirectory(base_dir_));

    sub_dir_ = base_dir_.AppendASCII("sub_dir");
    ASSERT_TRUE(CreateDirectory(sub_dir_));

    text_file_ = sub_dir_.AppendASCII("file.txt");
    CreateTextFile(text_file_, L"This text file has some text in it.");

    // Get the user and group files are created with from |base_dir_|.
    struct stat stat_buf;
    ASSERT_EQ(0, stat(base_dir_.value().c_str(), &stat_buf));
    uid_ = stat_buf.st_uid;
    ok_gids_.insert(stat_buf.st_gid);
    bad_gids_.insert(stat_buf.st_gid + 1);

    ASSERT_EQ(uid_, getuid());  // This process should be the owner.

    // To ensure that umask settings do not cause the initial state
    // of permissions to be different from what we expect, explicitly
    // set permissions on the directories we create.
    // Make all files and directories non-world-writable.

    // Users and group can read, write, traverse
    int enabled_permissions =
        FILE_PERMISSION_USER_MASK | FILE_PERMISSION_GROUP_MASK;
    // Other users can't read, write, traverse
    int disabled_permissions = FILE_PERMISSION_OTHERS_MASK;

    ASSERT_NO_FATAL_FAILURE(
        ChangePosixFilePermissions(
            base_dir_, enabled_permissions, disabled_permissions));
    ASSERT_NO_FATAL_FAILURE(
        ChangePosixFilePermissions(
            sub_dir_, enabled_permissions, disabled_permissions));
  }

  FilePath base_dir_;
  FilePath sub_dir_;
  FilePath text_file_;
  uid_t uid_;

  std::set<gid_t> ok_gids_;
  std::set<gid_t> bad_gids_;
};

TEST_F(VerifyPathControlledByUserTest, BadPaths) {
  // File does not exist.
  FilePath does_not_exist = base_dir_.AppendASCII("does")
                                     .AppendASCII("not")
                                     .AppendASCII("exist");
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, does_not_exist, uid_, ok_gids_));

  // |base| not a subpath of |path|.
  EXPECT_FALSE(VerifyPathControlledByUser(sub_dir_, base_dir_, uid_, ok_gids_));

  // An empty base path will fail to be a prefix for any path.
  FilePath empty;
  EXPECT_FALSE(VerifyPathControlledByUser(empty, base_dir_, uid_, ok_gids_));

  // Finding that a bad call fails proves nothing unless a good call succeeds.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
}

TEST_F(VerifyPathControlledByUserTest, Symlinks) {
  // Symlinks in the path should cause failure.

  // Symlink to the file at the end of the path.
  FilePath file_link =  base_dir_.AppendASCII("file_link");
  ASSERT_TRUE(CreateSymbolicLink(text_file_, file_link))
      << "Failed to create symlink.";

  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, file_link, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(file_link, file_link, uid_, ok_gids_));

  // Symlink from one directory to another within the path.
  FilePath link_to_sub_dir =  base_dir_.AppendASCII("link_to_sub_dir");
  ASSERT_TRUE(CreateSymbolicLink(sub_dir_, link_to_sub_dir))
    << "Failed to create symlink.";

  FilePath file_path_with_link = link_to_sub_dir.AppendASCII("file.txt");
  ASSERT_TRUE(PathExists(file_path_with_link));

  EXPECT_FALSE(VerifyPathControlledByUser(base_dir_, file_path_with_link, uid_,
                                          ok_gids_));

  EXPECT_FALSE(VerifyPathControlledByUser(link_to_sub_dir, file_path_with_link,
                                          uid_, ok_gids_));

  // Symlinks in parents of base path are allowed.
  EXPECT_TRUE(VerifyPathControlledByUser(file_path_with_link,
                                         file_path_with_link, uid_, ok_gids_));
}

TEST_F(VerifyPathControlledByUserTest, OwnershipChecks) {
  // Get a uid that is not the uid of files we create.
  uid_t bad_uid = uid_ + 1;

  // Make all files and directories non-world-writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(base_dir_, 0u, S_IWOTH));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(sub_dir_, 0u, S_IWOTH));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(text_file_, 0u, S_IWOTH));

  // We control these paths.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Another user does not control these paths.
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, sub_dir_, bad_uid, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, bad_uid, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, bad_uid, ok_gids_));

  // Another group does not control the paths.
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, bad_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, bad_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, bad_gids_));
}

TEST_F(VerifyPathControlledByUserTest, GroupWriteTest) {
  // Make all files and directories writable only by their owner.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(base_dir_, 0u, S_IWOTH|S_IWGRP));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(sub_dir_, 0u, S_IWOTH|S_IWGRP));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(text_file_, 0u, S_IWOTH|S_IWGRP));

  // Any group is okay because the path is not group-writable.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, bad_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, bad_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, bad_gids_));

  // No group is okay, because we don't check the group
  // if no group can write.
  std::set<gid_t> no_gids;  // Empty set of gids.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, no_gids));
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, text_file_, uid_, no_gids));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, no_gids));

  // Make all files and directories writable by their group.
  ASSERT_NO_FATAL_FAILURE(ChangePosixFilePermissions(base_dir_, S_IWGRP, 0u));
  ASSERT_NO_FATAL_FAILURE(ChangePosixFilePermissions(sub_dir_, S_IWGRP, 0u));
  ASSERT_NO_FATAL_FAILURE(ChangePosixFilePermissions(text_file_, S_IWGRP, 0u));

  // Now |ok_gids_| works, but |bad_gids_| fails.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, bad_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, bad_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, bad_gids_));

  // Because any group in the group set is allowed,
  // the union of good and bad gids passes.

  std::set<gid_t> multiple_gids;
  std::set_union(
      ok_gids_.begin(), ok_gids_.end(),
      bad_gids_.begin(), bad_gids_.end(),
      std::inserter(multiple_gids, multiple_gids.begin()));

  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, multiple_gids));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, multiple_gids));
  EXPECT_TRUE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, multiple_gids));
}

TEST_F(VerifyPathControlledByUserTest, WriteBitChecks) {
  // Make all files and directories non-world-writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(base_dir_, 0u, S_IWOTH));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(sub_dir_, 0u, S_IWOTH));
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(text_file_, 0u, S_IWOTH));

  // Initialy, we control all parts of the path.
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Make base_dir_ world-writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(base_dir_, S_IWOTH, 0u));
  EXPECT_FALSE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Make sub_dir_ world writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(sub_dir_, S_IWOTH, 0u));
  EXPECT_FALSE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Make text_file_ world writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(text_file_, S_IWOTH, 0u));
  EXPECT_FALSE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Make sub_dir_ non-world writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(sub_dir_, 0u, S_IWOTH));
  EXPECT_FALSE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Make base_dir_ non-world-writable.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(base_dir_, 0u, S_IWOTH));
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_FALSE(
      VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));

  // Back to the initial state: Nothing is writable, so every path
  // should pass.
  ASSERT_NO_FATAL_FAILURE(
      ChangePosixFilePermissions(text_file_, 0u, S_IWOTH));
  EXPECT_TRUE(VerifyPathControlledByUser(base_dir_, sub_dir_, uid_, ok_gids_));
  EXPECT_TRUE(
      VerifyPathControlledByUser(base_dir_, text_file_, uid_, ok_gids_));
  EXPECT_TRUE(VerifyPathControlledByUser(sub_dir_, text_file_, uid_, ok_gids_));
}

#if defined(OS_ANDROID)
TEST_F(FileUtilTest, ValidContentUriTest) {
  // Get the test image path.
  FilePath data_dir;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &data_dir));
  data_dir = data_dir.AppendASCII("file_util");
  ASSERT_TRUE(PathExists(data_dir));
  FilePath image_file = data_dir.Append(FILE_PATH_LITERAL("red.png"));
  int64 image_size;
  GetFileSize(image_file, &image_size);
  EXPECT_LT(0, image_size);

  // Insert the image into MediaStore. MediaStore will do some conversions, and
  // return the content URI.
  FilePath path = InsertImageIntoMediaStore(image_file);
  EXPECT_TRUE(path.IsContentUri());
  EXPECT_TRUE(PathExists(path));
  // The file size may not equal to the input image as MediaStore may convert
  // the image.
  int64 content_uri_size;
  GetFileSize(path, &content_uri_size);
  EXPECT_EQ(image_size, content_uri_size);

  // We should be able to read the file.
  char* buffer = new char[image_size];
  File file = OpenContentUriForRead(path);
  EXPECT_TRUE(file.IsValid());
  EXPECT_TRUE(file.ReadAtCurrentPos(buffer, image_size));
  delete[] buffer;
}

TEST_F(FileUtilTest, NonExistentContentUriTest) {
  FilePath path("content://foo.bar");
  EXPECT_TRUE(path.IsContentUri());
  EXPECT_FALSE(PathExists(path));
  // Size should be smaller than 0.
  int64 size;
  EXPECT_FALSE(GetFileSize(path, &size));

  // We should not be able to read the file.
  File file = OpenContentUriForRead(path);
  EXPECT_FALSE(file.IsValid());
}
#endif

TEST(ScopedFD, ScopedFDDoesClose) {
  int fds[2];
  char c = 0;
  ASSERT_EQ(0, pipe(fds));
  const int write_end = fds[1];
  ScopedFD read_end_closer(fds[0]);
  {
    ScopedFD write_end_closer(fds[1]);
  }
  // This is the only thread. This file descriptor should no longer be valid.
  int ret = close(write_end);
  EXPECT_EQ(-1, ret);
  EXPECT_EQ(EBADF, errno);
  // Make sure read(2) won't block.
  ASSERT_EQ(0, fcntl(fds[0], F_SETFL, O_NONBLOCK));
  // Reading the pipe should EOF.
  EXPECT_EQ(0, read(fds[0], &c, 1));
}

#if defined(GTEST_HAS_DEATH_TEST)
void CloseWithScopedFD(int fd) {
  ScopedFD fd_closer(fd);
}
#endif

TEST(ScopedFD, ScopedFDCrashesOnCloseFailure) {
  int fds[2];
  ASSERT_EQ(0, pipe(fds));
  ScopedFD read_end_closer(fds[0]);
  EXPECT_EQ(0, IGNORE_EINTR(close(fds[1])));
#if defined(GTEST_HAS_DEATH_TEST)
  // This is the only thread. This file descriptor should no longer be valid.
  // Trying to close it should crash. This is important for security.
  EXPECT_DEATH(CloseWithScopedFD(fds[1]), "");
#endif
}

#endif  // defined(OS_POSIX)

}  // namespace

}  // namespace base

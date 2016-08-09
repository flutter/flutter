// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <set>
#include <string>
#include <vector>

#include "base/files/file.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/path_service.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"
#include "third_party/zlib/google/zip.h"
#include "third_party/zlib/google/zip_reader.h"

namespace {

// Make the test a PlatformTest to setup autorelease pools properly on Mac.
class ZipTest : public PlatformTest {
 protected:
  enum ValidYearType {
    VALID_YEAR,
    INVALID_YEAR
  };

  virtual void SetUp() {
    PlatformTest::SetUp();

    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
    test_dir_ = temp_dir_.path();

    base::FilePath zip_path(test_dir_);
    zip_contents_.insert(zip_path.AppendASCII("foo.txt"));
    zip_path = zip_path.AppendASCII("foo");
    zip_contents_.insert(zip_path);
    zip_contents_.insert(zip_path.AppendASCII("bar.txt"));
    zip_path = zip_path.AppendASCII("bar");
    zip_contents_.insert(zip_path);
    zip_contents_.insert(zip_path.AppendASCII("baz.txt"));
    zip_contents_.insert(zip_path.AppendASCII("quux.txt"));
    zip_contents_.insert(zip_path.AppendASCII(".hidden"));

    // Include a subset of files in |zip_file_list_| to test ZipFiles().
    zip_file_list_.push_back(base::FilePath(FILE_PATH_LITERAL("foo.txt")));
    zip_file_list_.push_back(
        base::FilePath(FILE_PATH_LITERAL("foo/bar/quux.txt")));
    zip_file_list_.push_back(
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

  void TestUnzipFile(const base::FilePath::StringType& filename,
                     bool expect_hidden_files) {
    base::FilePath test_dir;
    ASSERT_TRUE(GetTestDataDirectory(&test_dir));
    TestUnzipFile(test_dir.Append(filename), expect_hidden_files);
  }

  void TestUnzipFile(const base::FilePath& path, bool expect_hidden_files) {
    ASSERT_TRUE(base::PathExists(path)) << "no file " << path.value();
    ASSERT_TRUE(zip::Unzip(path, test_dir_));

    base::FileEnumerator files(test_dir_, true,
        base::FileEnumerator::FILES | base::FileEnumerator::DIRECTORIES);
    base::FilePath next_path = files.Next();
    size_t count = 0;
    while (!next_path.value().empty()) {
      if (next_path.value().find(FILE_PATH_LITERAL(".svn")) ==
          base::FilePath::StringType::npos) {
        EXPECT_EQ(zip_contents_.count(next_path), 1U) <<
            "Couldn't find " << next_path.value();
        count++;
      }
      next_path = files.Next();
    }

    size_t expected_count = 0;
    for (std::set<base::FilePath>::iterator iter = zip_contents_.begin();
         iter != zip_contents_.end(); ++iter) {
      if (expect_hidden_files || iter->BaseName().value()[0] != '.')
        ++expected_count;
    }

    EXPECT_EQ(expected_count, count);
  }

  // This function does the following:
  // 1) Creates a test.txt file with the given last modification timestamp
  // 2) Zips test.txt and extracts it back into a different location.
  // 3) Confirms that test.txt in the output directory has the specified
  //    last modification timestamp if it is valid (|valid_year| is true).
  //    If the timestamp is not supported by the zip format, the last
  //    modification defaults to the current time.
  void TestTimeStamp(const char* date_time, ValidYearType valid_year) {
    SCOPED_TRACE(std::string("TestTimeStamp(") + date_time + ")");
    base::ScopedTempDir temp_dir;
    ASSERT_TRUE(temp_dir.CreateUniqueTempDir());

    base::FilePath zip_file = temp_dir.path().AppendASCII("out.zip");
    base::FilePath src_dir = temp_dir.path().AppendASCII("input");
    base::FilePath out_dir = temp_dir.path().AppendASCII("output");

    base::FilePath src_file = src_dir.AppendASCII("test.txt");
    base::FilePath out_file = out_dir.AppendASCII("test.txt");

    EXPECT_TRUE(base::CreateDirectory(src_dir));
    EXPECT_TRUE(base::CreateDirectory(out_dir));

    base::Time test_mtime;
    ASSERT_TRUE(base::Time::FromString(date_time, &test_mtime));

    // Adjusting the current timestamp to the resolution that the zip file
    // supports, which is 2 seconds. Note that between this call to Time::Now()
    // and zip::Zip() the clock can advance a bit, hence the use of EXPECT_GE.
    base::Time::Exploded now_parts;
    base::Time::Now().LocalExplode(&now_parts);
    now_parts.second = now_parts.second & ~1;
    now_parts.millisecond = 0;
    base::Time now_time = base::Time::FromLocalExploded(now_parts);

    EXPECT_EQ(1, base::WriteFile(src_file, "1", 1));
    EXPECT_TRUE(base::TouchFile(src_file, base::Time::Now(), test_mtime));

    EXPECT_TRUE(zip::Zip(src_dir, zip_file, true));
    ASSERT_TRUE(zip::Unzip(zip_file, out_dir));

    base::File::Info file_info;
    EXPECT_TRUE(base::GetFileInfo(out_file, &file_info));
    EXPECT_EQ(file_info.size, 1);

    if (valid_year == VALID_YEAR) {
      EXPECT_EQ(file_info.last_modified, test_mtime);
    } else {
      // Invalid date means the modification time will default to 'now'.
      EXPECT_GE(file_info.last_modified, now_time);
    }
  }

  // The path to temporary directory used to contain the test operations.
  base::FilePath test_dir_;

  base::ScopedTempDir temp_dir_;

  // Hard-coded contents of a known zip file.
  std::set<base::FilePath> zip_contents_;

  // Hard-coded list of relative paths for a zip file created with ZipFiles.
  std::vector<base::FilePath> zip_file_list_;
};

TEST_F(ZipTest, Unzip) {
  TestUnzipFile(FILE_PATH_LITERAL("test.zip"), true);
}

TEST_F(ZipTest, UnzipUncompressed) {
  TestUnzipFile(FILE_PATH_LITERAL("test_nocompress.zip"), true);
}

TEST_F(ZipTest, UnzipEvil) {
  base::FilePath path;
  ASSERT_TRUE(GetTestDataDirectory(&path));
  path = path.AppendASCII("evil.zip");
  // Unzip the zip file into a sub directory of test_dir_ so evil.zip
  // won't create a persistent file outside test_dir_ in case of a
  // failure.
  base::FilePath output_dir = test_dir_.AppendASCII("out");
  ASSERT_FALSE(zip::Unzip(path, output_dir));
  base::FilePath evil_file = output_dir;
  evil_file = evil_file.AppendASCII(
      "../levilevilevilevilevilevilevilevilevilevilevilevil");
  ASSERT_FALSE(base::PathExists(evil_file));
}

TEST_F(ZipTest, UnzipEvil2) {
  base::FilePath path;
  ASSERT_TRUE(GetTestDataDirectory(&path));
  // The zip file contains an evil file with invalid UTF-8 in its file
  // name.
  path = path.AppendASCII("evil_via_invalid_utf8.zip");
  // See the comment at UnzipEvil() for why we do this.
  base::FilePath output_dir = test_dir_.AppendASCII("out");
  // This should fail as it contains an evil file.
  ASSERT_FALSE(zip::Unzip(path, output_dir));
  base::FilePath evil_file = output_dir;
  evil_file = evil_file.AppendASCII("../evil.txt");
  ASSERT_FALSE(base::PathExists(evil_file));
}

TEST_F(ZipTest, Zip) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath zip_file = temp_dir.path().AppendASCII("out.zip");

  EXPECT_TRUE(zip::Zip(src_dir, zip_file, true));
  TestUnzipFile(zip_file, true);
}

TEST_F(ZipTest, ZipIgnoreHidden) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath zip_file = temp_dir.path().AppendASCII("out.zip");

  EXPECT_TRUE(zip::Zip(src_dir, zip_file, false));
  TestUnzipFile(zip_file, false);
}

TEST_F(ZipTest, ZipNonASCIIDir) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  // Append 'Тест' (in cyrillic).
  base::FilePath src_dir_russian =
      temp_dir.path().Append(base::FilePath::FromUTF8Unsafe(
          "\xD0\xA2\xD0\xB5\xD1\x81\xD1\x82"));
  base::CopyDirectory(src_dir, src_dir_russian, true);
  base::FilePath zip_file = temp_dir.path().AppendASCII("out_russian.zip");

  EXPECT_TRUE(zip::Zip(src_dir_russian, zip_file, true));
  TestUnzipFile(zip_file, true);
}

TEST_F(ZipTest, ZipTimeStamp) {
  // The dates tested are arbitrary, with some constraints. The zip format can
  // only store years from 1980 to 2107 and an even number of seconds, due to it
  // using the ms dos date format.

  // Valid arbitrary date.
  TestTimeStamp("23 Oct 1997 23:22:20", VALID_YEAR);

  // Date before 1980, zip format limitation, must default to unix epoch.
  TestTimeStamp("29 Dec 1979 21:00:10", INVALID_YEAR);

  // Despite the minizip headers telling the maximum year should be 2044, it
  // can actually go up to 2107. Beyond that, the dos date format cannot store
  // the year (2107-1980=127). To test that limit, the input file needs to be
  // touched, but the code that modifies the file access and modification times
  // relies on time_t which is defined as long, therefore being in many
  // platforms just a 4-byte integer, like 32-bit Mac OSX or linux. As such, it
  // suffers from the year-2038 bug. Therefore 2038 is the highest we can test
  // in all platforms reliably.
  TestTimeStamp("02 Jan 2038 23:59:58", VALID_YEAR);
}

#if defined(OS_POSIX)
TEST_F(ZipTest, ZipFiles) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath zip_name = temp_dir.path().AppendASCII("out.zip");

  base::File zip_file(zip_name,
                      base::File::FLAG_CREATE | base::File::FLAG_WRITE);
  ASSERT_TRUE(zip_file.IsValid());
  EXPECT_TRUE(zip::ZipFiles(src_dir, zip_file_list_,
                            zip_file.GetPlatformFile()));
  zip_file.Close();

  zip::ZipReader reader;
  EXPECT_TRUE(reader.Open(zip_name));
  EXPECT_EQ(zip_file_list_.size(), static_cast<size_t>(reader.num_entries()));
  for (size_t i = 0; i < zip_file_list_.size(); ++i) {
    EXPECT_TRUE(reader.LocateAndOpenEntry(zip_file_list_[i]));
    // Check the path in the entry just in case.
    const zip::ZipReader::EntryInfo* entry_info = reader.current_entry_info();
    EXPECT_EQ(entry_info->file_path(), zip_file_list_[i]);
  }
}
#endif  // defined(OS_POSIX)

TEST_F(ZipTest, UnzipFilesWithIncorrectSize) {
  base::FilePath test_data_folder;
  ASSERT_TRUE(GetTestDataDirectory(&test_data_folder));

  // test_mismatch_size.zip contains files with names from 0.txt to 7.txt with
  // sizes from 0 to 7 bytes respectively, but the metadata in the zip file says
  // the uncompressed size is 3 bytes. The ZipReader and minizip code needs to
  // be clever enough to get all the data out.
  base::FilePath test_zip_file =
      test_data_folder.AppendASCII("test_mismatch_size.zip");

  base::ScopedTempDir scoped_temp_dir;
  ASSERT_TRUE(scoped_temp_dir.CreateUniqueTempDir());
  const base::FilePath& temp_dir = scoped_temp_dir.path();

  ASSERT_TRUE(zip::Unzip(test_zip_file, temp_dir));
  EXPECT_TRUE(base::DirectoryExists(temp_dir.AppendASCII("d")));

  for (int i = 0; i < 8; i++) {
    SCOPED_TRACE(base::StringPrintf("Processing %d.txt", i));
    base::FilePath file_path = temp_dir.AppendASCII(
        base::StringPrintf("%d.txt", i));
    int64 file_size = -1;
    EXPECT_TRUE(base::GetFileSize(file_path, &file_size));
    EXPECT_EQ(static_cast<int64>(i), file_size);
  }
}

}  // namespace

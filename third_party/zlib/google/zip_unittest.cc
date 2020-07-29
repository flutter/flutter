// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stddef.h>
#include <stdint.h>

#include <map>
#include <set>
#include <string>
#include <vector>

#include "base/bind.h"
#include "base/files/file.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/path_service.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"
#include "third_party/zlib/google/zip.h"
#include "third_party/zlib/google/zip_reader.h"

namespace {

bool CreateFile(const std::string& content,
                base::FilePath* file_path,
                base::File* file) {
  if (!base::CreateTemporaryFile(file_path))
    return false;

  if (base::WriteFile(*file_path, content.data(), content.size()) == -1)
    return false;

  *file = base::File(
      *file_path, base::File::Flags::FLAG_OPEN | base::File::Flags::FLAG_READ);
  return file->IsValid();
}

// A virtual file system containing:
// /test
// /test/foo.txt
// /test/bar/bar1.txt
// /test/bar/bar2.txt
// Used to test providing a custom zip::FileAccessor when unzipping.
class VirtualFileSystem : public zip::FileAccessor {
 public:
  static constexpr char kFooContent[] = "This is foo.";
  static constexpr char kBar1Content[] = "This is bar.";
  static constexpr char kBar2Content[] = "This is bar too.";

  VirtualFileSystem() {
    base::FilePath test_dir(FILE_PATH_LITERAL("/test"));
    base::FilePath foo_txt_path = test_dir.Append(FILE_PATH_LITERAL("foo.txt"));

    base::FilePath file_path;
    base::File file;
    bool success = CreateFile(kFooContent, &file_path, &file);
    DCHECK(success);
    files_[foo_txt_path] = std::move(file);

    base::FilePath bar_dir = test_dir.Append(FILE_PATH_LITERAL("bar"));
    base::FilePath bar1_txt_path =
        bar_dir.Append(FILE_PATH_LITERAL("bar1.txt"));
    success = CreateFile(kBar1Content, &file_path, &file);
    DCHECK(success);
    files_[bar1_txt_path] = std::move(file);

    base::FilePath bar2_txt_path =
        bar_dir.Append(FILE_PATH_LITERAL("bar2.txt"));
    success = CreateFile(kBar2Content, &file_path, &file);
    DCHECK(success);
    files_[bar2_txt_path] = std::move(file);

    file_tree_[test_dir] = std::vector<DirectoryContentEntry>{
        DirectoryContentEntry(foo_txt_path, /*is_dir=*/false),
        DirectoryContentEntry(bar_dir, /*is_dir=*/true)};
    file_tree_[bar_dir] = std::vector<DirectoryContentEntry>{
        DirectoryContentEntry(bar1_txt_path, /*is_dir=*/false),
        DirectoryContentEntry(bar2_txt_path, /*is_dir=*/false)};
  }
  ~VirtualFileSystem() override = default;

 private:
  std::vector<base::File> OpenFilesForReading(
      const std::vector<base::FilePath>& paths) override {
    std::vector<base::File> files;
    for (const auto& path : paths) {
      auto iter = files_.find(path);
      files.push_back(iter == files_.end() ? base::File()
                                           : std::move(iter->second));
    }
    return files;
  }

  bool DirectoryExists(const base::FilePath& file) override {
    return file_tree_.count(file) == 1 && files_.count(file) == 0;
  }

  std::vector<DirectoryContentEntry> ListDirectoryContent(
      const base::FilePath& dir) override {
    auto iter = file_tree_.find(dir);
    if (iter == file_tree_.end()) {
      NOTREACHED();
      return std::vector<DirectoryContentEntry>();
    }
    return iter->second;
  }

  base::Time GetLastModifiedTime(const base::FilePath& path) override {
    return base::Time::FromDoubleT(172097977);  // Some random date.
  }

  std::map<base::FilePath, std::vector<DirectoryContentEntry>> file_tree_;
  std::map<base::FilePath, base::File> files_;

  DISALLOW_COPY_AND_ASSIGN(VirtualFileSystem);
};

// static
constexpr char VirtualFileSystem::kFooContent[];
constexpr char VirtualFileSystem::kBar1Content[];
constexpr char VirtualFileSystem::kBar2Content[];

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
    test_dir_ = temp_dir_.GetPath();

    base::FilePath zip_path(test_dir_);
    zip_contents_.insert(zip_path.Append(FILE_PATH_LITERAL("foo.txt")));
    zip_path = zip_path.Append(FILE_PATH_LITERAL("foo"));
    zip_contents_.insert(zip_path);
    zip_contents_.insert(zip_path.Append(FILE_PATH_LITERAL("bar.txt")));
    zip_path = zip_path.Append(FILE_PATH_LITERAL("bar"));
    zip_contents_.insert(zip_path);
    zip_contents_.insert(zip_path.Append(FILE_PATH_LITERAL("baz.txt")));
    zip_contents_.insert(zip_path.Append(FILE_PATH_LITERAL("quux.txt")));
    zip_contents_.insert(zip_path.Append(FILE_PATH_LITERAL(".hidden")));

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
    bool success = base::PathService::Get(base::DIR_SOURCE_ROOT, path);
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

    base::FilePath original_dir;
    ASSERT_TRUE(GetTestDataDirectory(&original_dir));
    original_dir = original_dir.AppendASCII("test");

    base::FileEnumerator files(test_dir_, true,
        base::FileEnumerator::FILES | base::FileEnumerator::DIRECTORIES);
    base::FilePath unzipped_entry_path = files.Next();
    size_t count = 0;
    while (!unzipped_entry_path.value().empty()) {
      EXPECT_EQ(zip_contents_.count(unzipped_entry_path), 1U)
          << "Couldn't find " << unzipped_entry_path.value();
      count++;

      if (base::PathExists(unzipped_entry_path) &&
          !base::DirectoryExists(unzipped_entry_path)) {
        // It's a file, check its contents are what we zipped.
        // TODO(774156): figure out why the commented out EXPECT_TRUE below
        // fails on the build bots (but not on the try-bots).
        base::FilePath relative_path;
        bool append_relative_path_success =
            test_dir_.AppendRelativePath(unzipped_entry_path, &relative_path);
        if (!append_relative_path_success) {
          LOG(ERROR) << "Append relative path failed, params: "
                     << test_dir_.value() << " and "
                     << unzipped_entry_path.value();
        }
        base::FilePath original_path = original_dir.Append(relative_path);
        LOG(ERROR) << "Comparing original " << original_path.value()
                   << " and unzipped file " << unzipped_entry_path.value()
                   << " result: "
                   << base::ContentsEqual(original_path, unzipped_entry_path);
        // EXPECT_TRUE(base::ContentsEqual(original_path, unzipped_entry_path))
        //    << "Contents differ between original " << original_path.value()
        //    << " and unzipped file " << unzipped_entry_path.value();
      }
      unzipped_entry_path = files.Next();
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

    base::FilePath zip_file = temp_dir.GetPath().AppendASCII("out.zip");
    base::FilePath src_dir = temp_dir.GetPath().AppendASCII("input");
    base::FilePath out_dir = temp_dir.GetPath().AppendASCII("output");

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
    base::Time now_time;
    EXPECT_TRUE(base::Time::FromLocalExploded(now_parts, &now_time));

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

TEST_F(ZipTest, UnzipWithFilter) {
  auto filter = base::BindRepeating([](const base::FilePath& path) {
    return path.BaseName().MaybeAsASCII() == "foo.txt";
  });
  base::FilePath path;
  ASSERT_TRUE(GetTestDataDirectory(&path));
  ASSERT_TRUE(zip::UnzipWithFilterCallback(path.AppendASCII("test.zip"),
                                           test_dir_, filter, false));
  // Only foo.txt should have been extracted. The following paths should not
  // be extracted:
  //   foo/
  //   foo/bar.txt
  //   foo/bar/
  //   foo/bar/.hidden
  //   foo/bar/baz.txt
  //   foo/bar/quux.txt
  ASSERT_TRUE(base::PathExists(test_dir_.AppendASCII("foo.txt")));
  base::FileEnumerator extractedFiles(
      test_dir_,
      false,  // Do not enumerate recursively - the file must be in the root.
      base::FileEnumerator::FileType::FILES);
  int extracted_count = 0;
  while (!extractedFiles.Next().empty())
    ++extracted_count;
  ASSERT_EQ(1, extracted_count);

  base::FileEnumerator extractedDirs(
      test_dir_,
      false,  // Do not enumerate recursively - we require zero directories.
      base::FileEnumerator::FileType::DIRECTORIES);
  extracted_count = 0;
  while (!extractedDirs.Next().empty())
    ++extracted_count;
  ASSERT_EQ(0, extracted_count);
}

TEST_F(ZipTest, UnzipWithDelegates) {
  auto filter =
      base::BindRepeating([](const base::FilePath& path) { return true; });
  auto dir_creator = base::BindRepeating(
      [](const base::FilePath& extract_dir, const base::FilePath& entry_path) {
        return base::CreateDirectory(extract_dir.Append(entry_path));
      },
      test_dir_);
  auto writer = base::BindRepeating(
      [](const base::FilePath& extract_dir, const base::FilePath& entry_path)
          -> std::unique_ptr<zip::WriterDelegate> {
        return std::make_unique<zip::FilePathWriterDelegate>(
            extract_dir.Append(entry_path));
      },
      test_dir_);
  base::FilePath path;
  ASSERT_TRUE(GetTestDataDirectory(&path));
  base::File file(path.AppendASCII("test.zip"),
                  base::File::Flags::FLAG_OPEN | base::File::Flags::FLAG_READ);
  ASSERT_TRUE(zip::UnzipWithFilterAndWriters(file.GetPlatformFile(), writer,
                                             dir_creator, filter, false));
  base::FilePath dir = test_dir_;
  base::FilePath dir_foo = dir.AppendASCII("foo");
  base::FilePath dir_foo_bar = dir_foo.AppendASCII("bar");
  ASSERT_TRUE(base::PathExists(dir.AppendASCII("foo.txt")));
  ASSERT_TRUE(base::PathExists(dir_foo));
  ASSERT_TRUE(base::PathExists(dir_foo.AppendASCII("bar.txt")));
  ASSERT_TRUE(base::PathExists(dir_foo_bar));
  ASSERT_TRUE(base::PathExists(dir_foo_bar.AppendASCII(".hidden")));
  ASSERT_TRUE(base::PathExists(dir_foo_bar.AppendASCII("baz.txt")));
  ASSERT_TRUE(base::PathExists(dir_foo_bar.AppendASCII("quux.txt")));
}

TEST_F(ZipTest, Zip) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath zip_file = temp_dir.GetPath().AppendASCII("out.zip");

  EXPECT_TRUE(zip::Zip(src_dir, zip_file, /*include_hidden_files=*/true));
  TestUnzipFile(zip_file, true);
}

TEST_F(ZipTest, ZipIgnoreHidden) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  base::FilePath zip_file = temp_dir.GetPath().AppendASCII("out.zip");

  EXPECT_TRUE(zip::Zip(src_dir, zip_file, /*include_hidden_files=*/false));
  TestUnzipFile(zip_file, false);
}

TEST_F(ZipTest, ZipNonASCIIDir) {
  base::FilePath src_dir;
  ASSERT_TRUE(GetTestDataDirectory(&src_dir));
  src_dir = src_dir.AppendASCII("test");

  base::ScopedTempDir temp_dir;
  ASSERT_TRUE(temp_dir.CreateUniqueTempDir());
  // Append 'Тест' (in cyrillic).
  base::FilePath src_dir_russian = temp_dir.GetPath().Append(
      base::FilePath::FromUTF8Unsafe("\xD0\xA2\xD0\xB5\xD1\x81\xD1\x82"));
  base::CopyDirectory(src_dir, src_dir_russian, true);
  base::FilePath zip_file = temp_dir.GetPath().AppendASCII("out_russian.zip");

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
  base::FilePath zip_name = temp_dir.GetPath().AppendASCII("out.zip");

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
    EXPECT_TRUE(reader.HasMore());
    EXPECT_TRUE(reader.OpenCurrentEntryInZip());
    const zip::ZipReader::EntryInfo* entry_info = reader.current_entry_info();
    EXPECT_EQ(entry_info->file_path(), zip_file_list_[i]);
    reader.AdvanceToNextEntry();
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
  const base::FilePath& temp_dir = scoped_temp_dir.GetPath();

  ASSERT_TRUE(zip::Unzip(test_zip_file, temp_dir));
  EXPECT_TRUE(base::DirectoryExists(temp_dir.AppendASCII("d")));

  for (int i = 0; i < 8; i++) {
    SCOPED_TRACE(base::StringPrintf("Processing %d.txt", i));
    base::FilePath file_path = temp_dir.AppendASCII(
        base::StringPrintf("%d.txt", i));
    int64_t file_size = -1;
    EXPECT_TRUE(base::GetFileSize(file_path, &file_size));
    EXPECT_EQ(static_cast<int64_t>(i), file_size);
  }
}

TEST_F(ZipTest, ZipWithFileAccessor) {
  base::FilePath zip_file;
  ASSERT_TRUE(base::CreateTemporaryFile(&zip_file));
  zip::ZipParams params(base::FilePath(FILE_PATH_LITERAL("/test")), zip_file);
  params.set_file_accessor(std::make_unique<VirtualFileSystem>());
  ASSERT_TRUE(zip::Zip(params));

  base::ScopedTempDir scoped_temp_dir;
  ASSERT_TRUE(scoped_temp_dir.CreateUniqueTempDir());
  const base::FilePath& temp_dir = scoped_temp_dir.GetPath();
  ASSERT_TRUE(zip::Unzip(zip_file, temp_dir));
  base::FilePath bar_dir = temp_dir.Append(FILE_PATH_LITERAL("bar"));
  EXPECT_TRUE(base::DirectoryExists(bar_dir));
  std::string file_content;
  EXPECT_TRUE(base::ReadFileToString(
      temp_dir.Append(FILE_PATH_LITERAL("foo.txt")), &file_content));
  EXPECT_EQ(VirtualFileSystem::kFooContent, file_content);
  EXPECT_TRUE(base::ReadFileToString(
      bar_dir.Append(FILE_PATH_LITERAL("bar1.txt")), &file_content));
  EXPECT_EQ(VirtualFileSystem::kBar1Content, file_content);
  EXPECT_TRUE(base::ReadFileToString(
      bar_dir.Append(FILE_PATH_LITERAL("bar2.txt")), &file_content));
  EXPECT_EQ(VirtualFileSystem::kBar2Content, file_content);
}

}  // namespace

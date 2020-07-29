// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/zip.h"

#include <list>
#include <string>
#include <vector>

#include "base/bind.h"
#include "base/files/file.h"
#include "base/files/file_enumerator.h"
#include "base/logging.h"
#include "base/memory/ptr_util.h"
#include "base/strings/string_util.h"
#include "build/build_config.h"
#include "third_party/zlib/google/zip_internal.h"
#include "third_party/zlib/google/zip_reader.h"
#include "third_party/zlib/google/zip_writer.h"

namespace zip {
namespace {

bool IsHiddenFile(const base::FilePath& file_path) {
  return file_path.BaseName().value()[0] == '.';
}

bool ExcludeNoFilesFilter(const base::FilePath& file_path) {
  return true;
}

bool ExcludeHiddenFilesFilter(const base::FilePath& file_path) {
  return !IsHiddenFile(file_path);
}

// Creates a directory at |extract_dir|/|entry_path|, including any parents.
bool CreateDirectory(const base::FilePath& extract_dir,
                     const base::FilePath& entry_path) {
  return base::CreateDirectory(extract_dir.Append(entry_path));
}

// Creates a WriterDelegate that can write a file at |extract_dir|/|entry_path|.
std::unique_ptr<WriterDelegate> CreateFilePathWriterDelegate(
    const base::FilePath& extract_dir,
    const base::FilePath& entry_path) {
  return std::make_unique<FilePathWriterDelegate>(
      extract_dir.Append(entry_path));
}

class DirectFileAccessor : public FileAccessor {
 public:
  explicit DirectFileAccessor(base::FilePath src_dir) : src_dir_(src_dir) {}
  ~DirectFileAccessor() override = default;

  std::vector<base::File> OpenFilesForReading(
      const std::vector<base::FilePath>& paths) override {
    std::vector<base::File> files;
    for (const auto& path : paths) {
      base::File file;
      if (base::PathExists(path) && !base::DirectoryExists(path)) {
        file = base::File(path, base::File::FLAG_OPEN | base::File::FLAG_READ);
      }
      files.push_back(std::move(file));
    }
    return files;
  }

  bool DirectoryExists(const base::FilePath& file) override {
    return base::DirectoryExists(file);
  }

  std::vector<DirectoryContentEntry> ListDirectoryContent(
      const base::FilePath& dir) override {
    std::vector<DirectoryContentEntry> files;
    base::FileEnumerator file_enumerator(
        dir, false /* recursive */,
        base::FileEnumerator::FILES | base::FileEnumerator::DIRECTORIES);
    for (base::FilePath path = file_enumerator.Next(); !path.value().empty();
         path = file_enumerator.Next()) {
      files.push_back(DirectoryContentEntry(path, base::DirectoryExists(path)));
    }
    return files;
  }

  base::Time GetLastModifiedTime(const base::FilePath& path) override {
    base::File::Info file_info;
    if (!base::GetFileInfo(path, &file_info)) {
      LOG(ERROR) << "Failed to retrieve file modification time for "
                 << path.value();
    }
    return file_info.last_modified;
  }

 private:
  base::FilePath src_dir_;

  DISALLOW_COPY_AND_ASSIGN(DirectFileAccessor);
};

}  // namespace

ZipParams::ZipParams(const base::FilePath& src_dir,
                     const base::FilePath& dest_file)
    : src_dir_(src_dir),
      dest_file_(dest_file),
      file_accessor_(new DirectFileAccessor(src_dir)) {}

#if defined(OS_POSIX)
// Does not take ownership of |fd|.
ZipParams::ZipParams(const base::FilePath& src_dir, int dest_fd)
    : src_dir_(src_dir),
      dest_fd_(dest_fd),
      file_accessor_(new DirectFileAccessor(src_dir)) {}
#endif

bool Zip(const ZipParams& params) {
  // Using a pointer to avoid copies of a potentially large array.
  const std::vector<base::FilePath>* files_to_add = &params.files_to_zip();
  std::vector<base::FilePath> all_files;
  if (files_to_add->empty()) {
    // Include all files from the src_dir (modulo the src_dir itself and
    // filtered and hidden files).

    files_to_add = &all_files;
    // Using a list so we can call push_back while iterating.
    std::list<FileAccessor::DirectoryContentEntry> entries;
    entries.push_back(FileAccessor::DirectoryContentEntry(
        params.src_dir(), true /* is directory*/));
    const FilterCallback& filter_callback = params.filter_callback();
    for (auto iter = entries.begin(); iter != entries.end(); ++iter) {
      const base::FilePath& entry_path = iter->path;
      if (iter != entries.begin() &&  // Don't filter the root dir.
          ((!params.include_hidden_files() && IsHiddenFile(entry_path)) ||
           (filter_callback && !filter_callback.Run(entry_path)))) {
        continue;
      }

      if (iter != entries.begin()) {  // Exclude the root dir from the ZIP file.
        // Make the path relative for AddEntryToZip.
        base::FilePath relative_path;
        bool success =
            params.src_dir().AppendRelativePath(entry_path, &relative_path);
        DCHECK(success);
        all_files.push_back(relative_path);
      }

      if (iter->is_directory) {
        std::vector<FileAccessor::DirectoryContentEntry> subentries =
            params.file_accessor()->ListDirectoryContent(entry_path);
        entries.insert(entries.end(), subentries.begin(), subentries.end());
      }
    }
  }

  std::unique_ptr<internal::ZipWriter> zip_writer;
#if defined(OS_POSIX)
  if (params.dest_fd() != base::kInvalidPlatformFile) {
    DCHECK(params.dest_file().empty());
    zip_writer = internal::ZipWriter::CreateWithFd(
        params.dest_fd(), params.src_dir(), params.file_accessor());
    if (!zip_writer)
      return false;
  }
#endif
  if (!zip_writer) {
    zip_writer = internal::ZipWriter::Create(
        params.dest_file(), params.src_dir(), params.file_accessor());
    if (!zip_writer)
      return false;
  }
  return zip_writer->WriteEntries(*files_to_add);
}

bool Unzip(const base::FilePath& src_file, const base::FilePath& dest_dir) {
  return UnzipWithFilterCallback(
      src_file, dest_dir, base::BindRepeating(&ExcludeNoFilesFilter), true);
}

bool UnzipWithFilterCallback(const base::FilePath& src_file,
                             const base::FilePath& dest_dir,
                             const FilterCallback& filter_cb,
                             bool log_skipped_files) {
  base::File file(src_file, base::File::FLAG_OPEN | base::File::FLAG_READ);
  if (!file.IsValid()) {
    DLOG(WARNING) << "Failed to open " << src_file.value();
    return false;
  }
  return UnzipWithFilterAndWriters(
      file.GetPlatformFile(),
      base::BindRepeating(&CreateFilePathWriterDelegate, dest_dir),
      base::BindRepeating(&CreateDirectory, dest_dir), filter_cb,
      log_skipped_files);
}

bool UnzipWithFilterAndWriters(const base::PlatformFile& src_file,
                               const WriterFactory& writer_factory,
                               const DirectoryCreator& directory_creator,
                               const FilterCallback& filter_cb,
                               bool log_skipped_files) {
  ZipReader reader;
  if (!reader.OpenFromPlatformFile(src_file)) {
    DLOG(WARNING) << "Failed to open src_file " << src_file;
    return false;
  }
  while (reader.HasMore()) {
    if (!reader.OpenCurrentEntryInZip()) {
      DLOG(WARNING) << "Failed to open the current file in zip";
      return false;
    }
    const base::FilePath& entry_path = reader.current_entry_info()->file_path();
    if (reader.current_entry_info()->is_unsafe()) {
      DLOG(WARNING) << "Found an unsafe file in zip " << entry_path;
      return false;
    }
    if (filter_cb.Run(entry_path)) {
      if (reader.current_entry_info()->is_directory()) {
        if (!directory_creator.Run(entry_path))
          return false;
      } else {
        std::unique_ptr<WriterDelegate> writer = writer_factory.Run(entry_path);
        if (!reader.ExtractCurrentEntry(writer.get(),
                                        std::numeric_limits<uint64_t>::max())) {
          DLOG(WARNING) << "Failed to extract " << entry_path;
          return false;
        }
      }
    } else if (log_skipped_files) {
      DLOG(WARNING) << "Skipped file " << entry_path;
    }

    if (!reader.AdvanceToNextEntry()) {
      DLOG(WARNING) << "Failed to advance to the next file";
      return false;
    }
  }
  return true;
}

bool ZipWithFilterCallback(const base::FilePath& src_dir,
                           const base::FilePath& dest_file,
                           const FilterCallback& filter_cb) {
  DCHECK(base::DirectoryExists(src_dir));
  ZipParams params(src_dir, dest_file);
  params.set_filter_callback(filter_cb);
  return Zip(params);
}

bool Zip(const base::FilePath& src_dir, const base::FilePath& dest_file,
         bool include_hidden_files) {
  if (include_hidden_files) {
    return ZipWithFilterCallback(src_dir, dest_file,
                                 base::BindRepeating(&ExcludeNoFilesFilter));
  } else {
    return ZipWithFilterCallback(
        src_dir, dest_file, base::BindRepeating(&ExcludeHiddenFilesFilter));
  }
}

#if defined(OS_POSIX)
bool ZipFiles(const base::FilePath& src_dir,
              const std::vector<base::FilePath>& src_relative_paths,
              int dest_fd) {
  DCHECK(base::DirectoryExists(src_dir));
  ZipParams params(src_dir, dest_fd);
  params.set_files_to_zip(src_relative_paths);
  return Zip(params);
}
#endif  // defined(OS_POSIX)

}  // namespace zip

// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/zlib/google/zip_reader.h"

#include <utility>

#include "base/bind.h"
#include "base/files/file.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/threading/thread_task_runner_handle.h"
#include "build/build_config.h"
#include "third_party/zlib/google/zip_internal.h"

#if defined(USE_SYSTEM_MINIZIP)
#include <minizip/unzip.h>
#else
#include "third_party/zlib/contrib/minizip/unzip.h"
#if defined(OS_WIN)
#include "third_party/zlib/contrib/minizip/iowin32.h"
#endif  // defined(OS_WIN)
#endif  // defined(USE_SYSTEM_MINIZIP)

namespace zip {

namespace {

// StringWriterDelegate --------------------------------------------------------

// A writer delegate that writes no more than |max_read_bytes| to a given
// std::string.
class StringWriterDelegate : public WriterDelegate {
 public:
  StringWriterDelegate(size_t max_read_bytes, std::string* output);
  ~StringWriterDelegate() override;

  // WriterDelegate methods:

  // Returns true.
  bool PrepareOutput() override;

  // Appends |num_bytes| bytes from |data| to the output string. Returns false
  // if |num_bytes| will cause the string to exceed |max_read_bytes|.
  bool WriteBytes(const char* data, int num_bytes) override;

  void SetTimeModified(const base::Time& time) override;

 private:
  size_t max_read_bytes_;
  std::string* output_;

  DISALLOW_COPY_AND_ASSIGN(StringWriterDelegate);
};

StringWriterDelegate::StringWriterDelegate(size_t max_read_bytes,
                                           std::string* output)
    : max_read_bytes_(max_read_bytes),
      output_(output) {
}

StringWriterDelegate::~StringWriterDelegate() {
}

bool StringWriterDelegate::PrepareOutput() {
  return true;
}

bool StringWriterDelegate::WriteBytes(const char* data, int num_bytes) {
  if (output_->size() + num_bytes > max_read_bytes_)
    return false;
  output_->append(data, num_bytes);
  return true;
}

void StringWriterDelegate::SetTimeModified(const base::Time& time) {
  // Do nothing.
}

}  // namespace

// TODO(satorux): The implementation assumes that file names in zip files
// are encoded in UTF-8. This is true for zip files created by Zip()
// function in zip.h, but not true for user-supplied random zip files.
ZipReader::EntryInfo::EntryInfo(const std::string& file_name_in_zip,
                                const unz_file_info& raw_file_info)
    : file_path_(base::FilePath::FromUTF8Unsafe(file_name_in_zip)),
      is_directory_(false),
      is_unsafe_(false),
      is_encrypted_(false) {
  original_size_ = raw_file_info.uncompressed_size;

  // Directory entries in zip files end with "/".
  is_directory_ = base::EndsWith(file_name_in_zip, "/",
                                 base::CompareCase::INSENSITIVE_ASCII);

  // Check the file name here for directory traversal issues.
  is_unsafe_ = file_path_.ReferencesParent();

  // We also consider that the file name is unsafe, if it's invalid UTF-8.
  base::string16 file_name_utf16;
  if (!base::UTF8ToUTF16(file_name_in_zip.data(), file_name_in_zip.size(),
                         &file_name_utf16)) {
    is_unsafe_ = true;
  }

  // We also consider that the file name is unsafe, if it's absolute.
  // On Windows, IsAbsolute() returns false for paths starting with "/".
  if (file_path_.IsAbsolute() ||
      base::StartsWith(file_name_in_zip, "/",
                       base::CompareCase::INSENSITIVE_ASCII))
    is_unsafe_ = true;

  // Whether the file is encrypted is bit 0 of the flag.
  is_encrypted_ = raw_file_info.flag & 1;

  // Construct the last modified time. The timezone info is not present in
  // zip files, so we construct the time as local time.
  base::Time::Exploded exploded_time = {};  // Zero-clear.
  exploded_time.year = raw_file_info.tmu_date.tm_year;
  // The month in zip file is 0-based, whereas ours is 1-based.
  exploded_time.month = raw_file_info.tmu_date.tm_mon + 1;
  exploded_time.day_of_month = raw_file_info.tmu_date.tm_mday;
  exploded_time.hour = raw_file_info.tmu_date.tm_hour;
  exploded_time.minute = raw_file_info.tmu_date.tm_min;
  exploded_time.second = raw_file_info.tmu_date.tm_sec;
  exploded_time.millisecond = 0;

  if (!base::Time::FromLocalExploded(exploded_time, &last_modified_))
    last_modified_ = base::Time::UnixEpoch();
}

ZipReader::ZipReader() {
  Reset();
}

ZipReader::~ZipReader() {
  Close();
}

bool ZipReader::Open(const base::FilePath& zip_file_path) {
  DCHECK(!zip_file_);

  // Use of "Unsafe" function does not look good, but there is no way to do
  // this safely on Linux. See file_util.h for details.
  zip_file_ = internal::OpenForUnzipping(zip_file_path.AsUTF8Unsafe());
  if (!zip_file_) {
    return false;
  }

  return OpenInternal();
}

bool ZipReader::OpenFromPlatformFile(base::PlatformFile zip_fd) {
  DCHECK(!zip_file_);

#if defined(OS_POSIX)
  zip_file_ = internal::OpenFdForUnzipping(zip_fd);
#elif defined(OS_WIN)
  zip_file_ = internal::OpenHandleForUnzipping(zip_fd);
#endif
  if (!zip_file_) {
    return false;
  }

  return OpenInternal();
}

bool ZipReader::OpenFromString(const std::string& data) {
  zip_file_ = internal::PrepareMemoryForUnzipping(data);
  if (!zip_file_)
    return false;
  return OpenInternal();
}

void ZipReader::Close() {
  if (zip_file_) {
    unzClose(zip_file_);
  }
  Reset();
}

bool ZipReader::HasMore() {
  return !reached_end_;
}

bool ZipReader::AdvanceToNextEntry() {
  DCHECK(zip_file_);

  // Should not go further if we already reached the end.
  if (reached_end_)
    return false;

  unz_file_pos position = {};
  if (unzGetFilePos(zip_file_, &position) != UNZ_OK)
    return false;
  const int current_entry_index = position.num_of_file;
  // If we are currently at the last entry, then the next position is the
  // end of the zip file, so mark that we reached the end.
  if (current_entry_index + 1 == num_entries_) {
    reached_end_ = true;
  } else {
    DCHECK_LT(current_entry_index + 1, num_entries_);
    if (unzGoToNextFile(zip_file_) != UNZ_OK) {
      return false;
    }
  }
  current_entry_info_.reset();
  return true;
}

bool ZipReader::OpenCurrentEntryInZip() {
  DCHECK(zip_file_);

  unz_file_info raw_file_info = {};
  char raw_file_name_in_zip[internal::kZipMaxPath] = {};
  const int result = unzGetCurrentFileInfo(zip_file_,
                                           &raw_file_info,
                                           raw_file_name_in_zip,
                                           sizeof(raw_file_name_in_zip) - 1,
                                           NULL,  // extraField.
                                           0,  // extraFieldBufferSize.
                                           NULL,  // szComment.
                                           0);  // commentBufferSize.
  if (result != UNZ_OK)
    return false;
  if (raw_file_name_in_zip[0] == '\0')
    return false;
  current_entry_info_.reset(
      new EntryInfo(raw_file_name_in_zip, raw_file_info));
  return true;
}

bool ZipReader::ExtractCurrentEntry(WriterDelegate* delegate,
                                    uint64_t num_bytes_to_extract) const {
  DCHECK(zip_file_);

  const int open_result = unzOpenCurrentFile(zip_file_);
  if (open_result != UNZ_OK)
    return false;

  if (!delegate->PrepareOutput())
    return false;
  std::unique_ptr<char[]> buf(new char[internal::kZipBufSize]);

  uint64_t remaining_capacity = num_bytes_to_extract;
  bool entire_file_extracted = false;

  while (remaining_capacity > 0) {
    const int num_bytes_read =
        unzReadCurrentFile(zip_file_, buf.get(), internal::kZipBufSize);

    if (num_bytes_read == 0) {
      entire_file_extracted = true;
      break;
    } else if (num_bytes_read < 0) {
      // If num_bytes_read < 0, then it's a specific UNZ_* error code.
      break;
    } else if (num_bytes_read > 0) {
      uint64_t num_bytes_to_write = std::min<uint64_t>(
          remaining_capacity, base::checked_cast<uint64_t>(num_bytes_read));
      if (!delegate->WriteBytes(buf.get(), num_bytes_to_write))
        break;
      if (remaining_capacity == base::checked_cast<uint64_t>(num_bytes_read)) {
        // Ensures function returns true if the entire file has been read.
        entire_file_extracted =
            (unzReadCurrentFile(zip_file_, buf.get(), 1) == 0);
      }
      CHECK_GE(remaining_capacity, num_bytes_to_write);
      remaining_capacity -= num_bytes_to_write;
    }
  }

  unzCloseCurrentFile(zip_file_);

  if (entire_file_extracted &&
      current_entry_info()->last_modified() != base::Time::UnixEpoch()) {
    delegate->SetTimeModified(current_entry_info()->last_modified());
  }

  return entire_file_extracted;
}

void ZipReader::ExtractCurrentEntryToFilePathAsync(
    const base::FilePath& output_file_path,
    SuccessCallback success_callback,
    FailureCallback failure_callback,
    const ProgressCallback& progress_callback) {
  DCHECK(zip_file_);
  DCHECK(current_entry_info_.get());

  // If this is a directory, just create it and return.
  if (current_entry_info()->is_directory()) {
    if (base::CreateDirectory(output_file_path)) {
      base::ThreadTaskRunnerHandle::Get()->PostTask(
          FROM_HERE, std::move(success_callback));
    } else {
      DVLOG(1) << "Unzip failed: unable to create directory.";
      base::ThreadTaskRunnerHandle::Get()->PostTask(
          FROM_HERE, std::move(failure_callback));
    }
    return;
  }

  if (unzOpenCurrentFile(zip_file_) != UNZ_OK) {
    DVLOG(1) << "Unzip failed: unable to open current zip entry.";
    base::ThreadTaskRunnerHandle::Get()->PostTask(FROM_HERE,
                                                  std::move(failure_callback));
    return;
  }

  base::FilePath output_dir_path = output_file_path.DirName();
  if (!base::CreateDirectory(output_dir_path)) {
    DVLOG(1) << "Unzip failed: unable to create containing directory.";
    base::ThreadTaskRunnerHandle::Get()->PostTask(FROM_HERE,
                                                  std::move(failure_callback));
    return;
  }

  const int flags = base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE;
  base::File output_file(output_file_path, flags);

  if (!output_file.IsValid()) {
    DVLOG(1) << "Unzip failed: unable to create platform file at "
             << output_file_path.value();
    base::ThreadTaskRunnerHandle::Get()->PostTask(FROM_HERE,
                                                  std::move(failure_callback));
    return;
  }

  base::ThreadTaskRunnerHandle::Get()->PostTask(
      FROM_HERE,
      base::BindOnce(&ZipReader::ExtractChunk, weak_ptr_factory_.GetWeakPtr(),
                     Passed(std::move(output_file)),
                     std::move(success_callback), std::move(failure_callback),
                     progress_callback, 0 /* initial offset */));
}

bool ZipReader::ExtractCurrentEntryToString(uint64_t max_read_bytes,
                                            std::string* output) const {
  DCHECK(output);
  DCHECK(zip_file_);

  if (max_read_bytes == 0) {
    output->clear();
    return true;
  }

  if (current_entry_info()->is_directory()) {
    output->clear();
    return true;
  }

  // The original_size() is the best hint for the real size, so it saves
  // doing reallocations for the common case when the uncompressed size is
  // correct. However, we need to assume that the uncompressed size could be
  // incorrect therefore this function needs to read as much data as possible.
  std::string contents;
  contents.reserve(
      static_cast<size_t>(std::min(base::checked_cast<int64_t>(max_read_bytes),
                                   current_entry_info()->original_size())));

  StringWriterDelegate writer(max_read_bytes, &contents);
  if (!ExtractCurrentEntry(&writer, max_read_bytes)) {
    if (contents.length() < max_read_bytes) {
      // There was an error in extracting entry. If ExtractCurrentEntry()
      // returns false, the entire file was not read - in which case
      // contents.length() should equal |max_read_bytes| unless an error
      // occurred which caused extraction to be aborted.
      output->clear();
    } else {
      // |num_bytes| is less than the length of current entry.
      output->swap(contents);
    }
    return false;
  }
  output->swap(contents);
  return true;
}

bool ZipReader::OpenInternal() {
  DCHECK(zip_file_);

  unz_global_info zip_info = {};  // Zero-clear.
  if (unzGetGlobalInfo(zip_file_, &zip_info) != UNZ_OK) {
    return false;
  }
  num_entries_ = zip_info.number_entry;
  if (num_entries_ < 0)
    return false;

  // We are already at the end if the zip file is empty.
  reached_end_ = (num_entries_ == 0);
  return true;
}

void ZipReader::Reset() {
  zip_file_ = NULL;
  num_entries_ = 0;
  reached_end_ = false;
  current_entry_info_.reset();
}

void ZipReader::ExtractChunk(base::File output_file,
                             SuccessCallback success_callback,
                             FailureCallback failure_callback,
                             const ProgressCallback& progress_callback,
                             const int64_t offset) {
  char buffer[internal::kZipBufSize];

  const int num_bytes_read = unzReadCurrentFile(zip_file_,
                                                buffer,
                                                internal::kZipBufSize);

  if (num_bytes_read == 0) {
    unzCloseCurrentFile(zip_file_);
    std::move(success_callback).Run();
  } else if (num_bytes_read < 0) {
    DVLOG(1) << "Unzip failed: error while reading zipfile "
             << "(" << num_bytes_read << ")";
    std::move(failure_callback).Run();
  } else {
    if (num_bytes_read != output_file.Write(offset, buffer, num_bytes_read)) {
      DVLOG(1) << "Unzip failed: unable to write all bytes to target.";
      std::move(failure_callback).Run();
      return;
    }

    int64_t current_progress = offset + num_bytes_read;

    progress_callback.Run(current_progress);

    base::ThreadTaskRunnerHandle::Get()->PostTask(
        FROM_HERE,
        base::BindOnce(&ZipReader::ExtractChunk, weak_ptr_factory_.GetWeakPtr(),
                       Passed(std::move(output_file)),
                       std::move(success_callback), std::move(failure_callback),
                       progress_callback, current_progress));
  }
}

// FileWriterDelegate ----------------------------------------------------------

FileWriterDelegate::FileWriterDelegate(base::File* file) : file_(file) {}

FileWriterDelegate::FileWriterDelegate(std::unique_ptr<base::File> file)
    : file_(file.get()), owned_file_(std::move(file)) {}

FileWriterDelegate::~FileWriterDelegate() {
  if (!file_->SetLength(file_length_)) {
    DVPLOG(1) << "Failed updating length of written file";
  }
}

bool FileWriterDelegate::PrepareOutput() {
  return file_->Seek(base::File::FROM_BEGIN, 0) >= 0;
}

bool FileWriterDelegate::WriteBytes(const char* data, int num_bytes) {
  int bytes_written = file_->WriteAtCurrentPos(data, num_bytes);
  if (bytes_written > 0)
    file_length_ += bytes_written;
  return bytes_written == num_bytes;
}

void FileWriterDelegate::SetTimeModified(const base::Time& time) {
  file_->SetTimes(base::Time::Now(), time);
}

// FilePathWriterDelegate ------------------------------------------------------

FilePathWriterDelegate::FilePathWriterDelegate(
    const base::FilePath& output_file_path)
    : output_file_path_(output_file_path) {}

FilePathWriterDelegate::~FilePathWriterDelegate() {}

bool FilePathWriterDelegate::PrepareOutput() {
  // We can't rely on parent directory entries being specified in the
  // zip, so we make sure they are created.
  if (!base::CreateDirectory(output_file_path_.DirName()))
    return false;

  file_.Initialize(output_file_path_,
                   base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE);
  return file_.IsValid();
}

bool FilePathWriterDelegate::WriteBytes(const char* data, int num_bytes) {
  return num_bytes == file_.WriteAtCurrentPos(data, num_bytes);
}

void FilePathWriterDelegate::SetTimeModified(const base::Time& time) {
  file_.Close();
  base::TouchFile(output_file_path_, base::Time::Now(), time);
}

}  // namespace zip

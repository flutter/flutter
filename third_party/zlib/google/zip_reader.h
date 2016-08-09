// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_
#define THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_

#include <string>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"

#if defined(USE_SYSTEM_MINIZIP)
#include <minizip/unzip.h>
#else
#include "third_party/zlib/contrib/minizip/unzip.h"
#endif

namespace zip {

// A delegate interface used to stream out an entry; see
// ZipReader::ExtractCurrentEntry.
class WriterDelegate {
 public:
  virtual ~WriterDelegate() {}

  // Invoked once before any data is streamed out to pave the way (e.g., to open
  // the output file). Return false on failure to cancel extraction.
  virtual bool PrepareOutput() = 0;

  // Invoked to write the next chunk of data. Return false on failure to cancel
  // extraction.
  virtual bool WriteBytes(const char* data, int num_bytes) = 0;
};

// This class is used for reading zip files. A typical use case of this
// class is to scan entries in a zip file and extract them. The code will
// look like:
//
//   ZipReader reader;
//   reader.Open(zip_file_path);
//   while (reader.HasMore()) {
//     reader.OpenCurrentEntryInZip();
//     reader.ExtractCurrentEntryToDirectory(output_directory_path);
//     reader.AdvanceToNextEntry();
//   }
//
// For simplicity, error checking is omitted in the example code above. The
// production code should check return values from all of these functions.
//
// This calls can also be used for random access of contents in a zip file
// using LocateAndOpenEntry().
//
class ZipReader {
 public:
  // A callback that is called when the operation is successful.
  typedef base::Closure SuccessCallback;
  // A callback that is called when the operation fails.
  typedef base::Closure FailureCallback;
  // A callback that is called periodically during the operation with the number
  // of bytes that have been processed so far.
  typedef base::Callback<void(int64)> ProgressCallback;

  // This class represents information of an entry (file or directory) in
  // a zip file.
  class EntryInfo {
   public:
    EntryInfo(const std::string& filename_in_zip,
              const unz_file_info& raw_file_info);

    // Returns the file path. The path is usually relative like
    // "foo/bar.txt", but if it's absolute, is_unsafe() returns true.
    const base::FilePath& file_path() const { return file_path_; }

    // Returns the size of the original file (i.e. after uncompressed).
    // Returns 0 if the entry is a directory.
    // Note: this value should not be trusted, because it is stored as metadata
    // in the zip archive and can be different from the real uncompressed size.
    int64 original_size() const { return original_size_; }

    // Returns the last modified time. If the time stored in the zip file was
    // not valid, the unix epoch will be returned.
    //
    // The time stored in the zip archive uses the MS-DOS date and time format.
    // http://msdn.microsoft.com/en-us/library/ms724247(v=vs.85).aspx
    // As such the following limitations apply:
    // * only years from 1980 to 2107 can be represented.
    // * the time stamp has a 2 second resolution.
    // * there's no timezone information, so the time is interpreted as local.
    base::Time last_modified() const { return last_modified_; }

    // Returns true if the entry is a directory.
    bool is_directory() const { return is_directory_; }

    // Returns true if the entry is unsafe, like having ".." or invalid
    // UTF-8 characters in its file name, or the file path is absolute.
    bool is_unsafe() const { return is_unsafe_; }

   private:
    const base::FilePath file_path_;
    int64 original_size_;
    base::Time last_modified_;
    bool is_directory_;
    bool is_unsafe_;
    DISALLOW_COPY_AND_ASSIGN(EntryInfo);
  };

  ZipReader();
  ~ZipReader();

  // Opens the zip file specified by |zip_file_path|. Returns true on
  // success.
  bool Open(const base::FilePath& zip_file_path);

  // Opens the zip file referred to by the platform file |zip_fd|, without
  // taking ownership of |zip_fd|. Returns true on success.
  bool OpenFromPlatformFile(base::PlatformFile zip_fd);

  // Opens the zip data stored in |data|. This class uses a weak reference to
  // the given sring while extracting files, i.e. the caller should keep the
  // string until it finishes extracting files.
  bool OpenFromString(const std::string& data);

  // Closes the currently opened zip file. This function is called in the
  // destructor of the class, so you usually don't need to call this.
  void Close();

  // Returns true if there is at least one entry to read. This function is
  // used to scan entries with AdvanceToNextEntry(), like:
  //
  // while (reader.HasMore()) {
  //   // Do something with the current file here.
  //   reader.AdvanceToNextEntry();
  // }
  bool HasMore();

  // Advances the next entry. Returns true on success.
  bool AdvanceToNextEntry();

  // Opens the current entry in the zip file. On success, returns true and
  // updates the the current entry state (i.e. current_entry_info() is
  // updated). This function should be called before operations over the
  // current entry like ExtractCurrentEntryToFile().
  //
  // Note that there is no CloseCurrentEntryInZip(). The the current entry
  // state is reset automatically as needed.
  bool OpenCurrentEntryInZip();

  // Locates an entry in the zip file and opens it. Returns true on
  // success. This function internally calls OpenCurrentEntryInZip() on
  // success. On failure, current_entry_info() becomes NULL.
  bool LocateAndOpenEntry(const base::FilePath& path_in_zip);

  // Extracts the current entry in chunks to |delegate|.
  bool ExtractCurrentEntry(WriterDelegate* delegate) const;

  // Extracts the current entry to the given output file path. If the
  // current file is a directory, just creates a directory
  // instead. Returns true on success. OpenCurrentEntryInZip() must be
  // called beforehand.
  //
  // This function preserves the timestamp of the original entry. If that
  // timestamp is not valid, the timestamp will be set to the current time.
  bool ExtractCurrentEntryToFilePath(
      const base::FilePath& output_file_path) const;

  // Asynchronously extracts the current entry to the given output file path.
  // If the current entry is a directory it just creates the directory
  // synchronously instead.  OpenCurrentEntryInZip() must be called beforehand.
  // success_callback will be called on success and failure_callback will be
  // called on failure.  progress_callback will be called at least once.
  // Callbacks will be posted to the current MessageLoop in-order.
  void ExtractCurrentEntryToFilePathAsync(
      const base::FilePath& output_file_path,
      const SuccessCallback& success_callback,
      const FailureCallback& failure_callback,
      const ProgressCallback& progress_callback);

  // Extracts the current entry to the given output directory path using
  // ExtractCurrentEntryToFilePath(). Sub directories are created as needed
  // based on the file path of the current entry. For example, if the file
  // path in zip is "foo/bar.txt", and the output directory is "output",
  // "output/foo/bar.txt" will be created.
  //
  // Returns true on success. OpenCurrentEntryInZip() must be called
  // beforehand.
  //
  // This function preserves the timestamp of the original entry. If that
  // timestamp is not valid, the timestamp will be set to the current time.
  bool ExtractCurrentEntryIntoDirectory(
      const base::FilePath& output_directory_path) const;

  // Extracts the current entry by writing directly to a platform file.
  // Does not close the file. Returns true on success.
  bool ExtractCurrentEntryToFile(base::File* file) const;

  // Extracts the current entry into memory. If the current entry is a directory
  // the |output| parameter is set to the empty string. If the current entry is
  // a file, the |output| parameter is filled with its contents. Returns true on
  // success. OpenCurrentEntryInZip() must be called beforehand.
  // Note: the |output| parameter can be filled with a big amount of data, avoid
  // passing it around by value, but by reference or pointer.
  // Note: the value returned by EntryInfo::original_size() cannot be
  // trusted, so the real size of the uncompressed contents can be different.
  // Use max_read_bytes to limit the ammount of memory used to carry the entry.
  // If the real size of the uncompressed data is bigger than max_read_bytes
  // then false is returned. |max_read_bytes| must be non-zero.
  bool ExtractCurrentEntryToString(
      size_t max_read_bytes,
      std::string* output) const;

  // Returns the current entry info. Returns NULL if the current entry is
  // not yet opened. OpenCurrentEntryInZip() must be called beforehand.
  EntryInfo* current_entry_info() const {
    return current_entry_info_.get();
  }

  // Returns the number of entries in the zip file.
  // Open() must be called beforehand.
  int num_entries() const { return num_entries_; }

 private:
  // Common code used both in Open and OpenFromFd.
  bool OpenInternal();

  // Resets the internal state.
  void Reset();

  // Extracts a chunk of the file to the target.  Will post a task for the next
  // chunk and success/failure/progress callbacks as necessary.
  void ExtractChunk(base::File target_file,
                    const SuccessCallback& success_callback,
                    const FailureCallback& failure_callback,
                    const ProgressCallback& progress_callback,
                    const int64 offset);

  unzFile zip_file_;
  int num_entries_;
  bool reached_end_;
  scoped_ptr<EntryInfo> current_entry_info_;

  base::WeakPtrFactory<ZipReader> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(ZipReader);
};

// A writer delegate that writes to a given File.
class FileWriterDelegate : public WriterDelegate {
 public:
  explicit FileWriterDelegate(base::File* file);

  // Truncates the file to the number of bytes written.
  ~FileWriterDelegate() override;

  // WriterDelegate methods:

  // Seeks to the beginning of the file, returning false if the seek fails.
  bool PrepareOutput() override;

  // Writes |num_bytes| bytes of |data| to the file, returning false on error or
  // if not all bytes could be written.
  bool WriteBytes(const char* data, int num_bytes) override;

 private:
  base::File* file_;
  int64_t file_length_;

  DISALLOW_COPY_AND_ASSIGN(FileWriterDelegate);
};

}  // namespace zip

#endif  // THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_

// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_
#define THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_

#include <stddef.h>
#include <stdint.h>

#include <memory>
#include <string>

#include "base/callback.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/macros.h"
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

  // Sets the last-modified time of the data.
  virtual void SetTimeModified(const base::Time& time) = 0;
};

// This class is used for reading zip files. A typical use case of this
// class is to scan entries in a zip file and extract them. The code will
// look like:
//
//   ZipReader reader;
//   reader.Open(zip_file_path);
//   while (reader.HasMore()) {
//     reader.OpenCurrentEntryInZip();
//     const base::FilePath& entry_path =
//        reader.current_entry_info()->file_path();
//     auto writer = CreateFilePathWriterDelegate(extract_dir, entry_path);
//     reader.ExtractCurrentEntry(writer, std::numeric_limits<uint64_t>::max());
//     reader.AdvanceToNextEntry();
//   }
//
// For simplicity, error checking is omitted in the example code above. The
// production code should check return values from all of these functions.
//
class ZipReader {
 public:
  // A callback that is called when the operation is successful.
  using SuccessCallback = base::OnceClosure;
  // A callback that is called when the operation fails.
  using FailureCallback = base::OnceClosure;
  // A callback that is called periodically during the operation with the number
  // of bytes that have been processed so far.
  using ProgressCallback = base::RepeatingCallback<void(int64_t)>;

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
    int64_t original_size() const { return original_size_; }

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

    // Returns true if the entry is encrypted.
    bool is_encrypted() const { return is_encrypted_; }

   private:
    const base::FilePath file_path_;
    int64_t original_size_;
    base::Time last_modified_;
    bool is_directory_;
    bool is_unsafe_;
    bool is_encrypted_;
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

  // Extracts |num_bytes_to_extract| bytes of the current entry to |delegate|,
  // starting from the beginning of the entry. Return value specifies whether
  // the entire file was extracted.
  bool ExtractCurrentEntry(WriterDelegate* delegate,
                           uint64_t num_bytes_to_extract) const;

  // Asynchronously extracts the current entry to the given output file path.
  // If the current entry is a directory it just creates the directory
  // synchronously instead.  OpenCurrentEntryInZip() must be called beforehand.
  // success_callback will be called on success and failure_callback will be
  // called on failure.  progress_callback will be called at least once.
  // Callbacks will be posted to the current MessageLoop in-order.
  void ExtractCurrentEntryToFilePathAsync(
      const base::FilePath& output_file_path,
      SuccessCallback success_callback,
      FailureCallback failure_callback,
      const ProgressCallback& progress_callback);

  // Extracts the current entry into memory. If the current entry is a
  // directory, the |output| parameter is set to the empty string. If the
  // current entry is a file, the |output| parameter is filled with its
  // contents. OpenCurrentEntryInZip() must be called beforehand. Note: the
  // |output| parameter can be filled with a big amount of data, avoid passing
  // it around by value, but by reference or pointer. Note: the value returned
  // by EntryInfo::original_size() cannot be trusted, so the real size of the
  // uncompressed contents can be different. |max_read_bytes| limits the ammount
  // of memory used to carry the entry. Returns true if the entire content is
  // read. If the entry is bigger than |max_read_bytes|, returns false and
  // |output| is filled with |max_read_bytes| of data. If an error occurs,
  // returns false, and |output| is set to the empty string.
  bool ExtractCurrentEntryToString(uint64_t max_read_bytes,
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
                    SuccessCallback success_callback,
                    FailureCallback failure_callback,
                    const ProgressCallback& progress_callback,
                    const int64_t offset);

  unzFile zip_file_;
  int num_entries_;
  bool reached_end_;
  std::unique_ptr<EntryInfo> current_entry_info_;

  base::WeakPtrFactory<ZipReader> weak_ptr_factory_{this};

  DISALLOW_COPY_AND_ASSIGN(ZipReader);
};

// A writer delegate that writes to a given File.
class FileWriterDelegate : public WriterDelegate {
 public:
  // Constructs a FileWriterDelegate that manipulates |file|. The delegate will
  // not own |file|, therefore the caller must guarantee |file| will outlive the
  // delegate.
  explicit FileWriterDelegate(base::File* file);

  // Constructs a FileWriterDelegate that takes ownership of |file|.
  explicit FileWriterDelegate(std::unique_ptr<base::File> file);

  // Truncates the file to the number of bytes written.
  ~FileWriterDelegate() override;

  // WriterDelegate methods:

  // Seeks to the beginning of the file, returning false if the seek fails.
  bool PrepareOutput() override;

  // Writes |num_bytes| bytes of |data| to the file, returning false on error or
  // if not all bytes could be written.
  bool WriteBytes(const char* data, int num_bytes) override;

  // Sets the last-modified time of the data.
  void SetTimeModified(const base::Time& time) override;

  // Return the actual size of the file.
  int64_t file_length() { return file_length_; }

 private:
  // The file the delegate modifies.
  base::File* file_;

  // The delegate can optionally own the file it modifies, in which case
  // owned_file_ is set and file_ is an alias for owned_file_.
  std::unique_ptr<base::File> owned_file_;

  int64_t file_length_ = 0;

  DISALLOW_COPY_AND_ASSIGN(FileWriterDelegate);
};

// A writer delegate that writes a file at a given path.
class FilePathWriterDelegate : public WriterDelegate {
 public:
  explicit FilePathWriterDelegate(const base::FilePath& output_file_path);
  ~FilePathWriterDelegate() override;

  // WriterDelegate methods:

  // Creates the output file and any necessary intermediate directories.
  bool PrepareOutput() override;

  // Writes |num_bytes| bytes of |data| to the file, returning false if not all
  // bytes could be written.
  bool WriteBytes(const char* data, int num_bytes) override;

  // Sets the last-modified time of the data.
  void SetTimeModified(const base::Time& time) override;

 private:
  base::FilePath output_file_path_;
  base::File file_;

  DISALLOW_COPY_AND_ASSIGN(FilePathWriterDelegate);
};

}  // namespace zip

#endif  // THIRD_PARTY_ZLIB_GOOGLE_ZIP_READER_H_

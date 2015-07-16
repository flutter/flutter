// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_FILE_PROXY_H_
#define BASE_FILES_FILE_PROXY_H_

#include "base/base_export.h"
#include "base/callback_forward.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"

namespace tracked_objects {
class Location;
};

namespace base {

class TaskRunner;
class Time;

// This class provides asynchronous access to a File. All methods follow the
// same rules of the equivalent File method, as they are implemented by bouncing
// the operation to File using a TaskRunner.
//
// This class performs automatic proxying to close the underlying file at
// destruction.
//
// The TaskRunner is in charge of any sequencing of the operations, but a single
// operation can be proxied at a time, regardless of the use of a callback.
// In other words, having a sequence like
//
//   proxy.Write(...);
//   proxy.Write(...);
//
// means the second Write will always fail.
class BASE_EXPORT FileProxy : public SupportsWeakPtr<FileProxy> {
 public:
  // This callback is used by methods that report only an error code. It is
  // valid to pass a null callback to some functions that takes a
  // StatusCallback, in which case the operation will complete silently.
  typedef Callback<void(File::Error)> StatusCallback;

  typedef Callback<void(File::Error,
                        const FilePath&)> CreateTemporaryCallback;
  typedef Callback<void(File::Error,
                        const File::Info&)> GetFileInfoCallback;
  typedef Callback<void(File::Error,
                        const char* data,
                        int bytes_read)> ReadCallback;
  typedef Callback<void(File::Error,
                        int bytes_written)> WriteCallback;

  FileProxy();
  explicit FileProxy(TaskRunner* task_runner);
  ~FileProxy();

  // Creates or opens a file with the given flags. It is invalid to pass a null
  // callback. If File::FLAG_CREATE is set in |file_flags| it always tries to
  // create a new file at the given |file_path| and fails if the file already
  // exists.
  //
  // This returns false if task posting to |task_runner| has failed.
  bool CreateOrOpen(const FilePath& file_path,
                    uint32 file_flags,
                    const StatusCallback& callback);

  // Creates a temporary file for writing. The path and an open file are
  // returned. It is invalid to pass a null callback. The additional file flags
  // will be added on top of the default file flags which are:
  //   File::FLAG_CREATE_ALWAYS
  //   File::FLAG_WRITE
  //   File::FLAG_TEMPORARY.
  //
  // This returns false if task posting to |task_runner| has failed.
  bool CreateTemporary(uint32 additional_file_flags,
                       const CreateTemporaryCallback& callback);

  // Returns true if the underlying |file_| is valid.
  bool IsValid() const;

  // Returns true if a new file was created (or an old one truncated to zero
  // length to simulate a new file), and false otherwise.
  bool created() const { return file_.created(); }

  // Claims ownership of |file|. It is an error to call this method when
  // IsValid() returns true.
  void SetFile(File file);

  File TakeFile();

  PlatformFile GetPlatformFile() const;

  // Proxies File::Close. The callback can be null.
  // This returns false if task posting to |task_runner| has failed.
  bool Close(const StatusCallback& callback);

  // Proxies File::GetInfo. The callback can't be null.
  // This returns false if task posting to |task_runner| has failed.
  bool GetInfo(const GetFileInfoCallback& callback);

  // Proxies File::Read. The callback can't be null.
  // This returns false if |bytes_to_read| is less than zero, or
  // if task posting to |task_runner| has failed.
  bool Read(int64 offset, int bytes_to_read, const ReadCallback& callback);

  // Proxies File::Write. The callback can be null.
  // This returns false if |bytes_to_write| is less than or equal to zero,
  // if |buffer| is NULL, or if task posting to |task_runner| has failed.
  bool Write(int64 offset,
             const char* buffer,
             int bytes_to_write,
             const WriteCallback& callback);

  // Proxies File::SetTimes. The callback can be null.
  // This returns false if task posting to |task_runner| has failed.
  bool SetTimes(Time last_access_time,
                Time last_modified_time,
                const StatusCallback& callback);

  // Proxies File::SetLength. The callback can be null.
  // This returns false if task posting to |task_runner| has failed.
  bool SetLength(int64 length, const StatusCallback& callback);

  // Proxies File::Flush. The callback can be null.
  // This returns false if task posting to |task_runner| has failed.
  bool Flush(const StatusCallback& callback);

 private:
  friend class FileHelper;
  TaskRunner* task_runner() { return task_runner_.get(); }

  scoped_refptr<TaskRunner> task_runner_;
  File file_;
  DISALLOW_COPY_AND_ASSIGN(FileProxy);
};

}  // namespace base

#endif  // BASE_FILES_FILE_PROXY_H_

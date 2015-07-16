// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path_watcher.h"

#include "base/bind.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/thread_task_runner_handle.h"
#include "base/time/time.h"
#include "base/win/object_watcher.h"

namespace base {

namespace {

class FilePathWatcherImpl : public FilePathWatcher::PlatformDelegate,
                            public base::win::ObjectWatcher::Delegate,
                            public MessageLoop::DestructionObserver {
 public:
  FilePathWatcherImpl()
      : handle_(INVALID_HANDLE_VALUE),
        recursive_watch_(false) {}

  // FilePathWatcher::PlatformDelegate overrides.
  bool Watch(const FilePath& path,
             bool recursive,
             const FilePathWatcher::Callback& callback) override;
  void Cancel() override;

  // Deletion of the FilePathWatcher will call Cancel() to dispose of this
  // object in the right thread. This also observes destruction of the required
  // cleanup thread, in case it quits before Cancel() is called.
  void WillDestroyCurrentMessageLoop() override;

  // Callback from MessageLoopForIO.
  void OnObjectSignaled(HANDLE object) override;

 private:
  ~FilePathWatcherImpl() override {}

  // Setup a watch handle for directory |dir|. Set |recursive| to true to watch
  // the directory sub trees. Returns true if no fatal error occurs. |handle|
  // will receive the handle value if |dir| is watchable, otherwise
  // INVALID_HANDLE_VALUE.
  static bool SetupWatchHandle(const FilePath& dir,
                               bool recursive,
                               HANDLE* handle) WARN_UNUSED_RESULT;

  // (Re-)Initialize the watch handle.
  bool UpdateWatch() WARN_UNUSED_RESULT;

  // Destroy the watch handle.
  void DestroyWatch();

  // Cleans up and stops observing the |task_runner_| thread.
  void CancelOnMessageLoopThread() override;

  // Callback to notify upon changes.
  FilePathWatcher::Callback callback_;

  // Path we're supposed to watch (passed to callback).
  FilePath target_;

  // Handle for FindFirstChangeNotification.
  HANDLE handle_;

  // ObjectWatcher to watch handle_ for events.
  base::win::ObjectWatcher watcher_;

  // Set to true to watch the sub trees of the specified directory file path.
  bool recursive_watch_;

  // Keep track of the last modified time of the file.  We use nulltime
  // to represent the file not existing.
  Time last_modified_;

  // The time at which we processed the first notification with the
  // |last_modified_| time stamp.
  Time first_notification_;

  DISALLOW_COPY_AND_ASSIGN(FilePathWatcherImpl);
};

bool FilePathWatcherImpl::Watch(const FilePath& path,
                                bool recursive,
                                const FilePathWatcher::Callback& callback) {
  DCHECK(target_.value().empty());  // Can only watch one path.

  set_task_runner(ThreadTaskRunnerHandle::Get());
  callback_ = callback;
  target_ = path;
  recursive_watch_ = recursive;
  MessageLoop::current()->AddDestructionObserver(this);

  File::Info file_info;
  if (GetFileInfo(target_, &file_info)) {
    last_modified_ = file_info.last_modified;
    first_notification_ = Time::Now();
  }

  if (!UpdateWatch())
    return false;

  watcher_.StartWatching(handle_, this);

  return true;
}

void FilePathWatcherImpl::Cancel() {
  if (callback_.is_null()) {
    // Watch was never called, or the |task_runner_| has already quit.
    set_cancelled();
    return;
  }

  // Switch to the file thread if necessary so we can stop |watcher_|.
  if (!task_runner()->BelongsToCurrentThread()) {
    task_runner()->PostTask(FROM_HERE, Bind(&FilePathWatcher::CancelWatch,
                                            make_scoped_refptr(this)));
  } else {
    CancelOnMessageLoopThread();
  }
}

void FilePathWatcherImpl::CancelOnMessageLoopThread() {
  DCHECK(task_runner()->BelongsToCurrentThread());
  set_cancelled();

  if (handle_ != INVALID_HANDLE_VALUE)
    DestroyWatch();

  if (!callback_.is_null()) {
    MessageLoop::current()->RemoveDestructionObserver(this);
    callback_.Reset();
  }
}

void FilePathWatcherImpl::WillDestroyCurrentMessageLoop() {
  CancelOnMessageLoopThread();
}

void FilePathWatcherImpl::OnObjectSignaled(HANDLE object) {
  DCHECK(object == handle_);
  // Make sure we stay alive through the body of this function.
  scoped_refptr<FilePathWatcherImpl> keep_alive(this);

  if (!UpdateWatch()) {
    callback_.Run(target_, true /* error */);
    return;
  }

  // Check whether the event applies to |target_| and notify the callback.
  File::Info file_info;
  bool file_exists = GetFileInfo(target_, &file_info);
  if (recursive_watch_) {
    // Only the mtime of |target_| is tracked but in a recursive watch,
    // some other file or directory may have changed so all notifications
    // are passed through. It is possible to figure out which file changed
    // using ReadDirectoryChangesW() instead of FindFirstChangeNotification(),
    // but that function is quite complicated:
    // http://qualapps.blogspot.com/2010/05/understanding-readdirectorychangesw.html
    callback_.Run(target_, false);
  } else if (file_exists && (last_modified_.is_null() ||
             last_modified_ != file_info.last_modified)) {
    last_modified_ = file_info.last_modified;
    first_notification_ = Time::Now();
    callback_.Run(target_, false);
  } else if (file_exists && last_modified_ == file_info.last_modified &&
             !first_notification_.is_null()) {
    // The target's last modification time is equal to what's on record. This
    // means that either an unrelated event occurred, or the target changed
    // again (file modification times only have a resolution of 1s). Comparing
    // file modification times against the wall clock is not reliable to find
    // out whether the change is recent, since this code might just run too
    // late. Moreover, there's no guarantee that file modification time and wall
    // clock times come from the same source.
    //
    // Instead, the time at which the first notification carrying the current
    // |last_notified_| time stamp is recorded. Later notifications that find
    // the same file modification time only need to be forwarded until wall
    // clock has advanced one second from the initial notification. After that
    // interval, client code is guaranteed to having seen the current revision
    // of the file.
    if (Time::Now() - first_notification_ > TimeDelta::FromSeconds(1)) {
      // Stop further notifications for this |last_modification_| time stamp.
      first_notification_ = Time();
    }
    callback_.Run(target_, false);
  } else if (!file_exists && !last_modified_.is_null()) {
    last_modified_ = Time();
    callback_.Run(target_, false);
  }

  // The watch may have been cancelled by the callback.
  if (handle_ != INVALID_HANDLE_VALUE)
    watcher_.StartWatching(handle_, this);
}

// static
bool FilePathWatcherImpl::SetupWatchHandle(const FilePath& dir,
                                           bool recursive,
                                           HANDLE* handle) {
  *handle = FindFirstChangeNotification(
      dir.value().c_str(),
      recursive,
      FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_SIZE |
      FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_DIR_NAME |
      FILE_NOTIFY_CHANGE_ATTRIBUTES | FILE_NOTIFY_CHANGE_SECURITY);
  if (*handle != INVALID_HANDLE_VALUE) {
    // Make sure the handle we got points to an existing directory. It seems
    // that windows sometimes hands out watches to directories that are
    // about to go away, but doesn't sent notifications if that happens.
    if (!DirectoryExists(dir)) {
      FindCloseChangeNotification(*handle);
      *handle = INVALID_HANDLE_VALUE;
    }
    return true;
  }

  // If FindFirstChangeNotification failed because the target directory
  // doesn't exist, access is denied (happens if the file is already gone but
  // there are still handles open), or the target is not a directory, try the
  // immediate parent directory instead.
  DWORD error_code = GetLastError();
  if (error_code != ERROR_FILE_NOT_FOUND &&
      error_code != ERROR_PATH_NOT_FOUND &&
      error_code != ERROR_ACCESS_DENIED &&
      error_code != ERROR_SHARING_VIOLATION &&
      error_code != ERROR_DIRECTORY) {
    DPLOG(ERROR) << "FindFirstChangeNotification failed for "
                 << dir.value();
    return false;
  }

  return true;
}

bool FilePathWatcherImpl::UpdateWatch() {
  if (handle_ != INVALID_HANDLE_VALUE)
    DestroyWatch();

  // Start at the target and walk up the directory chain until we succesfully
  // create a watch handle in |handle_|. |child_dirs| keeps a stack of child
  // directories stripped from target, in reverse order.
  std::vector<FilePath> child_dirs;
  FilePath watched_path(target_);
  while (true) {
    if (!SetupWatchHandle(watched_path, recursive_watch_, &handle_))
      return false;

    // Break if a valid handle is returned. Try the parent directory otherwise.
    if (handle_ != INVALID_HANDLE_VALUE)
      break;

    // Abort if we hit the root directory.
    child_dirs.push_back(watched_path.BaseName());
    FilePath parent(watched_path.DirName());
    if (parent == watched_path) {
      DLOG(ERROR) << "Reached the root directory";
      return false;
    }
    watched_path = parent;
  }

  // At this point, handle_ is valid. However, the bottom-up search that the
  // above code performs races against directory creation. So try to walk back
  // down and see whether any children appeared in the mean time.
  while (!child_dirs.empty()) {
    watched_path = watched_path.Append(child_dirs.back());
    child_dirs.pop_back();
    HANDLE temp_handle = INVALID_HANDLE_VALUE;
    if (!SetupWatchHandle(watched_path, recursive_watch_, &temp_handle))
      return false;
    if (temp_handle == INVALID_HANDLE_VALUE)
      break;
    FindCloseChangeNotification(handle_);
    handle_ = temp_handle;
  }

  return true;
}

void FilePathWatcherImpl::DestroyWatch() {
  watcher_.StopWatching();
  FindCloseChangeNotification(handle_);
  handle_ = INVALID_HANDLE_VALUE;
}

}  // namespace

FilePathWatcher::FilePathWatcher() {
  impl_ = new FilePathWatcherImpl();
}

}  // namespace base

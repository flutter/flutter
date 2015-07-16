// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path_watcher.h"
#include "base/files/file_path_watcher_kqueue.h"

#if !defined(OS_IOS)
#include "base/files/file_path_watcher_fsevents.h"
#endif

namespace base {

namespace {

class FilePathWatcherImpl : public FilePathWatcher::PlatformDelegate {
 public:
  bool Watch(const FilePath& path,
             bool recursive,
             const FilePathWatcher::Callback& callback) override {
    // Use kqueue for non-recursive watches and FSEvents for recursive ones.
    DCHECK(!impl_.get());
    if (recursive) {
      if (!FilePathWatcher::RecursiveWatchAvailable())
        return false;
#if !defined(OS_IOS)
      impl_ = new FilePathWatcherFSEvents();
#endif  // OS_IOS
    } else {
      impl_ = new FilePathWatcherKQueue();
    }
    DCHECK(impl_.get());
    return impl_->Watch(path, recursive, callback);
  }

  void Cancel() override {
    if (impl_.get())
      impl_->Cancel();
    set_cancelled();
  }

  void CancelOnMessageLoopThread() override {
    if (impl_.get())
      impl_->Cancel();
    set_cancelled();
  }

 protected:
  ~FilePathWatcherImpl() override {}

  scoped_refptr<PlatformDelegate> impl_;
};

}  // namespace

FilePathWatcher::FilePathWatcher() {
  impl_ = new FilePathWatcherImpl();
}

}  // namespace base

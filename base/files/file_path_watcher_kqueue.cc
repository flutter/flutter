// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path_watcher_kqueue.h"

#include <fcntl.h>
#include <sys/param.h>

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/thread_task_runner_handle.h"

// On some platforms these are not defined.
#if !defined(EV_RECEIPT)
#define EV_RECEIPT 0
#endif
#if !defined(O_EVTONLY)
#define O_EVTONLY O_RDONLY
#endif

namespace base {

FilePathWatcherKQueue::FilePathWatcherKQueue() : kqueue_(-1) {}

FilePathWatcherKQueue::~FilePathWatcherKQueue() {}

void FilePathWatcherKQueue::ReleaseEvent(struct kevent& event) {
  CloseFileDescriptor(&event.ident);
  EventData* entry = EventDataForKevent(event);
  delete entry;
  event.udata = NULL;
}

int FilePathWatcherKQueue::EventsForPath(FilePath path, EventVector* events) {
  DCHECK(MessageLoopForIO::current());
  // Make sure that we are working with a clean slate.
  DCHECK(events->empty());

  std::vector<FilePath::StringType> components;
  path.GetComponents(&components);

  if (components.size() < 1) {
    return -1;
  }

  int last_existing_entry = 0;
  FilePath built_path;
  bool path_still_exists = true;
  for (std::vector<FilePath::StringType>::iterator i = components.begin();
      i != components.end(); ++i) {
    if (i == components.begin()) {
      built_path = FilePath(*i);
    } else {
      built_path = built_path.Append(*i);
    }
    uintptr_t fd = kNoFileDescriptor;
    if (path_still_exists) {
      fd = FileDescriptorForPath(built_path);
      if (fd == kNoFileDescriptor) {
        path_still_exists = false;
      } else {
        ++last_existing_entry;
      }
    }
    FilePath::StringType subdir = (i != (components.end() - 1)) ? *(i + 1) : "";
    EventData* data = new EventData(built_path, subdir);
    struct kevent event;
    EV_SET(&event, fd, EVFILT_VNODE, (EV_ADD | EV_CLEAR | EV_RECEIPT),
           (NOTE_DELETE | NOTE_WRITE | NOTE_ATTRIB |
            NOTE_RENAME | NOTE_REVOKE | NOTE_EXTEND), 0, data);
    events->push_back(event);
  }
  return last_existing_entry;
}

uintptr_t FilePathWatcherKQueue::FileDescriptorForPath(const FilePath& path) {
  int fd = HANDLE_EINTR(open(path.value().c_str(), O_EVTONLY));
  if (fd == -1)
    return kNoFileDescriptor;
  return fd;
}

void FilePathWatcherKQueue::CloseFileDescriptor(uintptr_t* fd) {
  if (*fd == kNoFileDescriptor) {
    return;
  }

  if (IGNORE_EINTR(close(*fd)) != 0) {
    DPLOG(ERROR) << "close";
  }
  *fd = kNoFileDescriptor;
}

bool FilePathWatcherKQueue::AreKeventValuesValid(struct kevent* kevents,
                                               int count) {
  if (count < 0) {
    DPLOG(ERROR) << "kevent";
    return false;
  }
  bool valid = true;
  for (int i = 0; i < count; ++i) {
    if (kevents[i].flags & EV_ERROR && kevents[i].data) {
      // Find the kevent in |events_| that matches the kevent with the error.
      EventVector::iterator event = events_.begin();
      for (; event != events_.end(); ++event) {
        if (event->ident == kevents[i].ident) {
          break;
        }
      }
      std::string path_name;
      if (event != events_.end()) {
        EventData* event_data = EventDataForKevent(*event);
        if (event_data != NULL) {
          path_name = event_data->path_.value();
        }
      }
      if (path_name.empty()) {
        path_name = base::StringPrintf(
            "fd %ld", reinterpret_cast<long>(&kevents[i].ident));
      }
      DLOG(ERROR) << "Error: " << kevents[i].data << " for " << path_name;
      valid = false;
    }
  }
  return valid;
}

void FilePathWatcherKQueue::HandleAttributesChange(
    const EventVector::iterator& event,
    bool* target_file_affected,
    bool* update_watches) {
  EventVector::iterator next_event = event + 1;
  EventData* next_event_data = EventDataForKevent(*next_event);
  // Check to see if the next item in path is still accessible.
  uintptr_t have_access = FileDescriptorForPath(next_event_data->path_);
  if (have_access == kNoFileDescriptor) {
    *target_file_affected = true;
    *update_watches = true;
    EventVector::iterator local_event(event);
    for (; local_event != events_.end(); ++local_event) {
      // Close all nodes from the event down. This has the side effect of
      // potentially rendering other events in |updates| invalid.
      // There is no need to remove the events from |kqueue_| because this
      // happens as a side effect of closing the file descriptor.
      CloseFileDescriptor(&local_event->ident);
    }
  } else {
    CloseFileDescriptor(&have_access);
  }
}

void FilePathWatcherKQueue::HandleDeleteOrMoveChange(
    const EventVector::iterator& event,
    bool* target_file_affected,
    bool* update_watches) {
  *target_file_affected = true;
  *update_watches = true;
  EventVector::iterator local_event(event);
  for (; local_event != events_.end(); ++local_event) {
    // Close all nodes from the event down. This has the side effect of
    // potentially rendering other events in |updates| invalid.
    // There is no need to remove the events from |kqueue_| because this
    // happens as a side effect of closing the file descriptor.
    CloseFileDescriptor(&local_event->ident);
  }
}

void FilePathWatcherKQueue::HandleCreateItemChange(
    const EventVector::iterator& event,
    bool* target_file_affected,
    bool* update_watches) {
  // Get the next item in the path.
  EventVector::iterator next_event = event + 1;
  // Check to see if it already has a valid file descriptor.
  if (!IsKeventFileDescriptorOpen(*next_event)) {
    EventData* next_event_data = EventDataForKevent(*next_event);
    // If not, attempt to open a file descriptor for it.
    next_event->ident = FileDescriptorForPath(next_event_data->path_);
    if (IsKeventFileDescriptorOpen(*next_event)) {
      *update_watches = true;
      if (next_event_data->subdir_.empty()) {
        *target_file_affected = true;
      }
    }
  }
}

bool FilePathWatcherKQueue::UpdateWatches(bool* target_file_affected) {
  // Iterate over events adding kevents for items that exist to the kqueue.
  // Then check to see if new components in the path have been created.
  // Repeat until no new components in the path are detected.
  // This is to get around races in directory creation in a watched path.
  bool update_watches = true;
  while (update_watches) {
    size_t valid;
    for (valid = 0; valid < events_.size(); ++valid) {
      if (!IsKeventFileDescriptorOpen(events_[valid])) {
        break;
      }
    }
    if (valid == 0) {
      // The root of the file path is inaccessible?
      return false;
    }

    EventVector updates(valid);
    int count = HANDLE_EINTR(kevent(kqueue_, &events_[0], valid, &updates[0],
                                    valid, NULL));
    if (!AreKeventValuesValid(&updates[0], count)) {
      return false;
    }
    update_watches = false;
    for (; valid < events_.size(); ++valid) {
      EventData* event_data = EventDataForKevent(events_[valid]);
      events_[valid].ident = FileDescriptorForPath(event_data->path_);
      if (IsKeventFileDescriptorOpen(events_[valid])) {
        update_watches = true;
        if (event_data->subdir_.empty()) {
          *target_file_affected = true;
        }
      } else {
        break;
      }
    }
  }
  return true;
}

void FilePathWatcherKQueue::OnFileCanReadWithoutBlocking(int fd) {
  DCHECK(MessageLoopForIO::current());
  DCHECK_EQ(fd, kqueue_);
  DCHECK(events_.size());

  // Request the file system update notifications that have occurred and return
  // them in |updates|. |count| will contain the number of updates that have
  // occurred.
  EventVector updates(events_.size());
  struct timespec timeout = {0, 0};
  int count = HANDLE_EINTR(kevent(kqueue_, NULL, 0, &updates[0], updates.size(),
                                  &timeout));

  // Error values are stored within updates, so check to make sure that no
  // errors occurred.
  if (!AreKeventValuesValid(&updates[0], count)) {
    callback_.Run(target_, true /* error */);
    Cancel();
    return;
  }

  bool update_watches = false;
  bool send_notification = false;

  // Iterate through each of the updates and react to them.
  for (int i = 0; i < count; ++i) {
    // Find our kevent record that matches the update notification.
    EventVector::iterator event = events_.begin();
    for (; event != events_.end(); ++event) {
      if (!IsKeventFileDescriptorOpen(*event) ||
          event->ident == updates[i].ident) {
        break;
      }
    }
    if (event == events_.end() || !IsKeventFileDescriptorOpen(*event)) {
      // The event may no longer exist in |events_| because another event
      // modified |events_| in such a way to make it invalid. For example if
      // the path is /foo/bar/bam and foo is deleted, NOTE_DELETE events for
      // foo, bar and bam will be sent. If foo is processed first, then
      // the file descriptors for bar and bam will already be closed and set
      // to -1 before they get a chance to be processed.
      continue;
    }

    EventData* event_data = EventDataForKevent(*event);

    // If the subdir is empty, this is the last item on the path and is the
    // target file.
    bool target_file_affected = event_data->subdir_.empty();
    if ((updates[i].fflags & NOTE_ATTRIB) && !target_file_affected) {
      HandleAttributesChange(event, &target_file_affected, &update_watches);
    }
    if (updates[i].fflags & (NOTE_DELETE | NOTE_REVOKE | NOTE_RENAME)) {
      HandleDeleteOrMoveChange(event, &target_file_affected, &update_watches);
    }
    if ((updates[i].fflags & NOTE_WRITE) && !target_file_affected) {
      HandleCreateItemChange(event, &target_file_affected, &update_watches);
    }
    send_notification |= target_file_affected;
  }

  if (update_watches) {
    if (!UpdateWatches(&send_notification)) {
      callback_.Run(target_, true /* error */);
      Cancel();
    }
  }

  if (send_notification) {
    callback_.Run(target_, false);
  }
}

void FilePathWatcherKQueue::OnFileCanWriteWithoutBlocking(int fd) {
  NOTREACHED();
}

void FilePathWatcherKQueue::WillDestroyCurrentMessageLoop() {
  CancelOnMessageLoopThread();
}

bool FilePathWatcherKQueue::Watch(const FilePath& path,
                                  bool recursive,
                                  const FilePathWatcher::Callback& callback) {
  DCHECK(MessageLoopForIO::current());
  DCHECK(target_.value().empty());  // Can only watch one path.
  DCHECK(!callback.is_null());
  DCHECK_EQ(kqueue_, -1);

  if (recursive) {
    // Recursive watch is not supported using kqueue.
    NOTIMPLEMENTED();
    return false;
  }

  callback_ = callback;
  target_ = path;

  MessageLoop::current()->AddDestructionObserver(this);
  io_task_runner_ = ThreadTaskRunnerHandle::Get();

  kqueue_ = kqueue();
  if (kqueue_ == -1) {
    DPLOG(ERROR) << "kqueue";
    return false;
  }

  int last_entry = EventsForPath(target_, &events_);
  DCHECK_NE(last_entry, 0);

  EventVector responses(last_entry);

  int count = HANDLE_EINTR(kevent(kqueue_, &events_[0], last_entry,
                                  &responses[0], last_entry, NULL));
  if (!AreKeventValuesValid(&responses[0], count)) {
    // Calling Cancel() here to close any file descriptors that were opened.
    // This would happen in the destructor anyways, but FilePathWatchers tend to
    // be long lived, and if an error has occurred, there is no reason to waste
    // the file descriptors.
    Cancel();
    return false;
  }

  return MessageLoopForIO::current()->WatchFileDescriptor(
      kqueue_, true, MessageLoopForIO::WATCH_READ, &kqueue_watcher_, this);
}

void FilePathWatcherKQueue::Cancel() {
  SingleThreadTaskRunner* task_runner = io_task_runner_.get();
  if (!task_runner) {
    set_cancelled();
    return;
  }
  if (!task_runner->BelongsToCurrentThread()) {
    task_runner->PostTask(FROM_HERE,
                          base::Bind(&FilePathWatcherKQueue::Cancel, this));
    return;
  }
  CancelOnMessageLoopThread();
}

void FilePathWatcherKQueue::CancelOnMessageLoopThread() {
  DCHECK(MessageLoopForIO::current());
  if (!is_cancelled()) {
    set_cancelled();
    kqueue_watcher_.StopWatchingFileDescriptor();
    if (IGNORE_EINTR(close(kqueue_)) != 0) {
      DPLOG(ERROR) << "close kqueue";
    }
    kqueue_ = -1;
    std::for_each(events_.begin(), events_.end(), ReleaseEvent);
    events_.clear();
    io_task_runner_ = NULL;
    MessageLoop::current()->RemoveDestructionObserver(this);
    callback_.Reset();
  }
}

}  // namespace base

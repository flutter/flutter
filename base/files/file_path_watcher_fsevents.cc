// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path_watcher_fsevents.h"

#include <list>

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/mac/libdispatch_task_runner.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/message_loop/message_loop.h"
#include "base/thread_task_runner_handle.h"

namespace base {

namespace {

// The latency parameter passed to FSEventsStreamCreate().
const CFAbsoluteTime kEventLatencySeconds = 0.3;

class FSEventsTaskRunner : public mac::LibDispatchTaskRunner {
 public:
   FSEventsTaskRunner()
       : mac::LibDispatchTaskRunner("org.chromium.FilePathWatcherFSEvents") {
   }

 protected:
  ~FSEventsTaskRunner() override {}
};

static LazyInstance<FSEventsTaskRunner>::Leaky g_task_runner =
    LAZY_INSTANCE_INITIALIZER;

// Resolve any symlinks in the path.
FilePath ResolvePath(const FilePath& path) {
  const unsigned kMaxLinksToResolve = 255;

  std::vector<FilePath::StringType> component_vector;
  path.GetComponents(&component_vector);
  std::list<FilePath::StringType>
      components(component_vector.begin(), component_vector.end());

  FilePath result;
  unsigned resolve_count = 0;
  while (resolve_count < kMaxLinksToResolve && !components.empty()) {
    FilePath component(*components.begin());
    components.pop_front();

    FilePath current;
    if (component.IsAbsolute()) {
      current = component;
    } else {
      current = result.Append(component);
    }

    FilePath target;
    if (ReadSymbolicLink(current, &target)) {
      if (target.IsAbsolute())
        result.clear();
      std::vector<FilePath::StringType> target_components;
      target.GetComponents(&target_components);
      components.insert(components.begin(), target_components.begin(),
                        target_components.end());
      resolve_count++;
    } else {
      result = current;
    }
  }

  if (resolve_count >= kMaxLinksToResolve)
    result.clear();
  return result;
}

}  // namespace

FilePathWatcherFSEvents::FilePathWatcherFSEvents() : fsevent_stream_(NULL) {
}

bool FilePathWatcherFSEvents::Watch(const FilePath& path,
                                    bool recursive,
                                    const FilePathWatcher::Callback& callback) {
  DCHECK(MessageLoopForIO::current());
  DCHECK(!callback.is_null());
  DCHECK(callback_.is_null());

  // This class could support non-recursive watches, but that is currently
  // left to FilePathWatcherKQueue.
  if (!recursive)
    return false;

  set_task_runner(ThreadTaskRunnerHandle::Get());
  callback_ = callback;

  FSEventStreamEventId start_event = FSEventsGetCurrentEventId();
  g_task_runner.Get().PostTask(
      FROM_HERE, Bind(&FilePathWatcherFSEvents::StartEventStream, this,
                      start_event, path));
  return true;
}

void FilePathWatcherFSEvents::Cancel() {
  set_cancelled();
  callback_.Reset();

  // Switch to the dispatch queue thread to tear down the event stream.
  g_task_runner.Get().PostTask(
      FROM_HERE,
      Bind(&FilePathWatcherFSEvents::CancelOnMessageLoopThread, this));
}

// static
void FilePathWatcherFSEvents::FSEventsCallback(
    ConstFSEventStreamRef stream,
    void* event_watcher,
    size_t num_events,
    void* event_paths,
    const FSEventStreamEventFlags flags[],
    const FSEventStreamEventId event_ids[]) {
  FilePathWatcherFSEvents* watcher =
      reinterpret_cast<FilePathWatcherFSEvents*>(event_watcher);
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());

  bool root_changed = watcher->ResolveTargetPath();
  std::vector<FilePath> paths;
  FSEventStreamEventId root_change_at = FSEventStreamGetLatestEventId(stream);
  for (size_t i = 0; i < num_events; i++) {
    if (flags[i] & kFSEventStreamEventFlagRootChanged)
      root_changed = true;
    if (event_ids[i])
      root_change_at = std::min(root_change_at, event_ids[i]);
    paths.push_back(FilePath(
        reinterpret_cast<char**>(event_paths)[i]).StripTrailingSeparators());
  }

  // Reinitialize the event stream if we find changes to the root. This is
  // necessary since FSEvents doesn't report any events for the subtree after
  // the directory to be watched gets created.
  if (root_changed) {
    // Resetting the event stream from within the callback fails (FSEvents spews
    // bad file descriptor errors), so post a task to do the reset.
    g_task_runner.Get().PostTask(
        FROM_HERE,
        Bind(&FilePathWatcherFSEvents::UpdateEventStream, watcher,
             root_change_at));
  }

  watcher->OnFilePathsChanged(paths);
}

FilePathWatcherFSEvents::~FilePathWatcherFSEvents() {
  // This method may be called on either the libdispatch or task_runner()
  // thread. Checking callback_ on the libdispatch thread here is safe because
  // it is executing in a task posted by Cancel() which first reset callback_.
  // PostTask forms a sufficient memory barrier to ensure that the value is
  // consistent on the target thread.
  DCHECK(callback_.is_null())
      << "Cancel() must be called before FilePathWatcher is destroyed.";
}

void FilePathWatcherFSEvents::OnFilePathsChanged(
    const std::vector<FilePath>& paths) {
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());
  DCHECK(!resolved_target_.empty());
  task_runner()->PostTask(
      FROM_HERE, Bind(&FilePathWatcherFSEvents::DispatchEvents, this, paths,
                      target_, resolved_target_));
}

void FilePathWatcherFSEvents::DispatchEvents(const std::vector<FilePath>& paths,
                                             const FilePath& target,
                                             const FilePath& resolved_target) {
  DCHECK(task_runner()->RunsTasksOnCurrentThread());

  // Don't issue callbacks after Cancel() has been called.
  if (is_cancelled() || callback_.is_null()) {
    return;
  }

  for (const FilePath& path : paths) {
    if (resolved_target.IsParent(path) || resolved_target == path) {
      callback_.Run(target, false);
      return;
    }
  }
}

void FilePathWatcherFSEvents::CancelOnMessageLoopThread() {
  // For all other implementations, the "message loop thread" is the IO thread,
  // as returned by task_runner(). This implementation, however, needs to
  // cancel pending work on the Dispatch Queue thread.
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());

  if (fsevent_stream_) {
    DestroyEventStream();
    target_.clear();
    resolved_target_.clear();
  }
}

void FilePathWatcherFSEvents::UpdateEventStream(
    FSEventStreamEventId start_event) {
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());

  // It can happen that the watcher gets canceled while tasks that call this
  // function are still in flight, so abort if this situation is detected.
  if (resolved_target_.empty())
    return;

  if (fsevent_stream_)
    DestroyEventStream();

  ScopedCFTypeRef<CFStringRef> cf_path(CFStringCreateWithCString(
      NULL, resolved_target_.value().c_str(), kCFStringEncodingMacHFS));
  ScopedCFTypeRef<CFStringRef> cf_dir_path(CFStringCreateWithCString(
      NULL, resolved_target_.DirName().value().c_str(),
      kCFStringEncodingMacHFS));
  CFStringRef paths_array[] = { cf_path.get(), cf_dir_path.get() };
  ScopedCFTypeRef<CFArrayRef> watched_paths(CFArrayCreate(
      NULL, reinterpret_cast<const void**>(paths_array), arraysize(paths_array),
      &kCFTypeArrayCallBacks));

  FSEventStreamContext context;
  context.version = 0;
  context.info = this;
  context.retain = NULL;
  context.release = NULL;
  context.copyDescription = NULL;

  fsevent_stream_ = FSEventStreamCreate(NULL, &FSEventsCallback, &context,
                                        watched_paths,
                                        start_event,
                                        kEventLatencySeconds,
                                        kFSEventStreamCreateFlagWatchRoot);
  FSEventStreamSetDispatchQueue(fsevent_stream_,
                                g_task_runner.Get().GetDispatchQueue());

  if (!FSEventStreamStart(fsevent_stream_)) {
    task_runner()->PostTask(
        FROM_HERE, Bind(&FilePathWatcherFSEvents::ReportError, this, target_));
  }
}

bool FilePathWatcherFSEvents::ResolveTargetPath() {
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());
  FilePath resolved = ResolvePath(target_).StripTrailingSeparators();
  bool changed = resolved != resolved_target_;
  resolved_target_ = resolved;
  if (resolved_target_.empty()) {
    task_runner()->PostTask(
        FROM_HERE, Bind(&FilePathWatcherFSEvents::ReportError, this, target_));
  }
  return changed;
}

void FilePathWatcherFSEvents::ReportError(const FilePath& target) {
  DCHECK(task_runner()->RunsTasksOnCurrentThread());
  if (!callback_.is_null()) {
    callback_.Run(target, true);
  }
}

void FilePathWatcherFSEvents::DestroyEventStream() {
  FSEventStreamStop(fsevent_stream_);
  FSEventStreamInvalidate(fsevent_stream_);
  FSEventStreamRelease(fsevent_stream_);
  fsevent_stream_ = NULL;
}

void FilePathWatcherFSEvents::StartEventStream(FSEventStreamEventId start_event,
                                               const FilePath& path) {
  DCHECK(g_task_runner.Get().RunsTasksOnCurrentThread());
  DCHECK(resolved_target_.empty());

  target_ = path;
  ResolveTargetPath();
  UpdateEventStream(start_event);
}

}  // namespace base

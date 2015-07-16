// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_FILE_PATH_WATCHER_FSEVENTS_H_
#define BASE_FILES_FILE_PATH_WATCHER_FSEVENTS_H_

#include <CoreServices/CoreServices.h>

#include <vector>

#include "base/files/file_path.h"
#include "base/files/file_path_watcher.h"

namespace base {

// Mac-specific file watcher implementation based on FSEvents.
// There are trade-offs between the FSEvents implementation and a kqueue
// implementation. The biggest issues are that FSEvents on 10.6 sometimes drops
// events and kqueue does not trigger for modifications to a file in a watched
// directory. See file_path_watcher_mac.cc for the code that decides when to
// use which one.
class FilePathWatcherFSEvents : public FilePathWatcher::PlatformDelegate {
 public:
  FilePathWatcherFSEvents();

  // FilePathWatcher::PlatformDelegate overrides.
  bool Watch(const FilePath& path,
             bool recursive,
             const FilePathWatcher::Callback& callback) override;
  void Cancel() override;

 private:
  static void FSEventsCallback(ConstFSEventStreamRef stream,
                               void* event_watcher,
                               size_t num_events,
                               void* event_paths,
                               const FSEventStreamEventFlags flags[],
                               const FSEventStreamEventId event_ids[]);

  ~FilePathWatcherFSEvents() override;

  // Called from FSEventsCallback whenever there is a change to the paths.
  void OnFilePathsChanged(const std::vector<FilePath>& paths);

  // Called on the message_loop() thread to dispatch path events. Can't access
  // target_ and resolved_target_ directly as those are modified on the
  // libdispatch thread.
  void DispatchEvents(const std::vector<FilePath>& paths,
                      const FilePath& target,
                      const FilePath& resolved_target);

  // Cleans up and stops the event stream.
  void CancelOnMessageLoopThread() override;

  // (Re-)Initialize the event stream to start reporting events from
  // |start_event|.
  void UpdateEventStream(FSEventStreamEventId start_event);

  // Returns true if resolving the target path got a different result than
  // last time it was done.
  bool ResolveTargetPath();

  // Report an error watching the given target.
  void ReportError(const FilePath& target);

  // Destroy the event stream.
  void DestroyEventStream();

  // Start watching the FSEventStream.
  void StartEventStream(FSEventStreamEventId start_event, const FilePath& path);

  // Callback to notify upon changes.
  // (Only accessed from the message_loop() thread.)
  FilePathWatcher::Callback callback_;

  // Target path to watch (passed to callback).
  // (Only accessed from the libdispatch thread.)
  FilePath target_;

  // Target path with all symbolic links resolved.
  // (Only accessed from the libdispatch thread.)
  FilePath resolved_target_;

  // Backend stream we receive event callbacks from (strong reference).
  // (Only accessed from the libdispatch thread.)
  FSEventStreamRef fsevent_stream_;

  DISALLOW_COPY_AND_ASSIGN(FilePathWatcherFSEvents);
};

}  // namespace base

#endif  // BASE_FILES_FILE_PATH_WATCHER_FSEVENTS_H_

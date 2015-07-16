// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_IMPORTANT_FILE_WRITER_H_
#define BASE_FILES_IMPORTANT_FILE_WRITER_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/callback.h"
#include "base/files/file_path.h"
#include "base/memory/ref_counted.h"
#include "base/threading/non_thread_safe.h"
#include "base/time/time.h"
#include "base/timer/timer.h"

namespace base {

class SequencedTaskRunner;
class Thread;

// Helper to ensure that a file won't be corrupted by the write (for example on
// application crash). Consider a naive way to save an important file F:
//
// 1. Open F for writing, truncating it.
// 2. Write new data to F.
//
// It's good when it works, but it gets very bad if step 2. doesn't complete.
// It can be caused by a crash, a computer hang, or a weird I/O error. And you
// end up with a broken file.
//
// To be safe, we don't start with writing directly to F. Instead, we write to
// to a temporary file. Only after that write is successful, we rename the
// temporary file to target filename.
//
// If you want to know more about this approach and ext3/ext4 fsync issues, see
// http://valhenson.livejournal.com/37921.html
class BASE_EXPORT ImportantFileWriter : public NonThreadSafe {
 public:
  // Used by ScheduleSave to lazily provide the data to be saved. Allows us
  // to also batch data serializations.
  class BASE_EXPORT DataSerializer {
   public:
    // Should put serialized string in |data| and return true on successful
    // serialization. Will be called on the same thread on which
    // ImportantFileWriter has been created.
    virtual bool SerializeData(std::string* data) = 0;

   protected:
    virtual ~DataSerializer() {}
  };

  // Save |data| to |path| in an atomic manner (see the class comment above).
  // Blocks and writes data on the current thread.
  static bool WriteFileAtomically(const FilePath& path,
                                  const std::string& data);

  // Initialize the writer.
  // |path| is the name of file to write.
  // |task_runner| is the SequencedTaskRunner instance where on which we will
  // execute file I/O operations.
  // All non-const methods, ctor and dtor must be called on the same thread.
  ImportantFileWriter(
      const FilePath& path,
      const scoped_refptr<base::SequencedTaskRunner>& task_runner);

  // You have to ensure that there are no pending writes at the moment
  // of destruction.
  ~ImportantFileWriter();

  const FilePath& path() const { return path_; }

  // Returns true if there is a scheduled write pending which has not yet
  // been started.
  bool HasPendingWrite() const;

  // Save |data| to target filename. Does not block. If there is a pending write
  // scheduled by ScheduleWrite, it is cancelled.
  void WriteNow(scoped_ptr<std::string> data);

  // Schedule a save to target filename. Data will be serialized and saved
  // to disk after the commit interval. If another ScheduleWrite is issued
  // before that, only one serialization and write to disk will happen, and
  // the most recent |serializer| will be used. This operation does not block.
  // |serializer| should remain valid through the lifetime of
  // ImportantFileWriter.
  void ScheduleWrite(DataSerializer* serializer);

  // Serialize data pending to be saved and execute write on backend thread.
  void DoScheduledWrite();

  // Registers |on_next_successful_write| to be called once, on the next
  // successful write event. Only one callback can be set at once.
  void RegisterOnNextSuccessfulWriteCallback(
      const base::Closure& on_next_successful_write);

  TimeDelta commit_interval() const {
    return commit_interval_;
  }

  void set_commit_interval(const TimeDelta& interval) {
    commit_interval_ = interval;
  }

 private:
  // Helper method for WriteNow().
  bool PostWriteTask(const Callback<bool()>& task);

  // If |result| is true and |on_next_successful_write_| is set, invokes
  // |on_successful_write_| and then resets it; no-ops otherwise.
  void ForwardSuccessfulWrite(bool result);

  // Invoked once and then reset on the next successful write event.
  base::Closure on_next_successful_write_;

  // Path being written to.
  const FilePath path_;

  // TaskRunner for the thread on which file I/O can be done.
  const scoped_refptr<base::SequencedTaskRunner> task_runner_;

  // Timer used to schedule commit after ScheduleWrite.
  OneShotTimer<ImportantFileWriter> timer_;

  // Serializer which will provide the data to be saved.
  DataSerializer* serializer_;

  // Time delta after which scheduled data will be written to disk.
  TimeDelta commit_interval_;

  WeakPtrFactory<ImportantFileWriter> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(ImportantFileWriter);
};

}  // namespace base

#endif  // BASE_FILES_IMPORTANT_FILE_WRITER_H_

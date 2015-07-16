// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path_watcher.h"

#if defined(OS_WIN)
#include <windows.h>
#include <aclapi.h>
#elif defined(OS_POSIX)
#include <sys/stat.h>
#endif

#include <set>

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/compiler_specific.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/location.h"
#include "base/run_loop.h"
#include "base/single_thread_task_runner.h"
#include "base/stl_util.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/waitable_event.h"
#include "base/test/test_file_util.h"
#include "base/test/test_timeouts.h"
#include "base/thread_task_runner_handle.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_ANDROID)
#include "base/android/path_utils.h"
#endif  // defined(OS_ANDROID)

namespace base {

namespace {

class TestDelegate;

// Aggregates notifications from the test delegates and breaks the message loop
// the test thread is waiting on once they all came in.
class NotificationCollector
    : public base::RefCountedThreadSafe<NotificationCollector> {
 public:
  NotificationCollector() : task_runner_(base::ThreadTaskRunnerHandle::Get()) {}

  // Called from the file thread by the delegates.
  void OnChange(TestDelegate* delegate) {
    task_runner_->PostTask(
        FROM_HERE, base::Bind(&NotificationCollector::RecordChange, this,
                              base::Unretained(delegate)));
  }

  void Register(TestDelegate* delegate) {
    delegates_.insert(delegate);
  }

  void Reset() {
    signaled_.clear();
  }

  bool Success() {
    return signaled_ == delegates_;
  }

 private:
  friend class base::RefCountedThreadSafe<NotificationCollector>;
  ~NotificationCollector() {}

  void RecordChange(TestDelegate* delegate) {
    // Warning: |delegate| is Unretained. Do not dereference.
    ASSERT_TRUE(task_runner_->BelongsToCurrentThread());
    ASSERT_TRUE(delegates_.count(delegate));
    signaled_.insert(delegate);

    // Check whether all delegates have been signaled.
    if (signaled_ == delegates_)
      task_runner_->PostTask(FROM_HERE, MessageLoop::QuitWhenIdleClosure());
  }

  // Set of registered delegates.
  std::set<TestDelegate*> delegates_;

  // Set of signaled delegates.
  std::set<TestDelegate*> signaled_;

  // The loop we should break after all delegates signaled.
  scoped_refptr<base::SingleThreadTaskRunner> task_runner_;
};

class TestDelegateBase : public SupportsWeakPtr<TestDelegateBase> {
 public:
  TestDelegateBase() {}
  virtual ~TestDelegateBase() {}

  virtual void OnFileChanged(const FilePath& path, bool error) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(TestDelegateBase);
};

// A mock class for testing. Gmock is not appropriate because it is not
// thread-safe for setting expectations. Thus the test code cannot safely
// reset expectations while the file watcher is running.
// Instead, TestDelegate gets the notifications from FilePathWatcher and uses
// NotificationCollector to aggregate the results.
class TestDelegate : public TestDelegateBase {
 public:
  explicit TestDelegate(NotificationCollector* collector)
      : collector_(collector) {
    collector_->Register(this);
  }
  ~TestDelegate() override {}

  void OnFileChanged(const FilePath& path, bool error) override {
    if (error)
      ADD_FAILURE() << "Error " << path.value();
    else
      collector_->OnChange(this);
  }

 private:
  scoped_refptr<NotificationCollector> collector_;

  DISALLOW_COPY_AND_ASSIGN(TestDelegate);
};

void SetupWatchCallback(const FilePath& target,
                        FilePathWatcher* watcher,
                        TestDelegateBase* delegate,
                        bool recursive_watch,
                        bool* result,
                        base::WaitableEvent* completion) {
  *result = watcher->Watch(target, recursive_watch,
                           base::Bind(&TestDelegateBase::OnFileChanged,
                                      delegate->AsWeakPtr()));
  completion->Signal();
}

class FilePathWatcherTest : public testing::Test {
 public:
  FilePathWatcherTest()
      : file_thread_("FilePathWatcherTest") {}

  ~FilePathWatcherTest() override {}

 protected:
  void SetUp() override {
    // Create a separate file thread in order to test proper thread usage.
    base::Thread::Options options(MessageLoop::TYPE_IO, 0);
    ASSERT_TRUE(file_thread_.StartWithOptions(options));
#if defined(OS_ANDROID)
    // Watching files is only permitted when all parent directories are
    // accessible, which is not the case for the default temp directory
    // on Android which is under /data/data.  Use /sdcard instead.
    // TODO(pauljensen): Remove this when crbug.com/475568 is fixed.
    FilePath parent_dir;
    ASSERT_TRUE(android::GetExternalStorageDirectory(&parent_dir));
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDirUnderPath(parent_dir));
#else   // defined(OS_ANDROID)
    ASSERT_TRUE(temp_dir_.CreateUniqueTempDir());
#endif  // defined(OS_ANDROID)
    collector_ = new NotificationCollector();
  }

  void TearDown() override { RunLoop().RunUntilIdle(); }

  void DeleteDelegateOnFileThread(TestDelegate* delegate) {
    file_thread_.task_runner()->DeleteSoon(FROM_HERE, delegate);
  }

  FilePath test_file() {
    return temp_dir_.path().AppendASCII("FilePathWatcherTest");
  }

  FilePath test_link() {
    return temp_dir_.path().AppendASCII("FilePathWatcherTest.lnk");
  }

  // Write |content| to |file|. Returns true on success.
  bool WriteFile(const FilePath& file, const std::string& content) {
    int write_size = ::base::WriteFile(file, content.c_str(), content.length());
    return write_size == static_cast<int>(content.length());
  }

  bool SetupWatch(const FilePath& target,
                  FilePathWatcher* watcher,
                  TestDelegateBase* delegate,
                  bool recursive_watch) WARN_UNUSED_RESULT;

  bool WaitForEvents() WARN_UNUSED_RESULT {
    collector_->Reset();
    loop_.Run();
    return collector_->Success();
  }

  NotificationCollector* collector() { return collector_.get(); }

  MessageLoop loop_;
  base::Thread file_thread_;
  ScopedTempDir temp_dir_;
  scoped_refptr<NotificationCollector> collector_;

 private:
  DISALLOW_COPY_AND_ASSIGN(FilePathWatcherTest);
};

bool FilePathWatcherTest::SetupWatch(const FilePath& target,
                                     FilePathWatcher* watcher,
                                     TestDelegateBase* delegate,
                                     bool recursive_watch) {
  base::WaitableEvent completion(false, false);
  bool result;
  file_thread_.task_runner()->PostTask(
      FROM_HERE, base::Bind(SetupWatchCallback, target, watcher, delegate,
                            recursive_watch, &result, &completion));
  completion.Wait();
  return result;
}

// Basic test: Create the file and verify that we notice.
TEST_F(FilePathWatcherTest, NewFile) {
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that modifying the file is caught.
TEST_F(FilePathWatcherTest, ModifiedFile) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));

  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the file is modified.
  ASSERT_TRUE(WriteFile(test_file(), "new content"));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that moving the file into place is caught.
TEST_F(FilePathWatcherTest, MovedFile) {
  FilePath source_file(temp_dir_.path().AppendASCII("source"));
  ASSERT_TRUE(WriteFile(source_file, "content"));

  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the file is modified.
  ASSERT_TRUE(base::Move(source_file, test_file()));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

TEST_F(FilePathWatcherTest, DeletedFile) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));

  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the file is deleted.
  base::DeleteFile(test_file(), false);
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Used by the DeleteDuringNotify test below.
// Deletes the FilePathWatcher when it's notified.
class Deleter : public TestDelegateBase {
 public:
  Deleter(FilePathWatcher* watcher, MessageLoop* loop)
      : watcher_(watcher),
        loop_(loop) {
  }
  ~Deleter() override {}

  void OnFileChanged(const FilePath&, bool) override {
    watcher_.reset();
    loop_->task_runner()->PostTask(FROM_HERE,
                                   MessageLoop::QuitWhenIdleClosure());
  }

  FilePathWatcher* watcher() const { return watcher_.get(); }

 private:
  scoped_ptr<FilePathWatcher> watcher_;
  MessageLoop* loop_;

  DISALLOW_COPY_AND_ASSIGN(Deleter);
};

// Verify that deleting a watcher during the callback doesn't crash.
TEST_F(FilePathWatcherTest, DeleteDuringNotify) {
  FilePathWatcher* watcher = new FilePathWatcher;
  // Takes ownership of watcher.
  scoped_ptr<Deleter> deleter(new Deleter(watcher, &loop_));
  ASSERT_TRUE(SetupWatch(test_file(), watcher, deleter.get(), false));

  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(WaitForEvents());

  // We win if we haven't crashed yet.
  // Might as well double-check it got deleted, too.
  ASSERT_TRUE(deleter->watcher() == NULL);
}

// Verify that deleting the watcher works even if there is a pending
// notification.
// Flaky on MacOS (and ARM linux): http://crbug.com/85930
TEST_F(FilePathWatcherTest, DISABLED_DestroyWithPendingNotification) {
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  FilePathWatcher* watcher = new FilePathWatcher;
  ASSERT_TRUE(SetupWatch(test_file(), watcher, delegate.get(), false));
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  file_thread_.task_runner()->DeleteSoon(FROM_HERE, watcher);
  DeleteDelegateOnFileThread(delegate.release());
}

TEST_F(FilePathWatcherTest, MultipleWatchersSingleFile) {
  FilePathWatcher watcher1, watcher2;
  scoped_ptr<TestDelegate> delegate1(new TestDelegate(collector()));
  scoped_ptr<TestDelegate> delegate2(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher1, delegate1.get(), false));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher2, delegate2.get(), false));

  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate1.release());
  DeleteDelegateOnFileThread(delegate2.release());
}

// Verify that watching a file whose parent directory doesn't exist yet works if
// the directory and file are created eventually.
TEST_F(FilePathWatcherTest, NonExistentDirectory) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath file(dir.AppendASCII("file"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(file, &watcher, delegate.get(), false));

  ASSERT_TRUE(base::CreateDirectory(dir));

  ASSERT_TRUE(WriteFile(file, "content"));

  VLOG(1) << "Waiting for file creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file, "content v2"));
  VLOG(1) << "Waiting for file change";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(base::DeleteFile(file, false));
  VLOG(1) << "Waiting for file deletion";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Exercises watch reconfiguration for the case that directories on the path
// are rapidly created.
TEST_F(FilePathWatcherTest, DirectoryChain) {
  FilePath path(temp_dir_.path());
  std::vector<std::string> dir_names;
  for (int i = 0; i < 20; i++) {
    std::string dir(base::StringPrintf("d%d", i));
    dir_names.push_back(dir);
    path = path.AppendASCII(dir);
  }

  FilePathWatcher watcher;
  FilePath file(path.AppendASCII("file"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(file, &watcher, delegate.get(), false));

  FilePath sub_path(temp_dir_.path());
  for (std::vector<std::string>::const_iterator d(dir_names.begin());
       d != dir_names.end(); ++d) {
    sub_path = sub_path.AppendASCII(*d);
    ASSERT_TRUE(base::CreateDirectory(sub_path));
  }
  VLOG(1) << "Create File";
  ASSERT_TRUE(WriteFile(file, "content"));
  VLOG(1) << "Waiting for file creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file, "content v2"));
  VLOG(1) << "Waiting for file modification";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

#if defined(OS_MACOSX)
// http://crbug.com/85930
#define DisappearingDirectory DISABLED_DisappearingDirectory
#endif
TEST_F(FilePathWatcherTest, DisappearingDirectory) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath file(dir.AppendASCII("file"));
  ASSERT_TRUE(base::CreateDirectory(dir));
  ASSERT_TRUE(WriteFile(file, "content"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(file, &watcher, delegate.get(), false));

  ASSERT_TRUE(base::DeleteFile(dir, true));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Tests that a file that is deleted and reappears is tracked correctly.
TEST_F(FilePathWatcherTest, DeleteAndRecreate) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  ASSERT_TRUE(base::DeleteFile(test_file(), false));
  VLOG(1) << "Waiting for file deletion";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(test_file(), "content"));
  VLOG(1) << "Waiting for file creation";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

TEST_F(FilePathWatcherTest, WatchDirectory) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath file1(dir.AppendASCII("file1"));
  FilePath file2(dir.AppendASCII("file2"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(dir, &watcher, delegate.get(), false));

  ASSERT_TRUE(base::CreateDirectory(dir));
  VLOG(1) << "Waiting for directory creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file1, "content"));
  VLOG(1) << "Waiting for file1 creation";
  ASSERT_TRUE(WaitForEvents());

#if !defined(OS_MACOSX)
  // Mac implementation does not detect files modified in a directory.
  ASSERT_TRUE(WriteFile(file1, "content v2"));
  VLOG(1) << "Waiting for file1 modification";
  ASSERT_TRUE(WaitForEvents());
#endif  // !OS_MACOSX

  ASSERT_TRUE(base::DeleteFile(file1, false));
  VLOG(1) << "Waiting for file1 deletion";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file2, "content"));
  VLOG(1) << "Waiting for file2 creation";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

TEST_F(FilePathWatcherTest, MoveParent) {
  FilePathWatcher file_watcher;
  FilePathWatcher subdir_watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath dest(temp_dir_.path().AppendASCII("dest"));
  FilePath subdir(dir.AppendASCII("subdir"));
  FilePath file(subdir.AppendASCII("file"));
  scoped_ptr<TestDelegate> file_delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(file, &file_watcher, file_delegate.get(), false));
  scoped_ptr<TestDelegate> subdir_delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(subdir, &subdir_watcher, subdir_delegate.get(),
                         false));

  // Setup a directory hierarchy.
  ASSERT_TRUE(base::CreateDirectory(subdir));
  ASSERT_TRUE(WriteFile(file, "content"));
  VLOG(1) << "Waiting for file creation";
  ASSERT_TRUE(WaitForEvents());

  // Move the parent directory.
  base::Move(dir, dest);
  VLOG(1) << "Waiting for directory move";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(file_delegate.release());
  DeleteDelegateOnFileThread(subdir_delegate.release());
}

TEST_F(FilePathWatcherTest, RecursiveWatch) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  bool setup_result = SetupWatch(dir, &watcher, delegate.get(), true);
  if (!FilePathWatcher::RecursiveWatchAvailable()) {
    ASSERT_FALSE(setup_result);
    DeleteDelegateOnFileThread(delegate.release());
    return;
  }
  ASSERT_TRUE(setup_result);

  // Main directory("dir") creation.
  ASSERT_TRUE(base::CreateDirectory(dir));
  ASSERT_TRUE(WaitForEvents());

  // Create "$dir/file1".
  FilePath file1(dir.AppendASCII("file1"));
  ASSERT_TRUE(WriteFile(file1, "content"));
  ASSERT_TRUE(WaitForEvents());

  // Create "$dir/subdir".
  FilePath subdir(dir.AppendASCII("subdir"));
  ASSERT_TRUE(base::CreateDirectory(subdir));
  ASSERT_TRUE(WaitForEvents());

  // Create "$dir/subdir/subdir_file1".
  FilePath subdir_file1(subdir.AppendASCII("subdir_file1"));
  ASSERT_TRUE(WriteFile(subdir_file1, "content"));
  ASSERT_TRUE(WaitForEvents());

  // Create "$dir/subdir/subdir_child_dir".
  FilePath subdir_child_dir(subdir.AppendASCII("subdir_child_dir"));
  ASSERT_TRUE(base::CreateDirectory(subdir_child_dir));
  ASSERT_TRUE(WaitForEvents());

  // Create "$dir/subdir/subdir_child_dir/child_dir_file1".
  FilePath child_dir_file1(subdir_child_dir.AppendASCII("child_dir_file1"));
  ASSERT_TRUE(WriteFile(child_dir_file1, "content v2"));
  ASSERT_TRUE(WaitForEvents());

  // Write into "$dir/subdir/subdir_child_dir/child_dir_file1".
  ASSERT_TRUE(WriteFile(child_dir_file1, "content"));
  ASSERT_TRUE(WaitForEvents());

// Apps cannot change file attributes on Android in /sdcard as /sdcard uses the
// "fuse" file system, while /data uses "ext4".  Running these tests in /data
// would be preferable and allow testing file attributes and symlinks.
// TODO(pauljensen): Re-enable when crbug.com/475568 is fixed and SetUp() places
// the |temp_dir_| in /data.
#if !defined(OS_ANDROID)
  // Modify "$dir/subdir/subdir_child_dir/child_dir_file1" attributes.
  ASSERT_TRUE(base::MakeFileUnreadable(child_dir_file1));
  ASSERT_TRUE(WaitForEvents());
#endif

  // Delete "$dir/subdir/subdir_file1".
  ASSERT_TRUE(base::DeleteFile(subdir_file1, false));
  ASSERT_TRUE(WaitForEvents());

  // Delete "$dir/subdir/subdir_child_dir/child_dir_file1".
  ASSERT_TRUE(base::DeleteFile(child_dir_file1, false));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

#if defined(OS_POSIX)
#if defined(OS_ANDROID)
// Apps cannot create symlinks on Android in /sdcard as /sdcard uses the
// "fuse" file system, while /data uses "ext4".  Running these tests in /data
// would be preferable and allow testing file attributes and symlinks.
// TODO(pauljensen): Re-enable when crbug.com/475568 is fixed and SetUp() places
// the |temp_dir_| in /data.
#define RecursiveWithSymLink DISABLED_RecursiveWithSymLink
#endif  // defined(OS_ANDROID)
TEST_F(FilePathWatcherTest, RecursiveWithSymLink) {
  if (!FilePathWatcher::RecursiveWatchAvailable())
    return;

  FilePathWatcher watcher;
  FilePath test_dir(temp_dir_.path().AppendASCII("test_dir"));
  ASSERT_TRUE(base::CreateDirectory(test_dir));
  FilePath symlink(test_dir.AppendASCII("symlink"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(symlink, &watcher, delegate.get(), true));

  // Link creation.
  FilePath target1(temp_dir_.path().AppendASCII("target1"));
  ASSERT_TRUE(base::CreateSymbolicLink(target1, symlink));
  ASSERT_TRUE(WaitForEvents());

  // Target1 creation.
  ASSERT_TRUE(base::CreateDirectory(target1));
  ASSERT_TRUE(WaitForEvents());

  // Create a file in target1.
  FilePath target1_file(target1.AppendASCII("file"));
  ASSERT_TRUE(WriteFile(target1_file, "content"));
  ASSERT_TRUE(WaitForEvents());

  // Link change.
  FilePath target2(temp_dir_.path().AppendASCII("target2"));
  ASSERT_TRUE(base::CreateDirectory(target2));
  ASSERT_TRUE(base::DeleteFile(symlink, false));
  ASSERT_TRUE(base::CreateSymbolicLink(target2, symlink));
  ASSERT_TRUE(WaitForEvents());

  // Create a file in target2.
  FilePath target2_file(target2.AppendASCII("file"));
  ASSERT_TRUE(WriteFile(target2_file, "content"));
  ASSERT_TRUE(WaitForEvents());

  DeleteDelegateOnFileThread(delegate.release());
}
#endif  // OS_POSIX

TEST_F(FilePathWatcherTest, MoveChild) {
  FilePathWatcher file_watcher;
  FilePathWatcher subdir_watcher;
  FilePath source_dir(temp_dir_.path().AppendASCII("source"));
  FilePath source_subdir(source_dir.AppendASCII("subdir"));
  FilePath source_file(source_subdir.AppendASCII("file"));
  FilePath dest_dir(temp_dir_.path().AppendASCII("dest"));
  FilePath dest_subdir(dest_dir.AppendASCII("subdir"));
  FilePath dest_file(dest_subdir.AppendASCII("file"));

  // Setup a directory hierarchy.
  ASSERT_TRUE(base::CreateDirectory(source_subdir));
  ASSERT_TRUE(WriteFile(source_file, "content"));

  scoped_ptr<TestDelegate> file_delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(dest_file, &file_watcher, file_delegate.get(), false));
  scoped_ptr<TestDelegate> subdir_delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(dest_subdir, &subdir_watcher, subdir_delegate.get(),
                         false));

  // Move the directory into place, s.t. the watched file appears.
  ASSERT_TRUE(base::Move(source_dir, dest_dir));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(file_delegate.release());
  DeleteDelegateOnFileThread(subdir_delegate.release());
}

// Verify that changing attributes on a file is caught
#if defined(OS_ANDROID)
// Apps cannot change file attributes on Android in /sdcard as /sdcard uses the
// "fuse" file system, while /data uses "ext4".  Running these tests in /data
// would be preferable and allow testing file attributes and symlinks.
// TODO(pauljensen): Re-enable when crbug.com/475568 is fixed and SetUp() places
// the |temp_dir_| in /data.
#define FileAttributesChanged DISABLED_FileAttributesChanged
#endif  // defined(OS_ANDROID
TEST_F(FilePathWatcherTest, FileAttributesChanged) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the file is modified.
  ASSERT_TRUE(base::MakeFileUnreadable(test_file()));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

#if defined(OS_LINUX)

// Verify that creating a symlink is caught.
TEST_F(FilePathWatcherTest, CreateLink) {
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // Note that we are watching the symlink
  ASSERT_TRUE(SetupWatch(test_link(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the link is created.
  // Note that test_file() doesn't have to exist.
  ASSERT_TRUE(CreateSymbolicLink(test_file(), test_link()));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that deleting a symlink is caught.
TEST_F(FilePathWatcherTest, DeleteLink) {
  // Unfortunately this test case only works if the link target exists.
  // TODO(craig) fix this as part of crbug.com/91561.
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(CreateSymbolicLink(test_file(), test_link()));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_link(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the link is deleted.
  ASSERT_TRUE(base::DeleteFile(test_link(), false));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that modifying a target file that a link is pointing to
// when we are watching the link is caught.
TEST_F(FilePathWatcherTest, ModifiedLinkedFile) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(CreateSymbolicLink(test_file(), test_link()));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // Note that we are watching the symlink.
  ASSERT_TRUE(SetupWatch(test_link(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the file is modified.
  ASSERT_TRUE(WriteFile(test_file(), "new content"));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that creating a target file that a link is pointing to
// when we are watching the link is caught.
TEST_F(FilePathWatcherTest, CreateTargetLinkedFile) {
  ASSERT_TRUE(CreateSymbolicLink(test_file(), test_link()));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // Note that we are watching the symlink.
  ASSERT_TRUE(SetupWatch(test_link(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the target file is created.
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that deleting a target file that a link is pointing to
// when we are watching the link is caught.
TEST_F(FilePathWatcherTest, DeleteTargetLinkedFile) {
  ASSERT_TRUE(WriteFile(test_file(), "content"));
  ASSERT_TRUE(CreateSymbolicLink(test_file(), test_link()));
  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // Note that we are watching the symlink.
  ASSERT_TRUE(SetupWatch(test_link(), &watcher, delegate.get(), false));

  // Now make sure we get notified if the target file is deleted.
  ASSERT_TRUE(base::DeleteFile(test_file(), false));
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that watching a file whose parent directory is a link that
// doesn't exist yet works if the symlink is created eventually.
TEST_F(FilePathWatcherTest, LinkedDirectoryPart1) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath link_dir(temp_dir_.path().AppendASCII("dir.lnk"));
  FilePath file(dir.AppendASCII("file"));
  FilePath linkfile(link_dir.AppendASCII("file"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // dir/file should exist.
  ASSERT_TRUE(base::CreateDirectory(dir));
  ASSERT_TRUE(WriteFile(file, "content"));
  // Note that we are watching dir.lnk/file which doesn't exist yet.
  ASSERT_TRUE(SetupWatch(linkfile, &watcher, delegate.get(), false));

  ASSERT_TRUE(CreateSymbolicLink(dir, link_dir));
  VLOG(1) << "Waiting for link creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file, "content v2"));
  VLOG(1) << "Waiting for file change";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(base::DeleteFile(file, false));
  VLOG(1) << "Waiting for file deletion";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that watching a file whose parent directory is a
// dangling symlink works if the directory is created eventually.
TEST_F(FilePathWatcherTest, LinkedDirectoryPart2) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath link_dir(temp_dir_.path().AppendASCII("dir.lnk"));
  FilePath file(dir.AppendASCII("file"));
  FilePath linkfile(link_dir.AppendASCII("file"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  // Now create the link from dir.lnk pointing to dir but
  // neither dir nor dir/file exist yet.
  ASSERT_TRUE(CreateSymbolicLink(dir, link_dir));
  // Note that we are watching dir.lnk/file.
  ASSERT_TRUE(SetupWatch(linkfile, &watcher, delegate.get(), false));

  ASSERT_TRUE(base::CreateDirectory(dir));
  ASSERT_TRUE(WriteFile(file, "content"));
  VLOG(1) << "Waiting for dir/file creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file, "content v2"));
  VLOG(1) << "Waiting for file change";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(base::DeleteFile(file, false));
  VLOG(1) << "Waiting for file deletion";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

// Verify that watching a file with a symlink on the path
// to the file works.
TEST_F(FilePathWatcherTest, LinkedDirectoryPart3) {
  FilePathWatcher watcher;
  FilePath dir(temp_dir_.path().AppendASCII("dir"));
  FilePath link_dir(temp_dir_.path().AppendASCII("dir.lnk"));
  FilePath file(dir.AppendASCII("file"));
  FilePath linkfile(link_dir.AppendASCII("file"));
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(base::CreateDirectory(dir));
  ASSERT_TRUE(CreateSymbolicLink(dir, link_dir));
  // Note that we are watching dir.lnk/file but the file doesn't exist yet.
  ASSERT_TRUE(SetupWatch(linkfile, &watcher, delegate.get(), false));

  ASSERT_TRUE(WriteFile(file, "content"));
  VLOG(1) << "Waiting for file creation";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(WriteFile(file, "content v2"));
  VLOG(1) << "Waiting for file change";
  ASSERT_TRUE(WaitForEvents());

  ASSERT_TRUE(base::DeleteFile(file, false));
  VLOG(1) << "Waiting for file deletion";
  ASSERT_TRUE(WaitForEvents());
  DeleteDelegateOnFileThread(delegate.release());
}

#endif  // OS_LINUX

enum Permission {
  Read,
  Write,
  Execute
};

#if defined(OS_MACOSX)
bool ChangeFilePermissions(const FilePath& path, Permission perm, bool allow) {
  struct stat stat_buf;

  if (stat(path.value().c_str(), &stat_buf) != 0)
    return false;

  mode_t mode = 0;
  switch (perm) {
    case Read:
      mode = S_IRUSR | S_IRGRP | S_IROTH;
      break;
    case Write:
      mode = S_IWUSR | S_IWGRP | S_IWOTH;
      break;
    case Execute:
      mode = S_IXUSR | S_IXGRP | S_IXOTH;
      break;
    default:
      ADD_FAILURE() << "unknown perm " << perm;
      return false;
  }
  if (allow) {
    stat_buf.st_mode |= mode;
  } else {
    stat_buf.st_mode &= ~mode;
  }
  return chmod(path.value().c_str(), stat_buf.st_mode) == 0;
}
#endif  // defined(OS_MACOSX)

#if defined(OS_MACOSX)
// Linux implementation of FilePathWatcher doesn't catch attribute changes.
// http://crbug.com/78043
// Windows implementation of FilePathWatcher catches attribute changes that
// don't affect the path being watched.
// http://crbug.com/78045

// Verify that changing attributes on a directory works.
TEST_F(FilePathWatcherTest, DirAttributesChanged) {
  FilePath test_dir1(temp_dir_.path().AppendASCII("DirAttributesChangedDir1"));
  FilePath test_dir2(test_dir1.AppendASCII("DirAttributesChangedDir2"));
  FilePath test_file(test_dir2.AppendASCII("DirAttributesChangedFile"));
  // Setup a directory hierarchy.
  ASSERT_TRUE(base::CreateDirectory(test_dir1));
  ASSERT_TRUE(base::CreateDirectory(test_dir2));
  ASSERT_TRUE(WriteFile(test_file, "content"));

  FilePathWatcher watcher;
  scoped_ptr<TestDelegate> delegate(new TestDelegate(collector()));
  ASSERT_TRUE(SetupWatch(test_file, &watcher, delegate.get(), false));

  // We should not get notified in this case as it hasn't affected our ability
  // to access the file.
  ASSERT_TRUE(ChangeFilePermissions(test_dir1, Read, false));
  loop_.PostDelayedTask(FROM_HERE,
                        MessageLoop::QuitWhenIdleClosure(),
                        TestTimeouts::tiny_timeout());
  ASSERT_FALSE(WaitForEvents());
  ASSERT_TRUE(ChangeFilePermissions(test_dir1, Read, true));

  // We should get notified in this case because filepathwatcher can no
  // longer access the file
  ASSERT_TRUE(ChangeFilePermissions(test_dir1, Execute, false));
  ASSERT_TRUE(WaitForEvents());
  ASSERT_TRUE(ChangeFilePermissions(test_dir1, Execute, true));
  DeleteDelegateOnFileThread(delegate.release());
}

#endif  // OS_MACOSX
}  // namespace

}  // namespace base

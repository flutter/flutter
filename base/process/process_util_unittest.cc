// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define _CRT_SECURE_NO_WARNINGS

#include <limits>

#include "base/command_line.h"
#include "base/debug/alias.h"
#include "base/debug/stack_trace.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/path_service.h"
#include "base/posix/eintr_wrapper.h"
#include "base/process/kill.h"
#include "base/process/launch.h"
#include "base/process/memory.h"
#include "base/process/process.h"
#include "base/process/process_metrics.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "base/synchronization/waitable_event.h"
#include "base/test/multiprocess_test.h"
#include "base/test/test_timeouts.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/multiprocess_func_list.h"

#if defined(OS_LINUX)
#include <malloc.h>
#include <sched.h>
#include <sys/syscall.h>
#endif
#if defined(OS_POSIX)
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <signal.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#if defined(OS_WIN)
#include <windows.h>
#include "base/win/windows_version.h"
#endif
#if defined(OS_MACOSX)
#include <mach/vm_param.h>
#include <malloc/malloc.h>
#include "base/mac/mac_util.h"
#endif

using base::FilePath;

namespace {

const char kSignalFileSlow[] = "SlowChildProcess.die";
const char kSignalFileKill[] = "KilledChildProcess.die";

#if defined(OS_POSIX)
const char kSignalFileTerm[] = "TerminatedChildProcess.die";

#if defined(OS_ANDROID)
const char kShellPath[] = "/system/bin/sh";
const char kPosixShell[] = "sh";
#else
const char kShellPath[] = "/bin/sh";
const char kPosixShell[] = "bash";
#endif
#endif  // defined(OS_POSIX)

#if defined(OS_WIN)
const int kExpectedStillRunningExitCode = 0x102;
const int kExpectedKilledExitCode = 1;
#else
const int kExpectedStillRunningExitCode = 0;
#endif

// Sleeps until file filename is created.
void WaitToDie(const char* filename) {
  FILE* fp;
  do {
    base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(10));
    fp = fopen(filename, "r");
  } while (!fp);
  fclose(fp);
}

// Signals children they should die now.
void SignalChildren(const char* filename) {
  FILE* fp = fopen(filename, "w");
  fclose(fp);
}

// Using a pipe to the child to wait for an event was considered, but
// there were cases in the past where pipes caused problems (other
// libraries closing the fds, child deadlocking). This is a simple
// case, so it's not worth the risk.  Using wait loops is discouraged
// in most instances.
base::TerminationStatus WaitForChildTermination(base::ProcessHandle handle,
                                                int* exit_code) {
  // Now we wait until the result is something other than STILL_RUNNING.
  base::TerminationStatus status = base::TERMINATION_STATUS_STILL_RUNNING;
  const base::TimeDelta kInterval = base::TimeDelta::FromMilliseconds(20);
  base::TimeDelta waited;
  do {
    status = base::GetTerminationStatus(handle, exit_code);
    base::PlatformThread::Sleep(kInterval);
    waited += kInterval;
  } while (status == base::TERMINATION_STATUS_STILL_RUNNING &&
           waited < TestTimeouts::action_max_timeout());

  return status;
}

}  // namespace

class ProcessUtilTest : public base::MultiProcessTest {
 public:
#if defined(OS_POSIX)
  // Spawn a child process that counts how many file descriptors are open.
  int CountOpenFDsInChild();
#endif
  // Converts the filename to a platform specific filepath.
  // On Android files can not be created in arbitrary directories.
  static std::string GetSignalFilePath(const char* filename);
};

std::string ProcessUtilTest::GetSignalFilePath(const char* filename) {
#if !defined(OS_ANDROID)
  return filename;
#else
  FilePath tmp_dir;
  PathService::Get(base::DIR_CACHE, &tmp_dir);
  tmp_dir = tmp_dir.Append(filename);
  return tmp_dir.value();
#endif
}

MULTIPROCESS_TEST_MAIN(SimpleChildProcess) {
  return 0;
}

// TODO(viettrungluu): This should be in a "MultiProcessTestTest".
TEST_F(ProcessUtilTest, SpawnChild) {
  base::Process process = SpawnChild("SimpleChildProcess");
  ASSERT_TRUE(process.IsValid());
  int exit_code;
  EXPECT_TRUE(process.WaitForExitWithTimeout(
                  TestTimeouts::action_max_timeout(), &exit_code));
}

MULTIPROCESS_TEST_MAIN(SlowChildProcess) {
  WaitToDie(ProcessUtilTest::GetSignalFilePath(kSignalFileSlow).c_str());
  return 0;
}

TEST_F(ProcessUtilTest, KillSlowChild) {
  const std::string signal_file =
      ProcessUtilTest::GetSignalFilePath(kSignalFileSlow);
  remove(signal_file.c_str());
  base::Process process = SpawnChild("SlowChildProcess");
  ASSERT_TRUE(process.IsValid());
  SignalChildren(signal_file.c_str());
  int exit_code;
  EXPECT_TRUE(process.WaitForExitWithTimeout(
                  TestTimeouts::action_max_timeout(), &exit_code));
  remove(signal_file.c_str());
}

// Times out on Linux and Win, flakes on other platforms, http://crbug.com/95058
TEST_F(ProcessUtilTest, DISABLED_GetTerminationStatusExit) {
  const std::string signal_file =
      ProcessUtilTest::GetSignalFilePath(kSignalFileSlow);
  remove(signal_file.c_str());
  base::Process process = SpawnChild("SlowChildProcess");
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_EQ(base::TERMINATION_STATUS_STILL_RUNNING,
            base::GetTerminationStatus(process.Handle(), &exit_code));
  EXPECT_EQ(kExpectedStillRunningExitCode, exit_code);

  SignalChildren(signal_file.c_str());
  exit_code = 42;
  base::TerminationStatus status =
      WaitForChildTermination(process.Handle(), &exit_code);
  EXPECT_EQ(base::TERMINATION_STATUS_NORMAL_TERMINATION, status);
  EXPECT_EQ(0, exit_code);
  remove(signal_file.c_str());
}

#if defined(OS_WIN)
// TODO(cpu): figure out how to test this in other platforms.
TEST_F(ProcessUtilTest, GetProcId) {
  base::ProcessId id1 = base::GetProcId(GetCurrentProcess());
  EXPECT_NE(0ul, id1);
  base::Process process = SpawnChild("SimpleChildProcess");
  ASSERT_TRUE(process.IsValid());
  base::ProcessId id2 = process.Pid();
  EXPECT_NE(0ul, id2);
  EXPECT_NE(id1, id2);
}
#endif

#if !defined(OS_MACOSX)
// This test is disabled on Mac, since it's flaky due to ReportCrash
// taking a variable amount of time to parse and load the debug and
// symbol data for this unit test's executable before firing the
// signal handler.
//
// TODO(gspencer): turn this test process into a very small program
// with no symbols (instead of using the multiprocess testing
// framework) to reduce the ReportCrash overhead.
const char kSignalFileCrash[] = "CrashingChildProcess.die";

MULTIPROCESS_TEST_MAIN(CrashingChildProcess) {
  WaitToDie(ProcessUtilTest::GetSignalFilePath(kSignalFileCrash).c_str());
#if defined(OS_POSIX)
  // Have to disable to signal handler for segv so we can get a crash
  // instead of an abnormal termination through the crash dump handler.
  ::signal(SIGSEGV, SIG_DFL);
#endif
  // Make this process have a segmentation fault.
  volatile int* oops = NULL;
  *oops = 0xDEAD;
  return 1;
}

// This test intentionally crashes, so we don't need to run it under
// AddressSanitizer.
#if defined(ADDRESS_SANITIZER) || defined(SYZYASAN)
#define MAYBE_GetTerminationStatusCrash DISABLED_GetTerminationStatusCrash
#else
#define MAYBE_GetTerminationStatusCrash GetTerminationStatusCrash
#endif
TEST_F(ProcessUtilTest, MAYBE_GetTerminationStatusCrash) {
  const std::string signal_file =
    ProcessUtilTest::GetSignalFilePath(kSignalFileCrash);
  remove(signal_file.c_str());
  base::Process process = SpawnChild("CrashingChildProcess");
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_EQ(base::TERMINATION_STATUS_STILL_RUNNING,
            base::GetTerminationStatus(process.Handle(), &exit_code));
  EXPECT_EQ(kExpectedStillRunningExitCode, exit_code);

  SignalChildren(signal_file.c_str());
  exit_code = 42;
  base::TerminationStatus status =
      WaitForChildTermination(process.Handle(), &exit_code);
  EXPECT_EQ(base::TERMINATION_STATUS_PROCESS_CRASHED, status);

#if defined(OS_WIN)
  EXPECT_EQ(0xc0000005, exit_code);
#elif defined(OS_POSIX)
  int signaled = WIFSIGNALED(exit_code);
  EXPECT_NE(0, signaled);
  int signal = WTERMSIG(exit_code);
  EXPECT_EQ(SIGSEGV, signal);
#endif

  // Reset signal handlers back to "normal".
  base::debug::EnableInProcessStackDumping();
  remove(signal_file.c_str());
}
#endif  // !defined(OS_MACOSX)

MULTIPROCESS_TEST_MAIN(KilledChildProcess) {
  WaitToDie(ProcessUtilTest::GetSignalFilePath(kSignalFileKill).c_str());
#if defined(OS_WIN)
  // Kill ourselves.
  HANDLE handle = ::OpenProcess(PROCESS_ALL_ACCESS, 0, ::GetCurrentProcessId());
  ::TerminateProcess(handle, kExpectedKilledExitCode);
#elif defined(OS_POSIX)
  // Send a SIGKILL to this process, just like the OOM killer would.
  ::kill(getpid(), SIGKILL);
#endif
  return 1;
}

#if defined(OS_POSIX)
MULTIPROCESS_TEST_MAIN(TerminatedChildProcess) {
  WaitToDie(ProcessUtilTest::GetSignalFilePath(kSignalFileTerm).c_str());
  // Send a SIGTERM to this process.
  ::kill(getpid(), SIGTERM);
  return 1;
}
#endif

TEST_F(ProcessUtilTest, GetTerminationStatusSigKill) {
  const std::string signal_file =
    ProcessUtilTest::GetSignalFilePath(kSignalFileKill);
  remove(signal_file.c_str());
  base::Process process = SpawnChild("KilledChildProcess");
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_EQ(base::TERMINATION_STATUS_STILL_RUNNING,
            base::GetTerminationStatus(process.Handle(), &exit_code));
  EXPECT_EQ(kExpectedStillRunningExitCode, exit_code);

  SignalChildren(signal_file.c_str());
  exit_code = 42;
  base::TerminationStatus status =
      WaitForChildTermination(process.Handle(), &exit_code);
#if defined(OS_CHROMEOS)
  EXPECT_EQ(base::TERMINATION_STATUS_PROCESS_WAS_KILLED_BY_OOM, status);
#else
  EXPECT_EQ(base::TERMINATION_STATUS_PROCESS_WAS_KILLED, status);
#endif

#if defined(OS_WIN)
  EXPECT_EQ(kExpectedKilledExitCode, exit_code);
#elif defined(OS_POSIX)
  int signaled = WIFSIGNALED(exit_code);
  EXPECT_NE(0, signaled);
  int signal = WTERMSIG(exit_code);
  EXPECT_EQ(SIGKILL, signal);
#endif
  remove(signal_file.c_str());
}

#if defined(OS_POSIX)
TEST_F(ProcessUtilTest, GetTerminationStatusSigTerm) {
  const std::string signal_file =
    ProcessUtilTest::GetSignalFilePath(kSignalFileTerm);
  remove(signal_file.c_str());
  base::Process process = SpawnChild("TerminatedChildProcess");
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_EQ(base::TERMINATION_STATUS_STILL_RUNNING,
            base::GetTerminationStatus(process.Handle(), &exit_code));
  EXPECT_EQ(kExpectedStillRunningExitCode, exit_code);

  SignalChildren(signal_file.c_str());
  exit_code = 42;
  base::TerminationStatus status =
      WaitForChildTermination(process.Handle(), &exit_code);
  EXPECT_EQ(base::TERMINATION_STATUS_PROCESS_WAS_KILLED, status);

  int signaled = WIFSIGNALED(exit_code);
  EXPECT_NE(0, signaled);
  int signal = WTERMSIG(exit_code);
  EXPECT_EQ(SIGTERM, signal);
  remove(signal_file.c_str());
}
#endif

#if defined(OS_WIN)
// TODO(estade): if possible, port this test.
TEST_F(ProcessUtilTest, GetAppOutput) {
  // Let's create a decently long message.
  std::string message;
  for (int i = 0; i < 1025; i++) {  // 1025 so it does not end on a kilo-byte
                                    // boundary.
    message += "Hello!";
  }
  // cmd.exe's echo always adds a \r\n to its output.
  std::string expected(message);
  expected += "\r\n";

  FilePath cmd(L"cmd.exe");
  base::CommandLine cmd_line(cmd);
  cmd_line.AppendArg("/c");
  cmd_line.AppendArg("echo " + message + "");
  std::string output;
  ASSERT_TRUE(base::GetAppOutput(cmd_line, &output));
  EXPECT_EQ(expected, output);

  // Let's make sure stderr is ignored.
  base::CommandLine other_cmd_line(cmd);
  other_cmd_line.AppendArg("/c");
  // http://msdn.microsoft.com/library/cc772622.aspx
  cmd_line.AppendArg("echo " + message + " >&2");
  output.clear();
  ASSERT_TRUE(base::GetAppOutput(other_cmd_line, &output));
  EXPECT_EQ("", output);
}

// TODO(estade): if possible, port this test.
TEST_F(ProcessUtilTest, LaunchAsUser) {
  base::UserTokenHandle token;
  ASSERT_TRUE(OpenProcessToken(GetCurrentProcess(), TOKEN_ALL_ACCESS, &token));
  base::LaunchOptions options;
  options.as_user = token;
  EXPECT_TRUE(base::LaunchProcess(MakeCmdLine("SimpleChildProcess"),
                                  options).IsValid());
}

static const char kEventToTriggerHandleSwitch[] = "event-to-trigger-handle";

MULTIPROCESS_TEST_MAIN(TriggerEventChildProcess) {
  std::string handle_value_string =
      base::CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
          kEventToTriggerHandleSwitch);
  CHECK(!handle_value_string.empty());

  uint64 handle_value_uint64;
  CHECK(base::StringToUint64(handle_value_string, &handle_value_uint64));
  // Give ownership of the handle to |event|.
  base::WaitableEvent event(base::win::ScopedHandle(
      reinterpret_cast<HANDLE>(handle_value_uint64)));

  event.Signal();

  return 0;
}

TEST_F(ProcessUtilTest, InheritSpecifiedHandles) {
  // Manually create the event, so that it can be inheritable.
  SECURITY_ATTRIBUTES security_attributes = {};
  security_attributes.nLength = static_cast<DWORD>(sizeof(security_attributes));
  security_attributes.lpSecurityDescriptor = NULL;
  security_attributes.bInheritHandle = true;

  // Takes ownership of the event handle.
  base::WaitableEvent event(base::win::ScopedHandle(
      CreateEvent(&security_attributes, true, false, NULL)));
  base::HandlesToInheritVector handles_to_inherit;
  handles_to_inherit.push_back(event.handle());
  base::LaunchOptions options;
  options.handles_to_inherit = &handles_to_inherit;

  base::CommandLine cmd_line = MakeCmdLine("TriggerEventChildProcess");
  cmd_line.AppendSwitchASCII(kEventToTriggerHandleSwitch,
      base::Uint64ToString(reinterpret_cast<uint64>(event.handle())));

  // This functionality actually requires Vista or later. Make sure that it
  // fails properly on XP.
  if (base::win::GetVersion() < base::win::VERSION_VISTA) {
    EXPECT_FALSE(base::LaunchProcess(cmd_line, options).IsValid());
    return;
  }

  // Launch the process and wait for it to trigger the event.
  ASSERT_TRUE(base::LaunchProcess(cmd_line, options).IsValid());
  EXPECT_TRUE(event.TimedWait(TestTimeouts::action_max_timeout()));
}
#endif  // defined(OS_WIN)

#if defined(OS_POSIX)

namespace {

// Returns the maximum number of files that a process can have open.
// Returns 0 on error.
int GetMaxFilesOpenInProcess() {
  struct rlimit rlim;
  if (getrlimit(RLIMIT_NOFILE, &rlim) != 0) {
    return 0;
  }

  // rlim_t is a uint64 - clip to maxint. We do this since FD #s are ints
  // which are all 32 bits on the supported platforms.
  rlim_t max_int = static_cast<rlim_t>(std::numeric_limits<int32>::max());
  if (rlim.rlim_cur > max_int) {
    return max_int;
  }

  return rlim.rlim_cur;
}

const int kChildPipe = 20;  // FD # for write end of pipe in child process.

#if defined(OS_MACOSX)

// <http://opensource.apple.com/source/xnu/xnu-2422.1.72/bsd/sys/guarded.h>
#if !defined(_GUARDID_T)
#define _GUARDID_T
typedef __uint64_t guardid_t;
#endif  // _GUARDID_T

// From .../MacOSX10.9.sdk/usr/include/sys/syscall.h
#if !defined(SYS_change_fdguard_np)
#define SYS_change_fdguard_np 444
#endif

// <http://opensource.apple.com/source/xnu/xnu-2422.1.72/bsd/sys/guarded.h>
#if !defined(GUARD_DUP)
#define GUARD_DUP (1u << 1)
#endif

// <http://opensource.apple.com/source/xnu/xnu-2422.1.72/bsd/kern/kern_guarded.c?txt>
//
// Atomically replaces |guard|/|guardflags| with |nguard|/|nguardflags| on |fd|.
int change_fdguard_np(int fd,
                      const guardid_t *guard, u_int guardflags,
                      const guardid_t *nguard, u_int nguardflags,
                      int *fdflagsp) {
  return syscall(SYS_change_fdguard_np, fd, guard, guardflags,
                 nguard, nguardflags, fdflagsp);
}

// Attempt to set a file-descriptor guard on |fd|.  In case of success, remove
// it and return |true| to indicate that it can be guarded.  Returning |false|
// means either that |fd| is guarded by some other code, or more likely EBADF.
//
// Starting with 10.9, libdispatch began setting GUARD_DUP on a file descriptor.
// Unfortunately, it is spun up as part of +[NSApplication initialize], which is
// not really something that Chromium can avoid using on OSX.  See
// <http://crbug.com/338157>.  This function allows querying whether the file
// descriptor is guarded before attempting to close it.
bool CanGuardFd(int fd) {
  // The syscall is first provided in 10.9/Mavericks.
  if (!base::mac::IsOSMavericksOrLater())
    return true;

  // Saves the original flags to reset later.
  int original_fdflags = 0;

  // This can be any value at all, it just has to match up between the two
  // calls.
  const guardid_t kGuard = 15;

  // Attempt to change the guard.  This can fail with EBADF if the file
  // descriptor is bad, or EINVAL if the fd already has a guard set.
  int ret =
      change_fdguard_np(fd, NULL, 0, &kGuard, GUARD_DUP, &original_fdflags);
  if (ret == -1)
    return false;

  // Remove the guard.  It should not be possible to fail in removing the guard
  // just added.
  ret = change_fdguard_np(fd, &kGuard, GUARD_DUP, NULL, 0, &original_fdflags);
  DPCHECK(ret == 0);

  return true;
}
#endif  // OS_MACOSX

}  // namespace

MULTIPROCESS_TEST_MAIN(ProcessUtilsLeakFDChildProcess) {
  // This child process counts the number of open FDs, it then writes that
  // number out to a pipe connected to the parent.
  int num_open_files = 0;
  int write_pipe = kChildPipe;
  int max_files = GetMaxFilesOpenInProcess();
  for (int i = STDERR_FILENO + 1; i < max_files; i++) {
#if defined(OS_MACOSX)
    // Ignore guarded or invalid file descriptors.
    if (!CanGuardFd(i))
      continue;
#endif

    if (i != kChildPipe) {
      int fd;
      if ((fd = HANDLE_EINTR(dup(i))) != -1) {
        close(fd);
        num_open_files += 1;
      }
    }
  }

  int written = HANDLE_EINTR(write(write_pipe, &num_open_files,
                                   sizeof(num_open_files)));
  DCHECK_EQ(static_cast<size_t>(written), sizeof(num_open_files));
  int ret = IGNORE_EINTR(close(write_pipe));
  DPCHECK(ret == 0);

  return 0;
}

int ProcessUtilTest::CountOpenFDsInChild() {
  int fds[2];
  if (pipe(fds) < 0)
    NOTREACHED();

  base::FileHandleMappingVector fd_mapping_vec;
  fd_mapping_vec.push_back(std::pair<int, int>(fds[1], kChildPipe));
  base::LaunchOptions options;
  options.fds_to_remap = &fd_mapping_vec;
  base::Process process =
      SpawnChildWithOptions("ProcessUtilsLeakFDChildProcess", options);
  CHECK(process.IsValid());
  int ret = IGNORE_EINTR(close(fds[1]));
  DPCHECK(ret == 0);

  // Read number of open files in client process from pipe;
  int num_open_files = -1;
  ssize_t bytes_read =
      HANDLE_EINTR(read(fds[0], &num_open_files, sizeof(num_open_files)));
  CHECK_EQ(bytes_read, static_cast<ssize_t>(sizeof(num_open_files)));

#if defined(THREAD_SANITIZER)
  // Compiler-based ThreadSanitizer makes this test slow.
  base::TimeDelta timeout = base::TimeDelta::FromSeconds(3);
#else
  base::TimeDelta timeout = base::TimeDelta::FromSeconds(1);
#endif
  int exit_code;
  CHECK(process.WaitForExitWithTimeout(timeout, &exit_code));
  ret = IGNORE_EINTR(close(fds[0]));
  DPCHECK(ret == 0);

  return num_open_files;
}

#if defined(ADDRESS_SANITIZER) || defined(THREAD_SANITIZER)
// ProcessUtilTest.FDRemapping is flaky when ran under xvfb-run on Precise.
// The problem is 100% reproducible with both ASan and TSan.
// See http://crbug.com/136720.
#define MAYBE_FDRemapping DISABLED_FDRemapping
#else
#define MAYBE_FDRemapping FDRemapping
#endif
TEST_F(ProcessUtilTest, MAYBE_FDRemapping) {
  int fds_before = CountOpenFDsInChild();

  // open some dummy fds to make sure they don't propagate over to the
  // child process.
  int dev_null = open("/dev/null", O_RDONLY);
  int sockets[2];
  socketpair(AF_UNIX, SOCK_STREAM, 0, sockets);

  int fds_after = CountOpenFDsInChild();

  ASSERT_EQ(fds_after, fds_before);

  int ret;
  ret = IGNORE_EINTR(close(sockets[0]));
  DPCHECK(ret == 0);
  ret = IGNORE_EINTR(close(sockets[1]));
  DPCHECK(ret == 0);
  ret = IGNORE_EINTR(close(dev_null));
  DPCHECK(ret == 0);
}

namespace {

std::string TestLaunchProcess(const std::vector<std::string>& args,
                              const base::EnvironmentMap& env_changes,
                              const bool clear_environ,
                              const int clone_flags) {
  base::FileHandleMappingVector fds_to_remap;

  int fds[2];
  PCHECK(pipe(fds) == 0);

  fds_to_remap.push_back(std::make_pair(fds[1], 1));
  base::LaunchOptions options;
  options.wait = true;
  options.environ = env_changes;
  options.clear_environ = clear_environ;
  options.fds_to_remap = &fds_to_remap;
#if defined(OS_LINUX)
  options.clone_flags = clone_flags;
#else
  CHECK_EQ(0, clone_flags);
#endif  // OS_LINUX
  EXPECT_TRUE(base::LaunchProcess(args, options).IsValid());
  PCHECK(IGNORE_EINTR(close(fds[1])) == 0);

  char buf[512];
  const ssize_t n = HANDLE_EINTR(read(fds[0], buf, sizeof(buf)));

  PCHECK(IGNORE_EINTR(close(fds[0])) == 0);

  return std::string(buf, n);
}

const char kLargeString[] =
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789"
    "0123456789012345678901234567890123456789012345678901234567890123456789";

}  // namespace

TEST_F(ProcessUtilTest, LaunchProcess) {
  base::EnvironmentMap env_changes;
  std::vector<std::string> echo_base_test;
  echo_base_test.push_back(kPosixShell);
  echo_base_test.push_back("-c");
  echo_base_test.push_back("echo $BASE_TEST");

  std::vector<std::string> print_env;
  print_env.push_back("/usr/bin/env");
  const int no_clone_flags = 0;
  const bool no_clear_environ = false;

  const char kBaseTest[] = "BASE_TEST";

  env_changes[kBaseTest] = "bar";
  EXPECT_EQ("bar\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));
  env_changes.clear();

  EXPECT_EQ(0, setenv(kBaseTest, "testing", 1 /* override */));
  EXPECT_EQ("testing\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));

  env_changes[kBaseTest] = std::string();
  EXPECT_EQ("\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));

  env_changes[kBaseTest] = "foo";
  EXPECT_EQ("foo\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));

  env_changes.clear();
  EXPECT_EQ(0, setenv(kBaseTest, kLargeString, 1 /* override */));
  EXPECT_EQ(std::string(kLargeString) + "\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));

  env_changes[kBaseTest] = "wibble";
  EXPECT_EQ("wibble\n",
            TestLaunchProcess(
                echo_base_test, env_changes, no_clear_environ, no_clone_flags));

#if defined(OS_LINUX)
  // Test a non-trival value for clone_flags.
  // Don't test on Valgrind as it has limited support for clone().
  if (!RunningOnValgrind()) {
    EXPECT_EQ("wibble\n", TestLaunchProcess(echo_base_test, env_changes,
                                            no_clear_environ, CLONE_FS));
  }

  EXPECT_EQ(
      "BASE_TEST=wibble\n",
      TestLaunchProcess(
          print_env, env_changes, true /* clear_environ */, no_clone_flags));
  env_changes.clear();
  EXPECT_EQ(
      "",
      TestLaunchProcess(
          print_env, env_changes, true /* clear_environ */, no_clone_flags));
#endif
}

TEST_F(ProcessUtilTest, GetAppOutput) {
  std::string output;

#if defined(OS_ANDROID)
  std::vector<std::string> argv;
  argv.push_back("sh");  // Instead of /bin/sh, force path search to find it.
  argv.push_back("-c");

  argv.push_back("exit 0");
  EXPECT_TRUE(base::GetAppOutput(base::CommandLine(argv), &output));
  EXPECT_STREQ("", output.c_str());

  argv[2] = "exit 1";
  EXPECT_FALSE(base::GetAppOutput(base::CommandLine(argv), &output));
  EXPECT_STREQ("", output.c_str());

  argv[2] = "echo foobar42";
  EXPECT_TRUE(base::GetAppOutput(base::CommandLine(argv), &output));
  EXPECT_STREQ("foobar42\n", output.c_str());
#else
  EXPECT_TRUE(base::GetAppOutput(base::CommandLine(FilePath("true")),
                                 &output));
  EXPECT_STREQ("", output.c_str());

  EXPECT_FALSE(base::GetAppOutput(base::CommandLine(FilePath("false")),
                                  &output));

  std::vector<std::string> argv;
  argv.push_back("/bin/echo");
  argv.push_back("-n");
  argv.push_back("foobar42");
  EXPECT_TRUE(base::GetAppOutput(base::CommandLine(argv), &output));
  EXPECT_STREQ("foobar42", output.c_str());
#endif  // defined(OS_ANDROID)
}

// Flakes on Android, crbug.com/375840
#if defined(OS_ANDROID)
#define MAYBE_GetAppOutputRestricted DISABLED_GetAppOutputRestricted
#else
#define MAYBE_GetAppOutputRestricted GetAppOutputRestricted
#endif
TEST_F(ProcessUtilTest, MAYBE_GetAppOutputRestricted) {
  // Unfortunately, since we can't rely on the path, we need to know where
  // everything is. So let's use /bin/sh, which is on every POSIX system, and
  // its built-ins.
  std::vector<std::string> argv;
  argv.push_back(std::string(kShellPath));  // argv[0]
  argv.push_back("-c");  // argv[1]

  // On success, should set |output|. We use |/bin/sh -c 'exit 0'| instead of
  // |true| since the location of the latter may be |/bin| or |/usr/bin| (and we
  // need absolute paths).
  argv.push_back("exit 0");   // argv[2]; equivalent to "true"
  std::string output = "abc";
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           100));
  EXPECT_STREQ("", output.c_str());

  argv[2] = "exit 1";  // equivalent to "false"
  output = "before";
  EXPECT_FALSE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                            100));
  EXPECT_STREQ("", output.c_str());

  // Amount of output exactly equal to space allowed.
  argv[2] = "echo 123456789";  // (the sh built-in doesn't take "-n")
  output.clear();
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           10));
  EXPECT_STREQ("123456789\n", output.c_str());

  // Amount of output greater than space allowed.
  output.clear();
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           5));
  EXPECT_STREQ("12345", output.c_str());

  // Amount of output less than space allowed.
  output.clear();
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           15));
  EXPECT_STREQ("123456789\n", output.c_str());

  // Zero space allowed.
  output = "abc";
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           0));
  EXPECT_STREQ("", output.c_str());
}

#if !defined(OS_MACOSX) && !defined(OS_OPENBSD)
// TODO(benwells): GetAppOutputRestricted should terminate applications
// with SIGPIPE when we have enough output. http://crbug.com/88502
TEST_F(ProcessUtilTest, GetAppOutputRestrictedSIGPIPE) {
  std::vector<std::string> argv;
  std::string output;

  argv.push_back(std::string(kShellPath));  // argv[0]
  argv.push_back("-c");
#if defined(OS_ANDROID)
  argv.push_back("while echo 12345678901234567890; do :; done");
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           10));
  EXPECT_STREQ("1234567890", output.c_str());
#else
  argv.push_back("yes");
  EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                           10));
  EXPECT_STREQ("y\ny\ny\ny\ny\n", output.c_str());
#endif
}
#endif

#if defined(ADDRESS_SANITIZER) && defined(OS_MACOSX) && \
    defined(ARCH_CPU_64_BITS)
// Times out under AddressSanitizer on 64-bit OS X, see
// http://crbug.com/298197.
#define MAYBE_GetAppOutputRestrictedNoZombies \
    DISABLED_GetAppOutputRestrictedNoZombies
#else
#define MAYBE_GetAppOutputRestrictedNoZombies GetAppOutputRestrictedNoZombies
#endif
TEST_F(ProcessUtilTest, MAYBE_GetAppOutputRestrictedNoZombies) {
  std::vector<std::string> argv;

  argv.push_back(std::string(kShellPath));  // argv[0]
  argv.push_back("-c");  // argv[1]
  argv.push_back("echo 123456789012345678901234567890");  // argv[2]

  // Run |GetAppOutputRestricted()| 300 (> default per-user processes on Mac OS
  // 10.5) times with an output buffer big enough to capture all output.
  for (int i = 0; i < 300; i++) {
    std::string output;
    EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                             100));
    EXPECT_STREQ("123456789012345678901234567890\n", output.c_str());
  }

  // Ditto, but with an output buffer too small to capture all output.
  for (int i = 0; i < 300; i++) {
    std::string output;
    EXPECT_TRUE(base::GetAppOutputRestricted(base::CommandLine(argv), &output,
                                             10));
    EXPECT_STREQ("1234567890", output.c_str());
  }
}

TEST_F(ProcessUtilTest, GetAppOutputWithExitCode) {
  // Test getting output from a successful application.
  std::vector<std::string> argv;
  std::string output;
  int exit_code;
  argv.push_back(std::string(kShellPath));  // argv[0]
  argv.push_back("-c");  // argv[1]
  argv.push_back("echo foo");  // argv[2];
  EXPECT_TRUE(base::GetAppOutputWithExitCode(base::CommandLine(argv), &output,
                                             &exit_code));
  EXPECT_STREQ("foo\n", output.c_str());
  EXPECT_EQ(exit_code, 0);

  // Test getting output from an application which fails with a specific exit
  // code.
  output.clear();
  argv[2] = "echo foo; exit 2";
  EXPECT_TRUE(base::GetAppOutputWithExitCode(base::CommandLine(argv), &output,
                                             &exit_code));
  EXPECT_STREQ("foo\n", output.c_str());
  EXPECT_EQ(exit_code, 2);
}

TEST_F(ProcessUtilTest, GetParentProcessId) {
  base::ProcessId ppid = base::GetParentProcessId(base::GetCurrentProcId());
  EXPECT_EQ(ppid, getppid());
}

// TODO(port): port those unit tests.
bool IsProcessDead(base::ProcessHandle child) {
  // waitpid() will actually reap the process which is exactly NOT what we
  // want to test for.  The good thing is that if it can't find the process
  // we'll get a nice value for errno which we can test for.
  const pid_t result = HANDLE_EINTR(waitpid(child, NULL, WNOHANG));
  return result == -1 && errno == ECHILD;
}

TEST_F(ProcessUtilTest, DelayedTermination) {
  base::Process child_process = SpawnChild("process_util_test_never_die");
  ASSERT_TRUE(child_process.IsValid());
  base::EnsureProcessTerminated(child_process.Duplicate());
  int exit_code;
  child_process.WaitForExitWithTimeout(base::TimeDelta::FromSeconds(5),
                                       &exit_code);

  // Check that process was really killed.
  EXPECT_TRUE(IsProcessDead(child_process.Handle()));
}

MULTIPROCESS_TEST_MAIN(process_util_test_never_die) {
  while (1) {
    sleep(500);
  }
  return 0;
}

TEST_F(ProcessUtilTest, ImmediateTermination) {
  base::Process child_process = SpawnChild("process_util_test_die_immediately");
  ASSERT_TRUE(child_process.IsValid());
  // Give it time to die.
  sleep(2);
  base::EnsureProcessTerminated(child_process.Duplicate());

  // Check that process was really killed.
  EXPECT_TRUE(IsProcessDead(child_process.Handle()));
}

MULTIPROCESS_TEST_MAIN(process_util_test_die_immediately) {
  return 0;
}

#if !defined(OS_ANDROID)
const char kPipeValue = '\xcc';

class ReadFromPipeDelegate : public base::LaunchOptions::PreExecDelegate {
 public:
  explicit ReadFromPipeDelegate(int fd) : fd_(fd) {}
  ~ReadFromPipeDelegate() override {}
  void RunAsyncSafe() override {
    char c;
    RAW_CHECK(HANDLE_EINTR(read(fd_, &c, 1)) == 1);
    RAW_CHECK(IGNORE_EINTR(close(fd_)) == 0);
    RAW_CHECK(c == kPipeValue);
  }

 private:
  int fd_;
  DISALLOW_COPY_AND_ASSIGN(ReadFromPipeDelegate);
};

TEST_F(ProcessUtilTest, PreExecHook) {
  int pipe_fds[2];
  ASSERT_EQ(0, pipe(pipe_fds));

  base::ScopedFD read_fd(pipe_fds[0]);
  base::ScopedFD write_fd(pipe_fds[1]);
  base::FileHandleMappingVector fds_to_remap;
  fds_to_remap.push_back(std::make_pair(read_fd.get(), read_fd.get()));

  ReadFromPipeDelegate read_from_pipe_delegate(read_fd.get());
  base::LaunchOptions options;
  options.fds_to_remap = &fds_to_remap;
  options.pre_exec_delegate = &read_from_pipe_delegate;
  base::Process process(SpawnChildWithOptions("SimpleChildProcess", options));
  ASSERT_TRUE(process.IsValid());

  read_fd.reset();
  ASSERT_EQ(1, HANDLE_EINTR(write(write_fd.get(), &kPipeValue, 1)));

  int exit_code = 42;
  EXPECT_TRUE(process.WaitForExit(&exit_code));
  EXPECT_EQ(0, exit_code);
}
#endif  // !defined(OS_ANDROID)

#endif  // defined(OS_POSIX)

#if defined(OS_LINUX)
const int kSuccess = 0;

MULTIPROCESS_TEST_MAIN(CheckPidProcess) {
  const pid_t kInitPid = 1;
  const pid_t pid = syscall(__NR_getpid);
  CHECK(pid == kInitPid);
  CHECK(getpid() == pid);
  return kSuccess;
}

#if defined(CLONE_NEWUSER) && defined(CLONE_NEWPID)
TEST_F(ProcessUtilTest, CloneFlags) {
  if (RunningOnValgrind() ||
      !base::PathExists(FilePath("/proc/self/ns/user")) ||
      !base::PathExists(FilePath("/proc/self/ns/pid"))) {
    // User or PID namespaces are not supported.
    return;
  }

  base::LaunchOptions options;
  options.clone_flags = CLONE_NEWUSER | CLONE_NEWPID;

  base::Process process(SpawnChildWithOptions("CheckPidProcess", options));
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_TRUE(process.WaitForExit(&exit_code));
  EXPECT_EQ(kSuccess, exit_code);
}
#endif

TEST(ForkWithFlagsTest, UpdatesPidCache) {
  // The libc clone function, which allows ForkWithFlags to keep the pid cache
  // up to date, does not work on Valgrind.
  if (RunningOnValgrind()) {
    return;
  }

  // Warm up the libc pid cache, if there is one.
  ASSERT_EQ(syscall(__NR_getpid), getpid());

  pid_t ctid = 0;
  const pid_t pid =
      base::ForkWithFlags(SIGCHLD | CLONE_CHILD_SETTID, nullptr, &ctid);
  if (pid == 0) {
    // In child.  Check both the raw getpid syscall and the libc getpid wrapper
    // (which may rely on a pid cache).
    RAW_CHECK(syscall(__NR_getpid) == ctid);
    RAW_CHECK(getpid() == ctid);
    _exit(kSuccess);
  }

  ASSERT_NE(-1, pid);
  int status = 42;
  ASSERT_EQ(pid, HANDLE_EINTR(waitpid(pid, &status, 0)));
  ASSERT_TRUE(WIFEXITED(status));
  EXPECT_EQ(kSuccess, WEXITSTATUS(status));
}

MULTIPROCESS_TEST_MAIN(CheckCwdProcess) {
  base::FilePath expected;
  CHECK(base::GetTempDir(&expected));
  base::FilePath actual;
  CHECK(base::GetCurrentDirectory(&actual));
  CHECK(actual == expected);
  return kSuccess;
}

TEST_F(ProcessUtilTest, CurrentDirectory) {
  // TODO(rickyz): Add support for passing arguments to multiprocess children,
  // then create a special directory for this test.
  base::FilePath tmp_dir;
  ASSERT_TRUE(base::GetTempDir(&tmp_dir));

  base::LaunchOptions options;
  options.current_directory = tmp_dir;

  base::Process process(SpawnChildWithOptions("CheckCwdProcess", options));
  ASSERT_TRUE(process.IsValid());

  int exit_code = 42;
  EXPECT_TRUE(process.WaitForExit(&exit_code));
  EXPECT_EQ(kSuccess, exit_code);
}

TEST_F(ProcessUtilTest, InvalidCurrentDirectory) {
  base::LaunchOptions options;
  options.current_directory = base::FilePath("/dev/null");

  base::Process process(SpawnChildWithOptions("SimpleChildProcess", options));
  ASSERT_TRUE(process.IsValid());

  int exit_code = kSuccess;
  EXPECT_TRUE(process.WaitForExit(&exit_code));
  EXPECT_NE(kSuccess, exit_code);
}
#endif

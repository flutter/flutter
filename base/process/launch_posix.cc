// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/launch.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <setjmp.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/resource.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <iterator>
#include <limits>
#include <set>

#include "base/allocator/type_profiler_control.h"
#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/debug/debugger.h"
#include "base/debug/stack_trace.h"
#include "base/files/dir_reader_posix.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/posix/eintr_wrapper.h"
#include "base/process/process.h"
#include "base/process/process_metrics.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/waitable_event.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "base/third_party/valgrind/valgrind.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread_restrictions.h"
#include "build/build_config.h"

#if defined(OS_LINUX)
#include <sys/prctl.h>
#endif

#if defined(OS_CHROMEOS)
#include <sys/ioctl.h>
#endif

#if defined(OS_FREEBSD)
#include <sys/event.h>
#include <sys/ucontext.h>
#endif

#if defined(OS_MACOSX)
#include <crt_externs.h>
#include <sys/event.h>
#else
extern char** environ;
#endif

namespace base {

namespace {

// Get the process's "environment" (i.e. the thing that setenv/getenv
// work with).
char** GetEnvironment() {
#if defined(OS_MACOSX)
  return *_NSGetEnviron();
#else
  return environ;
#endif
}

// Set the process's "environment" (i.e. the thing that setenv/getenv
// work with).
void SetEnvironment(char** env) {
#if defined(OS_MACOSX)
  *_NSGetEnviron() = env;
#else
  environ = env;
#endif
}

// Set the calling thread's signal mask to new_sigmask and return
// the previous signal mask.
sigset_t SetSignalMask(const sigset_t& new_sigmask) {
  sigset_t old_sigmask;
#if defined(OS_ANDROID)
  // POSIX says pthread_sigmask() must be used in multi-threaded processes,
  // but Android's pthread_sigmask() was broken until 4.1:
  // https://code.google.com/p/android/issues/detail?id=15337
  // http://stackoverflow.com/questions/13777109/pthread-sigmask-on-android-not-working
  RAW_CHECK(sigprocmask(SIG_SETMASK, &new_sigmask, &old_sigmask) == 0);
#else
  RAW_CHECK(pthread_sigmask(SIG_SETMASK, &new_sigmask, &old_sigmask) == 0);
#endif
  return old_sigmask;
}

#if !defined(OS_LINUX) || \
    (!defined(__i386__) && !defined(__x86_64__) && !defined(__arm__))
void ResetChildSignalHandlersToDefaults() {
  // The previous signal handlers are likely to be meaningless in the child's
  // context so we reset them to the defaults for now. http://crbug.com/44953
  // These signal handlers are set up at least in browser_main_posix.cc:
  // BrowserMainPartsPosix::PreEarlyInitialization and stack_trace_posix.cc:
  // EnableInProcessStackDumping.
  signal(SIGHUP, SIG_DFL);
  signal(SIGINT, SIG_DFL);
  signal(SIGILL, SIG_DFL);
  signal(SIGABRT, SIG_DFL);
  signal(SIGFPE, SIG_DFL);
  signal(SIGBUS, SIG_DFL);
  signal(SIGSEGV, SIG_DFL);
  signal(SIGSYS, SIG_DFL);
  signal(SIGTERM, SIG_DFL);
}

#else

// TODO(jln): remove the Linux special case once kernels are fixed.

// Internally the kernel makes sigset_t an array of long large enough to have
// one bit per signal.
typedef uint64_t kernel_sigset_t;

// This is what struct sigaction looks like to the kernel at least on X86 and
// ARM. MIPS, for instance, is very different.
struct kernel_sigaction {
  void* k_sa_handler;  // For this usage it only needs to be a generic pointer.
  unsigned long k_sa_flags;
  void* k_sa_restorer;  // For this usage it only needs to be a generic pointer.
  kernel_sigset_t k_sa_mask;
};

// glibc's sigaction() will prevent access to sa_restorer, so we need to roll
// our own.
int sys_rt_sigaction(int sig, const struct kernel_sigaction* act,
                     struct kernel_sigaction* oact) {
  return syscall(SYS_rt_sigaction, sig, act, oact, sizeof(kernel_sigset_t));
}

// This function is intended to be used in between fork() and execve() and will
// reset all signal handlers to the default.
// The motivation for going through all of them is that sa_restorer can leak
// from parents and help defeat ASLR on buggy kernels.  We reset it to NULL.
// See crbug.com/177956.
void ResetChildSignalHandlersToDefaults(void) {
  for (int signum = 1; ; ++signum) {
    struct kernel_sigaction act = {0};
    int sigaction_get_ret = sys_rt_sigaction(signum, NULL, &act);
    if (sigaction_get_ret && errno == EINVAL) {
#if !defined(NDEBUG)
      // Linux supports 32 real-time signals from 33 to 64.
      // If the number of signals in the Linux kernel changes, someone should
      // look at this code.
      const int kNumberOfSignals = 64;
      RAW_CHECK(signum == kNumberOfSignals + 1);
#endif  // !defined(NDEBUG)
      break;
    }
    // All other failures are fatal.
    if (sigaction_get_ret) {
      RAW_LOG(FATAL, "sigaction (get) failed.");
    }

    // The kernel won't allow to re-set SIGKILL or SIGSTOP.
    if (signum != SIGSTOP && signum != SIGKILL) {
      act.k_sa_handler = reinterpret_cast<void*>(SIG_DFL);
      act.k_sa_restorer = NULL;
      if (sys_rt_sigaction(signum, &act, NULL)) {
        RAW_LOG(FATAL, "sigaction (set) failed.");
      }
    }
#if !defined(NDEBUG)
    // Now ask the kernel again and check that no restorer will leak.
    if (sys_rt_sigaction(signum, NULL, &act) || act.k_sa_restorer) {
      RAW_LOG(FATAL, "Cound not fix sa_restorer.");
    }
#endif  // !defined(NDEBUG)
  }
}
#endif  // !defined(OS_LINUX) ||
        // (!defined(__i386__) && !defined(__x86_64__) && !defined(__arm__))

#if defined(OS_LINUX)
bool IsRunningOnValgrind() {
  return RUNNING_ON_VALGRIND;
}

// This function runs on the stack specified on the clone call. It uses longjmp
// to switch back to the original stack so the child can return from sys_clone.
int CloneHelper(void* arg) {
  jmp_buf* env_ptr = reinterpret_cast<jmp_buf*>(arg);
  longjmp(*env_ptr, 1);

  // Should not be reached.
  RAW_CHECK(false);
  return 1;
}

// This function is noinline to ensure that stack_buf is below the stack pointer
// that is saved when setjmp is called below. This is needed because when
// compiled with FORTIFY_SOURCE, glibc's longjmp checks that the stack is moved
// upwards. See crbug.com/442912 for more details.
#if defined(ADDRESS_SANITIZER)
// Disable AddressSanitizer instrumentation for this function to make sure
// |stack_buf| is allocated on thread stack instead of ASan's fake stack.
// Under ASan longjmp() will attempt to clean up the area between the old and
// new stack pointers and print a warning that may confuse the user.
__attribute__((no_sanitize_address))
#endif
NOINLINE pid_t CloneAndLongjmpInChild(unsigned long flags,
                                      pid_t* ptid,
                                      pid_t* ctid,
                                      jmp_buf* env) {
  // We use the libc clone wrapper instead of making the syscall
  // directly because making the syscall may fail to update the libc's
  // internal pid cache. The libc interface unfortunately requires
  // specifying a new stack, so we use setjmp/longjmp to emulate
  // fork-like behavior.
  char stack_buf[PTHREAD_STACK_MIN];
#if defined(ARCH_CPU_X86_FAMILY) || defined(ARCH_CPU_ARM_FAMILY) || \
    defined(ARCH_CPU_MIPS64_FAMILY) || defined(ARCH_CPU_MIPS_FAMILY)
  // The stack grows downward.
  void* stack = stack_buf + sizeof(stack_buf);
#else
#error "Unsupported architecture"
#endif
  return clone(&CloneHelper, stack, flags, env, ptid, nullptr, ctid);
}
#endif  // defined(OS_LINUX)

}  // anonymous namespace

// Functor for |ScopedDIR| (below).
struct ScopedDIRClose {
  inline void operator()(DIR* x) const {
    if (x)
      closedir(x);
  }
};

// Automatically closes |DIR*|s.
typedef scoped_ptr<DIR, ScopedDIRClose> ScopedDIR;

#if defined(OS_LINUX)
static const char kFDDir[] = "/proc/self/fd";
#elif defined(OS_MACOSX)
static const char kFDDir[] = "/dev/fd";
#elif defined(OS_SOLARIS)
static const char kFDDir[] = "/dev/fd";
#elif defined(OS_FREEBSD)
static const char kFDDir[] = "/dev/fd";
#elif defined(OS_OPENBSD)
static const char kFDDir[] = "/dev/fd";
#elif defined(OS_ANDROID)
static const char kFDDir[] = "/proc/self/fd";
#endif

void CloseSuperfluousFds(const base::InjectiveMultimap& saved_mapping) {
  // DANGER: no calls to malloc or locks are allowed from now on:
  // http://crbug.com/36678

  // Get the maximum number of FDs possible.
  size_t max_fds = GetMaxFds();

  DirReaderPosix fd_dir(kFDDir);
  if (!fd_dir.IsValid()) {
    // Fallback case: Try every possible fd.
    for (size_t i = 0; i < max_fds; ++i) {
      const int fd = static_cast<int>(i);
      if (fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO)
        continue;
      // Cannot use STL iterators here, since debug iterators use locks.
      size_t j;
      for (j = 0; j < saved_mapping.size(); j++) {
        if (fd == saved_mapping[j].dest)
          break;
      }
      if (j < saved_mapping.size())
        continue;

      // Since we're just trying to close anything we can find,
      // ignore any error return values of close().
      close(fd);
    }
    return;
  }

  const int dir_fd = fd_dir.fd();

  for ( ; fd_dir.Next(); ) {
    // Skip . and .. entries.
    if (fd_dir.name()[0] == '.')
      continue;

    char *endptr;
    errno = 0;
    const long int fd = strtol(fd_dir.name(), &endptr, 10);
    if (fd_dir.name()[0] == 0 || *endptr || fd < 0 || errno)
      continue;
    if (fd == STDIN_FILENO || fd == STDOUT_FILENO || fd == STDERR_FILENO)
      continue;
    // Cannot use STL iterators here, since debug iterators use locks.
    size_t i;
    for (i = 0; i < saved_mapping.size(); i++) {
      if (fd == saved_mapping[i].dest)
        break;
    }
    if (i < saved_mapping.size())
      continue;
    if (fd == dir_fd)
      continue;

    // When running under Valgrind, Valgrind opens several FDs for its
    // own use and will complain if we try to close them.  All of
    // these FDs are >= |max_fds|, so we can check against that here
    // before closing.  See https://bugs.kde.org/show_bug.cgi?id=191758
    if (fd < static_cast<int>(max_fds)) {
      int ret = IGNORE_EINTR(close(fd));
      DPCHECK(ret == 0);
    }
  }
}

Process LaunchProcess(const CommandLine& cmdline,
                      const LaunchOptions& options) {
  return LaunchProcess(cmdline.argv(), options);
}

Process LaunchProcess(const std::vector<std::string>& argv,
                      const LaunchOptions& options) {
  size_t fd_shuffle_size = 0;
  if (options.fds_to_remap) {
    fd_shuffle_size = options.fds_to_remap->size();
  }

  InjectiveMultimap fd_shuffle1;
  InjectiveMultimap fd_shuffle2;
  fd_shuffle1.reserve(fd_shuffle_size);
  fd_shuffle2.reserve(fd_shuffle_size);

  scoped_ptr<char* []> argv_cstr(new char* [argv.size() + 1]);
  for (size_t i = 0; i < argv.size(); i++) {
    argv_cstr[i] = const_cast<char*>(argv[i].c_str());
  }
  argv_cstr[argv.size()] = NULL;

  scoped_ptr<char*[]> new_environ;
  char* const empty_environ = NULL;
  char* const* old_environ = GetEnvironment();
  if (options.clear_environ)
    old_environ = &empty_environ;
  if (!options.environ.empty())
    new_environ = AlterEnvironment(old_environ, options.environ);

  sigset_t full_sigset;
  sigfillset(&full_sigset);
  const sigset_t orig_sigmask = SetSignalMask(full_sigset);

  const char* current_directory = nullptr;
  if (!options.current_directory.empty()) {
    current_directory = options.current_directory.value().c_str();
  }

  pid_t pid;
#if defined(OS_LINUX)
  if (options.clone_flags) {
    // Signal handling in this function assumes the creation of a new
    // process, so we check that a thread is not being created by mistake
    // and that signal handling follows the process-creation rules.
    RAW_CHECK(
        !(options.clone_flags & (CLONE_SIGHAND | CLONE_THREAD | CLONE_VM)));

    // We specify a null ptid and ctid.
    RAW_CHECK(
        !(options.clone_flags &
          (CLONE_CHILD_CLEARTID | CLONE_CHILD_SETTID | CLONE_PARENT_SETTID)));

    // Since we use waitpid, we do not support custom termination signals in the
    // clone flags.
    RAW_CHECK((options.clone_flags & 0xff) == 0);

    pid = ForkWithFlags(options.clone_flags | SIGCHLD, nullptr, nullptr);
  } else
#endif
  {
    pid = fork();
  }

  // Always restore the original signal mask in the parent.
  if (pid != 0) {
    SetSignalMask(orig_sigmask);
  }

  if (pid < 0) {
    DPLOG(ERROR) << "fork";
    return Process();
  } else if (pid == 0) {
    // Child process

    // DANGER: no calls to malloc or locks are allowed from now on:
    // http://crbug.com/36678

    // DANGER: fork() rule: in the child, if you don't end up doing exec*(),
    // you call _exit() instead of exit(). This is because _exit() does not
    // call any previously-registered (in the parent) exit handlers, which
    // might do things like block waiting for threads that don't even exist
    // in the child.

    // If a child process uses the readline library, the process block forever.
    // In BSD like OSes including OS X it is safe to assign /dev/null as stdin.
    // See http://crbug.com/56596.
    base::ScopedFD null_fd(HANDLE_EINTR(open("/dev/null", O_RDONLY)));
    if (!null_fd.is_valid()) {
      RAW_LOG(ERROR, "Failed to open /dev/null");
      _exit(127);
    }

    int new_fd = HANDLE_EINTR(dup2(null_fd.get(), STDIN_FILENO));
    if (new_fd != STDIN_FILENO) {
      RAW_LOG(ERROR, "Failed to dup /dev/null for stdin");
      _exit(127);
    }

    if (options.new_process_group) {
      // Instead of inheriting the process group ID of the parent, the child
      // starts off a new process group with pgid equal to its process ID.
      if (setpgid(0, 0) < 0) {
        RAW_LOG(ERROR, "setpgid failed");
        _exit(127);
      }
    }

    // Stop type-profiler.
    // The profiler should be stopped between fork and exec since it inserts
    // locks at new/delete expressions.  See http://crbug.com/36678.
    base::type_profiler::Controller::Stop();

    if (options.maximize_rlimits) {
      // Some resource limits need to be maximal in this child.
      for (size_t i = 0; i < options.maximize_rlimits->size(); ++i) {
        const int resource = (*options.maximize_rlimits)[i];
        struct rlimit limit;
        if (getrlimit(resource, &limit) < 0) {
          RAW_LOG(WARNING, "getrlimit failed");
        } else if (limit.rlim_cur < limit.rlim_max) {
          limit.rlim_cur = limit.rlim_max;
          if (setrlimit(resource, &limit) < 0) {
            RAW_LOG(WARNING, "setrlimit failed");
          }
        }
      }
    }

#if defined(OS_MACOSX)
    RestoreDefaultExceptionHandler();
    if (!options.replacement_bootstrap_name.empty())
      ReplaceBootstrapPort(options.replacement_bootstrap_name);
#endif  // defined(OS_MACOSX)

    ResetChildSignalHandlersToDefaults();
    SetSignalMask(orig_sigmask);

#if 0
    // When debugging it can be helpful to check that we really aren't making
    // any hidden calls to malloc.
    void *malloc_thunk =
        reinterpret_cast<void*>(reinterpret_cast<intptr_t>(malloc) & ~4095);
    mprotect(malloc_thunk, 4096, PROT_READ | PROT_WRITE | PROT_EXEC);
    memset(reinterpret_cast<void*>(malloc), 0xff, 8);
#endif  // 0

#if defined(OS_CHROMEOS)
    if (options.ctrl_terminal_fd >= 0) {
      // Set process' controlling terminal.
      if (HANDLE_EINTR(setsid()) != -1) {
        if (HANDLE_EINTR(
                ioctl(options.ctrl_terminal_fd, TIOCSCTTY, NULL)) == -1) {
          RAW_LOG(WARNING, "ioctl(TIOCSCTTY), ctrl terminal not set");
        }
      } else {
        RAW_LOG(WARNING, "setsid failed, ctrl terminal not set");
      }
    }
#endif  // defined(OS_CHROMEOS)

    if (options.fds_to_remap) {
      // Cannot use STL iterators here, since debug iterators use locks.
      for (size_t i = 0; i < options.fds_to_remap->size(); ++i) {
        const FileHandleMappingVector::value_type& value =
            (*options.fds_to_remap)[i];
        fd_shuffle1.push_back(InjectionArc(value.first, value.second, false));
        fd_shuffle2.push_back(InjectionArc(value.first, value.second, false));
      }
    }

    if (!options.environ.empty() || options.clear_environ)
      SetEnvironment(new_environ.get());

    // fd_shuffle1 is mutated by this call because it cannot malloc.
    if (!ShuffleFileDescriptors(&fd_shuffle1))
      _exit(127);

    CloseSuperfluousFds(fd_shuffle2);

    // Set NO_NEW_PRIVS by default. Since NO_NEW_PRIVS only exists in kernel
    // 3.5+, do not check the return value of prctl here.
#if defined(OS_LINUX)
#ifndef PR_SET_NO_NEW_PRIVS
#define PR_SET_NO_NEW_PRIVS 38
#endif
    if (!options.allow_new_privs) {
      if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) && errno != EINVAL) {
        // Only log if the error is not EINVAL (i.e. not supported).
        RAW_LOG(FATAL, "prctl(PR_SET_NO_NEW_PRIVS) failed");
      }
    }

    if (options.kill_on_parent_death) {
      if (prctl(PR_SET_PDEATHSIG, SIGKILL) != 0) {
        RAW_LOG(ERROR, "prctl(PR_SET_PDEATHSIG) failed");
        _exit(127);
      }
    }
#endif

    if (current_directory != nullptr) {
      RAW_CHECK(chdir(current_directory) == 0);
    }

    if (options.pre_exec_delegate != nullptr) {
      options.pre_exec_delegate->RunAsyncSafe();
    }

    execvp(argv_cstr[0], argv_cstr.get());

    RAW_LOG(ERROR, "LaunchProcess: failed to execvp:");
    RAW_LOG(ERROR, argv_cstr[0]);
    _exit(127);
  } else {
    // Parent process
    if (options.wait) {
      // While this isn't strictly disk IO, waiting for another process to
      // finish is the sort of thing ThreadRestrictions is trying to prevent.
      base::ThreadRestrictions::AssertIOAllowed();
      pid_t ret = HANDLE_EINTR(waitpid(pid, 0, 0));
      DPCHECK(ret > 0);
    }
  }

  return Process(pid);
}

void RaiseProcessToHighPriority() {
  // On POSIX, we don't actually do anything here.  We could try to nice() or
  // setpriority() or sched_getscheduler, but these all require extra rights.
}

// Return value used by GetAppOutputInternal to encapsulate the various exit
// scenarios from the function.
enum GetAppOutputInternalResult {
  EXECUTE_FAILURE,
  EXECUTE_SUCCESS,
  GOT_MAX_OUTPUT,
};

// Executes the application specified by |argv| and wait for it to exit. Stores
// the output (stdout) in |output|. If |do_search_path| is set, it searches the
// path for the application; in that case, |envp| must be null, and it will use
// the current environment. If |do_search_path| is false, |argv[0]| should fully
// specify the path of the application, and |envp| will be used as the
// environment. Redirects stderr to /dev/null.
// If we successfully start the application and get all requested output, we
// return GOT_MAX_OUTPUT, or if there is a problem starting or exiting
// the application we return RUN_FAILURE. Otherwise we return EXECUTE_SUCCESS.
// The GOT_MAX_OUTPUT return value exists so a caller that asks for limited
// output can treat this as a success, despite having an exit code of SIG_PIPE
// due to us closing the output pipe.
// In the case of EXECUTE_SUCCESS, the application exit code will be returned
// in |*exit_code|, which should be checked to determine if the application
// ran successfully.
static GetAppOutputInternalResult GetAppOutputInternal(
    const std::vector<std::string>& argv,
    char* const envp[],
    std::string* output,
    size_t max_output,
    bool do_search_path,
    int* exit_code) {
  // Doing a blocking wait for another command to finish counts as IO.
  base::ThreadRestrictions::AssertIOAllowed();
  // exit_code must be supplied so calling function can determine success.
  DCHECK(exit_code);
  *exit_code = EXIT_FAILURE;

  int pipe_fd[2];
  pid_t pid;
  InjectiveMultimap fd_shuffle1, fd_shuffle2;
  scoped_ptr<char*[]> argv_cstr(new char*[argv.size() + 1]);

  fd_shuffle1.reserve(3);
  fd_shuffle2.reserve(3);

  // Either |do_search_path| should be false or |envp| should be null, but not
  // both.
  DCHECK(!do_search_path ^ !envp);

  if (pipe(pipe_fd) < 0)
    return EXECUTE_FAILURE;

  switch (pid = fork()) {
    case -1:  // error
      close(pipe_fd[0]);
      close(pipe_fd[1]);
      return EXECUTE_FAILURE;
    case 0:  // child
      {
        // DANGER: no calls to malloc or locks are allowed from now on:
        // http://crbug.com/36678

#if defined(OS_MACOSX)
        RestoreDefaultExceptionHandler();
#endif

        // Obscure fork() rule: in the child, if you don't end up doing exec*(),
        // you call _exit() instead of exit(). This is because _exit() does not
        // call any previously-registered (in the parent) exit handlers, which
        // might do things like block waiting for threads that don't even exist
        // in the child.
        int dev_null = open("/dev/null", O_WRONLY);
        if (dev_null < 0)
          _exit(127);

        // Stop type-profiler.
        // The profiler should be stopped between fork and exec since it inserts
        // locks at new/delete expressions.  See http://crbug.com/36678.
        base::type_profiler::Controller::Stop();

        fd_shuffle1.push_back(InjectionArc(pipe_fd[1], STDOUT_FILENO, true));
        fd_shuffle1.push_back(InjectionArc(dev_null, STDERR_FILENO, true));
        fd_shuffle1.push_back(InjectionArc(dev_null, STDIN_FILENO, true));
        // Adding another element here? Remeber to increase the argument to
        // reserve(), above.

        for (size_t i = 0; i < fd_shuffle1.size(); ++i)
          fd_shuffle2.push_back(fd_shuffle1[i]);

        if (!ShuffleFileDescriptors(&fd_shuffle1))
          _exit(127);

        CloseSuperfluousFds(fd_shuffle2);

        for (size_t i = 0; i < argv.size(); i++)
          argv_cstr[i] = const_cast<char*>(argv[i].c_str());
        argv_cstr[argv.size()] = NULL;
        if (do_search_path)
          execvp(argv_cstr[0], argv_cstr.get());
        else
          execve(argv_cstr[0], argv_cstr.get(), envp);
        _exit(127);
      }
    default:  // parent
      {
        // Close our writing end of pipe now. Otherwise later read would not
        // be able to detect end of child's output (in theory we could still
        // write to the pipe).
        close(pipe_fd[1]);

        output->clear();
        char buffer[256];
        size_t output_buf_left = max_output;
        ssize_t bytes_read = 1;  // A lie to properly handle |max_output == 0|
                                 // case in the logic below.

        while (output_buf_left > 0) {
          bytes_read = HANDLE_EINTR(read(pipe_fd[0], buffer,
                                    std::min(output_buf_left, sizeof(buffer))));
          if (bytes_read <= 0)
            break;
          output->append(buffer, bytes_read);
          output_buf_left -= static_cast<size_t>(bytes_read);
        }
        close(pipe_fd[0]);

        // Always wait for exit code (even if we know we'll declare
        // GOT_MAX_OUTPUT).
        Process process(pid);
        bool success = process.WaitForExit(exit_code);

        // If we stopped because we read as much as we wanted, we return
        // GOT_MAX_OUTPUT (because the child may exit due to |SIGPIPE|).
        if (!output_buf_left && bytes_read > 0)
          return GOT_MAX_OUTPUT;
        else if (success)
          return EXECUTE_SUCCESS;
        return EXECUTE_FAILURE;
      }
  }
}

bool GetAppOutput(const CommandLine& cl, std::string* output) {
  return GetAppOutput(cl.argv(), output);
}

bool GetAppOutput(const std::vector<std::string>& argv, std::string* output) {
  // Run |execve()| with the current environment and store "unlimited" data.
  int exit_code;
  GetAppOutputInternalResult result = GetAppOutputInternal(
      argv, NULL, output, std::numeric_limits<std::size_t>::max(), true,
      &exit_code);
  return result == EXECUTE_SUCCESS && exit_code == EXIT_SUCCESS;
}

// TODO(viettrungluu): Conceivably, we should have a timeout as well, so we
// don't hang if what we're calling hangs.
bool GetAppOutputRestricted(const CommandLine& cl,
                            std::string* output, size_t max_output) {
  // Run |execve()| with the empty environment.
  char* const empty_environ = NULL;
  int exit_code;
  GetAppOutputInternalResult result = GetAppOutputInternal(
      cl.argv(), &empty_environ, output, max_output, false, &exit_code);
  return result == GOT_MAX_OUTPUT || (result == EXECUTE_SUCCESS &&
                                      exit_code == EXIT_SUCCESS);
}

bool GetAppOutputWithExitCode(const CommandLine& cl,
                              std::string* output,
                              int* exit_code) {
  // Run |execve()| with the current environment and store "unlimited" data.
  GetAppOutputInternalResult result = GetAppOutputInternal(
      cl.argv(), NULL, output, std::numeric_limits<std::size_t>::max(), true,
      exit_code);
  return result == EXECUTE_SUCCESS;
}

#if defined(OS_LINUX)
pid_t ForkWithFlags(unsigned long flags, pid_t* ptid, pid_t* ctid) {
  const bool clone_tls_used = flags & CLONE_SETTLS;
  const bool invalid_ctid =
      (flags & (CLONE_CHILD_SETTID | CLONE_CHILD_CLEARTID)) && !ctid;
  const bool invalid_ptid = (flags & CLONE_PARENT_SETTID) && !ptid;

  // We do not support CLONE_VM.
  const bool clone_vm_used = flags & CLONE_VM;

  if (clone_tls_used || invalid_ctid || invalid_ptid || clone_vm_used) {
    RAW_LOG(FATAL, "Invalid usage of ForkWithFlags");
  }

  // Valgrind's clone implementation does not support specifiying a child_stack
  // without CLONE_VM, so we cannot use libc's clone wrapper when running under
  // Valgrind. As a result, the libc pid cache may be incorrect under Valgrind.
  // See crbug.com/442817 for more details.
  if (IsRunningOnValgrind()) {
    // See kernel/fork.c in Linux. There is different ordering of sys_clone
    // parameters depending on CONFIG_CLONE_BACKWARDS* configuration options.
#if defined(ARCH_CPU_X86_64)
    return syscall(__NR_clone, flags, nullptr, ptid, ctid, nullptr);
#elif defined(ARCH_CPU_X86) || defined(ARCH_CPU_ARM_FAMILY) || \
    defined(ARCH_CPU_MIPS_FAMILY) || defined(ARCH_CPU_MIPS64_FAMILY)
    // CONFIG_CLONE_BACKWARDS defined.
    return syscall(__NR_clone, flags, nullptr, ptid, nullptr, ctid);
#else
#error "Unsupported architecture"
#endif
  }

  jmp_buf env;
  if (setjmp(env) == 0) {
    return CloneAndLongjmpInChild(flags, ptid, ctid, &env);
  }

  return 0;
}
#endif  // defined(OS_LINUX)

}  // namespace base

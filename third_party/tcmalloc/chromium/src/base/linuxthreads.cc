/* Copyright (c) 2005-2007, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ---
 * Author: Markus Gutschke
 */

#include "base/linuxthreads.h"

#ifdef THREADS
#ifdef __cplusplus
extern "C" {
#endif

#include <sched.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/wait.h>

#include "base/linux_syscall_support.h"
#include "base/thread_lister.h"

#ifndef CLONE_UNTRACED
#define CLONE_UNTRACED 0x00800000
#endif


/* Synchronous signals that should not be blocked while in the lister thread.
 */
static const int sync_signals[]  = { SIGABRT, SIGILL, SIGFPE, SIGSEGV, SIGBUS,
                                     SIGXCPU, SIGXFSZ };

/* itoa() is not a standard function, and we cannot safely call printf()
 * after suspending threads. So, we just implement our own copy. A
 * recursive approach is the easiest here.
 */
static char *local_itoa(char *buf, int i) {
  if (i < 0) {
    *buf++ = '-';
    return local_itoa(buf, -i);
  } else {
    if (i >= 10)
      buf = local_itoa(buf, i/10);
    *buf++ = (i%10) + '0';
    *buf   = '\000';
    return buf;
  }
}


/* Wrapper around clone() that runs "fn" on the same stack as the
 * caller! Unlike fork(), the cloned thread shares the same address space.
 * The caller must be careful to use only minimal amounts of stack until
 * the cloned thread has returned.
 * There is a good chance that the cloned thread and the caller will share
 * the same copy of errno!
 */
#ifdef __GNUC__
#if __GNUC__ == 3 && __GNUC_MINOR__ >= 1 || __GNUC__ > 3
/* Try to force this function into a separate stack frame, and make sure
 * that arguments are passed on the stack.
 */
static int local_clone (int (*fn)(void *), void *arg, ...)
  __attribute__ ((noinline));
#endif
#endif

static int local_clone (int (*fn)(void *), void *arg, ...) {
  /* Leave 4kB of gap between the callers stack and the new clone. This
   * should be more than sufficient for the caller to call waitpid() until
   * the cloned thread terminates.
   *
   * It is important that we set the CLONE_UNTRACED flag, because newer
   * versions of "gdb" otherwise attempt to attach to our thread, and will
   * attempt to reap its status codes. This subsequently results in the
   * caller hanging indefinitely in waitpid(), waiting for a change in
   * status that will never happen. By setting the CLONE_UNTRACED flag, we
   * prevent "gdb" from stealing events, but we still expect the thread
   * lister to fail, because it cannot PTRACE_ATTACH to the process that
   * is being debugged. This is OK and the error code will be reported
   * correctly.
   */
  return sys_clone(fn, (char *)&arg - 4096,
                   CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_UNTRACED, arg, 0, 0, 0);
}


/* Local substitute for the atoi() function, which is not necessarily safe
 * to call once threads are suspended (depending on whether libc looks up
 * locale information,  when executing atoi()).
 */
static int local_atoi(const char *s) {
  int n   = 0;
  int neg = *s == '-';
  if (neg)
    s++;
  while (*s >= '0' && *s <= '9')
    n = 10*n + (*s++ - '0');
  return neg ? -n : n;
}


/* Re-runs fn until it doesn't cause EINTR
 */
#define NO_INTR(fn)   do {} while ((fn) < 0 && errno == EINTR)


/* Wrap a class around system calls, in order to give us access to
 * a private copy of errno. This only works in C++, but it has the
 * advantage of not needing nested functions, which are a non-standard
 * language extension.
 */
#ifdef __cplusplus
namespace {
  class SysCalls {
   public:
    #define SYS_CPLUSPLUS
    #define SYS_ERRNO     my_errno
    #define SYS_INLINE    inline
    #define SYS_PREFIX    -1
    #undef  SYS_LINUX_SYSCALL_SUPPORT_H
    #include "linux_syscall_support.h"
    SysCalls() : my_errno(0) { }
    int my_errno;
  };
}
#define ERRNO sys.my_errno
#else
#define ERRNO my_errno
#endif


/* Wrapper for open() which is guaranteed to never return EINTR.
 */
static int c_open(const char *fname, int flags, int mode) {
  ssize_t rc;
  NO_INTR(rc = sys_open(fname, flags, mode));
  return rc;
}


/* abort() is not safely reentrant, and changes it's behavior each time
 * it is called. This means, if the main application ever called abort()
 * we cannot safely call it again. This would happen if we were called
 * from a SIGABRT signal handler in the main application. So, document
 * that calling SIGABRT from the thread lister makes it not signal safe
 * (and vice-versa).
 * Also, since we share address space with the main application, we
 * cannot call abort() from the callback and expect the main application
 * to behave correctly afterwards. In fact, the only thing we can do, is
 * to terminate the main application with extreme prejudice (aka
 * PTRACE_KILL).
 * We set up our own SIGABRT handler to do this.
 * In order to find the main application from the signal handler, we
 * need to store information about it in global variables. This is
 * safe, because the main application should be suspended at this
 * time. If the callback ever called ResumeAllProcessThreads(), then
 * we are running a higher risk, though. So, try to avoid calling
 * abort() after calling ResumeAllProcessThreads.
 */
static volatile int *sig_pids, sig_num_threads, sig_proc, sig_marker;


/* Signal handler to help us recover from dying while we are attached to
 * other threads.
 */
static void SignalHandler(int signum, siginfo_t *si, void *data) {
  if (sig_pids != NULL) {
    if (signum == SIGABRT) {
      while (sig_num_threads-- > 0) {
        /* Not sure if sched_yield is really necessary here, but it does not */
        /* hurt, and it might be necessary for the same reasons that we have */
        /* to do so in sys_ptrace_detach().                                  */
        sys_sched_yield();
        sys_ptrace(PTRACE_KILL, sig_pids[sig_num_threads], 0, 0);
      }
    } else if (sig_num_threads > 0) {
      ResumeAllProcessThreads(sig_num_threads, (int *)sig_pids);
    }
  }
  sig_pids = NULL;
  if (sig_marker >= 0)
    NO_INTR(sys_close(sig_marker));
  sig_marker = -1;
  if (sig_proc >= 0)
    NO_INTR(sys_close(sig_proc));
  sig_proc = -1;

  sys__exit(signum == SIGABRT ? 1 : 2);
}


/* Try to dirty the stack, and hope that the compiler is not smart enough
 * to optimize this function away. Or worse, the compiler could inline the
 * function and permanently allocate the data on the stack.
 */
static void DirtyStack(size_t amount) {
  char buf[amount];
  memset(buf, 0, amount);
  sys_read(-1, buf, amount);
}


/* Data structure for passing arguments to the lister thread.
 */
#define ALT_STACKSIZE (MINSIGSTKSZ + 4096)

struct ListerParams {
  int         result, err;
  char        *altstack_mem;
  ListAllProcessThreadsCallBack callback;
  void        *parameter;
  va_list     ap;
};


static void ListerThread(struct ListerParams *args) {
  int                found_parent = 0;
  pid_t              clone_pid  = sys_gettid(), ppid = sys_getppid();
  char               proc_self_task[80], marker_name[48], *marker_path;
  const char         *proc_paths[3];
  const char *const  *proc_path = proc_paths;
  int                proc = -1, marker = -1, num_threads = 0;
  int                max_threads = 0, sig;
  struct kernel_stat marker_sb, proc_sb;
  stack_t            altstack;

  /* Create "marker" that we can use to detect threads sharing the same
   * address space and the same file handles. By setting the FD_CLOEXEC flag
   * we minimize the risk of misidentifying child processes as threads;
   * and since there is still a race condition,  we will filter those out
   * later, anyway.
   */
  if ((marker = sys_socket(PF_LOCAL, SOCK_DGRAM, 0)) < 0 ||
      sys_fcntl(marker, F_SETFD, FD_CLOEXEC) < 0) {
  failure:
    args->result = -1;
    args->err    = errno;
    if (marker >= 0)
      NO_INTR(sys_close(marker));
    sig_marker = marker = -1;
    if (proc >= 0)
      NO_INTR(sys_close(proc));
    sig_proc = proc = -1;
    sys__exit(1);
  }

  /* Compute search paths for finding thread directories in /proc            */
  local_itoa(strrchr(strcpy(proc_self_task, "/proc/"), '\000'), ppid);
  strcpy(marker_name, proc_self_task);
  marker_path = marker_name + strlen(marker_name);
  strcat(proc_self_task, "/task/");
  proc_paths[0] = proc_self_task; /* /proc/$$/task/                          */
  proc_paths[1] = "/proc/";       /* /proc/                                  */
  proc_paths[2] = NULL;

  /* Compute path for marker socket in /proc                                 */
  local_itoa(strcpy(marker_path, "/fd/") + 4, marker);
  if (sys_stat(marker_name, &marker_sb) < 0) {
    goto failure;
  }

  /* Catch signals on an alternate pre-allocated stack. This way, we can
   * safely execute the signal handler even if we ran out of memory.
   */
  memset(&altstack, 0, sizeof(altstack));
  altstack.ss_sp    = args->altstack_mem;
  altstack.ss_flags = 0;
  altstack.ss_size  = ALT_STACKSIZE;
  sys_sigaltstack(&altstack, (const stack_t *)NULL);

  /* Some kernels forget to wake up traced processes, when the
   * tracer dies.  So, intercept synchronous signals and make sure
   * that we wake up our tracees before dying. It is the caller's
   * responsibility to ensure that asynchronous signals do not
   * interfere with this function.
   */
  sig_marker = marker;
  sig_proc   = -1;
  for (sig = 0; sig < sizeof(sync_signals)/sizeof(*sync_signals); sig++) {
    struct kernel_sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction_ = SignalHandler;
    sys_sigfillset(&sa.sa_mask);
    sa.sa_flags      = SA_ONSTACK|SA_SIGINFO|SA_RESETHAND;
    sys_sigaction(sync_signals[sig], &sa, (struct kernel_sigaction *)NULL);
  }
  
  /* Read process directories in /proc/...                                   */
  for (;;) {
    /* Some kernels know about threads, and hide them in "/proc"
     * (although they are still there, if you know the process
     * id). Threads are moved into a separate "task" directory. We
     * check there first, and then fall back on the older naming
     * convention if necessary.
     */
    if ((sig_proc = proc = c_open(*proc_path, O_RDONLY|O_DIRECTORY, 0)) < 0) {
      if (*++proc_path != NULL)
        continue;
      goto failure;
    }
    if (sys_fstat(proc, &proc_sb) < 0)
      goto failure;
    
    /* Since we are suspending threads, we cannot call any libc
     * functions that might acquire locks. Most notably, we cannot
     * call malloc(). So, we have to allocate memory on the stack,
     * instead. Since we do not know how much memory we need, we
     * make a best guess. And if we guessed incorrectly we retry on
     * a second iteration (by jumping to "detach_threads").
     *
     * Unless the number of threads is increasing very rapidly, we
     * should never need to do so, though, as our guestimate is very
     * conservative.
     */
    if (max_threads < proc_sb.st_nlink + 100)
      max_threads = proc_sb.st_nlink + 100;
    
    /* scope */ {
      pid_t pids[max_threads];
      int   added_entries = 0;
      sig_num_threads     = num_threads;
      sig_pids            = pids;
      for (;;) {
        struct kernel_dirent *entry;
        char buf[4096];
        ssize_t nbytes = sys_getdents(proc, (struct kernel_dirent *)buf,
                                      sizeof(buf));
        if (nbytes < 0)
          goto failure;
        else if (nbytes == 0) {
          if (added_entries) {
            /* Need to keep iterating over "/proc" in multiple
             * passes until we no longer find any more threads. This
             * algorithm eventually completes, when all threads have
             * been suspended.
             */
            added_entries = 0;
            sys_lseek(proc, 0, SEEK_SET);
            continue;
          }
          break;
        }
        for (entry = (struct kernel_dirent *)buf;
             entry < (struct kernel_dirent *)&buf[nbytes];
             entry = (struct kernel_dirent *)((char *)entry+entry->d_reclen)) {
          if (entry->d_ino != 0) {
            const char *ptr = entry->d_name;
            pid_t pid;
            
            /* Some kernels hide threads by preceding the pid with a '.'     */
            if (*ptr == '.')
              ptr++;
            
            /* If the directory is not numeric, it cannot be a
             * process/thread
             */
            if (*ptr < '0' || *ptr > '9')
              continue;
            pid = local_atoi(ptr);

            /* Attach (and suspend) all threads                              */
            if (pid && pid != clone_pid) {
              struct kernel_stat tmp_sb;
              char fname[entry->d_reclen + 48];
              strcat(strcat(strcpy(fname, "/proc/"),
                            entry->d_name), marker_path);
              
              /* Check if the marker is identical to the one we created      */
              if (sys_stat(fname, &tmp_sb) >= 0 &&
                  marker_sb.st_ino == tmp_sb.st_ino) {
                long i, j;

                /* Found one of our threads, make sure it is no duplicate    */
                for (i = 0; i < num_threads; i++) {
                  /* Linear search is slow, but should not matter much for
                   * the typically small number of threads.
                   */
                  if (pids[i] == pid) {
                    /* Found a duplicate; most likely on second pass         */
                    goto next_entry;
                  }
                }
                
                /* Check whether data structure needs growing                */
                if (num_threads >= max_threads) {
                  /* Back to square one, this time with more memory          */
                  NO_INTR(sys_close(proc));
                  goto detach_threads;
                }

                /* Attaching to thread suspends it                           */
                pids[num_threads++] = pid;
                sig_num_threads     = num_threads;
                if (sys_ptrace(PTRACE_ATTACH, pid, (void *)0,
                               (void *)0) < 0) {
                  /* If operation failed, ignore thread. Maybe it
                   * just died?  There might also be a race
                   * condition with a concurrent core dumper or
                   * with a debugger. In that case, we will just
                   * make a best effort, rather than failing
                   * entirely.
                   */
                  num_threads--;
                  sig_num_threads = num_threads;
                  goto next_entry;
                }
                while (sys_waitpid(pid, (int *)0, __WALL) < 0) {
                  if (errno != EINTR) {
                    sys_ptrace_detach(pid);
                    num_threads--;
                    sig_num_threads = num_threads;
                    goto next_entry;
                  }
                }
                
                if (sys_ptrace(PTRACE_PEEKDATA, pid, &i, &j) || i++ != j ||
                    sys_ptrace(PTRACE_PEEKDATA, pid, &i, &j) || i   != j) {
                  /* Address spaces are distinct, even though both
                   * processes show the "marker". This is probably
                   * a forked child process rather than a thread.
                   */
                  sys_ptrace_detach(pid);
                  num_threads--;
                  sig_num_threads = num_threads;
                } else {
                  found_parent |= pid == ppid;
                  added_entries++;
                }
              }
            }
          }
        next_entry:;
        }
      }
      NO_INTR(sys_close(proc));
      sig_proc = proc = -1;

      /* If we failed to find any threads, try looking somewhere else in
       * /proc. Maybe, threads are reported differently on this system.
       */
      if (num_threads > 1 || !*++proc_path) {
        NO_INTR(sys_close(marker));
        sig_marker = marker = -1;

        /* If we never found the parent process, something is very wrong.
         * Most likely, we are running in debugger. Any attempt to operate
         * on the threads would be very incomplete. Let's just report an
         * error to the caller.
         */
        if (!found_parent) {
          ResumeAllProcessThreads(num_threads, pids);
          sys__exit(3);
        }

        /* Now we are ready to call the callback,
         * which takes care of resuming the threads for us.
         */
        args->result = args->callback(args->parameter, num_threads,
                                      pids, args->ap);
        args->err = errno;

        /* Callback should have resumed threads, but better safe than sorry  */
        if (ResumeAllProcessThreads(num_threads, pids)) {
          /* Callback forgot to resume at least one thread, report error     */
          args->err    = EINVAL;
          args->result = -1;
        }

        sys__exit(0);
      }
    detach_threads:
      /* Resume all threads prior to retrying the operation                  */
      ResumeAllProcessThreads(num_threads, pids);
      sig_pids = NULL;
      num_threads = 0;
      sig_num_threads = num_threads;
      max_threads += 100;
    }
  }
}


/* This function gets the list of all linux threads of the current process
 * passes them to the 'callback' along with the 'parameter' pointer; at the
 * call back call time all the threads are paused via
 * PTRACE_ATTACH.
 * The callback is executed from a separate thread which shares only the
 * address space, the filesystem, and the filehandles with the caller. Most
 * notably, it does not share the same pid and ppid; and if it terminates,
 * the rest of the application is still there. 'callback' is supposed to do
 * or arrange for ResumeAllProcessThreads. This happens automatically, if
 * the thread raises a synchronous signal (e.g. SIGSEGV); asynchronous
 * signals are blocked. If the 'callback' decides to unblock them, it must
 * ensure that they cannot terminate the application, or that
 * ResumeAllProcessThreads will get called.
 * It is an error for the 'callback' to make any library calls that could
 * acquire locks. Most notably, this means that most system calls have to
 * avoid going through libc. Also, this means that it is not legal to call
 * exit() or abort().
 * We return -1 on error and the return value of 'callback' on success.
 */
int ListAllProcessThreads(void *parameter,
                          ListAllProcessThreadsCallBack callback, ...) {
  char                   altstack_mem[ALT_STACKSIZE];
  struct ListerParams    args;
  pid_t                  clone_pid;
  int                    dumpable = 1, sig;
  struct kernel_sigset_t sig_blocked, sig_old;

  va_start(args.ap, callback);

  /* If we are short on virtual memory, initializing the alternate stack
   * might trigger a SIGSEGV. Let's do this early, before it could get us
   * into more trouble (i.e. before signal handlers try to use the alternate
   * stack, and before we attach to other threads).
   */
  memset(altstack_mem, 0, sizeof(altstack_mem));

  /* Some of our cleanup functions could conceivable use more stack space.
   * Try to touch the stack right now. This could be defeated by the compiler
   * being too smart for it's own good, so try really hard.
   */
  DirtyStack(32768);

  /* Make this process "dumpable". This is necessary in order to ptrace()
   * after having called setuid().
   */
  dumpable = sys_prctl(PR_GET_DUMPABLE, 0);
  if (!dumpable)
    sys_prctl(PR_SET_DUMPABLE, 1);

  /* Fill in argument block for dumper thread                                */
  args.result       = -1;
  args.err          = 0;
  args.altstack_mem = altstack_mem;
  args.parameter    = parameter;
  args.callback     = callback;

  /* Before cloning the thread lister, block all asynchronous signals, as we */
  /* are not prepared to handle them.                                        */
  sys_sigfillset(&sig_blocked);
  for (sig = 0; sig < sizeof(sync_signals)/sizeof(*sync_signals); sig++) {
    sys_sigdelset(&sig_blocked, sync_signals[sig]);
  }
  if (sys_sigprocmask(SIG_BLOCK, &sig_blocked, &sig_old)) {
    args.err = errno;
    args.result = -1;
    goto failed;
  }

  /* scope */ {
    /* After cloning, both the parent and the child share the same instance
     * of errno. We must make sure that at least one of these processes
     * (in our case, the parent) uses modified syscall macros that update
     * a local copy of errno, instead.
     */
    #ifdef __cplusplus
      #define sys0_sigprocmask sys.sigprocmask
      #define sys0_waitpid     sys.waitpid
      SysCalls sys;
    #else
      int my_errno;
      #define SYS_ERRNO        my_errno
      #define SYS_INLINE       inline
      #define SYS_PREFIX       0
      #undef  SYS_LINUX_SYSCALL_SUPPORT_H
      #include "linux_syscall_support.h"
    #endif
  
    int clone_errno;
    clone_pid = local_clone((int (*)(void *))ListerThread, &args);
    clone_errno = errno;

    sys_sigprocmask(SIG_SETMASK, &sig_old, &sig_old);

    if (clone_pid >= 0) {
      int status, rc;
      while ((rc = sys0_waitpid(clone_pid, &status, __WALL)) < 0 &&
             ERRNO == EINTR) {
             /* Keep waiting                                                 */
      }
      if (rc < 0) {
        args.err = ERRNO;
        args.result = -1;
      } else if (WIFEXITED(status)) {
        switch (WEXITSTATUS(status)) {
          case 0: break;             /* Normal process termination           */
          case 2: args.err = EFAULT; /* Some fault (e.g. SIGSEGV) detected   */
                  args.result = -1;
                  break;
          case 3: args.err = EPERM;  /* Process is already being traced      */
                  args.result = -1;
                  break;
          default:args.err = ECHILD; /* Child died unexpectedly              */
                  args.result = -1;
                  break;
        }
      } else if (!WIFEXITED(status)) {
        args.err    = EFAULT;        /* Terminated due to an unhandled signal*/
        args.result = -1;
      }
    } else {
      args.result = -1;
      args.err    = clone_errno;
    }
  }

  /* Restore the "dumpable" state of the process                             */
failed:
  if (!dumpable)
    sys_prctl(PR_SET_DUMPABLE, dumpable);

  va_end(args.ap);

  errno = args.err;
  return args.result;
}

/* This function resumes the list of all linux threads that
 * ListAllProcessThreads pauses before giving to its callback.
 * The function returns non-zero if at least one thread was
 * suspended and has now been resumed.
 */
int ResumeAllProcessThreads(int num_threads, pid_t *thread_pids) {
  int detached_at_least_one = 0;
  while (num_threads-- > 0) {
    detached_at_least_one |= sys_ptrace_detach(thread_pids[num_threads]) >= 0;
  }
  return detached_at_least_one;
}

#ifdef __cplusplus
}
#endif
#endif

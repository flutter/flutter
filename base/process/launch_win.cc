// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/launch.h"

#include <fcntl.h>
#include <io.h>
#include <shellapi.h>
#include <windows.h>
#include <userenv.h>
#include <psapi.h>

#include <ios>
#include <limits>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/command_line.h"
#include "base/debug/stack_trace.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/metrics/histogram.h"
#include "base/process/kill.h"
#include "base/strings/utf_string_conversions.h"
#include "base/sys_info.h"
#include "base/win/object_watcher.h"
#include "base/win/scoped_handle.h"
#include "base/win/scoped_process_information.h"
#include "base/win/startup_information.h"
#include "base/win/windows_version.h"

// userenv.dll is required for CreateEnvironmentBlock().
#pragma comment(lib, "userenv.lib")

namespace base {

namespace {

// This exit code is used by the Windows task manager when it kills a
// process.  It's value is obviously not that unique, and it's
// surprising to me that the task manager uses this value, but it
// seems to be common practice on Windows to test for it as an
// indication that the task manager has killed something if the
// process goes away.
const DWORD kProcessKilledExitCode = 1;

}  // namespace

void RouteStdioToConsole() {
  // Don't change anything if stdout or stderr already point to a
  // valid stream.
  //
  // If we are running under Buildbot or under Cygwin's default
  // terminal (mintty), stderr and stderr will be pipe handles.  In
  // that case, we don't want to open CONOUT$, because its output
  // likely does not go anywhere.
  //
  // We don't use GetStdHandle() to check stdout/stderr here because
  // it can return dangling IDs of handles that were never inherited
  // by this process.  These IDs could have been reused by the time
  // this function is called.  The CRT checks the validity of
  // stdout/stderr on startup (before the handle IDs can be reused).
  // _fileno(stdout) will return -2 (_NO_CONSOLE_FILENO) if stdout was
  // invalid.
  if (_fileno(stdout) >= 0 || _fileno(stderr) >= 0)
    return;

  if (!AttachConsole(ATTACH_PARENT_PROCESS)) {
    unsigned int result = GetLastError();
    // Was probably already attached.
    if (result == ERROR_ACCESS_DENIED)
      return;
    // Don't bother creating a new console for each child process if the
    // parent process is invalid (eg: crashed).
    if (result == ERROR_GEN_FAILURE)
      return;
    // Make a new console if attaching to parent fails with any other error.
    // It should be ERROR_INVALID_HANDLE at this point, which means the browser
    // was likely not started from a console.
    AllocConsole();
  }

  // Arbitrary byte count to use when buffering output lines.  More
  // means potential waste, less means more risk of interleaved
  // log-lines in output.
  enum { kOutputBufferSize = 64 * 1024 };

  if (freopen("CONOUT$", "w", stdout)) {
    setvbuf(stdout, NULL, _IOLBF, kOutputBufferSize);
    // Overwrite FD 1 for the benefit of any code that uses this FD
    // directly.  This is safe because the CRT allocates FDs 0, 1 and
    // 2 at startup even if they don't have valid underlying Windows
    // handles.  This means we won't be overwriting an FD created by
    // _open() after startup.
    _dup2(_fileno(stdout), 1);
  }
  if (freopen("CONOUT$", "w", stderr)) {
    setvbuf(stderr, NULL, _IOLBF, kOutputBufferSize);
    _dup2(_fileno(stderr), 2);
  }

  // Fix all cout, wcout, cin, wcin, cerr, wcerr, clog and wclog.
  std::ios::sync_with_stdio();
}

Process LaunchProcess(const CommandLine& cmdline,
                      const LaunchOptions& options) {
  return LaunchProcess(cmdline.GetCommandLineString(), options);
}

Process LaunchProcess(const string16& cmdline,
                      const LaunchOptions& options) {
  win::StartupInformation startup_info_wrapper;
  STARTUPINFO* startup_info = startup_info_wrapper.startup_info();

  bool inherit_handles = options.inherit_handles;
  DWORD flags = 0;
  if (options.handles_to_inherit) {
    if (options.handles_to_inherit->empty()) {
      inherit_handles = false;
    } else {
      if (base::win::GetVersion() < base::win::VERSION_VISTA) {
        DLOG(ERROR) << "Specifying handles to inherit requires Vista or later.";
        return Process();
      }

      if (options.handles_to_inherit->size() >
              std::numeric_limits<DWORD>::max() / sizeof(HANDLE)) {
        DLOG(ERROR) << "Too many handles to inherit.";
        return Process();
      }

      if (!startup_info_wrapper.InitializeProcThreadAttributeList(1)) {
        DPLOG(ERROR);
        return Process();
      }

      if (!startup_info_wrapper.UpdateProcThreadAttribute(
              PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
              const_cast<HANDLE*>(&options.handles_to_inherit->at(0)),
              static_cast<DWORD>(options.handles_to_inherit->size() *
                  sizeof(HANDLE)))) {
        DPLOG(ERROR);
        return Process();
      }

      inherit_handles = true;
      flags |= EXTENDED_STARTUPINFO_PRESENT;
    }
  }

  if (options.empty_desktop_name)
    startup_info->lpDesktop = const_cast<wchar_t*>(L"");
  startup_info->dwFlags = STARTF_USESHOWWINDOW;
  startup_info->wShowWindow = options.start_hidden ? SW_HIDE : SW_SHOW;

  if (options.stdin_handle || options.stdout_handle || options.stderr_handle) {
    DCHECK(inherit_handles);
    DCHECK(options.stdin_handle);
    DCHECK(options.stdout_handle);
    DCHECK(options.stderr_handle);
    startup_info->dwFlags |= STARTF_USESTDHANDLES;
    startup_info->hStdInput = options.stdin_handle;
    startup_info->hStdOutput = options.stdout_handle;
    startup_info->hStdError = options.stderr_handle;
  }

  if (options.job_handle) {
    flags |= CREATE_SUSPENDED;

    // If this code is run under a debugger, the launched process is
    // automatically associated with a job object created by the debugger.
    // The CREATE_BREAKAWAY_FROM_JOB flag is used to prevent this.
    flags |= CREATE_BREAKAWAY_FROM_JOB;
  }

  if (options.force_breakaway_from_job_)
    flags |= CREATE_BREAKAWAY_FROM_JOB;

  PROCESS_INFORMATION temp_process_info = {};

  string16 writable_cmdline(cmdline);
  if (options.as_user) {
    flags |= CREATE_UNICODE_ENVIRONMENT;
    void* enviroment_block = NULL;

    if (!CreateEnvironmentBlock(&enviroment_block, options.as_user, FALSE)) {
      DPLOG(ERROR);
      return Process();
    }

    BOOL launched =
        CreateProcessAsUser(options.as_user, NULL,
                            &writable_cmdline[0],
                            NULL, NULL, inherit_handles, flags,
                            enviroment_block, NULL, startup_info,
                            &temp_process_info);
    DestroyEnvironmentBlock(enviroment_block);
    if (!launched) {
      DPLOG(ERROR) << "Command line:" << std::endl << UTF16ToUTF8(cmdline)
                   << std::endl;;
      return Process();
    }
  } else {
    if (!CreateProcess(NULL,
                       &writable_cmdline[0], NULL, NULL,
                       inherit_handles, flags, NULL, NULL,
                       startup_info, &temp_process_info)) {
      DPLOG(ERROR) << "Command line:" << std::endl << UTF16ToUTF8(cmdline)
                   << std::endl;;
      return Process();
    }
  }
  base::win::ScopedProcessInformation process_info(temp_process_info);

  if (options.job_handle) {
    if (0 == AssignProcessToJobObject(options.job_handle,
                                      process_info.process_handle())) {
      DLOG(ERROR) << "Could not AssignProcessToObject.";
      Process scoped_process(process_info.TakeProcessHandle());
      scoped_process.Terminate(kProcessKilledExitCode, true);
      return Process();
    }

    ResumeThread(process_info.thread_handle());
  }

  if (options.wait)
    WaitForSingleObject(process_info.process_handle(), INFINITE);

  return Process(process_info.TakeProcessHandle());
}

Process LaunchElevatedProcess(const CommandLine& cmdline,
                              const LaunchOptions& options) {
  const string16 file = cmdline.GetProgram().value();
  const string16 arguments = cmdline.GetArgumentsString();

  SHELLEXECUTEINFO shex_info = {0};
  shex_info.cbSize = sizeof(shex_info);
  shex_info.fMask = SEE_MASK_NOCLOSEPROCESS;
  shex_info.hwnd = GetActiveWindow();
  shex_info.lpVerb = L"runas";
  shex_info.lpFile = file.c_str();
  shex_info.lpParameters = arguments.c_str();
  shex_info.lpDirectory = NULL;
  shex_info.nShow = options.start_hidden ? SW_HIDE : SW_SHOW;
  shex_info.hInstApp = NULL;

  if (!ShellExecuteEx(&shex_info)) {
    DPLOG(ERROR);
    return Process();
  }

  if (options.wait)
    WaitForSingleObject(shex_info.hProcess, INFINITE);

  return Process(shex_info.hProcess);
}

bool SetJobObjectLimitFlags(HANDLE job_object, DWORD limit_flags) {
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit_info = {0};
  limit_info.BasicLimitInformation.LimitFlags = limit_flags;
  return 0 != SetInformationJobObject(
      job_object,
      JobObjectExtendedLimitInformation,
      &limit_info,
      sizeof(limit_info));
}

bool GetAppOutput(const CommandLine& cl, std::string* output) {
  return GetAppOutput(cl.GetCommandLineString(), output);
}

bool GetAppOutput(const StringPiece16& cl, std::string* output) {
  HANDLE out_read = NULL;
  HANDLE out_write = NULL;

  SECURITY_ATTRIBUTES sa_attr;
  // Set the bInheritHandle flag so pipe handles are inherited.
  sa_attr.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa_attr.bInheritHandle = TRUE;
  sa_attr.lpSecurityDescriptor = NULL;

  // Create the pipe for the child process's STDOUT.
  if (!CreatePipe(&out_read, &out_write, &sa_attr, 0)) {
    NOTREACHED() << "Failed to create pipe";
    return false;
  }

  // Ensure we don't leak the handles.
  win::ScopedHandle scoped_out_read(out_read);
  win::ScopedHandle scoped_out_write(out_write);

  // Ensure the read handle to the pipe for STDOUT is not inherited.
  if (!SetHandleInformation(out_read, HANDLE_FLAG_INHERIT, 0)) {
    NOTREACHED() << "Failed to disabled pipe inheritance";
    return false;
  }

  FilePath::StringType writable_command_line_string;
  writable_command_line_string.assign(cl.data(), cl.size());

  STARTUPINFO start_info = {};

  start_info.cb = sizeof(STARTUPINFO);
  start_info.hStdOutput = out_write;
  // Keep the normal stdin and stderr.
  start_info.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  start_info.hStdError = GetStdHandle(STD_ERROR_HANDLE);
  start_info.dwFlags |= STARTF_USESTDHANDLES;

  // Create the child process.
  PROCESS_INFORMATION temp_process_info = {};
  if (!CreateProcess(NULL,
                     &writable_command_line_string[0],
                     NULL, NULL,
                     TRUE,  // Handles are inherited.
                     0, NULL, NULL, &start_info, &temp_process_info)) {
    NOTREACHED() << "Failed to start process";
    return false;
  }
  base::win::ScopedProcessInformation proc_info(temp_process_info);

  // Close our writing end of pipe now. Otherwise later read would not be able
  // to detect end of child's output.
  scoped_out_write.Close();

  // Read output from the child process's pipe for STDOUT
  const int kBufferSize = 1024;
  char buffer[kBufferSize];

  for (;;) {
    DWORD bytes_read = 0;
    BOOL success = ReadFile(out_read, buffer, kBufferSize, &bytes_read, NULL);
    if (!success || bytes_read == 0)
      break;
    output->append(buffer, bytes_read);
  }

  // Let's wait for the process to finish.
  WaitForSingleObject(proc_info.process_handle(), INFINITE);

  return true;
}

void RaiseProcessToHighPriority() {
  SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
}

}  // namespace base

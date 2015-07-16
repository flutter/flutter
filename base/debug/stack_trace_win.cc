// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/debug/stack_trace.h"

#include <windows.h>
#include <dbghelp.h>

#include <iostream>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/singleton.h"
#include "base/process/launch.h"
#include "base/strings/string_util.h"
#include "base/synchronization/lock.h"
#include "base/win/windows_version.h"

namespace base {
namespace debug {

namespace {

// Previous unhandled filter. Will be called if not NULL when we intercept an
// exception. Only used in unit tests.
LPTOP_LEVEL_EXCEPTION_FILTER g_previous_filter = NULL;

// Prints the exception call stack.
// This is the unit tests exception filter.
long WINAPI StackDumpExceptionFilter(EXCEPTION_POINTERS* info) {
  debug::StackTrace(info).Print();
  if (g_previous_filter)
    return g_previous_filter(info);
  return EXCEPTION_CONTINUE_SEARCH;
}

FilePath GetExePath() {
  wchar_t system_buffer[MAX_PATH];
  GetModuleFileName(NULL, system_buffer, MAX_PATH);
  system_buffer[MAX_PATH - 1] = L'\0';
  return FilePath(system_buffer);
}

// SymbolContext is a threadsafe singleton that wraps the DbgHelp Sym* family
// of functions.  The Sym* family of functions may only be invoked by one
// thread at a time.  SymbolContext code may access a symbol server over the
// network while holding the lock for this singleton.  In the case of high
// latency, this code will adversely affect performance.
//
// There is also a known issue where this backtrace code can interact
// badly with breakpad if breakpad is invoked in a separate thread while
// we are using the Sym* functions.  This is because breakpad does now
// share a lock with this function.  See this related bug:
//
//   http://code.google.com/p/google-breakpad/issues/detail?id=311
//
// This is a very unlikely edge case, and the current solution is to
// just ignore it.
class SymbolContext {
 public:
  static SymbolContext* GetInstance() {
    // We use a leaky singleton because code may call this during process
    // termination.
    return
      Singleton<SymbolContext, LeakySingletonTraits<SymbolContext> >::get();
  }

  // Returns the error code of a failed initialization.
  DWORD init_error() const {
    return init_error_;
  }

  // For the given trace, attempts to resolve the symbols, and output a trace
  // to the ostream os.  The format for each line of the backtrace is:
  //
  //    <tab>SymbolName[0xAddress+Offset] (FileName:LineNo)
  //
  // This function should only be called if Init() has been called.  We do not
  // LOG(FATAL) here because this code is called might be triggered by a
  // LOG(FATAL) itself. Also, it should not be calling complex code that is
  // extensible like PathService since that can in turn fire CHECKs.
  void OutputTraceToStream(const void* const* trace,
                           size_t count,
                           std::ostream* os) {
    base::AutoLock lock(lock_);

    for (size_t i = 0; (i < count) && os->good(); ++i) {
      const int kMaxNameLength = 256;
      DWORD_PTR frame = reinterpret_cast<DWORD_PTR>(trace[i]);

      // Code adapted from MSDN example:
      // http://msdn.microsoft.com/en-us/library/ms680578(VS.85).aspx
      ULONG64 buffer[
        (sizeof(SYMBOL_INFO) +
          kMaxNameLength * sizeof(wchar_t) +
          sizeof(ULONG64) - 1) /
        sizeof(ULONG64)];
      memset(buffer, 0, sizeof(buffer));

      // Initialize symbol information retrieval structures.
      DWORD64 sym_displacement = 0;
      PSYMBOL_INFO symbol = reinterpret_cast<PSYMBOL_INFO>(&buffer[0]);
      symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
      symbol->MaxNameLen = kMaxNameLength - 1;
      BOOL has_symbol = SymFromAddr(GetCurrentProcess(), frame,
                                    &sym_displacement, symbol);

      // Attempt to retrieve line number information.
      DWORD line_displacement = 0;
      IMAGEHLP_LINE64 line = {};
      line.SizeOfStruct = sizeof(IMAGEHLP_LINE64);
      BOOL has_line = SymGetLineFromAddr64(GetCurrentProcess(), frame,
                                           &line_displacement, &line);

      // Output the backtrace line.
      (*os) << "\t";
      if (has_symbol) {
        (*os) << symbol->Name << " [0x" << trace[i] << "+"
              << sym_displacement << "]";
      } else {
        // If there is no symbol information, add a spacer.
        (*os) << "(No symbol) [0x" << trace[i] << "]";
      }
      if (has_line) {
        (*os) << " (" << line.FileName << ":" << line.LineNumber << ")";
      }
      (*os) << "\n";
    }
  }

 private:
  friend struct DefaultSingletonTraits<SymbolContext>;

  SymbolContext() : init_error_(ERROR_SUCCESS) {
    // Initializes the symbols for the process.
    // Defer symbol load until they're needed, use undecorated names, and
    // get line numbers.
    SymSetOptions(SYMOPT_DEFERRED_LOADS |
                  SYMOPT_UNDNAME |
                  SYMOPT_LOAD_LINES);
    if (!SymInitialize(GetCurrentProcess(), NULL, TRUE)) {
      init_error_ = GetLastError();
      // TODO(awong): Handle error: SymInitialize can fail with
      // ERROR_INVALID_PARAMETER.
      // When it fails, we should not call debugbreak since it kills the current
      // process (prevents future tests from running or kills the browser
      // process).
      DLOG(ERROR) << "SymInitialize failed: " << init_error_;
      return;
    }

    init_error_ = ERROR_SUCCESS;

    // When transferring the binaries e.g. between bots, path put
    // into the executable will get off. To still retrieve symbols correctly,
    // add the directory of the executable to symbol search path.
    // All following errors are non-fatal.
    const size_t kSymbolsArraySize = 1024;
    scoped_ptr<wchar_t[]> symbols_path(new wchar_t[kSymbolsArraySize]);

    // Note: The below function takes buffer size as number of characters,
    // not number of bytes!
    if (!SymGetSearchPathW(GetCurrentProcess(),
                           symbols_path.get(),
                           kSymbolsArraySize)) {
      DLOG(WARNING) << "SymGetSearchPath failed: ";
      return;
    }

    std::wstring new_path(std::wstring(symbols_path.get()) +
                          L";" + GetExePath().DirName().value());
    if (!SymSetSearchPathW(GetCurrentProcess(), new_path.c_str())) {
      DLOG(WARNING) << "SymSetSearchPath failed.";
      return;
    }
  }

  DWORD init_error_;
  base::Lock lock_;
  DISALLOW_COPY_AND_ASSIGN(SymbolContext);
};

}  // namespace

bool EnableInProcessStackDumping() {
  // Add stack dumping support on exception on windows. Similar to OS_POSIX
  // signal() handling in process_util_posix.cc.
  g_previous_filter = SetUnhandledExceptionFilter(&StackDumpExceptionFilter);
  RouteStdioToConsole();
  return true;
}

// Disable optimizations for the StackTrace::StackTrace function. It is
// important to disable at least frame pointer optimization ("y"), since
// that breaks CaptureStackBackTrace() and prevents StackTrace from working
// in Release builds (it may still be janky if other frames are using FPO,
// but at least it will make it further).
#if defined(COMPILER_MSVC)
#pragma optimize("", off)
#endif

StackTrace::StackTrace() {
  // When walking our own stack, use CaptureStackBackTrace().
  count_ = CaptureStackBackTrace(0, arraysize(trace_), trace_, NULL);
}

#if defined(COMPILER_MSVC)
#pragma optimize("", on)
#endif

StackTrace::StackTrace(const EXCEPTION_POINTERS* exception_pointers) {
  // StackWalk64() may modify context record passed to it, so we will
  // use a copy.
  CONTEXT context_record = *exception_pointers->ContextRecord;
  InitTrace(&context_record);
}

StackTrace::StackTrace(const CONTEXT* context) {
  // StackWalk64() may modify context record passed to it, so we will
  // use a copy.
  CONTEXT context_record = *context;
  InitTrace(&context_record);
}

void StackTrace::InitTrace(CONTEXT* context_record) {
  // When walking an exception stack, we need to use StackWalk64().
  count_ = 0;
  // Initialize stack walking.
  STACKFRAME64 stack_frame;
  memset(&stack_frame, 0, sizeof(stack_frame));
#if defined(_WIN64)
  int machine_type = IMAGE_FILE_MACHINE_AMD64;
  stack_frame.AddrPC.Offset = context_record->Rip;
  stack_frame.AddrFrame.Offset = context_record->Rbp;
  stack_frame.AddrStack.Offset = context_record->Rsp;
#else
  int machine_type = IMAGE_FILE_MACHINE_I386;
  stack_frame.AddrPC.Offset = context_record->Eip;
  stack_frame.AddrFrame.Offset = context_record->Ebp;
  stack_frame.AddrStack.Offset = context_record->Esp;
#endif
  stack_frame.AddrPC.Mode = AddrModeFlat;
  stack_frame.AddrFrame.Mode = AddrModeFlat;
  stack_frame.AddrStack.Mode = AddrModeFlat;
  while (StackWalk64(machine_type,
                     GetCurrentProcess(),
                     GetCurrentThread(),
                     &stack_frame,
                     context_record,
                     NULL,
                     &SymFunctionTableAccess64,
                     &SymGetModuleBase64,
                     NULL) &&
         count_ < arraysize(trace_)) {
    trace_[count_++] = reinterpret_cast<void*>(stack_frame.AddrPC.Offset);
  }

  for (size_t i = count_; i < arraysize(trace_); ++i)
    trace_[i] = NULL;
}

void StackTrace::Print() const {
  OutputToStream(&std::cerr);
}

void StackTrace::OutputToStream(std::ostream* os) const {
  SymbolContext* context = SymbolContext::GetInstance();
  DWORD error = context->init_error();
  if (error != ERROR_SUCCESS) {
    (*os) << "Error initializing symbols (" << error
          << ").  Dumping unresolved backtrace:\n";
    for (size_t i = 0; (i < count_) && os->good(); ++i) {
      (*os) << "\t" << trace_[i] << "\n";
    }
  } else {
    (*os) << "Backtrace:\n";
    context->OutputTraceToStream(trace_, count_, os);
  }
}

}  // namespace debug
}  // namespace base

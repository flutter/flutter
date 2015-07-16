// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_LOGGING_H_
#define BASE_LOGGING_H_

#include <cassert>
#include <string>
#include <cstring>
#include <sstream>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/debug/debugger.h"
#include "build/build_config.h"

//
// Optional message capabilities
// -----------------------------
// Assertion failed messages and fatal errors are displayed in a dialog box
// before the application exits. However, running this UI creates a message
// loop, which causes application messages to be processed and potentially
// dispatched to existing application windows. Since the application is in a
// bad state when this assertion dialog is displayed, these messages may not
// get processed and hang the dialog, or the application might go crazy.
//
// Therefore, it can be beneficial to display the error dialog in a separate
// process from the main application. When the logging system needs to display
// a fatal error dialog box, it will look for a program called
// "DebugMessage.exe" in the same directory as the application executable. It
// will run this application with the message as the command line, and will
// not include the name of the application as is traditional for easier
// parsing.
//
// The code for DebugMessage.exe is only one line. In WinMain, do:
//   MessageBox(NULL, GetCommandLineW(), L"Fatal Error", 0);
//
// If DebugMessage.exe is not found, the logging code will use a normal
// MessageBox, potentially causing the problems discussed above.


// Instructions
// ------------
//
// Make a bunch of macros for logging.  The way to log things is to stream
// things to LOG(<a particular severity level>).  E.g.,
//
//   LOG(INFO) << "Found " << num_cookies << " cookies";
//
// You can also do conditional logging:
//
//   LOG_IF(INFO, num_cookies > 10) << "Got lots of cookies";
//
// The CHECK(condition) macro is active in both debug and release builds and
// effectively performs a LOG(FATAL) which terminates the process and
// generates a crashdump unless a debugger is attached.
//
// There are also "debug mode" logging macros like the ones above:
//
//   DLOG(INFO) << "Found cookies";
//
//   DLOG_IF(INFO, num_cookies > 10) << "Got lots of cookies";
//
// All "debug mode" logging is compiled away to nothing for non-debug mode
// compiles.  LOG_IF and development flags also work well together
// because the code can be compiled away sometimes.
//
// We also have
//
//   LOG_ASSERT(assertion);
//   DLOG_ASSERT(assertion);
//
// which is syntactic sugar for {,D}LOG_IF(FATAL, assert fails) << assertion;
//
// There are "verbose level" logging macros.  They look like
//
//   VLOG(1) << "I'm printed when you run the program with --v=1 or more";
//   VLOG(2) << "I'm printed when you run the program with --v=2 or more";
//
// These always log at the INFO log level (when they log at all).
// The verbose logging can also be turned on module-by-module.  For instance,
//    --vmodule=profile=2,icon_loader=1,browser_*=3,*/chromeos/*=4 --v=0
// will cause:
//   a. VLOG(2) and lower messages to be printed from profile.{h,cc}
//   b. VLOG(1) and lower messages to be printed from icon_loader.{h,cc}
//   c. VLOG(3) and lower messages to be printed from files prefixed with
//      "browser"
//   d. VLOG(4) and lower messages to be printed from files under a
//     "chromeos" directory.
//   e. VLOG(0) and lower messages to be printed from elsewhere
//
// The wildcarding functionality shown by (c) supports both '*' (match
// 0 or more characters) and '?' (match any single character)
// wildcards.  Any pattern containing a forward or backward slash will
// be tested against the whole pathname and not just the module.
// E.g., "*/foo/bar/*=2" would change the logging level for all code
// in source files under a "foo/bar" directory.
//
// There's also VLOG_IS_ON(n) "verbose level" condition macro. To be used as
//
//   if (VLOG_IS_ON(2)) {
//     // do some logging preparation and logging
//     // that can't be accomplished with just VLOG(2) << ...;
//   }
//
// There is also a VLOG_IF "verbose level" condition macro for sample
// cases, when some extra computation and preparation for logs is not
// needed.
//
//   VLOG_IF(1, (size > 1024))
//      << "I'm printed when size is more than 1024 and when you run the "
//         "program with --v=1 or more";
//
// We also override the standard 'assert' to use 'DLOG_ASSERT'.
//
// Lastly, there is:
//
//   PLOG(ERROR) << "Couldn't do foo";
//   DPLOG(ERROR) << "Couldn't do foo";
//   PLOG_IF(ERROR, cond) << "Couldn't do foo";
//   DPLOG_IF(ERROR, cond) << "Couldn't do foo";
//   PCHECK(condition) << "Couldn't do foo";
//   DPCHECK(condition) << "Couldn't do foo";
//
// which append the last system error to the message in string form (taken from
// GetLastError() on Windows and errno on POSIX).
//
// The supported severity levels for macros that allow you to specify one
// are (in increasing order of severity) INFO, WARNING, ERROR, and FATAL.
//
// Very important: logging a message at the FATAL severity level causes
// the program to terminate (after the message is logged).
//
// There is the special severity of DFATAL, which logs FATAL in debug mode,
// ERROR in normal mode.

namespace logging {

// TODO(avi): do we want to do a unification of character types here?
#if defined(OS_WIN)
typedef wchar_t PathChar;
#else
typedef char PathChar;
#endif

// Where to record logging output? A flat file and/or system debug log
// via OutputDebugString.
enum LoggingDestination {
  LOG_NONE                = 0,
  LOG_TO_FILE             = 1 << 0,
  LOG_TO_SYSTEM_DEBUG_LOG = 1 << 1,

  LOG_TO_ALL = LOG_TO_FILE | LOG_TO_SYSTEM_DEBUG_LOG,

  // On Windows, use a file next to the exe; on POSIX platforms, where
  // it may not even be possible to locate the executable on disk, use
  // stderr.
#if defined(OS_WIN)
  LOG_DEFAULT = LOG_TO_FILE,
#elif defined(OS_POSIX)
  LOG_DEFAULT = LOG_TO_SYSTEM_DEBUG_LOG,
#endif
};

// Indicates that the log file should be locked when being written to.
// Unless there is only one single-threaded process that is logging to
// the log file, the file should be locked during writes to make each
// log output atomic. Other writers will block.
//
// All processes writing to the log file must have their locking set for it to
// work properly. Defaults to LOCK_LOG_FILE.
enum LogLockingState { LOCK_LOG_FILE, DONT_LOCK_LOG_FILE };

// On startup, should we delete or append to an existing log file (if any)?
// Defaults to APPEND_TO_OLD_LOG_FILE.
enum OldFileDeletionState { DELETE_OLD_LOG_FILE, APPEND_TO_OLD_LOG_FILE };

struct BASE_EXPORT LoggingSettings {
  // The defaults values are:
  //
  //  logging_dest: LOG_DEFAULT
  //  log_file:     NULL
  //  lock_log:     LOCK_LOG_FILE
  //  delete_old:   APPEND_TO_OLD_LOG_FILE
  LoggingSettings();

  LoggingDestination logging_dest;

  // The three settings below have an effect only when LOG_TO_FILE is
  // set in |logging_dest|.
  const PathChar* log_file;
  LogLockingState lock_log;
  OldFileDeletionState delete_old;
};

// Define different names for the BaseInitLoggingImpl() function depending on
// whether NDEBUG is defined or not so that we'll fail to link if someone tries
// to compile logging.cc with NDEBUG but includes logging.h without defining it,
// or vice versa.
#if NDEBUG
#define BaseInitLoggingImpl BaseInitLoggingImpl_built_with_NDEBUG
#else
#define BaseInitLoggingImpl BaseInitLoggingImpl_built_without_NDEBUG
#endif

// Implementation of the InitLogging() method declared below.  We use a
// more-specific name so we can #define it above without affecting other code
// that has named stuff "InitLogging".
BASE_EXPORT bool BaseInitLoggingImpl(const LoggingSettings& settings);

// Sets the log file name and other global logging state. Calling this function
// is recommended, and is normally done at the beginning of application init.
// If you don't call it, all the flags will be initialized to their default
// values, and there is a race condition that may leak a critical section
// object if two threads try to do the first log at the same time.
// See the definition of the enums above for descriptions and default values.
//
// The default log file is initialized to "debug.log" in the application
// directory. You probably don't want this, especially since the program
// directory may not be writable on an enduser's system.
//
// This function may be called a second time to re-direct logging (e.g after
// loging in to a user partition), however it should never be called more than
// twice.
inline bool InitLogging(const LoggingSettings& settings) {
  return BaseInitLoggingImpl(settings);
}

// Sets the log level. Anything at or above this level will be written to the
// log file/displayed to the user (if applicable). Anything below this level
// will be silently ignored. The log level defaults to 0 (everything is logged
// up to level INFO) if this function is not called.
// Note that log messages for VLOG(x) are logged at level -x, so setting
// the min log level to negative values enables verbose logging.
BASE_EXPORT void SetMinLogLevel(int level);

// Gets the current log level.
BASE_EXPORT int GetMinLogLevel();

// Gets the VLOG default verbosity level.
BASE_EXPORT int GetVlogVerbosity();

// Gets the current vlog level for the given file (usually taken from
// __FILE__).

// Note that |N| is the size *with* the null terminator.
BASE_EXPORT int GetVlogLevelHelper(const char* file_start, size_t N);

template <size_t N>
int GetVlogLevel(const char (&file)[N]) {
  return GetVlogLevelHelper(file, N);
}

// Sets the common items you want to be prepended to each log message.
// process and thread IDs default to off, the timestamp defaults to on.
// If this function is not called, logging defaults to writing the timestamp
// only.
BASE_EXPORT void SetLogItems(bool enable_process_id, bool enable_thread_id,
                             bool enable_timestamp, bool enable_tickcount);

// Sets whether or not you'd like to see fatal debug messages popped up in
// a dialog box or not.
// Dialogs are not shown by default.
BASE_EXPORT void SetShowErrorDialogs(bool enable_dialogs);

// Sets the Log Assert Handler that will be used to notify of check failures.
// The default handler shows a dialog box and then terminate the process,
// however clients can use this function to override with their own handling
// (e.g. a silent one for Unit Tests)
typedef void (*LogAssertHandlerFunction)(const std::string& str);
BASE_EXPORT void SetLogAssertHandler(LogAssertHandlerFunction handler);

// Sets the Log Message Handler that gets passed every log message before
// it's sent to other log destinations (if any).
// Returns true to signal that it handled the message and the message
// should not be sent to other log destinations.
typedef bool (*LogMessageHandlerFunction)(int severity,
    const char* file, int line, size_t message_start, const std::string& str);
BASE_EXPORT void SetLogMessageHandler(LogMessageHandlerFunction handler);
BASE_EXPORT LogMessageHandlerFunction GetLogMessageHandler();

typedef int LogSeverity;
const LogSeverity LOG_VERBOSE = -1;  // This is level 1 verbosity
// Note: the log severities are used to index into the array of names,
// see log_severity_names.
const LogSeverity LOG_INFO = 0;
const LogSeverity LOG_WARNING = 1;
const LogSeverity LOG_ERROR = 2;
const LogSeverity LOG_FATAL = 3;
const LogSeverity LOG_NUM_SEVERITIES = 4;

// LOG_DFATAL is LOG_FATAL in debug mode, ERROR in normal mode
#ifdef NDEBUG
const LogSeverity LOG_DFATAL = LOG_ERROR;
#else
const LogSeverity LOG_DFATAL = LOG_FATAL;
#endif

// A few definitions of macros that don't generate much code. These are used
// by LOG() and LOG_IF, etc. Since these are used all over our code, it's
// better to have compact code for these operations.
#define COMPACT_GOOGLE_LOG_EX_INFO(ClassName, ...) \
  logging::ClassName(__FILE__, __LINE__, logging::LOG_INFO , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_WARNING(ClassName, ...) \
  logging::ClassName(__FILE__, __LINE__, logging::LOG_WARNING , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_ERROR(ClassName, ...) \
  logging::ClassName(__FILE__, __LINE__, logging::LOG_ERROR , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_FATAL(ClassName, ...) \
  logging::ClassName(__FILE__, __LINE__, logging::LOG_FATAL , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_DFATAL(ClassName, ...) \
  logging::ClassName(__FILE__, __LINE__, logging::LOG_DFATAL , ##__VA_ARGS__)

#define COMPACT_GOOGLE_LOG_INFO \
  COMPACT_GOOGLE_LOG_EX_INFO(LogMessage)
#define COMPACT_GOOGLE_LOG_WARNING \
  COMPACT_GOOGLE_LOG_EX_WARNING(LogMessage)
#define COMPACT_GOOGLE_LOG_ERROR \
  COMPACT_GOOGLE_LOG_EX_ERROR(LogMessage)
#define COMPACT_GOOGLE_LOG_FATAL \
  COMPACT_GOOGLE_LOG_EX_FATAL(LogMessage)
#define COMPACT_GOOGLE_LOG_DFATAL \
  COMPACT_GOOGLE_LOG_EX_DFATAL(LogMessage)

#if defined(OS_WIN)
// wingdi.h defines ERROR to be 0. When we call LOG(ERROR), it gets
// substituted with 0, and it expands to COMPACT_GOOGLE_LOG_0. To allow us
// to keep using this syntax, we define this macro to do the same thing
// as COMPACT_GOOGLE_LOG_ERROR, and also define ERROR the same way that
// the Windows SDK does for consistency.
#define ERROR 0
#define COMPACT_GOOGLE_LOG_EX_0(ClassName, ...) \
  COMPACT_GOOGLE_LOG_EX_ERROR(ClassName , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_0 COMPACT_GOOGLE_LOG_ERROR
// Needed for LOG_IS_ON(ERROR).
const LogSeverity LOG_0 = LOG_ERROR;
#endif

// As special cases, we can assume that LOG_IS_ON(FATAL) always holds. Also,
// LOG_IS_ON(DFATAL) always holds in debug mode. In particular, CHECK()s will
// always fire if they fail.
#define LOG_IS_ON(severity) \
  ((::logging::LOG_ ## severity) >= ::logging::GetMinLogLevel())

// We can't do any caching tricks with VLOG_IS_ON() like the
// google-glog version since it requires GCC extensions.  This means
// that using the v-logging functions in conjunction with --vmodule
// may be slow.
#define VLOG_IS_ON(verboselevel) \
  ((verboselevel) <= ::logging::GetVlogLevel(__FILE__))

// Helper macro which avoids evaluating the arguments to a stream if
// the condition doesn't hold. Condition is evaluated once and only once.
#define LAZY_STREAM(stream, condition)                                  \
  !(condition) ? (void) 0 : ::logging::LogMessageVoidify() & (stream)

// We use the preprocessor's merging operator, "##", so that, e.g.,
// LOG(INFO) becomes the token COMPACT_GOOGLE_LOG_INFO.  There's some funny
// subtle difference between ostream member streaming functions (e.g.,
// ostream::operator<<(int) and ostream non-member streaming functions
// (e.g., ::operator<<(ostream&, string&): it turns out that it's
// impossible to stream something like a string directly to an unnamed
// ostream. We employ a neat hack by calling the stream() member
// function of LogMessage which seems to avoid the problem.
#define LOG_STREAM(severity) COMPACT_GOOGLE_LOG_ ## severity.stream()

#define LOG(severity) LAZY_STREAM(LOG_STREAM(severity), LOG_IS_ON(severity))
#define LOG_IF(severity, condition) \
  LAZY_STREAM(LOG_STREAM(severity), LOG_IS_ON(severity) && (condition))

#define SYSLOG(severity) LOG(severity)
#define SYSLOG_IF(severity, condition) LOG_IF(severity, condition)

// The VLOG macros log with negative verbosities.
#define VLOG_STREAM(verbose_level) \
  logging::LogMessage(__FILE__, __LINE__, -verbose_level).stream()

#define VLOG(verbose_level) \
  LAZY_STREAM(VLOG_STREAM(verbose_level), VLOG_IS_ON(verbose_level))

#define VLOG_IF(verbose_level, condition) \
  LAZY_STREAM(VLOG_STREAM(verbose_level), \
      VLOG_IS_ON(verbose_level) && (condition))

#if defined (OS_WIN)
#define VPLOG_STREAM(verbose_level) \
  logging::Win32ErrorLogMessage(__FILE__, __LINE__, -verbose_level, \
    ::logging::GetLastSystemErrorCode()).stream()
#elif defined(OS_POSIX)
#define VPLOG_STREAM(verbose_level) \
  logging::ErrnoLogMessage(__FILE__, __LINE__, -verbose_level, \
    ::logging::GetLastSystemErrorCode()).stream()
#endif

#define VPLOG(verbose_level) \
  LAZY_STREAM(VPLOG_STREAM(verbose_level), VLOG_IS_ON(verbose_level))

#define VPLOG_IF(verbose_level, condition) \
  LAZY_STREAM(VPLOG_STREAM(verbose_level), \
    VLOG_IS_ON(verbose_level) && (condition))

// TODO(akalin): Add more VLOG variants, e.g. VPLOG.

#define LOG_ASSERT(condition)  \
  LOG_IF(FATAL, !(condition)) << "Assert failed: " #condition ". "
#define SYSLOG_ASSERT(condition) \
  SYSLOG_IF(FATAL, !(condition)) << "Assert failed: " #condition ". "

#if defined(OS_WIN)
#define PLOG_STREAM(severity) \
  COMPACT_GOOGLE_LOG_EX_ ## severity(Win32ErrorLogMessage, \
      ::logging::GetLastSystemErrorCode()).stream()
#elif defined(OS_POSIX)
#define PLOG_STREAM(severity) \
  COMPACT_GOOGLE_LOG_EX_ ## severity(ErrnoLogMessage, \
      ::logging::GetLastSystemErrorCode()).stream()
#endif

#define PLOG(severity)                                          \
  LAZY_STREAM(PLOG_STREAM(severity), LOG_IS_ON(severity))

#define PLOG_IF(severity, condition) \
  LAZY_STREAM(PLOG_STREAM(severity), LOG_IS_ON(severity) && (condition))

// The actual stream used isn't important.
#define EAT_STREAM_PARAMETERS                                           \
  true ? (void) 0 : ::logging::LogMessageVoidify() & LOG_STREAM(FATAL)

// CHECK dies with a fatal error if condition is not true.  It is *not*
// controlled by NDEBUG, so the check will be executed regardless of
// compilation mode.
//
// We make sure CHECK et al. always evaluates their arguments, as
// doing CHECK(FunctionWithSideEffect()) is a common idiom.

#if defined(OFFICIAL_BUILD) && defined(NDEBUG) && !defined(OS_ANDROID)

// Make all CHECK functions discard their log strings to reduce code
// bloat for official release builds.

// TODO(akalin): This would be more valuable if there were some way to
// remove BreakDebugger() from the backtrace, perhaps by turning it
// into a macro (like __debugbreak() on Windows).
#define CHECK(condition)                                                \
  !(condition) ? ::base::debug::BreakDebugger() : EAT_STREAM_PARAMETERS

#define PCHECK(condition) CHECK(condition)

#define CHECK_OP(name, op, val1, val2) CHECK((val1) op (val2))

#else

#if defined(_PREFAST_) && defined(OS_WIN)
// Use __analysis_assume to tell the VC++ static analysis engine that
// assert conditions are true, to suppress warnings.  The LAZY_STREAM
// parameter doesn't reference 'condition' in /analyze builds because
// this evaluation confuses /analyze. The !! before condition is because
// __analysis_assume gets confused on some conditions:
// http://randomascii.wordpress.com/2011/09/13/analyze-for-visual-studio-the-ugly-part-5/

#define CHECK(condition)                \
  __analysis_assume(!!(condition)),     \
  LAZY_STREAM(LOG_STREAM(FATAL), false) \
  << "Check failed: " #condition ". "

#define PCHECK(condition)                \
  __analysis_assume(!!(condition)),      \
  LAZY_STREAM(PLOG_STREAM(FATAL), false) \
  << "Check failed: " #condition ". "

#else  // _PREFAST_

#define CHECK(condition)                       \
  LAZY_STREAM(LOG_STREAM(FATAL), !(condition)) \
  << "Check failed: " #condition ". "

#define PCHECK(condition)                       \
  LAZY_STREAM(PLOG_STREAM(FATAL), !(condition)) \
  << "Check failed: " #condition ". "

#endif  // _PREFAST_

// Helper macro for binary operators.
// Don't use this macro directly in your code, use CHECK_EQ et al below.
//
// TODO(akalin): Rewrite this so that constructs like if (...)
// CHECK_EQ(...) else { ... } work properly.
#define CHECK_OP(name, op, val1, val2)                          \
  if (std::string* _result =                                    \
      logging::Check##name##Impl((val1), (val2),                \
                                 #val1 " " #op " " #val2))      \
    logging::LogMessage(__FILE__, __LINE__, _result).stream()

#endif

// Build the error message string.  This is separate from the "Impl"
// function template because it is not performance critical and so can
// be out of line, while the "Impl" code should be inline.  Caller
// takes ownership of the returned string.
template<class t1, class t2>
std::string* MakeCheckOpString(const t1& v1, const t2& v2, const char* names) {
  std::ostringstream ss;
  ss << names << " (" << v1 << " vs. " << v2 << ")";
  std::string* msg = new std::string(ss.str());
  return msg;
}

// Commonly used instantiations of MakeCheckOpString<>. Explicitly instantiated
// in logging.cc.
extern template BASE_EXPORT std::string* MakeCheckOpString<int, int>(
    const int&, const int&, const char* names);
extern template BASE_EXPORT
std::string* MakeCheckOpString<unsigned long, unsigned long>(
    const unsigned long&, const unsigned long&, const char* names);
extern template BASE_EXPORT
std::string* MakeCheckOpString<unsigned long, unsigned int>(
    const unsigned long&, const unsigned int&, const char* names);
extern template BASE_EXPORT
std::string* MakeCheckOpString<unsigned int, unsigned long>(
    const unsigned int&, const unsigned long&, const char* names);
extern template BASE_EXPORT
std::string* MakeCheckOpString<std::string, std::string>(
    const std::string&, const std::string&, const char* name);

// Helper functions for CHECK_OP macro.
// The (int, int) specialization works around the issue that the compiler
// will not instantiate the template version of the function on values of
// unnamed enum type - see comment below.
#define DEFINE_CHECK_OP_IMPL(name, op) \
  template <class t1, class t2> \
  inline std::string* Check##name##Impl(const t1& v1, const t2& v2, \
                                        const char* names) { \
    if (v1 op v2) return NULL; \
    else return MakeCheckOpString(v1, v2, names); \
  } \
  inline std::string* Check##name##Impl(int v1, int v2, const char* names) { \
    if (v1 op v2) return NULL; \
    else return MakeCheckOpString(v1, v2, names); \
  }
DEFINE_CHECK_OP_IMPL(EQ, ==)
DEFINE_CHECK_OP_IMPL(NE, !=)
DEFINE_CHECK_OP_IMPL(LE, <=)
DEFINE_CHECK_OP_IMPL(LT, < )
DEFINE_CHECK_OP_IMPL(GE, >=)
DEFINE_CHECK_OP_IMPL(GT, > )
#undef DEFINE_CHECK_OP_IMPL

#define CHECK_EQ(val1, val2) CHECK_OP(EQ, ==, val1, val2)
#define CHECK_NE(val1, val2) CHECK_OP(NE, !=, val1, val2)
#define CHECK_LE(val1, val2) CHECK_OP(LE, <=, val1, val2)
#define CHECK_LT(val1, val2) CHECK_OP(LT, < , val1, val2)
#define CHECK_GE(val1, val2) CHECK_OP(GE, >=, val1, val2)
#define CHECK_GT(val1, val2) CHECK_OP(GT, > , val1, val2)
#define CHECK_IMPLIES(val1, val2) CHECK(!(val1) || (val2))

#if defined(NDEBUG)
#define ENABLE_DLOG 0
#else
#define ENABLE_DLOG 1
#endif

#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
#define DCHECK_IS_ON() 0
#else
#define DCHECK_IS_ON() 1
#endif

// Definitions for DLOG et al.

#if ENABLE_DLOG

#define DLOG_IS_ON(severity) LOG_IS_ON(severity)
#define DLOG_IF(severity, condition) LOG_IF(severity, condition)
#define DLOG_ASSERT(condition) LOG_ASSERT(condition)
#define DPLOG_IF(severity, condition) PLOG_IF(severity, condition)
#define DVLOG_IF(verboselevel, condition) VLOG_IF(verboselevel, condition)
#define DVPLOG_IF(verboselevel, condition) VPLOG_IF(verboselevel, condition)

#else  // ENABLE_DLOG

// If ENABLE_DLOG is off, we want to avoid emitting any references to
// |condition| (which may reference a variable defined only if NDEBUG
// is not defined).  Contrast this with DCHECK et al., which has
// different behavior.

#define DLOG_IS_ON(severity) false
#define DLOG_IF(severity, condition) EAT_STREAM_PARAMETERS
#define DLOG_ASSERT(condition) EAT_STREAM_PARAMETERS
#define DPLOG_IF(severity, condition) EAT_STREAM_PARAMETERS
#define DVLOG_IF(verboselevel, condition) EAT_STREAM_PARAMETERS
#define DVPLOG_IF(verboselevel, condition) EAT_STREAM_PARAMETERS

#endif  // ENABLE_DLOG

// DEBUG_MODE is for uses like
//   if (DEBUG_MODE) foo.CheckThatFoo();
// instead of
//   #ifndef NDEBUG
//     foo.CheckThatFoo();
//   #endif
//
// We tie its state to ENABLE_DLOG.
enum { DEBUG_MODE = ENABLE_DLOG };

#undef ENABLE_DLOG

#define DLOG(severity)                                          \
  LAZY_STREAM(LOG_STREAM(severity), DLOG_IS_ON(severity))

#define DPLOG(severity)                                         \
  LAZY_STREAM(PLOG_STREAM(severity), DLOG_IS_ON(severity))

#define DVLOG(verboselevel) DVLOG_IF(verboselevel, VLOG_IS_ON(verboselevel))

#define DVPLOG(verboselevel) DVPLOG_IF(verboselevel, VLOG_IS_ON(verboselevel))

// Definitions for DCHECK et al.

#if DCHECK_IS_ON()

#define COMPACT_GOOGLE_LOG_EX_DCHECK(ClassName, ...) \
  COMPACT_GOOGLE_LOG_EX_FATAL(ClassName , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_DCHECK COMPACT_GOOGLE_LOG_FATAL
const LogSeverity LOG_DCHECK = LOG_FATAL;

#else  // DCHECK_IS_ON()

// These are just dummy values.
#define COMPACT_GOOGLE_LOG_EX_DCHECK(ClassName, ...) \
  COMPACT_GOOGLE_LOG_EX_INFO(ClassName , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_DCHECK COMPACT_GOOGLE_LOG_INFO
const LogSeverity LOG_DCHECK = LOG_INFO;

#endif  // DCHECK_IS_ON()

// DCHECK et al. make sure to reference |condition| regardless of
// whether DCHECKs are enabled; this is so that we don't get unused
// variable warnings if the only use of a variable is in a DCHECK.
// This behavior is different from DLOG_IF et al.

#if defined(_PREFAST_) && defined(OS_WIN)
// See comments on the previous use of __analysis_assume.

#define DCHECK(condition)                                               \
  __analysis_assume(!!(condition)),                                     \
  LAZY_STREAM(LOG_STREAM(DCHECK), false)                                \
  << "Check failed: " #condition ". "

#define DPCHECK(condition)                                              \
  __analysis_assume(!!(condition)),                                     \
  LAZY_STREAM(PLOG_STREAM(DCHECK), false)                               \
  << "Check failed: " #condition ". "

#else  // _PREFAST_

#define DCHECK(condition)                                                \
  LAZY_STREAM(LOG_STREAM(DCHECK), DCHECK_IS_ON() ? !(condition) : false) \
      << "Check failed: " #condition ". "

#define DPCHECK(condition)                                                \
  LAZY_STREAM(PLOG_STREAM(DCHECK), DCHECK_IS_ON() ? !(condition) : false) \
      << "Check failed: " #condition ". "

#endif  // _PREFAST_

// Helper macro for binary operators.
// Don't use this macro directly in your code, use DCHECK_EQ et al below.
#define DCHECK_OP(name, op, val1, val2)                                   \
  if (DCHECK_IS_ON())                                                     \
    if (std::string* _result = logging::Check##name##Impl(                \
            (val1), (val2), #val1 " " #op " " #val2))                     \
  logging::LogMessage(__FILE__, __LINE__, ::logging::LOG_DCHECK, _result) \
      .stream()

// Equality/Inequality checks - compare two values, and log a
// LOG_DCHECK message including the two values when the result is not
// as expected.  The values must have operator<<(ostream, ...)
// defined.
//
// You may append to the error message like so:
//   DCHECK_NE(1, 2) << ": The world must be ending!";
//
// We are very careful to ensure that each argument is evaluated exactly
// once, and that anything which is legal to pass as a function argument is
// legal here.  In particular, the arguments may be temporary expressions
// which will end up being destroyed at the end of the apparent statement,
// for example:
//   DCHECK_EQ(string("abc")[1], 'b');
//
// WARNING: These may not compile correctly if one of the arguments is a pointer
// and the other is NULL. To work around this, simply static_cast NULL to the
// type of the desired pointer.

#define DCHECK_EQ(val1, val2) DCHECK_OP(EQ, ==, val1, val2)
#define DCHECK_NE(val1, val2) DCHECK_OP(NE, !=, val1, val2)
#define DCHECK_LE(val1, val2) DCHECK_OP(LE, <=, val1, val2)
#define DCHECK_LT(val1, val2) DCHECK_OP(LT, < , val1, val2)
#define DCHECK_GE(val1, val2) DCHECK_OP(GE, >=, val1, val2)
#define DCHECK_GT(val1, val2) DCHECK_OP(GT, > , val1, val2)
#define DCHECK_IMPLIES(val1, val2) DCHECK(!(val1) || (val2))

#if !DCHECK_IS_ON() && defined(OS_CHROMEOS)
// Implement logging of NOTREACHED() as a dedicated function to get function
// call overhead down to a minimum.
void LogErrorNotReached(const char* file, int line);
#define NOTREACHED()                                       \
  true ? ::logging::LogErrorNotReached(__FILE__, __LINE__) \
       : EAT_STREAM_PARAMETERS
#else
#define NOTREACHED() DCHECK(false)
#endif

// Redefine the standard assert to use our nice log files
#undef assert
#define assert(x) DLOG_ASSERT(x)

// This class more or less represents a particular log message.  You
// create an instance of LogMessage and then stream stuff to it.
// When you finish streaming to it, ~LogMessage is called and the
// full message gets streamed to the appropriate destination.
//
// You shouldn't actually use LogMessage's constructor to log things,
// though.  You should use the LOG() macro (and variants thereof)
// above.
class BASE_EXPORT LogMessage {
 public:
  // Used for LOG(severity).
  LogMessage(const char* file, int line, LogSeverity severity);

  // Used for CHECK_EQ(), etc. Takes ownership of the given string.
  // Implied severity = LOG_FATAL.
  LogMessage(const char* file, int line, std::string* result);

  // Used for DCHECK_EQ(), etc. Takes ownership of the given string.
  LogMessage(const char* file, int line, LogSeverity severity,
             std::string* result);

  ~LogMessage();

  std::ostream& stream() { return stream_; }

 private:
  void Init(const char* file, int line);

  LogSeverity severity_;
  std::ostringstream stream_;
  size_t message_start_;  // Offset of the start of the message (past prefix
                          // info).
  // The file and line information passed in to the constructor.
  const char* file_;
  const int line_;

#if defined(OS_WIN)
  // Stores the current value of GetLastError in the constructor and restores
  // it in the destructor by calling SetLastError.
  // This is useful since the LogMessage class uses a lot of Win32 calls
  // that will lose the value of GLE and the code that called the log function
  // will have lost the thread error value when the log call returns.
  class SaveLastError {
   public:
    SaveLastError();
    ~SaveLastError();

    unsigned long get_error() const { return last_error_; }

   protected:
    unsigned long last_error_;
  };

  SaveLastError last_error_;
#endif

  DISALLOW_COPY_AND_ASSIGN(LogMessage);
};

// A non-macro interface to the log facility; (useful
// when the logging level is not a compile-time constant).
inline void LogAtLevel(int const log_level, std::string const &msg) {
  LogMessage(__FILE__, __LINE__, log_level).stream() << msg;
}

// This class is used to explicitly ignore values in the conditional
// logging macros.  This avoids compiler warnings like "value computed
// is not used" and "statement has no effect".
class LogMessageVoidify {
 public:
  LogMessageVoidify() { }
  // This has to be an operator with a precedence lower than << but
  // higher than ?:
  void operator&(std::ostream&) { }
};

#if defined(OS_WIN)
typedef unsigned long SystemErrorCode;
#elif defined(OS_POSIX)
typedef int SystemErrorCode;
#endif

// Alias for ::GetLastError() on Windows and errno on POSIX. Avoids having to
// pull in windows.h just for GetLastError() and DWORD.
BASE_EXPORT SystemErrorCode GetLastSystemErrorCode();
BASE_EXPORT std::string SystemErrorCodeToString(SystemErrorCode error_code);

#if defined(OS_WIN)
// Appends a formatted system message of the GetLastError() type.
class BASE_EXPORT Win32ErrorLogMessage {
 public:
  Win32ErrorLogMessage(const char* file,
                       int line,
                       LogSeverity severity,
                       SystemErrorCode err);

  // Appends the error message before destructing the encapsulated class.
  ~Win32ErrorLogMessage();

  std::ostream& stream() { return log_message_.stream(); }

 private:
  SystemErrorCode err_;
  LogMessage log_message_;

  DISALLOW_COPY_AND_ASSIGN(Win32ErrorLogMessage);
};
#elif defined(OS_POSIX)
// Appends a formatted system message of the errno type
class BASE_EXPORT ErrnoLogMessage {
 public:
  ErrnoLogMessage(const char* file,
                  int line,
                  LogSeverity severity,
                  SystemErrorCode err);

  // Appends the error message before destructing the encapsulated class.
  ~ErrnoLogMessage();

  std::ostream& stream() { return log_message_.stream(); }

 private:
  SystemErrorCode err_;
  LogMessage log_message_;

  DISALLOW_COPY_AND_ASSIGN(ErrnoLogMessage);
};
#endif  // OS_WIN

// Closes the log file explicitly if open.
// NOTE: Since the log file is opened as necessary by the action of logging
//       statements, there's no guarantee that it will stay closed
//       after this call.
BASE_EXPORT void CloseLogFile();

// Async signal safe logging mechanism.
BASE_EXPORT void RawLog(int level, const char* message);

#define RAW_LOG(level, message) logging::RawLog(logging::LOG_ ## level, message)

#define RAW_CHECK(condition)                                                   \
  do {                                                                         \
    if (!(condition))                                                          \
      logging::RawLog(logging::LOG_FATAL, "Check failed: " #condition "\n");   \
  } while (0)

#if defined(OS_WIN)
// Returns the default log file path.
BASE_EXPORT std::wstring GetLogFileFullPath();
#endif

}  // namespace logging

// Note that "The behavior of a C++ program is undefined if it adds declarations
// or definitions to namespace std or to a namespace within namespace std unless
// otherwise specified." --C++11[namespace.std]
//
// We've checked that this particular definition has the intended behavior on
// our implementations, but it's prone to breaking in the future, and please
// don't imitate this in your own definitions without checking with some
// standard library experts.
namespace std {
// These functions are provided as a convenience for logging, which is where we
// use streams (it is against Google style to use streams in other places). It
// is designed to allow you to emit non-ASCII Unicode strings to the log file,
// which is normally ASCII. It is relatively slow, so try not to use it for
// common cases. Non-ASCII characters will be converted to UTF-8 by these
// operators.
BASE_EXPORT std::ostream& operator<<(std::ostream& out, const wchar_t* wstr);
inline std::ostream& operator<<(std::ostream& out, const std::wstring& wstr) {
  return out << wstr.c_str();
}
}  // namespace std

// The NOTIMPLEMENTED() macro annotates codepaths which have
// not been implemented yet.
//
// The implementation of this macro is controlled by NOTIMPLEMENTED_POLICY:
//   0 -- Do nothing (stripped by compiler)
//   1 -- Warn at compile time
//   2 -- Fail at compile time
//   3 -- Fail at runtime (DCHECK)
//   4 -- [default] LOG(ERROR) at runtime
//   5 -- LOG(ERROR) at runtime, only once per call-site

#ifndef NOTIMPLEMENTED_POLICY
#if defined(OS_ANDROID) && defined(OFFICIAL_BUILD)
#define NOTIMPLEMENTED_POLICY 0
#else
// Select default policy: LOG(ERROR)
#define NOTIMPLEMENTED_POLICY 4
#endif
#endif

#if defined(COMPILER_GCC)
// On Linux, with GCC, we can use __PRETTY_FUNCTION__ to get the demangled name
// of the current function in the NOTIMPLEMENTED message.
#define NOTIMPLEMENTED_MSG "Not implemented reached in " << __PRETTY_FUNCTION__
#else
#define NOTIMPLEMENTED_MSG "NOT IMPLEMENTED"
#endif

#if NOTIMPLEMENTED_POLICY == 0
#define NOTIMPLEMENTED() EAT_STREAM_PARAMETERS
#elif NOTIMPLEMENTED_POLICY == 1
// TODO, figure out how to generate a warning
#define NOTIMPLEMENTED() COMPILE_ASSERT(false, NOT_IMPLEMENTED)
#elif NOTIMPLEMENTED_POLICY == 2
#define NOTIMPLEMENTED() COMPILE_ASSERT(false, NOT_IMPLEMENTED)
#elif NOTIMPLEMENTED_POLICY == 3
#define NOTIMPLEMENTED() NOTREACHED()
#elif NOTIMPLEMENTED_POLICY == 4
#define NOTIMPLEMENTED() LOG(ERROR) << NOTIMPLEMENTED_MSG
#elif NOTIMPLEMENTED_POLICY == 5
#define NOTIMPLEMENTED() do {\
  static bool logged_once = false;\
  LOG_IF(ERROR, !logged_once) << NOTIMPLEMENTED_MSG;\
  logged_once = true;\
} while(0);\
EAT_STREAM_PARAMETERS
#endif

#endif  // BASE_LOGGING_H_

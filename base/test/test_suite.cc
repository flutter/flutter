// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_suite.h"

#include "base/at_exit.h"
#include "base/base_paths.h"
#include "base/base_switches.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/debug/debugger.h"
#include "base/debug/stack_trace.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/i18n/icu_util.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/path_service.h"
#include "base/process/memory.h"
#include "base/test/gtest_xml_unittest_result_printer.h"
#include "base/test/gtest_xml_util.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/multiprocess_test.h"
#include "base/test/test_switches.h"
#include "base/test/test_timeouts.h"
#include "base/time/time.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/multiprocess_func_list.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#if defined(OS_IOS)
#include "base/test/test_listener_ios.h"
#endif  // OS_IOS
#endif  // OS_MACOSX

#if !defined(OS_WIN)
#include "base/i18n/rtl.h"
#if !defined(OS_IOS)
#include "base/strings/string_util.h"
#include "third_party/icu/source/common/unicode/uloc.h"
#endif
#endif

#if defined(OS_ANDROID)
#include "base/test/test_support_android.h"
#endif

#if defined(OS_IOS)
#include "base/test/test_support_ios.h"
#endif

namespace base {

namespace {

class MaybeTestDisabler : public testing::EmptyTestEventListener {
 public:
  void OnTestStart(const testing::TestInfo& test_info) override {
    ASSERT_FALSE(TestSuite::IsMarkedMaybe(test_info))
        << "Probably the OS #ifdefs don't include all of the necessary "
           "platforms.\nPlease ensure that no tests have the MAYBE_ prefix "
           "after the code is preprocessed.";
  }
};

class TestClientInitializer : public testing::EmptyTestEventListener {
 public:
  TestClientInitializer()
      : old_command_line_(CommandLine::NO_PROGRAM) {
  }

  void OnTestStart(const testing::TestInfo& test_info) override {
    old_command_line_ = *CommandLine::ForCurrentProcess();
  }

  void OnTestEnd(const testing::TestInfo& test_info) override {
    *CommandLine::ForCurrentProcess() = old_command_line_;
  }

 private:
  CommandLine old_command_line_;

  DISALLOW_COPY_AND_ASSIGN(TestClientInitializer);
};

}  // namespace

int RunUnitTestsUsingBaseTestSuite(int argc, char **argv) {
  TestSuite test_suite(argc, argv);
  return LaunchUnitTests(argc, argv,
                         Bind(&TestSuite::Run, Unretained(&test_suite)));
}

TestSuite::TestSuite(int argc, char** argv) : initialized_command_line_(false) {
  PreInitialize(true);
  InitializeFromCommandLine(argc, argv);
}

#if defined(OS_WIN)
TestSuite::TestSuite(int argc, wchar_t** argv)
    : initialized_command_line_(false) {
  PreInitialize(true);
  InitializeFromCommandLine(argc, argv);
}
#endif  // defined(OS_WIN)

TestSuite::TestSuite(int argc, char** argv, bool create_at_exit_manager)
    : initialized_command_line_(false) {
  PreInitialize(create_at_exit_manager);
  InitializeFromCommandLine(argc, argv);
}

TestSuite::~TestSuite() {
  if (initialized_command_line_)
    CommandLine::Reset();
}

void TestSuite::InitializeFromCommandLine(int argc, char** argv) {
  initialized_command_line_ = CommandLine::Init(argc, argv);
  testing::InitGoogleTest(&argc, argv);
  testing::InitGoogleMock(&argc, argv);

#if defined(OS_IOS)
  InitIOSRunHook(this, argc, argv);
#endif
}

#if defined(OS_WIN)
void TestSuite::InitializeFromCommandLine(int argc, wchar_t** argv) {
  // Windows CommandLine::Init ignores argv anyway.
  initialized_command_line_ = CommandLine::Init(argc, NULL);
  testing::InitGoogleTest(&argc, argv);
  testing::InitGoogleMock(&argc, argv);
}
#endif  // defined(OS_WIN)

void TestSuite::PreInitialize(bool create_at_exit_manager) {
#if defined(OS_WIN)
  testing::GTEST_FLAG(catch_exceptions) = false;
#endif
  EnableTerminationOnHeapCorruption();
#if defined(OS_LINUX) && defined(USE_AURA)
  // When calling native char conversion functions (e.g wrctomb) we need to
  // have the locale set. In the absence of such a call the "C" locale is the
  // default. In the gtk code (below) gtk_init() implicitly sets a locale.
  setlocale(LC_ALL, "");
#endif  // defined(OS_LINUX) && defined(USE_AURA)

  // On Android, AtExitManager is created in
  // testing/android/native_test_wrapper.cc before main() is called.
#if !defined(OS_ANDROID)
  if (create_at_exit_manager)
    at_exit_manager_.reset(new AtExitManager);
#endif

  // Don't add additional code to this function.  Instead add it to
  // Initialize().  See bug 6436.
}


// static
bool TestSuite::IsMarkedMaybe(const testing::TestInfo& test) {
  return strncmp(test.name(), "MAYBE_", 6) == 0;
}

void TestSuite::CatchMaybeTests() {
  testing::TestEventListeners& listeners =
      testing::UnitTest::GetInstance()->listeners();
  listeners.Append(new MaybeTestDisabler);
}

void TestSuite::ResetCommandLine() {
  testing::TestEventListeners& listeners =
      testing::UnitTest::GetInstance()->listeners();
  listeners.Append(new TestClientInitializer);
}

void TestSuite::AddTestLauncherResultPrinter() {
  // Only add the custom printer if requested.
  if (!CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kTestLauncherOutput)) {
    return;
  }

  FilePath output_path(CommandLine::ForCurrentProcess()->GetSwitchValuePath(
      switches::kTestLauncherOutput));

  // Do not add the result printer if output path already exists. It's an
  // indicator there is a process printing to that file, and we're likely
  // its child. Do not clobber the results in that case.
  if (PathExists(output_path)) {
    LOG(WARNING) << "Test launcher output path " << output_path.AsUTF8Unsafe()
                 << " exists. Not adding test launcher result printer.";
    return;
  }

  XmlUnitTestResultPrinter* printer = new XmlUnitTestResultPrinter;
  CHECK(printer->Initialize(output_path));
  testing::TestEventListeners& listeners =
      testing::UnitTest::GetInstance()->listeners();
  listeners.Append(printer);
}

// Don't add additional code to this method.  Instead add it to
// Initialize().  See bug 6436.
int TestSuite::Run() {
#if defined(OS_IOS)
  RunTestsFromIOSApp();
#endif

#if defined(OS_MACOSX)
  mac::ScopedNSAutoreleasePool scoped_pool;
#endif

  Initialize();
  std::string client_func =
      CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
          switches::kTestChildProcess);

  // Check to see if we are being run as a client process.
  if (!client_func.empty())
    return multi_process_function_list::InvokeChildProcessTest(client_func);
#if defined(OS_IOS)
  test_listener_ios::RegisterTestEndListener();
#endif
  int result = RUN_ALL_TESTS();

#if defined(OS_MACOSX)
  // This MUST happen before Shutdown() since Shutdown() tears down
  // objects (such as NotificationService::current()) that Cocoa
  // objects use to remove themselves as observers.
  scoped_pool.Recycle();
#endif

  Shutdown();

  return result;
}

// static
void TestSuite::UnitTestAssertHandler(const std::string& str) {
#if defined(OS_ANDROID)
  // Correlating test stdio with logcat can be difficult, so we emit this
  // helpful little hint about what was running.  Only do this for Android
  // because other platforms don't separate out the relevant logs in the same
  // way.
  const ::testing::TestInfo* const test_info =
      ::testing::UnitTest::GetInstance()->current_test_info();
  if (test_info) {
    LOG(ERROR) << "Currently running: " << test_info->test_case_name() << "."
               << test_info->name();
    fflush(stderr);
  }
#endif  // defined(OS_ANDROID)

  // The logging system actually prints the message before calling the assert
  // handler. Just exit now to avoid printing too many stack traces.
  _exit(1);
}

void TestSuite::SuppressErrorDialogs() {
#if defined(OS_WIN)
  UINT new_flags = SEM_FAILCRITICALERRORS |
                   SEM_NOGPFAULTERRORBOX |
                   SEM_NOOPENFILEERRORBOX;

  // Preserve existing error mode, as discussed at
  // http://blogs.msdn.com/oldnewthing/archive/2004/07/27/198410.aspx
  UINT existing_flags = SetErrorMode(new_flags);
  SetErrorMode(existing_flags | new_flags);

#if defined(_DEBUG) && defined(_HAS_EXCEPTIONS) && (_HAS_EXCEPTIONS == 1)
  // Suppress the "Debug Assertion Failed" dialog.
  // TODO(hbono): remove this code when gtest has it.
  // http://groups.google.com/d/topic/googletestframework/OjuwNlXy5ac/discussion
  _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
  _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
#endif  // defined(_DEBUG) && defined(_HAS_EXCEPTIONS) && (_HAS_EXCEPTIONS == 1)
#endif  // defined(OS_WIN)
}

void TestSuite::Initialize() {
#if !defined(OS_IOS)
  if (CommandLine::ForCurrentProcess()->HasSwitch(switches::kWaitForDebugger)) {
    debug::WaitForDebugger(60, true);
  }
#endif

#if defined(OS_IOS)
  InitIOSTestMessageLoop();
#endif  // OS_IOS

#if defined(OS_ANDROID)
  InitAndroidTest();
#else
  // Initialize logging.
  FilePath exe;
  PathService::Get(FILE_EXE, &exe);
  FilePath log_filename = exe.ReplaceExtension(FILE_PATH_LITERAL("log"));
  logging::LoggingSettings settings;
  settings.logging_dest = logging::LOG_TO_ALL;
  settings.log_file = log_filename.value().c_str();
  settings.delete_old = logging::DELETE_OLD_LOG_FILE;
  logging::InitLogging(settings);
  // We want process and thread IDs because we may have multiple processes.
  // Note: temporarily enabled timestamps in an effort to catch bug 6361.
  logging::SetLogItems(true, true, true, true);
#endif  // else defined(OS_ANDROID)

  CHECK(debug::EnableInProcessStackDumping());
#if defined(OS_WIN)
  // Make sure we run with high resolution timer to minimize differences
  // between production code and test code.
  Time::EnableHighResolutionTimer(true);
#endif  // defined(OS_WIN)

  // In some cases, we do not want to see standard error dialogs.
  if (!debug::BeingDebugged() &&
      !CommandLine::ForCurrentProcess()->HasSwitch("show-error-dialogs")) {
    SuppressErrorDialogs();
    debug::SetSuppressDebugUI(true);
    logging::SetLogAssertHandler(UnitTestAssertHandler);
  }

  i18n::InitializeICU();
  // On the Mac OS X command line, the default locale is *_POSIX. In Chromium,
  // the locale is set via an OS X locale API and is never *_POSIX.
  // Some tests (such as those involving word break iterator) will behave
  // differently and fail if we use *POSIX locale. Setting it to en_US here
  // does not affect tests that explicitly overrides the locale for testing.
  // This can be an issue on all platforms other than Windows.
  // TODO(jshin): Should we set the locale via an OS X locale API here?
#if !defined(OS_WIN)
#if defined(OS_IOS)
  i18n::SetICUDefaultLocale("en_US");
#else
  std::string default_locale(uloc_getDefault());
  if (EndsWith(default_locale, "POSIX", CompareCase::INSENSITIVE_ASCII))
    i18n::SetICUDefaultLocale("en_US");
#endif
#endif

  CatchMaybeTests();
  ResetCommandLine();
  AddTestLauncherResultPrinter();

  TestTimeouts::Initialize();

  trace_to_file_.BeginTracingFromCommandLineOptions();
}

void TestSuite::Shutdown() {
}

}  // namespace base

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "base/path_service.h"
#include "base/run_loop.h"
#include "base/strings/utf_string_conversions.h"
#include "base/threading/thread.h"
#include "crypto/random.h"
#include "mojo/dart/embedder/dart_controller.h"
#include "mojo/dart/embedder/test/dart_to_cpp.mojom.h"
#include "mojo/edk/test/test_utils.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace dart {

// Global value updated by some checks to prevent compilers from optimizing
// reads out of existence.
uint32 g_waste_accumulator = 0;

namespace {

// Negative numbers with different values in each byte, the last of
// which can survive promotion to double and back.
const int8  kExpectedInt8Value = -65;
const int16 kExpectedInt16Value = -16961;
const int32 kExpectedInt32Value = -1145258561;
const int64 kExpectedInt64Value = -77263311946305LL;

// Positive numbers with different values in each byte, the last of
// which can survive promotion to double and back.
const uint8  kExpectedUInt8Value = 65;
const uint16 kExpectedUInt16Value = 16961;
const uint32 kExpectedUInt32Value = 1145258561;
const uint64 kExpectedUInt64Value = 77263311946305LL;

// Double/float values, including special case constants.
const double kExpectedDoubleVal = 3.14159265358979323846;
const double kExpectedDoubleInf = std::numeric_limits<double>::infinity();
const double kExpectedDoubleNan = std::numeric_limits<double>::quiet_NaN();
const float kExpectedFloatVal = static_cast<float>(kExpectedDoubleVal);
const float kExpectedFloatInf = std::numeric_limits<float>::infinity();
const float kExpectedFloatNan = std::numeric_limits<float>::quiet_NaN();

// NaN has the property that it is not equal to itself.
#define EXPECT_NAN(x) EXPECT_NE(x, x)

void CheckDataPipe(MojoHandle data_pipe_handle) {
  unsigned char buffer[100];
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  MojoResult result = MojoReadData(
      data_pipe_handle, buffer, &buffer_size, MOJO_READ_DATA_FLAG_NONE);
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(64u, buffer_size);
  for (int i = 0; i < 64; ++i) {
    EXPECT_EQ(i, buffer[i]);
  }
}

void CheckMessagePipe(MojoHandle message_pipe_handle) {
  unsigned char buffer[100];
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  MojoResult result = MojoReadMessage(
      message_pipe_handle, buffer, &buffer_size, 0, 0, 0);
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(64u, buffer_size);
  for (int i = 0; i < 64; ++i) {
    EXPECT_EQ(255 - i, buffer[i]);
  }
}

dart_to_cpp::EchoArgsPtr BuildSampleEchoArgs() {
  dart_to_cpp::EchoArgsPtr args(dart_to_cpp::EchoArgs::New());
  args->si64 = kExpectedInt64Value;
  args->si32 = kExpectedInt32Value;
  args->si16 = kExpectedInt16Value;
  args->si8 = kExpectedInt8Value;
  args->ui64 = kExpectedUInt64Value;
  args->ui32 = kExpectedUInt32Value;
  args->ui16 = kExpectedUInt16Value;
  args->ui8 = kExpectedUInt8Value;
  args->float_val = kExpectedFloatVal;
  args->float_inf = kExpectedFloatInf;
  args->float_nan = kExpectedFloatNan;
  args->double_val = kExpectedDoubleVal;
  args->double_inf = kExpectedDoubleInf;
  args->double_nan = kExpectedDoubleNan;
  args->name = "coming";
  Array<String> string_array(3);
  string_array[0] = "one";
  string_array[1] = "two";
  string_array[2] = "three";
  args->string_array = string_array.Pass();
  return args.Pass();
}

void CheckSampleEchoArgs(const dart_to_cpp::EchoArgs& arg) {
  EXPECT_EQ(kExpectedInt64Value, arg.si64);
  EXPECT_EQ(kExpectedInt32Value, arg.si32);
  EXPECT_EQ(kExpectedInt16Value, arg.si16);
  EXPECT_EQ(kExpectedInt8Value, arg.si8);
  EXPECT_EQ(kExpectedUInt64Value, arg.ui64);
  EXPECT_EQ(kExpectedUInt32Value, arg.ui32);
  EXPECT_EQ(kExpectedUInt16Value, arg.ui16);
  EXPECT_EQ(kExpectedUInt8Value, arg.ui8);
  EXPECT_EQ(kExpectedFloatVal, arg.float_val);
  EXPECT_EQ(kExpectedFloatInf, arg.float_inf);
  EXPECT_NAN(arg.float_nan);
  EXPECT_EQ(kExpectedDoubleVal, arg.double_val);
  EXPECT_EQ(kExpectedDoubleInf, arg.double_inf);
  EXPECT_NAN(arg.double_nan);
  EXPECT_EQ(std::string("coming"), arg.name.get());
  EXPECT_EQ(std::string("one"), arg.string_array[0].get());
  EXPECT_EQ(std::string("two"), arg.string_array[1].get());
  EXPECT_EQ(std::string("three"), arg.string_array[2].get());
  CheckDataPipe(arg.data_handle.get().value());
  CheckMessagePipe(arg.message_handle.get().value());
}

void CheckSampleEchoArgsList(const dart_to_cpp::EchoArgsListPtr& list) {
  if (list.is_null())
    return;
  CheckSampleEchoArgs(*list->item);
  CheckSampleEchoArgsList(list->next);
}

// Base Provider implementation class. It's expected that tests subclass and
// override the appropriate Provider functions. When test is done quit the
// run_loop().
class CppSideConnection : public dart_to_cpp::CppSide {
 public:
  CppSideConnection() :
      run_loop_(NULL),
      dart_side_(NULL),
      mishandled_messages_(0),
      binding_(this) {
  }
  ~CppSideConnection() override {}

  void Bind(InterfaceRequest<dart_to_cpp::CppSide> request) {
    binding_.Bind(request.Pass());
  }

  void set_run_loop(base::RunLoop* run_loop) { run_loop_ = run_loop; }
  base::RunLoop* run_loop() { return run_loop_; }

  void set_dart_side(dart_to_cpp::DartSide* dart_side) {
    dart_side_ = dart_side;
  }
  dart_to_cpp::DartSide* dart_side() { return dart_side_; }

  // dart_to_cpp::CppSide:
  void StartTest() override { NOTREACHED(); }

  void TestFinished() override { NOTREACHED(); }

  void PingResponse() override { mishandled_messages_ += 1; }

  void EchoResponse(dart_to_cpp::EchoArgsListPtr list) override {
    mishandled_messages_ += 1;
  }

 protected:
  base::RunLoop* run_loop_;
  dart_to_cpp::DartSide* dart_side_;
  int mishandled_messages_;

 private:
  StrongBinding<dart_to_cpp::CppSide> binding_;
  DISALLOW_COPY_AND_ASSIGN(CppSideConnection);
};

// Trivial test to verify a message sent from Dart is received.
class PingCppSideConnection : public CppSideConnection {
 public:
  PingCppSideConnection() : got_message_(false) {}
  ~PingCppSideConnection() override {}

  // dart_to_cpp::CppSide:
  void StartTest() override {
    dart_side_->Ping();
  }

  void PingResponse() override {
    got_message_ = true;
    run_loop()->Quit();
  }

  bool DidSucceed() {
    return got_message_ && !mishandled_messages_;
  }

 private:
  bool got_message_;
  DISALLOW_COPY_AND_ASSIGN(PingCppSideConnection);
};

// Test that parameters are passed with correct values.
class EchoCppSideConnection : public CppSideConnection {
 public:
  EchoCppSideConnection() :
      message_count_(0),
      termination_seen_(false) {
  }
  ~EchoCppSideConnection() override {}

  // dart_to_cpp::CppSide:
  void StartTest() override {
    dart_side_->Echo(kExpectedMessageCount, BuildSampleEchoArgs());
  }

  void EchoResponse(dart_to_cpp::EchoArgsListPtr list) override {
    const dart_to_cpp::EchoArgsPtr& special_arg = list->item;
    message_count_ += 1;
    EXPECT_EQ(-1, special_arg->si64);
    EXPECT_EQ(-1, special_arg->si32);
    EXPECT_EQ(-1, special_arg->si16);
    EXPECT_EQ(-1, special_arg->si8);
    EXPECT_EQ(std::string("going"), special_arg->name.To<std::string>());
    CheckSampleEchoArgsList(list->next);
  }

  void TestFinished() override {
    termination_seen_ = true;
    run_loop()->Quit();
  }

  bool DidSucceed() {
    return termination_seen_ &&
        !mishandled_messages_ &&
        message_count_ == kExpectedMessageCount;
  }

 private:
  static const int kExpectedMessageCount = 10;
  int message_count_;
  bool termination_seen_;
  DISALLOW_COPY_AND_ASSIGN(EchoCppSideConnection);
};

}  // namespace

class DartToCppTest : public testing::Test {
 public:
  DartToCppTest() {}

  bool RunTest(const std::string& test, CppSideConnection* cpp_side) {
    // Putting Dart on its own thread so we can use Dart_RunLoop (called from
    // DartController::RunDartScript) and base::RunLoop::Run together. Passing
    // the thread to RunWithDartOnThread instead of inlining that function here
    // so that we are sure the MessagePipe destructor runs and closes the
    // handles on the C++ side before the Thread destructor runs and joins on
    // the Dart thread. Closing the handles on the C++ side must happen first
    // because it is the client, and therefore the Dart side will run and not
    // join while handles are still open, until the C++ side closes them.
    base::Thread dart_thread("dart");
    cpp_side->set_run_loop(&run_loop_);
    return RunWithDartOnThread(&dart_thread, test, cpp_side);
  }

 private:
  base::MessageLoop loop;
  base::RunLoop run_loop_;

  static void UnhandledExceptionCallback(bool* exception, Dart_Handle error) {
    *exception = true;
  }

  static bool GenerateEntropy(uint8_t* buffer, intptr_t length) {
    crypto::RandBytes(reinterpret_cast<void*>(buffer), length);
    return true;
  }

  static void InitializeDartConfig(DartControllerConfig* config,
                                   const std::string& test,
                                   MojoHandle handle,
                                   const char** arguments,
                                   int arguments_count,
                                   bool* unhandled_exception,
                                   char** error) {
    base::FilePath path;
    PathService::Get(base::DIR_SOURCE_ROOT, &path);
    path = path.AppendASCII("mojo")
               .AppendASCII("dart")
               .AppendASCII("embedder")
               .AppendASCII("test")
               .AppendASCII(test);

    // Read in the source.
    std::string source;
    EXPECT_TRUE(ReadFileToString(path, &source)) << "Failed to read test file";

    // Setup the package root.
    base::FilePath package_root;
    PathService::Get(base::DIR_EXE, &package_root);
    package_root = package_root.AppendASCII("gen")
                               .AppendASCII("dart-pkg")
                               .AppendASCII("packages");


    config->strict_compilation = true;
    config->script = source;
    config->script_uri = path.AsUTF8Unsafe();
    config->package_root = package_root.AsUTF8Unsafe();
    config->application_data = nullptr;
    config->callbacks.exception =
        base::Bind(&UnhandledExceptionCallback, unhandled_exception);
    config->entropy = GenerateEntropy;
    config->handle = handle;
    config->arguments = arguments;
    config->arguments_count = arguments_count;
    config->compile_all = false;
    config->error = error;
  }

  static void RunDartSide(const DartControllerConfig& config) {
    DartController::RunSingleDartScript(config);
  }

  bool RunWithDartOnThread(base::Thread* dart_thread,
                           const std::string& test,
                           CppSideConnection* cpp_side) {
    dart_to_cpp::DartSidePtr dart_side_ptr;
    auto dart_side_request = GetProxy(&dart_side_ptr);

    dart_to_cpp::CppSidePtr cpp_side_ptr;
    cpp_side->Bind(GetProxy(&cpp_side_ptr));
    dart_side_ptr->SetClient(cpp_side_ptr.Pass());

    dart_side_ptr.internal_state()->router_for_testing()->EnableTestingMode();

    cpp_side->set_dart_side(dart_side_ptr.get());

    DartControllerConfig config;
    char* error;
    bool unhandled_exception = false;
    InitializeDartConfig(
        &config,
        test,
        dart_side_request.PassMessagePipe().release().value(),
        nullptr,
        0,
        &unhandled_exception,
        &error);

    dart_thread->Start();
    dart_thread->message_loop()->PostTask(FROM_HERE,
        base::Bind(&RunDartSide, base::ConstRef(config)));

    run_loop_.Run();
    return unhandled_exception;
  }

  DISALLOW_COPY_AND_ASSIGN(DartToCppTest);
};

TEST_F(DartToCppTest, Ping) {
  PingCppSideConnection cpp_side_connection;
  bool unhandled_exception =
      RunTest("dart_to_cpp_tests.dart", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
  EXPECT_FALSE(unhandled_exception);
}

TEST_F(DartToCppTest, Echo) {
  EchoCppSideConnection cpp_side_connection;
  bool unhandled_exception =
      RunTest("dart_to_cpp_tests.dart", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
  EXPECT_FALSE(unhandled_exception);
}

}  // namespace dart
}  // namespace mojo

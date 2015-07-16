// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/strings/utf_string_conversions.h"
#include "gin/array_buffer.h"
#include "gin/public/isolate_holder.h"
#include "mojo/edk/js/mojo_runner_delegate.h"
#include "mojo/edk/js/tests/js_to_cpp.mojom.h"
#include "mojo/edk/test/test_utils.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/system/core.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace js {

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

js_to_cpp::EchoArgsPtr BuildSampleEchoArgs() {
  js_to_cpp::EchoArgsPtr args(js_to_cpp::EchoArgs::New());
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

void CheckSampleEchoArgs(const js_to_cpp::EchoArgs& arg) {
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

void CheckSampleEchoArgsList(const js_to_cpp::EchoArgsListPtr& list) {
  if (list.is_null())
    return;
  CheckSampleEchoArgs(*list->item);
  CheckSampleEchoArgsList(list->next);
}

// More forgiving checks are needed in the face of potentially corrupt
// messages. The values don't matter so long as all accesses are within
// bounds.
void CheckCorruptedString(const String& arg) {
  if (arg.is_null())
    return;
  for (size_t i = 0; i < arg.size(); ++i)
    g_waste_accumulator += arg[i];
}

void CheckCorruptedStringArray(const Array<String>& string_array) {
  if (string_array.is_null())
    return;
  for (size_t i = 0; i < string_array.size(); ++i)
    CheckCorruptedString(string_array[i]);
}

void CheckCorruptedDataPipe(MojoHandle data_pipe_handle) {
  unsigned char buffer[100];
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  MojoResult result = MojoReadData(
      data_pipe_handle, buffer, &buffer_size, MOJO_READ_DATA_FLAG_NONE);
  if (result != MOJO_RESULT_OK)
    return;
  for (uint32_t i = 0; i < buffer_size; ++i)
    g_waste_accumulator += buffer[i];
}

void CheckCorruptedMessagePipe(MojoHandle message_pipe_handle) {
  unsigned char buffer[100];
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  MojoResult result = MojoReadMessage(
      message_pipe_handle, buffer, &buffer_size, 0, 0, 0);
  if (result != MOJO_RESULT_OK)
    return;
  for (uint32_t i = 0; i < buffer_size; ++i)
    g_waste_accumulator += buffer[i];
}

void CheckCorruptedEchoArgs(const js_to_cpp::EchoArgsPtr& arg) {
  if (arg.is_null())
    return;
  CheckCorruptedString(arg->name);
  CheckCorruptedStringArray(arg->string_array);
  if (arg->data_handle.is_valid())
    CheckCorruptedDataPipe(arg->data_handle.get().value());
  if (arg->message_handle.is_valid())
    CheckCorruptedMessagePipe(arg->message_handle.get().value());
}

void CheckCorruptedEchoArgsList(const js_to_cpp::EchoArgsListPtr& list) {
  if (list.is_null())
    return;
  CheckCorruptedEchoArgs(list->item);
  CheckCorruptedEchoArgsList(list->next);
}

// Base Provider implementation class. It's expected that tests subclass and
// override the appropriate Provider functions. When test is done quit the
// run_loop().
class CppSideConnection : public js_to_cpp::CppSide {
 public:
  CppSideConnection()
      : run_loop_(nullptr),
        js_side_(nullptr),
        mishandled_messages_(0),
        binding_(this) {}
  ~CppSideConnection() override {}

  void set_run_loop(base::RunLoop* run_loop) { run_loop_ = run_loop; }
  base::RunLoop* run_loop() { return run_loop_; }

  void set_js_side(js_to_cpp::JsSide* js_side) { js_side_ = js_side; }
  js_to_cpp::JsSide* js_side() { return js_side_; }

  void Bind(InterfaceRequest<js_to_cpp::CppSide> request) {
    binding_.Bind(request.Pass());
    // Keep the pipe open even after validation errors.
    binding_.internal_router()->EnableTestingMode();
  }

  // js_to_cpp::CppSide:
  void StartTest() override { NOTREACHED(); }

  void TestFinished() override { NOTREACHED(); }

  void PingResponse() override { mishandled_messages_ += 1; }

  void EchoResponse(js_to_cpp::EchoArgsListPtr list) override {
    mishandled_messages_ += 1;
  }

  void BitFlipResponse(js_to_cpp::EchoArgsListPtr list) override {
    mishandled_messages_ += 1;
  }

  void BackPointerResponse(js_to_cpp::EchoArgsListPtr list) override {
    mishandled_messages_ += 1;
  }

 protected:
  base::RunLoop* run_loop_;
  js_to_cpp::JsSide* js_side_;
  int mishandled_messages_;
  mojo::Binding<js_to_cpp::CppSide> binding_;

 private:
  DISALLOW_COPY_AND_ASSIGN(CppSideConnection);
};

// Trivial test to verify a message sent from JS is received.
class PingCppSideConnection : public CppSideConnection {
 public:
  PingCppSideConnection() : got_message_(false) {}
  ~PingCppSideConnection() override {}

  // js_to_cpp::CppSide:
  void StartTest() override { js_side_->Ping(); }

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

  // js_to_cpp::CppSide:
  void StartTest() override {
    js_side_->Echo(kExpectedMessageCount, BuildSampleEchoArgs());
  }

  void EchoResponse(js_to_cpp::EchoArgsListPtr list) override {
    const js_to_cpp::EchoArgsPtr& special_arg = list->item;
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

// Test that corrupted messages don't wreak havoc.
class BitFlipCppSideConnection : public CppSideConnection {
 public:
  BitFlipCppSideConnection() : termination_seen_(false) {}
  ~BitFlipCppSideConnection() override {}

  // js_to_cpp::CppSide:
  void StartTest() override { js_side_->BitFlip(BuildSampleEchoArgs()); }

  void BitFlipResponse(js_to_cpp::EchoArgsListPtr list) override {
    CheckCorruptedEchoArgsList(list);
  }

  void TestFinished() override {
    termination_seen_ = true;
    run_loop()->Quit();
  }

  bool DidSucceed() {
    return termination_seen_;
  }

 private:
  bool termination_seen_;
  DISALLOW_COPY_AND_ASSIGN(BitFlipCppSideConnection);
};

// Test that severely random messages don't wreak havoc.
class BackPointerCppSideConnection : public CppSideConnection {
 public:
  BackPointerCppSideConnection() : termination_seen_(false) {}
  ~BackPointerCppSideConnection() override {}

  // js_to_cpp::CppSide:
  void StartTest() override { js_side_->BackPointer(BuildSampleEchoArgs()); }

  void BackPointerResponse(js_to_cpp::EchoArgsListPtr list) override {
    CheckCorruptedEchoArgsList(list);
  }

  void TestFinished() override {
    termination_seen_ = true;
    run_loop()->Quit();
  }

  bool DidSucceed() {
    return termination_seen_;
  }

 private:
  bool termination_seen_;
  DISALLOW_COPY_AND_ASSIGN(BackPointerCppSideConnection);
};

}  // namespace

class JsToCppTest : public testing::Test {
 public:
  JsToCppTest() {}

  void RunTest(const std::string& test, CppSideConnection* cpp_side) {
    cpp_side->set_run_loop(&run_loop_);

    js_to_cpp::JsSidePtr js_side;
    auto js_side_proxy = GetProxy(&js_side);

    cpp_side->set_js_side(js_side.get());
    js_to_cpp::CppSidePtr cpp_side_ptr;
    cpp_side->Bind(GetProxy(&cpp_side_ptr));

    js_side->SetCppSide(cpp_side_ptr.Pass());

    gin::IsolateHolder::Initialize(gin::IsolateHolder::kStrictMode,
                                   gin::ArrayBufferAllocator::SharedInstance());
    gin::IsolateHolder instance;
    MojoRunnerDelegate delegate;
    gin::ShellRunner runner(&delegate, instance.isolate());
    delegate.Start(&runner, js_side_proxy.PassMessagePipe().release().value(),
                   test);

    run_loop_.Run();
  }

 private:
  base::ShadowingAtExitManager at_exit_;
  base::MessageLoop loop;
  base::RunLoop run_loop_;

  DISALLOW_COPY_AND_ASSIGN(JsToCppTest);
};

TEST_F(JsToCppTest, Ping) {
  PingCppSideConnection cpp_side_connection;
  RunTest("mojo/edk/js/tests/js_to_cpp_tests", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
}

TEST_F(JsToCppTest, Echo) {
  EchoCppSideConnection cpp_side_connection;
  RunTest("mojo/edk/js/tests/js_to_cpp_tests", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
}

TEST_F(JsToCppTest, BitFlip) {
  BitFlipCppSideConnection cpp_side_connection;
  RunTest("mojo/edk/js/tests/js_to_cpp_tests", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
}

TEST_F(JsToCppTest, BackPointer) {
  BackPointerCppSideConnection cpp_side_connection;
  RunTest("mojo/edk/js/tests/js_to_cpp_tests", &cpp_side_connection);
  EXPECT_TRUE(cpp_side_connection.DidSucceed());
}

}  // namespace js
}  // namespace mojo

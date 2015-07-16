// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/public/interfaces/bindings/tests/math_calculator.mojom.h"
#include "mojo/public/interfaces/bindings/tests/sample_interfaces.mojom.h"
#include "mojo/public/interfaces/bindings/tests/sample_service.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

template <typename Method, typename Class>
class RunnableImpl {
 public:
  RunnableImpl(Method method, Class instance)
      : method_(method), instance_(instance) {}
  template <typename... Args>
  void Run(Args... args) const {
    (instance_->*method_)(args...);
  }

 private:
  Method method_;
  Class instance_;
};

template <typename Method, typename Class>
RunnableImpl<Method, Class> MakeRunnable(Method method, Class object) {
  return RunnableImpl<Method, Class>(method, object);
}

typedef mojo::Callback<void(double)> CalcCallback;

class MathCalculatorImpl : public math::Calculator {
 public:
  explicit MathCalculatorImpl(InterfaceRequest<math::Calculator> request)
      : total_(0.0), binding_(this, request.Pass()) {}
  ~MathCalculatorImpl() override {}

  void CloseMessagePipe() { binding_.Close(); }

  void WaitForIncomingMethodCall() { binding_.WaitForIncomingMethodCall(); }

  void Clear(const CalcCallback& callback) override {
    total_ = 0.0;
    callback.Run(total_);
  }

  void Add(double value, const CalcCallback& callback) override {
    total_ += value;
    callback.Run(total_);
  }

  void Multiply(double value, const CalcCallback& callback) override {
    total_ *= value;
    callback.Run(total_);
  }

 private:
  double total_;
  Binding<math::Calculator> binding_;
};

class MathCalculatorUI {
 public:
  explicit MathCalculatorUI(math::CalculatorPtr calculator)
      : calculator_(calculator.Pass()),
        output_(0.0),
        callback_(MakeRunnable(&MathCalculatorUI::Output, this)) {}

  bool WaitForIncomingResponse() {
    return calculator_.WaitForIncomingResponse();
  }

  bool encountered_error() const { return calculator_.encountered_error(); }

  void Add(double value) { calculator_->Add(value, callback_); }

  void Subtract(double value) { calculator_->Add(-value, callback_); }

  void Multiply(double value) { calculator_->Multiply(value, callback_); }

  void Divide(double value) { calculator_->Multiply(1.0 / value, callback_); }

  double GetOutput() const { return output_; }

 private:
  void Output(double output) { output_ = output; }

  math::CalculatorPtr calculator_;
  double output_;
  Callback<void(double)> callback_;
};

class SelfDestructingMathCalculatorUI {
 public:
  explicit SelfDestructingMathCalculatorUI(math::CalculatorPtr calculator)
      : calculator_(calculator.Pass()), nesting_level_(0) {
    ++num_instances_;
  }

  void BeginTest(bool nested) {
    nesting_level_ = nested ? 2 : 1;
    calculator_->Add(
        1.0, MakeRunnable(&SelfDestructingMathCalculatorUI::Output, this));
  }

  static int num_instances() { return num_instances_; }

  void Output(double value) {
    if (--nesting_level_ > 0) {
      // Add some more and wait for re-entrant call to Output!
      calculator_->Add(
          1.0, MakeRunnable(&SelfDestructingMathCalculatorUI::Output, this));
      RunLoop::current()->RunUntilIdle();
    } else {
      delete this;
    }
  }

 private:
  ~SelfDestructingMathCalculatorUI() { --num_instances_; }

  math::CalculatorPtr calculator_;
  int nesting_level_;
  static int num_instances_;
};

// static
int SelfDestructingMathCalculatorUI::num_instances_ = 0;

class ReentrantServiceImpl : public sample::Service {
 public:
  ~ReentrantServiceImpl() override {}

  explicit ReentrantServiceImpl(InterfaceRequest<sample::Service> request)
      : call_depth_(0), max_call_depth_(0), binding_(this, request.Pass()) {}

  int max_call_depth() { return max_call_depth_; }

  void Frobinate(sample::FooPtr foo,
                 sample::Service::BazOptions baz,
                 sample::PortPtr port,
                 const sample::Service::FrobinateCallback& callback) override {
    max_call_depth_ = std::max(++call_depth_, max_call_depth_);
    if (call_depth_ == 1) {
      EXPECT_TRUE(binding_.WaitForIncomingMethodCall());
    }
    call_depth_--;
    callback.Run(5);
  }

  void GetPort(mojo::InterfaceRequest<sample::Port> port) override {}

 private:
  int call_depth_;
  int max_call_depth_;
  Binding<sample::Service> binding_;
};

class IntegerAccessorImpl : public sample::IntegerAccessor {
 public:
  IntegerAccessorImpl() : integer_(0) {}
  ~IntegerAccessorImpl() override {}

  int64_t integer() const { return integer_; }

 private:
  // sample::IntegerAccessor implementation.
  void GetInteger(const GetIntegerCallback& callback) override {
    callback.Run(integer_, sample::ENUM_VALUE);
  }
  void SetInteger(int64_t data, sample::Enum type) override { integer_ = data; }

  int64_t integer_;
};

class InterfacePtrTest : public testing::Test {
 public:
  ~InterfacePtrTest() override { loop_.RunUntilIdle(); }

  void PumpMessages() { loop_.RunUntilIdle(); }

 private:
  Environment env_;
  RunLoop loop_;
};

TEST_F(InterfacePtrTest, IsBound) {
  math::CalculatorPtr calc;
  EXPECT_FALSE(calc.is_bound());
  MathCalculatorImpl calc_impl(GetProxy(&calc));
  EXPECT_TRUE(calc.is_bound());
}

TEST_F(InterfacePtrTest, EndToEnd) {
  math::CalculatorPtr calc;
  MathCalculatorImpl calc_impl(GetProxy(&calc));

  // Suppose this is instantiated in a process that has pipe1_.
  MathCalculatorUI calculator_ui(calc.Pass());

  calculator_ui.Add(2.0);
  calculator_ui.Multiply(5.0);

  PumpMessages();

  EXPECT_EQ(10.0, calculator_ui.GetOutput());
}

TEST_F(InterfacePtrTest, EndToEnd_Synchronous) {
  math::CalculatorPtr calc;
  MathCalculatorImpl calc_impl(GetProxy(&calc));

  // Suppose this is instantiated in a process that has pipe1_.
  MathCalculatorUI calculator_ui(calc.Pass());

  EXPECT_EQ(0.0, calculator_ui.GetOutput());

  calculator_ui.Add(2.0);
  EXPECT_EQ(0.0, calculator_ui.GetOutput());
  calc_impl.WaitForIncomingMethodCall();
  calculator_ui.WaitForIncomingResponse();
  EXPECT_EQ(2.0, calculator_ui.GetOutput());

  calculator_ui.Multiply(5.0);
  EXPECT_EQ(2.0, calculator_ui.GetOutput());
  calc_impl.WaitForIncomingMethodCall();
  calculator_ui.WaitForIncomingResponse();
  EXPECT_EQ(10.0, calculator_ui.GetOutput());
}

TEST_F(InterfacePtrTest, Movable) {
  math::CalculatorPtr a;
  math::CalculatorPtr b;
  MathCalculatorImpl calc_impl(GetProxy(&b));

  EXPECT_TRUE(!a);
  EXPECT_FALSE(!b);

  a = b.Pass();

  EXPECT_FALSE(!a);
  EXPECT_TRUE(!b);
}

TEST_F(InterfacePtrTest, Resettable) {
  math::CalculatorPtr a;

  EXPECT_TRUE(!a);

  MessagePipe pipe;

  // Save this so we can test it later.
  Handle handle = pipe.handle0.get();

  a = MakeProxy(InterfacePtrInfo<math::Calculator>(pipe.handle0.Pass(), 0u));

  EXPECT_FALSE(!a);

  a.reset();

  EXPECT_TRUE(!a);
  EXPECT_FALSE(a.internal_state()->router_for_testing());

  // Test that handle was closed.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, CloseRaw(handle));
}

TEST_F(InterfacePtrTest, BindInvalidHandle) {
  math::CalculatorPtr ptr;
  EXPECT_FALSE(ptr.get());
  EXPECT_FALSE(ptr);

  ptr.Bind(InterfacePtrInfo<math::Calculator>());
  EXPECT_FALSE(ptr.get());
  EXPECT_FALSE(ptr);
}

TEST_F(InterfacePtrTest, EncounteredError) {
  math::CalculatorPtr proxy;
  MathCalculatorImpl calc_impl(GetProxy(&proxy));

  MathCalculatorUI calculator_ui(proxy.Pass());

  calculator_ui.Add(2.0);
  PumpMessages();
  EXPECT_EQ(2.0, calculator_ui.GetOutput());
  EXPECT_FALSE(calculator_ui.encountered_error());

  calculator_ui.Multiply(5.0);
  EXPECT_FALSE(calculator_ui.encountered_error());

  // Close the server.
  calc_impl.CloseMessagePipe();

  // The state change isn't picked up locally yet.
  EXPECT_FALSE(calculator_ui.encountered_error());

  PumpMessages();

  // OK, now we see the error.
  EXPECT_TRUE(calculator_ui.encountered_error());
}

TEST_F(InterfacePtrTest, EncounteredErrorCallback) {
  math::CalculatorPtr proxy;
  MathCalculatorImpl calc_impl(GetProxy(&proxy));

  bool encountered_error = false;
  proxy.set_connection_error_handler(
      [&encountered_error]() { encountered_error = true; });

  MathCalculatorUI calculator_ui(proxy.Pass());

  calculator_ui.Add(2.0);
  PumpMessages();
  EXPECT_EQ(2.0, calculator_ui.GetOutput());
  EXPECT_FALSE(calculator_ui.encountered_error());

  calculator_ui.Multiply(5.0);
  EXPECT_FALSE(calculator_ui.encountered_error());

  // Close the server.
  calc_impl.CloseMessagePipe();

  // The state change isn't picked up locally yet.
  EXPECT_FALSE(calculator_ui.encountered_error());

  PumpMessages();

  // OK, now we see the error.
  EXPECT_TRUE(calculator_ui.encountered_error());

  // We should have also been able to observe the error through the error
  // handler.
  EXPECT_TRUE(encountered_error);
}

TEST_F(InterfacePtrTest, DestroyInterfacePtrOnMethodResponse) {
  math::CalculatorPtr proxy;
  MathCalculatorImpl calc_impl(GetProxy(&proxy));

  EXPECT_EQ(0, SelfDestructingMathCalculatorUI::num_instances());

  SelfDestructingMathCalculatorUI* impl =
      new SelfDestructingMathCalculatorUI(proxy.Pass());
  impl->BeginTest(false);

  PumpMessages();

  EXPECT_EQ(0, SelfDestructingMathCalculatorUI::num_instances());
}

TEST_F(InterfacePtrTest, NestedDestroyInterfacePtrOnMethodResponse) {
  math::CalculatorPtr proxy;
  MathCalculatorImpl calc_impl(GetProxy(&proxy));

  EXPECT_EQ(0, SelfDestructingMathCalculatorUI::num_instances());

  SelfDestructingMathCalculatorUI* impl =
      new SelfDestructingMathCalculatorUI(proxy.Pass());
  impl->BeginTest(true);

  PumpMessages();

  EXPECT_EQ(0, SelfDestructingMathCalculatorUI::num_instances());
}

TEST_F(InterfacePtrTest, ReentrantWaitForIncomingMethodCall) {
  sample::ServicePtr proxy;
  ReentrantServiceImpl impl(GetProxy(&proxy));

  proxy->Frobinate(nullptr, sample::Service::BAZ_OPTIONS_REGULAR, nullptr,
                   sample::Service::FrobinateCallback());
  proxy->Frobinate(nullptr, sample::Service::BAZ_OPTIONS_REGULAR, nullptr,
                   sample::Service::FrobinateCallback());

  PumpMessages();

  EXPECT_EQ(2, impl.max_call_depth());
}

TEST_F(InterfacePtrTest, QueryVersion) {
  IntegerAccessorImpl impl;
  sample::IntegerAccessorPtr ptr;
  Binding<sample::IntegerAccessor> binding(&impl, GetProxy(&ptr));

  EXPECT_EQ(0u, ptr.version());

  auto callback = [](uint32_t version) { EXPECT_EQ(3u, version); };
  ptr.QueryVersion(callback);

  PumpMessages();

  EXPECT_EQ(3u, ptr.version());
}

TEST_F(InterfacePtrTest, RequireVersion) {
  IntegerAccessorImpl impl;
  sample::IntegerAccessorPtr ptr;
  Binding<sample::IntegerAccessor> binding(&impl, GetProxy(&ptr));

  EXPECT_EQ(0u, ptr.version());

  ptr.RequireVersion(1u);
  EXPECT_EQ(1u, ptr.version());
  ptr->SetInteger(123, sample::ENUM_VALUE);
  PumpMessages();
  EXPECT_FALSE(ptr.encountered_error());
  EXPECT_EQ(123, impl.integer());

  ptr.RequireVersion(3u);
  EXPECT_EQ(3u, ptr.version());
  ptr->SetInteger(456, sample::ENUM_VALUE);
  PumpMessages();
  EXPECT_FALSE(ptr.encountered_error());
  EXPECT_EQ(456, impl.integer());

  // Require a version that is not supported by the impl side.
  ptr.RequireVersion(4u);
  // This value is set to the input of RequireVersion() synchronously.
  EXPECT_EQ(4u, ptr.version());
  ptr->SetInteger(789, sample::ENUM_VALUE);
  PumpMessages();
  EXPECT_TRUE(ptr.encountered_error());
  // The call to SetInteger() after RequireVersion(4u) is ignored.
  EXPECT_EQ(456, impl.integer());
}

class StrongMathCalculatorImpl : public math::Calculator {
 public:
  StrongMathCalculatorImpl(ScopedMessagePipeHandle handle,
                           bool* error_received,
                           bool* destroyed)
      : error_received_(error_received),
        destroyed_(destroyed),
        binding_(this, handle.Pass()) {
    binding_.set_connection_error_handler(
        [this]() { *error_received_ = true; });
  }
  ~StrongMathCalculatorImpl() override { *destroyed_ = true; }

  // math::Calculator implementation.
  void Clear(const CalcCallback& callback) override { callback.Run(total_); }

  void Add(double value, const CalcCallback& callback) override {
    total_ += value;
    callback.Run(total_);
  }

  void Multiply(double value, const CalcCallback& callback) override {
    total_ *= value;
    callback.Run(total_);
  }

 private:
  double total_ = 0.0;
  bool* error_received_;
  bool* destroyed_;

  StrongBinding<math::Calculator> binding_;
};

TEST(StrongConnectorTest, Math) {
  Environment env;
  RunLoop loop;

  bool error_received = false;
  bool destroyed = false;
  MessagePipe pipe;
  new StrongMathCalculatorImpl(pipe.handle0.Pass(), &error_received,
                               &destroyed);

  math::CalculatorPtr calc;
  calc.Bind(InterfacePtrInfo<math::Calculator>(pipe.handle1.Pass(), 0u));

  {
    // Suppose this is instantiated in a process that has the other end of the
    // message pipe.
    MathCalculatorUI calculator_ui(calc.Pass());

    calculator_ui.Add(2.0);
    calculator_ui.Multiply(5.0);

    loop.RunUntilIdle();

    EXPECT_EQ(10.0, calculator_ui.GetOutput());
    EXPECT_FALSE(error_received);
    EXPECT_FALSE(destroyed);
  }
  // Destroying calculator_ui should close the pipe and generate an error on the
  // other
  // end which will destroy the instance since it is strongly bound.

  loop.RunUntilIdle();
  EXPECT_TRUE(error_received);
  EXPECT_TRUE(destroyed);
}

class WeakMathCalculatorImpl : public math::Calculator {
 public:
  WeakMathCalculatorImpl(ScopedMessagePipeHandle handle,
                         bool* error_received,
                         bool* destroyed)
      : error_received_(error_received),
        destroyed_(destroyed),
        binding_(this, handle.Pass()) {
    binding_.set_connection_error_handler(
        [this]() { *error_received_ = true; });
  }
  ~WeakMathCalculatorImpl() override { *destroyed_ = true; }

  void Clear(const CalcCallback& callback) override { callback.Run(total_); }

  void Add(double value, const CalcCallback& callback) override {
    total_ += value;
    callback.Run(total_);
  }

  void Multiply(double value, const CalcCallback& callback) override {
    total_ *= value;
    callback.Run(total_);
  }

 private:
  double total_ = 0.0;
  bool* error_received_;
  bool* destroyed_;

  Binding<math::Calculator> binding_;
};

TEST(WeakConnectorTest, Math) {
  Environment env;
  RunLoop loop;

  bool error_received = false;
  bool destroyed = false;
  MessagePipe pipe;
  WeakMathCalculatorImpl impl(pipe.handle0.Pass(), &error_received, &destroyed);

  math::CalculatorPtr calc;
  calc.Bind(InterfacePtrInfo<math::Calculator>(pipe.handle1.Pass(), 0u));

  {
    // Suppose this is instantiated in a process that has the other end of the
    // message pipe.
    MathCalculatorUI calculator_ui(calc.Pass());

    calculator_ui.Add(2.0);
    calculator_ui.Multiply(5.0);

    loop.RunUntilIdle();

    EXPECT_EQ(10.0, calculator_ui.GetOutput());
    EXPECT_FALSE(error_received);
    EXPECT_FALSE(destroyed);
    // Destroying calculator_ui should close the pipe and generate an error on
    // the other
    // end which will destroy the instance since it is strongly bound.
  }

  loop.RunUntilIdle();
  EXPECT_TRUE(error_received);
  EXPECT_FALSE(destroyed);
}

}  // namespace
}  // namespace test
}  // namespace mojo

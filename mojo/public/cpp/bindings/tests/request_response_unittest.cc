// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/public/interfaces/bindings/tests/sample_import.mojom.h"
#include "mojo/public/interfaces/bindings/tests/sample_interfaces.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

class ProviderImpl : public sample::Provider {
 public:
  explicit ProviderImpl(InterfaceRequest<sample::Provider> request)
      : binding_(this, request.Pass()) {}

  void EchoString(const String& a,
                  const Callback<void(String)>& callback) override {
    Callback<void(String)> callback_copy;
    // Make sure operator= is used.
    callback_copy = callback;
    callback_copy.Run(a);
  }

  void EchoStrings(const String& a,
                   const String& b,
                   const Callback<void(String, String)>& callback) override {
    callback.Run(a, b);
  }

  void EchoMessagePipeHandle(
      ScopedMessagePipeHandle a,
      const Callback<void(ScopedMessagePipeHandle)>& callback) override {
    callback.Run(a.Pass());
  }

  void EchoEnum(sample::Enum a,
                const Callback<void(sample::Enum)>& callback) override {
    callback.Run(a);
  }

  void EchoInt(int32_t a, const EchoIntCallback& callback) override {
    callback.Run(a);
  }

  Binding<sample::Provider> binding_;
};

class StringRecorder {
 public:
  explicit StringRecorder(std::string* buf) : buf_(buf) {}
  void Run(const String& a) const { *buf_ = a; }
  void Run(const String& a, const String& b) const {
    *buf_ = a.get() + b.get();
  }

 private:
  std::string* buf_;
};

class EnumRecorder {
 public:
  explicit EnumRecorder(sample::Enum* value) : value_(value) {}
  void Run(sample::Enum a) const { *value_ = a; }

 private:
  sample::Enum* value_;
};

class MessagePipeWriter {
 public:
  explicit MessagePipeWriter(const char* text) : text_(text) {}
  void Run(ScopedMessagePipeHandle handle) const {
    WriteTextMessage(handle.get(), text_);
  }

 private:
  std::string text_;
};

class RequestResponseTest : public testing::Test {
 public:
  ~RequestResponseTest() override { loop_.RunUntilIdle(); }

  void PumpMessages() { loop_.RunUntilIdle(); }

 private:
  Environment env_;
  RunLoop loop_;
};

TEST_F(RequestResponseTest, EchoString) {
  sample::ProviderPtr provider;
  ProviderImpl provider_impl(GetProxy(&provider));

  std::string buf;
  provider->EchoString(String::From("hello"), StringRecorder(&buf));

  PumpMessages();

  EXPECT_EQ(std::string("hello"), buf);
}

TEST_F(RequestResponseTest, EchoStrings) {
  sample::ProviderPtr provider;
  ProviderImpl provider_impl(GetProxy(&provider));

  std::string buf;
  provider->EchoStrings(
      String::From("hello"), String::From(" world"), StringRecorder(&buf));

  PumpMessages();

  EXPECT_EQ(std::string("hello world"), buf);
}

TEST_F(RequestResponseTest, EchoMessagePipeHandle) {
  sample::ProviderPtr provider;
  ProviderImpl provider_impl(GetProxy(&provider));

  MessagePipe pipe2;
  provider->EchoMessagePipeHandle(pipe2.handle1.Pass(),
                                  MessagePipeWriter("hello"));

  PumpMessages();

  std::string value;
  ReadTextMessage(pipe2.handle0.get(), &value);

  EXPECT_EQ(std::string("hello"), value);
}

TEST_F(RequestResponseTest, EchoEnum) {
  sample::ProviderPtr provider;
  ProviderImpl provider_impl(GetProxy(&provider));

  sample::Enum value;
  provider->EchoEnum(sample::ENUM_VALUE, EnumRecorder(&value));

  PumpMessages();

  EXPECT_EQ(sample::ENUM_VALUE, value);
}

}  // namespace
}  // namespace test
}  // namespace mojo

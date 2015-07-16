// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/public/interfaces/bindings/tests/sample_factory.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

const char kText1[] = "hello";
const char kText2[] = "world";

class StringRecorder {
 public:
  explicit StringRecorder(std::string* buf) : buf_(buf) {}
  void Run(const String& a) const { *buf_ = a.To<std::string>(); }

 private:
  std::string* buf_;
};

class ImportedInterfaceImpl : public imported::ImportedInterface {
 public:
  explicit ImportedInterfaceImpl(
      InterfaceRequest<imported::ImportedInterface> request)
      : binding_(this, request.Pass()) {}

  void DoSomething() override { do_something_count_++; }

  static int do_something_count() { return do_something_count_; }

 private:
  static int do_something_count_;
  Binding<ImportedInterface> binding_;
};
int ImportedInterfaceImpl::do_something_count_ = 0;

class SampleNamedObjectImpl : public sample::NamedObject {
 public:
  explicit SampleNamedObjectImpl(InterfaceRequest<sample::NamedObject> request)
      : binding_(this, request.Pass()) {}
  void SetName(const mojo::String& name) override { name_ = name; }

  void GetName(const mojo::Callback<void(mojo::String)>& callback) override {
    callback.Run(name_);
  }

 private:
  std::string name_;
  StrongBinding<sample::NamedObject> binding_;
};

class SampleFactoryImpl : public sample::Factory {
 public:
  explicit SampleFactoryImpl(InterfaceRequest<sample::Factory> request)
      : binding_(this, request.Pass()) {}

  void DoStuff(sample::RequestPtr request,
               ScopedMessagePipeHandle pipe,
               const DoStuffCallback& callback) override {
    std::string text1;
    if (pipe.is_valid())
      EXPECT_TRUE(ReadTextMessage(pipe.get(), &text1));

    std::string text2;
    if (request->pipe.is_valid()) {
      EXPECT_TRUE(ReadTextMessage(request->pipe.get(), &text2));

      // Ensure that simply accessing request->pipe does not close it.
      EXPECT_TRUE(request->pipe.is_valid());
    }

    ScopedMessagePipeHandle pipe0;
    if (!text2.empty()) {
      CreateMessagePipe(nullptr, &pipe0, &pipe1_);
      EXPECT_TRUE(WriteTextMessage(pipe1_.get(), text2));
    }

    sample::ResponsePtr response(sample::Response::New());
    response->x = 2;
    response->pipe = pipe0.Pass();
    callback.Run(response.Pass(), text1);

    if (request->obj)
      request->obj->DoSomething();
  }

  void DoStuff2(ScopedDataPipeConsumerHandle pipe,
                const DoStuff2Callback& callback) override {
    // Read the data from the pipe, writing the response (as a string) to
    // DidStuff2().
    ASSERT_TRUE(pipe.is_valid());
    uint32_t data_size = 0;
    ASSERT_EQ(MOJO_RESULT_OK,
              ReadDataRaw(
                  pipe.get(), nullptr, &data_size, MOJO_READ_DATA_FLAG_QUERY));
    ASSERT_NE(0, static_cast<int>(data_size));
    char data[64];
    ASSERT_LT(static_cast<int>(data_size), 64);
    ASSERT_EQ(
        MOJO_RESULT_OK,
        ReadDataRaw(
            pipe.get(), data, &data_size, MOJO_READ_DATA_FLAG_ALL_OR_NONE));

    callback.Run(data);
  }

  void CreateNamedObject(
      InterfaceRequest<sample::NamedObject> object_request) override {
    EXPECT_TRUE(object_request.is_pending());
    new SampleNamedObjectImpl(object_request.Pass());
  }

  // These aren't called or implemented, but exist here to test that the
  // methods are generated with the correct argument types for imported
  // interfaces.
  void RequestImportedInterface(
      InterfaceRequest<imported::ImportedInterface> imported,
      const mojo::Callback<void(InterfaceRequest<imported::ImportedInterface>)>&
          callback) override {}
  void TakeImportedInterface(
      imported::ImportedInterfacePtr imported,
      const mojo::Callback<void(imported::ImportedInterfacePtr)>& callback)
      override {}

 private:
  ScopedMessagePipeHandle pipe1_;
  Binding<sample::Factory> binding_;
};

class HandlePassingTest : public testing::Test {
 public:
  void TearDown() override { PumpMessages(); }

  void PumpMessages() { loop_.RunUntilIdle(); }

 private:
  Environment env_;
  RunLoop loop_;
};

struct DoStuffCallback {
  DoStuffCallback(bool* got_response, std::string* got_text_reply)
      : got_response(got_response), got_text_reply(got_text_reply) {}

  void Run(sample::ResponsePtr response, const String& text_reply) const {
    *got_text_reply = text_reply;

    if (response->pipe.is_valid()) {
      std::string text2;
      EXPECT_TRUE(ReadTextMessage(response->pipe.get(), &text2));

      // Ensure that simply accessing response.pipe does not close it.
      EXPECT_TRUE(response->pipe.is_valid());

      EXPECT_EQ(std::string(kText2), text2);

      // Do some more tests of handle passing:
      ScopedMessagePipeHandle p = response->pipe.Pass();
      EXPECT_TRUE(p.is_valid());
      EXPECT_FALSE(response->pipe.is_valid());
    }

    *got_response = true;
  }

  bool* got_response;
  std::string* got_text_reply;
};

TEST_F(HandlePassingTest, Basic) {
  sample::FactoryPtr factory;
  SampleFactoryImpl factory_impl(GetProxy(&factory));

  MessagePipe pipe0;
  EXPECT_TRUE(WriteTextMessage(pipe0.handle1.get(), kText1));

  MessagePipe pipe1;
  EXPECT_TRUE(WriteTextMessage(pipe1.handle1.get(), kText2));

  imported::ImportedInterfacePtr imported;
  ImportedInterfaceImpl imported_impl(GetProxy(&imported));

  sample::RequestPtr request(sample::Request::New());
  request->x = 1;
  request->pipe = pipe1.handle0.Pass();
  request->obj = imported.Pass();
  bool got_response = false;
  std::string got_text_reply;
  DoStuffCallback cb(&got_response, &got_text_reply);
  factory->DoStuff(request.Pass(), pipe0.handle0.Pass(), cb);

  EXPECT_FALSE(*cb.got_response);
  int count_before = ImportedInterfaceImpl::do_something_count();

  PumpMessages();

  EXPECT_TRUE(*cb.got_response);
  EXPECT_EQ(kText1, *cb.got_text_reply);
  EXPECT_EQ(1, ImportedInterfaceImpl::do_something_count() - count_before);
}

TEST_F(HandlePassingTest, PassInvalid) {
  sample::FactoryPtr factory;
  SampleFactoryImpl factory_impl(GetProxy(&factory));

  sample::RequestPtr request(sample::Request::New());
  request->x = 1;
  bool got_response = false;
  std::string got_text_reply;
  DoStuffCallback cb(&got_response, &got_text_reply);
  factory->DoStuff(request.Pass(), ScopedMessagePipeHandle().Pass(), cb);

  EXPECT_FALSE(*cb.got_response);

  PumpMessages();

  EXPECT_TRUE(*cb.got_response);
}

struct DoStuff2Callback {
  DoStuff2Callback(bool* got_response, std::string* got_text_reply)
      : got_response(got_response), got_text_reply(got_text_reply) {}

  void Run(const String& text_reply) const {
    *got_response = true;
    *got_text_reply = text_reply;
  }

  bool* got_response;
  std::string* got_text_reply;
};

// Verifies DataPipeConsumer can be passed and read from.
TEST_F(HandlePassingTest, DataPipe) {
  sample::FactoryPtr factory;
  SampleFactoryImpl factory_impl(GetProxy(&factory));

  // Writes a string to a data pipe and passes the data pipe (consumer) to the
  // factory.
  ScopedDataPipeProducerHandle producer_handle;
  ScopedDataPipeConsumerHandle consumer_handle;
  MojoCreateDataPipeOptions options = {sizeof(MojoCreateDataPipeOptions),
                                       MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,
                                       1,
                                       1024};
  ASSERT_EQ(MOJO_RESULT_OK,
            CreateDataPipe(&options, &producer_handle, &consumer_handle));
  std::string expected_text_reply = "got it";
  // +1 for \0.
  uint32_t data_size = static_cast<uint32_t>(expected_text_reply.size() + 1);
  ASSERT_EQ(MOJO_RESULT_OK,
            WriteDataRaw(producer_handle.get(),
                         expected_text_reply.c_str(),
                         &data_size,
                         MOJO_WRITE_DATA_FLAG_ALL_OR_NONE));

  bool got_response = false;
  std::string got_text_reply;
  DoStuff2Callback cb(&got_response, &got_text_reply);
  factory->DoStuff2(consumer_handle.Pass(), cb);

  EXPECT_FALSE(*cb.got_response);

  PumpMessages();

  EXPECT_TRUE(*cb.got_response);
  EXPECT_EQ(expected_text_reply, *cb.got_text_reply);
}

TEST_F(HandlePassingTest, PipesAreClosed) {
  sample::FactoryPtr factory;
  SampleFactoryImpl factory_impl(GetProxy(&factory));

  MessagePipe extra_pipe;

  MojoHandle handle0_value = extra_pipe.handle0.get().value();
  MojoHandle handle1_value = extra_pipe.handle1.get().value();

  {
    Array<ScopedMessagePipeHandle> pipes(2);
    pipes[0] = extra_pipe.handle0.Pass();
    pipes[1] = extra_pipe.handle1.Pass();

    sample::RequestPtr request(sample::Request::New());
    request->more_pipes = pipes.Pass();

    factory->DoStuff(request.Pass(), ScopedMessagePipeHandle(),
                     sample::Factory::DoStuffCallback());
  }

  // We expect the pipes to have been closed.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, MojoClose(handle0_value));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, MojoClose(handle1_value));
}

TEST_F(HandlePassingTest, IsHandle) {
  // Validate that mojo::internal::IsHandle<> works as expected since this.
  // template is key to ensuring that we don't leak handles.
  EXPECT_TRUE(internal::IsHandle<Handle>::value);
  EXPECT_TRUE(internal::IsHandle<MessagePipeHandle>::value);
  EXPECT_TRUE(internal::IsHandle<DataPipeConsumerHandle>::value);
  EXPECT_TRUE(internal::IsHandle<DataPipeProducerHandle>::value);
  EXPECT_TRUE(internal::IsHandle<SharedBufferHandle>::value);

  // Basic sanity checks...
  EXPECT_FALSE(internal::IsHandle<int>::value);
  EXPECT_FALSE(internal::IsHandle<sample::FactoryPtr>::value);
  EXPECT_FALSE(internal::IsHandle<String>::value);
}

TEST_F(HandlePassingTest, CreateNamedObject) {
  sample::FactoryPtr factory;
  SampleFactoryImpl factory_impl(GetProxy(&factory));

  sample::NamedObjectPtr object1;
  EXPECT_FALSE(object1);

  InterfaceRequest<sample::NamedObject> object1_request = GetProxy(&object1);
  EXPECT_TRUE(object1_request.is_pending());
  factory->CreateNamedObject(object1_request.Pass());
  EXPECT_FALSE(object1_request.is_pending());  // We've passed the request.

  ASSERT_TRUE(object1);
  object1->SetName("object1");

  sample::NamedObjectPtr object2;
  factory->CreateNamedObject(GetProxy(&object2));
  object2->SetName("object2");

  std::string name1;
  object1->GetName(StringRecorder(&name1));

  std::string name2;
  object2->GetName(StringRecorder(&name2));

  PumpMessages();  // Yield for results.

  EXPECT_EQ(std::string("object1"), name1);
  EXPECT_EQ(std::string("object2"), name2);
}

}  // namespace
}  // namespace test
}  // namespace mojo

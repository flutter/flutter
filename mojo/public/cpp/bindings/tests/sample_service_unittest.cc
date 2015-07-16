// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <ostream>
#include <string>

#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/interfaces/bindings/tests/sample_service.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

template <>
struct TypeConverter<int32_t, sample::BarPtr> {
  static int32_t Convert(const sample::BarPtr& bar) {
    return static_cast<int32_t>(bar->alpha) << 16 |
           static_cast<int32_t>(bar->beta) << 8 |
           static_cast<int32_t>(bar->gamma);
  }
};

}  // namespace mojo

namespace sample {
namespace {

// Set this variable to true to print the message in hex.
bool g_dump_message_as_hex = false;

// Set this variable to true to print the message in human readable form.
bool g_dump_message_as_text = false;

// Make a sample |Foo|.
FooPtr MakeFoo() {
  mojo::String name("foopy");

  BarPtr bar(Bar::New());
  bar->alpha = 20;
  bar->beta = 40;
  bar->gamma = 60;
  bar->type = Bar::TYPE_VERTICAL;

  mojo::Array<BarPtr> extra_bars(3);
  for (size_t i = 0; i < extra_bars.size(); ++i) {
    Bar::Type type = i % 2 == 0 ? Bar::TYPE_VERTICAL : Bar::TYPE_HORIZONTAL;
    BarPtr bar(Bar::New());
    uint8_t base = static_cast<uint8_t>(i * 100);
    bar->alpha = base;
    bar->beta = base + 20;
    bar->gamma = base + 40;
    bar->type = type;
    extra_bars[i] = bar.Pass();
  }

  mojo::Array<uint8_t> data(10);
  for (size_t i = 0; i < data.size(); ++i)
    data[i] = static_cast<uint8_t>(data.size() - i);

  mojo::Array<mojo::ScopedDataPipeConsumerHandle> input_streams(2);
  mojo::Array<mojo::ScopedDataPipeProducerHandle> output_streams(2);
  for (size_t i = 0; i < input_streams.size(); ++i) {
    MojoCreateDataPipeOptions options;
    options.struct_size = sizeof(MojoCreateDataPipeOptions);
    options.flags = MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE;
    options.element_num_bytes = 1;
    options.capacity_num_bytes = 1024;
    mojo::ScopedDataPipeProducerHandle producer;
    mojo::ScopedDataPipeConsumerHandle consumer;
    mojo::CreateDataPipe(&options, &producer, &consumer);
    input_streams[i] = consumer.Pass();
    output_streams[i] = producer.Pass();
  }

  mojo::Array<mojo::Array<bool>> array_of_array_of_bools(2);
  for (size_t i = 0; i < 2; ++i) {
    mojo::Array<bool> array_of_bools(2);
    for (size_t j = 0; j < 2; ++j)
      array_of_bools[j] = j;
    array_of_array_of_bools[i] = array_of_bools.Pass();
  }

  mojo::MessagePipe pipe;
  FooPtr foo(Foo::New());
  foo->name = name;
  foo->x = 1;
  foo->y = 2;
  foo->a = false;
  foo->b = true;
  foo->c = false;
  foo->bar = bar.Pass();
  foo->extra_bars = extra_bars.Pass();
  foo->data = data.Pass();
  foo->source = pipe.handle1.Pass();
  foo->input_streams = input_streams.Pass();
  foo->output_streams = output_streams.Pass();
  foo->array_of_array_of_bools = array_of_array_of_bools.Pass();

  return foo.Pass();
}

// Check that the given |Foo| is identical to the one made by |MakeFoo()|.
void CheckFoo(const Foo& foo) {
  const std::string kName("foopy");
  ASSERT_FALSE(foo.name.is_null());
  EXPECT_EQ(kName.size(), foo.name.size());
  for (size_t i = 0; i < std::min(kName.size(), foo.name.size()); i++) {
    // Test both |operator[]| and |at|.
    EXPECT_EQ(kName[i], foo.name.at(i)) << i;
    EXPECT_EQ(kName[i], foo.name[i]) << i;
  }
  EXPECT_EQ(kName, foo.name.get());

  EXPECT_EQ(1, foo.x);
  EXPECT_EQ(2, foo.y);
  EXPECT_FALSE(foo.a);
  EXPECT_TRUE(foo.b);
  EXPECT_FALSE(foo.c);

  EXPECT_EQ(20, foo.bar->alpha);
  EXPECT_EQ(40, foo.bar->beta);
  EXPECT_EQ(60, foo.bar->gamma);
  EXPECT_EQ(Bar::TYPE_VERTICAL, foo.bar->type);

  EXPECT_EQ(3u, foo.extra_bars.size());
  for (size_t i = 0; i < foo.extra_bars.size(); i++) {
    uint8_t base = static_cast<uint8_t>(i * 100);
    Bar::Type type = i % 2 == 0 ? Bar::TYPE_VERTICAL : Bar::TYPE_HORIZONTAL;
    EXPECT_EQ(base, foo.extra_bars[i]->alpha) << i;
    EXPECT_EQ(base + 20, foo.extra_bars[i]->beta) << i;
    EXPECT_EQ(base + 40, foo.extra_bars[i]->gamma) << i;
    EXPECT_EQ(type, foo.extra_bars[i]->type) << i;
  }

  EXPECT_EQ(10u, foo.data.size());
  for (size_t i = 0; i < foo.data.size(); ++i) {
    EXPECT_EQ(static_cast<uint8_t>(foo.data.size() - i), foo.data[i]) << i;
  }

  EXPECT_FALSE(foo.input_streams.is_null());
  EXPECT_EQ(2u, foo.input_streams.size());

  EXPECT_FALSE(foo.output_streams.is_null());
  EXPECT_EQ(2u, foo.output_streams.size());

  EXPECT_EQ(2u, foo.array_of_array_of_bools.size());
  for (size_t i = 0; i < foo.array_of_array_of_bools.size(); ++i) {
    EXPECT_EQ(2u, foo.array_of_array_of_bools[i].size());
    for (size_t j = 0; j < foo.array_of_array_of_bools[i].size(); ++j) {
      EXPECT_EQ(bool(j), foo.array_of_array_of_bools[i][j]);
    }
  }
}

void PrintSpacer(int depth) {
  for (int i = 0; i < depth; ++i)
    std::cout << "   ";
}

void Print(int depth, const char* name, bool value) {
  PrintSpacer(depth);
  std::cout << name << ": " << (value ? "true" : "false") << std::endl;
}

void Print(int depth, const char* name, int32_t value) {
  PrintSpacer(depth);
  std::cout << name << ": " << value << std::endl;
}

void Print(int depth, const char* name, uint8_t value) {
  PrintSpacer(depth);
  std::cout << name << ": " << uint32_t(value) << std::endl;
}

template <typename H>
void Print(int depth,
           const char* name,
           const mojo::ScopedHandleBase<H>& value) {
  PrintSpacer(depth);
  std::cout << name << ": 0x" << std::hex << value.get().value() << std::endl;
}

void Print(int depth, const char* name, const mojo::String& str) {
  PrintSpacer(depth);
  std::cout << name << ": \"" << str.get() << "\"" << std::endl;
}

void Print(int depth, const char* name, const BarPtr& bar) {
  PrintSpacer(depth);
  std::cout << name << ":" << std::endl;
  if (!bar.is_null()) {
    ++depth;
    Print(depth, "alpha", bar->alpha);
    Print(depth, "beta", bar->beta);
    Print(depth, "gamma", bar->gamma);
    Print(depth, "packed", bar.To<int32_t>());
    --depth;
  }
}

template <typename T>
void Print(int depth, const char* name, const mojo::Array<T>& array) {
  PrintSpacer(depth);
  std::cout << name << ":" << std::endl;
  if (!array.is_null()) {
    ++depth;
    for (size_t i = 0; i < array.size(); ++i) {
      std::stringstream buf;
      buf << i;
      Print(depth, buf.str().data(), array.at(i));
    }
    --depth;
  }
}

void Print(int depth, const char* name, const FooPtr& foo) {
  PrintSpacer(depth);
  std::cout << name << ":" << std::endl;
  if (!foo.is_null()) {
    ++depth;
    Print(depth, "name", foo->name);
    Print(depth, "x", foo->x);
    Print(depth, "y", foo->y);
    Print(depth, "a", foo->a);
    Print(depth, "b", foo->b);
    Print(depth, "c", foo->c);
    Print(depth, "bar", foo->bar);
    Print(depth, "extra_bars", foo->extra_bars);
    Print(depth, "data", foo->data);
    Print(depth, "source", foo->source);
    Print(depth, "input_streams", foo->input_streams);
    Print(depth, "output_streams", foo->output_streams);
    Print(depth, "array_of_array_of_bools", foo->array_of_array_of_bools);
    --depth;
  }
}

void DumpHex(const uint8_t* bytes, uint32_t num_bytes) {
  for (uint32_t i = 0; i < num_bytes; ++i) {
    std::cout << std::setw(2) << std::setfill('0') << std::hex
              << uint32_t(bytes[i]);

    if (i % 16 == 15) {
      std::cout << std::endl;
      continue;
    }

    if (i % 2 == 1)
      std::cout << " ";
    if (i % 8 == 7)
      std::cout << " ";
  }
}

class ServiceImpl : public Service {
 public:
  void Frobinate(FooPtr foo,
                 BazOptions baz,
                 PortPtr port,
                 const Service::FrobinateCallback& callback) override {
    // Users code goes here to handle the incoming Frobinate message.

    // We mainly check that we're given the expected arguments.
    EXPECT_FALSE(foo.is_null());
    if (!foo.is_null())
      CheckFoo(*foo);
    EXPECT_EQ(BAZ_OPTIONS_EXTRA, baz);

    if (g_dump_message_as_text) {
      // Also dump the Foo structure and all of its members.
      std::cout << "Frobinate:" << std::endl;
      int depth = 1;
      Print(depth, "foo", foo);
      Print(depth, "baz", baz);
      Print(depth, "port", port.get());
    }
    callback.Run(5);
  }

  void GetPort(mojo::InterfaceRequest<Port> port_request) override {}
};

class ServiceProxyImpl : public ServiceProxy {
 public:
  explicit ServiceProxyImpl(mojo::MessageReceiverWithResponder* receiver)
      : ServiceProxy(receiver) {}
};

class SimpleMessageReceiver : public mojo::MessageReceiverWithResponder {
 public:
  bool Accept(mojo::Message* message) override {
    // Imagine some IPC happened here.

    if (g_dump_message_as_hex) {
      DumpHex(reinterpret_cast<const uint8_t*>(message->data()),
              message->data_num_bytes());
    }

    // In the receiving process, an implementation of ServiceStub is known to
    // the system. It receives the incoming message.
    ServiceImpl impl;

    ServiceStub stub;
    stub.set_sink(&impl);
    return stub.Accept(message);
  }

  bool AcceptWithResponder(mojo::Message* message,
                           mojo::MessageReceiver* responder) override {
    return false;
  }
};

class BindingsSampleTest : public testing::Test {
 public:
  BindingsSampleTest() {}
  ~BindingsSampleTest() override {}

 private:
  mojo::Environment env_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(BindingsSampleTest);
};

TEST_F(BindingsSampleTest, Basic) {
  SimpleMessageReceiver receiver;

  // User has a proxy to a Service somehow.
  Service* service = new ServiceProxyImpl(&receiver);

  // User constructs a message to send.

  // Notice that it doesn't matter in what order the structs / arrays are
  // allocated. Here, the various members of Foo are allocated before Foo is
  // allocated.

  FooPtr foo = MakeFoo();
  CheckFoo(*foo);

  PortPtr port;
  service->Frobinate(foo.Pass(), Service::BAZ_OPTIONS_EXTRA, port.Pass(),
                     Service::FrobinateCallback());

  delete service;
}

TEST_F(BindingsSampleTest, DefaultValues) {
  DefaultsTestPtr defaults(DefaultsTest::New());
  EXPECT_EQ(-12, defaults->a0);
  EXPECT_EQ(kTwelve, defaults->a1);
  EXPECT_EQ(1234, defaults->a2);
  EXPECT_EQ(34567U, defaults->a3);
  EXPECT_EQ(123456, defaults->a4);
  EXPECT_EQ(3456789012U, defaults->a5);
  EXPECT_EQ(-111111111111LL, defaults->a6);
  EXPECT_EQ(9999999999999999999ULL, defaults->a7);
  EXPECT_EQ(0x12345, defaults->a8);
  EXPECT_EQ(-0x12345, defaults->a9);
  EXPECT_EQ(1234, defaults->a10);
  EXPECT_TRUE(defaults->a11);
  EXPECT_FALSE(defaults->a12);
  EXPECT_FLOAT_EQ(123.25f, defaults->a13);
  EXPECT_DOUBLE_EQ(1234567890.123, defaults->a14);
  EXPECT_DOUBLE_EQ(1E10, defaults->a15);
  EXPECT_DOUBLE_EQ(-1.2E+20, defaults->a16);
  EXPECT_DOUBLE_EQ(1.23E-20, defaults->a17);
  EXPECT_TRUE(defaults->a18.is_null());
  EXPECT_TRUE(defaults->a19.is_null());
  EXPECT_EQ(Bar::TYPE_BOTH, defaults->a20);
  EXPECT_TRUE(defaults->a21.is_null());
  ASSERT_FALSE(defaults->a22.is_null());
  EXPECT_EQ(imported::SHAPE_RECTANGLE, defaults->a22->shape);
  EXPECT_EQ(imported::COLOR_BLACK, defaults->a22->color);
  EXPECT_EQ(0xFFFFFFFFFFFFFFFFULL, defaults->a23);
  EXPECT_EQ(0x123456789, defaults->a24);
  EXPECT_EQ(-0x123456789, defaults->a25);
}

}  // namespace
}  // namespace sample

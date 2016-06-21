// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains tests that are shared between different implementations of
// |DataPipeImpl|.

#include "mojo/edk/system/data_pipe_impl.h"

#include <stdint.h>

#include <memory>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"
#include "mojo/edk/system/data_pipe_producer_dispatcher.h"
#include "mojo/edk/system/handle_transport.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::PlatformPipe;
using mojo::platform::ThreadSleep;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

const uint32_t kSizeOfOptions =
    static_cast<uint32_t>(sizeof(MojoCreateDataPipeOptions));

// In various places, we have to poll (since, e.g., we can't yet wait for a
// certain amount of data to be available). This is the maximum number of
// iterations (separated by a short sleep).
// TODO(vtl): Get rid of this.
const size_t kMaxPoll = 100;

// DataPipeImplTestHelper ------------------------------------------------------

class DataPipeImplTestHelper {
 public:
  virtual ~DataPipeImplTestHelper() {}

  virtual void SetUp() = 0;
  virtual void TearDown() = 0;

  virtual void Create(const MojoCreateDataPipeOptions& validated_options) = 0;

  // Returns true if the producer and consumer exhibit the behavior that you'd
  // expect from a pure circular buffer implementation (reflected to two-phase
  // reads and writes).
  virtual bool IsStrictCircularBuffer() const = 0;

  // Possibly transfers the producer/consumer.
  virtual void DoTransfer() = 0;

  // Returns the |DataPipe| object for the producer and consumer, respectively.
  virtual DataPipe* DataPipeForProducer() = 0;
  virtual DataPipe* DataPipeForConsumer() = 0;

  // Closes the producer and consumer, respectively. (Other operations go
  // through the above accessors; closing is special since it may require that a
  // dispatcher be closed.)
  virtual void ProducerClose() = 0;
  virtual void ConsumerClose() = 0;

 protected:
  DataPipeImplTestHelper() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(DataPipeImplTestHelper);
};

// DataPipeImplTest ------------------------------------------------------------

template <class Helper>
class DataPipeImplTest : public testing::Test {
 public:
  DataPipeImplTest() {}
  ~DataPipeImplTest() override {}

  void SetUp() override { Reset(); }
  void TearDown() override { helper_->TearDown(); }

 protected:
  void Create(const MojoCreateDataPipeOptions& options) {
    MojoCreateDataPipeOptions validated_options = {};
    ASSERT_EQ(MOJO_RESULT_OK,
              DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                              &validated_options));
    helper_->Create(validated_options);
  }

  bool IsStrictCircularBuffer() const {
    return helper_->IsStrictCircularBuffer();
  }

  void DoTransfer() { return helper_->DoTransfer(); }

  void Reset() {
    if (helper_)
      helper_->TearDown();

    helper_.reset(new Helper());
    helper_->SetUp();
  }

  void ProducerClose() { helper_->ProducerClose(); }
  MojoResult ProducerSetOptions(uint32_t write_threshold_num_bytes) {
    return dpp()->ProducerSetOptions(write_threshold_num_bytes);
  }
  void ProducerGetOptions(uint32_t* write_threshold_num_bytes) {
    dpp()->ProducerGetOptions(write_threshold_num_bytes);
  }
  MojoResult ProducerWriteData(UserPointer<const void> elements,
                               UserPointer<uint32_t> num_bytes,
                               bool all_or_none) {
    return dpp()->ProducerWriteData(elements, num_bytes, all_or_none);
  }
  MojoResult ProducerBeginWriteData(UserPointer<void*> buffer,
                                    UserPointer<uint32_t> buffer_num_bytes) {
    return dpp()->ProducerBeginWriteData(buffer, buffer_num_bytes);
  }
  MojoResult ProducerEndWriteData(uint32_t num_bytes_written) {
    return dpp()->ProducerEndWriteData(num_bytes_written);
  }
  MojoResult ProducerAddAwakable(Awakable* awakable,
                                 MojoHandleSignals signals,
                                 bool force,
                                 uint64_t context,
                                 HandleSignalsState* signals_state) {
    return dpp()->ProducerAddAwakable(awakable, signals, force, context,
                                      signals_state);
  }
  void ProducerRemoveAwakable(Awakable* awakable,
                              HandleSignalsState* signals_state) {
    return dpp()->ProducerRemoveAwakable(awakable, signals_state);
  }

  void ConsumerClose() { helper_->ConsumerClose(); }
  MojoResult ConsumerSetOptions(uint32_t read_threshold_num_bytes) {
    return dpc()->ConsumerSetOptions(read_threshold_num_bytes);
  }
  void ConsumerGetOptions(uint32_t* read_threshold_num_bytes) {
    dpc()->ConsumerGetOptions(read_threshold_num_bytes);
  }
  MojoResult ConsumerReadData(UserPointer<void> elements,
                              UserPointer<uint32_t> num_bytes,
                              bool all_or_none,
                              bool peek) {
    return dpc()->ConsumerReadData(elements, num_bytes, all_or_none, peek);
  }
  MojoResult ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                 bool all_or_none) {
    return dpc()->ConsumerDiscardData(num_bytes, all_or_none);
  }
  MojoResult ConsumerQueryData(UserPointer<uint32_t> num_bytes) {
    return dpc()->ConsumerQueryData(num_bytes);
  }
  MojoResult ConsumerBeginReadData(UserPointer<const void*> buffer,
                                   UserPointer<uint32_t> buffer_num_bytes) {
    return dpc()->ConsumerBeginReadData(buffer, buffer_num_bytes);
  }
  MojoResult ConsumerEndReadData(uint32_t num_bytes_read) {
    return dpc()->ConsumerEndReadData(num_bytes_read);
  }
  MojoResult ConsumerAddAwakable(Awakable* awakable,
                                 MojoHandleSignals signals,
                                 bool force,
                                 uint64_t context,
                                 HandleSignalsState* signals_state) {
    return dpc()->ConsumerAddAwakable(awakable, signals, force, context,
                                      signals_state);
  }
  void ConsumerRemoveAwakable(Awakable* awakable,
                              HandleSignalsState* signals_state) {
    return dpc()->ConsumerRemoveAwakable(awakable, signals_state);
  }

 private:
  DataPipe* dpp() { return helper_->DataPipeForProducer(); }
  DataPipe* dpc() { return helper_->DataPipeForConsumer(); }

  std::unique_ptr<Helper> helper_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(DataPipeImplTest);
};

// LocalDataPipeImplTestHelper -------------------------------------------------

class LocalDataPipeImplTestHelper : public DataPipeImplTestHelper {
 public:
  LocalDataPipeImplTestHelper() {}
  ~LocalDataPipeImplTestHelper() override {}

  void SetUp() override {}
  void TearDown() override {}

  void Create(const MojoCreateDataPipeOptions& validated_options) override {
    CHECK(!dp_);
    dp_ = DataPipe::CreateLocal(validated_options);
  }

  bool IsStrictCircularBuffer() const override { return true; }

  void DoTransfer() override {}

  // Returns the |DataPipe| object for the producer and consumer, respectively.
  DataPipe* DataPipeForProducer() override { return dp_.get(); }
  DataPipe* DataPipeForConsumer() override { return dp_.get(); }

  void ProducerClose() override { dp_->ProducerClose(); }
  void ConsumerClose() override { dp_->ConsumerClose(); }

 private:
  RefPtr<DataPipe> dp_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LocalDataPipeImplTestHelper);
};

// RemoteDataPipeImplTestHelper ------------------------------------------------

// Base class for |Remote{Producer,Consumer}DataPipeImplTestHelper|.
class RemoteDataPipeImplTestHelper : public DataPipeImplTestHelper {
 public:
  RemoteDataPipeImplTestHelper()
      : platform_support_(embedder::CreateSimplePlatformSupport()),
        io_thread_(test::TestIOThread::StartMode::AUTO) {}
  ~RemoteDataPipeImplTestHelper() override {}

  void SetUp() override {
    RefPtr<ChannelEndpoint> ep[2];
    message_pipes_[0] = MessagePipe::CreateLocalProxy(&ep[0]);
    message_pipes_[1] = MessagePipe::CreateLocalProxy(&ep[1]);

    io_thread_.PostTaskAndWait([this, &ep]() mutable {
      SetUpOnIOThread(std::move(ep[0]), std::move(ep[1]));
    });
  }

  void TearDown() override {
    EnsureMessagePipeClosed(0);
    EnsureMessagePipeClosed(1);
    io_thread_.PostTaskAndWait([this]() { TearDownOnIOThread(); });
  }

  void Create(const MojoCreateDataPipeOptions& validated_options) override {
    CHECK(!dp_);
    dp_ = DataPipe::CreateLocal(validated_options);
  }

  bool IsStrictCircularBuffer() const override { return false; }

 protected:
  // Note: This has an out parameter instead of just returning a |Handle|, since
  // return values don't play well with |ASSERT_...()|.
  void SendHandle(size_t source_i,
                  const Handle& handle_to_send,
                  Handle* handle_to_receive) {
    DCHECK(source_i == 0 || source_i == 1);
    size_t dest_i = source_i ^ 1;

    // Write the dispatcher to MP |source_i| (port 0). Wait and receive on MP
    // |dest_i| (port 0). (Add the waiter first, to avoid any handling the case
    // where it's already readable.)
    Waiter waiter;
    waiter.Init();
    ASSERT_EQ(MOJO_RESULT_OK, message_pipe(dest_i)->AddAwakable(
                                  0, &waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                  false, 987, nullptr));
    {
      HandleTransport transport(test::HandleTryStartTransport(handle_to_send));
      ASSERT_TRUE(transport.is_valid());

      std::vector<HandleTransport> transports;
      transports.push_back(transport);
      ASSERT_EQ(MOJO_RESULT_OK, message_pipe(source_i)->WriteMessage(
                                    0, NullUserPointer(), 0, &transports,
                                    MOJO_WRITE_MESSAGE_FLAG_NONE));
      transport.End();
    }
    uint64_t context = 0;
    ASSERT_EQ(MOJO_RESULT_OK, waiter.Wait(test::ActionTimeout(), &context));
    EXPECT_EQ(987u, context);
    HandleSignalsState hss = HandleSignalsState();
    message_pipe(dest_i)->RemoveAwakable(0, &waiter, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);
    char read_buffer[100] = {};
    uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
    HandleVector read_handles;
    uint32_t read_num_handles = 10;  // Maximum to get.
    ASSERT_EQ(MOJO_RESULT_OK,
              message_pipe(dest_i)->ReadMessage(
                  0, UserPointer<void>(read_buffer),
                  MakeUserPointer(&read_buffer_size), &read_handles,
                  &read_num_handles, MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, static_cast<size_t>(read_buffer_size));
    ASSERT_EQ(1u, read_handles.size());
    ASSERT_EQ(1u, read_num_handles);
    ASSERT_TRUE(read_handles[0]);
    EXPECT_TRUE(read_handles[0].dispatcher->HasOneRef());
    EXPECT_EQ(handle_to_send.rights, read_handles[0].rights);

    *handle_to_receive = std::move(read_handles[0]);
  }

  RefPtr<MessagePipe> message_pipe(size_t i) { return message_pipes_[i]; }
  RefPtr<DataPipe> dp() { return dp_; }

 private:
  void EnsureMessagePipeClosed(size_t i) {
    if (!message_pipes_[i])
      return;
    message_pipes_[i]->Close(0);
    message_pipes_[i] = nullptr;
  }

  void SetUpOnIOThread(RefPtr<ChannelEndpoint>&& ep0,
                       RefPtr<ChannelEndpoint>&& ep1) {
    CHECK(io_thread_.IsCurrentAndRunning());

    PlatformPipe channel_pair;
    channels_[0] = MakeRefCounted<Channel>(platform_support_.get());
    channels_[0]->Init(io_thread_.task_runner().Clone(),
                       io_thread_.platform_handle_watcher(),
                       RawChannel::Create(channel_pair.handle0.Pass()));
    channels_[0]->SetBootstrapEndpoint(std::move(ep0));
    channels_[1] = MakeRefCounted<Channel>(platform_support_.get());
    channels_[1]->Init(io_thread_.task_runner().Clone(),
                       io_thread_.platform_handle_watcher(),
                       RawChannel::Create(channel_pair.handle1.Pass()));
    channels_[1]->SetBootstrapEndpoint(std::move(ep1));
  }

  void TearDownOnIOThread() {
    CHECK(io_thread_.IsCurrentAndRunning());

    if (channels_[0]) {
      channels_[0]->Shutdown();
      channels_[0] = nullptr;
    }
    if (channels_[1]) {
      channels_[1]->Shutdown();
      channels_[1] = nullptr;
    }
  }

  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  test::TestIOThread io_thread_;
  RefPtr<Channel> channels_[2];
  RefPtr<MessagePipe> message_pipes_[2];

  RefPtr<DataPipe> dp_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteDataPipeImplTestHelper);
};

// RemoteProducerDataPipeImplTestHelper ----------------------------------------

// Note about naming confusion: This class is named after the "local" class,
// i.e., |dp_| will have a |RemoteProducerDataPipeImpl|. The remote side, of
// course, will have a |RemoteConsumerDataPipeImpl|.
class RemoteProducerDataPipeImplTestHelper
    : public RemoteDataPipeImplTestHelper {
 public:
  RemoteProducerDataPipeImplTestHelper() {}
  ~RemoteProducerDataPipeImplTestHelper() override {}

  void DoTransfer() override {
    // This is the producer dispatcher we'll send.
    auto to_send = DataPipeProducerDispatcher::Create();
    to_send->Init(dp());
    Handle handle_to_send(std::move(to_send),
                          DataPipeProducerDispatcher::kDefaultHandleRights);
    Handle handle_to_receive;
    SendHandle(0, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();

    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_PRODUCER,
              handle_to_receive.dispatcher->GetType());
    producer_dispatcher_ = RefPtr<DataPipeProducerDispatcher>(
        static_cast<DataPipeProducerDispatcher*>(
            handle_to_receive.dispatcher.get()));
  }

  DataPipe* DataPipeForProducer() override {
    if (producer_dispatcher_)
      return producer_dispatcher_->GetDataPipeForTest();
    return dp().get();
  }
  DataPipe* DataPipeForConsumer() override { return dp().get(); }

  void ProducerClose() override {
    if (producer_dispatcher_)
      ASSERT_EQ(MOJO_RESULT_OK, producer_dispatcher_->Close());
    else
      dp()->ProducerClose();
  }
  void ConsumerClose() override { dp()->ConsumerClose(); }

 protected:
  RefPtr<DataPipeProducerDispatcher> producer_dispatcher_;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteProducerDataPipeImplTestHelper);
};

// RemoteConsumerDataPipeImplTestHelper ----------------------------------------

// Note about naming confusion: This class is named after the "local" class,
// i.e., |dp_| will have a |RemoteConsumerDataPipeImpl|. The remote side, of
// course, will have a |RemoteProducerDataPipeImpl|.
class RemoteConsumerDataPipeImplTestHelper
    : public RemoteDataPipeImplTestHelper {
 public:
  RemoteConsumerDataPipeImplTestHelper() {}
  ~RemoteConsumerDataPipeImplTestHelper() override {}

  void DoTransfer() override {
    // This is the consumer dispatcher we'll send.
    auto to_send = DataPipeConsumerDispatcher::Create();
    to_send->Init(dp());
    Handle handle_to_send(std::move(to_send),
                          DataPipeConsumerDispatcher::kDefaultHandleRights);
    Handle handle_to_receive;
    SendHandle(0, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();

    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_CONSUMER,
              handle_to_receive.dispatcher->GetType());
    consumer_dispatcher_ = RefPtr<DataPipeConsumerDispatcher>(
        static_cast<DataPipeConsumerDispatcher*>(
            handle_to_receive.dispatcher.get()));
  }

  DataPipe* DataPipeForProducer() override { return dp().get(); }
  DataPipe* DataPipeForConsumer() override {
    if (consumer_dispatcher_)
      return consumer_dispatcher_->GetDataPipeForTest();
    return dp().get();
  }

  void ProducerClose() override { dp()->ProducerClose(); }
  void ConsumerClose() override {
    if (consumer_dispatcher_)
      ASSERT_EQ(MOJO_RESULT_OK, consumer_dispatcher_->Close());
    else
      dp()->ConsumerClose();
  }

 protected:
  RefPtr<DataPipeConsumerDispatcher> consumer_dispatcher_;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteConsumerDataPipeImplTestHelper);
};

// RemoteProducerDataPipeImplTestHelper2 ---------------------------------------

// This is like |RemoteProducerDataPipeImplTestHelper|, but |DoTransfer()| does
// a second transfer. This thus tests passing a producer handle twice, and in
// particular tests (some of) |RemoteConsumerDataPipeImpl|'s
// |ProducerEndSerialize()| (instead of |LocalDataPipeImpl|'s).
//
// Note about naming confusion: This class is named after the "local" class,
// i.e., |dp_| will have a |RemoteProducerDataPipeImpl|. The remote side, of
// course, will have a |RemoteConsumerDataPipeImpl|.
class RemoteProducerDataPipeImplTestHelper2
    : public RemoteProducerDataPipeImplTestHelper {
 public:
  RemoteProducerDataPipeImplTestHelper2() {}
  ~RemoteProducerDataPipeImplTestHelper2() override {}

  void DoTransfer() override {
    // This is the producer dispatcher we'll send.
    auto to_send = DataPipeProducerDispatcher::Create();
    to_send->Init(dp());
    Handle handle_to_send(std::move(to_send),
                          DataPipeProducerDispatcher::kDefaultHandleRights);
    Handle handle_to_receive;
    SendHandle(0, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();
    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_PRODUCER,
              handle_to_receive.dispatcher->GetType());
    handle_to_send = std::move(handle_to_receive);

    // Now send it back the other way.
    SendHandle(1, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();

    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_PRODUCER,
              handle_to_receive.dispatcher->GetType());
    producer_dispatcher_ = RefPtr<DataPipeProducerDispatcher>(
        static_cast<DataPipeProducerDispatcher*>(
            handle_to_receive.dispatcher.get()));
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteProducerDataPipeImplTestHelper2);
};

// RemoteConsumerDataPipeImplTestHelper2 ---------------------------------------

// This is like |RemoteConsumerDataPipeImplTestHelper|, but |DoTransfer()| does
// a second transfer. This thus tests passing a consumer handle twice, and in
// particular tests (some of) |RemoteProducerDataPipeImpl|'s
// |ConsumerEndSerialize()| (instead of |LocalDataPipeImpl|'s).
//
// Note about naming confusion: This class is named after the "local" class,
// i.e., |dp_| will have a |RemoteConsumerDataPipeImpl|. The remote side, of
// course, will have a |RemoteProducerDataPipeImpl|.
class RemoteConsumerDataPipeImplTestHelper2
    : public RemoteConsumerDataPipeImplTestHelper {
 public:
  RemoteConsumerDataPipeImplTestHelper2() {}
  ~RemoteConsumerDataPipeImplTestHelper2() override {}

  void DoTransfer() override {
    // This is the consumer dispatcher we'll send.
    auto to_send = DataPipeConsumerDispatcher::Create();
    to_send->Init(dp());
    Handle handle_to_send(std::move(to_send),
                          DataPipeConsumerDispatcher::kDefaultHandleRights);
    Handle handle_to_receive;
    SendHandle(0, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();
    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_CONSUMER,
              handle_to_receive.dispatcher->GetType());
    handle_to_send = std::move(handle_to_receive);

    // Now send it back the other way.
    SendHandle(1, handle_to_send, &handle_to_receive);
    // |handle_to_send.dispatcher| should have been closed. This is |DCHECK()|ed
    // when it is destroyed.
    EXPECT_TRUE(handle_to_send.dispatcher->HasOneRef());
    handle_to_send.reset();

    ASSERT_EQ(Dispatcher::Type::DATA_PIPE_CONSUMER,
              handle_to_receive.dispatcher->GetType());
    consumer_dispatcher_ = RefPtr<DataPipeConsumerDispatcher>(
        static_cast<DataPipeConsumerDispatcher*>(
            handle_to_receive.dispatcher.get()));
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteConsumerDataPipeImplTestHelper2);
};

// Test case instantiation -----------------------------------------------------

using HelperTypes = testing::Types<LocalDataPipeImplTestHelper,
                                   RemoteProducerDataPipeImplTestHelper,
                                   RemoteConsumerDataPipeImplTestHelper,
                                   RemoteProducerDataPipeImplTestHelper2,
                                   RemoteConsumerDataPipeImplTestHelper2>;

TYPED_TEST_CASE(DataPipeImplTest, HelperTypes);

// Tests -----------------------------------------------------------------------

// Tests creation (and possibly also transferring) of data pipes with various
// (valid) options.
TYPED_TEST(DataPipeImplTest, CreateAndMaybeTransfer) {
  MojoCreateDataPipeOptions test_options[] = {
      // Default options -- we'll initialize this below.
      {},
      // Trivial element size, non-default capacity.
      {kSizeOfOptions,                           // |struct_size|.
       MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
       1,                                        // |element_num_bytes|.
       1000},                                    // |capacity_num_bytes|.
      // Nontrivial element size, non-default capacity.
      {kSizeOfOptions,                           // |struct_size|.
       MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
       4,                                        // |element_num_bytes|.
       4000},                                    // |capacity_num_bytes|.
      // Nontrivial element size, default capacity.
      {kSizeOfOptions,                           // |struct_size|.
       MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
       100,                                      // |element_num_bytes|.
       0}                                        // |capacity_num_bytes|.
  };

  // Initialize the first element of |test_options| to the default options.
  EXPECT_EQ(MOJO_RESULT_OK, DataPipe::ValidateCreateOptions(NullUserPointer(),
                                                            &test_options[0]));

  for (size_t i = 0; i < MOJO_ARRAYSIZE(test_options); i++) {
    this->Create(test_options[i]);
    this->DoTransfer();
    this->ProducerClose();
    this->ConsumerClose();
    this->Reset();
  }
}

TYPED_TEST(DataPipeImplTest, SimpleReadWrite) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      1000 * sizeof(int32_t)                    // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;
  uint64_t context;

  int32_t elements[10] = {};
  uint32_t num_bytes = 0u;

  // Try reading; nothing there yet.
  num_bytes =
      static_cast<uint32_t>(MOJO_ARRAYSIZE(elements) * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), false, false));

  // Query; nothing there yet.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Discard; nothing there yet.
  num_bytes = static_cast<uint32_t>(5u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), false));

  // Read with invalid |num_bytes|.
  num_bytes = sizeof(elements[0]) + 1;
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), false, false));

  // For remote data pipes, we'll have to wait; add the waiter before writing.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 123, nullptr));

  // Write two elements.
  elements[0] = 123;
  elements[1] = 456;
  num_bytes = static_cast<uint32_t>(2u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(elements),
                                    MakeUserPointer(&num_bytes), false));
  // It should have written everything (even without "all or none").
  EXPECT_EQ(2u * sizeof(elements[0]), num_bytes);

  // Wait.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::ActionTimeout(), &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Query.
  // TODO(vtl): It's theoretically possible (though not with the current
  // implementation/configured limits) that not all the data has arrived yet.
  // (The theoretically-correct assertion here is that |num_bytes| is |1 * ...|
  // or |2 * ...|.)
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(2 * sizeof(elements[0]), num_bytes);

  // Read one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(1u * sizeof(elements[0]), num_bytes);
  EXPECT_EQ(123, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Query.
  // TODO(vtl): See previous TODO. (If we got 2 elements there, however, we
  // should get 1 here.)
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1 * sizeof(elements[0]), num_bytes);

  // Peek one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), false, true));
  EXPECT_EQ(1u * sizeof(elements[0]), num_bytes);
  EXPECT_EQ(456, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Query. Still has 1 element remaining.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1 * sizeof(elements[0]), num_bytes);

  // Try to read two elements, with "all or none".
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(2u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(-1, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Try to read two elements, without "all or none".
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(2u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(1u * sizeof(elements[0]), num_bytes);
  EXPECT_EQ(456, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Query.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  this->ProducerClose();
  this->ConsumerClose();
}

// Note: The "basic" waiting tests test that the "wait states" are correct in
// various situations; they don't test that waiters are properly awoken on state
// changes. (For that, we need to use multiple threads.)
TYPED_TEST(DataPipeImplTest, BasicProducerWaiting) {
  // Note: We take advantage of the fact that current for current
  // implementations capacities are strict maximums. This is not guaranteed by
  // the API.

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      2 * sizeof(int32_t)                       // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter pwaiter;  // For producer.
  Waiter cwaiter;  // For consumer.
  HandleSignalsState hss;
  uint64_t context;

  // Never readable.
  pwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 12, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Already writable.
  pwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 34, &hss));

  // We'll need to wait for readability for the remote cases.
  cwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&cwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 1234, nullptr));

  // Write two elements.
  int32_t elements[2] = {123, 456};
  uint32_t num_bytes = static_cast<uint32_t>(2u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(elements),
                                    MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(static_cast<uint32_t>(2u * sizeof(elements[0])), num_bytes);

  // Adding a waiter should now succeed.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 56, nullptr));
  // And it shouldn't be writable yet.
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, pwaiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Wait for data to become available to the consumer.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, cwaiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(1234u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&cwaiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Peek one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, true));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(123, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Add a waiter.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 56, nullptr));
  // And it still shouldn't be writable yet.
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, pwaiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Do it again.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 78, nullptr));

  // Read one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(123, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Waiting should now succeed.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, pwaiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(78u, context);
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Try writing, using a two-phase write.
  void* buffer = nullptr;
  num_bytes = static_cast<uint32_t>(3u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&buffer),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(buffer);
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);

  static_cast<int32_t*>(buffer)[0] = 789;
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(static_cast<uint32_t>(
                                1u * sizeof(elements[0]))));

  // Add a waiter.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 90, nullptr));

  // Read one element, using a two-phase read.
  const void* read_buffer = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer);
  // Since we only read one element (after having written three in all), the
  // two-phase read should only allow us to read one. This checks an
  // implementation detail!
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(456, static_cast<const int32_t*>(read_buffer)[0]);
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(static_cast<uint32_t>(
                                1u * sizeof(elements[0]))));

  // Waiting should succeed.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, pwaiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(90u, context);
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Write one element.
  elements[0] = 123;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(elements),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);

  // Add a waiter.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 12, nullptr));

  // Close the consumer.
  this->ConsumerClose();

  // It should now be never-writable.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            pwaiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(12u, context);
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ProducerClose();
}

TYPED_TEST(DataPipeImplTest, PeerClosedProducerWaiting) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      2 * sizeof(int32_t)                       // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;
  uint64_t context;

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 12, nullptr));

  // Close the consumer.
  this->ConsumerClose();

  // It should be signaled.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(12u, context);
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ProducerClose();
}

TYPED_TEST(DataPipeImplTest, PeerClosedConsumerWaiting) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      2 * sizeof(int32_t)                       // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;
  uint64_t context;

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 12, nullptr));

  // Close the producer.
  this->ProducerClose();

  // It should be signaled.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(12u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

TYPED_TEST(DataPipeImplTest, BasicConsumerWaiting) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      1000 * sizeof(int32_t)                    // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  Waiter waiter2;
  HandleSignalsState hss;
  uint64_t context;

  // Never writable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 12, &hss));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Add waiter: not yet readable.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 34, nullptr));

  // Write two elements.
  int32_t elements[2] = {123, 456};
  uint32_t num_bytes = static_cast<uint32_t>(2u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(elements),
                                    MakeUserPointer(&num_bytes), true));

  // Wait for readability (needed for remote cases).
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(34u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Discard one element.
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);

  // Should still be readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 78, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Peek one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, true));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(456, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Should still be readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 78, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(456, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Adding a waiter should now succeed.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 90, nullptr));

  // Write one element.
  elements[0] = 789;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(elements),
                                    MakeUserPointer(&num_bytes), true));

  // Waiting should now succeed.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(90u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // We'll want to wait for the peer closed signal to propagate.
  waiter.Init();
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 12, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Should still be readable, even if the peer closed signal hasn't propagated
  // yet.
  waiter2.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&waiter2, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 34, &hss));
  // We don't know if the peer closed signal has propagated yet (for the remote
  // cases).
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Wait for the peer closed signal.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(12u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(elements),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  EXPECT_EQ(789, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Should be never-readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 56, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

// Test with two-phase APIs and also closing the producer with an active
// consumer waiter.
TYPED_TEST(DataPipeImplTest, ConsumerWaitingTwoPhase) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      1000 * sizeof(int32_t)                    // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;
  uint64_t context;

  // Add waiter: not yet readable.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 12, nullptr));

  // Write two elements.
  int32_t* elements = nullptr;
  void* buffer = nullptr;
  uint32_t num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&buffer),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(buffer);
  EXPECT_GE(num_bytes, static_cast<uint32_t>(3u * sizeof(elements[0])));
  elements = static_cast<int32_t*>(buffer);
  elements[0] = 123;
  elements[1] = 456;
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(static_cast<uint32_t>(
                                2u * sizeof(elements[0]))));

  // Wait for readability (needed for remote cases).
  context = 0;
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(12u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read one element.
  const void* read_buffer = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer);
  EXPECT_EQ(static_cast<uint32_t>(2u * sizeof(elements[0])), num_bytes);
  const int32_t* read_elements = static_cast<const int32_t*>(read_buffer);
  EXPECT_EQ(123, read_elements[0]);
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(static_cast<uint32_t>(
                                1u * sizeof(elements[0]))));

  // Should still be readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 34, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read one element.
  // Request three, but not in all-or-none mode.
  read_buffer = nullptr;
  num_bytes = static_cast<uint32_t>(3u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer);
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(elements[0])), num_bytes);
  read_elements = static_cast<const int32_t*>(read_buffer);
  EXPECT_EQ(456, read_elements[0]);
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(static_cast<uint32_t>(
                                1u * sizeof(elements[0]))));

  // Adding a waiter should now succeed.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 56, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Should be never-readable.
  context = 0;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(test::TinyTimeout(), &context));
  EXPECT_EQ(56u, context);
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

// Tests that data pipes aren't writable/readable during two-phase writes/reads.
TYPED_TEST(DataPipeImplTest, BasicTwoPhaseWaiting) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      1000 * sizeof(int32_t)                    // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter pwaiter;  // For producer.
  Waiter cwaiter;  // For consumer.
  HandleSignalsState hss;

  // It should be writable.
  pwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  void* write_ptr = nullptr;
  uint32_t num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(write_ptr);
  EXPECT_GE(num_bytes, static_cast<uint32_t>(1u * sizeof(int32_t)));

  // At this point, it shouldn't be writable.
  pwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 1, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, pwaiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&pwaiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // It shouldn't be readable yet either (we'll wait later).
  cwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&cwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 2, nullptr));

  static_cast<int32_t*>(write_ptr)[0] = 123;
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(
                                static_cast<uint32_t>(1u * sizeof(int32_t))));

  // It should immediately be writable again.
  pwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 3, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // It should become readable.
  EXPECT_EQ(MOJO_RESULT_OK, cwaiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&cwaiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Start another two-phase write and check that it's readable even in the
  // middle of it.
  write_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(write_ptr);
  EXPECT_GE(num_bytes, static_cast<uint32_t>(1u * sizeof(int32_t)));

  // It should be readable.
  cwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&cwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 5, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // End the two-phase write without writing anything.
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(0u));

  // Start a two-phase read.
  const void* read_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_ptr);
  EXPECT_EQ(static_cast<uint32_t>(1u * sizeof(int32_t)), num_bytes);

  // At this point, it should still be writable.
  pwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ProducerAddAwakable(&pwaiter, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 6, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // But not readable.
  cwaiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&cwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 7, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, cwaiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&cwaiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // End the two-phase read without reading anything.
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(0u));

  // It should be readable again.
  cwaiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(&cwaiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 8, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  this->ProducerClose();
  this->ConsumerClose();
}

void Seq(int32_t start, size_t count, int32_t* out) {
  for (size_t i = 0; i < count; i++)
    out[i] = start + static_cast<int32_t>(i);
}

TYPED_TEST(DataPipeImplTest, AllOrNone) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      10 * sizeof(int32_t)                      // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Try writing way too much.
  uint32_t num_bytes = 20u * sizeof(int32_t);
  int32_t buffer[100];
  Seq(0, MOJO_ARRAYSIZE(buffer), buffer);
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ProducerWriteData(UserPointer<const void>(buffer),
                                    MakeUserPointer(&num_bytes), true));

  // Should still be empty.
  num_bytes = ~0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 1, nullptr));

  // Write some data.
  num_bytes = 5u * sizeof(int32_t);
  Seq(100, MOJO_ARRAYSIZE(buffer), buffer);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(buffer),
                                    MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(5u * sizeof(int32_t), num_bytes);

  // Wait for data.
  // TODO(vtl): There's no real guarantee that all the data will become
  // available at once (except that in current implementations, with reasonable
  // limits, it will). Eventually, we'll be able to wait for a specified amount
  // of data to become available.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Half full.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(5u * sizeof(int32_t), num_bytes);

  // Too much.
  num_bytes = 6u * sizeof(int32_t);
  Seq(200, MOJO_ARRAYSIZE(buffer), buffer);
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ProducerWriteData(UserPointer<const void>(buffer),
                                    MakeUserPointer(&num_bytes), true));

  // Try reading too much.
  num_bytes = 11u * sizeof(int32_t);
  memset(buffer, 0xab, sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), true, false));
  int32_t expected_buffer[100];
  memset(expected_buffer, 0xab, sizeof(expected_buffer));
  EXPECT_EQ(0, memcmp(buffer, expected_buffer, sizeof(buffer)));

  // Try discarding too much.
  num_bytes = 11u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));

  // Just a little.
  num_bytes = 2u * sizeof(int32_t);
  Seq(300, MOJO_ARRAYSIZE(buffer), buffer);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(buffer),
                                    MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(2u * sizeof(int32_t), num_bytes);

  // Just right.
  num_bytes = 3u * sizeof(int32_t);
  Seq(400, MOJO_ARRAYSIZE(buffer), buffer);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(buffer),
                                    MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(3u * sizeof(int32_t), num_bytes);

  // TODO(vtl): Hack (see also the TODO above): We can't currently wait for a
  // specified amount of data to be available, so poll.
  for (size_t i = 0; i < kMaxPoll; i++) {
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
    if (num_bytes >= 10u * sizeof(int32_t))
      break;

    ThreadSleep(test::EpsilonTimeout());
  }
  EXPECT_EQ(10u * sizeof(int32_t), num_bytes);

  // Read half.
  num_bytes = 5u * sizeof(int32_t);
  memset(buffer, 0xab, sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(5u * sizeof(int32_t), num_bytes);
  memset(expected_buffer, 0xab, sizeof(expected_buffer));
  Seq(100, 5, expected_buffer);
  EXPECT_EQ(0, memcmp(buffer, expected_buffer, sizeof(buffer)));

  // Try reading too much again.
  num_bytes = 6u * sizeof(int32_t);
  memset(buffer, 0xab, sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), true, false));
  memset(expected_buffer, 0xab, sizeof(expected_buffer));
  EXPECT_EQ(0, memcmp(buffer, expected_buffer, sizeof(buffer)));

  // Try discarding too much again.
  num_bytes = 6u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));

  // Discard a little.
  num_bytes = 2u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(2u * sizeof(int32_t), num_bytes);

  // Three left.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(3u * sizeof(int32_t), num_bytes);

  // We'll need to wait for the peer closed to propagate.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 2, nullptr));

  // Close the producer, then test producer-closed cases.
  this->ProducerClose();

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Try reading too much; "failed precondition" since the producer is closed.
  num_bytes = 4u * sizeof(int32_t);
  memset(buffer, 0xab, sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), true, false));
  memset(expected_buffer, 0xab, sizeof(expected_buffer));
  EXPECT_EQ(0, memcmp(buffer, expected_buffer, sizeof(buffer)));

  // Try discarding too much; "failed precondition" again.
  num_bytes = 4u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));

  // Read a little.
  num_bytes = 2u * sizeof(int32_t);
  memset(buffer, 0xab, sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(2u * sizeof(int32_t), num_bytes);
  memset(expected_buffer, 0xab, sizeof(expected_buffer));
  Seq(400, 2, expected_buffer);
  EXPECT_EQ(0, memcmp(buffer, expected_buffer, sizeof(buffer)));

  // Discard the remaining element.
  num_bytes = 1u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), true));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);

  // Empty again.
  num_bytes = ~0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  this->ConsumerClose();
}

// Tests that |ProducerWriteData()| and |ConsumerReadData()| writes and reads,
// respectively, as much as possible, even if it may have to "wrap around" the
// internal circular buffer. (Note that the two-phase write and read need not do
// this.)
TYPED_TEST(DataPipeImplTest, WrapAround) {
  unsigned char test_data[1000];
  for (size_t i = 0; i < MOJO_ARRAYSIZE(test_data); i++)
    test_data[i] = static_cast<unsigned char>(i);

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      100u                                      // |capacity_num_bytes|.
  };
  MojoCreateDataPipeOptions validated_options = {};
  // This test won't be valid if |ValidateCreateOptions()| decides to give the
  // pipe more space.
  EXPECT_EQ(MOJO_RESULT_OK, DataPipe::ValidateCreateOptions(
                                MakeUserPointer(&options), &validated_options));
  ASSERT_EQ(100u, validated_options.capacity_num_bytes);
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 1, nullptr));

  // Write 20 bytes.
  uint32_t num_bytes = 20u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(&test_data[0]),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(20u, num_bytes);

  // Wait for data.
  // TODO(vtl): (See corresponding TODO in AllOrNone.)
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read 10 bytes.
  unsigned char read_buffer[1000] = {0};
  num_bytes = 10u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(read_buffer),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(10u, num_bytes);
  EXPECT_EQ(0, memcmp(read_buffer, &test_data[0], 10u));

  if (this->IsStrictCircularBuffer()) {
    // Check that a two-phase write can now only write (at most) 80 bytes. (This
    // checks an implementation detail; this behavior is not guaranteed.)
    void* write_buffer_ptr = nullptr;
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ProducerBeginWriteData(MakeUserPointer(&write_buffer_ptr),
                                           MakeUserPointer(&num_bytes)));
    EXPECT_TRUE(write_buffer_ptr);
    EXPECT_EQ(80u, num_bytes);
    EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(0u));
  }

  // TODO(vtl): (See corresponding TODO in TwoPhaseAllOrNone.)
  size_t total_num_bytes = 0u;
  for (size_t i = 0; i < kMaxPoll; i++) {
    // Write as much data as we can (using |ProducerWriteData()|). We should
    // write 90 bytes (eventually).
    num_bytes = 200u;
    MojoResult result = this->ProducerWriteData(
        UserPointer<const void>(&test_data[20 + total_num_bytes]),
        MakeUserPointer(&num_bytes), false);
    if (result == MOJO_RESULT_OK) {
      total_num_bytes += num_bytes;
      if (total_num_bytes >= 90u)
        break;
    } else {
      EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE, result);
    }

    ThreadSleep(test::EpsilonTimeout());
  }
  EXPECT_EQ(90u, total_num_bytes);

  // TODO(vtl): (See corresponding TODO in TwoPhaseAllOrNone.)
  for (size_t i = 0; i < kMaxPoll; i++) {
    // We have 100.
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
    if (num_bytes >= 100u)
      break;

    ThreadSleep(test::EpsilonTimeout());
  }
  EXPECT_EQ(100u, num_bytes);

  if (this->IsStrictCircularBuffer()) {
    // Check that a two-phase read can now only read (at most) 90 bytes. (This
    // checks an implementation detail; this behavior is not guaranteed.)
    const void* read_buffer_ptr = nullptr;
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                          MakeUserPointer(&num_bytes)));
    EXPECT_TRUE(read_buffer_ptr);
    EXPECT_EQ(90u, num_bytes);
    EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(0u));
  }

  // Read as much as possible (using |ConsumerReadData()|). We should read 100
  // bytes.
  num_bytes = static_cast<uint32_t>(MOJO_ARRAYSIZE(read_buffer) *
                                    sizeof(read_buffer[0]));
  memset(read_buffer, 0, num_bytes);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(read_buffer),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(100u, num_bytes);
  EXPECT_EQ(0, memcmp(read_buffer, &test_data[10], 100u));

  this->ProducerClose();
  this->ConsumerClose();
}

// Tests the behavior of writing (simple and two-phase), closing the producer,
// then reading (simple and two-phase).
TYPED_TEST(DataPipeImplTest, WriteCloseProducerRead) {
  const char kTestData[] = "hello world";
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Write it again, so we'll have something left over.
  num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Start two-phase write.
  void* write_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_buffer_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(write_buffer_ptr);
  EXPECT_GT(num_bytes, 0u);

  // TODO(vtl): (See corresponding TODO in TwoPhaseAllOrNone.)
  for (size_t i = 0; i < kMaxPoll; i++) {
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
    if (num_bytes >= 2u * kTestDataSize)
      break;

    ThreadSleep(test::EpsilonTimeout());
  }
  EXPECT_EQ(2u * kTestDataSize, num_bytes);

  // Start two-phase read.
  const void* read_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer_ptr);
  EXPECT_EQ(2u * kTestDataSize, num_bytes);

  // Close the producer.
  this->ProducerClose();

  // The consumer can finish its two-phase read.
  EXPECT_EQ(0, memcmp(read_buffer_ptr, kTestData, kTestDataSize));
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(kTestDataSize));

  // And start another.
  read_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer_ptr);
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Close the consumer, which cancels the two-phase read.
  this->ConsumerClose();
}

// Tests the behavior of interrupting a two-phase read and write by closing the
// consumer.
TYPED_TEST(DataPipeImplTest, TwoPhaseWriteReadCloseConsumer) {
  const char kTestData[] = "hello world";
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 1, nullptr));

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Start two-phase write.
  void* write_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_buffer_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(write_buffer_ptr);
  ASSERT_GT(num_bytes, kTestDataSize);

  // Wait for data.
  // TODO(vtl): (See corresponding TODO in AllOrNone.)
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Start two-phase read.
  const void* read_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(read_buffer_ptr);
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 1, nullptr));

  // Close the consumer.
  this->ConsumerClose();

  // Wait for producer to know that the consumer is closed.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  // Actually write some data. (Note: Premature freeing of the buffer would
  // probably only be detected under ASAN or similar.)
  memcpy(write_buffer_ptr, kTestData, kTestDataSize);
  // Note: Even though the consumer has been closed, ending the two-phase
  // write will report success.
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(kTestDataSize));

  // But trying to write should result in failure.
  num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));

  // As will trying to start another two-phase write.
  write_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ProducerBeginWriteData(MakeUserPointer(&write_buffer_ptr),
                                         MakeUserPointer(&num_bytes)));

  this->ProducerClose();
}

// Tests the behavior of "interrupting" a two-phase write by closing both the
// producer and the consumer.
TYPED_TEST(DataPipeImplTest, TwoPhaseWriteCloseBoth) {
  const uint32_t kTestDataSize = 15u;

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  // Start two-phase write.
  void* write_buffer_ptr = nullptr;
  uint32_t num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_buffer_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_TRUE(write_buffer_ptr);
  ASSERT_GT(num_bytes, kTestDataSize);

  this->ConsumerClose();
  this->ProducerClose();
}

// Tests the behavior of writing, closing the producer, and then reading (with
// and without data remaining).
TYPED_TEST(DataPipeImplTest, WriteCloseProducerReadNoData) {
  const char kTestData[] = "hello world";
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 1, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Wait. (Note that once the consumer knows that the producer is closed, it
  // must also know about all the data that was sent.)
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Peek that data.
  char buffer[1000];
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), false, true));
  EXPECT_EQ(kTestDataSize, num_bytes);
  EXPECT_EQ(0, memcmp(buffer, kTestData, kTestDataSize));

  // Read that data.
  memset(buffer, 0, 1000);
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(kTestDataSize, num_bytes);
  EXPECT_EQ(0, memcmp(buffer, kTestData, kTestDataSize));

  // A second read should fail.
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerReadData(UserPointer<void>(buffer),
                                   MakeUserPointer(&num_bytes), false, false));

  // A two-phase read should also fail.
  const void* read_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                        MakeUserPointer(&num_bytes)));

  // Ditto for discard.
  num_bytes = 10u;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerDiscardData(MakeUserPointer(&num_bytes), false));

  this->ConsumerClose();
}

// Tests the behavior of writing, reading (all the data), closing the producer,
// and then waiting for more data (with no data remaining).
TYPED_TEST(DataPipeImplTest, WriteReadCloseProducerWaitNoData) {
  const int64_t kTestData = 123456789012345LL;
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      kTestDataSize,                            // |element_num_bytes|.
      100u * kTestDataSize                      // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 0, nullptr));

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(&kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read that data.
  int64_t data[10] = {};
  num_bytes = static_cast<uint32_t>(sizeof(data));
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(data),
                                   MakeUserPointer(&num_bytes), false, false));
  EXPECT_EQ(kTestDataSize, num_bytes);
  EXPECT_EQ(kTestData, data[0]);

  // Add waiter again.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 0, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Wait.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

// During a two-phase read, the consumer is not readable so it may be waited
// upon (to become readable again). If the producer is closed and the two-phase
// read consumes the remaining data, that wait should become unsatisfiable.
TYPED_TEST(DataPipeImplTest, BeginReadCloseProducerWaitEndReadNoData) {
  const int64_t kTestData = 123456789012345LL;
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      kTestDataSize,                            // |element_num_bytes|.
      100u * kTestDataSize                      // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // Add waiter (for the consumer to become readable).
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 0, nullptr));

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(&kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Start a two-phase read.
  num_bytes = 0u;
  const void* read_ptr = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_EQ(kTestDataSize, num_bytes);
  EXPECT_EQ(kTestData, static_cast<const int64_t*>(read_ptr)[0]);

  // Add waiter (for the producer to be closed).
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 0, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Wait for producer close to be detected.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Add waiter (for the consumer to become readable).
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 0, nullptr));

  // Complete the two-phase read.
  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(kTestDataSize));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

// During a two-phase write, the producer is not writable so it may be waited
// upon (to become writable again). If the consumer is closed, that wait should
// become unsatisfiable.
TYPED_TEST(DataPipeImplTest, BeginWriteCloseConsumerWaitEndWrite) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      100u                                      // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter1;
  Waiter waiter2;
  HandleSignalsState hss;

  // Start a two-phase write.
  void* write_ptr = nullptr;
  uint32_t num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_ptr),
                                         MakeUserPointer(&num_bytes)));

  // Add waiter (for the consumer to be closed).
  waiter1.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&waiter1, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                                      false, 0, nullptr));

  // Add a separate waiter (for the producer to become writable).
  waiter2.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ProducerAddAwakable(&waiter2, MOJO_HANDLE_SIGNAL_WRITABLE,
                                      false, 0, nullptr));

  // Close the consumer.
  this->ConsumerClose();

  // Wait for the consumer close to be detected.
  // Note: If we didn't wait for the consumer close to be detected before
  // completing the two-phase write, wait might succeed (in the remote cases).
  // This is because the first |Awake()| "wins".
  EXPECT_EQ(MOJO_RESULT_OK, waiter1.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter1, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  // Complete the two-phase write (with nothing written).
  EXPECT_EQ(MOJO_RESULT_OK, this->ProducerEndWriteData(0u));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter2.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter2, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ProducerClose();
}

// Test that two-phase reads/writes behave correctly when given invalid
// arguments.
TYPED_TEST(DataPipeImplTest, TwoPhaseMoreInvalidArguments) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      static_cast<uint32_t>(sizeof(int32_t)),   // |element_num_bytes|.
      10 * sizeof(int32_t)                      // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  Waiter waiter;
  HandleSignalsState hss;

  // No data.
  uint32_t num_bytes = 1000u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Try "ending" a two-phase write when one isn't active.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ProducerEndWriteData(1u * sizeof(int32_t)));

  // Wait a bit, to make sure that if a signal were (incorrectly) sent, it'd
  // have time to propagate.
  ThreadSleep(test::EpsilonTimeout());

  // Still no data.
  num_bytes = 1000u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Try ending a two-phase write with an invalid amount (too much).
  void* write_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            this->ProducerEndWriteData(num_bytes +
                                       static_cast<uint32_t>(sizeof(int32_t))));

  // But the two-phase write still ended.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, this->ProducerEndWriteData(0u));

  // Wait a bit (as above).
  ThreadSleep(test::EpsilonTimeout());

  // Still no data.
  num_bytes = 1000u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Try ending a two-phase write with an invalid amount (not a multiple of the
  // element size).
  write_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerBeginWriteData(MakeUserPointer(&write_ptr),
                                         MakeUserPointer(&num_bytes)));
  EXPECT_GE(num_bytes, 1u);
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, this->ProducerEndWriteData(1u));

  // But the two-phase write still ended.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, this->ProducerEndWriteData(0u));

  // Wait a bit (as above).
  ThreadSleep(test::EpsilonTimeout());

  // Still no data.
  num_bytes = 1000u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(0u, num_bytes);

  // Add waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 1, nullptr));

  // Now write some data, so we'll be able to try reading.
  int32_t element = 123;
  num_bytes = 1u * sizeof(int32_t);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(&element),
                                    MakeUserPointer(&num_bytes), false));

  // Wait for data.
  // TODO(vtl): (See corresponding TODO in AllOrNone.)
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // One element available.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);

  // Try "ending" a two-phase read when one isn't active.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerEndReadData(1u * sizeof(int32_t)));

  // Still one element available.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);

  // Try ending a two-phase read with an invalid amount (too much).
  num_bytes = 0u;
  const void* read_ptr = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            this->ConsumerEndReadData(num_bytes +
                                      static_cast<uint32_t>(sizeof(int32_t))));

  // Still one element available.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);

  // Try ending a two-phase read with an invalid amount (not a multiple of the
  // element size).
  num_bytes = 0u;
  read_ptr = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);
  EXPECT_EQ(123, static_cast<const int32_t*>(read_ptr)[0]);
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, this->ConsumerEndReadData(1u));

  // Still one element available.
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
  EXPECT_EQ(1u * sizeof(int32_t), num_bytes);

  this->ProducerClose();
  this->ConsumerClose();
}

// Tests the behavior of writing, closing the producer, and then doing a
// two-phase read of all the data.
// Note: If this test fails/crashes flakily, this is almost certainly an
// indication of a problem in the implementation and not the test.
TYPED_TEST(DataPipeImplTest, WriteCloseProducerTwoPhaseReadAllData) {
  const char kTestData[] = "hello world";
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));

  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  // Write some data, so we'll have something to read.
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // TODO(vtl): Hack: We can't currently wait for a specified amount of data to
  // be available, so poll.
  for (size_t i = 0; i < kMaxPoll; i++) {
    num_bytes = 0u;
    EXPECT_EQ(MOJO_RESULT_OK,
              this->ConsumerQueryData(MakeUserPointer(&num_bytes)));
    if (num_bytes >= kTestDataSize)
      break;

    ThreadSleep(test::EpsilonTimeout());
  }
  EXPECT_EQ(kTestDataSize, num_bytes);

  const void* read_buffer_ptr = nullptr;
  num_bytes = 0u;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerBeginReadData(MakeUserPointer(&read_buffer_ptr),
                                        MakeUserPointer(&num_bytes)));
  EXPECT_EQ(kTestDataSize, num_bytes);
  EXPECT_EQ(0, memcmp(read_buffer_ptr, kTestData, kTestDataSize));

  // Close the producer.
  this->ProducerClose();

  // Note: This tiny sleep is to allow/encourage a certain race. In particular,
  // for the remote producer case in
  // |RemoteProducerDataPipeImpl::MarkDataAsConsumed()| (caused by
  // |ConsumerEndReadData()| below) we want |producer_open()| to be false but
  // the call to |channel_endpoint_->EnqueueMessage()| to fail. (This race can
  // occur without the sleep, but is much less likely.)
  ThreadSleep(10u);

  EXPECT_EQ(MOJO_RESULT_OK, this->ConsumerEndReadData(num_bytes));

  this->ConsumerClose();
}

TYPED_TEST(DataPipeImplTest, WriteThreshold) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      10u                                       // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  // The default write threshold should be 0 (which means "default", i.e., one
  // element).
  uint32_t write_threshold_num_bytes = 123;
  this->ProducerGetOptions(&write_threshold_num_bytes);
  EXPECT_EQ(0u, write_threshold_num_bytes);

  Waiter waiter;
  HandleSignalsState hss;

  // Try to wait to the write threshold signal; it should already have it.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ProducerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD, false, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Before writing, add a waiter on the consumer (since we'll need to know when
  // the written bytes have propagated).
  Waiter read_waiter;
  read_waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(&read_waiter, MOJO_HANDLE_SIGNAL_READABLE,
                                      false, 0, nullptr));

  // Write 5 bytes.
  static const char kTestData[5] = {'A', 'B', 'C', 'D', 'E'};
  uint32_t num_bytes = 5;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(5u, num_bytes);

  // It should still have the write threshold signal.
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      this->ProducerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));

  // Set the write threshold to 5.
  this->ProducerSetOptions(5);
  write_threshold_num_bytes = 123u;
  this->ProducerGetOptions(&write_threshold_num_bytes);
  EXPECT_EQ(5u, write_threshold_num_bytes);

  // Should still have the write threshold signal.
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      this->ProducerAddAwakable(&waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));

  // Set the write threshold to 6.
  this->ProducerSetOptions(6);

  // Should no longer have the write threshold signal.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK, this->ProducerAddAwakable(
                                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK, this->ProducerAddAwakable(
                                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));

  // Wait for the consumer to be readable.
  EXPECT_EQ(MOJO_RESULT_OK, read_waiter.Wait(test::TinyTimeout(), nullptr));
  this->ConsumerRemoveAwakable(&read_waiter, nullptr);

  // Read a byte.
  char read_byte = 'a';
  num_bytes = sizeof(read_byte);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(&read_byte),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(1u, num_bytes);
  EXPECT_EQ(kTestData[0], read_byte);

  // Wait; should get the write threshold signal.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
            hss.satisfiable_signals);

  // Write 6 more bytes.
  static const char kMoreTestData[6] = {'1', '2', '3', '4', '5', '6'};
  num_bytes = 6;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kMoreTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(6u, num_bytes);

  // Should no longer have the write threshold signal.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK, this->ProducerAddAwakable(
                                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  this->ProducerRemoveAwakable(&waiter, nullptr);

  // Set the write threshold to 0 (which means the element size, 1).
  this->ProducerSetOptions(0);
  write_threshold_num_bytes = 123u;
  this->ProducerGetOptions(&write_threshold_num_bytes);
  EXPECT_EQ(0u, write_threshold_num_bytes);

  // Should still not have the write threshold signal.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK, this->ProducerAddAwakable(
                                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  this->ProducerRemoveAwakable(&waiter, nullptr);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK, this->ProducerAddAwakable(
                                &waiter, MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD,
                                false, 0, nullptr));

  // Close the consumer.
  this->ConsumerClose();

  // Wait; the condition should now never be satisfiable.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ProducerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ProducerClose();
}

TYPED_TEST(DataPipeImplTest, ReadThreshold) {
  const MojoCreateDataPipeOptions options = {
      kSizeOfOptions,                           // |struct_size|.
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
      1u,                                       // |element_num_bytes|.
      1000u                                     // |capacity_num_bytes|.
  };
  this->Create(options);
  this->DoTransfer();

  // The default read threshold should be 0 (which means "default", i.e., one
  // element).
  uint32_t read_threshold_num_bytes = 123;
  this->ConsumerGetOptions(&read_threshold_num_bytes);
  EXPECT_EQ(0u, read_threshold_num_bytes);

  Waiter waiter;
  HandleSignalsState hss;

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));
  // Trivial wait: it shouldn't have the read threshold signal.
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));

  // Write a byte.
  const char kTestData[] = {'x'};
  const uint32_t kTestDataSize = static_cast<uint32_t>(sizeof(kTestData));
  uint32_t num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Wait for the read threshold signal.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Set the read threshold to 1.
  this->ConsumerSetOptions(1);
  read_threshold_num_bytes = 123u;
  this->ConsumerGetOptions(&read_threshold_num_bytes);
  EXPECT_EQ(1u, read_threshold_num_bytes);

  // Try to add a waiter: it should (still) already have the read threshold
  // signal.
  waiter.Init();
  hss = HandleSignalsState();
  ASSERT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Set the read threshold to 2.
  this->ConsumerSetOptions(2);
  read_threshold_num_bytes = 123u;
  this->ConsumerGetOptions(&read_threshold_num_bytes);
  EXPECT_EQ(2u, read_threshold_num_bytes);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));

  // Write another byte.
  num_bytes = kTestDataSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ProducerWriteData(UserPointer<const void>(kTestData),
                                    MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(kTestDataSize, num_bytes);

  // Wait for the read threshold signal.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read one byte.
  char read_byte = 'a';
  num_bytes = sizeof(read_byte);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(&read_byte),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(1u, num_bytes);
  EXPECT_EQ(kTestData[0], read_byte);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));
  // Trivial wait: it shouldn't have the read threshold signal.
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));
  // Trivial wait: it shouldn't have the read threshold signal.
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Add a waiter.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, nullptr));

  // Close the producer.
  this->ProducerClose();

  // Wait; the current read threshold becomes never satisfiable.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(test::TinyTimeout(), nullptr));
  hss = HandleSignalsState();
  this->ConsumerRemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Set the read threshold back to zero to 0.
  this->ConsumerSetOptions(0);
  read_threshold_num_bytes = 123u;
  this->ConsumerGetOptions(&read_threshold_num_bytes);
  // "Get options" should preserve 0 (and not set it to the element size).
  EXPECT_EQ(0u, read_threshold_num_bytes);

  // Try to add a waiter: it should have the read threshold signal.
  waiter.Init();
  hss = HandleSignalsState();
  ASSERT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                MOJO_HANDLE_SIGNAL_READ_THRESHOLD,
            hss.satisfiable_signals);

  // Read the other byte.
  read_byte = 'a';
  num_bytes = sizeof(read_byte);
  EXPECT_EQ(MOJO_RESULT_OK,
            this->ConsumerReadData(UserPointer<void>(&read_byte),
                                   MakeUserPointer(&num_bytes), true, false));
  EXPECT_EQ(1u, num_bytes);
  EXPECT_EQ(kTestData[0], read_byte);

  // Try to add a waiter: the read threshold signal should be unsatisfiable.
  waiter.Init();
  hss = HandleSignalsState();
  ASSERT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            this->ConsumerAddAwakable(
                &waiter, MOJO_HANDLE_SIGNAL_READ_THRESHOLD, false, 0, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  this->ConsumerClose();
}

}  // namespace
}  // namespace system
}  // namespace mojo

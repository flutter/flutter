// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/core_test_base.h"

#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/core.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace test {

namespace {

// MockDispatcher --------------------------------------------------------------

class MockDispatcher : public Dispatcher {
 public:
  static RefPtr<MockDispatcher> Create(CoreTestBase::MockHandleInfo* info) {
    return AdoptRef(new MockDispatcher(info));
  }

  // |Dispatcher| public methods:
  Type GetType() const override { return Type::UNKNOWN; }

  bool SupportsEntrypointClass(
      EntrypointClass entrypoint_class) const override {
    return true;
  }

 private:
  explicit MockDispatcher(CoreTestBase::MockHandleInfo* info) : info_(info) {
    CHECK(info_);
    info_->IncrementCtorCallCount();
  }

  ~MockDispatcher() override { info_->IncrementDtorCallCount(); }

  // |Dispatcher| protected methods:
  void CloseImplNoLock() override {
    info_->IncrementCloseCallCount();
    mutex().AssertHeld();
  }

  MojoResult DuplicateDispatcherImplNoLock(
      util::RefPtr<Dispatcher>* new_dispatcher) override {
    info_->IncrementDuplicateDispatcherCallCount();
    *new_dispatcher = MockDispatcher::Create(info_);
    return MOJO_RESULT_OK;
  }

  MojoResult WriteMessageImplNoLock(UserPointer<const void> bytes,
                                    uint32_t num_bytes,
                                    std::vector<HandleTransport>* transports,
                                    MojoWriteMessageFlags /*flags*/) override {
    info_->IncrementWriteMessageCallCount();
    mutex().AssertHeld();

    if (num_bytes > GetConfiguration().max_message_num_bytes)
      return MOJO_RESULT_RESOURCE_EXHAUSTED;

    if (transports)
      return MOJO_RESULT_UNIMPLEMENTED;

    return MOJO_RESULT_OK;
  }

  MojoResult ReadMessageImplNoLock(UserPointer<void> bytes,
                                   UserPointer<uint32_t> num_bytes,
                                   HandleVector* handles,
                                   uint32_t* num_handles,
                                   MojoReadMessageFlags /*flags*/) override {
    info_->IncrementReadMessageCallCount();
    mutex().AssertHeld();

    if (num_handles) {
      *num_handles = 1;
      if (handles) {
        // Okay to leave an invalid handle.
        handles->resize(1);
      }
    }

    return MOJO_RESULT_OK;
  }

  MojoResult WriteDataImplNoLock(UserPointer<const void> /*elements*/,
                                 UserPointer<uint32_t> /*num_bytes*/,
                                 MojoWriteDataFlags /*flags*/) override {
    info_->IncrementWriteDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult BeginWriteDataImplNoLock(
      UserPointer<void*> /*buffer*/,
      UserPointer<uint32_t> /*buffer_num_bytes*/,
      MojoWriteDataFlags /*flags*/) override {
    info_->IncrementBeginWriteDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult EndWriteDataImplNoLock(uint32_t /*num_bytes_written*/) override {
    info_->IncrementEndWriteDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult ReadDataImplNoLock(UserPointer<void> /*elements*/,
                                UserPointer<uint32_t> /*num_bytes*/,
                                MojoReadDataFlags /*flags*/) override {
    info_->IncrementReadDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult BeginReadDataImplNoLock(UserPointer<const void*> /*buffer*/,
                                     UserPointer<uint32_t> /*buffer_num_bytes*/,
                                     MojoReadDataFlags /*flags*/) override {
    info_->IncrementBeginReadDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult EndReadDataImplNoLock(uint32_t /*num_bytes_read*/) override {
    info_->IncrementEndReadDataCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult DuplicateBufferHandleImplNoLock(
      UserPointer<const MojoDuplicateBufferHandleOptions> /*options*/,
      RefPtr<Dispatcher>* /*new_dispatcher*/) override {
    info_->IncrementDuplicateBufferHandleCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult GetBufferInformationImplNoLock(
      UserPointer<MojoBufferInformation> /*info*/,
      uint32_t /*info_num_bytes*/) override {
    info_->IncrementGetBufferInformationCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult MapBufferImplNoLock(
      uint64_t /*offset*/,
      uint64_t /*num_bytes*/,
      MojoMapBufferFlags /*flags*/,
      std::unique_ptr<platform::PlatformSharedBufferMapping>* /*mapping*/)
      override {
    info_->IncrementMapBufferCallCount();
    mutex().AssertHeld();
    return MOJO_RESULT_UNIMPLEMENTED;
  }

  MojoResult AddAwakableImplNoLock(Awakable* awakable,
                                   MojoHandleSignals /*signals*/,
                                   uint32_t /*context*/,
                                   HandleSignalsState* signals_state) override {
    info_->IncrementAddAwakableCallCount();
    mutex().AssertHeld();
    if (signals_state)
      *signals_state = HandleSignalsState();
    if (info_->IsAddAwakableAllowed()) {
      info_->AwakableWasAdded(awakable);
      return MOJO_RESULT_OK;
    }

    return MOJO_RESULT_FAILED_PRECONDITION;
  }

  void RemoveAwakableImplNoLock(Awakable* /*awakable*/,
                                HandleSignalsState* signals_state) override {
    info_->IncrementRemoveAwakableCallCount();
    mutex().AssertHeld();
    if (signals_state)
      *signals_state = HandleSignalsState();
  }

  void CancelAllAwakablesNoLock() override {
    info_->IncrementCancelAllAwakablesCallCount();
    mutex().AssertHeld();
  }

  RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* /*message_pipe*/,
      unsigned /*port*/) override {
    CancelAllAwakablesNoLock();
    return Create(info_);
  }

  CoreTestBase::MockHandleInfo* const info_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockDispatcher);
};

}  // namespace

// CoreTestBase ----------------------------------------------------------------

// static
constexpr MojoHandleRights CoreTestBase::kDefaultMockHandleRights;

CoreTestBase::CoreTestBase()
    : platform_support_(embedder::CreateSimplePlatformSupport()) {}

CoreTestBase::~CoreTestBase() {}

void CoreTestBase::SetUp() {
  CHECK(!core_);
  core_.reset(new Core(platform_support_.get()));
}

void CoreTestBase::TearDown() {
  CHECK(core_);
  core_.reset();
}

MojoHandle CoreTestBase::CreateMockHandle(CoreTestBase::MockHandleInfo* info) {
  CHECK(core_);
  auto dispatcher = MockDispatcher::Create(info);
  MojoHandle rv = core_->AddHandle(Handle(
      std::move(dispatcher),
      MOJO_HANDLE_RIGHT_DUPLICATE | MOJO_HANDLE_RIGHT_TRANSFER |
          MOJO_HANDLE_RIGHT_READ | MOJO_HANDLE_RIGHT_WRITE |
          MOJO_HANDLE_RIGHT_GET_OPTIONS | MOJO_HANDLE_RIGHT_SET_OPTIONS |
          MOJO_HANDLE_RIGHT_MAP_READABLE | MOJO_HANDLE_RIGHT_MAP_WRITABLE |
          MOJO_HANDLE_RIGHT_MAP_EXECUTABLE));
  CHECK_NE(rv, MOJO_HANDLE_INVALID);
  return rv;
}

// CoreTestBase_MockHandleInfo -------------------------------------------------

CoreTestBase_MockHandleInfo::CoreTestBase_MockHandleInfo() {}

CoreTestBase_MockHandleInfo::~CoreTestBase_MockHandleInfo() {}

unsigned CoreTestBase_MockHandleInfo::GetCtorCallCount() const {
  MutexLocker locker(&mutex_);
  return ctor_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetDtorCallCount() const {
  MutexLocker locker(&mutex_);
  return dtor_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetCloseCallCount() const {
  MutexLocker locker(&mutex_);
  return close_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetDuplicateDispatcherCallCount() const {
  MutexLocker locker(&mutex_);
  return duplicate_dispatcher_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetWriteMessageCallCount() const {
  MutexLocker locker(&mutex_);
  return write_message_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetReadMessageCallCount() const {
  MutexLocker locker(&mutex_);
  return read_message_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetWriteDataCallCount() const {
  MutexLocker locker(&mutex_);
  return write_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetBeginWriteDataCallCount() const {
  MutexLocker locker(&mutex_);
  return begin_write_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetEndWriteDataCallCount() const {
  MutexLocker locker(&mutex_);
  return end_write_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetReadDataCallCount() const {
  MutexLocker locker(&mutex_);
  return read_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetBeginReadDataCallCount() const {
  MutexLocker locker(&mutex_);
  return begin_read_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetEndReadDataCallCount() const {
  MutexLocker locker(&mutex_);
  return end_read_data_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetDuplicateBufferHandleCallCount()
    const {
  MutexLocker locker(&mutex_);
  return duplicate_buffer_handle_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetGetBufferInformationCallCount() const {
  MutexLocker locker(&mutex_);
  return get_buffer_information_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetMapBufferCallCount() const {
  MutexLocker locker(&mutex_);
  return map_buffer_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetAddAwakableCallCount() const {
  MutexLocker locker(&mutex_);
  return add_awakable_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetRemoveAwakableCallCount() const {
  MutexLocker locker(&mutex_);
  return remove_awakable_call_count_;
}

unsigned CoreTestBase_MockHandleInfo::GetCancelAllAwakablesCallCount() const {
  MutexLocker locker(&mutex_);
  return cancel_all_awakables_call_count_;
}

size_t CoreTestBase_MockHandleInfo::GetAddedAwakableSize() const {
  MutexLocker locker(&mutex_);
  return added_awakables_.size();
}

Awakable* CoreTestBase_MockHandleInfo::GetAddedAwakableAt(unsigned i) const {
  MutexLocker locker(&mutex_);
  return added_awakables_[i];
}

void CoreTestBase_MockHandleInfo::IncrementCtorCallCount() {
  MutexLocker locker(&mutex_);
  ctor_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementDtorCallCount() {
  MutexLocker locker(&mutex_);
  dtor_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementCloseCallCount() {
  MutexLocker locker(&mutex_);
  close_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementDuplicateDispatcherCallCount() {
  MutexLocker locker(&mutex_);
  duplicate_dispatcher_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementWriteMessageCallCount() {
  MutexLocker locker(&mutex_);
  write_message_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementReadMessageCallCount() {
  MutexLocker locker(&mutex_);
  read_message_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementWriteDataCallCount() {
  MutexLocker locker(&mutex_);
  write_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementBeginWriteDataCallCount() {
  MutexLocker locker(&mutex_);
  begin_write_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementEndWriteDataCallCount() {
  MutexLocker locker(&mutex_);
  end_write_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementReadDataCallCount() {
  MutexLocker locker(&mutex_);
  read_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementBeginReadDataCallCount() {
  MutexLocker locker(&mutex_);
  begin_read_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementEndReadDataCallCount() {
  MutexLocker locker(&mutex_);
  end_read_data_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementDuplicateBufferHandleCallCount() {
  MutexLocker locker(&mutex_);
  duplicate_buffer_handle_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementGetBufferInformationCallCount() {
  MutexLocker locker(&mutex_);
  get_buffer_information_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementMapBufferCallCount() {
  MutexLocker locker(&mutex_);
  map_buffer_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementAddAwakableCallCount() {
  MutexLocker locker(&mutex_);
  add_awakable_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementRemoveAwakableCallCount() {
  MutexLocker locker(&mutex_);
  remove_awakable_call_count_++;
}

void CoreTestBase_MockHandleInfo::IncrementCancelAllAwakablesCallCount() {
  MutexLocker locker(&mutex_);
  cancel_all_awakables_call_count_++;
}

void CoreTestBase_MockHandleInfo::AllowAddAwakable(bool alllow) {
  MutexLocker locker(&mutex_);
  add_awakable_allowed_ = alllow;
}

bool CoreTestBase_MockHandleInfo::IsAddAwakableAllowed() const {
  MutexLocker locker(&mutex_);
  return add_awakable_allowed_;
}

void CoreTestBase_MockHandleInfo::AwakableWasAdded(Awakable* awakable) {
  MutexLocker locker(&mutex_);
  added_awakables_.push_back(awakable);
}

}  // namespace test
}  // namespace system
}  // namespace mojo

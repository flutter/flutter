// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CORE_TEST_BASE_H_
#define MOJO_EDK_SYSTEM_CORE_TEST_BASE_H_

#include <memory>

#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace system {

class Core;
class Awakable;

namespace test {

class CoreTestBase_MockHandleInfo;

class CoreTestBase : public testing::Test {
 public:
  using MockHandleInfo = CoreTestBase_MockHandleInfo;

  static constexpr MojoHandleRights kDefaultMockHandleRights =
      MOJO_HANDLE_RIGHT_DUPLICATE | MOJO_HANDLE_RIGHT_TRANSFER |
      MOJO_HANDLE_RIGHT_READ | MOJO_HANDLE_RIGHT_WRITE |
      MOJO_HANDLE_RIGHT_GET_OPTIONS | MOJO_HANDLE_RIGHT_SET_OPTIONS |
      MOJO_HANDLE_RIGHT_MAP_READABLE | MOJO_HANDLE_RIGHT_MAP_WRITABLE |
      MOJO_HANDLE_RIGHT_MAP_EXECUTABLE;

  CoreTestBase();
  ~CoreTestBase() override;

  void SetUp() override;
  void TearDown() override;

 protected:
  // |info| must remain alive until the returned handle and any handles
  // duplicated from it are closed.
  MojoHandle CreateMockHandle(MockHandleInfo* info);

  Core* core() { return core_.get(); }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  std::unique_ptr<Core> core_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(CoreTestBase);
};

class CoreTestBase_MockHandleInfo {
 public:
  CoreTestBase_MockHandleInfo();
  ~CoreTestBase_MockHandleInfo();

  unsigned GetCtorCallCount() const;
  unsigned GetDtorCallCount() const;
  unsigned GetCloseCallCount() const;
  unsigned GetDuplicateDispatcherCallCount() const;
  unsigned GetWriteMessageCallCount() const;
  unsigned GetReadMessageCallCount() const;
  unsigned GetWriteDataCallCount() const;
  unsigned GetBeginWriteDataCallCount() const;
  unsigned GetEndWriteDataCallCount() const;
  unsigned GetReadDataCallCount() const;
  unsigned GetBeginReadDataCallCount() const;
  unsigned GetEndReadDataCallCount() const;
  unsigned GetDuplicateBufferHandleCallCount() const;
  unsigned GetGetBufferInformationCallCount() const;
  unsigned GetMapBufferCallCount() const;
  unsigned GetAddAwakableCallCount() const;
  unsigned GetRemoveAwakableCallCount() const;
  unsigned GetCancelAllStateCallCount() const;

  size_t GetAddedAwakableSize() const;
  Awakable* GetAddedAwakableAt(unsigned i) const;

  // For use by |MockDispatcher|:
  void IncrementCtorCallCount();
  void IncrementDtorCallCount();
  void IncrementCloseCallCount();
  void IncrementDuplicateDispatcherCallCount();
  void IncrementWriteMessageCallCount();
  void IncrementReadMessageCallCount();
  void IncrementWriteDataCallCount();
  void IncrementBeginWriteDataCallCount();
  void IncrementEndWriteDataCallCount();
  void IncrementReadDataCallCount();
  void IncrementBeginReadDataCallCount();
  void IncrementEndReadDataCallCount();
  void IncrementDuplicateBufferHandleCallCount();
  void IncrementGetBufferInformationCallCount();
  void IncrementMapBufferCallCount();
  void IncrementAddAwakableCallCount();
  void IncrementRemoveAwakableCallCount();
  void IncrementCancelAllStateCallCount();

  void AllowAddAwakable(bool alllow);
  bool IsAddAwakableAllowed() const;
  void AwakableWasAdded(Awakable*);

 private:
  mutable util::Mutex mutex_;
  unsigned ctor_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned dtor_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned close_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned duplicate_dispatcher_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned write_message_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned read_message_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned write_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned begin_write_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned end_write_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned read_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned begin_read_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned end_read_data_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned duplicate_buffer_handle_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned get_buffer_information_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned map_buffer_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned add_awakable_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned remove_awakable_call_count_ MOJO_GUARDED_BY(mutex_) = 0;
  unsigned cancel_all_awakables_call_count_ MOJO_GUARDED_BY(mutex_) = 0;

  bool add_awakable_allowed_ MOJO_GUARDED_BY(mutex_) = false;
  std::vector<Awakable*> added_awakables_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(CoreTestBase_MockHandleInfo);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CORE_TEST_BASE_H_

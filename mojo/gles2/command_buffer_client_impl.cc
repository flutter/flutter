// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gles2/command_buffer_client_impl.h"

#include <limits>

#include "base/logging.h"
#include "base/process/process_handle.h"
#include "services/gles2/command_buffer_type_conversions.h"
#include "services/gles2/mojo_buffer_backing.h"

namespace gles2 {

namespace {

bool CreateMapAndDupSharedBuffer(size_t size,
                                 void** memory,
                                 mojo::ScopedSharedBufferHandle* handle,
                                 mojo::ScopedSharedBufferHandle* duped) {
  MojoResult result = mojo::CreateSharedBuffer(NULL, size, handle);
  if (result != MOJO_RESULT_OK)
    return false;
  DCHECK(handle->is_valid());

  result = mojo::DuplicateBuffer(handle->get(), NULL, duped);
  if (result != MOJO_RESULT_OK)
    return false;
  DCHECK(duped->is_valid());

  result = mojo::MapBuffer(
      handle->get(), 0, size, memory, MOJO_MAP_BUFFER_FLAG_NONE);
  if (result != MOJO_RESULT_OK)
    return false;
  DCHECK(*memory);

  return true;
}

}  // namespace

CommandBufferDelegate::~CommandBufferDelegate() {}

void CommandBufferDelegate::ContextLost() {}

class CommandBufferClientImpl::SyncClientImpl
    : public mojo::CommandBufferSyncClient {
 public:
  SyncClientImpl(mojo::CommandBufferSyncClientPtr* ptr,
                 const MojoAsyncWaiter* async_waiter)
      : initialized_successfully_(false), binding_(this, ptr, async_waiter) {}

  bool WaitForInitialization() {
    if (!binding_.WaitForIncomingMethodCall())
      return false;
    return initialized_successfully_;
  }

  mojo::CommandBufferStatePtr WaitForProgress() {
    if (!binding_.WaitForIncomingMethodCall())
      return mojo::CommandBufferStatePtr();
    return command_buffer_state_.Pass();
  }

  gpu::Capabilities GetCapabilities() {
    return capabilities_.To<gpu::Capabilities>();
  }

 private:
  // CommandBufferSyncClient methods:
  void DidInitialize(bool success,
                     mojo::GpuCapabilitiesPtr capabilities) override {
    initialized_successfully_ = success;
    capabilities_ = capabilities.Pass();
  }
  void DidMakeProgress(mojo::CommandBufferStatePtr state) override {
    command_buffer_state_ = state.Pass();
  }

  bool initialized_successfully_;
  mojo::GpuCapabilitiesPtr capabilities_;
  mojo::CommandBufferStatePtr command_buffer_state_;
  mojo::Binding<mojo::CommandBufferSyncClient> binding_;

  DISALLOW_COPY_AND_ASSIGN(SyncClientImpl);
};

class CommandBufferClientImpl::SyncPointClientImpl
    : public mojo::CommandBufferSyncPointClient {
 public:
  SyncPointClientImpl(mojo::CommandBufferSyncPointClientPtr* ptr,
                      const MojoAsyncWaiter* async_waiter)
      : sync_point_(0u), binding_(this, ptr, async_waiter) {}

  uint32_t WaitForInsertSyncPoint() {
    if (!binding_.WaitForIncomingMethodCall())
      return 0u;
    uint32_t result = sync_point_;
    sync_point_ = 0u;
    return result;
  }

 private:
  void DidInsertSyncPoint(uint32_t sync_point) override {
    sync_point_ = sync_point;
  }

  uint32_t sync_point_;

  mojo::Binding<mojo::CommandBufferSyncPointClient> binding_;
};

CommandBufferClientImpl::CommandBufferClientImpl(
    CommandBufferDelegate* delegate,
    const MojoAsyncWaiter* async_waiter,
    mojo::ScopedMessagePipeHandle command_buffer_handle)
    : delegate_(delegate),
      observer_binding_(this),
      shared_state_(NULL),
      last_put_offset_(-1),
      next_transfer_buffer_id_(0),
      async_waiter_(async_waiter) {
  command_buffer_.Bind(
      mojo::InterfacePtrInfo<mojo::CommandBuffer>(command_buffer_handle.Pass(),
                                                  0u),
      async_waiter);
  command_buffer_.set_connection_error_handler(
      [this]() { DidLoseContext(gpu::error::kUnknown); });
}

CommandBufferClientImpl::~CommandBufferClientImpl() {}

bool CommandBufferClientImpl::Initialize() {
  const size_t kSharedStateSize = sizeof(gpu::CommandBufferSharedState);
  void* memory = NULL;
  mojo::ScopedSharedBufferHandle duped;
  bool result = CreateMapAndDupSharedBuffer(
      kSharedStateSize, &memory, &shared_state_handle_, &duped);
  if (!result)
    return false;

  shared_state_ = static_cast<gpu::CommandBufferSharedState*>(memory);

  shared_state()->Initialize();

  mojo::CommandBufferSyncClientPtr sync_client;
  sync_client_impl_.reset(new SyncClientImpl(&sync_client, async_waiter_));

  mojo::CommandBufferSyncPointClientPtr sync_point_client;
  sync_point_client_impl_.reset(
      new SyncPointClientImpl(&sync_point_client, async_waiter_));

  mojo::CommandBufferLostContextObserverPtr observer_ptr;
  observer_binding_.Bind(GetProxy(&observer_ptr), async_waiter_);
  command_buffer_->Initialize(sync_client.Pass(),
                              sync_point_client.Pass(),
                              observer_ptr.Pass(),
                              duped.Pass());

  // Wait for DidInitialize to come on the sync client pipe.
  if (!sync_client_impl_->WaitForInitialization()) {
    VLOG(1) << "Channel encountered error while creating command buffer";
    return false;
  }
  capabilities_ = sync_client_impl_->GetCapabilities();
  return true;
}

gpu::CommandBuffer::State CommandBufferClientImpl::GetLastState() {
  return last_state_;
}

int32 CommandBufferClientImpl::GetLastToken() {
  TryUpdateState();
  return last_state_.token;
}

void CommandBufferClientImpl::Flush(int32 put_offset) {
  if (last_put_offset_ == put_offset)
    return;

  last_put_offset_ = put_offset;
  command_buffer_->Flush(put_offset);
}

void CommandBufferClientImpl::OrderingBarrier(int32_t put_offset) {
  // TODO(jamesr): Implement this more efficiently.
  Flush(put_offset);
}

void CommandBufferClientImpl::WaitForTokenInRange(int32 start, int32 end) {
  TryUpdateState();
  while (!InRange(start, end, last_state_.token) &&
         last_state_.error == gpu::error::kNoError) {
    MakeProgressAndUpdateState();
    TryUpdateState();
  }
}

void CommandBufferClientImpl::WaitForGetOffsetInRange(int32 start, int32 end) {
  TryUpdateState();
  while (!InRange(start, end, last_state_.get_offset) &&
         last_state_.error == gpu::error::kNoError) {
    MakeProgressAndUpdateState();
    TryUpdateState();
  }
}

void CommandBufferClientImpl::SetGetBuffer(int32 shm_id) {
  command_buffer_->SetGetBuffer(shm_id);
  last_put_offset_ = -1;
}

scoped_refptr<gpu::Buffer> CommandBufferClientImpl::CreateTransferBuffer(
    size_t size,
    int32* id) {
  if (size >= std::numeric_limits<uint32_t>::max())
    return NULL;

  void* memory = NULL;
  mojo::ScopedSharedBufferHandle handle;
  mojo::ScopedSharedBufferHandle duped;
  if (!CreateMapAndDupSharedBuffer(size, &memory, &handle, &duped))
    return NULL;

  *id = ++next_transfer_buffer_id_;

  command_buffer_->RegisterTransferBuffer(
      *id, duped.Pass(), static_cast<uint32_t>(size));

  scoped_ptr<gpu::BufferBacking> backing(
      new MojoBufferBacking(handle.Pass(), memory, size));
  scoped_refptr<gpu::Buffer> buffer(new gpu::Buffer(backing.Pass()));
  return buffer;
}

void CommandBufferClientImpl::DestroyTransferBuffer(int32 id) {
  command_buffer_->DestroyTransferBuffer(id);
}

gpu::Capabilities CommandBufferClientImpl::GetCapabilities() {
  return capabilities_;
}

int32_t CommandBufferClientImpl::CreateImage(ClientBuffer buffer,
                                             size_t width,
                                             size_t height,
                                             unsigned internalformat) {
  // TODO(piman)
  NOTIMPLEMENTED();
  return -1;
}

void CommandBufferClientImpl::DestroyImage(int32 id) {
  // TODO(piman)
  NOTIMPLEMENTED();
}

int32_t CommandBufferClientImpl::CreateGpuMemoryBufferImage(
    size_t width,
    size_t height,
    unsigned internalformat,
    unsigned usage) {
  // TODO(piman)
  NOTIMPLEMENTED();
  return -1;
}

uint32_t CommandBufferClientImpl::InsertSyncPoint() {
  command_buffer_->InsertSyncPoint(true);
  return sync_point_client_impl_->WaitForInsertSyncPoint();
}

uint32_t CommandBufferClientImpl::InsertFutureSyncPoint() {
  command_buffer_->InsertSyncPoint(false);
  return sync_point_client_impl_->WaitForInsertSyncPoint();
}

void CommandBufferClientImpl::RetireSyncPoint(uint32_t sync_point) {
  command_buffer_->RetireSyncPoint(sync_point);
}

void CommandBufferClientImpl::SignalSyncPoint(uint32_t sync_point,
                                              const base::Closure& callback) {
  // TODO(piman)
}

void CommandBufferClientImpl::SignalQuery(uint32_t query,
                                          const base::Closure& callback) {
  // TODO(piman)
  NOTIMPLEMENTED();
}

void CommandBufferClientImpl::SetSurfaceVisible(bool visible) {
  // TODO(piman)
  NOTIMPLEMENTED();
}

uint32_t CommandBufferClientImpl::CreateStreamTexture(uint32_t texture_id) {
  // TODO(piman)
  NOTIMPLEMENTED();
  return 0;
}

void CommandBufferClientImpl::DidLoseContext(int32_t lost_reason) {
  last_state_.error = gpu::error::kLostContext;
  last_state_.context_lost_reason =
      static_cast<gpu::error::ContextLostReason>(lost_reason);
  delegate_->ContextLost();
}

void CommandBufferClientImpl::TryUpdateState() {
  if (last_state_.error == gpu::error::kNoError)
    shared_state()->Read(&last_state_);
}

void CommandBufferClientImpl::MakeProgressAndUpdateState() {
  command_buffer_->MakeProgress(last_state_.get_offset);

  mojo::CommandBufferStatePtr state = sync_client_impl_->WaitForProgress();
  if (!state) {
    VLOG(1) << "Channel encountered error while waiting for command buffer";
    // TODO(piman): is it ok for this to re-enter?
    DidLoseContext(gpu::error::kUnknown);
    return;
  }

  if (state->generation - last_state_.generation < 0x80000000U)
    last_state_ = state.To<State>();
}

void CommandBufferClientImpl::SetLock(base::Lock* lock) {
}

}  // namespace gles2

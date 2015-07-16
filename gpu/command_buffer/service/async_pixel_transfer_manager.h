// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_H_

#include <set>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/containers/hash_tables.h"
#include "base/memory/linked_ptr.h"
#include "base/memory/ref_counted.h"
#include "gpu/command_buffer/service/texture_manager.h"
#include "gpu/gpu_export.h"

namespace gfx {
class GLContext;
}

namespace gpu {
class AsyncPixelTransferDelegate;
class AsyncMemoryParams;
struct AsyncTexImage2DParams;

class AsyncPixelTransferCompletionObserver
    : public base::RefCountedThreadSafe<AsyncPixelTransferCompletionObserver> {
 public:
  AsyncPixelTransferCompletionObserver();

  virtual void DidComplete(const AsyncMemoryParams& mem_params) = 0;

 protected:
  virtual ~AsyncPixelTransferCompletionObserver();

 private:
  friend class base::RefCountedThreadSafe<AsyncPixelTransferCompletionObserver>;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferCompletionObserver);
};

class GPU_EXPORT AsyncPixelTransferManager
    : public gles2::TextureManager::DestructionObserver {
 public:
  static AsyncPixelTransferManager* Create(gfx::GLContext* context);

  ~AsyncPixelTransferManager() override;

  void Initialize(gles2::TextureManager* texture_manager);

  virtual void BindCompletedAsyncTransfers() = 0;

  // There's no guarantee that callback will run on the caller thread.
  virtual void AsyncNotifyCompletion(
      const AsyncMemoryParams& mem_params,
      AsyncPixelTransferCompletionObserver* observer) = 0;

  virtual uint32 GetTextureUploadCount() = 0;
  virtual base::TimeDelta GetTotalTextureUploadTime() = 0;

  // ProcessMorePendingTransfers() will be called at a good time
  // to process a small amount of pending transfer work while
  // NeedsProcessMorePendingTransfers() returns true. Implementations
  // that can't dispatch work to separate threads should use
  // this to avoid blocking the caller thread inappropriately.
  virtual void ProcessMorePendingTransfers() = 0;
  virtual bool NeedsProcessMorePendingTransfers() = 0;

  // Wait for all AsyncTex(Sub)Image2D uploads to finish before returning.
  virtual void WaitAllAsyncTexImage2D() = 0;

  AsyncPixelTransferDelegate* CreatePixelTransferDelegate(
      gles2::TextureRef* ref,
      const AsyncTexImage2DParams& define_params);

  AsyncPixelTransferDelegate* GetPixelTransferDelegate(
      gles2::TextureRef* ref);

  void ClearPixelTransferDelegateForTest(gles2::TextureRef* ref);

  bool AsyncTransferIsInProgress(gles2::TextureRef* ref);

  // gles2::TextureRef::DestructionObserver implementation:
  void OnTextureManagerDestroying(gles2::TextureManager* manager) override;
  void OnTextureRefDestroying(gles2::TextureRef* texture) override;

 protected:
  AsyncPixelTransferManager();

 private:
  gles2::TextureManager* manager_;

  typedef base::hash_map<gles2::TextureRef*,
                         linked_ptr<AsyncPixelTransferDelegate> >
      TextureToDelegateMap;
  TextureToDelegateMap delegate_map_;

  // A factory method called by CreatePixelTransferDelegate that is overriden
  // by each implementation.
  virtual AsyncPixelTransferDelegate* CreatePixelTransferDelegateImpl(
      gles2::TextureRef* ref,
      const AsyncTexImage2DParams& define_params) = 0;

  DISALLOW_COPY_AND_ASSIGN(AsyncPixelTransferManager);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_ASYNC_PIXEL_TRANSFER_MANAGER_H_

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_H_

#include "base/memory/ref_counted.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class Texture;

// Manages resources scoped beyond the context or context group level.
class GPU_EXPORT MailboxManager : public base::RefCounted<MailboxManager> {
 public:
  // Look up the texture definition from the named mailbox.
  virtual Texture* ConsumeTexture(const Mailbox& mailbox) = 0;

  // Put the texture into the named mailbox.
  virtual void ProduceTexture(const Mailbox& mailbox, Texture* texture) = 0;

  // If |true| then Pull/PushTextureUpdates() needs to be called.
  virtual bool UsesSync() = 0;

  // Used to synchronize texture state across share groups.
  virtual void PushTextureUpdates(uint32 sync_point) = 0;
  virtual void PullTextureUpdates(uint32 sync_point) = 0;

  // Destroy any mailbox that reference the given texture.
  virtual void TextureDeleted(Texture* texture) = 0;

 protected:
  MailboxManager() {}
  virtual ~MailboxManager() {}

 private:
  friend class base::RefCounted<MailboxManager>;

  DISALLOW_COPY_AND_ASSIGN(MailboxManager);
};

}  // namespage gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_H_


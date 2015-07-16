// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_IMPL_H_
#define GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_IMPL_H_

#include <map>
#include <utility>

#include "base/memory/linked_ptr.h"
#include "base/memory/ref_counted.h"
#include "gpu/command_buffer/common/constants.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class Texture;
class TextureManager;

// Manages resources scoped beyond the context or context group level.
class GPU_EXPORT MailboxManagerImpl : public MailboxManager {
 public:
  MailboxManagerImpl();

  // MailboxManager implementation:
  Texture* ConsumeTexture(const Mailbox& mailbox) override;
  void ProduceTexture(const Mailbox& mailbox, Texture* texture) override;
  bool UsesSync() override;
  void PushTextureUpdates(uint32 sync_point) override {}
  void PullTextureUpdates(uint32 sync_point) override {}
  void TextureDeleted(Texture* texture) override;

 protected:
  ~MailboxManagerImpl() override;

 private:
  friend class base::RefCounted<MailboxManager>;

  void InsertTexture(const Mailbox& mailbox, Texture* texture);

  // This is a bidirectional map between mailbox and textures. We can have
  // multiple mailboxes per texture, but one texture per mailbox. We keep an
  // iterator in the MailboxToTextureMap to be able to manage changes to
  // the TextureToMailboxMap efficiently.
  typedef std::multimap<Texture*, Mailbox> TextureToMailboxMap;
  typedef std::map<Mailbox, TextureToMailboxMap::iterator>
      MailboxToTextureMap;

  MailboxToTextureMap mailbox_to_textures_;
  TextureToMailboxMap textures_to_mailboxes_;

  DISALLOW_COPY_AND_ASSIGN(MailboxManagerImpl);
};

}  // namespage gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_MAILBOX_MANAGER_IMPL_H_


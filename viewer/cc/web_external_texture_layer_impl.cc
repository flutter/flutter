// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_external_texture_layer_impl.h"

#include "sky/viewer/cc/web_external_bitmap_impl.h"
#include "sky/viewer/cc/web_layer_impl.h"
#include "cc/layers/texture_layer.h"
#include "cc/resources/resource_update_queue.h"
#include "cc/resources/single_release_callback.h"
#include "cc/resources/texture_mailbox.h"
#include "sky/engine/public/platform/WebExternalTextureLayerClient.h"
#include "sky/engine/public/platform/WebExternalTextureMailbox.h"
#include "sky/engine/public/platform/WebFloatRect.h"
#include "sky/engine/public/platform/WebGraphicsContext3D.h"
#include "sky/engine/public/platform/WebSize.h"
#include "third_party/khronos/GLES2/gl2.h"

using cc::TextureLayer;
using cc::ResourceUpdateQueue;

namespace sky_viewer_cc {

WebExternalTextureLayerImpl::WebExternalTextureLayerImpl(
    blink::WebExternalTextureLayerClient* client)
    : client_(client) {
  cc::TextureLayerClient* cc_client = client_ ? this : NULL;
  scoped_refptr<TextureLayer> layer = TextureLayer::CreateForMailbox(cc_client);
  layer->SetIsDrawable(true);
  layer_.reset(new WebLayerImpl(layer));
}

WebExternalTextureLayerImpl::~WebExternalTextureLayerImpl() {
  static_cast<TextureLayer*>(layer_->layer())->ClearClient();
}

blink::WebLayer* WebExternalTextureLayerImpl::layer() {
  return layer_.get();
}

void WebExternalTextureLayerImpl::clearTexture() {
  TextureLayer* layer = static_cast<TextureLayer*>(layer_->layer());
  layer->ClearTexture();
}

void WebExternalTextureLayerImpl::setOpaque(bool opaque) {
  static_cast<TextureLayer*>(layer_->layer())->SetContentsOpaque(opaque);
}

void WebExternalTextureLayerImpl::setPremultipliedAlpha(
    bool premultiplied_alpha) {
  static_cast<TextureLayer*>(layer_->layer())
      ->SetPremultipliedAlpha(premultiplied_alpha);
}

void WebExternalTextureLayerImpl::setBlendBackgroundColor(bool blend) {
  static_cast<TextureLayer*>(layer_->layer())->SetBlendBackgroundColor(blend);
}

void WebExternalTextureLayerImpl::setRateLimitContext(bool rate_limit) {
  static_cast<TextureLayer*>(layer_->layer())->SetRateLimitContext(rate_limit);
}

bool WebExternalTextureLayerImpl::PrepareTextureMailbox(
    cc::TextureMailbox* mailbox,
    scoped_ptr<cc::SingleReleaseCallback>* release_callback,
    bool use_shared_memory) {
  blink::WebExternalTextureMailbox client_mailbox;
  WebExternalBitmapImpl* bitmap = NULL;

  if (use_shared_memory)
    bitmap = AllocateBitmap();
  if (!client_->prepareMailbox(&client_mailbox, bitmap)) {
    if (bitmap)
      free_bitmaps_.push_back(bitmap);
    return false;
  }
  gpu::Mailbox name;
  name.SetName(client_mailbox.name);
  if (bitmap) {
    *mailbox = cc::TextureMailbox(bitmap->shared_memory(), bitmap->size());
  } else {
    *mailbox =
        cc::TextureMailbox(name, GL_TEXTURE_2D, client_mailbox.syncPoint);
  }
  mailbox->set_allow_overlay(client_mailbox.allowOverlay);

  if (mailbox->IsValid()) {
    *release_callback = cc::SingleReleaseCallback::Create(
        base::Bind(&WebExternalTextureLayerImpl::DidReleaseMailbox,
                   this->AsWeakPtr(),
                   client_mailbox,
                   bitmap));
  }

  return true;
}

WebExternalBitmapImpl* WebExternalTextureLayerImpl::AllocateBitmap() {
  if (!free_bitmaps_.empty()) {
    WebExternalBitmapImpl* result = free_bitmaps_.back();
    free_bitmaps_.weak_erase(free_bitmaps_.end() - 1);
    return result;
  }
  return new WebExternalBitmapImpl;
}

// static
void WebExternalTextureLayerImpl::DidReleaseMailbox(
    base::WeakPtr<WebExternalTextureLayerImpl> layer,
    const blink::WebExternalTextureMailbox& mailbox,
    WebExternalBitmapImpl* bitmap,
    unsigned sync_point,
    bool lost_resource) {
  DCHECK(layer);
  blink::WebExternalTextureMailbox available_mailbox;
  memcpy(available_mailbox.name, mailbox.name, sizeof(available_mailbox.name));
  available_mailbox.syncPoint = sync_point;
  if (bitmap)
    layer->free_bitmaps_.push_back(bitmap);
  layer->client_->mailboxReleased(available_mailbox, lost_resource);
}

}  // namespace sky_viewer_cc

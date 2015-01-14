// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/surface_holder.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "sky/compositor/surface_allocator.h"

namespace sky {

SurfaceHolder::Client::~Client() {
}

SurfaceHolder::SurfaceHolder(Client* client, mojo::Shell* shell)
    : client_(client), id_namespace_(0u), local_id_(0u), weak_factory_(this) {
  mojo::ServiceProviderPtr service_provider;
  shell->ConnectToApplication("mojo:surfaces_service",
                              mojo::GetProxy(&service_provider), nullptr);
  mojo::ConnectToService(service_provider.get(), &surface_);
  surface_.set_client(this);
}

SurfaceHolder::~SurfaceHolder() {
  if (local_id_ != 0u)
    surface_->DestroySurface(local_id_);
}

void SurfaceHolder::SubmitFrame(mojo::FramePtr frame,
                                const base::Closure& callback) {
  surface_->SubmitFrame(local_id_, frame.Pass(), callback);
}

void SurfaceHolder::SetSize(const gfx::Size& size) {
  if (local_id_ != 0u && size_ == size)
    return;

  if (local_id_ != 0u)
    surface_->DestroySurface(local_id_);

  local_id_++;
  surface_->CreateSurface(local_id_);
  size_ = size;

  if (id_namespace_ != 0u)
    SetQualifiedId();
}

void SurfaceHolder::SetQualifiedId() {
  auto qualified_id = mojo::SurfaceId::New();
  qualified_id->id_namespace = id_namespace_;
  qualified_id->local = local_id_;
  client_->OnSurfaceIdAvailable(qualified_id.Pass());
}

void SurfaceHolder::SetIdNamespace(uint32_t id_namespace) {
  id_namespace_ = id_namespace;
  if (local_id_ != 0u)
    SetQualifiedId();
}

void SurfaceHolder::ReturnResources(
    mojo::Array<mojo::ReturnedResourcePtr> resources) {
  // TODO(abarth): The surface service shouldn't spam us with empty calls.
  if (!resources.size())
    return;
  client_->ReturnResources(resources.Pass());
}

}  // namespace sky

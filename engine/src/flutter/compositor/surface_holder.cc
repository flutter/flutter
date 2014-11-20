// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/surface_holder.h"

#include "base/bind.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "sky/compositor/surface_allocator.h"

namespace sky {

SurfaceHolder::Client::~Client() {
}

SurfaceHolder::SurfaceHolder(Client* client, mojo::Shell* shell)
    : client_(client), weak_factory_(this) {
  mojo::ServiceProviderPtr service_provider;
  shell->ConnectToApplication("mojo:surfaces_service",
                              mojo::GetProxy(&service_provider));
  mojo::ConnectToService(service_provider.get(), &surfaces_service_);

  surfaces_service_->CreateSurfaceConnection(base::Bind(
      &SurfaceHolder::OnSurfaceConnectionCreated, weak_factory_.GetWeakPtr()));
}

SurfaceHolder::~SurfaceHolder() {
  if (surface_id_)
    surface_->DestroySurface(surface_id_.Clone());
}

void SurfaceHolder::SubmitFrame(mojo::FramePtr frame) {
  surface_->SubmitFrame(surface_id_.Clone(), frame.Pass());
}

void SurfaceHolder::SetSize(const gfx::Size& size) {
  if (surface_id_ && size_ == size)
    return;

  if (surface_id_) {
    surface_->DestroySurface(surface_id_.Clone());
  } else {
    surface_id_ = mojo::SurfaceId::New();
  }

  surface_id_->id = surface_allocator_->CreateSurfaceId();
  surface_->CreateSurface(surface_id_.Clone(), mojo::Size::From(size));
  size_ = size;

  client_->OnSurfaceIdAvailable(surface_id_.Clone());
}

void SurfaceHolder::ReturnResources(
    mojo::Array<mojo::ReturnedResourcePtr> resources) {
  // TODO(abarth): The surface service shouldn't spam us with empty calls.
  if (!resources.size())
    return;
  client_->ReturnResources(resources.Pass());
  client_->OnReadyForNextFrame();
}

void SurfaceHolder::OnSurfaceConnectionCreated(mojo::SurfacePtr surface,
                                               uint32_t id_namespace) {
  surface_ = surface.Pass();
  surface_.set_client(this);
  surface_allocator_.reset(new SurfaceAllocator(id_namespace));

  client_->OnReadyForNextFrame();
}

}  // namespace sky

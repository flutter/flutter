// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_SURFACE_HOLDER_H_
#define SKY_COMPOSITOR_SURFACE_HOLDER_H_

#include "base/callback_forward.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "mojo/services/surfaces/public/interfaces/surface_id.mojom.h"
#include "mojo/services/surfaces/public/interfaces/surfaces.mojom.h"
#include "ui/gfx/geometry/rect.h"

namespace mojo {
class Shell;
}

namespace sky {
class SurfaceAllocator;

class SurfaceHolder : public mojo::ResourceReturner {
 public:
  class Client {
   public:
    virtual void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) = 0;
    virtual void ReturnResources(
        mojo::Array<mojo::ReturnedResourcePtr> resources) = 0;

   protected:
    virtual ~Client();
  };

  explicit SurfaceHolder(Client* client, mojo::Shell* shell);
  ~SurfaceHolder() override;

  void SetSize(const gfx::Size& size);
  void SubmitFrame(mojo::FramePtr frame, const base::Closure& callback);

 private:
  // mojo::ResourceReturner
  void ReturnResources(
      mojo::Array<mojo::ReturnedResourcePtr> resources) override;

  void SetIdNamespace(uint32_t id_namespace);
  void SetQualifiedId();

  Client* client_;
  gfx::Size size_;
  uint32_t id_namespace_;
  uint32_t local_id_;
  mojo::SurfacePtr surface_;
  mojo::Binding<mojo::ResourceReturner> returner_binding_;

  base::WeakPtrFactory<SurfaceHolder> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SurfaceHolder);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_SURFACE_HOLDER_H_

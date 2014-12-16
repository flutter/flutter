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
#include "mojo/services/surfaces/public/interfaces/surfaces_service.mojom.h"
#include "ui/gfx/geometry/rect.h"

namespace mojo {
class Shell;
}

namespace sky {
class SurfaceAllocator;

class SurfaceHolder : public mojo::SurfaceClient {
 public:
  class Client {
   public:
    virtual void OnSurfaceConnectionCreated() = 0;
    virtual void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) = 0;
    virtual void ReturnResources(
        mojo::Array<mojo::ReturnedResourcePtr> resources) = 0;

   protected:
    virtual ~Client();
  };

  explicit SurfaceHolder(Client* client, mojo::Shell* shell);
  ~SurfaceHolder() override;

  bool IsReadyForFrame() const;

  void SetSize(const gfx::Size& size);
  void SubmitFrame(mojo::FramePtr frame, const base::Closure& callback);

 private:
  // mojo::SurfaceClient
  void SetIdNamespace(uint32_t id_namespace) override;
  void ReturnResources(
      mojo::Array<mojo::ReturnedResourcePtr> resources) override;

  void OnSurfaceConnectionCreated(mojo::SurfacePtr surface,
                                  uint32_t id_namespace);

  Client* client_;
  gfx::Size size_;
  scoped_ptr<SurfaceAllocator> surface_allocator_;
  mojo::SurfacesServicePtr surfaces_service_;
  mojo::SurfacePtr surface_;
  mojo::SurfaceIdPtr surface_id_;

  base::WeakPtrFactory<SurfaceHolder> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SurfaceHolder);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_SURFACE_HOLDER_H_

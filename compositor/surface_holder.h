// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_SURFACE_HOLDER_H_
#define SKY_COMPOSITOR_SURFACE_HOLDER_H_

#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "mojo/services/public/interfaces/surfaces/surface_id.mojom.h"
#include "mojo/services/public/interfaces/surfaces/surfaces.mojom.h"
#include "mojo/services/public/interfaces/surfaces/surfaces_service.mojom.h"
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
    virtual void OnReadyForNextFrame() = 0;
    virtual void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) = 0;
    virtual void ReturnResources(
        mojo::Array<mojo::ReturnedResourcePtr> resources) = 0;

   protected:
    virtual ~Client();
  };

  explicit SurfaceHolder(Client* client, mojo::Shell* shell);
  ~SurfaceHolder() override;

  void SetSize(const gfx::Size& size);
  void SubmitFrame(mojo::FramePtr frame);

 private:
  // mojo::SurfaceClient
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

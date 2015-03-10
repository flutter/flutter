// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_HOST_H_
#define SKY_COMPOSITOR_LAYER_HOST_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "mojo/gpu/gl_context_owner.h"
#include "mojo/skia/ganesh_context.h"
#include "sky/compositor/layer_host_client.h"
#include "sky/compositor/resource_manager.h"
#include "sky/compositor/surface_holder.h"

namespace sky {
class ResourceManager;
class Layer;
class LayerHostClient;

class LayerHost : public SurfaceHolder::Client {
 public:
  explicit LayerHost(LayerHostClient* client);
  ~LayerHost() override;

  LayerHostClient* client() const { return client_; }

  const base::WeakPtr<mojo::GLContext>& gl_context() const {
    return gl_context_owner_.context();
  }

  mojo::GaneshContext* ganesh_context() const {
    return const_cast<mojo::GaneshContext*>(&ganesh_context_);
  }

  ResourceManager* resource_manager() const {
    return const_cast<ResourceManager*>(&resource_manager_);
  }

  void SetNeedsAnimate();
  void SetRootLayer(scoped_refptr<Layer> layer);

 private:
  enum State {
    kReadyForFrame,
    kWaitingForFrameAcknowldgement,
  };

  // SurfaceHolder::Client
  void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) override;
  void ReturnResources(
      mojo::Array<mojo::ReturnedResourcePtr> resources) override;

  void BeginFrameSoon();
  void BeginFrame();

  void Upload(Layer* layer);
  void DidCompleteFrame();

  LayerHostClient* client_;
  State state_;
  bool frame_requested_;
  SurfaceHolder surface_holder_;
  mojo::GLContextOwner gl_context_owner_;
  mojo::GaneshContext ganesh_context_;
  ResourceManager resource_manager_;
  scoped_refptr<Layer> root_layer_;

  base::WeakPtrFactory<LayerHost> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(LayerHost);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_HOST_H_

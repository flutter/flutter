// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_HOST_H_
#define SKY_COMPOSITOR_LAYER_HOST_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/skia/ganesh_context.h"
#include "sky/compositor/layer_host_client.h"
#include "sky/compositor/resource_manager.h"
#include "sky/compositor/surface_holder.h"
#include "sky/scheduler/scheduler.h"

namespace sky {
class ResourceManager;
class Layer;
class LayerHostClient;

class LayerHost : public SurfaceHolder::Client, public Scheduler::Client {
 public:
  explicit LayerHost(LayerHostClient* client);
  ~LayerHost();

  LayerHostClient* client() const { return client_; }

  const base::WeakPtr<mojo::GLContext>& gl_context() const {
    return gl_context_;
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
    kIdle,
    kWaitingForBeginFrame,
    kProducingFrame,
    kWaitingForSurfaceToUploadFrame,
  };

  // SurfaceHolder::Client
  void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) override;
  void ReturnResources(
      mojo::Array<mojo::ReturnedResourcePtr> resources) override;

  // Scheduler::Client
  void BeginFrame(base::TimeTicks frame_time,
                  base::TimeTicks deadline) override;

  void Upload(Layer* layer);

  LayerHostClient* client_;
  State state_;
  SurfaceHolder surface_holder_;
  base::WeakPtr<mojo::GLContext> gl_context_;
  mojo::GaneshContext ganesh_context_;
  ResourceManager resource_manager_;
  Scheduler scheduler_;

  scoped_refptr<Layer> root_layer_;

  DISALLOW_COPY_AND_ASSIGN(LayerHost);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_HOST_H_

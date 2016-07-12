// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

#include <MGL/mgl_echo.h>

#include "base/trace_event/trace_event.h"
#include "mojo/gpu/gl_texture.h"
#include "mojo/skia/ganesh_texture_surface.h"
#include "sky/shell/shell.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {
namespace shell {
namespace {

void DidEcho(void* context) {
  TRACE_EVENT_ASYNC_END0("flutter", "MGLEcho", context);
  Rasterizer::DrawCallback* callback =
      static_cast<Rasterizer::DrawCallback*>(context);
  callback->Run();
  delete callback;
}

}  // namespace

const uint32_t kContentImageResourceId = 1;
const uint32_t kRootNodeId = mojo::gfx::composition::kSceneRootNodeId;

std::unique_ptr<Rasterizer> Rasterizer::Create() {
  return std::unique_ptr<Rasterizer>(new RasterizerMojo());
}

RasterizerMojo::RasterizerMojo() : binding_(this), weak_factory_(this) {}

RasterizerMojo::~RasterizerMojo() {
  weak_factory_.InvalidateWeakPtrs();
  Shell::Shared().PurgeRasterizers();
}

base::WeakPtr<Rasterizer> RasterizerMojo::GetWeakRasterizerPtr() {
  return weak_factory_.GetWeakPtr();
}

void RasterizerMojo::ConnectToRasterizer(
    mojo::InterfaceRequest<rasterizer::Rasterizer> request) {
  binding_.Bind(request.Pass());

  Shell::Shared().AddRasterizer(GetWeakRasterizerPtr());
}

void RasterizerMojo::Init(mojo::ApplicationConnectorPtr connector,
                          mojo::gfx::composition::ScenePtr scene) {
  gl_state_.reset(new GLState(connector.get()));
  scene_ = scene.Pass();
}

void RasterizerMojo::Setup(PlatformView* platform_view,
                           base::Closure rasterizer_continuation,
                           base::WaitableEvent* setup_completion_event) {
  rasterizer_continuation.Run();
  setup_completion_event->Signal();
}

void RasterizerMojo::Teardown(base::WaitableEvent* teardown_completion_event) {
  teardown_completion_event->Signal();
}

void RasterizerMojo::Draw(uint64_t layer_tree_ptr,
                          const DrawCallback& callback) {
  TRACE_EVENT0("flutter", "RasterizerMojo::Draw");

  std::unique_ptr<flow::LayerTree> layer_tree(
      reinterpret_cast<flow::LayerTree*>(layer_tree_ptr));

  if (!scene_ || !gl_state_ || gl_state_->gl_context->is_lost()) {
    TRACE_EVENT_INSTANT0("flutter", "RasterizerMojo::Draw error one",
                         TRACE_EVENT_SCOPE_THREAD);
    callback.Run();
    return;
  }

  mojo::Size size;
  size.width = layer_tree->frame_size().width();
  size.height = layer_tree->frame_size().height();

  if (size.width <= 0 || size.height <= 0.0) {
    TRACE_EVENT_INSTANT0("flutter", "RasterizerMojo::Draw empty frame size",
                         TRACE_EVENT_SCOPE_THREAD);
    callback.Run();
    return;
  }

  compositor_context_.engine_time().SetLapTime(layer_tree->construction_time());

  std::unique_ptr<mojo::GLTexture> texture =
      gl_state_->gl_texture_recycler.GetTexture(size);
  DCHECK(texture);

  {
    mojo::skia::GaneshContext::Scope scope(gl_state_->ganesh_context);
    mojo::skia::GaneshTextureSurface texture_surface(scope, std::move(texture));

    SkCanvas* canvas = texture_surface.canvas();
    flow::CompositorContext::ScopedFrame frame =
        compositor_context_.AcquireFrame(scope.gr_context().get(), *canvas);
    canvas->clear(SK_ColorBLACK);
    layer_tree->Raster(frame);

    texture = texture_surface.TakeTexture();
  }

  mojo::gfx::composition::ResourcePtr resource =
      gl_state_->gl_texture_recycler.BindTextureResource(std::move(texture));
  DCHECK(resource);

  auto update = mojo::gfx::composition::SceneUpdate::New();
  update->clear_resources = true;
  update->clear_nodes = true;
  update->resources.insert(kContentImageResourceId, resource.Pass());

  auto root_node = mojo::gfx::composition::Node::New();
  root_node->op = mojo::gfx::composition::NodeOp::New();
  root_node->op->set_image(mojo::gfx::composition::ImageNodeOp::New());
  root_node->op->get_image()->content_rect = mojo::RectF::New();
  root_node->op->get_image()->content_rect->width = size.width;
  root_node->op->get_image()->content_rect->height = size.height;
  root_node->op->get_image()->image_resource_id = kContentImageResourceId;
  root_node->hit_test_behavior = mojo::gfx::composition::HitTestBehavior::New();
  root_node->combinator = mojo::gfx::composition::Node::Combinator::MERGE;
  layer_tree->UpdateScene(update.get(), root_node.get());

  update->nodes.insert(kRootNodeId, root_node.Pass());
  scene_->Update(update.Pass());
  auto metadata = mojo::gfx::composition::SceneMetadata::New();
  metadata->version = layer_tree->scene_version();
  scene_->Publish(metadata.Pass());

  last_layer_tree_ = std::move(layer_tree);

  // Ask MGL to ack these commands so that we know we're not getting too far
  // ahead. Ideally Mozart would help us coordinate with the other views.
  DrawCallback* context = new DrawCallback();
  *context = callback;
  TRACE_EVENT_ASYNC_BEGIN0("flutter", "MGLEcho", context);
  mojo::GLContext::Scope scope(gl_state_->gl_context);
  MGLEcho(DidEcho, context);
}

flow::LayerTree* RasterizerMojo::GetLastLayerTree() {
  return last_layer_tree_.get();
}

RasterizerMojo::GLState::GLState(mojo::ApplicationConnector* connector)
    : gl_context(mojo::GLContext::CreateOffscreen(connector)),
      gl_texture_recycler(gl_context),
      ganesh_context(new mojo::skia::GaneshContext(gl_context)) {}

RasterizerMojo::GLState::~GLState() {}

}  // namespace shell
}  // namespace sky

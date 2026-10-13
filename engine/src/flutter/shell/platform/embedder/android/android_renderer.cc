// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/android/android_renderer.h"

#include <android/api-level.h>
#include <android/native_window.h>

#include <cstddef>
#include <memory>
#include <utility>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/shell/platform/embedder/android/android_context_dynamic_impeller.h"
#include "flutter/shell/platform/embedder/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/embedder/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/embedder/android/android_surface_dynamic_impeller.h"
#include "flutter/shell/platform/embedder/android/android_surface_gl_impeller.h"
#include "flutter/shell/platform/embedder/android/external_view_embedder/external_view_embedder_wrapper.h"

#if !SLIMPELLER
#include "flutter/shell/platform/embedder/android/android_context_gl_skia.h"
#include "flutter/shell/platform/embedder/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/embedder/android/android_surface_software.h"
#endif  // !SLIMPELLER

#if IMPELLER_ENABLE_VULKAN  // b/258506856 for why this is behind an if
#include "flutter/shell/platform/embedder/android/android_surface_vk_impeller.h"
#endif

namespace flutter {

namespace {

static constexpr int kMinAPILevelHCPP = 34;

AndroidContext::ContextSettings CreateContextSettings(
    const Settings& p_settings) {
  AndroidContext::ContextSettings settings;
  settings.enable_gpu_tracing = p_settings.enable_vulkan_gpu_tracing;
  settings.enable_validation = p_settings.enable_vulkan_validation;
  settings.enable_surface_control = p_settings.enable_surface_control;
  return settings;
}
}  // namespace

AndroidSurfaceFactoryImpl::AndroidSurfaceFactoryImpl(
    const std::shared_ptr<AndroidContext>& context,
    bool enable_impeller,
    bool lazy_shader_mode,
    CreateSurfaceTransaction create_transaction)
    : android_context_(context),
      enable_impeller_(enable_impeller),
      lazy_shader_mode_(lazy_shader_mode),
      create_transaction_(std::move(create_transaction)) {}

AndroidSurfaceFactoryImpl::~AndroidSurfaceFactoryImpl() = default;

std::unique_ptr<AndroidSurface> AndroidSurfaceFactoryImpl::CreateSurface() {
  if (android_context_->IsDynamicSelection()) {
    auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
        android_context_);
    return std::make_unique<AndroidSurfaceDynamicImpeller>(cast_ptr,
                                                           create_transaction_);
  }
  switch (android_context_->RenderingApi()) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_unique<AndroidSurfaceSoftware>();
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidSurfaceGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_));
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidSurfaceGLImpeller>(
          std::static_pointer_cast<AndroidContextGLImpeller>(android_context_));
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidSurfaceVKImpeller>(
          std::static_pointer_cast<AndroidContextVKImpeller>(android_context_),
          create_transaction_);
    case AndroidRenderingAPI::kImpellerAutoselect: {
      auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
          android_context_);
      return std::make_unique<AndroidSurfaceDynamicImpeller>(
          cast_ptr, create_transaction_);
    }
  }
  FML_UNREACHABLE();
}

static std::shared_ptr<flutter::AndroidContext> CreateAndroidContext(
    const flutter::TaskRunners& task_runners,
    AndroidRenderingAPI android_rendering_api,
    bool enable_opengl_gpu_tracing,
    const AndroidContext::ContextSettings& settings,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner) {
  switch (android_rendering_api) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidContextGLSkia>(
          fml::MakeRefCounted<AndroidEnvironmentGL>(),  //
          task_runners                                  //
      );
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidContextVKImpeller>(settings);
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidContextGLImpeller>(
          std::make_unique<impeller::egl::Display>(), enable_opengl_gpu_tracing,
          std::move(io_task_runner));
    case AndroidRenderingAPI::kImpellerAutoselect:
      // Determine if we're using GL or Vulkan.
      return std::make_unique<AndroidContextDynamicImpeller>(
          settings, std::move(io_task_runner));
  }
  FML_UNREACHABLE();
}

AndroidRenderer::AndroidRenderer(
    const TaskRunners& task_runners,
    const Settings& settings,
    AndroidRenderingAPI rendering_api,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner,
    CreateSurfaceTransaction create_transaction)
    : AndroidRenderer(task_runners,
                      settings,
                      CreateAndroidContext(task_runners,
                                           rendering_api,
                                           settings.enable_opengl_gpu_tracing,
                                           CreateContextSettings(settings),
                                           std::move(io_task_runner)),
                      std::move(create_transaction)) {}

AndroidRenderer::AndroidRenderer(
    const TaskRunners& task_runners,
    const Settings& settings,
    std::shared_ptr<AndroidContext> android_context,
    CreateSurfaceTransaction create_transaction)
    : task_runners_(task_runners),
      android_context_(std::move(android_context)) {
  if (android_context_) {
    FML_CHECK(android_context_->IsValid())
        << "Could not create surface from invalid Android context.";
    surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
        android_context_,                           //
        settings.enable_impeller,                   //
        settings.impeller_enable_lazy_shader_mode,  //
        std::move(create_transaction)               //
    );
    android_surface_ = surface_factory_->CreateSurface();
    android_meets_hcpp_criteria_ =
        settings.enable_surface_control &&
        android_get_device_api_level() >= kMinAPILevelHCPP &&
        settings.enable_impeller;
    FML_CHECK(android_surface_ && android_surface_->IsValid())
        << "Could not create an OpenGL, Vulkan or Software surface to set "
           "up "
           "rendering.";
  }
}

AndroidRenderer::~AndroidRenderer() = default;

bool AndroidRenderer::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (!android_surface_) {
    return false;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get(),
       native_window = std::move(native_window)]() {
        surface->TeardownOnScreenContext();
        surface->SetNativeWindow(native_window);
        latch.Signal();
      });
  latch.Wait();
  return true;
}

void AndroidRenderer::SwapNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  SetNativeWindow(std::move(native_window));
}

void AndroidRenderer::TeardownSurface() {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get()]() {
        surface->TeardownOnScreenContext();
        latch.Signal();
      });
  latch.Wait();
}

void AndroidRenderer::ResizeSurface(const DlISize& size) {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),  //
      [&latch, surface = android_surface_.get(), size]() {
        surface->OnScreenSurfaceResize(size);
        latch.Signal();
      });
  latch.Wait();
}

std::unique_ptr<Surface> AndroidRenderer::CreateRenderingSurface() {
  if (!android_surface_) {
    return nullptr;
  }
  return android_surface_->CreateGPUSurface(
      android_context_->GetMainSkiaContext().get());
}

std::unique_ptr<SnapshotSurfaceProducer>
AndroidRenderer::CreateSnapshotSurfaceProducer() {
  if (!android_surface_) {
    return nullptr;
  }
  return std::make_unique<AndroidSnapshotSurfaceProducer>(*android_surface_);
}

bool AndroidRenderer::MakeResourceContextCurrent() const {
  if (!android_surface_) {
    return false;
  }
  return android_surface_->ResourceContextMakeCurrent();
}

void AndroidRenderer::ReleaseResourceContext() const {
  if (android_surface_) {
    android_surface_->ResourceContextClearCurrent();
  }
}

std::shared_ptr<impeller::Context> AndroidRenderer::GetImpellerContext() const {
  if (android_surface_) {
    return android_surface_->GetImpellerContext();
  }
  return android_context_->GetImpellerContext();
}

bool AndroidRenderer::IsSurfaceControlEnabled() const {
  // This needs to know if we're actually using HCPP.
  return android_meets_hcpp_criteria_ &&
         android_context_->RenderingApi() ==
             AndroidRenderingAPI::kImpellerVulkan &&
         impeller::ContextVK::Cast(*android_context_->GetImpellerContext())
             .GetShouldEnableSurfaceControlSwapchain();
}

void AndroidRenderer::SetupImpellerContext() {
  android_context_->SetupImpellerContext();
  android_surface_->SetupImpellerSurface();
}

void AndroidRenderer::SetExternalViewEmbedderDelegate(
    std::shared_ptr<AndroidExternalViewEmbedderDelegate> delegate) {
  external_view_embedder_delegate_ = std::move(delegate);
}

namespace {

#define SAFE_COMPOSITOR_MEMBER(c, member, default_val)                     \
  (((c) != nullptr &&                                                      \
    (c)->struct_size >= offsetof(FlutterNativeWindowCompositor, member) +  \
                            sizeof(FlutterNativeWindowCompositor::member)) \
       ? (c)->member                                                       \
       : (default_val))

class PathReceiver final : public DlPathReceiver {
 public:
  PathReceiver(std::vector<FlutterPathVerb>& verbs,
               std::vector<FlutterPoint>& points,
               std::vector<double>& conic_weights)
      : verbs_(verbs), points_(points), conic_weights_(conic_weights) {}
  void MoveTo(const DlPoint& p2, bool) override {
    verbs_.push_back(kFlutterPathVerbMove);
    points_.push_back({p2.x, p2.y});
  }
  void LineTo(const DlPoint& p2) override {
    verbs_.push_back(kFlutterPathVerbLine);
    points_.push_back({p2.x, p2.y});
  }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    verbs_.push_back(kFlutterPathVerbQuad);
    points_.insert(points_.end(), {{cp.x, cp.y}, {p2.x, p2.y}});
  }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar weight) override {
    verbs_.push_back(kFlutterPathVerbConic);
    points_.insert(points_.end(), {{cp.x, cp.y}, {p2.x, p2.y}});
    conic_weights_.push_back(weight);
    return true;
  }
  void CubicTo(const DlPoint& c1,
               const DlPoint& c2,
               const DlPoint& p2) override {
    verbs_.push_back(kFlutterPathVerbCubic);
    points_.insert(points_.end(), {{c1.x, c1.y}, {c2.x, c2.y}, {p2.x, p2.y}});
  }
  void Close() override { verbs_.push_back(kFlutterPathVerbClose); }

 private:
  std::vector<FlutterPathVerb>& verbs_;
  std::vector<FlutterPoint>& points_;
  std::vector<double>& conic_weights_;
};

struct ConvertedPath {
  std::vector<FlutterPathVerb> verbs;
  std::vector<FlutterPoint> points;
  std::vector<double> conic_weights;
  FlutterPath path = {};
};

struct ConvertedMutations {
  std::vector<std::unique_ptr<ConvertedPath>> paths;
  std::vector<FlutterPlatformViewMutation> storage;
  std::vector<const FlutterPlatformViewMutation*> ptrs;
};

ConvertedMutations ConvertMutatorsStack(const MutatorsStack& mutators_stack) {
  ConvertedMutations out;
  for (auto it = mutators_stack.Begin(); it != mutators_stack.End(); ++it) {
    switch ((*it)->GetType()) {
      case MutatorType::kTransform: {
        const DlMatrix& m = (*it)->GetMatrix();
        FlutterPlatformViewMutation mut = {};
        mut.type = kFlutterPlatformViewMutationTypeTransformation;
        mut.transformation = {m.m[0],  m.m[4], m.m[12], m.m[1], m.m[5],
                              m.m[13], m.m[3], m.m[7],  m.m[15]};
        out.storage.push_back(mut);
        break;
      }
      case MutatorType::kClipRect: {
        const DlRect& r = (*it)->GetRect();
        FlutterPlatformViewMutation mut = {};
        mut.type = kFlutterPlatformViewMutationTypeClipRect;
        mut.clip_rect = {r.GetLeft(), r.GetTop(), r.GetRight(), r.GetBottom()};
        out.storage.push_back(mut);
        break;
      }
      case MutatorType::kClipRRect:
      case MutatorType::kClipRSE: {
        const DlRoundRect rr = (*it)->GetType() == MutatorType::kClipRRect
                                   ? (*it)->GetRRect()
                                   : (*it)->GetRSEApproximation();
        const DlRect& r = rr.GetBounds();
        const DlRoundingRadii& rad = rr.GetRadii();
        FlutterPlatformViewMutation mut = {};
        mut.type = kFlutterPlatformViewMutationTypeClipRoundedRect;
        mut.clip_rounded_rect = {
            {r.GetLeft(), r.GetTop(), r.GetRight(), r.GetBottom()},
            {rad.top_left.width, rad.top_left.height},
            {rad.top_right.width, rad.top_right.height},
            {rad.bottom_right.width, rad.bottom_right.height},
            {rad.bottom_left.width, rad.bottom_left.height}};
        out.storage.push_back(mut);
        break;
      }
      case MutatorType::kOpacity: {
        FlutterPlatformViewMutation mut = {};
        mut.type = kFlutterPlatformViewMutationTypeOpacity;
        mut.opacity = (*it)->GetAlphaFloat();
        out.storage.push_back(mut);
        break;
      }
      case MutatorType::kClipPath: {
        const DlPath& dl_path = (*it)->GetPath();
        auto holder = std::make_unique<ConvertedPath>();
        PathReceiver recv(holder->verbs, holder->points, holder->conic_weights);
        dl_path.Dispatch(recv);
        holder->path = {
            sizeof(FlutterPath),
            dl_path.GetFillType() == DlPathFillType::kOdd
                ? kFlutterPathFillTypeEvenOdd
                : kFlutterPathFillTypeNonZero,
            holder->verbs.size(),
            holder->verbs.empty() ? nullptr : holder->verbs.data(),
            holder->points.size(),
            holder->points.empty() ? nullptr : holder->points.data(),
            holder->conic_weights.size(),
            holder->conic_weights.empty() ? nullptr
                                          : holder->conic_weights.data()};
        FlutterPlatformViewMutation mut = {};
        mut.type = kFlutterPlatformViewMutationTypeClipPath;
        mut.clip_path = &holder->path;
        out.paths.push_back(std::move(holder));
        out.storage.push_back(mut);
        break;
      }
      case MutatorType::kBackdropFilter:
      case MutatorType::kBackdropClipRect:
      case MutatorType::kBackdropClipRRect:
      case MutatorType::kBackdropClipRSuperellipse:
      case MutatorType::kBackdropClipPath:
        break;
    }
  }
  out.ptrs.reserve(out.storage.size());
  for (const FlutterPlatformViewMutation& m : out.storage) {
    out.ptrs.push_back(&m);
  }
  return out;
}

class NativeWindowCompositorDelegate final
    : public AndroidExternalViewEmbedderDelegate {
 public:
  NativeWindowCompositorDelegate(const FlutterNativeWindowCompositor* c,
                                 void* fallback_user_data) {
    compositor_.struct_size = sizeof(FlutterNativeWindowCompositor);
    void* ud = SAFE_COMPOSITOR_MEMBER(c, user_data, nullptr);
    compositor_.user_data = ud != nullptr ? ud : fallback_user_data;
#define COPY_CB(field) \
  compositor_.field = SAFE_COMPOSITOR_MEMBER(c, field, nullptr)
    COPY_CB(begin_frame_callback);
    COPY_CB(end_frame_callback);
    COPY_CB(create_overlay_surface_callback);
    COPY_CB(destroy_overlay_surfaces_callback);
    COPY_CB(display_overlay_surface_callback);
    COPY_CB(display_platform_view_callback);
    COPY_CB(swap_transaction_callback);
    COPY_CB(create_overlay_surface2_callback);
    COPY_CB(destroy_overlay_surface2_callback);
    COPY_CB(end_frame2_callback);
    COPY_CB(show_overlay_surface2_callback);
    COPY_CB(hide_overlay_surface2_callback);
    COPY_CB(display_platform_view2_callback);
    COPY_CB(hide_platform_view2_callback);
    COPY_CB(maybe_resize_surface_view_callback);
#undef COPY_CB
  }

  void FlutterViewBeginFrame() override {
    CallVoid(compositor_.begin_frame_callback);
  }
  void FlutterViewEndFrame() override {
    CallVoid(compositor_.end_frame_callback);
  }
  std::unique_ptr<OverlayMetadata> FlutterViewCreateOverlaySurface() override {
    return InvokeCreateOverlay(compositor_.create_overlay_surface_callback);
  }
  void FlutterViewDestroyOverlaySurfaces() override {
    CallVoid(compositor_.destroy_overlay_surfaces_callback);
  }
  void FlutterViewDisplayOverlaySurface(int id,
                                        int x,
                                        int y,
                                        int w,
                                        int h) override {
    if (compositor_.display_overlay_surface_callback) {
      compositor_.display_overlay_surface_callback(compositor_.user_data, id, x,
                                                   y, w, h);
    }
  }
  void FlutterViewOnDisplayPlatformView(int id,
                                        int x,
                                        int y,
                                        int w,
                                        int h,
                                        int vw,
                                        int vh,
                                        MutatorsStack s) override {
    InvokeDisplayView(compositor_.display_platform_view_callback, id, x, y, w,
                      h, vw, vh, s);
  }
  void swapTransaction() override {
    CallVoid(compositor_.swap_transaction_callback);
  }
  std::unique_ptr<OverlayMetadata> createOverlaySurface2() override {
    return InvokeCreateOverlay(compositor_.create_overlay_surface2_callback);
  }
  void destroyOverlaySurface2() override {
    CallVoid(compositor_.destroy_overlay_surface2_callback);
  }
  void onEndFrame2() override { CallVoid(compositor_.end_frame2_callback); }
  void showOverlaySurface2() override {
    CallVoid(compositor_.show_overlay_surface2_callback);
  }
  void hideOverlaySurface2() override {
    CallVoid(compositor_.hide_overlay_surface2_callback);
  }
  void onDisplayPlatformView2(int32_t id,
                              int32_t x,
                              int32_t y,
                              int32_t w,
                              int32_t h,
                              int32_t vw,
                              int32_t vh,
                              MutatorsStack s) override {
    InvokeDisplayView(compositor_.display_platform_view2_callback, id, x, y, w,
                      h, vw, vh, s);
  }
  void hidePlatformView2(int32_t view_id) override {
    if (compositor_.hide_platform_view2_callback) {
      compositor_.hide_platform_view2_callback(compositor_.user_data, view_id);
    }
  }
  void MaybeResizeSurfaceView(int32_t width, int32_t height) const override {
    if (compositor_.maybe_resize_surface_view_callback) {
      compositor_.maybe_resize_surface_view_callback(compositor_.user_data,
                                                     width, height);
    }
  }

 private:
  void CallVoid(VoidCallback cb) const {
    if (cb) {
      cb(compositor_.user_data);
    }
  }
  using DisplayCallback =
      decltype(FlutterNativeWindowCompositor::display_platform_view_callback);

  void InvokeDisplayView(DisplayCallback cb,
                         int32_t id,
                         int32_t x,
                         int32_t y,
                         int32_t w,
                         int32_t h,
                         int32_t vw,
                         int32_t vh,
                         const MutatorsStack& s) const {
    if (!cb) {
      return;
    }
    ConvertedMutations converted = ConvertMutatorsStack(s);
    cb(compositor_.user_data, id, x, y, w, h, vw, vh,
       converted.ptrs.empty() ? nullptr : converted.ptrs.data(),
       converted.ptrs.size());
  }

  std::unique_ptr<OverlayMetadata> InvokeCreateOverlay(
      bool (*cb)(void*, FlutterNativeWindowOverlay*)) const {
    if (!cb) {
      return nullptr;
    }
    FlutterNativeWindowOverlay overlay = {sizeof(FlutterNativeWindowOverlay), 0,
                                          nullptr};
    if (!cb(compositor_.user_data, &overlay)) {
      return nullptr;
    }
    auto* raw = static_cast<ANativeWindow*>(overlay.window);
    if (raw != nullptr) {
      ANativeWindow_acquire(raw);
    }
    return std::make_unique<OverlayMetadata>(
        overlay.id, fml::MakeRefCounted<AndroidNativeWindow>(raw));
  }

  FlutterNativeWindowCompositor compositor_ = {};
};

#undef SAFE_COMPOSITOR_MEMBER

}  // namespace

std::shared_ptr<AndroidExternalViewEmbedderDelegate>
MakeNativeWindowCompositorDelegate(
    const FlutterNativeWindowCompositor* compositor,
    void* fallback_user_data) {
  if (compositor == nullptr) {
    return nullptr;
  }
  return std::make_shared<NativeWindowCompositorDelegate>(compositor,
                                                          fallback_user_data);
}

void AndroidRenderer::SetCompositor(
    const FlutterNativeWindowCompositor* compositor,
    void* fallback_user_data) {
  external_view_embedder_delegate_ =
      MakeNativeWindowCompositorDelegate(compositor, fallback_user_data);
}

std::shared_ptr<ExternalViewEmbedder>
AndroidRenderer::CreateExternalViewEmbedder() const {
  if (!android_context_ || !external_view_embedder_delegate_) {
    return nullptr;
  }
  return std::make_shared<AndroidExternalViewEmbedderWrapper>(
      android_meets_hcpp_criteria_, *android_context_,
      external_view_embedder_delegate_, surface_factory_, task_runners_);
}

}  // namespace flutter

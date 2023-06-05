// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/gfx_external_view_embedder.h"

#include <fuchsia/sysmem/cpp/fidl.h>
#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/async-testing/test_loop.h>
#include <lib/async/dispatcher.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/fidl/cpp/synchronous_interface_ptr.h>
#include <lib/inspect/cpp/inspect.h>
#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>

#include <algorithm>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"

#include "fakes/scenic/fake_resources.h"
#include "fakes/scenic/fake_session.h"
#include "flutter/shell/platform/fuchsia/flutter/surface_producer.h"

#include "gmock/gmock.h"  // For EXPECT_THAT and matchers
#include "gtest/gtest.h"

using fuchsia::scenic::scheduling::FramePresentedInfo;
using fuchsia::scenic::scheduling::FuturePresentationTimes;
using fuchsia::scenic::scheduling::PresentReceivedInfo;
using ::testing::_;
using ::testing::ElementsAre;
using ::testing::FieldsAre;
using ::testing::IsEmpty;
using ::testing::IsNull;
using ::testing::Matcher;
using ::testing::Pointee;
using ::testing::SizeIs;
using ::testing::VariantWith;

namespace flutter_runner::testing {
namespace {

class FakeSurfaceProducerSurface : public SurfaceProducerSurface {
 public:
  explicit FakeSurfaceProducerSurface(scenic::Session* session,
                                      const SkISize& size,
                                      uint32_t buffer_id)
      : session_(session),
        surface_(SkSurfaces::Null(size.width(), size.height())),
        buffer_id_(buffer_id) {
    FML_CHECK(session_);
    FML_CHECK(buffer_id_ != 0);

    fuchsia::sysmem::BufferCollectionTokenSyncPtr token;
    buffer_binding_ = token.NewRequest();

    image_id_ = session_->AllocResourceId();
    session_->RegisterBufferCollection(buffer_id_, std::move(token));
    session_->Enqueue(scenic::NewCreateImage2Cmd(
        image_id_, surface_->width(), surface_->height(), buffer_id_, 0));
  }
  ~FakeSurfaceProducerSurface() override {
    session_->DeregisterBufferCollection(buffer_id_);
    session_->Enqueue(scenic::NewReleaseResourceCmd(image_id_));
  }

  bool IsValid() const override { return true; }

  SkISize GetSize() const override {
    return SkISize::Make(surface_->width(), surface_->height());
  }

  void SetImageId(uint32_t image_id) override { FAIL(); }
  uint32_t GetImageId() override { return image_id_; }

  sk_sp<SkSurface> GetSkiaSurface() const override { return surface_; }

  fuchsia::ui::composition::BufferCollectionImportToken
  GetBufferCollectionImportToken() override {
    return fuchsia::ui::composition::BufferCollectionImportToken{};
  }

  zx::event GetAcquireFence() override { return zx::event{}; }

  zx::event GetReleaseFence() override { return zx::event{}; }

  void SetReleaseImageCallback(
      ReleaseImageCallback release_image_callback) override {}

  size_t AdvanceAndGetAge() override { return 0; }
  bool FlushSessionAcquireAndReleaseEvents() override { return true; }
  void SignalWritesFinished(
      const std::function<void(void)>& on_writes_committed) override {}

 private:
  scenic::Session* session_;

  sk_sp<SkSurface> surface_;

  fidl::InterfaceRequest<fuchsia::sysmem::BufferCollectionToken>
      buffer_binding_;
  FakeResourceId image_id_{kInvalidFakeResourceId};
  uint32_t buffer_id_{0};
};

class FakeSurfaceProducer : public SurfaceProducer {
 public:
  explicit FakeSurfaceProducer(scenic::Session* session) : session_(session) {}
  ~FakeSurfaceProducer() override = default;

  // |SurfaceProducer|
  GrDirectContext* gr_context() const override { return nullptr; }

  // |SurfaceProducer|
  std::unique_ptr<SurfaceProducerSurface> ProduceOffscreenSurface(
      const SkISize& size) override {
    return nullptr;
  }

  // |SurfaceProducer|
  std::unique_ptr<SurfaceProducerSurface> ProduceSurface(
      const SkISize& size) override {
    return std::make_unique<FakeSurfaceProducerSurface>(session_, size,
                                                        buffer_id_++);
  }

  // |SurfaceProducer|
  void SubmitSurfaces(
      std::vector<std::unique_ptr<SurfaceProducerSurface>> surfaces) override {}

 private:
  scenic::Session* session_;

  uint32_t buffer_id_{1};
};

std::string GetCurrentTestName() {
  return ::testing::UnitTest::GetInstance()->current_test_info()->name();
}

zx_koid_t GetKoid(zx_handle_t handle) {
  if (handle == ZX_HANDLE_INVALID) {
    return ZX_KOID_INVALID;
  }

  zx_info_handle_basic_t info;
  zx_status_t status = zx_object_get_info(handle, ZX_INFO_HANDLE_BASIC, &info,
                                          sizeof(info), nullptr, nullptr);
  return status == ZX_OK ? info.koid : ZX_KOID_INVALID;
}

zx_koid_t GetPeerKoid(zx_handle_t handle) {
  if (handle == ZX_HANDLE_INVALID) {
    return ZX_KOID_INVALID;
  }

  zx_info_handle_basic_t info;
  zx_status_t status = zx_object_get_info(handle, ZX_INFO_HANDLE_BASIC, &info,
                                          sizeof(info), nullptr, nullptr);
  return status == ZX_OK ? info.related_koid : ZX_KOID_INVALID;
}

MATCHER_P(MaybeIsEmpty, assert_empty, "") {
  return assert_empty ? ExplainMatchResult(IsEmpty(), arg, result_listener)
                      : ExplainMatchResult(_, arg, result_listener);
}

Matcher<FakeSceneGraph> IsEmptySceneGraph() {
  return FieldsAre(IsEmpty(), IsEmpty(), IsEmpty(), kInvalidFakeResourceId);
}

void AssertRootSceneGraph(const FakeSceneGraph& scene_graph,
                          bool assert_empty) {
  ASSERT_NE(scene_graph.root_view_id, kInvalidFakeResourceId);
  ASSERT_EQ(scene_graph.resource_map.count(scene_graph.root_view_id), 1u);
  auto scene_graph_root =
      scene_graph.resource_map.find(scene_graph.root_view_id);
  ASSERT_THAT(
      scene_graph_root->second,
      Pointee(FieldsAre(
          scene_graph.root_view_id, "", FakeResource::kDefaultEmptyEventMask,
          VariantWith<FakeView>(FieldsAre(
              _, _, _, _,
              ElementsAre(Pointee(FieldsAre(
                  _, "Flutter::MetricsWatcher",
                  fuchsia::ui::gfx::kMetricsEventMask,
                  VariantWith<FakeEntityNode>(FieldsAre(
                      FieldsAre(
                          ElementsAre(Pointee(FieldsAre(
                              _, "Flutter::LayerTree",
                              FakeResource::kDefaultEmptyEventMask,
                              VariantWith<FakeEntityNode>(FieldsAre(
                                  FieldsAre(MaybeIsEmpty(assert_empty),
                                            FakeNode::kDefaultZeroRotation,
                                            FakeNode::kDefaultOneScale,
                                            FakeNode::kDefaultZeroTranslation,
                                            FakeNode::kDefaultZeroAnchor,
                                            FakeNode::kIsHitTestable,
                                            FakeNode::kIsSemanticallyVisible),
                                  IsEmpty()))))),
                          FakeNode::kDefaultZeroRotation,
                          FakeNode::kDefaultOneScale,
                          FakeNode::kDefaultZeroTranslation,
                          FakeNode::kDefaultZeroAnchor,
                          FakeNode::kIsHitTestable,
                          FakeNode::kIsSemanticallyVisible),
                      IsEmpty()))))),
              FakeView::kDebugBoundsDisbaled)))));
}

void ExpectRootSceneGraph(
    const FakeSceneGraph& scene_graph,
    const std::string& debug_name,
    const fuchsia::ui::views::ViewHolderToken& view_holder_token,
    const fuchsia::ui::views::ViewRef& view_ref) {
  AssertRootSceneGraph(scene_graph, true);

  // These are safe to do unchecked due to `AssertRootSceneGraph` above.
  auto root_view_it = scene_graph.resource_map.find(scene_graph.root_view_id);
  auto* root_view_state = std::get_if<FakeView>(&root_view_it->second->state);
  EXPECT_EQ(root_view_state->token, GetPeerKoid(view_holder_token.value.get()));
  EXPECT_EQ(root_view_state->control_ref,
            GetPeerKoid(view_ref.reference.get()));
  EXPECT_EQ(root_view_state->view_ref, GetKoid(view_ref.reference.get()));
  EXPECT_EQ(root_view_state->debug_name, debug_name);
  EXPECT_EQ(scene_graph.resource_map.size(), 3u);
}

/// Verifies the scene subgraph for a particular flutter embedder layer.
///
/// ARGUMENTS
///
/// scenic_node: The root of the layer's scenic subgraph.
///
/// layer_size: The expected dimensions of the layer's image.
///
/// flutter_layer_index: This layer's 0-indexed position in the list of
/// flutter layers present in this frame, sorted in paint order.
///
/// paint_regions: List of non-overlapping rects, in canvas coordinate space,
/// where content was drawn. For each "paint region" present in the frame, the
/// embedder reports a corresponding "hit region" to scenic as a hittable
/// ShapeNode. ShapeNodes are centered at (0, 0), by default, so they must be
/// translated to match the locations of the corresopnding paint regions.
void ExpectImageCompositorLayer(const FakeResource& scenic_node,
                                const SkISize layer_size,
                                size_t flutter_layer_index,
                                std::vector<SkRect> paint_regions) {
  const SkSize float_layer_size =
      SkSize::Make(layer_size.width(), layer_size.height());
  const float views_under_layer_depth =
      flutter_layer_index *
      GfxExternalViewEmbedder::kScenicZElevationForPlatformView;
  const float layer_depth =
      flutter_layer_index *
          GfxExternalViewEmbedder::kScenicZElevationBetweenLayers +
      views_under_layer_depth;
  const float layer_opacity =
      (flutter_layer_index == 0)
          ? GfxExternalViewEmbedder::kBackgroundLayerOpacity / 255.f
          : GfxExternalViewEmbedder::kOverlayLayerOpacity / 255.f;

  EXPECT_THAT(
      scenic_node,
      FieldsAre(
          _, "Flutter::Layer", FakeResource::kDefaultEmptyEventMask,
          VariantWith<FakeEntityNode>(FieldsAre(
              FieldsAre(
                  // Verify children separately below, since the
                  // expected number of children may vary across
                  // different test cases that call this method.
                  _, FakeNode::kDefaultZeroRotation, FakeNode::kDefaultOneScale,
                  FakeNode::kDefaultZeroTranslation,
                  FakeNode::kDefaultZeroAnchor, FakeNode::kIsHitTestable,
                  FakeNode::kIsSemanticallyVisible),
              _))));

  const auto* layer_node_state =
      std::get_if<FakeEntityNode>(&scenic_node.state);
  ASSERT_TRUE(layer_node_state);

  const auto& layer_node_children = layer_node_state->node_state.children;

  // The layer entity node should have a child node for the image, and
  // separate children for each of the hit regions.
  ASSERT_EQ(layer_node_children.size(), paint_regions.size() + 1);

  // Verify image node.
  EXPECT_THAT(
      layer_node_children[0],
      Pointee(FieldsAre(
          _, "Flutter::Layer::Image", FakeResource::kDefaultEmptyEventMask,
          VariantWith<FakeShapeNode>(FieldsAre(
              FieldsAre(IsEmpty(), FakeNode::kDefaultZeroRotation,
                        FakeNode::kDefaultOneScale,
                        std::array<float, 3>{float_layer_size.width() / 2.f,
                                             float_layer_size.height() / 2.f,
                                             -layer_depth},
                        FakeNode::kDefaultZeroAnchor,
                        FakeNode::kIsNotHitTestable,
                        FakeNode::kIsNotSemanticallyVisible),
              Pointee(
                  FieldsAre(_, "", FakeResource::kDefaultEmptyEventMask,
                            VariantWith<FakeShape>(
                                FieldsAre(VariantWith<FakeShape::RectangleDef>(
                                    FieldsAre(float_layer_size.width(),
                                              float_layer_size.height())))))),
              Pointee(FieldsAre(
                  _, "", FakeResource::kDefaultEmptyEventMask,
                  VariantWith<FakeMaterial>(FieldsAre(
                      Pointee(FieldsAre(
                          _, "", FakeResource::kDefaultEmptyEventMask,
                          VariantWith<FakeImage>(FieldsAre(
                              VariantWith<FakeImage::Image2Def>(
                                  FieldsAre(_, 0, float_layer_size.width(),
                                            float_layer_size.height())),
                              IsNull())))),
                      std::array<float, 4>{1.f, 1.f, 1.f,
                                           layer_opacity})))))))));

  // Verify hit regions.
  for (size_t i = 0; i < paint_regions.size(); ++i) {
    ASSERT_LT(i, layer_node_children.size());
    const auto& paint_region = paint_regions[i];
    EXPECT_THAT(
        layer_node_children[i + 1],
        Pointee(FieldsAre(
            _, "Flutter::Layer::HitRegion",
            FakeResource::kDefaultEmptyEventMask,
            VariantWith<FakeShapeNode>(FieldsAre(
                FieldsAre(IsEmpty(), FakeNode::kDefaultZeroRotation,
                          FakeNode::kDefaultOneScale,
                          std::array<float, 3>{
                              paint_region.x() + paint_region.width() / 2.f,
                              paint_region.y() + paint_region.height() / 2.f,
                              -layer_depth},
                          FakeNode::kDefaultZeroAnchor,
                          FakeNode::kIsHitTestable,
                          FakeNode::kIsSemanticallyVisible),
                Pointee(FieldsAre(
                    _, "", FakeResource::kDefaultEmptyEventMask,
                    VariantWith<FakeShape>(FieldsAre(
                        VariantWith<FakeShape::RectangleDef>(FieldsAre(
                            paint_region.width(), paint_region.height())))))),
                IsNull())))));
  }
}

void ExpectViewCompositorLayer(const FakeResource& scenic_node,
                               const fuchsia::ui::views::ViewToken& view_token,
                               const flutter::EmbeddedViewParams& view_params,
                               size_t flutter_layer_index) {
  const float views_under_layer_depth =
      flutter_layer_index > 0
          ? (flutter_layer_index - 1) *
                GfxExternalViewEmbedder::kScenicZElevationForPlatformView
          : 0.f;
  const float layer_depth =
      flutter_layer_index *
          GfxExternalViewEmbedder::kScenicZElevationBetweenLayers +
      views_under_layer_depth;
  EXPECT_THAT(
      scenic_node,
      FieldsAre(
          _, _ /*"Flutter::PlatformView::OpacityMutator" */,
          FakeResource::kDefaultEmptyEventMask,
          VariantWith<FakeOpacityNode>(FieldsAre(
              FieldsAre(
                  ElementsAre(Pointee(FieldsAre(
                      _, _ /*"Flutter::PlatformView::TransformMutator" */,
                      FakeResource::kDefaultEmptyEventMask,
                      VariantWith<FakeEntityNode>(FieldsAre(
                          FieldsAre(
                              ElementsAre(Pointee(FieldsAre(
                                  _, "", FakeResource::kDefaultEmptyEventMask,
                                  VariantWith<FakeViewHolder>(FieldsAre(
                                      FieldsAre(
                                          IsEmpty(),
                                          FakeNode::kDefaultZeroRotation,
                                          FakeNode::kDefaultOneScale,
                                          FakeNode::kDefaultZeroTranslation,
                                          FakeNode::kDefaultZeroAnchor,
                                          FakeNode::kIsHitTestable,
                                          FakeNode::kIsSemanticallyVisible),
                                      GetPeerKoid(view_token.value.get()),
                                      "Flutter::PlatformView",
                                      fuchsia::ui::gfx::ViewProperties{
                                          .bounding_box =
                                              fuchsia::ui::gfx::BoundingBox{
                                                  .min = {0.f, 0.f, -1000.f},
                                                  .max =
                                                      {view_params.sizePoints()
                                                           .width(),
                                                       view_params.sizePoints()
                                                           .height(),
                                                       0.f},
                                              }},
                                      FakeViewHolder::
                                          kDefaultBoundsColorWhite))))),
                              FakeNode::kDefaultZeroRotation,
                              FakeNode::kDefaultOneScale,
                              std::array<float, 3>{0.f, 0.f, -layer_depth},
                              FakeNode::kDefaultZeroAnchor,
                              FakeNode::kIsHitTestable,
                              FakeNode::kIsSemanticallyVisible),
                          IsEmpty()))))),
                  FakeNode::kDefaultZeroRotation, FakeNode::kDefaultOneScale,
                  FakeNode::kDefaultZeroTranslation,
                  FakeNode::kDefaultZeroAnchor, FakeNode::kIsHitTestable,
                  FakeNode::kIsSemanticallyVisible),
              FakeOpacityNode::kDefaultOneOpacity))));
}

std::vector<FakeResource> ExtractLayersFromSceneGraph(
    const FakeSceneGraph& scene_graph) {
  AssertRootSceneGraph(scene_graph, false);

  // These are safe to do unchecked due to `AssertRootSceneGraph` above.
  auto root_view_it = scene_graph.resource_map.find(scene_graph.root_view_id);
  auto* root_view_state = std::get_if<FakeView>(&root_view_it->second->state);
  auto* metrics_watcher_state =
      std::get_if<FakeEntityNode>(&root_view_state->children[0]->state);
  auto* layer_tree_state = std::get_if<FakeEntityNode>(
      &metrics_watcher_state->node_state.children[0]->state);

  std::vector<FakeResource> scenic_layers;
  for (auto& layer_resource : layer_tree_state->node_state.children) {
    scenic_layers.push_back(*layer_resource);
  }

  return scenic_layers;
}

void DrawSimpleFrame(GfxExternalViewEmbedder& external_view_embedder,
                     SkISize frame_size,
                     float frame_dpr,
                     std::function<void(flutter::DlCanvas*)> draw_callback) {
  external_view_embedder.BeginFrame(frame_size, nullptr, frame_dpr, nullptr);
  {
    flutter::DlCanvas* root_canvas = external_view_embedder.GetRootCanvas();
    external_view_embedder.PostPrerollAction(nullptr);
    draw_callback(root_canvas);
  }
  external_view_embedder.EndFrame(false, nullptr);
  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  external_view_embedder.SubmitFrame(
      nullptr, nullptr,
      std::make_unique<flutter::SurfaceFrame>(
          nullptr, framebuffer_info,
          [](const flutter::SurfaceFrame& surface_frame,
             flutter::DlCanvas* canvas) { return true; },
          frame_size));
}

void DrawFrameWithView(
    GfxExternalViewEmbedder& external_view_embedder,
    SkISize frame_size,
    float frame_dpr,
    int view_id,
    flutter::EmbeddedViewParams& view_params,
    std::function<void(flutter::DlCanvas*)> background_draw_callback,
    std::function<void(flutter::DlCanvas*)> overlay_draw_callback) {
  external_view_embedder.BeginFrame(frame_size, nullptr, frame_dpr, nullptr);
  {
    flutter::DlCanvas* root_canvas = external_view_embedder.GetRootCanvas();
    external_view_embedder.PrerollCompositeEmbeddedView(
        view_id, std::make_unique<flutter::EmbeddedViewParams>(view_params));
    external_view_embedder.PostPrerollAction(nullptr);
    background_draw_callback(root_canvas);
    flutter::DlCanvas* overlay_canvas =
        external_view_embedder.CompositeEmbeddedView(view_id);
    overlay_draw_callback(overlay_canvas);
  }
  external_view_embedder.EndFrame(false, nullptr);
  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  external_view_embedder.SubmitFrame(
      nullptr, nullptr,
      std::make_unique<flutter::SurfaceFrame>(
          nullptr, framebuffer_info,
          [](const flutter::SurfaceFrame& surface_frame,
             flutter::DlCanvas* canvas) { return true; },
          frame_size));
}

FramePresentedInfo MakeFramePresentedInfoForOnePresent(
    int64_t latched_time,
    int64_t frame_presented_time) {
  std::vector<PresentReceivedInfo> present_infos;
  present_infos.emplace_back();
  present_infos.back().set_present_received_time(0);
  present_infos.back().set_latched_time(0);
  return FramePresentedInfo{
      .actual_presentation_time = 0,
      .presentation_infos = std::move(present_infos),
      .num_presents_allowed = 1,
  };
}

};  // namespace

class GfxExternalViewEmbedderTest
    : public ::testing::Test,
      public fuchsia::ui::scenic::SessionListener {
 protected:
  GfxExternalViewEmbedderTest()
      : session_subloop_(loop_.StartNewLoop()),
        session_listener_(this),
        session_connection_(CreateSessionConnection()),
        fake_surface_producer_(
            std::make_shared<FakeSurfaceProducer>(session_connection_->get())) {
  }
  ~GfxExternalViewEmbedderTest() override = default;

  async::TestLoop& loop() { return loop_; }

  FakeSession& fake_session() { return fake_session_; }

  std::shared_ptr<FakeSurfaceProducer> fake_surface_producer() {
    return fake_surface_producer_;
  }

  std::shared_ptr<GfxSessionConnection> session_connection() {
    return session_connection_;
  }

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override { FAIL(); }

  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override {
    FAIL();
  }

  std::shared_ptr<GfxSessionConnection> CreateSessionConnection() {
    FML_CHECK(!fake_session_.is_bound());
    FML_CHECK(!session_listener_.is_bound());

    inspect::Node inspect_node =
        inspector_.GetRoot().CreateChild("GfxExternalViewEmbedderTest");

    auto [session, session_listener] =
        fake_session_.Bind(session_subloop_->dispatcher());
    session_listener_.Bind(std::move(session_listener));

    return std::make_shared<GfxSessionConnection>(
        GetCurrentTestName(), std::move(inspect_node), std::move(session),
        []() { FAIL(); }, [](auto...) {}, 1, fml::TimeDelta::Zero());
  }

  async::TestLoop loop_;  // Must come before FIDL bindings.
  std::unique_ptr<async::LoopInterface> session_subloop_;

  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_;

  inspect::Inspector inspector_;

  FakeSession fake_session_;

  std::shared_ptr<GfxSessionConnection> session_connection_;
  std::shared_ptr<FakeSurfaceProducer> fake_surface_producer_;
};

// Tests the trivial case where flutter does not present any content to scenic.
TEST_F(GfxExternalViewEmbedderTest, RootScene) {
  const std::string debug_name = GetCurrentTestName();
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  GfxExternalViewEmbedder external_view_embedder(
      debug_name, std::move(view_token), std::move(view_ref_pair),
      session_connection(), fake_surface_producer());
  EXPECT_EQ(fake_session().debug_name(), "");
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Pump the loop; the contents of the initial `Present` should be processed.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_session().debug_name(), debug_name);
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Fire the `OnFramePresented` event associated with the first `Present`, then
  // pump the loop.  The `OnFramePresented` event is resolved.
  //
  // The scene graph shouldn't change.
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);
}

// Tests the case where flutter renders a single image.
TEST_F(GfxExternalViewEmbedderTest, SimpleScene) {
  const std::string debug_name = GetCurrentTestName();
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  // Create the `GfxExternalViewEmbedder` and pump the message loop until
  // the initial scene graph is setup.
  GfxExternalViewEmbedder external_view_embedder(
      debug_name, std::move(view_token), std::move(view_ref_pair),
      session_connection(), fake_surface_producer());
  loop().RunUntilIdle();
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Draw the scene.  The scene graph shouldn't change yet.
  const SkISize frame_size = SkISize::Make(512, 512);
  SkRect paint_region;
  DrawSimpleFrame(external_view_embedder, frame_size, 1.f,
                  [&paint_region](flutter::DlCanvas* canvas) {
                    const SkISize layer_size = canvas->GetBaseLayerSize();
                    const SkSize canvas_size =
                        SkSize::Make(layer_size.width(), layer_size.height());
                    flutter::DlPaint rect_paint(flutter::DlColor::kGreen());

                    paint_region = SkRect::MakeXYWH(
                        canvas_size.width() / 4.f, canvas_size.height() / 2.f,
                        canvas_size.width() / 32.f,
                        canvas_size.height() / 32.f);

                    canvas->DrawRect(paint_region, rect_paint);
                  });
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Pump the message loop.  The scene updates should propogate to Scenic.
  loop().RunUntilIdle();
  std::vector<FakeResource> scenic_layers =
      ExtractLayersFromSceneGraph(fake_session().SceneGraph());
  EXPECT_EQ(scenic_layers.size(), 1u);
  ExpectImageCompositorLayer(scenic_layers[0], frame_size,
                             /* flutter layer index = */ 0, {paint_region});
}

// Tests the case where flutter embeds a platform view on top of an image layer.
TEST_F(GfxExternalViewEmbedderTest, SceneWithOneView) {
  const std::string debug_name = GetCurrentTestName();
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  // Create the `GfxExternalViewEmbedder` and pump the message loop until
  // the initial scene graph is setup.
  GfxExternalViewEmbedder external_view_embedder(
      debug_name, std::move(view_token), std::move(view_ref_pair),
      session_connection(), fake_surface_producer());
  loop().RunUntilIdle();
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Create the view before drawing the scene.
  const SkSize child_view_size = SkSize::Make(256.f, 512.f);
  auto [child_view_token, child_view_holder_token] =
      scenic::ViewTokenPair::New();
  const uint32_t child_view_id = child_view_holder_token.value.get();
  flutter::EmbeddedViewParams child_view_params(SkMatrix::I(), child_view_size,
                                                flutter::MutatorsStack());
  external_view_embedder.CreateView(
      child_view_id, []() {}, [](scenic::ResourceId) {});

  // Draw the scene.  The scene graph shouldn't change yet.
  const SkISize frame_size = SkISize::Make(512, 512);

  SkRect main_surface_paint_region, overlay_paint_region;

  DrawFrameWithView(
      external_view_embedder, frame_size, 1.f, child_view_id, child_view_params,
      [&main_surface_paint_region](flutter::DlCanvas* canvas) {
        const SkISize layer_size = canvas->GetBaseLayerSize();
        const SkSize canvas_size =
            SkSize::Make(layer_size.width(), layer_size.height());

        main_surface_paint_region = SkRect::MakeXYWH(
            canvas_size.width() / 4.f, canvas_size.width() / 2.f,
            canvas_size.width() / 32.f, canvas_size.height() / 32.f);

        flutter::DlPaint rect_paint(flutter::DlColor::kGreen());
        canvas->DrawRect(main_surface_paint_region, rect_paint);
      },
      [&overlay_paint_region](flutter::DlCanvas* canvas) {
        const SkISize layer_size = canvas->GetBaseLayerSize();
        const SkSize canvas_size =
            SkSize::Make(layer_size.width(), layer_size.height());
        overlay_paint_region = SkRect::MakeXYWH(
            canvas_size.width() * 3.f / 4.f, canvas_size.height() / 2.f,
            canvas_size.width() / 32.f, canvas_size.height() / 32.f);

        flutter::DlPaint rect_paint(flutter::DlColor::kRed());
        canvas->DrawRect(overlay_paint_region, rect_paint);
      });
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Pump the message loop.  The scene updates should propagate to Scenic.
  loop().RunUntilIdle();
  std::vector<FakeResource> scenic_layers =
      ExtractLayersFromSceneGraph(fake_session().SceneGraph());
  EXPECT_EQ(scenic_layers.size(), 3u);
  ExpectImageCompositorLayer(scenic_layers[0], frame_size,
                             /* flutter layer index = */ 0,
                             {main_surface_paint_region});
  ExpectViewCompositorLayer(scenic_layers[1], child_view_token,
                            child_view_params,
                            /* flutter layer index = */ 1);
  ExpectImageCompositorLayer(scenic_layers[2], frame_size,
                             /* flutter layer index = */ 1,
                             {overlay_paint_region});

  // Destroy the view.
  external_view_embedder.DestroyView(child_view_id, [](scenic::ResourceId) {});

  // Pump the message loop.
  loop().RunUntilIdle();
}

// Tests the case where flutter renders an image with two non-overlapping pieces
// of content. In this case, the embedder should report two separate hit regions
// to scenic.
TEST_F(GfxExternalViewEmbedderTest, SimpleSceneDisjointHitRegions) {
  const std::string debug_name = GetCurrentTestName();
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  // Create the `GfxExternalViewEmbedder` and pump the message loop until
  // the initial scene graph is setup.
  GfxExternalViewEmbedder external_view_embedder(
      debug_name, std::move(view_token), std::move(view_ref_pair),
      session_connection(), fake_surface_producer());
  loop().RunUntilIdle();
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Draw the scene.  The scene graph shouldn't change yet.
  SkRect paint_region_1, paint_region_2;
  const SkISize frame_size = SkISize::Make(512, 512);
  DrawSimpleFrame(
      external_view_embedder, frame_size, 1.f,
      [&paint_region_1, &paint_region_2](flutter::DlCanvas* canvas) {
        const SkISize layer_size = canvas->GetBaseLayerSize();
        const SkSize canvas_size =
            SkSize::Make(layer_size.width(), layer_size.height());

        paint_region_1 = SkRect::MakeXYWH(
            canvas_size.width() / 4.f, canvas_size.height() / 2.f,
            canvas_size.width() / 32.f, canvas_size.height() / 32.f);

        flutter::DlPaint rect_paint(flutter::DlColor::kGreen());
        canvas->DrawRect(paint_region_1, rect_paint);

        paint_region_2 = SkRect::MakeXYWH(
            canvas_size.width() * 3.f / 4.f, canvas_size.height() / 2.f,
            canvas_size.width() / 32.f, canvas_size.height() / 32.f);

        rect_paint.setColor(flutter::DlColor::kRed());
        canvas->DrawRect(paint_region_2, rect_paint);
      });
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Pump the message loop.  The scene updates should propogate to Scenic.
  loop().RunUntilIdle();
  std::vector<FakeResource> scenic_layers =
      ExtractLayersFromSceneGraph(fake_session().SceneGraph());
  EXPECT_EQ(scenic_layers.size(), 1u);
  ExpectImageCompositorLayer(scenic_layers[0], frame_size,
                             /* flutter layer index = */ 0,
                             {paint_region_1, paint_region_2});
}

// Tests the case where flutter renders an image with two overlapping pieces of
// content. In this case, the embedder should report a single joint hit region
// to scenic.
TEST_F(GfxExternalViewEmbedderTest, SimpleSceneOverlappingHitRegions) {
  const std::string debug_name = GetCurrentTestName();
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  fuchsia::ui::views::ViewRef view_ref;
  view_ref_pair.view_ref.Clone(&view_ref);

  // Create the `GfxExternalViewEmbedder` and pump the message loop until
  // the initial scene graph is setup.
  GfxExternalViewEmbedder external_view_embedder(
      debug_name, std::move(view_token), std::move(view_ref_pair),
      session_connection(), fake_surface_producer());
  loop().RunUntilIdle();
  fake_session().FireOnFramePresentedEvent(
      MakeFramePresentedInfoForOnePresent(0, 0));
  loop().RunUntilIdle();
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  // Draw the scene.  The scene graph shouldn't change yet.
  SkRect joined_paint_region = SkRect::MakeEmpty();
  const SkISize frame_size = SkISize::Make(512, 512);
  DrawSimpleFrame(external_view_embedder, frame_size, 1.f,
                  [&joined_paint_region](flutter::DlCanvas* canvas) {
                    const SkISize layer_size = canvas->GetBaseLayerSize();
                    const SkSize canvas_size =
                        SkSize::Make(layer_size.width(), layer_size.height());

                    auto paint_region_1 = SkRect::MakeXYWH(
                        canvas_size.width() / 4.f, canvas_size.height() / 4.f,
                        canvas_size.width() / 2.f, canvas_size.height() / 2.f);
                    flutter::DlPaint rect_paint(flutter::DlColor::kGreen());
                    canvas->DrawRect(paint_region_1, rect_paint);

                    auto paint_region_2 = SkRect::MakeXYWH(
                        canvas_size.width() * 3.f / 8.f,
                        canvas_size.height() / 4.f, canvas_size.width() / 2.f,
                        canvas_size.height() / 2.f);
                    rect_paint.setColor(flutter::DlColor::kRed());
                    canvas->DrawRect(paint_region_2, rect_paint);

                    joined_paint_region.join(paint_region_1);
                    joined_paint_region.join(paint_region_2);
                  });
  ExpectRootSceneGraph(fake_session().SceneGraph(), debug_name,
                       view_holder_token, view_ref);

  EXPECT_EQ(joined_paint_region.x(), 128.f);
  EXPECT_EQ(joined_paint_region.y(), 128.f);
  EXPECT_EQ(joined_paint_region.width(), 320.f);
  EXPECT_EQ(joined_paint_region.height(), 256.f);
  // Pump the message loop.  The scene updates should propogate to Scenic.
  loop().RunUntilIdle();
  std::vector<FakeResource> scenic_layers =
      ExtractLayersFromSceneGraph(fake_session().SceneGraph());
  EXPECT_EQ(scenic_layers.size(), 1u);
  ExpectImageCompositorLayer(scenic_layers[0], frame_size,
                             /* flutter layer index = */ 0,
                             {joined_paint_region});
}

}  // namespace flutter_runner::testing

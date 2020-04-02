// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <deque>

#include "gtest/gtest.h"

#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl_test_base.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async/default.h>
#include <lib/fidl/cpp/optional.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/id.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>

#include "flutter/flow/layers/child_scene_layer.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/layers/physical_shape_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/view_holder.h"
#include "flutter/fml/platform/fuchsia/message_loop_fuchsia.h"
#include "flutter/fml/task_runner.h"

namespace flutter {
namespace testing {

using FuchsiaLayerTest = ::testing::Test;

class MockSession : public fuchsia::ui::scenic::testing::Session_TestBase {
 public:
  MockSession() : binding_(this) {}

  void NotImplemented_(const std::string& name) final {}

  void Bind(fidl::InterfaceRequest<::fuchsia::ui::scenic::Session> request,
            ::fuchsia::ui::scenic::SessionListenerPtr listener) {
    binding_.Bind(std::move(request));
    listener_ = std::move(listener);
  }

  static std::string Vec3ValueToString(fuchsia::ui::gfx::Vector3Value value) {
    return "{" + std::to_string(value.value.x) + ", " +
           std::to_string(value.value.y) + ", " +
           std::to_string(value.value.z) + "}";
  }

  static std::string QuaternionValueToString(
      fuchsia::ui::gfx::QuaternionValue value) {
    return "{" + std::to_string(value.value.x) + ", " +
           std::to_string(value.value.y) + ", " +
           std::to_string(value.value.z) + ", " +
           std::to_string(value.value.w) + "}";
  }

  static std::string GfxCreateResourceCmdToString(
      const fuchsia::ui::gfx::CreateResourceCmd& cmd) {
    std::string id = " id: " + std::to_string(cmd.id);
    switch (cmd.resource.Which()) {
      case fuchsia::ui::gfx::ResourceArgs::Tag::kRectangle:
        return "Rectangle" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kRoundedRectangle:
        return "RoundedRectangle" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kViewHolder:
        return "ViewHolder" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kOpacityNode:
        return "OpacityNode" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kEntityNode:
        return "EntityNode" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kShapeNode:
        return "ShapeNode" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kMaterial:
        return "Material" + id;
      case fuchsia::ui::gfx::ResourceArgs::Tag::kImage:
        return "Image" + id + ", memory_id: " +
               std::to_string(cmd.resource.image().memory_id) +
               ", memory_offset: " +
               std::to_string(cmd.resource.image().memory_offset);
      default:
        return "Unhandled CreateResource command" +
               std::to_string(cmd.resource.Which());
    }
  }

  static std::string GfxCmdToString(const fuchsia::ui::gfx::Command& cmd) {
    switch (cmd.Which()) {
      case fuchsia::ui::gfx::Command::Tag::kCreateResource:
        return "CreateResource: " +
               GfxCreateResourceCmdToString(cmd.create_resource());
      case fuchsia::ui::gfx::Command::Tag::kReleaseResource:
        return "ReleaseResource id: " +
               std::to_string(cmd.release_resource().id);
      case fuchsia::ui::gfx::Command::Tag::kAddChild:
        return "AddChild id: " + std::to_string(cmd.add_child().node_id) +
               " child_id: " + std::to_string(cmd.add_child().child_id);
      case fuchsia::ui::gfx::Command::Tag::kSetTranslation:
        return "SetTranslation id: " +
               std::to_string(cmd.set_translation().id) +
               " value: " + Vec3ValueToString(cmd.set_translation().value);
      case fuchsia::ui::gfx::Command::Tag::kSetScale:
        return "SetScale id: " + std::to_string(cmd.set_scale().id) +
               " value: " + Vec3ValueToString(cmd.set_scale().value);
      case fuchsia::ui::gfx::Command::Tag::kSetRotation:
        return "SetRotation id: " + std::to_string(cmd.set_rotation().id) +
               " value: " + QuaternionValueToString(cmd.set_rotation().value);
      case fuchsia::ui::gfx::Command::Tag::kSetOpacity:
        return "SetOpacity id: " + std::to_string(cmd.set_opacity().node_id) +
               ", opacity: " + std::to_string(cmd.set_opacity().opacity);
      case fuchsia::ui::gfx::Command::Tag::kSetColor:
        return "SetColor id: " + std::to_string(cmd.set_color().material_id) +
               ", rgba: (" + std::to_string(cmd.set_color().color.value.red) +
               ", " + std::to_string(cmd.set_color().color.value.green) + ", " +
               std::to_string(cmd.set_color().color.value.blue) + ", " +
               std::to_string(cmd.set_color().color.value.alpha) + ")";
      case fuchsia::ui::gfx::Command::Tag::kSetLabel:
        return "SetLabel id: " + std::to_string(cmd.set_label().id) + " " +
               cmd.set_label().label;
      case fuchsia::ui::gfx::Command::Tag::kSetHitTestBehavior:
        return "SetHitTestBehavior node_id: " +
               std::to_string(cmd.set_hit_test_behavior().node_id);
      case fuchsia::ui::gfx::Command::Tag::kSetClipPlanes:
        return "SetClipPlanes node_id: " +
               std::to_string(cmd.set_clip_planes().node_id);
      case fuchsia::ui::gfx::Command::Tag::kSetShape:
        return "SetShape node_id: " + std::to_string(cmd.set_shape().node_id) +
               ", shape_id: " + std::to_string(cmd.set_shape().shape_id);
      case fuchsia::ui::gfx::Command::Tag::kSetMaterial:
        return "SetMaterial node_id: " +
               std::to_string(cmd.set_material().node_id) + ", material_id: " +
               std::to_string(cmd.set_material().material_id);
      case fuchsia::ui::gfx::Command::Tag::kSetTexture:
        return "SetTexture material_id: " +
               std::to_string(cmd.set_texture().material_id) +
               ", texture_id: " + std::to_string(cmd.set_texture().texture_id);

      default:
        return "Unhandled gfx command" + std::to_string(cmd.Which());
    }
  }

  static std::string ScenicCmdToString(
      const fuchsia::ui::scenic::Command& cmd) {
    if (cmd.Which() != fuchsia::ui::scenic::Command::Tag::kGfx) {
      return "Unhandled non-gfx command: " + std::to_string(cmd.Which());
    }
    return GfxCmdToString(cmd.gfx());
  }

  // |fuchsia::ui::scenic::Session|
  void Enqueue(std::vector<fuchsia::ui::scenic::Command> cmds) override {
    for (const auto& cmd : cmds) {
      num_enqueued_commands_++;
      EXPECT_FALSE(expected_.empty())
          << "Received more commands than expected; command: <"
          << ScenicCmdToString(cmd)
          << ">, num_enqueued_commands: " << num_enqueued_commands_;
      if (!expected_.empty()) {
        EXPECT_TRUE(AreCommandsEqual(expected_.front(), cmd))
            << "actual command: <" << ScenicCmdToString(cmd)
            << ">, expected command: <" << ScenicCmdToString(expected_.front())
            << ">, num_enqueued_commands: " << num_enqueued_commands_;
        expected_.pop_front();
      }
    }
  }

  void SetExpectedCommands(std::vector<fuchsia::ui::gfx::Command> gfx_cmds) {
    std::deque<fuchsia::ui::scenic::Command> scenic_commands;
    for (auto it = gfx_cmds.begin(); it != gfx_cmds.end(); it++) {
      scenic_commands.push_back(scenic::NewCommand(std::move((*it))));
    }
    expected_ = std::move(scenic_commands);
    num_enqueued_commands_ = 0;
  }

  size_t num_enqueued_commands() { return num_enqueued_commands_; }

 private:
  static bool IsGfxCommand(const fuchsia::ui::scenic::Command& cmd,
                           fuchsia::ui::gfx::Command::Tag tag) {
    return cmd.Which() == fuchsia::ui::scenic::Command::Tag::kGfx &&
           cmd.gfx().Which() == tag;
  }

  static bool IsCreateResourceCommand(const fuchsia::ui::scenic::Command& cmd,
                                      fuchsia::ui::gfx::ResourceArgs::Tag tag) {
    return IsGfxCommand(cmd, fuchsia::ui::gfx::Command::Tag::kCreateResource) &&
           cmd.gfx().create_resource().resource.Which() == tag;
  }

  static bool AreCommandsEqual(const fuchsia::ui::scenic::Command& command1,
                               const fuchsia::ui::scenic::Command& command2) {
    // For CreateViewHolderCommand, just compare the id and ignore the
    // view_holder_token.
    if (IsCreateResourceCommand(
            command1, fuchsia::ui::gfx::ResourceArgs::Tag::kViewHolder)) {
      return IsCreateResourceCommand(
                 command2, fuchsia::ui::gfx::ResourceArgs::Tag::kViewHolder) &&
             command1.gfx().create_resource().id ==
                 command2.gfx().create_resource().id;
    }
    // For CreateImageCommand, just compare the id and memory_id.
    if (IsCreateResourceCommand(command1,
                                fuchsia::ui::gfx::ResourceArgs::Tag::kImage)) {
      return IsCreateResourceCommand(
                 command2, fuchsia::ui::gfx::ResourceArgs::Tag::kImage) &&
             command1.gfx().create_resource().id ==
                 command2.gfx().create_resource().id &&
             command1.gfx().create_resource().resource.image().memory_id ==
                 command2.gfx().create_resource().resource.image().memory_id;
    }
    // For SetHitTestBehaviorCommand, just compare the node_id.
    if (IsGfxCommand(command1,
                     fuchsia::ui::gfx::Command::Tag::kSetHitTestBehavior)) {
      return IsGfxCommand(
                 command2,
                 fuchsia::ui::gfx::Command::Tag::kSetHitTestBehavior) &&
             command1.gfx().set_hit_test_behavior().node_id ==
                 command2.gfx().set_hit_test_behavior().node_id;
    }
    // For SetHitTestBehaviorCommand, just compare the node_id.
    if (IsGfxCommand(command1,
                     fuchsia::ui::gfx::Command::Tag::kSetClipPlanes)) {
      return IsGfxCommand(command2,
                          fuchsia::ui::gfx::Command::Tag::kSetClipPlanes) &&
             command1.gfx().set_clip_planes().node_id ==
                 command2.gfx().set_clip_planes().node_id;
    }
    return fidl::Equals(command1, command2);
  }

  std::deque<fuchsia::ui::scenic::Command> expected_;
  size_t num_enqueued_commands_ = 0;
  fidl::Binding<fuchsia::ui::scenic::Session> binding_;
  fuchsia::ui::scenic::SessionListenerPtr listener_;
};

class MockSurfaceProducerSurface
    : public SceneUpdateContext::SurfaceProducerSurface {
 public:
  MockSurfaceProducerSurface(scenic::Session* session, const SkISize& size)
      : image_(session, 0, 0, {}), size_(size) {}

  size_t AdvanceAndGetAge() override { return 0; }

  bool FlushSessionAcquireAndReleaseEvents() override { return false; }

  bool IsValid() const override { return false; }

  SkISize GetSize() const override { return size_; }

  void SignalWritesFinished(
      const std::function<void(void)>& on_writes_committed) override {}

  scenic::Image* GetImage() override { return &image_; };

  sk_sp<SkSurface> GetSkiaSurface() const override { return nullptr; };

 private:
  scenic::Image image_;
  SkISize size_;
};

class MockSurfaceProducer : public SceneUpdateContext::SurfaceProducer {
 public:
  MockSurfaceProducer(scenic::Session* session) : session_(session) {}
  std::unique_ptr<SceneUpdateContext::SurfaceProducerSurface> ProduceSurface(
      const SkISize& size,
      const LayerRasterCacheKey& layer_key,
      std::unique_ptr<scenic::EntityNode> entity_node) override {
    return std::make_unique<MockSurfaceProducerSurface>(session_, size);
  }

  // Query a retained entity node (owned by a retained surface) for retained
  // rendering.
  bool HasRetainedNode(const LayerRasterCacheKey& key) const override {
    return false;
  }

  scenic::EntityNode* GetRetainedNode(const LayerRasterCacheKey& key) override {
    return nullptr;
  }

  void SubmitSurface(std::unique_ptr<SceneUpdateContext::SurfaceProducerSurface>
                         surface) override {}

 private:
  scenic::Session* session_;
};

struct TestContext {
  // Message loop.
  fml::RefPtr<fml::MessageLoopFuchsia> loop;
  fml::RefPtr<fml::TaskRunner> task_runner;

  // Session.
  MockSession mock_session;
  fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener> listener_request;
  std::unique_ptr<scenic::Session> session;

  // SceneUpdateContext.
  std::unique_ptr<MockSurfaceProducer> mock_surface_producer;
  std::unique_ptr<SceneUpdateContext> scene_update_context;

  // PrerollContext.
  MutatorsStack unused_stack;
  const Stopwatch unused_stopwatch;
  TextureRegistry unused_texture_registry;
  std::unique_ptr<PrerollContext> preroll_context;
};

std::unique_ptr<TestContext> InitTest() {
  std::unique_ptr<TestContext> context = std::make_unique<TestContext>();

  // Init message loop.
  context->loop = fml::MakeRefCounted<fml::MessageLoopFuchsia>();
  context->task_runner = fml::MakeRefCounted<fml::TaskRunner>(context->loop);

  // Init Session.
  fuchsia::ui::scenic::SessionPtr session_ptr;
  fuchsia::ui::scenic::SessionListenerPtr listener;
  context->listener_request = listener.NewRequest();
  context->mock_session.Bind(session_ptr.NewRequest(), std::move(listener));
  context->session = std::make_unique<scenic::Session>(std::move(session_ptr));

  // Init SceneUpdateContext.
  context->mock_surface_producer =
      std::make_unique<MockSurfaceProducer>(context->session.get());
  context->scene_update_context = std::make_unique<SceneUpdateContext>(
      context->session.get(), context->mock_surface_producer.get());
  context->scene_update_context->set_metrics(
      fidl::MakeOptional(fuchsia::ui::gfx::Metrics{1.f, 1.f, 1.f}));

  // Init PrerollContext.
  context->preroll_context = std::unique_ptr<PrerollContext>(new PrerollContext{
      nullptr,                    // raster_cache (don't consult the cache)
      nullptr,                    // gr_context  (used for the raster cache)
      nullptr,                    // external view embedder
      context->unused_stack,      // mutator stack
      nullptr,                    // SkColorSpace* dst_color_space
      kGiantRect,                 // SkRect cull_rect
      false,                      // layer reads from surface
      context->unused_stopwatch,  // frame time (dont care)
      context->unused_stopwatch,  // engine time (dont care)
      context->unused_texture_registry,  // texture registry (not
                                         // supported)
      false,                             // checkerboard_offscreen_layers
      100.f,                             // maximum depth allowed for rendering
      1.f                                // ratio between logical and physical
  });

  return context;
}

zx_koid_t GetChildLayerId() {
  static zx_koid_t sChildLayerId = 17324;
  return sChildLayerId++;
}

class AutoDestroyChildLayerId {
 public:
  AutoDestroyChildLayerId(zx_koid_t id) : id_(id) {}
  ~AutoDestroyChildLayerId() { ViewHolder::Destroy(id_); }

 private:
  zx_koid_t id_;
};

// Create a hierarchy with PhysicalShapeLayers and ChildSceneLayers, and
// inspect the commands sent to Scenic.
//
//
// What we expect:
//
// The Scenic elevations of the PhysicalShapeLayers are monotically
// increasing, even though the elevations we gave them when creating them are
// decreasing. The two should not have any correlation; we're merely mirror
// the paint order using Scenic elevation.
//
// PhysicalShapeLayers created before/below a ChildView do not get their own
// node; PhysicalShapeLayers created afterward do.
//
// Nested PhysicalShapeLayers are collapsed.
TEST_F(FuchsiaLayerTest, PhysicalShapeLayersAndChildSceneLayers) {
  auto test_context = InitTest();

  // Root.
  auto root = std::make_shared<ContainerLayer>();
  SkPath path;
  path.addRect(SkRect::MakeWH(10.f, 10.f));

  // Child #1: PhysicalShapeLayer.
  auto physical_shape1 = std::make_shared<PhysicalShapeLayer>(
      /*color=*/SK_ColorCYAN,
      /*shadow_color=*/SK_ColorBLACK,
      /*elevation*/ 23.f, path, Clip::antiAlias);
  root->Add(physical_shape1);

  // Child #2: ChildSceneLayer.
  const zx_koid_t kChildLayerId1 = GetChildLayerId();
  auto [unused_view_token1, unused_view_holder_token1] =
      scenic::ViewTokenPair::New();
  ViewHolder::Create(kChildLayerId1, test_context->task_runner,
                     std::move(unused_view_holder_token1),
                     /*bind_callback=*/[](scenic::ResourceId id) {});
  // Will destroy only when we go out of scope (i.e. end of the test).
  AutoDestroyChildLayerId auto_destroy1(kChildLayerId1);
  auto child_view1 = std::make_shared<ChildSceneLayer>(
      kChildLayerId1, SkPoint::Make(1, 1), SkSize::Make(10, 10),
      /*hit_testable=*/false);
  root->Add(child_view1);

  // Child #3: PhysicalShapeLayer
  auto physical_shape2 = std::make_shared<PhysicalShapeLayer>(
      /*color=*/SK_ColorCYAN,
      /*shadow_color=*/SK_ColorBLACK,
      /*elevation*/ 21.f, path, Clip::antiAlias);
  root->Add(physical_shape2);

  // Grandchild (child of #3): PhysicalShapeLayer
  auto physical_shape3 = std::make_shared<PhysicalShapeLayer>(
      /*color=*/SK_ColorCYAN,
      /*shadow_color=*/SK_ColorBLACK,
      /*elevation*/ 19.f, path, Clip::antiAlias);
  physical_shape2->Add(physical_shape3);

  // Child #4: ChildSceneLayer
  const zx_koid_t kChildLayerId2 = GetChildLayerId();
  auto [unused_view_token2, unused_view_holder_token2] =
      scenic::ViewTokenPair::New();
  ViewHolder::Create(kChildLayerId2, test_context->task_runner,
                     std::move(unused_view_holder_token2),
                     /*bind_callback=*/[](scenic::ResourceId id) {});
  // Will destroy only when we go out of scope (i.e. end of the test).
  AutoDestroyChildLayerId auto_destroy2(kChildLayerId2);
  auto child_view2 = std::make_shared<ChildSceneLayer>(
      kChildLayerId2, SkPoint::Make(1, 1), SkSize::Make(10, 10),
      /*hit_testable=*/false);
  root->Add(child_view2);

  // Child #5: PhysicalShapeLayer
  auto physical_shape4 = std::make_shared<PhysicalShapeLayer>(
      /*color=*/SK_ColorCYAN,
      /*shadow_color=*/SK_ColorBLACK,
      /*elevation*/ 17.f, path, Clip::antiAlias);
  root->Add(physical_shape4);

  // Preroll.
  root->Preroll(test_context->preroll_context.get(), SkMatrix());

  // Create another frame to be the "real" root. Required because
  // UpdateScene() traversal expects there to already be a top node.
  SceneUpdateContext::Frame frame(*(test_context->scene_update_context),
                                  SkRRect::MakeRect(SkRect::MakeWH(100, 100)),
                                  SK_ColorTRANSPARENT, SK_AlphaOPAQUE,
                                  "fuchsia test root");

  // Submit the list of command we will expect Scenic to see.
  //
  // Some things we expect:
  //
  // The Scenic elevations of the PhysicalShapeLayers are monotically
  // increasing, even though the elevations we gave them when creating them are
  // decreasing. The two should not have any correlation; we're merely mirror
  // the paint order using Scenic elevation.
  //
  // PhysicalShapeLayers created before/below a ChildView do not get their own
  // node; PhysicalShapeLayers created afterward do.
  //
  // Nested PhysicalShapeLayers are collapsed.

  std::vector<fuchsia::ui::gfx::Command> expected;

  //
  // Test root.
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/1));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/2));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/1, "fuchsia test root"));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/1, {0, 0}));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/1, /*child_id=*/2));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/2, kOneMinusEpsilon));

  //
  // Child #1: PhysicalShapeLayer
  //
  // Expect no new commands! Should be composited into base layer.

  //
  // Child #2: ChildSceneLayer.
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/3));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/4));
  auto [view_token1, view_holder_token1] = scenic::ViewTokenPair::New();
  expected.push_back(scenic::NewCreateViewHolderCmd(
      /*id=*/5, std::move(view_holder_token1), ""));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/4, /*child_id=*/3));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/4, "flutter::ViewHolder"));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/3, /*child_id=*/5));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/2, /*child_id=*/4));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/4, 1.f));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/3, {1, 1, -0.1}));
  expected.push_back(scenic::NewSetHitTestBehaviorCmd(
      /*id=*/3, /*ignored*/ fuchsia::ui::gfx::HitTestBehavior::kSuppress));

  //
  // Child #3: PhysicalShapeLayer
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/6));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/2, /*child_id=*/6));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/7));
  expected.push_back(
      scenic::NewSetLabelCmd(/*id=*/6, "flutter::PhysicalShapeLayer"));
  expected.push_back(scenic::NewSetTranslationCmd(
      /*id=*/6, {0, 0, -kScenicZElevationBetweenLayers}));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/6, /*child_id=*/7));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/7, kOneMinusEpsilon));
  expected.push_back(scenic::NewSetClipPlanesCmd(/*id=*/6, /*ignored*/ {}));
  expected.push_back(scenic::NewCreateShapeNodeCmd(/*id=*/8));
  expected.push_back(scenic::NewCreateRectangleCmd(
      /*id=*/9, /*width=*/10, /*height=*/10));
  expected.push_back(scenic::NewSetShapeCmd(/*id=*/8, /*shape_id=*/9));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/8, {5, 5, 0}));
  expected.push_back(scenic::NewCreateMaterialCmd(/*id=*/10));
  expected.push_back(scenic::NewSetMaterialCmd(/*id=*/8, /*material_id=*/10));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/6, /*child_id=*/8));

  expected.push_back(scenic::NewCreateImageCmd(/*id=*/11, 0, 0, {}));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/6));
  expected.push_back(scenic::NewSetColorCmd(/*id=*/10, /*r*/ 255, /*g*/ 255,
                                            /*b*/ 255, /*a*/ 255));
  expected.push_back(
      scenic::NewSetTextureCmd(/*material_id=*/10, /*texture_id=*/11));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/10));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/9));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/8));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/7));

  //
  // Grandchild (child of #3): PhysicalShapeLayer
  //
  // Expect no new commands! Should be composited into parent.

  //
  // Child #4: ChildSceneLayer
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/12));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/13));
  auto [view_token2, view_holder_token2] = scenic::ViewTokenPair::New();
  expected.push_back(scenic::NewCreateViewHolderCmd(
      /*id=*/14, std::move(view_holder_token2), ""));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/13, /*child_id=*/12));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/13, "flutter::ViewHolder"));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/12, /*child_id=*/14));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/2, /*child_id=*/13));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/13, 1.f));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/12, {1, 1, -0.1}));
  expected.push_back(scenic::NewSetHitTestBehaviorCmd(
      /*id=*/12, /*ignored*/ fuchsia::ui::gfx::HitTestBehavior::kSuppress));

  //
  // Child #5: PhysicalShapeLayer
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/15));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/2, /*child_id=*/15));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/16));
  expected.push_back(
      scenic::NewSetLabelCmd(/*id=*/15, "flutter::PhysicalShapeLayer"));
  expected.push_back(scenic::NewSetTranslationCmd(
      /*id=*/15, {0, 0, -2 * kScenicZElevationBetweenLayers}));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/15, /*child_id=*/16));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/16, kOneMinusEpsilon));
  expected.push_back(scenic::NewSetClipPlanesCmd(/*id=*/15, /*ignored*/ {}));
  expected.push_back(scenic::NewCreateShapeNodeCmd(/*id=*/17));
  expected.push_back(scenic::NewCreateRectangleCmd(
      /*id=*/18, /*width=*/10, /*height=*/10));
  expected.push_back(scenic::NewSetShapeCmd(/*id=*/17, /*shape_id=*/18));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/17, {5, 5, 0}));
  expected.push_back(scenic::NewCreateMaterialCmd(/*id=*/19));
  expected.push_back(scenic::NewSetMaterialCmd(/*id=*/17, /*material_id=*/19));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/15, /*child_id=*/17));

  expected.push_back(scenic::NewCreateImageCmd(/*id=*/20, 0, 0, {}));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/15));
  expected.push_back(scenic::NewSetColorCmd(/*id=*/19, /*r*/ 255, /*g*/ 255,
                                            /*b*/ 255, /*a*/ 255));
  expected.push_back(
      scenic::NewSetTextureCmd(/*material_id=*/19, /*texture_id=*/20));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/19));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/18));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/17));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/16));

  test_context->mock_session.SetExpectedCommands(std::move(expected));

  // Finally, UpdateScene(). The MockSession will check the emitted commands
  // against the list above.
  root->UpdateScene(*(test_context->scene_update_context));

  test_context->session->Flush();

  // Run loop until idle, so that the Session receives and processes
  // its method calls.
  async_loop_run_until_idle(
      async_loop_from_dispatcher(async_get_default_dispatcher()));

  // Ensure we saw enough commands.
  EXPECT_EQ(72u, test_context->mock_session.num_enqueued_commands());
}

// Create a hierarchy with OpacityLayers, TransformLayer, PhysicalShapeLayers
// and ChildSceneLayers, and inspect the commands sent to Scenic.
//
// We are interested in verifying that the opacity values of children are
// correct, and the transform values as well.
//
TEST_F(FuchsiaLayerTest, OpacityAndTransformLayer) {
  auto test_context = InitTest();

  // Root.
  auto root = std::make_shared<ContainerLayer>();
  SkPath path;
  path.addRect(SkRect::MakeWH(10.f, 10.f));

  // OpacityLayer #1
  auto opacity_layer1 =
      std::make_shared<OpacityLayer>(127, SkPoint::Make(0, 0));
  root->Add(opacity_layer1);

  // OpacityLayer #2
  auto opacity_layer2 =
      std::make_shared<OpacityLayer>(127, SkPoint::Make(0, 0));
  opacity_layer1->Add(opacity_layer2);

  // TransformLayer
  SkMatrix translate_and_scale;
  translate_and_scale.setScaleTranslate(1.1f, 1.1f, 2.f, 2.f);
  auto transform_layer = std::make_shared<TransformLayer>(translate_and_scale);
  opacity_layer2->Add(transform_layer);

  // TransformLayer Child #1: ChildSceneLayer.
  const zx_koid_t kChildLayerId1 = GetChildLayerId();
  auto [unused_view_token1, unused_view_holder_token1] =
      scenic::ViewTokenPair::New();

  ViewHolder::Create(kChildLayerId1, test_context->task_runner,
                     std::move(unused_view_holder_token1),
                     /*bind_callback=*/[](scenic::ResourceId id) {});
  // Will destroy only when we go out of scope (i.e. end of the test).
  AutoDestroyChildLayerId auto_destroy1(kChildLayerId1);
  auto child_view1 = std::make_shared<ChildSceneLayer>(
      kChildLayerId1, SkPoint::Make(1, 1), SkSize::Make(10, 10),
      /*hit_testable=*/false);
  transform_layer->Add(child_view1);

  // TransformLayer Child #2: PhysicalShapeLayer.
  auto physical_shape1 = std::make_shared<PhysicalShapeLayer>(
      /*color=*/SK_ColorCYAN,
      /*shadow_color=*/SK_ColorBLACK,
      /*elevation*/ 23.f, path, Clip::antiAlias);
  transform_layer->Add(physical_shape1);

  // Preroll.
  root->Preroll(test_context->preroll_context.get(), SkMatrix());

  // Create another frame to be the "real" root. Required because
  // UpdateScene() traversal expects there to already be a top node.
  SceneUpdateContext::Frame frame(*(test_context->scene_update_context),
                                  SkRRect::MakeRect(SkRect::MakeWH(100, 100)),
                                  SK_ColorTRANSPARENT, SK_AlphaOPAQUE,
                                  "fuchsia test root");

  // Submit the list of command we will expect Scenic to see.
  //
  // We are interested in verifying that the opacity values of children are
  // correct.

  std::vector<fuchsia::ui::gfx::Command> expected;

  //
  // Test root.
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/1));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/2));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/1, "fuchsia test root"));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/1, {0, 0, 0}));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/1, /*child_id=*/2));
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/2, kOneMinusEpsilon));

  //
  // OpacityLayer #1
  //
  // Expect no new commands for this.

  //
  // OpacityLayer #2
  //
  // Expect no new commands for this.

  //
  // TransformLayer
  //
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/3));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/2, /*child_id=*/3));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/3, "flutter::Transform"));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/3, {2.f, 2.f, 0.f}));
  expected.push_back(scenic::NewSetScaleCmd(/*id=*/3, {1.1f, 1.1f, 1.f}));
  expected.push_back(scenic::NewSetRotationCmd(/*id=*/3, {0.f, 0.f, 0.f, 1.f}));

  //
  // TransformLayer Child #1: ChildSceneLayer.
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/4));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/5));
  auto [view_token1, view_holder_token1] = scenic::ViewTokenPair::New();
  expected.push_back(scenic::NewCreateViewHolderCmd(
      /*id=*/6, std::move(view_holder_token1), ""));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/5, /*child_id=*/4));
  expected.push_back(scenic::NewSetLabelCmd(/*id=*/5, "flutter::ViewHolder"));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/4, /*child_id=*/6));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/3, /*child_id=*/5));

  // Check opacity value. Extra rounding required because we pass alpha as
  // a uint/SkAlpha to SceneUpdateContext::Frame.
  float opacity1 = kOneMinusEpsilon * (127 / 255.f) * (127 / 255.f);
  opacity1 = SkScalarRoundToInt(opacity1 * 255) / 255.f;
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/5, opacity1));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/4, {1, 1, -0.1}));
  expected.push_back(scenic::NewSetHitTestBehaviorCmd(
      /*id=*/4, /*ignored*/ fuchsia::ui::gfx::HitTestBehavior::kSuppress));

  //
  // TransformLayer Child #2: PhysicalShapeLayer
  //
  expected.push_back(scenic::NewCreateEntityNodeCmd(/*id=*/7));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/3, /*child_id=*/7));
  expected.push_back(scenic::NewCreateOpacityNodeCmdHACK(/*id=*/8));
  expected.push_back(
      scenic::NewSetLabelCmd(/*id=*/7, "flutter::PhysicalShapeLayer"));
  expected.push_back(scenic::NewSetTranslationCmd(
      /*id=*/7, {0, 0, -kScenicZElevationBetweenLayers}));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/7, /*child_id=*/8));

  // Check opacity value. Extra rounding required because we pass alpha as
  // a uint/SkAlpha to SceneUpdateContext::Frame.
  float opacity2 = kOneMinusEpsilon * (127 / 255.f) * (127 / 255.f);
  opacity2 = SkScalarRoundToInt(opacity2 * 255) / 255.f;
  expected.push_back(scenic::NewSetOpacityCmd(/*id=*/8, opacity2));
  expected.push_back(scenic::NewSetClipPlanesCmd(/*id=*/7, /*ignored*/ {}));
  expected.push_back(scenic::NewCreateShapeNodeCmd(/*id=*/9));
  expected.push_back(scenic::NewCreateRectangleCmd(
      /*id=*/10, /*width=*/10, /*height=*/10));
  expected.push_back(scenic::NewSetShapeCmd(/*id=*/9, /*shape_id=*/10));
  expected.push_back(scenic::NewSetTranslationCmd(/*id=*/9, {5, 5, 0}));
  expected.push_back(scenic::NewCreateMaterialCmd(/*id=*/11));
  expected.push_back(scenic::NewSetMaterialCmd(/*id=*/9,
                                               /*material_id=*/11));
  expected.push_back(scenic::NewAddChildCmd(/*id=*/7,
                                            /*child_id=*/9));

  expected.push_back(scenic::NewCreateImageCmd(/*id=*/12, 0, 0, {}));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/7));
  expected.push_back(scenic::NewSetColorCmd(/*id=*/11, /*r*/ 255,
                                            /*g*/ 255,
                                            /*b*/ 255, /*a*/ 63));
  expected.push_back(
      scenic::NewSetTextureCmd(/*material_id=*/11, /*texture_id=*/12));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/11));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/10));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/9));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/8));
  expected.push_back(scenic::NewReleaseResourceCmd(/*id=*/3));

  test_context->mock_session.SetExpectedCommands(std::move(expected));

  // Finally, UpdateScene(). The MockSession will check the emitted
  // commands against the list above.
  root->UpdateScene(*(test_context->scene_update_context));

  test_context->session->Flush();

  // Run loop until idle, so that the Session receives and processes
  // its method calls.
  async_loop_run_until_idle(
      async_loop_from_dispatcher(async_get_default_dispatcher()));

  // Ensure we saw enough commands.
  EXPECT_EQ(46u, test_context->mock_session.num_enqueued_commands());
}

}  // namespace testing
}  // namespace flutter

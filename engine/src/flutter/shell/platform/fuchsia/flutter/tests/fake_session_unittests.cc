// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fakes/scenic/fake_session.h"

#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/async-testing/test_loop.h>
#include <lib/async/dispatcher.h>
#include <lib/ui/scenic/cpp/resources.h>
#include <lib/ui/scenic/cpp/session.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <zircon/types.h>

#include <memory>
#include <string>
#include <type_traits>
#include <vector>

#include "flutter/fml/logging.h"
#include "gmock/gmock.h"  // For EXPECT_THAT and matchers
#include "gtest/gtest.h"

#include "fakes/scenic/fake_resources.h"

using ::testing::_;
using ::testing::AllOf;
using ::testing::ElementsAre;
using ::testing::FieldsAre;
using ::testing::IsEmpty;
using ::testing::Matcher;
using ::testing::Not;
using ::testing::Pair;
using ::testing::Pointee;
using ::testing::SizeIs;
using ::testing::VariantWith;

namespace flutter_runner::testing {
namespace {

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

Matcher<FakeResource> IsEntityNode(
    Matcher<decltype(FakeResource::id)> id,
    Matcher<decltype(FakeResource::label)> label,
    Matcher<decltype(FakeNode::children)> children) {
  return FieldsAre(
      id, label, FakeResource::kDefaultEmptyEventMask,
      VariantWith<FakeEntityNode>(FieldsAre(
          FieldsAre(children, FakeNode::kDefaultZeroRotation,
                    FakeNode::kDefaultOneScale,
                    FakeNode::kDefaultZeroTranslation,
                    FakeNode::kDefaultZeroAnchor, FakeNode::kIsHitTestable,
                    FakeNode::kIsSemanticallyVisible),
          IsEmpty())));
}

Matcher<FakeSceneGraph> IsEmptySceneGraph() {
  return FieldsAre(IsEmpty(), IsEmpty(), IsEmpty(), kInvalidFakeResourceId);
}

MATCHER_P2(IsEntityNodeSceneGraph, node_label, node_id, "") {
  static_assert(std::is_same_v<FakeSceneGraph, std::decay_t<decltype(arg)>>);
  static_assert(
      std::is_constructible_v<std::string, std::decay_t<decltype(node_label)>>);
  static_assert(
      std::is_same_v<FakeResourceId, std::decay_t<decltype(node_id)>>);

  return ExplainMatchResult(
      FieldsAre(
          IsEmpty(),
          AllOf(SizeIs(1u),
                Contains(Pair(node_id, Pointee(IsEntityNode(node_id, node_label,
                                                            IsEmpty()))))),
          _, kInvalidFakeResourceId),
      arg, result_listener);
}

MATCHER_P5(IsBasicSceneGraph,
           view_label,
           node_label,
           view_holder_koid,
           view_ref_control_koid,
           view_ref_koid,
           "") {
  static_assert(std::is_same_v<FakeSceneGraph, std::decay_t<decltype(arg)>>);
  static_assert(
      std::is_constructible_v<std::string, std::decay_t<decltype(view_label)>>);
  static_assert(
      std::is_constructible_v<std::string, std::decay_t<decltype(node_label)>>);
  static_assert(
      std::is_same_v<zx_koid_t, std::decay_t<decltype(view_holder_koid)>>);
  static_assert(
      std::is_same_v<zx_koid_t, std::decay_t<decltype(view_ref_control_koid)>>);
  static_assert(
      std::is_same_v<zx_koid_t, std::decay_t<decltype(view_ref_koid)>>);

  return ExplainMatchResult(
      FieldsAre(
          IsEmpty(),
          AllOf(SizeIs(2u),
                Contains(Pair(arg.root_view_id,
                              Pointee(FieldsAre(
                                  arg.root_view_id, "",
                                  FakeResource::kDefaultEmptyEventMask,
                                  VariantWith<FakeView>(FieldsAre(
                                      view_holder_koid, view_ref_control_koid,
                                      view_ref_koid, view_label,
                                      ElementsAre(Pointee(IsEntityNode(
                                          _, node_label, IsEmpty()))),
                                      FakeView::kDebugBoundsDisbaled))))))),
          _, AllOf(Not(kInvalidFakeResourceId), arg.root_view_id)),
      arg, result_listener);
}

}  // namespace

class FakeSessionTest : public ::testing::Test,
                        public fuchsia::ui::scenic::SessionListener {
 protected:
  FakeSessionTest()
      : session_listener_(this), session_subloop_(loop_.StartNewLoop()) {}
  ~FakeSessionTest() override = default;

  async::TestLoop& loop() { return loop_; }

  FakeSession& fake_session() { return fake_session_; }

  scenic::Session CreateSession() {
    FML_CHECK(!fake_session_.is_bound());
    FML_CHECK(!session_listener_.is_bound());

    auto [session, session_listener] =
        fake_session_.Bind(session_subloop_->dispatcher());
    session_listener_.Bind(std::move(session_listener));

    return scenic::Session(session.Bind());
  }

 private:
  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicError(std::string error) override { FAIL(); }

  // |fuchsia::ui::scenic::SessionListener|
  void OnScenicEvent(std::vector<fuchsia::ui::scenic::Event> events) override {
    FAIL();
  }

  async::TestLoop loop_;  // Must come before FIDL bindings.

  fuchsia::ui::scenic::SessionPtr session_ptr_;
  fidl::Binding<fuchsia::ui::scenic::SessionListener> session_listener_;

  std::unique_ptr<async::LoopInterface> session_subloop_;
  FakeSession fake_session_;
};

TEST_F(FakeSessionTest, Initialization) {
  EXPECT_EQ(fake_session().debug_name(), "");
  EXPECT_EQ(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Pump the loop one time; the session should retain its initial state.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_session().debug_name(), "");
  EXPECT_EQ(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());
}

TEST_F(FakeSessionTest, DebugLabel) {
  scenic::Session session = CreateSession();

  // Set the session's debug name.  The `SetDebugName` hasn't been processed
  // yet, so the session's view of the debug name is still empty.
  const std::string kDebugLabel = GetCurrentTestName();
  session.SetDebugName(kDebugLabel);
  session.Flush();  // Bypass local command caching.
  EXPECT_EQ(fake_session().debug_name(), "");

  // Pump the loop; the contents of the initial `SetDebugName` should be
  // processed.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_session().debug_name(), kDebugLabel);
}

TEST_F(FakeSessionTest, CommandQueueInvariants) {
  scenic::Session session = CreateSession();

  // The scene graph is initially empty.
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Create entity node for testing; no creation commands have been processed
  // yet, so the session's view of the scene graph is empty.
  std::optional<scenic::EntityNode> node(&session);
  session.Flush();  // Bypass local command caching.
  EXPECT_EQ(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Pump the loop; the initial creation command should be enqueued but still
  // not processed yet, so the session's view of the scene graph is empty.
  loop().RunUntilIdle();
  EXPECT_GT(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Present initial scene graph.  The `Present` hasn't been processed yet, so
  // the session's view of the scene graph is still empty.
  session.Present2(0u, 0u, [](auto...) {});
  EXPECT_GT(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Pump the loop; the contents of the initial `Present` should be processed.
  loop().RunUntilIdle();
  EXPECT_EQ(fake_session().command_queue().size(), 0u);
  EXPECT_THAT(fake_session().SceneGraph(),
              IsEntityNodeSceneGraph("", node->id()));
}

TEST_F(FakeSessionTest, SimpleResourceLifecycle) {
  scenic::Session session = CreateSession();

  // The scene graph is initially empty.
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Present an initial entity node, pumping the loop to process commands.
  std::optional<scenic::EntityNode> node(&session);
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  EXPECT_THAT(fake_session().SceneGraph(),
              IsEntityNodeSceneGraph("", node->id()));

  // Present a simple property update on the test entity node.
  const std::string kNodeLabel = "EntityNode";
  node->SetLabel(kNodeLabel);
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  EXPECT_THAT(fake_session().SceneGraph(),
              IsEntityNodeSceneGraph(kNodeLabel, node->id()));

  // Present the destruction of the entity node.
  node.reset();
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());
}

TEST_F(FakeSessionTest, ResourceReferenceCounting) {
  scenic::Session session = CreateSession();

  // Present a chain of 4 entity nodes for testing.
  std::array<std::optional<scenic::EntityNode>, 4> nodes{
      std::optional<scenic::EntityNode>(&session),
      std::optional<scenic::EntityNode>(&session),
      std::optional<scenic::EntityNode>(&session),
      std::optional<scenic::EntityNode>(&session)};
  const std::string kNodeLabel = "EntityNode";
  for (size_t i = 0; i < 4; i++) {
    nodes[i]->SetLabel(kNodeLabel + std::string(1, '0' + i));
    if (i < 3) {
      nodes[i]->AddChild(*nodes[i + 1]);
    }
  }
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  {
    auto scene_graph = fake_session().SceneGraph();
    EXPECT_EQ(scene_graph.root_view_id, kInvalidFakeResourceId);
    EXPECT_EQ(scene_graph.buffer_collection_map.size(), 0u);
    EXPECT_EQ(scene_graph.resource_map.size(), 4u);
    EXPECT_EQ(scene_graph.label_map.size(), 4u);
    for (size_t i = 0; i < 4; i++) {
      const std::string node_i_label = kNodeLabel + std::string(1, '0' + i);
      ASSERT_EQ(scene_graph.resource_map.count(nodes[i]->id()), 1u);
      ASSERT_EQ(scene_graph.label_map.count(node_i_label), 1u);

      const auto node_i = scene_graph.resource_map[nodes[i]->id()];
      const auto node_i_label_resources = scene_graph.label_map[node_i_label];
      EXPECT_EQ(node_i_label_resources.size(), 1u);
      EXPECT_FALSE(node_i_label_resources[0].expired());
      EXPECT_EQ(node_i_label_resources[0].lock(), node_i);
    }

    EXPECT_THAT(
        scene_graph.resource_map[nodes[0]->id()],
        Pointee(IsEntityNode(
            nodes[0]->id(), kNodeLabel + std::string(1, '0'),
            ElementsAre(Pointee(IsEntityNode(
                nodes[1]->id(), kNodeLabel + std::string(1, '1'),
                ElementsAre(Pointee(IsEntityNode(
                    nodes[2]->id(), kNodeLabel + std::string(1, '2'),
                    ElementsAre(Pointee(IsEntityNode(
                        nodes[3]->id(), kNodeLabel + std::string(1, '3'),
                        IsEmpty()))))))))))));
  }

  // Destroy node #0.  It should be dropped immediately since it has no parent.
  nodes[0].reset();
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  {
    auto scene_graph = fake_session().SceneGraph();
    EXPECT_EQ(scene_graph.root_view_id, kInvalidFakeResourceId);
    EXPECT_EQ(scene_graph.buffer_collection_map.size(), 0u);
    EXPECT_EQ(scene_graph.resource_map.size(), 3u);
    EXPECT_EQ(scene_graph.label_map.size(), 3u);
    for (size_t i = 1; i < 4; i++) {
      const std::string node_i_label = kNodeLabel + std::string(1, '0' + i);
      ASSERT_EQ(scene_graph.resource_map.count(nodes[i]->id()), 1u);
      ASSERT_EQ(scene_graph.label_map.count(node_i_label), 1u);

      const auto node_i = scene_graph.resource_map[nodes[i]->id()];
      const auto node_i_label_resources = scene_graph.label_map[node_i_label];
      EXPECT_EQ(node_i_label_resources.size(), 1u);
      EXPECT_FALSE(node_i_label_resources[0].expired());
      EXPECT_EQ(node_i_label_resources[0].lock(), node_i);
    }

    EXPECT_EQ(scene_graph.resource_map.count(nodes[0]->id()), 0u);
    EXPECT_THAT(scene_graph.resource_map[nodes[1]->id()],
                Pointee(IsEntityNode(
                    nodes[1]->id(), kNodeLabel + std::string(1, '1'),
                    ElementsAre(Pointee(IsEntityNode(
                        nodes[2]->id(), kNodeLabel + std::string(1, '2'),
                        ElementsAre(Pointee(IsEntityNode(
                            nodes[3]->id(), kNodeLabel + std::string(1, '3'),
                            IsEmpty())))))))));
  }

  // Destroy node #2.  It should still exist in the tree and the labels map
  // because it has a parent, but it is removed from the resource map.
  nodes[2].reset();
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  {
    auto scene_graph = fake_session().SceneGraph();
    EXPECT_EQ(scene_graph.root_view_id, kInvalidFakeResourceId);
    EXPECT_EQ(scene_graph.buffer_collection_map.size(), 0u);
    EXPECT_EQ(scene_graph.resource_map.size(), 2u);
    EXPECT_EQ(scene_graph.label_map.size(), 3u);
    for (size_t i = 1; i < 4; i++) {
      const std::string node_i_label = kNodeLabel + std::string(1, '0' + i);
      ASSERT_EQ(scene_graph.label_map.count(node_i_label), 1u);
      ASSERT_EQ(scene_graph.resource_map.count(nodes[i]->id()),
                i != 2 ? 1u : 0u);

      const auto node_i_label_resources = scene_graph.label_map[node_i_label];
      EXPECT_EQ(node_i_label_resources.size(), 1u);
      EXPECT_FALSE(node_i_label_resources[0].expired());

      if (i != 2) {
        const auto node_i = scene_graph.resource_map[nodes[i]->id()];
        EXPECT_EQ(node_i_label_resources[0].lock(), node_i);
      } else {
        EXPECT_EQ(scene_graph.resource_map.count(nodes[i]->id()), 0u);
      }
    }

    EXPECT_THAT(scene_graph.resource_map[nodes[1]->id()],
                Pointee(IsEntityNode(
                    nodes[1]->id(), kNodeLabel + std::string(1, '1'),
                    ElementsAre(Pointee(IsEntityNode(
                        nodes[2]->id(), kNodeLabel + std::string(1, '2'),
                        ElementsAre(Pointee(IsEntityNode(
                            nodes[3]->id(), kNodeLabel + std::string(1, '3'),
                            IsEmpty())))))))));
  }

  // Destroy node #3.  It should still exist in the tree and the labels map
  // because it has a grand-parent, but it is removed from the resource map.
  nodes[3].reset();
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  {
    auto scene_graph = fake_session().SceneGraph();
    EXPECT_EQ(scene_graph.root_view_id, kInvalidFakeResourceId);
    EXPECT_EQ(scene_graph.buffer_collection_map.size(), 0u);
    EXPECT_EQ(scene_graph.resource_map.size(), 1u);
    EXPECT_EQ(scene_graph.label_map.size(), 3u);
    for (size_t i = 1; i < 4; i++) {
      const std::string node_i_label = kNodeLabel + std::string(1, '0' + i);
      ASSERT_EQ(scene_graph.label_map.count(node_i_label), 1u);
      ASSERT_EQ(scene_graph.resource_map.count(nodes[i]->id()),
                i < 2 ? 1u : 0u);

      const auto node_i_label_resources = scene_graph.label_map[node_i_label];
      EXPECT_EQ(node_i_label_resources.size(), 1u);
      EXPECT_FALSE(node_i_label_resources[0].expired());

      if (i < 2) {
        const auto node_i = scene_graph.resource_map[nodes[i]->id()];
        EXPECT_EQ(node_i_label_resources[0].lock(), node_i);
      } else {
        EXPECT_EQ(scene_graph.resource_map.count(nodes[i]->id()), 0u);
      }
    }

    EXPECT_THAT(scene_graph.resource_map[nodes[1]->id()],
                Pointee(IsEntityNode(
                    nodes[1]->id(), kNodeLabel + std::string(1, '1'),
                    ElementsAre(Pointee(IsEntityNode(
                        nodes[2]->id(), kNodeLabel + std::string(1, '2'),
                        ElementsAre(Pointee(IsEntityNode(
                            nodes[3]->id(), kNodeLabel + std::string(1, '3'),
                            IsEmpty())))))))));
  }
}

TEST_F(FakeSessionTest, BasicSceneGraph) {
  scenic::Session session = CreateSession();

  // The scene graph is initially empty.
  EXPECT_THAT(fake_session().SceneGraph(), IsEmptySceneGraph());

  // Create and present initial scene graph.
  const std::string kViewDebugString = GetCurrentTestName();
  const std::string kNodeLabel = "ChildNode";
  fuchsia::ui::views::ViewRef view_ref;
  auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();
  auto view_ref_pair = scenic::ViewRefPair::New();
  view_ref_pair.view_ref.Clone(&view_ref);
  scenic::View root_view(&session, std::move(view_token),
                         std::move(view_ref_pair.control_ref),
                         std::move(view_ref_pair.view_ref), kViewDebugString);
  scenic::EntityNode child_node(&session);
  child_node.SetLabel(kNodeLabel);
  root_view.AddChild(child_node);
  session.Present2(0u, 0u, [](auto...) {});
  loop().RunUntilIdle();
  EXPECT_THAT(fake_session().SceneGraph(),
              IsBasicSceneGraph(kViewDebugString, kNodeLabel,
                                GetPeerKoid(view_holder_token.value.get()),
                                GetPeerKoid(view_ref.reference.get()),
                                GetKoid(view_ref.reference.get())));
}

}  // namespace flutter_runner::testing

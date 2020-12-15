// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atk/atk.h>
#include <dlfcn.h>
#include <utility>
#include <vector>

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/platform/atk_util_auralinux.h"
#include "ui/accessibility/platform/ax_platform_node_auralinux.h"
#include "ui/accessibility/platform/ax_platform_node_unittest.h"
#include "ui/accessibility/platform/test_ax_node_wrapper.h"

namespace ui {

class AXPlatformNodeAuraLinuxTest : public AXPlatformNodeTest {
 public:
  AXPlatformNodeAuraLinuxTest() = default;
  ~AXPlatformNodeAuraLinuxTest() override = default;
  AXPlatformNodeAuraLinuxTest(const AXPlatformNodeAuraLinuxTest&) = delete;
  AXPlatformNodeAuraLinuxTest& operator=(const AXPlatformNodeAuraLinuxTest&) =
      delete;

  void SetUp() override {
    AXPlatformNode::NotifyAddAXModeFlags(kAXModeComplete);
  }

 protected:
  AXPlatformNodeAuraLinux* GetPlatformNode(AXNode* node) {
    TestAXNodeWrapper* wrapper =
        TestAXNodeWrapper::GetOrCreate(GetTree(), node);
    if (!wrapper)
      return nullptr;
    return static_cast<AXPlatformNodeAuraLinux*>(wrapper->ax_platform_node());
  }

  AXPlatformNodeAuraLinux* GetRootPlatformNode() {
    return GetPlatformNode(GetRootAsAXNode());
  }

  AtkObject* AtkObjectFromNode(AXNode* node) {
    if (AXPlatformNode* ax_platform_node = GetPlatformNode(node)) {
      return ax_platform_node->GetNativeViewAccessible();
    } else {
      return nullptr;
    }
  }

  TestAXNodeWrapper* GetRootWrapper() {
    return TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
  }

  AtkObject* GetRootAtkObject() { return AtkObjectFromNode(GetRootAsAXNode()); }
};

static void EnsureAtkObjectHasAttributeWithValue(AtkObject* atk_object,
                                                 const gchar* attribute_name,
                                                 const gchar* attribute_value) {
  AtkAttributeSet* attributes = atk_object_get_attributes(atk_object);
  bool saw_attribute = false;

  AtkAttributeSet* current = attributes;
  while (current) {
    AtkAttribute* attribute = static_cast<AtkAttribute*>(current->data);

    if (0 == strcmp(attribute_name, attribute->name)) {
      // Ensure that we only see this attribute once.
      ASSERT_FALSE(saw_attribute) << attribute_name;

      EXPECT_STREQ(attribute_value, attribute->value);
      saw_attribute = true;
    }

    current = current->next;
  }

  ASSERT_TRUE(saw_attribute);
  atk_attribute_set_free(attributes);
}

static void EnsureAtkObjectDoesNotHaveAttribute(AtkObject* atk_object,
                                                const gchar* attribute_name) {
  AtkAttributeSet* attributes = atk_object_get_attributes(atk_object);
  AtkAttributeSet* current = attributes;
  while (current) {
    AtkAttribute* attribute = static_cast<AtkAttribute*>(current->data);
    ASSERT_STRNE(attribute_name, attribute->name) << attribute_name;
    current = current->next;
  }
  atk_attribute_set_free(attributes);
}

static void SetStringAttributeOnNode(
    AXNode* ax_node,
    ax::mojom::StringAttribute attribute,
    const char* attribute_value,
    base::Optional<ax::mojom::Role> role = base::nullopt) {
  AXNodeData new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  new_data.id = ax_node->data().id;
  new_data.AddStringAttribute(attribute, attribute_value);
  ax_node->SetData(new_data);
}

static void TestAtkObjectIntAttribute(
    AXNode* ax_node,
    AtkObject* atk_object,
    ax::mojom::IntAttribute mojom_attribute,
    const gchar* attribute_name,
    base::Optional<ax::mojom::Role> role = base::nullopt) {
  AXNodeData new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  ax_node->SetData(new_data);
  EnsureAtkObjectDoesNotHaveAttribute(atk_object, attribute_name);

  std::pair<int, const char*> tests[] = {
      std::make_pair(0, "0"),       std::make_pair(1, "1"),
      std::make_pair(2, "2"),       std::make_pair(-100, "-100"),
      std::make_pair(1000, "1000"),
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    AXNodeData new_data = AXNodeData();
    new_data.role = role.value_or(ax::mojom::Role::kApplication);
    new_data.id = ax_node->data().id;
    new_data.AddIntAttribute(mojom_attribute, tests[i].first);
    ax_node->SetData(new_data);
    EnsureAtkObjectHasAttributeWithValue(atk_object, attribute_name,
                                         tests[i].second);
  }
}

static void TestAtkObjectStringAttribute(
    AXNode* ax_node,
    AtkObject* atk_object,
    ax::mojom::StringAttribute mojom_attribute,
    const gchar* attribute_name,
    base::Optional<ax::mojom::Role> role = base::nullopt) {
  AXNodeData new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  ax_node->SetData(new_data);
  EnsureAtkObjectDoesNotHaveAttribute(atk_object, attribute_name);

  const char* tests[] = {
      "", "a string with spaces", "a string with , a comma",
      "\xE2\x98\xBA",  // The smiley emoji.
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    SetStringAttributeOnNode(ax_node, mojom_attribute, tests[i], role);
    EnsureAtkObjectHasAttributeWithValue(atk_object, attribute_name, tests[i]);
  }
}

static void TestAtkObjectBoolAttribute(
    AXNode* ax_node,
    AtkObject* atk_object,
    ax::mojom::BoolAttribute mojom_attribute,
    const gchar* attribute_name,
    base::Optional<ax::mojom::Role> role = base::nullopt) {
  AXNodeData new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  ax_node->SetData(new_data);
  EnsureAtkObjectDoesNotHaveAttribute(atk_object, attribute_name);

  new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  new_data.id = ax_node->data().id;
  new_data.AddBoolAttribute(mojom_attribute, true);
  ax_node->SetData(new_data);
  EnsureAtkObjectHasAttributeWithValue(atk_object, attribute_name, "true");

  new_data = AXNodeData();
  new_data.role = role.value_or(ax::mojom::Role::kApplication);
  new_data.id = ax_node->data().id;
  new_data.AddBoolAttribute(mojom_attribute, false);
  ax_node->SetData(new_data);
  EnsureAtkObjectHasAttributeWithValue(atk_object, attribute_name, "false");
}

static bool AtkObjectHasState(AtkObject* atk_object, AtkStateType state) {
  AtkStateSet* state_set = atk_object_ref_state_set(atk_object);
  EXPECT_TRUE(ATK_IS_STATE_SET(state_set));
  bool in_state_set = atk_state_set_contains_state(state_set, state);
  g_object_unref(state_set);
  return in_state_set;
}

//
// AtkObject tests
//
#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 16, 0)
#define ATK_216
#endif

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectDetachedObject) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("Name");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  const gchar* name = atk_object_get_name(root_obj);
  EXPECT_STREQ("Name", name);

  AtkStateSet* state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  EXPECT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_DEFUNCT));
  g_object_unref(state_set);

  // Create an empty tree.
  SetTree(std::make_unique<AXTree>());
  EXPECT_EQ(nullptr, atk_object_get_name(root_obj));

  state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  EXPECT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_DEFUNCT));
  g_object_unref(state_set);

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectName) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("Name");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  const gchar* name = atk_object_get_name(root_obj);
  EXPECT_STREQ("Name", name);

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectDescription) {
  AXNodeData root;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kDescription,
                          "Description");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  const gchar* description = atk_object_get_description(root_obj);
  EXPECT_STREQ("Description", description);

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectRole) {
  AXNodeData root;
  root.id = 1;
  root.child_ids.push_back(2);
  root.role = ax::mojom::Role::kApplication;

  AXNodeData child;
  child.id = 2;

  Init(root, child);
  AXNode* child_node = GetRootAsAXNode()->children()[0];

  AtkObject* root_obj(AtkObjectFromNode(GetRootAsAXNode()));
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);
  EXPECT_EQ(ATK_ROLE_APPLICATION, atk_object_get_role(root_obj));
  g_object_unref(root_obj);

  child.role = ax::mojom::Role::kAlert;
  child_node->SetData(child);
  AtkObject* child_obj(AtkObjectFromNode(child_node));
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_NOTIFICATION, atk_object_get_role(child_obj));
  g_object_unref(child_obj);

  child.role = ax::mojom::Role::kAlertDialog;
  child_node->SetData(child);
  child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_ALERT, atk_object_get_role(child_obj));
  g_object_unref(child_obj);

  child.role = ax::mojom::Role::kButton;
  child_node->SetData(child);
  child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_PUSH_BUTTON, atk_object_get_role(child_obj));
  g_object_unref(child_obj);

  child.role = ax::mojom::Role::kCanvas;
  child_node->SetData(child);
  child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_CANVAS, atk_object_get_role(child_obj));
  g_object_unref(child_obj);

  child.role = ax::mojom::Role::kApplication;
  child_node->SetData(child);
  child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_EMBEDDED, atk_object_get_role(child_obj));
  g_object_unref(child_obj);

  child.role = ax::mojom::Role::kWindow;
  child_node->SetData(child);
  child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  g_object_ref(child_obj);
  EXPECT_EQ(ATK_ROLE_FRAME, atk_object_get_role(child_obj));
  g_object_unref(child_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectState) {
  AXNodeData root;
  root.id = 1;
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  AtkStateSet* state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_ENABLED));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_SENSITIVE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_SHOWING));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_VISIBLE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_BUSY));
#if defined(ATK_216)
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_CHECKABLE));
#endif
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_CHECKED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_DEFAULT));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_EDITABLE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDABLE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_FOCUSABLE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_FOCUSED));
#if defined(ATK_216)
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_HAS_POPUP));
#endif
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_HORIZONTAL));
  ASSERT_FALSE(
      atk_state_set_contains_state(state_set, ATK_STATE_INVALID_ENTRY));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_MODAL));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_MULTI_LINE));
  ASSERT_FALSE(
      atk_state_set_contains_state(state_set, ATK_STATE_MULTISELECTABLE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_REQUIRED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_SELECTABLE));
  ASSERT_FALSE(
      atk_state_set_contains_state(state_set, ATK_STATE_SELECTABLE_TEXT));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_SELECTED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_SINGLE_LINE));
  ASSERT_FALSE(atk_state_set_contains_state(state_set,
                                            ATK_STATE_SUPPORTS_AUTOCOMPLETION));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_VERTICAL));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_VISITED));
  g_object_unref(state_set);

  root = AXNodeData();
  root.AddState(ax::mojom::State::kDefault);
  root.AddState(ax::mojom::State::kEditable);
  root.AddState(ax::mojom::State::kExpanded);
  root.AddState(ax::mojom::State::kFocusable);
  root.AddState(ax::mojom::State::kMultiselectable);
  root.AddState(ax::mojom::State::kRequired);
  root.AddState(ax::mojom::State::kVertical);
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kBusy, true);
  root.SetInvalidState(ax::mojom::InvalidState::kTrue);
  root.AddStringAttribute(ax::mojom::StringAttribute::kAutoComplete, "foo");
  GetRootAsAXNode()->SetData(root);

  state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_BUSY));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_DEFAULT));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_EDITABLE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDABLE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDED));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_FOCUSABLE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_INVALID_ENTRY));
  ASSERT_TRUE(
      atk_state_set_contains_state(state_set, ATK_STATE_MULTISELECTABLE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_REQUIRED));
  ASSERT_TRUE(atk_state_set_contains_state(state_set,
                                           ATK_STATE_SUPPORTS_AUTOCOMPLETION));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_VERTICAL));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_FOCUSED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_HORIZONTAL));
  g_object_unref(state_set);

  root = AXNodeData();
  root.AddState(ax::mojom::State::kCollapsed);
  root.AddState(ax::mojom::State::kHorizontal);
  root.AddState(ax::mojom::State::kVisited);
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  root.SetHasPopup(ax::mojom::HasPopup::kTrue);
  GetRootAsAXNode()->SetData(root);

  state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDABLE));
#if defined(ATK_216)
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_HAS_POPUP));
#endif
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_HORIZONTAL));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_SELECTABLE));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_SELECTED));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_VISITED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_EXPANDED));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_VERTICAL));
  g_object_unref(state_set);

  root = AXNodeData();
  root.AddState(ax::mojom::State::kInvisible);
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kModal, true);
  GetRootAsAXNode()->SetData(root);

  state_set = atk_object_ref_state_set(root_obj);
  ASSERT_TRUE(ATK_IS_STATE_SET(state_set));
  ASSERT_TRUE(atk_state_set_contains_state(state_set, ATK_STATE_MODAL));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_SHOWING));
  ASSERT_FALSE(atk_state_set_contains_state(state_set, ATK_STATE_VISIBLE));
  g_object_unref(state_set);

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectChildAndParent) {
  AXNodeData root;
  root.id = 1;
  root.child_ids.push_back(2);
  root.child_ids.push_back(3);

  AXNodeData button;
  button.role = ax::mojom::Role::kButton;
  button.id = 2;

  AXNodeData checkbox;
  checkbox.role = ax::mojom::Role::kCheckBox;
  checkbox.id = 3;

  Init(root, button, checkbox);
  AXNode* button_node = GetRootAsAXNode()->children()[0];
  AXNode* checkbox_node = GetRootAsAXNode()->children()[1];
  AtkObject* root_obj = GetRootAtkObject();
  AtkObject* button_obj = AtkObjectFromNode(button_node);
  AtkObject* checkbox_obj = AtkObjectFromNode(checkbox_node);

  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  EXPECT_EQ(2, atk_object_get_n_accessible_children(root_obj));
  ASSERT_TRUE(ATK_IS_OBJECT(button_obj));
  EXPECT_EQ(0, atk_object_get_n_accessible_children(button_obj));
  ASSERT_TRUE(ATK_IS_OBJECT(checkbox_obj));
  EXPECT_EQ(0, atk_object_get_n_accessible_children(checkbox_obj));

  {
    AtkObject* result = atk_object_ref_accessible_child(root_obj, 0);
    EXPECT_TRUE(ATK_IS_OBJECT(root_obj));
    EXPECT_EQ(result, button_obj);
    g_object_unref(result);
  }
  {
    AtkObject* result = atk_object_ref_accessible_child(root_obj, 1);
    EXPECT_TRUE(ATK_IS_OBJECT(root_obj));
    EXPECT_EQ(result, checkbox_obj);
    g_object_unref(result);
  }

  // Now check parents.
  {
    AtkObject* result = atk_object_get_parent(button_obj);
    EXPECT_TRUE(ATK_IS_OBJECT(result));
    EXPECT_EQ(result, root_obj);
  }
  {
    AtkObject* result = atk_object_get_parent(checkbox_obj);
    EXPECT_TRUE(ATK_IS_OBJECT(result));
    EXPECT_EQ(result, root_obj);
  }

  // Test invalid indices.
  AtkObject* result = atk_object_ref_accessible_child(root_obj, -1);
  EXPECT_EQ(result, nullptr);
  result = atk_object_ref_accessible_child(root_obj, -88);
  EXPECT_EQ(result, nullptr);
  result = atk_object_ref_accessible_child(root_obj, 3);
  EXPECT_EQ(result, nullptr);
  result = atk_object_ref_accessible_child(root_obj, 1000);
  EXPECT_EQ(result, nullptr);
  result = atk_object_ref_accessible_child(root_obj, 828282);
  EXPECT_EQ(result, nullptr);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectIndexInParent) {
  AXNodeData root;
  root.id = 1;
  root.child_ids.push_back(2);
  root.child_ids.push_back(3);

  AXNodeData left;
  left.id = 2;

  AXNodeData right;
  right.id = 3;

  Init(root, left, right);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  AtkObject* left_obj = atk_object_ref_accessible_child(root_obj, 0);
  ASSERT_TRUE(ATK_IS_OBJECT(left_obj));
  AtkObject* right_obj = atk_object_ref_accessible_child(root_obj, 1);
  ASSERT_TRUE(ATK_IS_OBJECT(right_obj));

  EXPECT_EQ(0, atk_object_get_index_in_parent(left_obj));
  EXPECT_EQ(1, atk_object_get_index_in_parent(right_obj));

  g_object_unref(left_obj);
  g_object_unref(right_obj);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectStringAttributes) {
  AXNodeData root_data;
  root_data.id = 1;

  Init(root_data);

  AXNode* root_node = GetRootAsAXNode();
  AtkObject* root_atk_object(AtkObjectFromNode(root_node));
  ASSERT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  std::pair<ax::mojom::StringAttribute, const char*> tests[] = {
      std::make_pair(ax::mojom::StringAttribute::kDisplay, "display"),
      std::make_pair(ax::mojom::StringAttribute::kHtmlTag, "tag"),
      std::make_pair(ax::mojom::StringAttribute::kRole, "xml-roles"),
      std::make_pair(ax::mojom::StringAttribute::kPlaceholder, "placeholder"),
      std::make_pair(ax::mojom::StringAttribute::kRoleDescription,
                     "roledescription"),
      std::make_pair(ax::mojom::StringAttribute::kKeyShortcuts, "keyshortcuts"),
      std::make_pair(ax::mojom::StringAttribute::kLiveStatus, "live"),
      std::make_pair(ax::mojom::StringAttribute::kLiveRelevant, "relevant"),
      std::make_pair(ax::mojom::StringAttribute::kContainerLiveStatus,
                     "container-live"),
      std::make_pair(ax::mojom::StringAttribute::kContainerLiveRelevant,
                     "container-relevant"),
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    TestAtkObjectStringAttribute(root_node, root_atk_object, tests[i].first,
                                 tests[i].second);
  }

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectBoolAttributes) {
  AXNodeData root_data;
  root_data.id = 1;

  Init(root_data);

  AXNode* root_node = GetRootAsAXNode();
  AtkObject* root_atk_object(AtkObjectFromNode(root_node));
  ASSERT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  std::pair<ax::mojom::BoolAttribute, const char*> tests[] = {
      std::make_pair(ax::mojom::BoolAttribute::kLiveAtomic, "atomic"),
      std::make_pair(ax::mojom::BoolAttribute::kBusy, "busy"),
      std::make_pair(ax::mojom::BoolAttribute::kContainerLiveAtomic,
                     "container-atomic"),
      std::make_pair(ax::mojom::BoolAttribute::kContainerLiveBusy,
                     "container-busy"),
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    TestAtkObjectBoolAttribute(root_node, root_atk_object, tests[i].first,
                               tests[i].second);
  }

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, DISABLED_TestAtkObjectIntAttributes) {
  AXNodeData root_data;
  root_data.id = 1;
  Init(root_data);

  AXNode* root_node = GetRootAsAXNode();
  AtkObject* root_atk_object(AtkObjectFromNode(root_node));
  ASSERT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kHierarchicalLevel,
                            "level");
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaColumnCount,
                            "colcount", ax::mojom::Role::kTable);
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaColumnCount,
                            "colcount", ax::mojom::Role::kGrid);
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaColumnCount,
                            "colcount", ax::mojom::Role::kTreeGrid);

  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaRowCount, "rowcount",
                            ax::mojom::Role::kTable);
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaRowCount, "rowcount",
                            ax::mojom::Role::kGrid);
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaRowCount, "rowcount",
                            ax::mojom::Role::kTreeGrid);

  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaCellColumnIndex,
                            "colindex", ax::mojom::Role::kCell);
  TestAtkObjectIntAttribute(root_node, root_atk_object,
                            ax::mojom::IntAttribute::kAriaCellRowIndex,
                            "rowindex", ax::mojom::Role::kCell);

  g_object_unref(root_atk_object);
}

//
// AtkComponent tests
//

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkComponentRefAtPoint) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 30, 30);

  AXNodeData node1;
  node1.id = 2;
  node1.role = ax::mojom::Role::kGenericContainer;
  node1.relative_bounds.bounds = gfx::RectF(0, 0, 10, 10);
  node1.SetName("Name1");
  root.child_ids.push_back(node1.id);

  AXNodeData node2;
  node2.id = 3;
  node2.role = ax::mojom::Role::kGenericContainer;
  node2.relative_bounds.bounds = gfx::RectF(20, 20, 10, 10);
  node2.SetName("Name2");
  root.child_ids.push_back(node2.id);

  Init(root, node1, node2);

  AtkObject* root_obj(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_obj));
  EXPECT_TRUE(ATK_IS_COMPONENT(root_obj));
  g_object_ref(root_obj);

  AtkObject* child_obj = atk_component_ref_accessible_at_point(
      ATK_COMPONENT(root_obj), 50, 50, ATK_XY_SCREEN);
  EXPECT_EQ(nullptr, child_obj);

  // this is directly on node 1.
  child_obj = atk_component_ref_accessible_at_point(ATK_COMPONENT(root_obj), 5,
                                                    5, ATK_XY_SCREEN);
  ASSERT_NE(nullptr, child_obj);
  EXPECT_TRUE(ATK_IS_OBJECT(child_obj));

  const gchar* name = atk_object_get_name(child_obj);
  EXPECT_STREQ("Name1", name);

  g_object_unref(child_obj);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkComponentsGetExtentsPositionSize) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  root.relative_bounds.bounds = gfx::RectF(10, 40, 800, 600);
  root.child_ids.push_back(2);

  AXNodeData child;
  child.id = 2;
  child.relative_bounds.bounds = gfx::RectF(100, 150, 200, 200);
  Init(root, child);

  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(100, 200));

  AtkObject* root_obj = GetRootAtkObject();
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_COMPONENT(root_obj));
  g_object_ref(root_obj);

  gint x_left, y_top, width, height;
  atk_component_get_extents(ATK_COMPONENT(root_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(110, x_left);
  EXPECT_EQ(240, y_top);
  EXPECT_EQ(800, width);
  EXPECT_EQ(600, height);

  AtkObject* hit_test_result = atk_component_ref_accessible_at_point(
      ATK_COMPONENT(root_obj), x_left, y_top, ATK_XY_SCREEN);
  ASSERT_EQ(hit_test_result, root_obj);
  g_object_unref(hit_test_result);

  atk_component_get_position(ATK_COMPONENT(root_obj), &x_left, &y_top,
                             ATK_XY_SCREEN);
  EXPECT_EQ(110, x_left);
  EXPECT_EQ(240, y_top);

  atk_component_get_extents(ATK_COMPONENT(root_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_WINDOW);
  EXPECT_EQ(0, x_left);
  EXPECT_EQ(0, y_top);
  EXPECT_EQ(800, width);
  EXPECT_EQ(600, height);

  hit_test_result = atk_component_ref_accessible_at_point(
      ATK_COMPONENT(root_obj), x_left + 2, y_top + 2, ATK_XY_WINDOW);
  ASSERT_EQ(hit_test_result, root_obj);
  g_object_unref(hit_test_result);

  atk_component_get_position(ATK_COMPONENT(root_obj), &x_left, &y_top,
                             ATK_XY_WINDOW);
  EXPECT_EQ(0, x_left);
  EXPECT_EQ(0, y_top);

  atk_component_get_size(ATK_COMPONENT(root_obj), &width, &height);
  EXPECT_EQ(800, width);
  EXPECT_EQ(600, height);

  AXNode* child_node = GetRootAsAXNode()->children()[0];
  AtkObject* child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  ASSERT_TRUE(ATK_IS_COMPONENT(child_obj));
  g_object_ref(child_obj);

  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(200, x_left);
  EXPECT_EQ(350, y_top);
  EXPECT_EQ(200, width);
  EXPECT_EQ(200, height);

  hit_test_result = atk_component_ref_accessible_at_point(
      ATK_COMPONENT(root_obj), x_left, y_top, ATK_XY_SCREEN);
  ASSERT_EQ(hit_test_result, child_obj);
  g_object_unref(hit_test_result);

  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_WINDOW);
  EXPECT_EQ(90, x_left);
  EXPECT_EQ(110, y_top);
  EXPECT_EQ(200, width);
  EXPECT_EQ(200, height);

  hit_test_result = atk_component_ref_accessible_at_point(
      ATK_COMPONENT(root_obj), x_left, y_top, ATK_XY_WINDOW);
  ASSERT_EQ(hit_test_result, child_obj);
  g_object_unref(hit_test_result);

  atk_component_get_extents(ATK_COMPONENT(child_obj), nullptr, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(200, height);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, nullptr, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(200, x_left);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, nullptr,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(350, y_top);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            nullptr, ATK_XY_SCREEN);
  EXPECT_EQ(200, width);

  g_object_unref(child_obj);
  g_object_unref(root_obj);

  // Un-set the global offset so that it doesn't affect subsequent tests.
  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(0, 0));
}

#if ATK_CHECK_VERSION(2, 30, 0)
typedef bool (*ScrollToPointFunc)(AtkComponent* component,
                                  AtkCoordType coords,
                                  gint x,
                                  gint y);
typedef bool (*ScrollToFunc)(AtkComponent* component, AtkScrollType type);

TEST_F(AXPlatformNodeAuraLinuxTest, AtkComponentScrollToPoint) {
  // There's a chance we may be compiled with a newer version of ATK and then
  // run with an older one, so we need to do a runtime check for this method
  // that is available in ATK 2.30 instead of linking directly.
  ScrollToPointFunc scroll_to_point = reinterpret_cast<ScrollToPointFunc>(
      dlsym(RTLD_DEFAULT, "atk_component_scroll_to_point"));
  if (!scroll_to_point) {
    LOG(WARNING) << "Skipping AtkComponentScrollToPoint"
                    " because ATK version < 2.30 detected.";
    return;
  }

  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 2000, 2000);

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;
  child1.relative_bounds.bounds = gfx::RectF(10, 10, 10, 10);
  root.child_ids.push_back(2);

  Init(root, child1);

  AXNode* child_node = GetRootAsAXNode()->children()[0];
  AtkObject* child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  ASSERT_TRUE(ATK_IS_COMPONENT(child_obj));
  g_object_ref(child_obj);

  int x_left, y_top, width, height;
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(10, x_left);
  EXPECT_EQ(10, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  scroll_to_point(ATK_COMPONENT(child_obj), ATK_XY_SCREEN, 600, 650);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(610, x_left);
  EXPECT_EQ(660, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  scroll_to_point(ATK_COMPONENT(child_obj), ATK_XY_PARENT, 10, 10);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  // The test wrapper scrolls every element when scrolling, so this should be
  // 10 pixels to bottom and left of the current coordinates of the root.
  EXPECT_EQ(620, x_left);
  EXPECT_EQ(670, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  g_object_unref(child_obj);

  // Un-set the global offset so that it doesn't affect subsequent tests.
  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(0, 0));
}

TEST_F(AXPlatformNodeAuraLinuxTest, AtkComponentScrollTo) {
  // There's a chance we may be compiled with a newer version of ATK and then
  // run with an older one, so we need to do a runtime check for this method
  // that is available in ATK 2.30 instead of linking directly.
  ScrollToFunc scroll_to = reinterpret_cast<ScrollToFunc>(
      dlsym(RTLD_DEFAULT, "atk_component_scroll_to"));
  if (!scroll_to) {
    LOG(WARNING) << "Skipping AtkComponentScrollTo"
                    " because ATK version < 2.30 detected.";
    return;
  }

  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 2000, 2000);

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;
  child1.relative_bounds.bounds = gfx::RectF(10, 10, 10, 10);
  root.child_ids.push_back(2);

  Init(root, child1);

  AXNode* child_node = GetRootAsAXNode()->children()[0];
  AtkObject* child_obj = AtkObjectFromNode(child_node);
  ASSERT_TRUE(ATK_IS_OBJECT(child_obj));
  ASSERT_TRUE(ATK_IS_COMPONENT(child_obj));
  g_object_ref(child_obj);

  int x_left, y_top, width, height;
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(10, x_left);
  EXPECT_EQ(10, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  scroll_to(ATK_COMPONENT(child_obj), ATK_SCROLL_ANYWHERE);
  atk_component_get_extents(ATK_COMPONENT(child_obj), &x_left, &y_top, &width,
                            &height, ATK_XY_SCREEN);
  EXPECT_EQ(0, x_left);
  EXPECT_EQ(0, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  // Un-set the global offset so that it doesn't affect subsequent tests.
  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(0, 0));
}
#endif  //  ATK_CHECK_VERSION(2, 30, 0)

//
// AtkValue tests
//

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkValueGetCurrentValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kSlider;
  root.AddFloatAttribute(ax::mojom::FloatAttribute::kValueForRange, 5.0);
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_VALUE(root_obj));
  g_object_ref(root_obj);

  GValue current_value = G_VALUE_INIT;
  atk_value_get_current_value(ATK_VALUE(root_obj), &current_value);

  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&current_value));
  EXPECT_EQ(5.0, g_value_get_float(&current_value));

  g_value_unset(&current_value);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkValueGetMaximumValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kSlider;
  root.AddFloatAttribute(ax::mojom::FloatAttribute::kMaxValueForRange, 5.0);
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_VALUE(root_obj));
  g_object_ref(root_obj);

  GValue max_value = G_VALUE_INIT;
  atk_value_get_maximum_value(ATK_VALUE(root_obj), &max_value);

  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&max_value));
  EXPECT_EQ(5.0, g_value_get_float(&max_value));

  g_value_unset(&max_value);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkValueGetMinimumValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kSlider;
  root.AddFloatAttribute(ax::mojom::FloatAttribute::kMinValueForRange, 5.0);
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_VALUE(root_obj));
  g_object_ref(root_obj);

  GValue min_value = G_VALUE_INIT;
  atk_value_get_minimum_value(ATK_VALUE(root_obj), &min_value);

  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&min_value));
  EXPECT_EQ(5.0, g_value_get_float(&min_value));

  g_value_unset(&min_value);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkValueGetMinimumIncrement) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kSlider;
  root.AddFloatAttribute(ax::mojom::FloatAttribute::kStepValueForRange, 5.0);
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_VALUE(root_obj));
  g_object_ref(root_obj);

  GValue increment = G_VALUE_INIT;
  atk_value_get_minimum_increment(ATK_VALUE(root_obj), &increment);

  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&increment));
  EXPECT_EQ(5.0, g_value_get_float(&increment));

  g_value_unset(&increment);
  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkValueChangedSignal) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kSlider;
  root.AddFloatAttribute(ax::mojom::FloatAttribute::kMaxValueForRange, 5.0);
  Init(root);

  AtkObject* root_object(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_object));
  ASSERT_TRUE(ATK_IS_VALUE(root_object));
  g_object_ref(root_object);

  bool saw_value_change = false;
  g_signal_connect(
      root_object, "property-change::accessible-value",
      G_CALLBACK(+[](AtkObject*, void* property, bool* saw_value_change) {
        *saw_value_change = true;
      }),
      &saw_value_change);

  GValue new_value = G_VALUE_INIT;
  g_value_init(&new_value, G_TYPE_FLOAT);

  g_value_set_float(&new_value, 24.0);
  ASSERT_TRUE(atk_value_set_current_value(ATK_VALUE(root_object), &new_value));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kValueChanged);

  GValue current_value = G_VALUE_INIT;
  atk_value_get_current_value(ATK_VALUE(root_object), &current_value);
  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&current_value));
  EXPECT_EQ(24.0, g_value_get_float(&current_value));
  EXPECT_TRUE(saw_value_change);

  saw_value_change = false;
  g_value_set_float(&new_value, 100.0);
  ASSERT_TRUE(atk_value_set_current_value(ATK_VALUE(root_object), &new_value));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kValueChanged);

  g_value_unset(&current_value);
  atk_value_get_current_value(ATK_VALUE(root_object), &current_value);
  EXPECT_EQ(G_TYPE_FLOAT, G_VALUE_TYPE(&current_value));
  EXPECT_EQ(100.0, g_value_get_float(&current_value));
  EXPECT_TRUE(saw_value_change);

  g_value_unset(&current_value);
  g_value_unset(&new_value);
  g_object_unref(root_object);
}

//
// AtkHyperlinkImpl interface
//

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkHyperlink) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kLink;
  root.AddStringAttribute(ax::mojom::StringAttribute::kUrl, "http://foo.com");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  ASSERT_TRUE(ATK_IS_HYPERLINK_IMPL(root_obj));
  g_object_ref(root_obj);

  AtkHyperlink* hyperlink(
      atk_hyperlink_impl_get_hyperlink(ATK_HYPERLINK_IMPL(root_obj)));
  ASSERT_TRUE(ATK_IS_HYPERLINK(hyperlink));

  EXPECT_EQ(1, atk_hyperlink_get_n_anchors(hyperlink));
  gchar* uri = atk_hyperlink_get_uri(hyperlink, 0);
  EXPECT_STREQ("http://foo.com", uri);
  g_free(uri);

  g_object_unref(hyperlink);
  g_object_unref(root_obj);
}

//
// AtkText interface
//
//

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextGetText) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue, "A string.");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  auto verify_text = [&](const char* expected, int start, int end) {
    char* actual = atk_text_get_text(atk_text, start, end);
    EXPECT_STREQ(expected, actual);
    g_free(actual);
  };

  verify_text("A string.", 0, -1);
  verify_text("A string.", 0, 20);
  verify_text("A string", 0, 8);
  verify_text("str", 2, 5);
  verify_text(".", 8, 9);
  verify_text("", 0, 0);
  verify_text(nullptr, -1, -1);
  verify_text(nullptr, 5, 2);
  verify_text(nullptr, 10, 20);

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextCharacterGranularity) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue,
                          "A decently long string \xE2\x98\xBA with an emoji.");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  EXPECT_EQ(static_cast<gunichar>('d'),
            atk_text_get_character_at_offset(atk_text, 2));
  EXPECT_EQ(0u, atk_text_get_character_at_offset(atk_text, -1));
  EXPECT_EQ(0u, atk_text_get_character_at_offset(atk_text, 42342));
  EXPECT_EQ(0x263Au, atk_text_get_character_at_offset(atk_text, 23));
  EXPECT_EQ(static_cast<gunichar>(' '),
            atk_text_get_character_at_offset(atk_text, 24));

  auto verify_text = [&](const char* expected_text, char* text,
                         int expected_start, int expected_end, int start,
                         int end) {
    EXPECT_STREQ(expected_text, text);
    EXPECT_EQ(start, expected_start);
    EXPECT_EQ(end, expected_end);
    g_free(text);
  };

  auto verify_text_at_offset = [&](const char* expected_text, int offset,
                                   int expected_start, int expected_end) {
    testing::Message message;
    message << "While checking at offset " << offset;
    SCOPED_TRACE(message);

    int start = 0, end = 0;
    char* text = atk_text_get_text_at_offset(
        atk_text, offset, ATK_TEXT_BOUNDARY_CHAR, &start, &end);
    verify_text(expected_text, text, expected_start, expected_end, start, end);
  };

  verify_text_at_offset("d", 2, 2, 3);
  verify_text_at_offset(nullptr, -1, 0, 0);
  verify_text_at_offset(nullptr, 42342, 0, 0);
  verify_text_at_offset("\xE2\x98\xBA", 23, 23, 24);
  verify_text_at_offset(" ", 24, 24, 25);

  auto verify_text_after_offset = [&](const char* expected_text, int offset,
                                      int expected_start, int expected_end) {
    testing::Message message;
    message << "While checking after offset " << offset;
    SCOPED_TRACE(message);

    int start = 0, end = 0;
    char* text = atk_text_get_text_after_offset(
        atk_text, offset, ATK_TEXT_BOUNDARY_CHAR, &start, &end);
    verify_text(expected_text, text, expected_start, expected_end, start, end);
  };

  verify_text_after_offset("d", 1, 2, 3);
  verify_text_after_offset(nullptr, 42342, -1, -1);
  verify_text_after_offset("\xE2\x98\xBA", 22, 23, 24);
  verify_text_after_offset(" ", 23, 24, 25);

  // This boundary condition is enforced by ATK for some reason.
  verify_text_after_offset(nullptr, -1, 0, 0);

  auto verify_text_before_offset = [&](const char* expected_text, int offset,
                                       int expected_start, int expected_end) {
    testing::Message message;
    message << "While checking before offset " << offset;
    SCOPED_TRACE(message);

    int start = 0, end = 0;
    char* text = atk_text_get_text_before_offset(
        atk_text, offset, ATK_TEXT_BOUNDARY_CHAR, &start, &end);
    verify_text(expected_text, text, expected_start, expected_end, start, end);
  };

  verify_text_before_offset("d", 3, 2, 3);
  verify_text_before_offset(nullptr, 42342, -1, -1);
  verify_text_before_offset("\xE2\x98\xBA", 24, 23, 24);
  verify_text_before_offset(" ", 25, 24, 25);
  verify_text_after_offset(nullptr, -1, 0, 0);

  g_object_unref(root_obj);
}

struct GetTextSegmentTest {
  int offset;
  const char* content;
  int start_offset;
  int end_offset;
};

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextWordGranularity) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue,
                          "A decently long string.");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  static GetTextSegmentTest tests[] = {{0, "A ", 0, 2},
                                       {2, "decently ", 2, 11},
                                       {-1, nullptr, -1, -1},
                                       {1000, nullptr, -1, -1}};

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    testing::Message message;
    message << "While checking at index " << tests[i].offset << " for \'"
            << tests[i].content << "\' at " << tests[i].start_offset << '-'
            << tests[i].end_offset << '.';
    SCOPED_TRACE(message);

    int start_offset = -1, end_offset = -1;
    char* content = atk_text_get_text_at_offset(atk_text, tests[i].offset,
                                                ATK_TEXT_BOUNDARY_WORD_START,
                                                &start_offset, &end_offset);
    EXPECT_STREQ(content, tests[i].content);
    EXPECT_EQ(start_offset, tests[i].start_offset);
    EXPECT_EQ(end_offset, tests[i].end_offset);
    g_free(content);
  }

#if ATK_CHECK_VERSION(2, 10, 0)
  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    testing::Message message;
    message << "While checking at index " << tests[i].offset << " for \'"
            << tests[i].content << "\' at " << tests[i].start_offset << '-'
            << tests[i].end_offset << '.';
    SCOPED_TRACE(message);

    int start_offset = -1, end_offset = -1;
    char* content = atk_text_get_string_at_offset(atk_text, tests[i].offset,
                                                  ATK_TEXT_GRANULARITY_WORD,
                                                  &start_offset, &end_offset);
    ASSERT_STREQ(content, tests[i].content) << "with test index=" << i;
    ASSERT_EQ(start_offset, tests[i].start_offset) << "with test index=" << i;
    ASSERT_EQ(end_offset, tests[i].end_offset) << "with test index=" << i;
    g_free(content);
  }
#endif

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextSentenceGranularity) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue,
                          "A short sentence. Another sentence.     A third...");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  static GetTextSegmentTest tests[] = {
      {0, "A short sentence. ", 0, 18},
      {20, "Another sentence.     ", 18, 40},
      {37, "Another sentence.     ", 18, 40},
      {49, "A third...", 40, 50},
      {-1, nullptr, -1, -1},
      {-1000, nullptr, -1, -1},
      {1000, nullptr, -1, -1},
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    testing::Message message;
    message << "While checking at index " << tests[i].offset << " for \'"
            << tests[i].content << "\' at " << tests[i].start_offset << '-'
            << tests[i].end_offset << '.';
    SCOPED_TRACE(message);

    int start_offset = -1, end_offset = -1;
    char* content = atk_text_get_text_at_offset(
        atk_text, tests[i].offset, ATK_TEXT_BOUNDARY_SENTENCE_START,
        &start_offset, &end_offset);
    ASSERT_STREQ(content, tests[i].content);
    ASSERT_EQ(start_offset, tests[i].start_offset);
    ASSERT_EQ(end_offset, tests[i].end_offset);
    g_free(content);
  }

#if ATK_CHECK_VERSION(2, 10, 0)
  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    testing::Message message;
    message << "While checking at index " << tests[i].offset << " for \'"
            << tests[i].content << "\' at " << tests[i].start_offset << '-'
            << tests[i].end_offset << '.';
    SCOPED_TRACE(message);

    int start_offset = -1, end_offset = -1;
    char* content = atk_text_get_string_at_offset(atk_text, tests[i].offset,
                                                  ATK_TEXT_GRANULARITY_SENTENCE,
                                                  &start_offset, &end_offset);
    ASSERT_STREQ(content, tests[i].content);
    ASSERT_EQ(start_offset, tests[i].start_offset);
    ASSERT_EQ(end_offset, tests[i].end_offset);
    g_free(content);
  }
#endif

  g_object_unref(root_obj);
}

#if ATK_CHECK_VERSION(2, 10, 0)
TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextParagraphGranularity) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(
      ax::mojom::StringAttribute::kValue,
      "A short paragraph. \nAnother paragraph.\nA third...");
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  static GetTextSegmentTest tests[] = {
      {0, "A short paragraph. ", 0, 19},
      {25, "Another paragraph.", 20, 38},
      {-1, nullptr, -1, -1},
      {12345, nullptr, -1, -1},
  };

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    int start_offset = -1, end_offset = -1;
    char* content = atk_text_get_string_at_offset(
        atk_text, tests[i].offset, ATK_TEXT_GRANULARITY_PARAGRAPH,
        &start_offset, &end_offset);
    ASSERT_STREQ(content, tests[i].content) << "with test index=" << i;
    ASSERT_EQ(start_offset, tests[i].start_offset) << "with test index=" << i;
    ASSERT_EQ(end_offset, tests[i].end_offset) << "with test index=" << i;
    g_free(content);
  }
#endif

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextWithNonBMPCharacters) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;

  // The playing card emoji in this string should be considered a single
  // character offset for all AtkText API calls.
  static const char root_text[] =
      "\xF0\x9F\x83\x8f a decently long \xF0\x9F\x83\x8f string "
      "\xF0\x9F\x83\x8f.";
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue, root_text);
  Init(root);

  AtkObject* root_obj(GetRootAtkObject());
  ASSERT_TRUE(ATK_IS_OBJECT(root_obj));
  g_object_ref(root_obj);

  ASSERT_TRUE(ATK_IS_TEXT(root_obj));
  AtkText* atk_text = ATK_TEXT(root_obj);

  int root_text_length = g_utf8_strlen(root_text, -1);
  ASSERT_EQ(atk_text_get_character_count(atk_text), root_text_length);

  for (int i = 0; i < root_text_length; i++) {
    testing::Message message;
    message << "Checking character at offset " << i;
    SCOPED_TRACE(message);

    gunichar character = atk_text_get_character_at_offset(atk_text, i);
    gunichar expected_character =
        g_utf8_get_char_validated(g_utf8_offset_to_pointer(root_text, i), -1);
    ASSERT_EQ(character, expected_character);

    int start_offset = -1, end_offset = -1;
    char* char_string = atk_text_get_text_at_offset(
        atk_text, i, ATK_TEXT_BOUNDARY_CHAR, &start_offset, &end_offset);
    character = g_utf8_get_char_validated(char_string, -1);
    ASSERT_EQ(character, expected_character);
    ASSERT_EQ(start_offset, i);
    ASSERT_EQ(end_offset, i + 1);
    g_free(char_string);

#if ATK_CHECK_VERSION(2, 10, 0)
    start_offset = -1;
    end_offset = -1;
    char_string = atk_text_get_string_at_offset(
        atk_text, i, ATK_TEXT_GRANULARITY_CHAR, &start_offset, &end_offset);

    character = g_utf8_get_char_validated(char_string, -1);
    ASSERT_EQ(character, expected_character);
    ASSERT_EQ(start_offset, i);
    ASSERT_EQ(end_offset, i + 1);
    g_free(char_string);
#endif
  }

  static GetTextSegmentTest tests[] = {{0, "\xF0\x9F\x83\x8f ", 0, 2},
                                       {6, "decently ", 4, 13}};

  for (unsigned i = 0; i < G_N_ELEMENTS(tests); i++) {
    int start_offset = -1, end_offset = -1;
    char* word = atk_text_get_text_at_offset(atk_text, tests[i].offset,
                                             ATK_TEXT_BOUNDARY_WORD_START,
                                             &start_offset, &end_offset);
    testing::Message message;
    message << "Checking test with index=" << i << " and expected text=\'"
            << tests[i].content << "\' at " << tests[1].start_offset << '-'
            << tests[1].end_offset << '.';
    SCOPED_TRACE(message);

    ASSERT_STREQ(word, tests[i].content);
    ASSERT_EQ(start_offset, tests[i].start_offset);
    ASSERT_EQ(end_offset, tests[i].end_offset);

    g_free(word);
  }

  g_object_unref(root_obj);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextCaretMoved) {
  Init(BuildTextField());

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  ASSERT_TRUE(ATK_IS_TEXT(root_atk_object));
  AtkText* atk_text = ATK_TEXT(root_atk_object);

  int caret_position_from_event = -1;
  g_signal_connect(atk_text, "text-caret-moved",
                   G_CALLBACK(+[](AtkText*, int new_position, gpointer data) {
                     int* caret_position_from_event = static_cast<int*>(data);
                     *caret_position_from_event = new_position;
                   }),
                   &caret_position_from_event);

  atk_text_set_caret_offset(atk_text, 4);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), 4);
  ASSERT_EQ(caret_position_from_event, 4);

  // Setting the same position should not trigger another event.
  caret_position_from_event = -1;
  atk_text_set_caret_offset(atk_text, 4);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), 4);
  ASSERT_EQ(caret_position_from_event, -1);

  int character_count = atk_text_get_character_count(atk_text);
  atk_text_set_caret_offset(atk_text, -1);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), character_count);
  ASSERT_EQ(caret_position_from_event, character_count);

  atk_text_set_caret_offset(atk_text, 0);  // Reset position.
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);

  caret_position_from_event = -1;
  atk_text_set_caret_offset(atk_text, -1000);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), character_count);
  ASSERT_EQ(caret_position_from_event, character_count);

  atk_text_set_caret_offset(atk_text, 0);  // Reset position.
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);

  caret_position_from_event = -1;
  atk_text_set_caret_offset(atk_text, 1000);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), character_count);
  ASSERT_EQ(caret_position_from_event, character_count);

  caret_position_from_event = -1;
  atk_text_set_caret_offset(atk_text, character_count - 1);
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  ASSERT_EQ(atk_text_get_caret_offset(atk_text), character_count - 1);
  ASSERT_EQ(caret_position_from_event, character_count - 1);

  g_object_unref(root_atk_object);
}

class ActivationTester {
 public:
  explicit ActivationTester(AtkObject* target) : target_(target) {
    auto callback = G_CALLBACK(+[](AtkWindow*, bool* flag) { *flag = true; });
    activate_id_ =
        g_signal_connect(target, "activate", callback, &saw_activate_);
    deactivate_id_ =
        g_signal_connect(target, "deactivate", callback, &saw_deactivate_);

    DCHECK(activate_id_);
    DCHECK(deactivate_id_);
    DCHECK(activate_id_ != deactivate_id_);
  }

  bool IsActivatedInStateSet() {
    return AtkObjectHasState(target_, ATK_STATE_ACTIVE);
  }

  void Reset() {
    saw_activate_ = false;
    saw_deactivate_ = false;
  }

  virtual ~ActivationTester() {
    g_signal_handler_disconnect(target_, activate_id_);
    g_signal_handler_disconnect(target_, deactivate_id_);
  }

  AtkObject* target_;
  bool saw_activate_ = false;
  bool saw_deactivate_ = false;
  gulong activate_id_ = 0;
  gulong deactivate_id_ = 0;
};

//
// AtkWindow interface and active state
//
//
TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkWindowActive) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  root.child_ids.push_back(2);

  AXNodeData child;
  child.id = 2;
  child.role = ax::mojom::Role::kCheckBox;

  Init(root, child);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  EXPECT_TRUE(ATK_IS_WINDOW(root_atk_object));

  AXNode* checkbox_node = GetRootAsAXNode()->children()[0];
  AtkObject* checkbox_atk_obj = AtkObjectFromNode(checkbox_node);

  // Focus the checkbox to ensure that it also gets new focus events when
  // the toplevel window goes from unfocused to focused.
  GetPlatformNode(checkbox_node)
      ->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);

  bool saw_active_focus_state_change = false;
  g_signal_connect(checkbox_atk_obj, "state-change",
                   G_CALLBACK(+[](AtkObject* atkobject, gchar* state_changed,
                                  gboolean new_value, bool* flag) {
                     if (!g_strcmp0(state_changed, "focused") && new_value)
                       *flag = true;
                   }),
                   &saw_active_focus_state_change);

  // ATK window activated event will be held until AT-SPI bridge is ready. We
  // work that around by faking its state.
  ui::AtkUtilAuraLinux::GetInstance()->SetAtSpiReady(true);

  {
    ActivationTester tester(root_atk_object);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowActivated);
    EXPECT_TRUE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_TRUE(tester.IsActivatedInStateSet());
    EXPECT_TRUE(saw_active_focus_state_change);
  }

  {
    saw_active_focus_state_change = false;

    ActivationTester tester(root_atk_object);
    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowDeactivated);
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_TRUE(tester.saw_deactivate_);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
    EXPECT_FALSE(saw_active_focus_state_change);
  }

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestPostponedAtkWindowActive) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  Init(root);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);
  EXPECT_TRUE(ATK_IS_WINDOW(root_atk_object));

  AtkUtilAuraLinux* atk_util = ui::AtkUtilAuraLinux::GetInstance();

  {
    ActivationTester tester(root_atk_object);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowActivated);

    // ATK window activated event will be held until AT-SPI bridge is ready.
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);

    // We force the AT-SPI ready flag to flush any held events.
    atk_util->SetAtSpiReady(true);
    EXPECT_TRUE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_TRUE(tester.IsActivatedInStateSet());
  }

  {
    ActivationTester tester(root_atk_object);

    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowDeactivated);

    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_TRUE(tester.saw_deactivate_);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
  }

  {
    atk_util->SetAtSpiReady(false);

    ActivationTester tester(root_atk_object);

    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowActivated);

    // Window deactivated will cancel the previously held activated event.
    static_cast<AXPlatformNodeAuraLinux*>(GetRootPlatformNode())
        ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowDeactivated);

    // We force the AT-SPI ready flag to flush any held events.
    atk_util->SetAtSpiReady(true);

    // No events seen because they cancelled each other.
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
  }

  g_object_unref(root_atk_object);
}

//
// AtkWindow interface and iconified state
//
TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkWindowMinimized) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  Init(root);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  EXPECT_TRUE(ATK_IS_WINDOW(root_atk_object));
  EXPECT_FALSE(AtkObjectHasState(root_atk_object, ATK_STATE_ICONIFIED));

  GetRootWrapper()->set_minimized(true);
  EXPECT_TRUE(AtkObjectHasState(root_atk_object, ATK_STATE_ICONIFIED));

  bool saw_state_change = false;
  g_signal_connect(root_atk_object, "state-change",
                   G_CALLBACK(+[](AtkObject* atkobject, gchar* state_changed,
                                  gboolean new_value, bool* flag) {
                     if (!g_strcmp0(state_changed, "iconified"))
                       *flag = true;
                   }),
                   &saw_state_change);

  AXPlatformNodeAuraLinux* root_node = GetRootPlatformNode();
  static_cast<AXPlatformNodeAuraLinux*>(root_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kWindowVisibilityChanged);

  EXPECT_TRUE(saw_state_change);

  saw_state_change = false;
  static_cast<AXPlatformNodeAuraLinux*>(root_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kWindowVisibilityChanged);
  EXPECT_FALSE(saw_state_change);

  GetRootWrapper()->set_minimized(false);
  static_cast<AXPlatformNodeAuraLinux*>(root_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kWindowVisibilityChanged);
  EXPECT_TRUE(saw_state_change);

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestFocusTriggersAtkWindowActive) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  root.child_ids.push_back(2);

  AXNodeData child_node_data;
  child_node_data.id = 2;
  child_node_data.role = ax::mojom::Role::kButton;

  Init(root, child_node_data);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  EXPECT_TRUE(ATK_IS_WINDOW(root_atk_object));

  g_object_ref(root_atk_object);

  AXNode* child_node = GetRootAsAXNode()->children()[0];

  // A focus event on a child node should not cause the window to
  // activate.
  {
    ActivationTester tester(root_atk_object);
    GetPlatformNode(child_node)
        ->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
  }

  // A focus event on the window itself should cause the window to activate.
  {
    ActivationTester tester(root_atk_object);
    GetRootPlatformNode()->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);
    EXPECT_TRUE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_TRUE(tester.IsActivatedInStateSet());
  }

  // Since the window is already active, we shouldn't see another activation
  // event, but it should still be active.
  {
    ActivationTester tester(root_atk_object);
    GetRootPlatformNode()->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_TRUE(tester.IsActivatedInStateSet());
  }

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkPopupWindowActive) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kApplication;
  root.child_ids.push_back(2);
  root.child_ids.push_back(4);

  AXNodeData window_node_data;
  window_node_data.id = 2;
  window_node_data.role = ax::mojom::Role::kWindow;
  window_node_data.child_ids.push_back(3);

  AXNodeData document_node_data;
  document_node_data.id = 3;
  document_node_data.role = ax::mojom::Role::kRootWebArea;

  AXNodeData menu_node_data;
  menu_node_data.id = 4;
  menu_node_data.role = ax::mojom::Role::kWindow;
  menu_node_data.child_ids.push_back(5);

  AXNodeData menu_item_data;
  menu_item_data.id = 5;

  Init(root, window_node_data, document_node_data, menu_node_data,
       menu_item_data);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  AXNode* window_node = GetRootAsAXNode()->children()[0];
  AtkObject* window_atk_node(AtkObjectFromNode(window_node));

  AXNode* document_node = window_node->children()[0];
  AtkObject* document_atk_node(AtkObjectFromNode(document_node));
  EXPECT_EQ(ATK_ROLE_DOCUMENT_WEB, atk_object_get_role(document_atk_node));
  int focus_events_on_original_node = 0;
  g_signal_connect(
      document_atk_node, "focus-event",
      G_CALLBACK(+[](AtkObject* atkobject, gint focused, int* focus_events) {
        if (focused)
          *focus_events += 1;
      }),
      &focus_events_on_original_node);
  atk_component_grab_focus(ATK_COMPONENT(document_atk_node));

  ActivationTester toplevel_tester(window_atk_node);
  GetPlatformNode(window_node)
      ->NotifyAccessibilityEvent(ax::mojom::Event::kWindowActivated);
  EXPECT_TRUE(toplevel_tester.saw_activate_);
  EXPECT_FALSE(toplevel_tester.saw_deactivate_);
  EXPECT_TRUE(toplevel_tester.IsActivatedInStateSet());

  toplevel_tester.Reset();

  AXNode* menu_node = GetRootAsAXNode()->children()[1];
  AtkObject* menu_atk_node(AtkObjectFromNode(menu_node));
  {
    ActivationTester tester(menu_atk_node);
    GetPlatformNode(menu_node)->NotifyAccessibilityEvent(
        ax::mojom::Event::kMenuPopupStart);
    EXPECT_TRUE(tester.saw_activate_);
    EXPECT_FALSE(tester.saw_deactivate_);
    EXPECT_TRUE(tester.IsActivatedInStateSet());
    EXPECT_EQ(focus_events_on_original_node, 0);
  }

  EXPECT_FALSE(toplevel_tester.saw_activate_);
  EXPECT_TRUE(toplevel_tester.saw_deactivate_);

  toplevel_tester.Reset();

  {
    ActivationTester tester(menu_atk_node);
    GetPlatformNode(menu_node)->NotifyAccessibilityEvent(
        ax::mojom::Event::kMenuPopupEnd);
    EXPECT_FALSE(tester.saw_activate_);
    EXPECT_TRUE(tester.saw_deactivate_);
    EXPECT_FALSE(tester.IsActivatedInStateSet());
    EXPECT_EQ(focus_events_on_original_node, 1);
  }

  // Now that the menu is definitively closed, activation should have returned
  // to the previously activated toplevel frame.
  EXPECT_TRUE(toplevel_tester.saw_activate_);
  EXPECT_FALSE(toplevel_tester.saw_deactivate_);

  // Now we test opening the menu and closing it without hiding any submenus.
  // The toplevel should lose and then regain focus.
  focus_events_on_original_node = 0;
  toplevel_tester.Reset();

  GetPlatformNode(menu_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kMenuPopupStart);
  GetPlatformNode(menu_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kMenuPopupEnd);
  EXPECT_TRUE(toplevel_tester.saw_activate_);
  EXPECT_TRUE(toplevel_tester.saw_deactivate_);

  // The menu has closed so the original node should have received focus again.
  EXPECT_EQ(focus_events_on_original_node, 1);

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkSelectionInterface) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kListBox;
  root.AddState(ax::mojom::State::kFocusable);
  root.AddState(ax::mojom::State::kMultiselectable);
  root.child_ids.push_back(2);
  root.child_ids.push_back(3);
  root.child_ids.push_back(4);
  root.child_ids.push_back(5);

  AXNodeData item_1;
  item_1.id = 2;
  item_1.role = ax::mojom::Role::kListBoxOption;

  AXNodeData item_2;
  item_2.id = 3;
  item_2.role = ax::mojom::Role::kListBoxOption;

  AXNodeData item_3;
  item_3.id = 4;
  item_3.role = ax::mojom::Role::kListBoxOption;

  // Add a final item which is not selectable.
  AXNodeData item_4;
  item_4.id = 5;
  item_4.role = ax::mojom::Role::kListItem;

  AXTreeUpdate update;
  update.root_id = 1;
  update.nodes.push_back(root);
  update.nodes.push_back(item_1);
  update.nodes.push_back(item_2);
  update.nodes.push_back(item_3);
  update.nodes.push_back(item_4);
  Init(update);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  ASSERT_TRUE(ATK_IS_SELECTION(root_atk_object));

  ASSERT_TRUE(ATK_IS_SELECTION(root_atk_object));
  AtkSelection* selection = ATK_SELECTION(root_atk_object);
  ASSERT_EQ(atk_selection_get_selection_count(selection), 0);
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 0));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 1));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 2));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3));

  ASSERT_FALSE(atk_selection_is_child_selected(selection, -1));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, -100));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 4));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3000));

  ASSERT_TRUE(atk_selection_select_all_selection(selection));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 3);
  ASSERT_TRUE(atk_selection_is_child_selected(selection, 0));
  ASSERT_TRUE(atk_selection_is_child_selected(selection, 1));
  ASSERT_TRUE(atk_selection_is_child_selected(selection, 2));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3));

  ASSERT_FALSE(atk_selection_is_child_selected(selection, -1));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, -100));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 4));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3000));

  ASSERT_TRUE(atk_selection_clear_selection(selection));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 0);
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 0));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 1));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 2));
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3));

  ASSERT_TRUE(atk_selection_add_selection(selection, 1));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 1);
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 0));
  ASSERT_TRUE(atk_selection_is_child_selected(selection, 1));

  // The index to this function is the index into the selected elements, not
  // into the children.
  ASSERT_TRUE(atk_selection_remove_selection(selection, 0));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 0);
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 1));

  // We should not be able to select an item with a role that is not
  // selectable.
  ASSERT_FALSE(atk_selection_add_selection(selection, 3));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 0);
  ASSERT_FALSE(atk_selection_is_child_selected(selection, 3));

  // Test some out of bounds use of atk_selection_add_selection.
  ASSERT_FALSE(atk_selection_add_selection(selection, -1));
  ASSERT_FALSE(atk_selection_add_selection(selection, -100));
  ASSERT_FALSE(atk_selection_add_selection(selection, 4));
  ASSERT_FALSE(atk_selection_add_selection(selection, 100));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 0);

  ASSERT_TRUE(atk_selection_select_all_selection(selection));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 3);
  ASSERT_FALSE(atk_selection_remove_selection(selection, -1));
  ASSERT_FALSE(atk_selection_remove_selection(selection, -100));
  ASSERT_FALSE(atk_selection_remove_selection(selection, 4));
  ASSERT_FALSE(atk_selection_remove_selection(selection, 100));
  ASSERT_EQ(atk_selection_get_selection_count(selection), 3);

  g_object_unref(root_atk_object);
}

// Tests GetPosInSet() and GetSetSize() functions of AXPlatformNodeBase.
// PosInSet and SetSize must be tested separately from other IntAttributes
// because they can be either assigned values or calculated dynamically.
TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectSetSizePosInSet) {
  AXTreeUpdate update;
  update.root_id = 1;
  update.nodes.resize(4);
  update.nodes[0].id = 1;
  update.nodes[0].role = ax::mojom::Role::kRadioGroup;
  update.nodes[0].child_ids = {2, 3, 4};
  update.nodes[1].id = 2;
  update.nodes[1].role =
      ax::mojom::Role::kRadioButton;  // kRadioButton posinset = 2, setsize = 5.
  update.nodes[1].AddIntAttribute(ax::mojom::IntAttribute::kPosInSet, 2);
  update.nodes[2].id = 3;
  update.nodes[2].role =
      ax::mojom::Role::kRadioButton;  // kRadioButton posinset = 3, setsize = 5.
  update.nodes[3].id = 4;
  update.nodes[3].role =
      ax::mojom::Role::kRadioButton;  // kRadioButton posinset = 5, stesize = 5
  update.nodes[3].AddIntAttribute(ax::mojom::IntAttribute::kPosInSet, 5);
  Init(update);

  AXNode* radiobutton1 = GetRootAsAXNode()->children()[0];
  AtkObject* radiobutton1_atk_object(AtkObjectFromNode(radiobutton1));
  EXPECT_TRUE(ATK_IS_OBJECT(radiobutton1_atk_object));

  AXNode* radiobutton2 = GetRootAsAXNode()->children()[1];
  AtkObject* radiobutton2_atk_object(AtkObjectFromNode(radiobutton2));
  EXPECT_TRUE(ATK_IS_OBJECT(radiobutton2_atk_object));

  AXNode* radiobutton3 = GetRootAsAXNode()->children()[2];
  AtkObject* radiobutton3_atk_object(AtkObjectFromNode(radiobutton3));
  EXPECT_TRUE(ATK_IS_OBJECT(radiobutton3_atk_object));

  // Notice that setsize was never assigned to any of the kRadioButtons, but was
  // inferred.
  EnsureAtkObjectHasAttributeWithValue(radiobutton1_atk_object, "posinset",
                                       "2");
  EnsureAtkObjectHasAttributeWithValue(radiobutton1_atk_object, "setsize", "5");
  EnsureAtkObjectHasAttributeWithValue(radiobutton2_atk_object, "posinset",
                                       "3");
  EnsureAtkObjectHasAttributeWithValue(radiobutton2_atk_object, "setsize", "5");
  EnsureAtkObjectHasAttributeWithValue(radiobutton3_atk_object, "posinset",
                                       "5");
  EnsureAtkObjectHasAttributeWithValue(radiobutton3_atk_object, "setsize", "5");
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkRelations) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kDetailsIds, {2});

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;

  root.child_ids.push_back(2);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kStaticText;
  std::vector<int32_t> labelledby_ids = {1, 4};
  child2.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                             labelledby_ids);

  root.child_ids.push_back(3);

  AXNodeData child3;
  child3.id = 4;
  child3.role = ax::mojom::Role::kStaticText;
  child3.AddIntListAttribute(ax::mojom::IntListAttribute::kDetailsIds, {2});
  child3.AddIntAttribute(ax::mojom::IntAttribute::kMemberOfId, 1);

  root.child_ids.push_back(4);

  Init(root, child1, child2, child3);

  // We don't test relations that are too new for the runtime version of ATK.
  GEnumClass* enum_class =
      G_ENUM_CLASS(g_type_class_ref(atk_relation_type_get_type()));
  int max_relation_type = enum_class->maximum;
  g_type_class_unref(enum_class);

  auto assert_contains_relation = [&](AtkObject* object, AtkObject* target,
                                      AtkRelationType relation) {
    if (relation > max_relation_type)
      return;

    AtkRelationSet* relations = atk_object_ref_relation_set(object);
    ASSERT_TRUE(atk_relation_set_contains(relations, relation));
    ASSERT_TRUE(atk_relation_set_contains_target(relations, relation, target));
    g_object_unref(G_OBJECT(relations));
  };

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  AtkObject* atk_child1(AtkObjectFromNode(GetRootAsAXNode()->children()[0]));
  AtkObject* atk_child2(AtkObjectFromNode(GetRootAsAXNode()->children()[1]));
  AtkObject* atk_child3(AtkObjectFromNode(GetRootAsAXNode()->children()[2]));

  assert_contains_relation(root_atk_object, atk_child1, ATK_RELATION_DETAILS);
  assert_contains_relation(atk_child1, root_atk_object,
                           ATK_RELATION_DETAILS_FOR);
  assert_contains_relation(atk_child3, atk_child1, ATK_RELATION_DETAILS);
  assert_contains_relation(atk_child1, atk_child3, ATK_RELATION_DETAILS_FOR);

  assert_contains_relation(atk_child2, root_atk_object,
                           ATK_RELATION_LABELLED_BY);
  assert_contains_relation(root_atk_object, atk_child2, ATK_RELATION_LABEL_FOR);
  assert_contains_relation(atk_child2, atk_child3, ATK_RELATION_LABELLED_BY);
  assert_contains_relation(atk_child3, atk_child2, ATK_RELATION_LABEL_FOR);

  assert_contains_relation(atk_child3, root_atk_object, ATK_RELATION_MEMBER_OF);

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAllReverseAtkRelations) {
  // We don't test relations that are too new for the runtime version of ATK.
  GEnumClass* enum_class =
      G_ENUM_CLASS(g_type_class_ref(atk_relation_type_get_type()));
  int max_relation_type = enum_class->maximum;
  g_type_class_unref(enum_class);

  auto test_relation = [&](auto attribute_setter,
                           AtkRelationType expected_relation,
                           AtkRelationType expected_reverse_relation) {
    if (expected_relation > max_relation_type ||
        expected_reverse_relation > max_relation_type)
      return;

    AXNodeData root_data;
    root_data.id = 1;
    root_data.role = ax::mojom::Role::kRootWebArea;
    attribute_setter(&root_data, 2);

    AXNodeData child_data;
    child_data.id = 2;
    child_data.role = ax::mojom::Role::kStaticText;
    root_data.child_ids.push_back(2);
    Init(root_data, child_data);

    AtkObject* source(GetRootAtkObject());
    AtkObject* target(AtkObjectFromNode(GetRootAsAXNode()->children()[0]));

    AtkRelationSet* relations = atk_object_ref_relation_set(source);
    ASSERT_TRUE(atk_relation_set_contains(relations, expected_relation));
    ASSERT_TRUE(
        atk_relation_set_contains_target(relations, expected_relation, target));
    g_object_unref(G_OBJECT(relations));

    relations = atk_object_ref_relation_set(target);
    ASSERT_TRUE(
        atk_relation_set_contains(relations, expected_reverse_relation));
    ASSERT_TRUE(atk_relation_set_contains_target(
        relations, expected_reverse_relation, source));
    g_object_unref(G_OBJECT(relations));
  };

  auto test_int_relation = [&](ax::mojom::IntAttribute relation,
                               AtkRelationType expected_relation,
                               AtkRelationType expected_reverse_relation) {
    auto setter = [&](AXNodeData* data, int target_id) {
      data->AddIntAttribute(relation, target_id);
    };
    test_relation(setter, expected_relation, expected_reverse_relation);
  };

  auto test_int_list_relation = [&](ax::mojom::IntListAttribute relation,
                                    AtkRelationType expected_relation,
                                    AtkRelationType expected_reverse_relation) {
    auto setter = [&](AXNodeData* data, int target_id) {
      std::vector<int32_t> ids = {target_id};
      data->AddIntListAttribute(relation, ids);
    };
    test_relation(setter, expected_relation, expected_reverse_relation);
  };

  test_int_list_relation(ax::mojom::IntListAttribute::kDetailsIds,
                         ATK_RELATION_DETAILS, ATK_RELATION_DETAILS_FOR);
  test_int_relation(ax::mojom::IntAttribute::kErrormessageId,
                    ATK_RELATION_ERROR_MESSAGE, ATK_RELATION_ERROR_FOR);
  test_int_list_relation(ax::mojom::IntListAttribute::kControlsIds,
                         ATK_RELATION_CONTROLLER_FOR,
                         ATK_RELATION_CONTROLLED_BY);
  test_int_list_relation(ax::mojom::IntListAttribute::kDescribedbyIds,
                         ATK_RELATION_DESCRIBED_BY,
                         ATK_RELATION_DESCRIPTION_FOR);
  test_int_list_relation(ax::mojom::IntListAttribute::kFlowtoIds,
                         ATK_RELATION_FLOWS_TO, ATK_RELATION_FLOWS_FROM);
  test_int_list_relation(ax::mojom::IntListAttribute::kLabelledbyIds,
                         ATK_RELATION_LABELLED_BY, ATK_RELATION_LABEL_FOR);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkRelationsTargetIndex) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData label1;
  label1.id = 2;
  label1.role = ax::mojom::Role::kStaticText;
  root.child_ids.push_back(2);

  AXNodeData label2;
  label2.id = 3;
  label2.role = ax::mojom::Role::kList;
  root.child_ids.push_back(3);

  AXNodeData label3;
  label3.id = 4;
  label3.role = ax::mojom::Role::kTable;
  root.child_ids.push_back(4);

  AXNodeData button1;
  button1.id = 5;
  button1.role = ax::mojom::Role::kButton;
  button1.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                              {2, 3, 4});
  root.child_ids.push_back(5);

  AXNodeData button2;
  button2.id = 6;
  button2.role = ax::mojom::Role::kButton;
  button2.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                              {4, 3, 2});
  root.child_ids.push_back(6);

  AXNodeData button3;
  button3.id = 7;
  button3.role = ax::mojom::Role::kButton;
  button3.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                              {4, 4, 2, 2, 3});
  root.child_ids.push_back(7);

  Init(root, label1, label2, label3, button1, button2, button3);

  auto test_index = [&](AtkObject* source, AtkObject* target,
                        AtkRelationType relation_type, int index) {
    AtkRelationSet* relation_set = atk_object_ref_relation_set(source);
    ASSERT_TRUE(atk_relation_set_contains(relation_set, relation_type));

    AtkRelation* relation =
        atk_relation_set_get_relation_by_type(relation_set, relation_type);
    GPtrArray* targets = atk_relation_get_target(relation);
    ASSERT_TRUE(ATK_IS_OBJECT(g_ptr_array_index(targets, index)));
    ASSERT_TRUE(ATK_OBJECT(g_ptr_array_index(targets, index)) == target);

    g_object_unref(G_OBJECT(relation_set));
  };

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));
  g_object_ref(root_atk_object);

  AtkObject* atk_label1(AtkObjectFromNode(GetRootAsAXNode()->children()[0]));
  AtkObject* atk_label2(AtkObjectFromNode(GetRootAsAXNode()->children()[1]));
  AtkObject* atk_label3(AtkObjectFromNode(GetRootAsAXNode()->children()[2]));
  AtkObject* atk_button1(AtkObjectFromNode(GetRootAsAXNode()->children()[3]));
  AtkObject* atk_button2(AtkObjectFromNode(GetRootAsAXNode()->children()[4]));
  AtkObject* atk_button3(AtkObjectFromNode(GetRootAsAXNode()->children()[5]));

  test_index(atk_button1, atk_label1, ATK_RELATION_LABELLED_BY, 0);
  test_index(atk_button1, atk_label2, ATK_RELATION_LABELLED_BY, 1);
  test_index(atk_button1, atk_label3, ATK_RELATION_LABELLED_BY, 2);

  test_index(atk_button2, atk_label3, ATK_RELATION_LABELLED_BY, 0);
  test_index(atk_button2, atk_label2, ATK_RELATION_LABELLED_BY, 1);
  test_index(atk_button2, atk_label1, ATK_RELATION_LABELLED_BY, 2);

  test_index(atk_button3, atk_label3, ATK_RELATION_LABELLED_BY, 0);
  test_index(atk_button3, atk_label1, ATK_RELATION_LABELLED_BY, 1);
  test_index(atk_button3, atk_label2, ATK_RELATION_LABELLED_BY, 2);

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextTextFieldGetNSelectionsZero) {
  Init(BuildTextField());
  AtkObject* root_atk_object(GetRootAtkObject());
  g_object_ref(root_atk_object);

  AtkText* atk_text = ATK_TEXT(root_atk_object);
  ASSERT_NE(nullptr, atk_text);
  EXPECT_EQ(0, atk_text_get_n_selections(atk_text));

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest,
       TestAtkTextContentEditableGetNSelectionsZero) {
  Init(BuildContentEditable());
  AtkObject* root_atk_object(GetRootAtkObject());
  g_object_ref(root_atk_object);

  AtkText* atk_text = ATK_TEXT(root_atk_object);
  ASSERT_NE(nullptr, atk_text);
  EXPECT_EQ(0, atk_text_get_n_selections(atk_text));

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextContentEditableGetNSelections) {
  Init(BuildContentEditableWithSelectionRange(1, 2));
  AtkObject* root_atk_object(GetRootAtkObject());
  g_object_ref(root_atk_object);

  AtkText* atk_text = ATK_TEXT(root_atk_object);
  ASSERT_NE(nullptr, atk_text);
  EXPECT_EQ(1, atk_text_get_n_selections(atk_text));

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextTextFieldSetSelection) {
  Init(BuildTextField());
  AtkObject* root_atk_object(GetRootAtkObject());
  g_object_ref(root_atk_object);

  AtkText* atk_text = ATK_TEXT(root_atk_object);
  ASSERT_NE(nullptr, atk_text);

  bool saw_selection_change = false;
  g_signal_connect(
      atk_text, "text-selection-changed",
      G_CALLBACK(+[](AtkObject* atkobject, bool* flag) { *flag = true; }),
      &saw_selection_change);

  int selection_start, selection_end;

  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 1));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_TRUE(saw_selection_change);
  g_free(atk_text_get_selection(atk_text, 0, &selection_start, &selection_end));
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 1);

  // Reset position.
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 0));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);

  saw_selection_change = false;
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 1, 0));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_TRUE(saw_selection_change);
  g_free(atk_text_get_selection(atk_text, 0, &selection_start, &selection_end));
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 1);

  saw_selection_change = false;
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 2, 4));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_TRUE(saw_selection_change);
  g_free(atk_text_get_selection(atk_text, 0, &selection_start, &selection_end));
  EXPECT_EQ(selection_start, 2);
  EXPECT_EQ(selection_end, 4);

  saw_selection_change = false;
  EXPECT_FALSE(atk_text_set_selection(atk_text, 1, 0, 0));
  EXPECT_FALSE(saw_selection_change);
  g_free(atk_text_get_selection(atk_text, 0, &selection_start, &selection_end));
  EXPECT_EQ(selection_start, 2);
  EXPECT_EQ(selection_end, 4);

  saw_selection_change = false;
  EXPECT_FALSE(atk_text_set_selection(atk_text, 0, 0, 50));

  saw_selection_change = false;
  int n_characters = atk_text_get_character_count(atk_text);
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, -1));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_TRUE(saw_selection_change);
  g_free(atk_text_get_selection(atk_text, 0, &selection_start, &selection_end));
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, n_characters);

  saw_selection_change = false;
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 1));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_EQ(1, atk_text_get_n_selections(atk_text));
  EXPECT_TRUE(atk_text_remove_selection(atk_text, 0));
  EXPECT_TRUE(saw_selection_change);
  EXPECT_EQ(0, atk_text_get_n_selections(atk_text));

  // Reset position.
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 0));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);

  saw_selection_change = false;
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 1));
  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kTextSelectionChanged);
  EXPECT_EQ(1, atk_text_get_n_selections(atk_text));
  EXPECT_FALSE(atk_text_remove_selection(atk_text, 1));
  EXPECT_TRUE(saw_selection_change);
  EXPECT_EQ(1, atk_text_get_n_selections(atk_text));

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkTextTextFieldGetSelection) {
  Init(BuildTextField());
  AtkObject* root_atk_object(GetRootAtkObject());
  g_object_ref(root_atk_object);

  AtkText* atk_text = ATK_TEXT(root_atk_object);
  ASSERT_NE(nullptr, atk_text);

  int selection_start = 0, selection_end = 0;
  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 3));
  gchar* selected_text =
      atk_text_get_selection(atk_text, 0, &selection_start, &selection_end);
  EXPECT_STREQ("How", selected_text);
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 3);
  g_free(selected_text);

  selection_start = 0;
  selection_end = 0;

  EXPECT_TRUE(atk_text_remove_selection(atk_text, 0));
  selected_text =
      atk_text_get_selection(atk_text, 0, &selection_start, &selection_end);
  EXPECT_EQ(nullptr, selected_text);
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 0);

  EXPECT_TRUE(atk_text_set_selection(atk_text, 0, 0, 3));

  selected_text =
      atk_text_get_selection(atk_text, 1, &selection_start, &selection_end);
  EXPECT_EQ(nullptr, selected_text);
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 0);

  selected_text =
      atk_text_get_selection(atk_text, -1, &selection_start, &selection_end);
  EXPECT_EQ(nullptr, selected_text);
  EXPECT_EQ(selection_start, 0);
  EXPECT_EQ(selection_end, 0);

  g_object_unref(root_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectExpandRebuildsPlatformNode) {
  AXNodeData root_data;
  root_data.id = 1;
  root_data.role = ax::mojom::Role::kUnknown;

  Init(root_data);

  AtkObject* original_atk_object = GetRootAtkObject();
  ASSERT_TRUE(ATK_IS_OBJECT(original_atk_object));
  ASSERT_FALSE(ATK_IS_SELECTION(original_atk_object));
  g_object_ref(original_atk_object);

  root_data = AXNodeData();
  root_data.id = 1;
  root_data.role = ax::mojom::Role::kListBox;
  GetRootAsAXNode()->SetData(root_data);

  ASSERT_EQ(original_atk_object, GetRootAtkObject());

  GetRootPlatformNode()->NotifyAccessibilityEvent(
      ax::mojom::Event::kExpandedChanged);

  AtkObject* new_atk_object = GetRootAtkObject();
  ASSERT_NE(original_atk_object, new_atk_object);
  ASSERT_TRUE(ATK_IS_SELECTION(new_atk_object));

  g_object_unref(original_atk_object);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestAtkObjectParentChanged) {
  AXNodeData root_data;
  root_data.id = 1;
  root_data.role = ax::mojom::Role::kListBox;
  root_data.child_ids.push_back(2);

  AXNodeData item_1_data;
  item_1_data.id = 2;
  item_1_data.role = ax::mojom::Role::kListBoxOption;

  Init(root_data, item_1_data);

  AXNode* item_1 = GetRootAsAXNode()->children()[0];
  AtkObject* atk_object = AtkObjectFromNode(item_1);
  AXPlatformNodeAuraLinux* node = GetPlatformNode(item_1);

  bool saw_parent_changed = false;
  g_signal_connect(
      atk_object, "property-change::accessible-parent",
      G_CALLBACK(+[](AtkObject*, void* property, bool* saw_parent_changed) {
        *saw_parent_changed = true;
      }),
      &saw_parent_changed);

  ASSERT_FALSE(saw_parent_changed);
  node->OnParentChanged();
  ASSERT_TRUE(saw_parent_changed);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestScrolledToAnchorEvent) {
  AXNodeData root_data;
  root_data.id = 1;
  root_data.role = ax::mojom::Role::kListBox;
  root_data.child_ids.push_back(2);

  AXNodeData item_1_data;
  item_1_data.id = 2;
  item_1_data.role = ax::mojom::Role::kListBoxOption;

  Init(root_data, item_1_data);

  AXNode* item_1 = GetRootAsAXNode()->children()[0];
  AtkObject* atk_object = AtkObjectFromNode(item_1);

  bool saw_caret_moved = false;
  g_signal_connect(
      atk_object, "text-caret-moved",
      G_CALLBACK(+[](AtkObject*, int position, bool* saw_caret_moved) {
        *saw_caret_moved = true;
      }),
      &saw_caret_moved);

  GetPlatformNode(item_1)->OnScrolledToAnchor();

  ASSERT_TRUE(saw_caret_moved);
}

TEST_F(AXPlatformNodeAuraLinuxTest, TestDialogActiveWhenChildFocused) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWindow;
  root.child_ids.push_back(2);
  root.child_ids.push_back(3);

  AXNodeData dialog;
  dialog.id = 2;
  dialog.role = ax::mojom::Role::kDialog;
  dialog.child_ids.push_back(4);

  AXNodeData node_outside_dialog;
  node_outside_dialog.id = 3;
  node_outside_dialog.role = ax::mojom::Role::kTextField;

  AXNodeData entry;
  entry.id = 4;
  entry.role = ax::mojom::Role::kTextField;

  Init(root, dialog, node_outside_dialog, entry);

  AtkObject* root_atk_object(GetRootAtkObject());
  EXPECT_TRUE(ATK_IS_OBJECT(root_atk_object));

  AXNode* dialog_node = GetRootAsAXNode()->children()[0];
  AtkObject* dialog_obj = AtkObjectFromNode(dialog_node);
  bool saw_active_state_change = false;
  g_signal_connect(dialog_obj, "state-change",
                   G_CALLBACK(+[](AtkObject* atkobject, gchar* state_changed,
                                  gboolean new_value, bool* flag) {
                     if (!g_strcmp0(state_changed, "active"))
                       *flag = true;
                   }),
                   &saw_active_state_change);

  AXNode* entry_node = dialog_node->children()[0];
  GetPlatformNode(entry_node)
      ->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);
  EXPECT_TRUE(saw_active_state_change);
  EXPECT_TRUE(AtkObjectHasState(dialog_obj, ATK_STATE_ACTIVE));

  saw_active_state_change = false;

  AXNode* outside_node = GetRootAsAXNode()->children()[1];
  GetPlatformNode(outside_node)
      ->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);
  EXPECT_TRUE(saw_active_state_change);
  EXPECT_FALSE(AtkObjectHasState(dialog_obj, ATK_STATE_ACTIVE));
}

// Tests if kActiveDescendantChanged on unfocused node triggers a focused event.
TEST_F(AXPlatformNodeAuraLinuxTest,
       TestActiveDescendantChangedOnUnfocusedNode) {
  AXNodeData menu;
  menu.id = 1;
  menu.role = ax::mojom::Role::kMenu;
  menu.AddIntAttribute(ax::mojom::IntAttribute::kActivedescendantId, 4);
  menu.child_ids = {2, 3};

  AXNodeData input;
  input.id = 2;
  input.role = ax::mojom::Role::kTextField;
  input.AddState(ax::mojom::State::kFocusable);
  input.AddIntAttribute(ax::mojom::IntAttribute::kActivedescendantId, 4);

  AXNodeData container;
  container.id = 3;
  container.role = ax::mojom::Role::kGenericContainer;
  container.child_ids = {4, 5};

  AXNodeData menu_item_1;
  menu_item_1.id = 4;
  menu_item_1.role = ax::mojom::Role::kMenuItemCheckBox;

  AXNodeData menu_item_2;
  menu_item_2.id = 5;
  menu_item_2.role = ax::mojom::Role::kMenuItemCheckBox;

  Init(menu, input, container, menu_item_1, menu_item_2);
  TestAXNodeWrapper::SetGlobalIsWebContent(true);

  // Creates TestAXNodeWrapper for the first menu item to keep the current
  // active descendant.
  AtkObjectFromNode(GetRootAsAXNode()->children()[1]->children()[0]);

  // Sets focus to the input node.
  AXNode* input_node = GetRootAsAXNode()->children()[0];
  GetPlatformNode(input_node)
      ->NotifyAccessibilityEvent(ax::mojom::Event::kFocus);

  bool saw_active_focus_state_change = false;
  AtkObject* menu_2_atk_object =
      AtkObjectFromNode(GetRootAsAXNode()->children()[1]->children()[1]);
  EXPECT_TRUE(ATK_IS_OBJECT(menu_2_atk_object));
  g_object_ref(menu_2_atk_object);
  // Registers callback to get focus event on |menu_2_atk_object|.
  g_signal_connect(menu_2_atk_object, "state-change",
                   G_CALLBACK(+[](AtkObject* atkobject, gchar* state_changed,
                                  gboolean new_value, bool* flag) {
                     if (!g_strcmp0(state_changed, "focused") && new_value)
                       *flag = true;
                   }),
                   &saw_active_focus_state_change);

  // Updates the active descendant node from the node id 4 to the node id 5;
  AXNode* menu_node = GetRootAsAXNode();
  AXNodeData menu_new_data(menu);
  menu_new_data.AddIntAttribute(ax::mojom::IntAttribute::kActivedescendantId,
                                5);
  menu_node->SetData(menu_new_data);

  AXNodeData input_new_data(input);
  input_new_data.AddIntAttribute(ax::mojom::IntAttribute::kActivedescendantId,
                                 5);
  input_node->SetData(input_new_data);

  // Notifies active descendant is changed.
  GetPlatformNode(menu_node)->NotifyAccessibilityEvent(
      ax::mojom::Event::kActiveDescendantChanged);
  // The current active descendant node, |menu_2_atk_object|, should get the
  // focused event.
  EXPECT_TRUE(saw_active_focus_state_change);

  TestAXNodeWrapper::SetGlobalIsWebContent(false);
  g_object_unref(menu_2_atk_object);
}

}  // namespace ui

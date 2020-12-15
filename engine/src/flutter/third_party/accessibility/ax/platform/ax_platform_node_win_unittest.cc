//
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_node_win_unittest.h"

#include <oleacc.h>
#include <wrl/client.h>

#include <memory>

#include "base/auto_reset.h"
#include "base/json/json_reader.h"
#include "base/run_loop.h"
#include "base/stl_util.h"
#include "base/test/metrics/histogram_tester.h"
#include "base/test/task_environment.h"
#include "base/win/atl.h"
#include "base/win/scoped_bstr.h"
#include "base/win/scoped_safearray.h"
#include "base/win/scoped_variant.h"
#include "testing/gmock/include/gmock/gmock-matchers.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/iaccessible2/ia2_api_all.h"
#include "ui/accessibility/accessibility_features.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/platform/ax_fragment_root_win.h"
#include "ui/accessibility/platform/ax_platform_node_win.h"
#include "ui/accessibility/platform/test_ax_node_wrapper.h"
#include "ui/base/win/atl_module.h"

using Microsoft::WRL::ComPtr;
using base::win::ScopedBstr;
using base::win::ScopedVariant;

namespace ui {

const base::string16 AXPlatformNodeWinTest::kEmbeddedCharacterAsString = {
    ui::AXPlatformNodeBase::kEmbeddedCharacter};

namespace {

// Most IAccessible functions require a VARIANT set to CHILDID_SELF as
// the first argument.
ScopedVariant SELF(CHILDID_SELF);

}  // namespace

// Helper macros for UIAutomation HRESULT expectations
#define EXPECT_UIA_ELEMENTNOTAVAILABLE(expr) \
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE), (expr))
#define EXPECT_UIA_INVALIDOPERATION(expr) \
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_INVALIDOPERATION), (expr))
#define EXPECT_UIA_ELEMENTNOTENABLED(expr) \
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTENABLED), (expr))
#define EXPECT_UIA_NOTSUPPORTED(expr) \
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED), (expr))

#define ASSERT_UIA_ELEMENTNOTAVAILABLE(expr) \
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE), (expr))
#define ASSERT_UIA_INVALIDOPERATION(expr) \
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_INVALIDOPERATION), (expr))
#define ASSERT_UIA_ELEMENTNOTENABLED(expr) \
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTENABLED), (expr))
#define ASSERT_UIA_NOTSUPPORTED(expr) \
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED), (expr))

// Helper macros for testing UIAutomation property values and maintain
// correct stack tracing and failure causality.
//
// WARNING: These aren't intended to be generic EXPECT_BSTR_EQ macros
// as the logic is specific to extracting and comparing UIA property
// values.
#define EXPECT_UIA_EMPTY(node, property_id)                     \
  {                                                             \
    ScopedVariant actual;                                       \
    ASSERT_HRESULT_SUCCEEDED(                                   \
        node->GetPropertyValue(property_id, actual.Receive())); \
    EXPECT_EQ(VT_EMPTY, actual.type());                         \
  }

#define EXPECT_UIA_VALUE_EQ(node, property_id, expectedVariant) \
  {                                                             \
    ScopedVariant actual;                                       \
    ASSERT_HRESULT_SUCCEEDED(                                   \
        node->GetPropertyValue(property_id, actual.Receive())); \
    EXPECT_EQ(0, actual.Compare(expectedVariant));              \
  }

#define EXPECT_UIA_BSTR_EQ(node, property_id, expected)                  \
  {                                                                      \
    ScopedVariant expectedVariant(expected);                             \
    ASSERT_EQ(VT_BSTR, expectedVariant.type());                          \
    ASSERT_NE(nullptr, expectedVariant.ptr()->bstrVal);                  \
    ScopedVariant actual;                                                \
    ASSERT_HRESULT_SUCCEEDED(                                            \
        node->GetPropertyValue(property_id, actual.Receive()));          \
    ASSERT_EQ(VT_BSTR, actual.type());                                   \
    ASSERT_NE(nullptr, actual.ptr()->bstrVal);                           \
    EXPECT_STREQ(expectedVariant.ptr()->bstrVal, actual.ptr()->bstrVal); \
  }

#define EXPECT_UIA_BOOL_EQ(node, property_id, expected)               \
  {                                                                   \
    ScopedVariant expectedVariant(expected);                          \
    ASSERT_EQ(VT_BOOL, expectedVariant.type());                       \
    ScopedVariant actual;                                             \
    ASSERT_HRESULT_SUCCEEDED(                                         \
        node->GetPropertyValue(property_id, actual.Receive()));       \
    EXPECT_EQ(expectedVariant.ptr()->boolVal, actual.ptr()->boolVal); \
  }

#define EXPECT_UIA_DOUBLE_ARRAY_EQ(node, array_property_id,                 \
                                   expected_property_values)                \
  {                                                                         \
    ScopedVariant array;                                                    \
    ASSERT_HRESULT_SUCCEEDED(                                               \
        node->GetPropertyValue(array_property_id, array.Receive()));        \
    ASSERT_EQ(VT_ARRAY | VT_R8, array.type());                              \
    ASSERT_EQ(1u, SafeArrayGetDim(array.ptr()->parray));                    \
    LONG array_lower_bound;                                                 \
    ASSERT_HRESULT_SUCCEEDED(                                               \
        SafeArrayGetLBound(array.ptr()->parray, 1, &array_lower_bound));    \
    LONG array_upper_bound;                                                 \
    ASSERT_HRESULT_SUCCEEDED(                                               \
        SafeArrayGetUBound(array.ptr()->parray, 1, &array_upper_bound));    \
    double* array_data;                                                     \
    ASSERT_HRESULT_SUCCEEDED(::SafeArrayAccessData(                         \
        array.ptr()->parray, reinterpret_cast<void**>(&array_data)));       \
    size_t count = array_upper_bound - array_lower_bound + 1;               \
    ASSERT_EQ(expected_property_values.size(), count);                      \
    for (size_t i = 0; i < count; ++i) {                                    \
      EXPECT_EQ(array_data[i], expected_property_values[i]);                \
    }                                                                       \
    ASSERT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(array.ptr()->parray)); \
  }

#define EXPECT_UIA_INT_EQ(node, property_id, expected)              \
  {                                                                 \
    ScopedVariant expectedVariant(expected);                        \
    ASSERT_EQ(VT_I4, expectedVariant.type());                       \
    ScopedVariant actual;                                           \
    ASSERT_HRESULT_SUCCEEDED(                                       \
        node->GetPropertyValue(property_id, actual.Receive()));     \
    EXPECT_EQ(expectedVariant.ptr()->intVal, actual.ptr()->intVal); \
  }

#define EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(array, element_test_property_id,     \
                                         expected_property_values)            \
  {                                                                           \
    ASSERT_EQ(1u, SafeArrayGetDim(array));                                    \
    LONG array_lower_bound;                                                   \
    ASSERT_HRESULT_SUCCEEDED(                                                 \
        SafeArrayGetLBound(array, 1, &array_lower_bound));                    \
    LONG array_upper_bound;                                                   \
    ASSERT_HRESULT_SUCCEEDED(                                                 \
        SafeArrayGetUBound(array, 1, &array_upper_bound));                    \
    IUnknown** array_data;                                                    \
    ASSERT_HRESULT_SUCCEEDED(                                                 \
        ::SafeArrayAccessData(array, reinterpret_cast<void**>(&array_data))); \
    size_t count = array_upper_bound - array_lower_bound + 1;                 \
    ASSERT_EQ(expected_property_values.size(), count);                        \
    for (size_t i = 0; i < count; ++i) {                                      \
      ComPtr<IRawElementProviderSimple> element;                              \
      ASSERT_HRESULT_SUCCEEDED(                                               \
          array_data[i]->QueryInterface(IID_PPV_ARGS(&element)));             \
      EXPECT_UIA_BSTR_EQ(element, element_test_property_id,                   \
                         expected_property_values[i].c_str());                \
    }                                                                         \
    ASSERT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(array));                 \
  }

#define EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(node, array_property_id,  \
                                                  element_test_property_id, \
                                                  expected_property_values) \
  {                                                                         \
    ScopedVariant array;                                                    \
    ASSERT_HRESULT_SUCCEEDED(                                               \
        node->GetPropertyValue(array_property_id, array.Receive()));        \
    ASSERT_EQ(VT_ARRAY | VT_UNKNOWN, array.type());                         \
    EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(array.ptr()->parray,                   \
                                     element_test_property_id,              \
                                     expected_property_values);             \
  }

#define EXPECT_UIA_PROPERTY_UNORDERED_ELEMENT_ARRAY_BSTR_EQ(                   \
    node, array_property_id, element_test_property_id,                         \
    expected_property_values)                                                  \
  {                                                                            \
    ScopedVariant array;                                                       \
    ASSERT_HRESULT_SUCCEEDED(                                                  \
        node->GetPropertyValue(array_property_id, array.Receive()));           \
    ASSERT_EQ(VT_ARRAY | VT_UNKNOWN, array.type());                            \
    ASSERT_EQ(1u, SafeArrayGetDim(array.ptr()->parray));                       \
    LONG array_lower_bound;                                                    \
    ASSERT_HRESULT_SUCCEEDED(                                                  \
        SafeArrayGetLBound(array.ptr()->parray, 1, &array_lower_bound));       \
    LONG array_upper_bound;                                                    \
    ASSERT_HRESULT_SUCCEEDED(                                                  \
        SafeArrayGetUBound(array.ptr()->parray, 1, &array_upper_bound));       \
    IUnknown** array_data;                                                     \
    ASSERT_HRESULT_SUCCEEDED(::SafeArrayAccessData(                            \
        array.ptr()->parray, reinterpret_cast<void**>(&array_data)));          \
    size_t count = array_upper_bound - array_lower_bound + 1;                  \
    ASSERT_EQ(expected_property_values.size(), count);                         \
    std::vector<std::wstring> property_values;                                 \
    for (size_t i = 0; i < count; ++i) {                                       \
      ComPtr<IRawElementProviderSimple> element;                               \
      ASSERT_HRESULT_SUCCEEDED(                                                \
          array_data[i]->QueryInterface(IID_PPV_ARGS(&element)));              \
      ScopedVariant actual;                                                    \
      ASSERT_HRESULT_SUCCEEDED(element->GetPropertyValue(                      \
          element_test_property_id, actual.Receive()));                        \
      ASSERT_EQ(VT_BSTR, actual.type());                                       \
      ASSERT_NE(nullptr, actual.ptr()->bstrVal);                               \
      property_values.push_back(std::wstring(                                  \
          V_BSTR(actual.ptr()), SysStringLen(V_BSTR(actual.ptr()))));          \
    }                                                                          \
    ASSERT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(array.ptr()->parray));    \
    EXPECT_THAT(property_values,                                               \
                testing::UnorderedElementsAreArray(expected_property_values)); \
  }

MockIRawElementProviderSimple::MockIRawElementProviderSimple() = default;
MockIRawElementProviderSimple::~MockIRawElementProviderSimple() = default;

HRESULT
MockIRawElementProviderSimple::CreateMockIRawElementProviderSimple(
    IRawElementProviderSimple** provider) {
  CComObject<MockIRawElementProviderSimple>* raw_element_provider = nullptr;
  HRESULT hr = CComObject<MockIRawElementProviderSimple>::CreateInstance(
      &raw_element_provider);
  if (SUCCEEDED(hr)) {
    *provider = raw_element_provider;
  }

  return hr;
}

//
// IRawElementProviderSimple methods.
//
IFACEMETHODIMP MockIRawElementProviderSimple::GetPatternProvider(
    PATTERNID pattern_id,
    IUnknown** result) {
  return E_NOTIMPL;
}

IFACEMETHODIMP MockIRawElementProviderSimple::GetPropertyValue(
    PROPERTYID property_id,
    VARIANT* result) {
  return E_NOTIMPL;
}

IFACEMETHODIMP
MockIRawElementProviderSimple::get_ProviderOptions(enum ProviderOptions* ret) {
  return E_NOTIMPL;
}

IFACEMETHODIMP MockIRawElementProviderSimple::get_HostRawElementProvider(
    IRawElementProviderSimple** provider) {
  return E_NOTIMPL;
}

AXPlatformNodeWinTest::AXPlatformNodeWinTest() {
  scoped_feature_list_.InitAndEnableFeature(features::kIChromeAccessible);
}

AXPlatformNodeWinTest::~AXPlatformNodeWinTest() {}

void AXPlatformNodeWinTest::SetUp() {
  win::CreateATLModuleIfNeeded();
}

void AXPlatformNodeWinTest::TearDown() {
  // Destroy the tree and make sure we're not leaking any objects.
  ax_fragment_root_.reset(nullptr);
  DestroyTree();
  TestAXNodeWrapper::SetGlobalIsWebContent(false);
  ASSERT_EQ(0U, AXPlatformNodeBase::GetInstanceCountForTesting());
}

AXPlatformNode* AXPlatformNodeWinTest::AXPlatformNodeFromNode(AXNode* node) {
  const TestAXNodeWrapper* wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), node);
  return wrapper ? wrapper->ax_platform_node() : nullptr;
}

template <typename T>
ComPtr<T> AXPlatformNodeWinTest::QueryInterfaceFromNodeId(AXNode::AXID id) {
  return QueryInterfaceFromNode<T>(GetNodeFromTree(id));
}

template <typename T>
ComPtr<T> AXPlatformNodeWinTest::QueryInterfaceFromNode(AXNode* node) {
  AXPlatformNode* ax_platform_node = AXPlatformNodeFromNode(node);
  if (!ax_platform_node)
    return ComPtr<T>();
  ComPtr<T> result;
  EXPECT_HRESULT_SUCCEEDED(
      ax_platform_node->GetNativeViewAccessible()->QueryInterface(__uuidof(T),
                                                                  &result));
  return result;
}

ComPtr<IRawElementProviderSimple>
AXPlatformNodeWinTest::GetRootIRawElementProviderSimple() {
  return QueryInterfaceFromNode<IRawElementProviderSimple>(GetRootAsAXNode());
}

ComPtr<IRawElementProviderSimple>
AXPlatformNodeWinTest::GetIRawElementProviderSimpleFromChildIndex(
    int child_index) {
  if (!GetRootAsAXNode() || child_index < 0 ||
      size_t{child_index} >= GetRootAsAXNode()->children().size()) {
    return ComPtr<IRawElementProviderSimple>();
  }

  return QueryInterfaceFromNode<IRawElementProviderSimple>(
      GetRootAsAXNode()->children()[size_t{child_index}]);
}

Microsoft::WRL::ComPtr<IRawElementProviderSimple>
AXPlatformNodeWinTest::GetIRawElementProviderSimpleFromTree(
    const ui::AXTreeID tree_id,
    const AXNode::AXID node_id) {
  return QueryInterfaceFromNode<IRawElementProviderSimple>(
      GetNodeFromTree(tree_id, node_id));
}

ComPtr<IRawElementProviderFragment>
AXPlatformNodeWinTest::GetRootIRawElementProviderFragment() {
  return QueryInterfaceFromNode<IRawElementProviderFragment>(GetRootAsAXNode());
}

Microsoft::WRL::ComPtr<IRawElementProviderFragment>
AXPlatformNodeWinTest::IRawElementProviderFragmentFromNode(AXNode* node) {
  AXPlatformNode* platform_node = AXPlatformNodeFromNode(node);
  gfx::NativeViewAccessible native_view =
      platform_node->GetNativeViewAccessible();
  ComPtr<IUnknown> unknown_node = native_view;
  ComPtr<IRawElementProviderFragment> fragment_node;
  unknown_node.As(&fragment_node);

  return fragment_node;
}

ComPtr<IAccessible> AXPlatformNodeWinTest::IAccessibleFromNode(AXNode* node) {
  return QueryInterfaceFromNode<IAccessible>(node);
}

ComPtr<IAccessible> AXPlatformNodeWinTest::GetRootIAccessible() {
  return IAccessibleFromNode(GetRootAsAXNode());
}

ComPtr<IAccessible2> AXPlatformNodeWinTest::ToIAccessible2(
    ComPtr<IUnknown> unknown) {
  CHECK(unknown);
  ComPtr<IServiceProvider> service_provider;
  unknown.As(&service_provider);
  ComPtr<IAccessible2> result;
  CHECK(SUCCEEDED(
      service_provider->QueryService(IID_IAccessible2, IID_PPV_ARGS(&result))));
  return result;
}

ComPtr<IAccessible2> AXPlatformNodeWinTest::ToIAccessible2(
    ComPtr<IAccessible> accessible) {
  CHECK(accessible);
  ComPtr<IServiceProvider> service_provider;
  accessible.As(&service_provider);
  ComPtr<IAccessible2> result;
  CHECK(SUCCEEDED(
      service_provider->QueryService(IID_IAccessible2, IID_PPV_ARGS(&result))));
  return result;
}

ComPtr<IAccessible2_2> AXPlatformNodeWinTest::ToIAccessible2_2(
    ComPtr<IAccessible> accessible) {
  CHECK(accessible);
  ComPtr<IServiceProvider> service_provider;
  accessible.As(&service_provider);
  ComPtr<IAccessible2_2> result;
  CHECK(SUCCEEDED(service_provider->QueryService(IID_IAccessible2_2,
                                                 IID_PPV_ARGS(&result))));
  return result;
}

void AXPlatformNodeWinTest::CheckVariantHasName(const ScopedVariant& variant,
                                                const wchar_t* expected_name) {
  ASSERT_NE(nullptr, variant.ptr());
  ComPtr<IAccessible> accessible;
  ASSERT_HRESULT_SUCCEEDED(
      V_DISPATCH(variant.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
  ScopedBstr name;
  EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
  EXPECT_STREQ(expected_name, name.Get());
}

void AXPlatformNodeWinTest::CheckIUnknownHasName(ComPtr<IUnknown> unknown,
                                                 const wchar_t* expected_name) {
  ComPtr<IAccessible2> accessible = ToIAccessible2(unknown);
  ASSERT_NE(nullptr, accessible.Get());

  ScopedBstr name;
  EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
  EXPECT_STREQ(expected_name, name.Get());
}

ComPtr<IAccessibleTableCell> AXPlatformNodeWinTest::GetCellInTable() {
  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable2> table;
  root_obj.As(&table);
  if (!table)
    return ComPtr<IAccessibleTableCell>();

  ComPtr<IUnknown> cell;
  table->get_cellAt(1, 1, &cell);
  if (!cell)
    return ComPtr<IAccessibleTableCell>();

  ComPtr<IAccessibleTableCell> table_cell;
  cell.As(&table_cell);
  return table_cell;
}

void AXPlatformNodeWinTest::InitFragmentRoot() {
  test_fragment_root_delegate_ = std::make_unique<TestFragmentRootDelegate>();
  ax_fragment_root_.reset(InitNodeAsFragmentRoot(
      GetRootAsAXNode(), test_fragment_root_delegate_.get()));
}

AXFragmentRootWin* AXPlatformNodeWinTest::InitNodeAsFragmentRoot(
    AXNode* node,
    TestFragmentRootDelegate* delegate) {
  delegate->child_ = AXPlatformNodeFromNode(node)->GetNativeViewAccessible();
  if (node->parent())
    delegate->parent_ =
        AXPlatformNodeFromNode(node->parent())->GetNativeViewAccessible();

  return new AXFragmentRootWin(gfx::kMockAcceleratedWidget, delegate);
}

ComPtr<IRawElementProviderFragmentRoot>
AXPlatformNodeWinTest::GetFragmentRoot() {
  ComPtr<IRawElementProviderFragmentRoot> fragment_root_provider;
  ax_fragment_root_->GetNativeViewAccessible()->QueryInterface(
      IID_PPV_ARGS(&fragment_root_provider));
  return fragment_root_provider;
}

AXPlatformNodeWinTest::PatternSet
AXPlatformNodeWinTest::GetSupportedPatternsFromNodeId(AXNode::AXID id) {
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      QueryInterfaceFromNodeId<IRawElementProviderSimple>(id);
  PatternSet supported_patterns;
  static const std::vector<LONG> all_supported_patterns_ = {
      UIA_TextChildPatternId,  UIA_TextEditPatternId,
      UIA_TextPatternId,       UIA_WindowPatternId,
      UIA_InvokePatternId,     UIA_ExpandCollapsePatternId,
      UIA_GridPatternId,       UIA_GridItemPatternId,
      UIA_RangeValuePatternId, UIA_ScrollPatternId,
      UIA_ScrollItemPatternId, UIA_TablePatternId,
      UIA_TableItemPatternId,  UIA_SelectionItemPatternId,
      UIA_SelectionPatternId,  UIA_TogglePatternId,
      UIA_ValuePatternId,
  };
  for (LONG property_id : all_supported_patterns_) {
    ComPtr<IUnknown> provider;
    if (SUCCEEDED(raw_element_provider_simple->GetPatternProvider(property_id,
                                                                  &provider)) &&
        provider) {
      supported_patterns.insert(property_id);
    }
  }
  return supported_patterns;
}

TestFragmentRootDelegate::TestFragmentRootDelegate() = default;

TestFragmentRootDelegate::~TestFragmentRootDelegate() = default;

gfx::NativeViewAccessible TestFragmentRootDelegate::GetChildOfAXFragmentRoot() {
  return child_;
}

gfx::NativeViewAccessible
TestFragmentRootDelegate::GetParentOfAXFragmentRoot() {
  return parent_;
}

bool TestFragmentRootDelegate::IsAXFragmentRootAControlElement() {
  return is_control_element_;
}

TEST_F(AXPlatformNodeWinTest, IAccessibleDetachedObject) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("Name");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedBstr name;
  EXPECT_EQ(S_OK, root_obj->get_accName(SELF, name.Receive()));
  EXPECT_STREQ(L"Name", name.Get());

  // Create an empty tree.
  SetTree(std::make_unique<AXTree>());
  ScopedBstr name2;
  EXPECT_EQ(E_FAIL, root_obj->get_accName(SELF, name2.Receive()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleHitTest) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 40, 40);

  AXNodeData node1;
  node1.id = 2;
  node1.role = ax::mojom::Role::kGenericContainer;
  node1.relative_bounds.bounds = gfx::RectF(0, 0, 10, 10);
  node1.SetName("Name1");
  root.child_ids.push_back(node1.id);

  AXNodeData node2;
  node2.id = 3;
  node2.role = ax::mojom::Role::kGenericContainer;
  node2.relative_bounds.bounds = gfx::RectF(20, 20, 20, 20);
  node2.SetName("Name2");
  root.child_ids.push_back(node2.id);

  Init(root, node1, node2);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  // This is way outside of the root node.
  ScopedVariant obj_1;
  EXPECT_EQ(S_FALSE, root_obj->accHitTest(50, 50, obj_1.Receive()));
  EXPECT_EQ(VT_EMPTY, obj_1.type());

  // This is directly on node 1.
  EXPECT_EQ(S_OK, root_obj->accHitTest(5, 5, obj_1.Receive()));
  ASSERT_NE(nullptr, obj_1.ptr());
  CheckVariantHasName(obj_1, L"Name1");

  // This is directly on node 2 with a scale factor of 1.5.
  ScopedVariant obj_2;
  std::unique_ptr<base::AutoReset<float>> scale_factor_reset =
      TestAXNodeWrapper::SetScaleFactor(1.5);
  EXPECT_EQ(S_OK, root_obj->accHitTest(38, 38, obj_2.Receive()));
  ASSERT_NE(nullptr, obj_2.ptr());
  CheckVariantHasName(obj_2, L"Name2");
}

TEST_F(AXPlatformNodeWinTest, IAccessibleHitTestDoesNotLoopForever) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 40, 40);

  AXNodeData node1;
  node1.id = 2;
  node1.role = ax::mojom::Role::kGenericContainer;
  node1.relative_bounds.bounds = gfx::RectF(0, 0, 10, 10);
  node1.SetName("Name1");
  root.child_ids.push_back(node1.id);

  Init(root, node1);

  // Set up the endless loop.
  TestAXNodeWrapper::SetHitTestResult(1, 2);
  TestAXNodeWrapper::SetHitTestResult(2, 1);

  // Hit testing on the root returns the child. Hit testing on the
  // child returns the root, but that should be rejected rather than
  // looping endlessly.
  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedVariant obj_1;
  EXPECT_EQ(S_OK, root_obj->accHitTest(5, 5, obj_1.Receive()));
  ASSERT_NE(nullptr, obj_1.ptr());
  CheckVariantHasName(obj_1, L"Name1");
}

TEST_F(AXPlatformNodeWinTest, IAccessibleName) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("Name");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedBstr name;
  EXPECT_EQ(S_OK, root_obj->get_accName(SELF, name.Receive()));
  EXPECT_STREQ(L"Name", name.Get());

  EXPECT_EQ(E_INVALIDARG, root_obj->get_accName(SELF, nullptr));
  ScopedVariant bad_id(999);
  ScopedBstr name2;
  EXPECT_EQ(E_INVALIDARG, root_obj->get_accName(bad_id, name2.Receive()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleDescription) {
  AXNodeData root;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kDescription,
                          "Description");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedBstr description;
  EXPECT_EQ(S_OK, root_obj->get_accDescription(SELF, description.Receive()));
  EXPECT_STREQ(L"Description", description.Get());

  EXPECT_EQ(E_INVALIDARG, root_obj->get_accDescription(SELF, nullptr));
  ScopedVariant bad_id(999);
  ScopedBstr d2;
  EXPECT_EQ(E_INVALIDARG, root_obj->get_accDescription(bad_id, d2.Receive()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleAccValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTextField;
  root.AddStringAttribute(ax::mojom::StringAttribute::kValue, "Value");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedBstr value;
  EXPECT_EQ(S_OK, root_obj->get_accValue(SELF, value.Receive()));
  EXPECT_STREQ(L"Value", value.Get());

  EXPECT_EQ(E_INVALIDARG, root_obj->get_accValue(SELF, nullptr));
  ScopedVariant bad_id(999);
  ScopedBstr v2;
  EXPECT_EQ(E_INVALIDARG, root_obj->get_accValue(bad_id, v2.Receive()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleShortcut) {
  AXNodeData root;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kKeyShortcuts,
                          "Shortcut");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ScopedBstr shortcut;
  EXPECT_EQ(S_OK, root_obj->get_accKeyboardShortcut(SELF, shortcut.Receive()));
  EXPECT_STREQ(L"Shortcut", shortcut.Get());

  EXPECT_EQ(E_INVALIDARG, root_obj->get_accKeyboardShortcut(SELF, nullptr));
  ScopedVariant bad_id(999);
  ScopedBstr k2;
  EXPECT_EQ(E_INVALIDARG,
            root_obj->get_accKeyboardShortcut(bad_id, k2.Receive()));
}

TEST_F(AXPlatformNodeWinTest,
       IAccessibleSelectionListBoxOptionNothingSelected) {
  AXNodeData list;
  list.id = 1;
  list.role = ax::mojom::Role::kListBox;

  AXNodeData list_item_1;
  list_item_1.id = 2;
  list_item_1.role = ax::mojom::Role::kListBoxOption;
  list_item_1.SetName("Name1");

  AXNodeData list_item_2;
  list_item_2.id = 3;
  list_item_2.role = ax::mojom::Role::kListBoxOption;
  list_item_2.SetName("Name2");

  list.child_ids.push_back(list_item_1.id);
  list.child_ids.push_back(list_item_2.id);

  Init(list, list_item_1, list_item_2);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_EMPTY, selection.type());
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionListBoxOptionOneSelected) {
  AXNodeData list;
  list.id = 1;
  list.role = ax::mojom::Role::kListBox;

  AXNodeData list_item_1;
  list_item_1.id = 2;
  list_item_1.role = ax::mojom::Role::kListBoxOption;
  list_item_1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  list_item_1.SetName("Name1");

  AXNodeData list_item_2;
  list_item_2.id = 3;
  list_item_2.role = ax::mojom::Role::kListBoxOption;
  list_item_2.SetName("Name2");

  list.child_ids.push_back(list_item_1.id);
  list.child_ids.push_back(list_item_2.id);

  Init(list, list_item_1, list_item_2);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_DISPATCH, selection.type());

  CheckVariantHasName(selection, L"Name1");
}

TEST_F(AXPlatformNodeWinTest,
       IAccessibleSelectionListBoxOptionMultipleSelected) {
  AXNodeData list;
  list.id = 1;
  list.role = ax::mojom::Role::kListBox;

  AXNodeData list_item_1;
  list_item_1.id = 2;
  list_item_1.role = ax::mojom::Role::kListBoxOption;
  list_item_1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  list_item_1.SetName("Name1");

  AXNodeData list_item_2;
  list_item_2.id = 3;
  list_item_2.role = ax::mojom::Role::kListBoxOption;
  list_item_2.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  list_item_2.SetName("Name2");

  AXNodeData list_item_3;
  list_item_3.id = 4;
  list_item_3.role = ax::mojom::Role::kListBoxOption;
  list_item_3.SetName("Name3");

  list.child_ids.push_back(list_item_1.id);
  list.child_ids.push_back(list_item_2.id);
  list.child_ids.push_back(list_item_3.id);

  Init(list, list_item_1, list_item_2, list_item_3);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_UNKNOWN, selection.type());
  ASSERT_NE(nullptr, selection.ptr());

  // Loop through the selections and  make sure we have the right ones.
  ComPtr<IEnumVARIANT> accessibles;
  ASSERT_HRESULT_SUCCEEDED(
      V_UNKNOWN(selection.ptr())->QueryInterface(IID_PPV_ARGS(&accessibles)));
  ULONG retrieved_count;

  // Check out the first selected item.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedBstr name;
    EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
    EXPECT_STREQ(L"Name1", name.Get());
  }

  // And the second selected element.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedBstr name;
    EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
    EXPECT_STREQ(L"Name2", name.Get());
  }

  // There shouldn't be any more selected.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_FALSE, hr);
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionTableNothingSelected) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_EMPTY, selection.type());
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionTableRowOneSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 5 == table_row_1
  update.nodes[5].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_DISPATCH, selection.type());
  ASSERT_NE(nullptr, selection.ptr());

  ComPtr<IAccessible> row;
  ASSERT_HRESULT_SUCCEEDED(
      V_DISPATCH(selection.ptr())->QueryInterface(IID_PPV_ARGS(&row)));

  ScopedVariant role;
  EXPECT_HRESULT_SUCCEEDED(row->get_accRole(SELF, role.Receive()));
  EXPECT_EQ(ROLE_SYSTEM_ROW, V_I4(role.ptr()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionTableRowMultipleSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 5 == table_row_1
  // 9 == table_row_2
  update.nodes[5].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[9].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ScopedVariant selection;
  EXPECT_EQ(S_OK, root_obj->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_UNKNOWN, selection.type());
  ASSERT_NE(nullptr, selection.ptr());

  // Loop through the selections and  make sure we have the right ones.
  ComPtr<IEnumVARIANT> accessibles;
  ASSERT_HRESULT_SUCCEEDED(
      V_UNKNOWN(selection.ptr())->QueryInterface(IID_PPV_ARGS(&accessibles)));
  ULONG retrieved_count;

  // Check out the first selected row.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedVariant role;
    EXPECT_HRESULT_SUCCEEDED(accessible->get_accRole(SELF, role.Receive()));
    EXPECT_EQ(ROLE_SYSTEM_ROW, V_I4(role.ptr()));
  }

  // And the second selected element.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedVariant role;
    EXPECT_HRESULT_SUCCEEDED(accessible->get_accRole(SELF, role.Receive()));
    EXPECT_EQ(ROLE_SYSTEM_ROW, V_I4(role.ptr()));
  }

  // There shouldn't be any more selected.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_FALSE, hr);
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionTableCellOneSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ComPtr<IDispatch> row2;
  ASSERT_HRESULT_SUCCEEDED(root_obj->get_accChild(ScopedVariant(2), &row2));
  ComPtr<IAccessible> row2_accessible;
  ASSERT_HRESULT_SUCCEEDED(row2.As(&row2_accessible));

  ScopedVariant selection;
  EXPECT_EQ(S_OK, row2_accessible->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_DISPATCH, selection.type());
  ASSERT_NE(nullptr, selection.ptr());

  ComPtr<IAccessible> cell;
  ASSERT_HRESULT_SUCCEEDED(
      V_DISPATCH(selection.ptr())->QueryInterface(IID_PPV_ARGS(&cell)));

  ScopedVariant role;
  EXPECT_HRESULT_SUCCEEDED(cell->get_accRole(SELF, role.Receive()));
  EXPECT_EQ(ROLE_SYSTEM_CELL, V_I4(role.ptr()));

  ScopedBstr name;
  EXPECT_EQ(S_OK, cell->get_accName(SELF, name.Receive()));
  EXPECT_STREQ(L"1", name.Get());
}

TEST_F(AXPlatformNodeWinTest, IAccessibleSelectionTableCellMultipleSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 11 == table_cell_3
  // 12 == table_cell_4
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ASSERT_NE(nullptr, root_obj.Get());

  ComPtr<IDispatch> row3;
  ASSERT_HRESULT_SUCCEEDED(root_obj->get_accChild(ScopedVariant(3), &row3));
  ComPtr<IAccessible> row3_accessible;
  ASSERT_HRESULT_SUCCEEDED(row3.As(&row3_accessible));

  ScopedVariant selection;
  EXPECT_EQ(S_OK, row3_accessible->get_accSelection(selection.Receive()));
  EXPECT_EQ(VT_UNKNOWN, selection.type());
  ASSERT_NE(nullptr, selection.ptr());

  // Loop through the selections and  make sure we have the right ones.
  ComPtr<IEnumVARIANT> accessibles;
  ASSERT_HRESULT_SUCCEEDED(
      V_UNKNOWN(selection.ptr())->QueryInterface(IID_PPV_ARGS(&accessibles)));
  ULONG retrieved_count;

  // Check out the first selected cell.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedBstr name;
    EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
    EXPECT_STREQ(L"3", name.Get());
  }

  // And the second selected cell.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_OK, hr);

    ComPtr<IAccessible> accessible;
    ASSERT_HRESULT_SUCCEEDED(
        V_DISPATCH(item.ptr())->QueryInterface(IID_PPV_ARGS(&accessible)));
    ScopedBstr name;
    EXPECT_EQ(S_OK, accessible->get_accName(SELF, name.Receive()));
    EXPECT_STREQ(L"4", name.Get());
  }

  // There shouldn't be any more selected.
  {
    ScopedVariant item;
    HRESULT hr = accessibles->Next(1, item.Receive(), &retrieved_count);
    EXPECT_EQ(S_FALSE, hr);
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleRole) {
  AXNodeData root;
  root.id = 1;
  root.child_ids.push_back(2);

  AXNodeData child;
  child.id = 2;

  Init(root, child);
  AXNode* child_node = GetRootAsAXNode()->children()[0];
  ComPtr<IAccessible> child_iaccessible(IAccessibleFromNode(child_node));

  ScopedVariant role;

  child.role = ax::mojom::Role::kAlert;
  child_node->SetData(child);
  EXPECT_EQ(S_OK, child_iaccessible->get_accRole(SELF, role.Receive()));
  EXPECT_EQ(ROLE_SYSTEM_ALERT, V_I4(role.ptr()));

  child.role = ax::mojom::Role::kButton;
  child_node->SetData(child);
  EXPECT_EQ(S_OK, child_iaccessible->get_accRole(SELF, role.Receive()));
  EXPECT_EQ(ROLE_SYSTEM_PUSHBUTTON, V_I4(role.ptr()));

  child.role = ax::mojom::Role::kPopUpButton;
  child_node->SetData(child);
  EXPECT_EQ(S_OK, child_iaccessible->get_accRole(SELF, role.Receive()));
  EXPECT_EQ(ROLE_SYSTEM_BUTTONMENU, V_I4(role.ptr()));

  EXPECT_EQ(E_INVALIDARG, child_iaccessible->get_accRole(SELF, nullptr));
  ScopedVariant bad_id(999);
  EXPECT_EQ(E_INVALIDARG,
            child_iaccessible->get_accRole(bad_id, role.Receive()));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleLocation) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(10, 40, 800, 600);
  Init(root);

  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(100, 200));

  LONG x_left, y_top, width, height;
  EXPECT_EQ(S_OK, GetRootIAccessible()->accLocation(&x_left, &y_top, &width,
                                                    &height, SELF));
  EXPECT_EQ(110, x_left);
  EXPECT_EQ(240, y_top);
  EXPECT_EQ(800, width);
  EXPECT_EQ(600, height);

  EXPECT_EQ(E_INVALIDARG, GetRootIAccessible()->accLocation(
                              nullptr, &y_top, &width, &height, SELF));
  EXPECT_EQ(E_INVALIDARG, GetRootIAccessible()->accLocation(
                              &x_left, nullptr, &width, &height, SELF));
  EXPECT_EQ(E_INVALIDARG, GetRootIAccessible()->accLocation(
                              &x_left, &y_top, nullptr, &height, SELF));
  EXPECT_EQ(E_INVALIDARG, GetRootIAccessible()->accLocation(
                              &x_left, &y_top, &width, nullptr, SELF));
  ScopedVariant bad_id(999);
  EXPECT_EQ(E_INVALIDARG, GetRootIAccessible()->accLocation(
                              &x_left, &y_top, &width, &height, bad_id));

  // Un-set the global offset so that it doesn't affect subsequent tests.
  TestAXNodeWrapper::SetGlobalCoordinateOffset(gfx::Vector2d(0, 0));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleChildAndParent) {
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
  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IAccessible> button_iaccessible(IAccessibleFromNode(button_node));
  ComPtr<IAccessible> checkbox_iaccessible(IAccessibleFromNode(checkbox_node));

  LONG child_count;
  EXPECT_EQ(S_OK, root_iaccessible->get_accChildCount(&child_count));
  EXPECT_EQ(2L, child_count);
  EXPECT_EQ(S_OK, button_iaccessible->get_accChildCount(&child_count));
  EXPECT_EQ(0L, child_count);
  EXPECT_EQ(S_OK, checkbox_iaccessible->get_accChildCount(&child_count));
  EXPECT_EQ(0L, child_count);

  {
    ComPtr<IDispatch> result;
    EXPECT_EQ(S_OK, root_iaccessible->get_accChild(SELF, &result));
    EXPECT_EQ(result.Get(), root_iaccessible.Get());
  }

  {
    ComPtr<IDispatch> result;
    ScopedVariant child1(1);
    EXPECT_EQ(S_OK, root_iaccessible->get_accChild(child1, &result));
    EXPECT_EQ(result.Get(), button_iaccessible.Get());
  }

  {
    ComPtr<IDispatch> result;
    ScopedVariant child2(2);
    EXPECT_EQ(S_OK, root_iaccessible->get_accChild(child2, &result));
    EXPECT_EQ(result.Get(), checkbox_iaccessible.Get());
  }

  {
    // Asking for child id 3 should fail.
    ComPtr<IDispatch> result;
    ScopedVariant child3(3);
    EXPECT_EQ(E_INVALIDARG, root_iaccessible->get_accChild(child3, &result));
  }

  // We should be able to ask for the button by its unique id too.
  LONG button_unique_id;
  ComPtr<IAccessible2> button_iaccessible2 = ToIAccessible2(button_iaccessible);
  button_iaccessible2->get_uniqueID(&button_unique_id);
  ASSERT_LT(button_unique_id, 0);
  {
    ComPtr<IDispatch> result;
    ScopedVariant button_id_variant(button_unique_id);
    EXPECT_EQ(S_OK, root_iaccessible->get_accChild(button_id_variant, &result));
    EXPECT_EQ(result.Get(), button_iaccessible.Get());
  }

  // We shouldn't be able to ask for the root node by its unique ID
  // from one of its children, though.
  LONG root_unique_id;
  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);
  root_iaccessible2->get_uniqueID(&root_unique_id);
  ASSERT_LT(root_unique_id, 0);
  {
    ComPtr<IDispatch> result;
    ScopedVariant root_id_variant(root_unique_id);
    EXPECT_EQ(E_INVALIDARG,
              button_iaccessible->get_accChild(root_id_variant, &result));
  }

  // Now check parents.
  {
    ComPtr<IDispatch> result;
    EXPECT_EQ(S_OK, button_iaccessible->get_accParent(&result));
    EXPECT_EQ(result.Get(), root_iaccessible.Get());
  }

  {
    ComPtr<IDispatch> result;
    EXPECT_EQ(S_OK, checkbox_iaccessible->get_accParent(&result));
    EXPECT_EQ(result.Get(), root_iaccessible.Get());
  }

  {
    ComPtr<IDispatch> result;
    EXPECT_EQ(S_FALSE, root_iaccessible->get_accParent(&result));
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessible2IndexInParent) {
  AXNodeData root;
  root.id = 1;
  root.child_ids.push_back(2);
  root.child_ids.push_back(3);

  AXNodeData left;
  left.id = 2;

  AXNodeData right;
  right.id = 3;

  Init(root, left, right);
  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);
  ComPtr<IAccessible> left_iaccessible(
      IAccessibleFromNode(GetRootAsAXNode()->children()[0]));
  ComPtr<IAccessible2> left_iaccessible2 = ToIAccessible2(left_iaccessible);
  ComPtr<IAccessible> right_iaccessible(
      IAccessibleFromNode(GetRootAsAXNode()->children()[1]));
  ComPtr<IAccessible2> right_iaccessible2 = ToIAccessible2(right_iaccessible);

  LONG index;
  EXPECT_EQ(E_FAIL, root_iaccessible2->get_indexInParent(&index));

  EXPECT_EQ(S_OK, left_iaccessible2->get_indexInParent(&index));
  EXPECT_EQ(0, index);

  EXPECT_EQ(S_OK, right_iaccessible2->get_indexInParent(&index));
  EXPECT_EQ(1, index);
}

TEST_F(AXPlatformNodeWinTest, AccNavigate) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;
  root.child_ids.push_back(2);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kStaticText;
  root.child_ids.push_back(3);

  Init(root, child1, child2);
  ComPtr<IAccessible> ia_root(GetRootIAccessible());
  ComPtr<IDispatch> disp_root;
  ASSERT_HRESULT_SUCCEEDED(ia_root.As(&disp_root));
  ScopedVariant var_root(disp_root.Get());
  ComPtr<IAccessible> ia_child1(
      IAccessibleFromNode(GetRootAsAXNode()->children()[0]));
  ComPtr<IDispatch> disp_child1;
  ASSERT_HRESULT_SUCCEEDED(ia_child1.As(&disp_child1));
  ScopedVariant var_child1(disp_child1.Get());
  ComPtr<IAccessible> ia_child2(
      IAccessibleFromNode(GetRootAsAXNode()->children()[1]));
  ComPtr<IDispatch> disp_child2;
  ASSERT_HRESULT_SUCCEEDED(ia_child2.As(&disp_child2));
  ScopedVariant var_child2(disp_child2.Get());
  ScopedVariant end;

  // Invalid arguments.
  EXPECT_EQ(
      E_INVALIDARG,
      ia_root->accNavigate(NAVDIR_NEXT, ScopedVariant::kEmptyVariant, nullptr));
  EXPECT_EQ(E_INVALIDARG,
            ia_child1->accNavigate(NAVDIR_NEXT, ScopedVariant::kEmptyVariant,
                                   end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());

  // Navigating to first/last child should only be from self.
  EXPECT_EQ(E_INVALIDARG,
            ia_root->accNavigate(NAVDIR_FIRSTCHILD, var_root, end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());
  EXPECT_EQ(E_INVALIDARG,
            ia_root->accNavigate(NAVDIR_LASTCHILD, var_root, end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());

  // Spatial directions are not supported.
  EXPECT_EQ(E_NOTIMPL, ia_child1->accNavigate(NAVDIR_UP, SELF, end.AsInput()));
  EXPECT_EQ(E_NOTIMPL, ia_root->accNavigate(NAVDIR_DOWN, SELF, end.AsInput()));
  EXPECT_EQ(E_NOTIMPL,
            ia_child1->accNavigate(NAVDIR_RIGHT, SELF, end.AsInput()));
  EXPECT_EQ(E_NOTIMPL,
            ia_child2->accNavigate(NAVDIR_LEFT, SELF, end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());

  // Logical directions should be supported.
  EXPECT_EQ(S_OK, ia_root->accNavigate(NAVDIR_FIRSTCHILD, SELF, end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child1.ptr()), V_DISPATCH(end.ptr()));

  EXPECT_EQ(S_OK, ia_root->accNavigate(NAVDIR_LASTCHILD, SELF, end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child2.ptr()), V_DISPATCH(end.ptr()));

  EXPECT_EQ(S_OK, ia_child1->accNavigate(NAVDIR_NEXT, SELF, end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child2.ptr()), V_DISPATCH(end.ptr()));

  EXPECT_EQ(S_OK, ia_child2->accNavigate(NAVDIR_PREVIOUS, SELF, end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child1.ptr()), V_DISPATCH(end.ptr()));

  // Child indices can also be passed by variant.
  // Indices are one-based.
  EXPECT_EQ(S_OK,
            ia_root->accNavigate(NAVDIR_NEXT, ScopedVariant(1), end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child2.ptr()), V_DISPATCH(end.ptr()));

  EXPECT_EQ(S_OK, ia_root->accNavigate(NAVDIR_PREVIOUS, ScopedVariant(2),
                                       end.AsInput()));
  EXPECT_EQ(VT_DISPATCH, end.type());
  EXPECT_EQ(V_DISPATCH(var_child1.ptr()), V_DISPATCH(end.ptr()));

  // Test out-of-bounds.
  EXPECT_EQ(S_FALSE,
            ia_child1->accNavigate(NAVDIR_PREVIOUS, SELF, end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());
  EXPECT_EQ(S_FALSE, ia_child2->accNavigate(NAVDIR_NEXT, SELF, end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());

  EXPECT_EQ(S_FALSE, ia_root->accNavigate(NAVDIR_PREVIOUS, ScopedVariant(1),
                                          end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());
  EXPECT_EQ(S_FALSE,
            ia_root->accNavigate(NAVDIR_NEXT, ScopedVariant(2), end.AsInput()));
  EXPECT_EQ(VT_EMPTY, end.type());
}

TEST_F(AXPlatformNodeWinTest, IAccessible2TextFieldSetSelection) {
  Init(BuildTextField());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  EXPECT_HRESULT_SUCCEEDED(text_field->setSelection(0, 0, 1));
  EXPECT_HRESULT_SUCCEEDED(text_field->setSelection(0, 1, 0));
  EXPECT_HRESULT_SUCCEEDED(text_field->setSelection(0, 2, 2));
  EXPECT_HRESULT_SUCCEEDED(text_field->setSelection(0, IA2_TEXT_OFFSET_CARET,
                                                    IA2_TEXT_OFFSET_LENGTH));

  EXPECT_HRESULT_FAILED(text_field->setSelection(1, 0, 0));
  EXPECT_HRESULT_FAILED(text_field->setSelection(0, 0, 50));
}

// This test is disabled until UpdateStep2ComputeHypertext is migrated over
// to AXPlatformNodeWin because |hypertext_| is only initialized
// on the BrowserAccessibility side.
TEST_F(AXPlatformNodeWinTest,
       DISABLED_IAccessible2ContentEditableSetSelection) {
  Init(BuildContentEditable());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> content_editable;
  ia2_text_field.As(&content_editable);
  ASSERT_NE(nullptr, content_editable.Get());

  EXPECT_HRESULT_SUCCEEDED(content_editable->setSelection(0, 0, 1));
  EXPECT_HRESULT_SUCCEEDED(content_editable->setSelection(0, 1, 0));
  EXPECT_HRESULT_SUCCEEDED(content_editable->setSelection(0, 2, 2));
  EXPECT_HRESULT_SUCCEEDED(content_editable->setSelection(
      0, IA2_TEXT_OFFSET_CARET, IA2_TEXT_OFFSET_LENGTH));

  EXPECT_HRESULT_FAILED(content_editable->setSelection(1, 0, 0));
  EXPECT_HRESULT_FAILED(content_editable->setSelection(0, 0, 50));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetAccessibilityAt) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  ComPtr<IUnknown> cell_1;
  EXPECT_EQ(S_OK, result->get_accessibleAt(1, 1, &cell_1));
  CheckIUnknownHasName(cell_1, L"1");

  ComPtr<IUnknown> cell_2;
  EXPECT_EQ(S_OK, result->get_accessibleAt(1, 2, &cell_2));
  CheckIUnknownHasName(cell_2, L"2");

  ComPtr<IUnknown> cell_3;
  EXPECT_EQ(S_OK, result->get_accessibleAt(2, 1, &cell_3));
  CheckIUnknownHasName(cell_3, L"3");

  ComPtr<IUnknown> cell_4;
  EXPECT_EQ(S_OK, result->get_accessibleAt(2, 2, &cell_4));
  CheckIUnknownHasName(cell_4, L"4");
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetAccessibilityAtOutOfBounds) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(E_INVALIDARG, result->get_accessibleAt(-1, -1, &cell));
  }

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(E_INVALIDARG, result->get_accessibleAt(0, 5, &cell));
  }

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(E_INVALIDARG, result->get_accessibleAt(5, 0, &cell));
  }

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(E_INVALIDARG, result->get_accessibleAt(10, 10, &cell));
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableQueryInterfaceOnNonTable) {
  ComPtr<IAccessibleTable> table;
  ComPtr<IAccessibleTable2> table2;

  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWebArea;
  Init(root);

  ComPtr<IAccessible> root_obj = GetRootIAccessible();
  EXPECT_EQ(E_NOINTERFACE, root_obj->QueryInterface(IID_PPV_ARGS(&table)));
  EXPECT_EQ(E_NOINTERFACE, root_obj->QueryInterface(IID_PPV_ARGS(&table2)));

  AXTreeUpdate update = Build3X3Table();
  update.node_id_to_clear = 1;
  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());
  EXPECT_EQ(E_NOINTERFACE, cell->QueryInterface(IID_PPV_ARGS(&table)));
  EXPECT_EQ(E_NOINTERFACE, cell->QueryInterface(IID_PPV_ARGS(&table2)));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellQueryInterfaceOnNonCell) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj = GetRootIAccessible();
  ComPtr<IAccessibleTableCell> cell;
  EXPECT_EQ(E_NOINTERFACE, root_obj->QueryInterface(IID_PPV_ARGS(&cell)));
}

TEST_F(AXPlatformNodeWinTest, IAccessible2ScrollToPoint) {
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

  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IDispatch> result;
  EXPECT_EQ(S_OK, root_iaccessible->get_accChild(ScopedVariant(1), &result));
  ComPtr<IAccessible2> ax_child1;
  EXPECT_EQ(S_OK, result.As(&ax_child1));
  result.Reset();

  LONG x_left, y_top, width, height;
  EXPECT_EQ(S_OK,
            ax_child1->accLocation(&x_left, &y_top, &width, &height, SELF));
  EXPECT_EQ(10, x_left);
  EXPECT_EQ(10, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);
  EXPECT_EQ(S_OK, root_iaccessible2->scrollToPoint(
                      IA2_COORDTYPE_SCREEN_RELATIVE, 600, 650));

  EXPECT_EQ(S_OK,
            ax_child1->accLocation(&x_left, &y_top, &width, &height, SELF));
  EXPECT_EQ(610, x_left);
  EXPECT_EQ(660, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  EXPECT_EQ(S_OK, root_iaccessible2->scrollToPoint(
                      IA2_COORDTYPE_PARENT_RELATIVE, 0, 0));

  EXPECT_EQ(S_OK,
            ax_child1->accLocation(&x_left, &y_top, &width, &height, SELF));
  EXPECT_EQ(10, x_left);
  EXPECT_EQ(10, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);
}

TEST_F(AXPlatformNodeWinTest, IAccessible2ScrollTo) {
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

  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IDispatch> result;
  EXPECT_EQ(S_OK, root_iaccessible->get_accChild(ScopedVariant(1), &result));
  ComPtr<IAccessible2> ax_child1;
  EXPECT_EQ(S_OK, result.As(&ax_child1));
  result.Reset();

  LONG x_left, y_top, width, height;
  EXPECT_EQ(S_OK,
            ax_child1->accLocation(&x_left, &y_top, &width, &height, SELF));
  EXPECT_EQ(10, x_left);
  EXPECT_EQ(10, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);

  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);
  EXPECT_EQ(S_OK, ax_child1->scrollTo(IA2_SCROLL_TYPE_ANYWHERE));

  EXPECT_EQ(S_OK,
            ax_child1->accLocation(&x_left, &y_top, &width, &height, SELF));
  EXPECT_EQ(0, x_left);
  EXPECT_EQ(0, y_top);
  EXPECT_EQ(10, width);
  EXPECT_EQ(10, height);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetChildIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG id;
  EXPECT_EQ(S_OK, result->get_childIndex(0, 0, &id));
  EXPECT_EQ(id, 0);

  EXPECT_EQ(S_OK, result->get_childIndex(0, 1, &id));
  EXPECT_EQ(id, 1);

  EXPECT_EQ(S_OK, result->get_childIndex(1, 0, &id));
  EXPECT_EQ(id, 3);

  EXPECT_EQ(S_OK, result->get_childIndex(1, 1, &id));
  EXPECT_EQ(id, 4);

  EXPECT_EQ(E_INVALIDARG, result->get_childIndex(-1, -1, &id));
  EXPECT_EQ(E_INVALIDARG, result->get_childIndex(0, 5, &id));
  EXPECT_EQ(E_INVALIDARG, result->get_childIndex(5, 0, &id));
  EXPECT_EQ(E_INVALIDARG, result->get_childIndex(5, 5, &id));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetColumnDescription) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  {
    ScopedBstr name;
    EXPECT_EQ(S_FALSE, result->get_columnDescription(0, name.Receive()));
  }
  {
    ScopedBstr name;
    EXPECT_EQ(S_OK, result->get_columnDescription(1, name.Receive()));
    EXPECT_STREQ(L"column header 1", name.Get());
  }

  {
    ScopedBstr name;
    EXPECT_EQ(S_OK, result->get_columnDescription(2, name.Receive()));
    EXPECT_STREQ(L"column header 2", name.Get());
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetColumnExtentAt) {
  // TODO(dougt) This table doesn't have any spanning cells. This test
  // tests get_columnExtentAt for (1) and an invalid input.
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG columns_spanned;
  EXPECT_EQ(S_OK, result->get_columnExtentAt(1, 1, &columns_spanned));
  EXPECT_EQ(columns_spanned, 1);

  EXPECT_EQ(E_INVALIDARG, result->get_columnExtentAt(-1, -1, &columns_spanned));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetColumnIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG index;
  EXPECT_EQ(S_OK, result->get_columnIndex(2, &index));
  EXPECT_EQ(index, 2);
  EXPECT_EQ(S_OK, result->get_columnIndex(3, &index));
  EXPECT_EQ(index, 0);

  EXPECT_EQ(E_INVALIDARG, result->get_columnIndex(-1, &index));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNColumns) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG count;
  EXPECT_EQ(S_OK, result->get_nColumns(&count));
  EXPECT_EQ(count, 3);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNRows) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG count;
  EXPECT_EQ(S_OK, result->get_nRows(&count));
  EXPECT_EQ(count, 3);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetRowDescription) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  {
    ScopedBstr name;
    EXPECT_EQ(S_FALSE, result->get_rowDescription(0, name.Receive()));
  }

  {
    ScopedBstr name;
    EXPECT_EQ(S_OK, result->get_rowDescription(1, name.Receive()));
    EXPECT_STREQ(L"row header 1", name.Get());
  }

  {
    ScopedBstr name;
    EXPECT_EQ(S_OK, result->get_rowDescription(2, name.Receive()));
    EXPECT_STREQ(L"row header 2", name.Get());
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetRowExtentAt) {
  // TODO(dougt) This table doesn't have any spanning cells. This test
  // tests get_rowExtentAt for (1) and an invalid input.
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG rows_spanned;
  EXPECT_EQ(S_OK, result->get_rowExtentAt(0, 1, &rows_spanned));
  EXPECT_EQ(1, rows_spanned);

  EXPECT_EQ(E_INVALIDARG, result->get_columnExtentAt(-1, -1, &rows_spanned));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetRowIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG index;
  EXPECT_EQ(S_OK, result->get_rowIndex(2, &index));
  EXPECT_EQ(0, index);
  EXPECT_EQ(S_OK, result->get_rowIndex(3, &index));
  EXPECT_EQ(1, index);

  EXPECT_EQ(E_INVALIDARG, result->get_rowIndex(-1, &index));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetRowColumnExtentsAtIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG row, column, row_extents, column_extents;
  BOOLEAN is_selected = false;
  EXPECT_EQ(S_OK,
            result->get_rowColumnExtentsAtIndex(0, &row, &column, &row_extents,
                                                &column_extents, &is_selected));

  EXPECT_EQ(0, row);
  EXPECT_EQ(0, column);
  EXPECT_EQ(1, row_extents);
  EXPECT_EQ(1, column_extents);
  EXPECT_FALSE(is_selected);

  EXPECT_EQ(E_INVALIDARG,
            result->get_rowColumnExtentsAtIndex(-1, &row, &column, &row_extents,
                                                &column_extents, &is_selected));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetCellAt) {
  Init(Build3X3Table());

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  ComPtr<IAccessibleTable2> result;
  root_obj.As(&result);
  ASSERT_NE(nullptr, result.Get());

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(S_OK, result->get_cellAt(1, 1, &cell));
    CheckIUnknownHasName(cell, L"1");
  }

  {
    ComPtr<IUnknown> cell;
    EXPECT_EQ(E_INVALIDARG, result->get_cellAt(-1, -1, &cell));
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetColumnExtent) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  LONG column_spanned;
  EXPECT_EQ(S_OK, cell->get_columnExtent(&column_spanned));
  EXPECT_EQ(1, column_spanned);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetColumnHeaderCells) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  IUnknown** cell_accessibles;

  LONG number_cells;
  EXPECT_EQ(S_OK,
            cell->get_columnHeaderCells(&cell_accessibles, &number_cells));
  EXPECT_EQ(1, number_cells);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetColumnIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  LONG index;
  EXPECT_EQ(S_OK, cell->get_columnIndex(&index));
  EXPECT_EQ(index, 1);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetRowExtent) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  LONG rows_spanned;
  EXPECT_EQ(S_OK, cell->get_rowExtent(&rows_spanned));
  EXPECT_EQ(rows_spanned, 1);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetRowHeaderCells) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  IUnknown** cell_accessibles;

  LONG number_cells;
  EXPECT_EQ(S_OK, cell->get_rowHeaderCells(&cell_accessibles, &number_cells));
  EXPECT_EQ(number_cells, 1);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetRowIndex) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  LONG index;
  EXPECT_EQ(S_OK, cell->get_rowIndex(&index));
  EXPECT_EQ(index, 1);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetRowColumnExtent) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  LONG row, column, row_extents, column_extents;
  BOOLEAN is_selected = false;
  EXPECT_EQ(S_OK, cell->get_rowColumnExtents(&row, &column, &row_extents,
                                             &column_extents, &is_selected));
  EXPECT_EQ(1, row);
  EXPECT_EQ(1, column);
  EXPECT_EQ(1, row_extents);
  EXPECT_EQ(1, column_extents);
  EXPECT_FALSE(is_selected);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableCellGetTable) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  // Check to make sure that this is the right table by checking one cell.
  ComPtr<IUnknown> cell_1;
  EXPECT_EQ(S_OK, result->get_accessibleAt(1, 1, &cell_1));
  CheckIUnknownHasName(cell_1, L"1");
}

TEST_F(AXPlatformNodeWinTest, IAccessible2GetNRelations) {
  // This is is a duplicated of
  // BrowserAccessibilityTest::TestIAccessible2Relations but without the
  // specific COM/BrowserAccessibility knowledge.
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  std::vector<AXNode::AXID> describedby_ids = {1, 2, 3};
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kDescribedbyIds,
                           describedby_ids);

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;

  root.child_ids.push_back(2);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kStaticText;

  root.child_ids.push_back(3);

  Init(root, child1, child2);
  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);

  ComPtr<IDispatch> result;
  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(1), &result));
  ComPtr<IAccessible2> ax_child1;
  EXPECT_EQ(S_OK, result.As(&ax_child1));
  result.Reset();

  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(2), &result));
  ComPtr<IAccessible2> ax_child2;
  EXPECT_EQ(S_OK, result.As(&ax_child2));
  result.Reset();

  LONG n_relations = 0;
  LONG n_targets = 0;
  ScopedBstr relation_type;
  ComPtr<IAccessibleRelation> describedby_relation;
  ComPtr<IAccessibleRelation> description_for_relation;
  ComPtr<IUnknown> target;

  EXPECT_HRESULT_SUCCEEDED(root_iaccessible2->get_nRelations(&n_relations));
  EXPECT_EQ(1, n_relations);

  EXPECT_HRESULT_SUCCEEDED(
      root_iaccessible2->get_relation(0, &describedby_relation));

  EXPECT_HRESULT_SUCCEEDED(
      describedby_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"describedBy", base::string16(relation_type.Get()));

  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(describedby_relation->get_nTargets(&n_targets));
  EXPECT_EQ(2, n_targets);

  EXPECT_HRESULT_SUCCEEDED(describedby_relation->get_target(0, &target));
  target.Reset();

  EXPECT_HRESULT_SUCCEEDED(describedby_relation->get_target(1, &target));
  target.Reset();

  describedby_relation.Reset();

  // Test the reverse relations.
  EXPECT_HRESULT_SUCCEEDED(ax_child1->get_nRelations(&n_relations));
  EXPECT_EQ(1, n_relations);

  EXPECT_HRESULT_SUCCEEDED(
      ax_child1->get_relation(0, &description_for_relation));
  EXPECT_HRESULT_SUCCEEDED(
      description_for_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"descriptionFor", base::string16(relation_type.Get()));
  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(description_for_relation->get_nTargets(&n_targets));
  EXPECT_EQ(1, n_targets);

  EXPECT_HRESULT_SUCCEEDED(description_for_relation->get_target(0, &target));
  target.Reset();
  description_for_relation.Reset();

  EXPECT_HRESULT_SUCCEEDED(ax_child2->get_nRelations(&n_relations));
  EXPECT_EQ(1, n_relations);

  EXPECT_HRESULT_SUCCEEDED(
      ax_child2->get_relation(0, &description_for_relation));
  EXPECT_HRESULT_SUCCEEDED(
      description_for_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"descriptionFor", base::string16(relation_type.Get()));
  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(description_for_relation->get_nTargets(&n_targets));
  EXPECT_EQ(1, n_targets);

  EXPECT_HRESULT_SUCCEEDED(description_for_relation->get_target(0, &target));
  target.Reset();

  // TODO(dougt): Try adding one more relation.
}

TEST_F(AXPlatformNodeWinTest,
       IAccessible2TestPopupForRelationMapsToControlledByRelation) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kTextField;
  child1.AddIntListAttribute(ax::mojom::IntListAttribute::kControlsIds, {3});
  root.child_ids.push_back(2);

  // Add listbox that is popup for the textfield.
  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kListBox;
  child2.AddIntAttribute(ax::mojom::IntAttribute::kPopupForId, 2);
  root.child_ids.push_back(3);

  Init(root, child1, child2);
  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IAccessible2> root_iaccessible2 = ToIAccessible2(root_iaccessible);

  ComPtr<IDispatch> result;
  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(1), &result));
  ComPtr<IAccessible2> ax_child1;
  EXPECT_EQ(S_OK, result.As(&ax_child1));
  result.Reset();

  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(2), &result));
  ComPtr<IAccessible2> ax_child2;
  EXPECT_EQ(S_OK, result.As(&ax_child2));
  result.Reset();

  LONG n_relations = 0;
  LONG n_targets = 0;
  ScopedBstr relation_type;
  ComPtr<IAccessibleRelation> controls_relation;
  ComPtr<IAccessibleRelation> controlled_by_relation;
  ComPtr<IUnknown> target;

  EXPECT_HRESULT_SUCCEEDED(ax_child1->get_nRelations(&n_relations));
  EXPECT_EQ(1, n_relations);

  EXPECT_HRESULT_SUCCEEDED(ax_child1->get_relation(0, &controls_relation));

  EXPECT_HRESULT_SUCCEEDED(
      controls_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"controllerFor", base::string16(relation_type.Get()));

  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(controls_relation->get_nTargets(&n_targets));
  EXPECT_EQ(1, n_targets);

  EXPECT_HRESULT_SUCCEEDED(controls_relation->get_target(0, &target));
  target.Reset();

  controls_relation.Reset();

  // Test the controlled by relation, mapped from the popup for relation.
  EXPECT_HRESULT_SUCCEEDED(ax_child2->get_nRelations(&n_relations));
  // The test is currently outsmarting us, and automatically mapping the
  // reverse relation in addition to mapping the popup for -> controlled by.
  // Therefore, the same relation will exist twice in this test, which
  // actually shows that the popup for -> controlled by relation is working.
  // As a result, both relations should have the same result in this test.
  EXPECT_EQ(2, n_relations);

  // Both relations should have the same result in this test.
  EXPECT_HRESULT_SUCCEEDED(ax_child2->get_relation(0, &controlled_by_relation));
  EXPECT_HRESULT_SUCCEEDED(
      controlled_by_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"controlledBy", base::string16(relation_type.Get()));
  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(controlled_by_relation->get_nTargets(&n_targets));
  EXPECT_EQ(1, n_targets);

  EXPECT_HRESULT_SUCCEEDED(controlled_by_relation->get_target(0, &target));
  target.Reset();
  controlled_by_relation.Reset();

  // Both relations should have the same result in this test.
  EXPECT_HRESULT_SUCCEEDED(ax_child2->get_relation(1, &controlled_by_relation));
  EXPECT_HRESULT_SUCCEEDED(
      controlled_by_relation->get_relationType(relation_type.Receive()));
  EXPECT_EQ(L"controlledBy", base::string16(relation_type.Get()));
  relation_type.Reset();

  EXPECT_HRESULT_SUCCEEDED(controlled_by_relation->get_nTargets(&n_targets));
  EXPECT_EQ(1, n_targets);

  EXPECT_HRESULT_SUCCEEDED(controlled_by_relation->get_target(0, &target));
  target.Reset();
}

TEST_F(AXPlatformNodeWinTest, DISABLED_TestRelationTargetsOfType) {
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
  std::vector<AXNode::AXID> labelledby_ids = {1, 4};
  child2.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                             labelledby_ids);

  root.child_ids.push_back(3);

  AXNodeData child3;
  child3.id = 4;
  child3.role = ax::mojom::Role::kStaticText;
  child3.AddIntListAttribute(ax::mojom::IntListAttribute::kDetailsIds, {2});

  root.child_ids.push_back(4);

  Init(root, child1, child2, child3);
  ComPtr<IAccessible> root_iaccessible(GetRootIAccessible());
  ComPtr<IAccessible2_2> root_iaccessible2 = ToIAccessible2_2(root_iaccessible);

  ComPtr<IDispatch> result;
  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(1), &result));
  ComPtr<IAccessible2_2> ax_child1;
  EXPECT_EQ(S_OK, result.As(&ax_child1));
  result.Reset();

  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(2), &result));
  ComPtr<IAccessible2_2> ax_child2;
  EXPECT_EQ(S_OK, result.As(&ax_child2));
  result.Reset();

  EXPECT_EQ(S_OK, root_iaccessible2->get_accChild(ScopedVariant(3), &result));
  ComPtr<IAccessible2_2> ax_child3;
  EXPECT_EQ(S_OK, result.As(&ax_child3));
  result.Reset();

  {
    ScopedBstr type(L"details");
    IUnknown** targets;
    LONG n_targets;
    EXPECT_EQ(S_OK, root_iaccessible2->get_relationTargetsOfType(
                        type.Get(), 0, &targets, &n_targets));
    ASSERT_EQ(1, n_targets);
    EXPECT_EQ(ax_child1.Get(), targets[0]);
    CoTaskMemFree(targets);
  }

  {
    ScopedBstr type(IA2_RELATION_LABELLED_BY);
    IUnknown** targets;
    LONG n_targets;
    EXPECT_EQ(S_OK, ax_child2->get_relationTargetsOfType(type.Get(), 0,
                                                         &targets, &n_targets));
    ASSERT_EQ(2, n_targets);
    EXPECT_EQ(root_iaccessible2.Get(), targets[0]);
    EXPECT_EQ(ax_child3.Get(), targets[1]);
    CoTaskMemFree(targets);
  }

  {
    ScopedBstr type(L"detailsFor");
    IUnknown** targets;
    LONG n_targets;
    EXPECT_EQ(S_OK, ax_child1->get_relationTargetsOfType(type.Get(), 0,
                                                         &targets, &n_targets));
    ASSERT_EQ(2, n_targets);
    EXPECT_EQ(root_iaccessible2.Get(), targets[0]);
    EXPECT_EQ(ax_child3.Get(), targets[1]);
    CoTaskMemFree(targets);
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedChildrenZero) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedChildren;
  EXPECT_EQ(S_OK, result->get_nSelectedChildren(&selectedChildren));
  EXPECT_EQ(0, selectedChildren);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedChildrenOne) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedChildren;
  EXPECT_EQ(S_OK, result->get_nSelectedChildren(&selectedChildren));
  EXPECT_EQ(1, selectedChildren);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedChildrenMany) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  // 8 == table_cell_2
  // 11 == table_cell_3
  // 12 == table_cell_4
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedChildren;
  EXPECT_EQ(S_OK, result->get_nSelectedChildren(&selectedChildren));
  EXPECT_EQ(4, selectedChildren);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedColumnsZero) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedColumns;
  EXPECT_EQ(S_OK, result->get_nSelectedColumns(&selectedColumns));
  EXPECT_EQ(0, selectedColumns);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedColumnsOne) {
  AXTreeUpdate update = Build3X3Table();

  // 3 == table_column_header_2
  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[3].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedColumns;
  EXPECT_EQ(S_OK, result->get_nSelectedColumns(&selectedColumns));
  EXPECT_EQ(1, selectedColumns);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedColumnsMany) {
  AXTreeUpdate update = Build3X3Table();

  // 3 == table_column_header_2
  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[3].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  // 4 == table_column_header_3
  // 8 == table_cell_2
  // 12 == table_cell_4
  update.nodes[4].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedColumns;
  EXPECT_EQ(S_OK, result->get_nSelectedColumns(&selectedColumns));
  EXPECT_EQ(2, selectedColumns);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedRowsZero) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedRows;
  EXPECT_EQ(S_OK, result->get_nSelectedRows(&selectedRows));
  EXPECT_EQ(0, selectedRows);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedRowsOne) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_1
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedRows;
  EXPECT_EQ(S_OK, result->get_nSelectedRows(&selectedRows));
  EXPECT_EQ(1, selectedRows);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetNSelectedRowsMany) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_3
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  // 10 == table_row_header_3
  // 11 == table_cell_1
  // 12 == table_cell_2
  update.nodes[10].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG selectedRows;
  EXPECT_EQ(S_OK, result->get_nSelectedRows(&selectedRows));
  EXPECT_EQ(2, selectedRows);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedChildren) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  // 12 == table_cell_4
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max = 10;
  LONG* indices;
  LONG count;
  EXPECT_EQ(S_OK, result->get_selectedChildren(max, &indices, &count));
  EXPECT_EQ(2, count);
  EXPECT_EQ(4, indices[0]);
  EXPECT_EQ(8, indices[1]);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedChildrenZeroMax) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  // 12 == table_cell_4
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG* indices;
  LONG count;
  EXPECT_EQ(E_INVALIDARG, result->get_selectedChildren(0, &indices, &count));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedColumnsZero) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_columns = 10;
  LONG* columns;
  LONG n_columns;
  EXPECT_EQ(S_OK,
            result->get_selectedColumns(max_columns, &columns, &n_columns));
  EXPECT_EQ(0, n_columns);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedColumnsOne) {
  AXTreeUpdate update = Build3X3Table();

  // 3 == table_column_header_2
  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[3].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_columns = 10;
  LONG* columns;
  LONG n_columns;
  EXPECT_EQ(S_OK,
            result->get_selectedColumns(max_columns, &columns, &n_columns));
  EXPECT_EQ(1, n_columns);
  EXPECT_EQ(1, columns[0]);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedColumnsMany) {
  AXTreeUpdate update = Build3X3Table();

  // 3 == table_column_header_2
  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[3].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  // 4 == table_column_header_3
  // 8 == table_cell_2
  // 12 == table_cell_4
  update.nodes[4].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_columns = 10;
  LONG* columns;
  LONG n_columns;
  EXPECT_EQ(S_OK,
            result->get_selectedColumns(max_columns, &columns, &n_columns));
  EXPECT_EQ(2, n_columns);
  EXPECT_EQ(1, columns[0]);
  EXPECT_EQ(2, columns[1]);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedRowsZero) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_rows = 10;
  LONG* rows;
  LONG n_rows;
  EXPECT_EQ(S_OK, result->get_selectedRows(max_rows, &rows, &n_rows));
  EXPECT_EQ(0, n_rows);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedRowsOne) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_1
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_rows = 10;
  LONG* rows;
  LONG n_rows;
  EXPECT_EQ(S_OK, result->get_selectedRows(max_rows, &rows, &n_rows));
  EXPECT_EQ(1, n_rows);
  EXPECT_EQ(1, rows[0]);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableGetSelectedRowsMany) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_3
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  // 10 == table_row_header_3
  // 11 == table_cell_1
  // 12 == table_cell_2
  update.nodes[10].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  LONG max_rows = 10;
  LONG* rows;
  LONG n_rows;
  EXPECT_EQ(S_OK, result->get_selectedRows(max_rows, &rows, &n_rows));
  EXPECT_EQ(2, n_rows);
  EXPECT_EQ(1, rows[0]);
  EXPECT_EQ(2, rows[1]);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableIsColumnSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 3 == table_column_header_2
  // 7 == table_cell_1
  // 11 == table_cell_3
  update.nodes[3].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  BOOLEAN selected = false;
  EXPECT_EQ(S_OK, result->get_isColumnSelected(0, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(S_OK, result->get_isColumnSelected(1, &selected));
  EXPECT_TRUE(selected);

  EXPECT_EQ(S_OK, result->get_isColumnSelected(2, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(E_INVALIDARG, result->get_isColumnSelected(3, &selected));
  EXPECT_EQ(E_INVALIDARG, result->get_isColumnSelected(-3, &selected));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableIsRowSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_3
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  BOOLEAN selected;
  EXPECT_EQ(S_OK, result->get_isRowSelected(0, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(S_OK, result->get_isRowSelected(1, &selected));
  EXPECT_TRUE(selected);

  EXPECT_EQ(S_OK, result->get_isRowSelected(2, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(E_INVALIDARG, result->get_isRowSelected(3, &selected));
  EXPECT_EQ(E_INVALIDARG, result->get_isRowSelected(-3, &selected));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTableIsSelected) {
  AXTreeUpdate update = Build3X3Table();

  // 6 == table_row_header_3
  // 7 == table_cell_1
  // 8 == table_cell_2
  update.nodes[6].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[8].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  BOOLEAN selected = false;
  EXPECT_EQ(S_OK, result->get_isSelected(0, 0, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(S_OK, result->get_isSelected(0, 1, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(S_OK, result->get_isSelected(0, 2, &selected));
  EXPECT_FALSE(selected);

  EXPECT_EQ(E_INVALIDARG, result->get_isSelected(0, 4, &selected));

  EXPECT_EQ(S_OK, result->get_isSelected(1, 0, &selected));
  EXPECT_TRUE(selected);

  EXPECT_EQ(S_OK, result->get_isSelected(1, 1, &selected));
  EXPECT_TRUE(selected);

  EXPECT_EQ(S_OK, result->get_isSelected(1, 2, &selected));
  EXPECT_TRUE(selected);

  EXPECT_EQ(E_INVALIDARG, result->get_isSelected(1, 4, &selected));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTable2GetSelectedChildrenZero) {
  Init(Build3X3Table());

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable2> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  IUnknown** cell_accessibles;
  LONG count;
  EXPECT_EQ(S_OK, result->get_selectedCells(&cell_accessibles, &count));
  EXPECT_EQ(0, count);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTable2GetSelectedChildren) {
  AXTreeUpdate update = Build3X3Table();

  // 7 == table_cell_1
  // 12 == table_cell_4
  update.nodes[7].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);

  Init(update);

  ComPtr<IAccessibleTableCell> cell = GetCellInTable();
  ASSERT_NE(nullptr, cell.Get());

  ComPtr<IUnknown> table;
  EXPECT_EQ(S_OK, cell->get_table(&table));

  ComPtr<IAccessibleTable2> result;
  table.As(&result);
  ASSERT_NE(nullptr, result.Get());

  IUnknown** cell_accessibles;
  LONG count;
  EXPECT_EQ(S_OK, result->get_selectedCells(&cell_accessibles, &count));
  EXPECT_EQ(2, count);

  ComPtr<IUnknown> table_cell_1(cell_accessibles[0]);
  CheckIUnknownHasName(table_cell_1, L"1");

  ComPtr<IUnknown> table_cell_4(cell_accessibles[1]);
  CheckIUnknownHasName(table_cell_4, L"4");
}

TEST_F(AXPlatformNodeWinTest, IAccessible2GetGroupPosition) {
  AXNodeData root;
  root.id = 1;
  root.AddIntAttribute(ax::mojom::IntAttribute::kHierarchicalLevel, 1);
  root.AddIntAttribute(ax::mojom::IntAttribute::kSetSize, 1);
  root.AddIntAttribute(ax::mojom::IntAttribute::kPosInSet, 1);
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ComPtr<IAccessible2> iaccessible2 = ToIAccessible2(root_obj);
  LONG level, similar, position;
  EXPECT_EQ(S_OK, iaccessible2->get_groupPosition(&level, &similar, &position));
  EXPECT_EQ(1, level);
  EXPECT_EQ(0, similar);
  EXPECT_EQ(0, position);

  EXPECT_EQ(E_INVALIDARG,
            iaccessible2->get_groupPosition(nullptr, nullptr, nullptr));
}

TEST_F(AXPlatformNodeWinTest, IAccessible2GetLocalizedExtendedRole) {
  AXNodeData root;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kRoleDescription,
                          "extended role");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ComPtr<IAccessible2> iaccessible2 = ToIAccessible2(root_obj);
  ScopedBstr role;
  EXPECT_EQ(S_OK, iaccessible2->get_localizedExtendedRole(role.Receive()));
  EXPECT_STREQ(L"extended role", role.Get());
}

TEST_F(AXPlatformNodeWinTest, UnlabeledImageRoleDescription) {
  AXTreeUpdate tree;
  tree.root_id = 1;
  tree.nodes.resize(3);
  tree.nodes[0].id = 1;
  tree.nodes[0].child_ids = {2, 3};

  tree.nodes[1].id = 2;
  tree.nodes[1].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kEligibleForAnnotation);
  tree.nodes[1].role = ax::mojom::Role::kImage;

  tree.nodes[2].id = 3;
  tree.nodes[2].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kSilentlyEligibleForAnnotation);
  tree.nodes[2].role = ax::mojom::Role::kImage;

  Init(tree);
  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  for (int child_index = 0; child_index < int{tree.nodes[0].child_ids.size()};
       ++child_index) {
    ComPtr<IDispatch> child_dispatch;
    ASSERT_HRESULT_SUCCEEDED(root_obj->get_accChild(
        ScopedVariant(child_index + 1), &child_dispatch));
    ComPtr<IAccessible> child;
    ASSERT_HRESULT_SUCCEEDED(child_dispatch.As(&child));
    ComPtr<IAccessible2> ia2_child = ToIAccessible2(child);

    ScopedBstr role_description;
    ASSERT_EQ(S_OK,
              ia2_child->get_localizedExtendedRole(role_description.Receive()));
    EXPECT_STREQ(L"Unlabeled image", role_description.Get());
  }
}

TEST_F(AXPlatformNodeWinTest, UnlabeledImageAttributes) {
  AXTreeUpdate tree;
  tree.root_id = 1;
  tree.nodes.resize(3);
  tree.nodes[0].id = 1;
  tree.nodes[0].child_ids = {2, 3};

  tree.nodes[1].id = 2;
  tree.nodes[1].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kEligibleForAnnotation);
  tree.nodes[1].role = ax::mojom::Role::kImage;

  tree.nodes[2].id = 3;
  tree.nodes[2].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kSilentlyEligibleForAnnotation);
  tree.nodes[2].role = ax::mojom::Role::kImage;

  Init(tree);
  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  for (int child_index = 0; child_index < int{tree.nodes[0].child_ids.size()};
       ++child_index) {
    ComPtr<IDispatch> child_dispatch;
    ASSERT_HRESULT_SUCCEEDED(root_obj->get_accChild(
        ScopedVariant(child_index + 1), &child_dispatch));
    ComPtr<IAccessible> child;
    ASSERT_HRESULT_SUCCEEDED(child_dispatch.As(&child));
    ComPtr<IAccessible2> ia2_child = ToIAccessible2(child);

    ScopedBstr attributes_bstr;
    ASSERT_EQ(S_OK, ia2_child->get_attributes(attributes_bstr.Receive()));
    base::string16 attributes(attributes_bstr.Get());

    std::vector<base::string16> attribute_vector = base::SplitString(
        attributes, L";", base::KEEP_WHITESPACE, base::SPLIT_WANT_ALL);
    EXPECT_TRUE(
        base::Contains(attribute_vector, L"roledescription:Unlabeled image"));
  }
}

TEST_F(AXPlatformNodeWinTest, AnnotatedImageName) {
  std::vector<const wchar_t*> expected_names;

  AXTreeUpdate tree;
  tree.root_id = 1;
  tree.nodes.resize(11);
  tree.nodes[0].id = 1;
  tree.nodes[0].child_ids = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

  // If the status is EligibleForAnnotation and there's no existing label,
  // the name should be the discoverability string.
  tree.nodes[1].id = 2;
  tree.nodes[1].role = ax::mojom::Role::kImage;
  tree.nodes[1].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[1].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kEligibleForAnnotation);
  expected_names.push_back(
      L"To get missing image descriptions, open the context menu.");

  // If the status is EligibleForAnnotation, the discoverability string
  // should be appended to the existing name.
  tree.nodes[2].id = 3;
  tree.nodes[2].role = ax::mojom::Role::kImage;
  tree.nodes[2].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[2].SetName("ExistingLabel");
  tree.nodes[2].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kEligibleForAnnotation);
  expected_names.push_back(
      L"ExistingLabel. To get missing image descriptions, open the context "
      L"menu.");

  // If the status is SilentlyEligibleForAnnotation, the discoverability string
  // should not be appended to the existing name.
  tree.nodes[3].id = 4;
  tree.nodes[3].role = ax::mojom::Role::kImage;
  tree.nodes[3].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[3].SetName("ExistingLabel");
  tree.nodes[3].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kSilentlyEligibleForAnnotation);
  expected_names.push_back(L"ExistingLabel");

  // If the status is IneligibleForAnnotation, nothing should be appended.
  tree.nodes[4].id = 5;
  tree.nodes[4].role = ax::mojom::Role::kImage;
  tree.nodes[4].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[4].SetName("ExistingLabel");
  tree.nodes[4].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kIneligibleForAnnotation);
  expected_names.push_back(L"ExistingLabel");

  // If the status is AnnotationPending, pending text should be appended
  // to the name.
  tree.nodes[5].id = 6;
  tree.nodes[5].role = ax::mojom::Role::kImage;
  tree.nodes[5].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[5].SetName("ExistingLabel");
  tree.nodes[5].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationPending);
  expected_names.push_back(L"ExistingLabel. Getting description...");

  // If the status is AnnotationSucceeded, and there's no annotation,
  // nothing should be appended. (Ideally this shouldn't happen.)
  tree.nodes[6].id = 7;
  tree.nodes[6].role = ax::mojom::Role::kImage;
  tree.nodes[6].SetName("ExistingLabel");
  tree.nodes[6].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationSucceeded);
  expected_names.push_back(L"ExistingLabel");

  // If the status is AnnotationSucceeded, the annotation should be appended
  // to the existing label.
  tree.nodes[7].id = 8;
  tree.nodes[7].role = ax::mojom::Role::kImage;
  tree.nodes[7].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[7].SetName("ExistingLabel");
  tree.nodes[7].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationSucceeded);
  expected_names.push_back(L"ExistingLabel. Annotation");

  // If the status is AnnotationEmpty, failure text should be added to the
  // name.
  tree.nodes[8].id = 9;
  tree.nodes[8].role = ax::mojom::Role::kImage;
  tree.nodes[8].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[8].SetName("ExistingLabel");
  tree.nodes[8].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationEmpty);
  expected_names.push_back(L"ExistingLabel. No description available.");

  // If the status is AnnotationAdult, appropriate text should be appended
  // to the name.
  tree.nodes[9].id = 10;
  tree.nodes[9].role = ax::mojom::Role::kImage;
  tree.nodes[9].AddStringAttribute(ax::mojom::StringAttribute::kImageAnnotation,
                                   "Annotation");
  tree.nodes[9].SetName("ExistingLabel");
  tree.nodes[9].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationAdult);
  expected_names.push_back(
      L"ExistingLabel. Appears to contain adult content. No description "
      L"available.");

  // If the status is AnnotationProcessFailed, failure text should be added
  // to the name.
  tree.nodes[10].id = 11;
  tree.nodes[10].role = ax::mojom::Role::kImage;
  tree.nodes[10].AddStringAttribute(
      ax::mojom::StringAttribute::kImageAnnotation, "Annotation");
  tree.nodes[10].SetName("ExistingLabel");
  tree.nodes[10].SetImageAnnotationStatus(
      ax::mojom::ImageAnnotationStatus::kAnnotationProcessFailed);
  expected_names.push_back(L"ExistingLabel. No description available.");

  // We should have one expected name per child of the root.
  ASSERT_EQ(expected_names.size(), tree.nodes[0].child_ids.size());
  int child_count = static_cast<int>(expected_names.size());

  Init(tree);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());

  for (int child_index = 0; child_index < child_count; child_index++) {
    ComPtr<IDispatch> child_dispatch;
    ASSERT_HRESULT_SUCCEEDED(root_obj->get_accChild(
        ScopedVariant(child_index + 1), &child_dispatch));
    ComPtr<IAccessible> child;
    ASSERT_HRESULT_SUCCEEDED(child_dispatch.As(&child));

    ScopedBstr name;
    EXPECT_EQ(S_OK, child->get_accName(SELF, name.Receive()));
    EXPECT_STREQ(expected_names[child_index], name.Get());
  }
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextGetNCharacters) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData node;
  node.id = 2;
  node.role = ax::mojom::Role::kStaticText;
  node.SetName("Name");
  root.child_ids.push_back(node.id);

  Init(root, node);

  AXNode* child_node = GetRootAsAXNode()->children()[0];
  ComPtr<IAccessible> child_iaccessible(IAccessibleFromNode(child_node));
  ASSERT_NE(nullptr, child_iaccessible.Get());

  ComPtr<IAccessibleText> text;
  child_iaccessible.As(&text);
  ASSERT_NE(nullptr, text.Get());

  LONG count;
  EXPECT_HRESULT_SUCCEEDED(text->get_nCharacters(&count));
  EXPECT_EQ(4, count);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextGetOffsetAtPoint) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kWebArea;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 300, 200);
  root.child_ids = {2, 3};

  AXNodeData button;
  button.id = 2;
  button.role = ax::mojom::Role::kButton;
  button.SetName("button");
  button.relative_bounds.bounds = gfx::RectF(20, 0, 10, 10);

  AXNodeData static_text1;
  static_text1.id = 3;
  static_text1.role = ax::mojom::Role::kStaticText;
  static_text1.SetName("line 1");
  static_text1.relative_bounds.bounds = gfx::RectF(0, 20, 30, 10);
  static_text1.child_ids = {4};

  AXNodeData inline_box1;
  inline_box1.id = 4;
  inline_box1.role = ax::mojom::Role::kInlineTextBox;
  inline_box1.SetName("line 1");
  inline_box1.relative_bounds.bounds = gfx::RectF(0, 20, 30, 10);
  std::vector<int32_t> character_offsets1;
  // The width of each character is 5px, height is 10px.
  character_offsets1.push_back(5);   // "l" {0, 20, 5x10}
  character_offsets1.push_back(10);  // "i" {5, 20, 5x10}
  character_offsets1.push_back(15);  // "n" {10, 20, 5x10}
  character_offsets1.push_back(20);  // "e" {15, 20, 5x10}
  character_offsets1.push_back(25);  // " " {20, 20, 5x10}
  character_offsets1.push_back(30);  // "1" {25, 20, 5x10}

  inline_box1.AddIntListAttribute(
      ax::mojom::IntListAttribute::kCharacterOffsets, character_offsets1);
  inline_box1.AddIntListAttribute(ax::mojom::IntListAttribute::kWordStarts,
                                  std::vector<int32_t>{0, 5});
  inline_box1.AddIntListAttribute(ax::mojom::IntListAttribute::kWordEnds,
                                  std::vector<int32_t>{4, 6});

  Init(root, button, static_text1, inline_box1);

  LONG offset_result;
  ComPtr<IAccessible> root_iaccessible(IAccessibleFromNode(GetRootAsAXNode()));
  ASSERT_NE(nullptr, root_iaccessible.Get());

  ComPtr<IAccessibleText> root_text;
  root_iaccessible.As(&root_text);
  ASSERT_NE(nullptr, root_text.Get());

  // Test point(0, 0) with coordinate parent relative, which is not supported.
  // Expected result: S_FALSE.
  EXPECT_EQ(S_FALSE, root_text->get_offsetAtPoint(
                         0, 0, IA2CoordinateType::IA2_COORDTYPE_PARENT_RELATIVE,
                         &offset_result));
  EXPECT_EQ(-1, offset_result);

  // Test point(0, 0) retrieved from IAccessibleText of the root web area is
  // outside of any text. Expected result: S_FALSE.
  EXPECT_EQ(S_FALSE, root_text->get_offsetAtPoint(
                         0, 0, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
                         &offset_result));
  EXPECT_EQ(-1, offset_result);

  // Test point(25, 5) retrieved from IAccessibleText of the root web area is
  // on button, and outside of any text. Expected result: S_FALSE.
  EXPECT_EQ(S_FALSE,
            root_text->get_offsetAtPoint(
                25, 5, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
                &offset_result));
  EXPECT_EQ(-1, offset_result);

  // Test point(0, 20) retrieved from IAccessibleText of the root web area is
  // on "line 1", character="l". Expected result: S_OK, offset=0.
  EXPECT_EQ(S_OK, root_text->get_offsetAtPoint(
                      0, 20, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
                      &offset_result));
  EXPECT_EQ(0, offset_result);

  AXNode* static_text1_node = GetRootAsAXNode()->children()[1];
  ComPtr<IAccessible> text1_iaccessible(IAccessibleFromNode(static_text1_node));
  ASSERT_NE(nullptr, text1_iaccessible.Get());

  ComPtr<IAccessibleText> text1;
  text1_iaccessible.As(&text1);
  ASSERT_NE(nullptr, text1.Get());

  // "l" 4 points of bounds {(0, 20), (5, 20), (0, 30), (5, 30)}
  // "i" 4 points of bounds {(5, 20), (10, 20), (5, 30), (10, 30)}
  // "n" 4 points of bounds {(10, 20), (15, 20), (10, 30), (15, 30)}
  // "e" 4 points of bounds {(15, 20), (20, 20), (15, 30), (20, 30)}
  // " " 4 points of bounds {(20, 20), (25, 20), (20, 30), (25, 30)}
  // "1" 4 points of bounds {(25, 20), (30, 20), (25, 30), (30, 30)}

  // Test point(0, 0) outside of any character bounds and text.
  EXPECT_EQ(S_FALSE, text1->get_offsetAtPoint(
                         0, 0, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
                         &offset_result));
  EXPECT_EQ(-1, offset_result);

  // Test point(30, 30) outside of any character bounds but on the text.
  EXPECT_EQ(S_OK, text1->get_offsetAtPoint(
                      30, 30, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
                      &offset_result));
  EXPECT_EQ(-1, offset_result);

  // Test point(0, 20) inside bounds of "l", text offset=0
  // character bounds={(0, 20), (5, 20), (0, 30), (5, 30)}
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      0, 20, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE, &offset_result));
  EXPECT_EQ(0, offset_result);

  // Test point(9, 20) inside bounds of "i", text offset=1
  // character bounds={(5, 20), (10, 20), (5, 30), (10, 30)}
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      9, 20, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE, &offset_result));
  EXPECT_EQ(1, offset_result);

  // Test point(10, 30) inside bounds of "n", text offset=2
  // character bounds={(10, 20), (15, 20), (10, 30), (15, 30)}
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      10, 29, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
      &offset_result));
  EXPECT_EQ(2, offset_result);

  // Test point(19, 29) inside bounds of "e", text offset=3
  // character bounds={(15, 20), (20, 20), (15, 30), (20, 30)
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      19, 29, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
      &offset_result));
  EXPECT_EQ(3, offset_result);

  // Test point(23, 25) inside bounds of " ", text offset=4
  // character bounds={(20, 20), (25, 20), (20, 30), (25, 30)}
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      23, 25, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
      &offset_result));
  EXPECT_EQ(4, offset_result);

  // Test point(25, 20) inside bounds of "1", text offset=5
  // character bounds={(25, 20), (30, 20), (25, 30), (30, 30)}
  EXPECT_HRESULT_SUCCEEDED(text1->get_offsetAtPoint(
      25, 20, IA2CoordinateType::IA2_COORDTYPE_SCREEN_RELATIVE,
      &offset_result));
  EXPECT_EQ(5, offset_result);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldRemoveSelection) {
  Init(BuildTextFieldWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);

  EXPECT_HRESULT_SUCCEEDED(text_field->removeSelection(0));

  // There is no selection, just a caret.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(0, &start_offset, &end_offset));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextContentEditableRemoveSelection) {
  Init(BuildTextFieldWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);

  EXPECT_HRESULT_SUCCEEDED(text_field->removeSelection(0));

  // There is no selection, just a caret.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(0, &start_offset, &end_offset));
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldGetSelected) {
  Init(BuildTextFieldWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;

  // We only care about selection_index of zero, so passing anything but 0 as
  // the first parameter should fail.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(1, &start_offset, &end_offset));

  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldGetSelectedBackward) {
  Init(BuildTextFieldWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleContentEditabledGetSelected) {
  Init(BuildContentEditableWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;

  // We only care about selection_index of zero, so passing anything but 0 as
  // the first parameter should fail.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(1, &start_offset, &end_offset));

  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleContentEditabledGetSelectedBackward) {
  Init(BuildContentEditableWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldAddSelection) {
  Init(BuildTextField());
  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  // There is no selection, just a caret.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(0, &start_offset, &end_offset));

  EXPECT_HRESULT_SUCCEEDED(text_field->addSelection(1, 2));

  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

// This test is disabled until UpdateStep2ComputeHypertext is migrated over
// to AXPlatformNodeWin because |hypertext_| is only initialized
// on the BrowserAccessibility side.
TEST_F(AXPlatformNodeWinTest,
       DISABLED_IAccessibleTextContentEditableAddSelection) {
  Init(BuildContentEditable());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG start_offset, end_offset;
  // There is no selection, just a caret.
  EXPECT_EQ(E_INVALIDARG,
            text_field->get_selection(0, &start_offset, &end_offset));

  EXPECT_HRESULT_SUCCEEDED(text_field->addSelection(1, 2));

  EXPECT_HRESULT_SUCCEEDED(
      text_field->get_selection(0, &start_offset, &end_offset));
  EXPECT_EQ(1, start_offset);
  EXPECT_EQ(2, end_offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldGetNSelectionsZero) {
  Init(BuildTextField());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG selections;
  EXPECT_HRESULT_SUCCEEDED(text_field->get_nSelections(&selections));
  EXPECT_EQ(0, selections);
}

TEST_F(AXPlatformNodeWinTest,
       IAccessibleTextContentEditableGetNSelectionsZero) {
  Init(BuildContentEditable());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG selections;
  EXPECT_HRESULT_SUCCEEDED(text_field->get_nSelections(&selections));
  EXPECT_EQ(0, selections);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextContentEditableGetNSelections) {
  Init(BuildContentEditableWithSelectionRange(1, 2));
  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG selections;
  EXPECT_HRESULT_SUCCEEDED(text_field->get_nSelections(&selections));
  EXPECT_EQ(1, selections);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldGetCaretOffsetNoCaret) {
  Init(BuildTextField());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG offset;
  EXPECT_EQ(S_FALSE, text_field->get_caretOffset(&offset));
  EXPECT_EQ(0, offset);
}

TEST_F(AXPlatformNodeWinTest, IAccessibleTextTextFieldGetCaretOffsetHasCaret) {
  Init(BuildTextFieldWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG offset;
  EXPECT_HRESULT_SUCCEEDED(text_field->get_caretOffset(&offset));
  EXPECT_EQ(2, offset);
}

TEST_F(AXPlatformNodeWinTest,
       IAccessibleTextContextEditableGetCaretOffsetNoCaret) {
  Init(BuildContentEditable());

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG offset;
  EXPECT_EQ(S_FALSE, text_field->get_caretOffset(&offset));
  EXPECT_EQ(0, offset);
}

TEST_F(AXPlatformNodeWinTest,
       IAccessibleTextContentEditableGetCaretOffsetHasCaret) {
  Init(BuildContentEditableWithSelectionRange(1, 2));

  ComPtr<IAccessible2> ia2_text_field = ToIAccessible2(GetRootIAccessible());
  ComPtr<IAccessibleText> text_field;
  ia2_text_field.As(&text_field);
  ASSERT_NE(nullptr, text_field.Get());

  LONG offset;
  EXPECT_HRESULT_SUCCEEDED(text_field->get_caretOffset(&offset));
  EXPECT_EQ(2, offset);
}

TEST_F(AXPlatformNodeWinTest, IGridProviderGetRowCount) {
  Init(BuildAriaColumnAndRowCountGrids());

  // Empty Grid
  ComPtr<IGridProvider> grid1_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[0]);

  // Grid with a cell that defines aria-rowindex (4) and aria-colindex (5)
  ComPtr<IGridProvider> grid2_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[1]);

  // Grid that specifies aria-rowcount (2) and aria-colcount (3)
  ComPtr<IGridProvider> grid3_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[2]);

  // Grid that specifies aria-rowcount and aria-colcount are both (-1)
  ComPtr<IGridProvider> grid4_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[3]);

  int row_count;

  EXPECT_HRESULT_SUCCEEDED(grid1_provider->get_RowCount(&row_count));
  EXPECT_EQ(row_count, 0);

  EXPECT_HRESULT_SUCCEEDED(grid2_provider->get_RowCount(&row_count));
  EXPECT_EQ(row_count, 4);

  EXPECT_HRESULT_SUCCEEDED(grid3_provider->get_RowCount(&row_count));
  EXPECT_EQ(row_count, 2);

  EXPECT_EQ(E_UNEXPECTED, grid4_provider->get_RowCount(&row_count));
}

TEST_F(AXPlatformNodeWinTest, IGridProviderGetColumnCount) {
  Init(BuildAriaColumnAndRowCountGrids());

  // Empty Grid
  ComPtr<IGridProvider> grid1_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[0]);

  // Grid with a cell that defines aria-rowindex (4) and aria-colindex (5)
  ComPtr<IGridProvider> grid2_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[1]);

  // Grid that specifies aria-rowcount (2) and aria-colcount (3)
  ComPtr<IGridProvider> grid3_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[2]);

  // Grid that specifies aria-rowcount and aria-colcount are both (-1)
  ComPtr<IGridProvider> grid4_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()->children()[3]);

  int column_count;

  EXPECT_HRESULT_SUCCEEDED(grid1_provider->get_ColumnCount(&column_count));
  EXPECT_EQ(column_count, 0);

  EXPECT_HRESULT_SUCCEEDED(grid2_provider->get_ColumnCount(&column_count));
  EXPECT_EQ(column_count, 5);

  EXPECT_HRESULT_SUCCEEDED(grid3_provider->get_ColumnCount(&column_count));
  EXPECT_EQ(column_count, 3);

  EXPECT_EQ(E_UNEXPECTED, grid4_provider->get_ColumnCount(&column_count));
}

TEST_F(AXPlatformNodeWinTest, IGridProviderGetItem) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kGrid;
  root.AddIntAttribute(ax::mojom::IntAttribute::kAriaRowCount, 1);
  root.AddIntAttribute(ax::mojom::IntAttribute::kAriaColumnCount, 1);

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData cell1;
  cell1.id = 3;
  cell1.role = ax::mojom::Role::kCell;
  row1.child_ids.push_back(cell1.id);

  Init(root, row1, cell1);

  ComPtr<IGridProvider> root_igridprovider(
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode()));

  ComPtr<IRawElementProviderSimple> cell1_irawelementprovidersimple(
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[0]->children()[0]));

  IRawElementProviderSimple* grid_item = nullptr;
  EXPECT_HRESULT_SUCCEEDED(root_igridprovider->GetItem(0, 0, &grid_item));
  EXPECT_NE(nullptr, grid_item);
  EXPECT_EQ(cell1_irawelementprovidersimple.Get(), grid_item);
}

TEST_F(AXPlatformNodeWinTest, ITableProviderGetColumnHeaders) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData column_header;
  column_header.id = 3;
  column_header.role = ax::mojom::Role::kColumnHeader;
  column_header.SetName(L"column_header");
  row1.child_ids.push_back(column_header.id);

  AXNodeData row_header;
  row_header.id = 4;
  row_header.role = ax::mojom::Role::kRowHeader;
  row_header.SetName(L"row_header");
  row1.child_ids.push_back(row_header.id);

  Init(root, row1, column_header, row_header);

  ComPtr<ITableProvider> root_itableprovider(
      QueryInterfaceFromNode<ITableProvider>(GetRootAsAXNode()));

  base::win::ScopedSafearray safearray;
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->GetColumnHeaders(safearray.Receive()));
  EXPECT_NE(nullptr, safearray.Get());

  std::vector<std::wstring> expected_names = {L"column_header"};
  EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(safearray.Get(), UIA_NamePropertyId,
                                   expected_names);

  // Remove column_header's native event target and verify it's no longer
  // returned.
  TestAXNodeWrapper* column_header_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[0]->children()[0]);
  column_header_wrapper->ResetNativeEventTarget();

  safearray.Release();
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->GetColumnHeaders(safearray.Receive()));
  EXPECT_EQ(nullptr, safearray.Get());
}

TEST_F(AXPlatformNodeWinTest, ITableProviderGetColumnHeadersMultipleHeaders) {
  // Build a table like this:
  //   header_r1c1  | header_r1c2 | header_r1c3
  //    cell_r2c1   | cell_r2c2   | cell_r2c3
  //    cell_r3c1   | header_r3c2 |

  // <table>
  //   <tr aria-label="row1">
  //     <th>header_r1c1</th>
  //     <th>header_r1c2</th>
  //     <th>header_r1c3</th>
  //   </tr>
  //   <tr aria-label="row2">
  //     <td>cell_r2c1</td>
  //     <td>cell_r2c2</td>
  //     <td>cell_r2c3</td>
  //   </tr>
  //   <tr aria-label="row3">
  //     <td>cell_r3c1</td>
  //     <th>header_r3c2</th>
  //   </tr>
  // </table>

  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData row2;
  row2.id = 3;
  row2.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row2.id);

  AXNodeData row3;
  row3.id = 4;
  row3.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row3.id);

  // <tr aria-label="row1">
  //   <th>header_r1c1</th> <th>header_r1c2</th> <th>header_r1c3</th>
  // </tr>
  AXNodeData header_r1c1;
  header_r1c1.id = 5;
  header_r1c1.role = ax::mojom::Role::kColumnHeader;
  header_r1c1.SetName(L"header_r1c1");
  row1.child_ids.push_back(header_r1c1.id);

  AXNodeData header_r1c2;
  header_r1c2.id = 6;
  header_r1c2.role = ax::mojom::Role::kColumnHeader;
  header_r1c2.SetName(L"header_r1c2");
  row1.child_ids.push_back(header_r1c2.id);

  AXNodeData header_r1c3;
  header_r1c3.id = 7;
  header_r1c3.role = ax::mojom::Role::kColumnHeader;
  header_r1c3.SetName(L"header_r1c3");
  row1.child_ids.push_back(header_r1c3.id);

  // <tr aria-label="row2">
  //   <td>cell_r2c1</td> <td>cell_r2c2</td> <td>cell_r2c3</td>
  // </tr>
  AXNodeData cell_r2c1;
  cell_r2c1.id = 8;
  cell_r2c1.role = ax::mojom::Role::kCell;
  cell_r2c1.SetName(L"cell_r2c1");
  row2.child_ids.push_back(cell_r2c1.id);

  AXNodeData cell_r2c2;
  cell_r2c2.id = 9;
  cell_r2c2.role = ax::mojom::Role::kCell;
  cell_r2c2.SetName(L"cell_r2c2");
  row2.child_ids.push_back(cell_r2c2.id);

  AXNodeData cell_r2c3;
  cell_r2c3.id = 10;
  cell_r2c3.role = ax::mojom::Role::kCell;
  cell_r2c3.SetName(L"cell_r2c3");
  row2.child_ids.push_back(cell_r2c3.id);

  // <tr aria-label="row3">
  //   <td>cell_r3c1</td> <th>header_r3c2</th>
  // </tr>
  AXNodeData cell_r3c1;
  cell_r3c1.id = 11;
  cell_r3c1.role = ax::mojom::Role::kCell;
  cell_r3c1.SetName(L"cell_r3c1");
  row3.child_ids.push_back(cell_r3c1.id);

  AXNodeData header_r3c2;
  header_r3c2.id = 12;
  header_r3c2.role = ax::mojom::Role::kColumnHeader;
  header_r3c2.SetName(L"header_r3c2");
  row3.child_ids.push_back(header_r3c2.id);

  Init(root, row1, row2, row3, header_r1c1, header_r1c2, header_r1c3, cell_r2c1,
       cell_r2c2, cell_r2c3, cell_r3c1, header_r3c2);

  ComPtr<ITableProvider> root_itableprovider(
      QueryInterfaceFromNode<ITableProvider>(GetRootAsAXNode()));

  base::win::ScopedSafearray safearray;
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->GetColumnHeaders(safearray.Receive()));
  EXPECT_NE(nullptr, safearray.Get());

  // Validate that we retrieve all column headers of the table and in the order
  // below.
  std::vector<std::wstring> expected_names = {L"header_r1c1", L"header_r1c2",
                                              L"header_r3c2", L"header_r1c3"};
  EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(safearray.Get(), UIA_NamePropertyId,
                                   expected_names);
}

TEST_F(AXPlatformNodeWinTest, ITableProviderGetRowHeaders) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData column_header;
  column_header.id = 3;
  column_header.role = ax::mojom::Role::kColumnHeader;
  column_header.SetName(L"column_header");
  row1.child_ids.push_back(column_header.id);

  AXNodeData row_header;
  row_header.id = 4;
  row_header.role = ax::mojom::Role::kRowHeader;
  row_header.SetName(L"row_header");
  row1.child_ids.push_back(row_header.id);

  Init(root, row1, column_header, row_header);

  ComPtr<ITableProvider> root_itableprovider(
      QueryInterfaceFromNode<ITableProvider>(GetRootAsAXNode()));

  base::win::ScopedSafearray safearray;
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->GetRowHeaders(safearray.Receive()));
  EXPECT_NE(nullptr, safearray.Get());
  std::vector<std::wstring> expected_names = {L"row_header"};
  EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(safearray.Get(), UIA_NamePropertyId,
                                   expected_names);

  // Remove row_header's native event target and verify it's no longer returned.
  TestAXNodeWrapper* row_header_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[0]->children()[1]);
  row_header_wrapper->ResetNativeEventTarget();

  safearray.Release();
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->GetRowHeaders(safearray.Receive()));
  EXPECT_EQ(nullptr, safearray.Get());
}

TEST_F(AXPlatformNodeWinTest, ITableProviderGetRowOrColumnMajor) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  Init(root);

  ComPtr<ITableProvider> root_itableprovider(
      QueryInterfaceFromNode<ITableProvider>(GetRootAsAXNode()));

  RowOrColumnMajor row_or_column_major;
  EXPECT_HRESULT_SUCCEEDED(
      root_itableprovider->get_RowOrColumnMajor(&row_or_column_major));
  EXPECT_EQ(row_or_column_major, RowOrColumnMajor_RowMajor);
}

TEST_F(AXPlatformNodeWinTest, ITableItemProviderGetColumnHeaderItems) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData column_header_1;
  column_header_1.id = 3;
  column_header_1.role = ax::mojom::Role::kColumnHeader;
  column_header_1.SetName(L"column_header_1");
  row1.child_ids.push_back(column_header_1.id);

  AXNodeData column_header_2;
  column_header_2.id = 4;
  column_header_2.role = ax::mojom::Role::kColumnHeader;
  column_header_2.SetName(L"column_header_2");
  row1.child_ids.push_back(column_header_2.id);

  AXNodeData row2;
  row2.id = 5;
  row2.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row2.id);

  AXNodeData cell;
  cell.id = 6;
  cell.role = ax::mojom::Role::kCell;
  row2.child_ids.push_back(cell.id);

  Init(root, row1, column_header_1, column_header_2, row2, cell);

  TestAXNodeWrapper* root_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
  root_wrapper->BuildAllWrappers(GetTree(), GetRootAsAXNode());

  ComPtr<ITableItemProvider> cell_itableitemprovider(
      QueryInterfaceFromNode<ITableItemProvider>(
          GetRootAsAXNode()->children()[1]->children()[0]));

  base::win::ScopedSafearray safearray;
  EXPECT_HRESULT_SUCCEEDED(
      cell_itableitemprovider->GetColumnHeaderItems(safearray.Receive()));
  EXPECT_NE(nullptr, safearray.Get());

  std::vector<std::wstring> expected_names = {L"column_header_1"};
  EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(safearray.Get(), UIA_NamePropertyId,
                                   expected_names);

  // Remove column_header_1's native event target and verify it's no longer
  // returned.
  TestAXNodeWrapper* column_header_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[0]->children()[0]);
  column_header_wrapper->ResetNativeEventTarget();

  safearray.Release();
  EXPECT_HRESULT_SUCCEEDED(
      cell_itableitemprovider->GetColumnHeaderItems(safearray.Receive()));
  EXPECT_EQ(nullptr, safearray.Get());
}

TEST_F(AXPlatformNodeWinTest, ITableItemProviderGetRowHeaderItems) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData row_header_1;
  row_header_1.id = 3;
  row_header_1.role = ax::mojom::Role::kRowHeader;
  row_header_1.SetName(L"row_header_1");
  row1.child_ids.push_back(row_header_1.id);

  AXNodeData cell;
  cell.id = 4;
  cell.role = ax::mojom::Role::kCell;
  row1.child_ids.push_back(cell.id);

  AXNodeData row2;
  row2.id = 5;
  row2.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row2.id);

  AXNodeData row_header_2;
  row_header_2.id = 6;
  row_header_2.role = ax::mojom::Role::kRowHeader;
  row_header_2.SetName(L"row_header_2");
  row2.child_ids.push_back(row_header_2.id);

  Init(root, row1, row_header_1, cell, row2, row_header_2);

  TestAXNodeWrapper* root_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
  root_wrapper->BuildAllWrappers(GetTree(), GetRootAsAXNode());

  ComPtr<ITableItemProvider> cell_itableitemprovider(
      QueryInterfaceFromNode<ITableItemProvider>(
          GetRootAsAXNode()->children()[0]->children()[1]));

  base::win::ScopedSafearray safearray;
  EXPECT_HRESULT_SUCCEEDED(
      cell_itableitemprovider->GetRowHeaderItems(safearray.Receive()));
  EXPECT_NE(nullptr, safearray.Get());
  std::vector<std::wstring> expected_names = {L"row_header_1"};
  EXPECT_UIA_ELEMENT_ARRAY_BSTR_EQ(safearray.Get(), UIA_NamePropertyId,
                                   expected_names);

  // Remove row_header_1's native event target and verify it's no longer
  // returned.
  TestAXNodeWrapper* row_header_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[0]->children()[0]);
  row_header_wrapper->ResetNativeEventTarget();

  safearray.Release();
  EXPECT_HRESULT_SUCCEEDED(
      cell_itableitemprovider->GetRowHeaderItems(safearray.Receive()));
  EXPECT_EQ(nullptr, safearray.Get());
}

TEST_F(AXPlatformNodeWinTest, IA2GetAttribute) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kButton;
  root.AddStringAttribute(ax::mojom::StringAttribute::kRoleDescription,
                          "Potato");
  Init(root);

  ComPtr<IAccessible> root_obj(GetRootIAccessible());
  ComPtr<IAccessible2_2> iaccessible2 = ToIAccessible2_2(root_obj);

  ScopedBstr roledescription(L"roledescription");
  ScopedVariant result;
  ASSERT_EQ(S_OK, iaccessible2->get_attribute(roledescription.Get(),
                                              result.Receive()));
  ScopedBstr expected_bstr(L"Potato");
  ASSERT_EQ(VT_BSTR, result.type());
  EXPECT_STREQ(expected_bstr.Get(), result.ptr()->bstrVal);

  ScopedBstr smoothness(L"smoothness");
  ScopedVariant result2;
  EXPECT_EQ(S_FALSE,
            iaccessible2->get_attribute(smoothness.Get(), result2.Receive()));

  EXPECT_EQ(E_INVALIDARG, iaccessible2->get_attribute(nullptr, nullptr));
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertySimple) {
  AXNodeData root;
  root.role = ax::mojom::Role::kList;
  root.SetName("fake name");
  root.AddStringAttribute(ax::mojom::StringAttribute::kAccessKey, "Ctrl+Q");
  root.AddStringAttribute(ax::mojom::StringAttribute::kLanguage, "en-us");
  root.AddStringAttribute(ax::mojom::StringAttribute::kKeyShortcuts, "Alt+F4");
  root.AddStringAttribute(ax::mojom::StringAttribute::kDescription,
                          "fake description");
  root.AddIntAttribute(ax::mojom::IntAttribute::kSetSize, 2);
  root.AddIntAttribute(ax::mojom::IntAttribute::kInvalidState, 1);
  root.id = 1;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kListItem;
  child1.AddIntAttribute(ax::mojom::IntAttribute::kPosInSet, 1);
  child1.SetName("child1");
  root.child_ids.push_back(child1.id);

  Init(root, child1);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();
  ScopedVariant uia_id;
  EXPECT_UIA_BSTR_EQ(root_node, UIA_AccessKeyPropertyId, L"Ctrl+Q");
  EXPECT_UIA_BSTR_EQ(root_node, UIA_AcceleratorKeyPropertyId, L"Alt+F4");
  ASSERT_HRESULT_SUCCEEDED(root_node->GetPropertyValue(
      UIA_AutomationIdPropertyId, uia_id.Receive()));
  EXPECT_UIA_BSTR_EQ(root_node, UIA_AutomationIdPropertyId,
                     uia_id.ptr()->bstrVal);
  EXPECT_UIA_BSTR_EQ(root_node, UIA_FullDescriptionPropertyId,
                     L"fake description");
  EXPECT_UIA_BSTR_EQ(root_node, UIA_AriaRolePropertyId, L"list");
  EXPECT_UIA_BSTR_EQ(root_node, UIA_AriaPropertiesPropertyId,
                     L"readonly=true;expanded=false;multiline=false;"
                     L"multiselectable=false;required=false;setsize=2");
  constexpr int en_us_lcid = 1033;
  EXPECT_UIA_INT_EQ(root_node, UIA_CulturePropertyId, en_us_lcid);
  EXPECT_UIA_BSTR_EQ(root_node, UIA_NamePropertyId, L"fake name");
  EXPECT_UIA_INT_EQ(root_node, UIA_ControlTypePropertyId,
                    int{UIA_ListControlTypeId});
  EXPECT_UIA_INT_EQ(root_node, UIA_OrientationPropertyId,
                    int{OrientationType_None});
  EXPECT_UIA_INT_EQ(root_node, UIA_SizeOfSetPropertyId, 2);
  EXPECT_UIA_INT_EQ(root_node, UIA_ToggleToggleStatePropertyId,
                    int{ToggleState_Off});
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsPasswordPropertyId, false);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsEnabledPropertyId, true);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_HasKeyboardFocusPropertyId, false);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsRequiredForFormPropertyId, false);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsDataValidForFormPropertyId, true);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsKeyboardFocusablePropertyId, false);
  EXPECT_UIA_BOOL_EQ(root_node, UIA_IsOffscreenPropertyId, false);
  ComPtr<IRawElementProviderSimple> child_node1 =
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[0]);
  EXPECT_UIA_INT_EQ(child_node1, UIA_PositionInSetPropertyId, 1);
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueClickablePoint) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kButton;
  root.relative_bounds.bounds = gfx::RectF(20, 30, 100, 200);
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();

  // The clickable point of a rectangle {20, 30, 100, 200} is the rectangle's
  // center, with coordinates {x: 70, y: 130}.
  std::vector<double> expected_values = {70, 130};
  EXPECT_UIA_DOUBLE_ARRAY_EQ(raw_element_provider_simple,
                             UIA_ClickablePointPropertyId, expected_values);
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValue_Histogram) {
  AXNodeData root;
  root.id = 1;
  Init(root);
  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();

  // Log a known property ID
  {
    base::HistogramTester histogram_tester;
    ScopedVariant property_value;
    root_node->GetPropertyValue(UIA_NamePropertyId, property_value.Receive());
    histogram_tester.ExpectUniqueSample(
        "Accessibility.WinAPIs.GetPropertyValue", UIA_NamePropertyId, 1);
    histogram_tester.ExpectTotalCount(
        "Accessibility.Performance.WinAPIs.UMA_API_GET_PROPERTY_VALUE", 1);
  }

  // Collapse unknown property IDs to zero
  {
    base::HistogramTester histogram_tester;
    ScopedVariant property_value;
    root_node->GetPropertyValue(42, property_value.Receive());
    histogram_tester.ExpectUniqueSample(
        "Accessibility.WinAPIs.GetPropertyValue", 0, 1);
    histogram_tester.ExpectTotalCount(
        "Accessibility.Performance.WinAPIs.UMA_API_GET_PROPERTY_VALUE", 1);
  }
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueIsDialog) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.child_ids = {2, 3};

  AXNodeData alert_dialog;
  alert_dialog.id = 2;
  alert_dialog.role = ax::mojom::Role::kAlertDialog;

  AXNodeData dialog;
  dialog.id = 3;
  dialog.role = ax::mojom::Role::kDialog;

  Init(root, alert_dialog, dialog);

  EXPECT_UIA_BOOL_EQ(GetRootIRawElementProviderSimple(), UIA_IsDialogPropertyId,
                     false);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(0),
                     UIA_IsDialogPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(1),
                     UIA_IsDialogPropertyId, true);
}

TEST_F(AXPlatformNodeWinTest,
       UIAGetPropertyValueIsControlElementIgnoredInvisible) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.child_ids = {2, 3, 4, 5, 6, 7, 8};

  AXNodeData normal_button;
  normal_button.id = 2;
  normal_button.role = ax::mojom::Role::kButton;

  AXNodeData ignored_button;
  ignored_button.id = 3;
  ignored_button.role = ax::mojom::Role::kButton;
  ignored_button.AddState(ax::mojom::State::kIgnored);

  AXNodeData invisible_button;
  invisible_button.id = 4;
  invisible_button.role = ax::mojom::Role::kButton;
  invisible_button.AddState(ax::mojom::State::kInvisible);

  AXNodeData invisible_focusable_button;
  invisible_focusable_button.id = 5;
  invisible_focusable_button.role = ax::mojom::Role::kButton;
  invisible_focusable_button.AddState(ax::mojom::State::kInvisible);
  invisible_focusable_button.AddState(ax::mojom::State::kFocusable);

  AXNodeData focusable_generic_container;
  focusable_generic_container.id = 6;
  focusable_generic_container.role = ax::mojom::Role::kGenericContainer;
  focusable_generic_container.AddState(ax::mojom::State::kFocusable);

  AXNodeData ignored_focusable_generic_container;
  ignored_focusable_generic_container.id = 7;
  ignored_focusable_generic_container.role = ax::mojom::Role::kGenericContainer;
  ignored_focusable_generic_container.AddState(ax::mojom::State::kIgnored);
  focusable_generic_container.AddState(ax::mojom::State::kFocusable);

  AXNodeData invisible_focusable_generic_container;
  invisible_focusable_generic_container.id = 8;
  invisible_focusable_generic_container.role =
      ax::mojom::Role::kGenericContainer;
  invisible_focusable_generic_container.AddState(ax::mojom::State::kInvisible);
  invisible_focusable_generic_container.AddState(ax::mojom::State::kFocusable);

  Init(root, normal_button, ignored_button, invisible_button,
       invisible_focusable_button, focusable_generic_container,
       ignored_focusable_generic_container,
       invisible_focusable_generic_container);

  // Turn on web content mode for the AXTree.
  TestAXNodeWrapper::SetGlobalIsWebContent(true);

  // Normal button (id=2), no invisible or ignored state set. Should be a
  // control element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(0),
                     UIA_IsControlElementPropertyId, true);

  // Button with ignored state (id=3). Should not be a control element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(1),
                     UIA_IsControlElementPropertyId, false);

  // Button with invisible state (id=4). Should not be a control element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(2),
                     UIA_IsControlElementPropertyId, false);

  // Button with invisible state, but focusable (id=5). Should not be a control
  // element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(3),
                     UIA_IsControlElementPropertyId, false);

  // Generic container, focusable (id=6). Should be a control
  // element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(4),
                     UIA_IsControlElementPropertyId, true);

  // Generic container, ignored but focusable (id=7). Should not be a control
  // element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(5),
                     UIA_IsControlElementPropertyId, false);

  // Generic container, invisible and ignored, but focusable (id=8). Should not
  // be a control element.
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromChildIndex(6),
                     UIA_IsControlElementPropertyId, false);
}

TEST_F(AXPlatformNodeWinTest, UIAGetControllerForPropertyId) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.child_ids = {2, 3, 4};

  AXNodeData tab;
  tab.id = 2;
  tab.role = ax::mojom::Role::kTab;
  tab.SetName("tab");
  std::vector<AXNode::AXID> controller_ids = {3, 4};
  tab.AddIntListAttribute(ax::mojom::IntListAttribute::kControlsIds,
                          controller_ids);

  AXNodeData panel1;
  panel1.id = 3;
  panel1.role = ax::mojom::Role::kTabPanel;
  panel1.SetName("panel1");

  AXNodeData panel2;
  panel2.id = 4;
  panel2.role = ax::mojom::Role::kTabPanel;
  panel2.SetName("panel2");

  Init(root, tab, panel1, panel2);
  TestAXNodeWrapper* root_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode());
  root_wrapper->BuildAllWrappers(GetTree(), GetRootAsAXNode());

  ComPtr<IRawElementProviderSimple> tab_node =
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[0]);

  std::vector<std::wstring> expected_names_1 = {L"panel1", L"panel2"};
  EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(
      tab_node, UIA_ControllerForPropertyId, UIA_NamePropertyId,
      expected_names_1);

  // Remove panel1's native event target and verify it's no longer returned.
  TestAXNodeWrapper* panel1_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[1]);
  panel1_wrapper->ResetNativeEventTarget();
  std::vector<std::wstring> expected_names_2 = {L"panel2"};
  EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(
      tab_node, UIA_ControllerForPropertyId, UIA_NamePropertyId,
      expected_names_2);
}

TEST_F(AXPlatformNodeWinTest, UIAGetDescribedByPropertyId) {
  AXNodeData root;
  std::vector<AXNode::AXID> describedby_ids = {2, 3, 4};
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kDescribedbyIds,
                           describedby_ids);
  root.id = 1;
  root.role = ax::mojom::Role::kMarquee;
  root.SetName("root");

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;
  child1.SetName("child1");

  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kStaticText;
  child2.SetName("child2");

  root.child_ids.push_back(child2.id);

  Init(root, child1, child2);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();

  std::vector<std::wstring> expected_names = {L"child1", L"child2"};
  EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(
      root_node, UIA_DescribedByPropertyId, UIA_NamePropertyId, expected_names);
}

TEST_F(AXPlatformNodeWinTest, UIAItemStatusPropertyId) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  row1.AddIntAttribute(ax::mojom::IntAttribute::kSortDirection,
                       static_cast<int>(ax::mojom::SortDirection::kAscending));
  root.child_ids.push_back(row1.id);

  AXNodeData header1;
  header1.id = 3;
  header1.role = ax::mojom::Role::kRowHeader;
  header1.AddIntAttribute(
      ax::mojom::IntAttribute::kSortDirection,
      static_cast<int>(ax::mojom::SortDirection::kAscending));
  row1.child_ids.push_back(header1.id);

  AXNodeData header2;
  header2.id = 4;
  header2.role = ax::mojom::Role::kColumnHeader;
  header2.AddIntAttribute(
      ax::mojom::IntAttribute::kSortDirection,
      static_cast<int>(ax::mojom::SortDirection::kDescending));
  row1.child_ids.push_back(header2.id);

  AXNodeData header3;
  header3.id = 5;
  header3.role = ax::mojom::Role::kColumnHeader;
  header3.AddIntAttribute(ax::mojom::IntAttribute::kSortDirection,
                          static_cast<int>(ax::mojom::SortDirection::kOther));
  row1.child_ids.push_back(header3.id);

  AXNodeData header4;
  header4.id = 6;
  header4.role = ax::mojom::Role::kColumnHeader;
  header4.AddIntAttribute(
      ax::mojom::IntAttribute::kSortDirection,
      static_cast<int>(ax::mojom::SortDirection::kUnsorted));
  row1.child_ids.push_back(header4.id);

  Init(root, row1, header1, header2, header3, header4);

  auto* row_node = GetRootAsAXNode()->children()[0];

  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         row_node->children()[0]),
                     UIA_ItemStatusPropertyId, L"ascending");

  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         row_node->children()[1]),
                     UIA_ItemStatusPropertyId, L"descending");

  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         row_node->children()[2]),
                     UIA_ItemStatusPropertyId, L"other");

  EXPECT_UIA_VALUE_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                          row_node->children()[3]),
                      UIA_ItemStatusPropertyId, ScopedVariant::kEmptyVariant);

  EXPECT_UIA_VALUE_EQ(
      QueryInterfaceFromNode<IRawElementProviderSimple>(row_node),
      UIA_ItemStatusPropertyId, ScopedVariant::kEmptyVariant);
}

TEST_F(AXPlatformNodeWinTest, UIAGetFlowsToPropertyId) {
  AXNodeData root;
  std::vector<AXNode::AXID> flowto_ids = {2, 3, 4};
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kFlowtoIds, flowto_ids);
  root.id = 1;
  root.role = ax::mojom::Role::kMarquee;
  root.SetName("root");

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kStaticText;
  child1.SetName("child1");

  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kStaticText;
  child2.SetName("child2");

  root.child_ids.push_back(child2.id);

  Init(root, child1, child2);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();
  std::vector<std::wstring> expected_names = {L"child1", L"child2"};
  EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(root_node, UIA_FlowsToPropertyId,
                                            UIA_NamePropertyId, expected_names);
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueFlowsFromNone) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("root");

  Init(root);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();

  ScopedVariant property_value;
  EXPECT_HRESULT_SUCCEEDED(root_node->GetPropertyValue(
      UIA_FlowsFromPropertyId, property_value.Receive()));
  EXPECT_EQ(VT_ARRAY | VT_UNKNOWN, property_value.type());
  EXPECT_EQ(nullptr, V_ARRAY(property_value.ptr()));
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueFlowsFromSingle) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("root");
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kFlowtoIds, {2});

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kGenericContainer;
  child1.SetName("child1");
  root.child_ids.push_back(child1.id);

  Init(root, child1);
  ASSERT_NE(nullptr,
            TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode()));

  ComPtr<IRawElementProviderSimple> child_node1 =
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[0]);
  std::vector<std::wstring> expected_names = {L"root"};
  EXPECT_UIA_PROPERTY_ELEMENT_ARRAY_BSTR_EQ(
      child_node1, UIA_FlowsFromPropertyId, UIA_NamePropertyId, expected_names);
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueFlowsFromMultiple) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.SetName("root");
  root.AddIntListAttribute(ax::mojom::IntListAttribute::kFlowtoIds, {2, 3});

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kGenericContainer;
  child1.SetName("child1");
  child1.AddIntListAttribute(ax::mojom::IntListAttribute::kFlowtoIds, {3});
  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kGenericContainer;
  child2.SetName("child2");
  root.child_ids.push_back(child2.id);

  Init(root, child1, child2);
  ASSERT_NE(nullptr,
            TestAXNodeWrapper::GetOrCreate(GetTree(), GetRootAsAXNode()));
  ASSERT_NE(nullptr, TestAXNodeWrapper::GetOrCreate(
                         GetTree(), GetRootAsAXNode()->children()[0]));

  ComPtr<IRawElementProviderSimple> child_node2 =
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[1]);
  std::vector<std::wstring> expected_names_1 = {L"root", L"child1"};
  EXPECT_UIA_PROPERTY_UNORDERED_ELEMENT_ARRAY_BSTR_EQ(
      child_node2, UIA_FlowsFromPropertyId, UIA_NamePropertyId,
      expected_names_1);

  // Remove child1's native event target and verify it's no longer returned.
  TestAXNodeWrapper* child1_wrapper = TestAXNodeWrapper::GetOrCreate(
      GetTree(), GetRootAsAXNode()->children()[0]);
  child1_wrapper->ResetNativeEventTarget();
  std::vector<std::wstring> expected_names_2 = {L"root"};
  EXPECT_UIA_PROPERTY_UNORDERED_ELEMENT_ARRAY_BSTR_EQ(
      child_node2, UIA_FlowsFromPropertyId, UIA_NamePropertyId,
      expected_names_2);
}

TEST_F(AXPlatformNodeWinTest, UIAGetPropertyValueFrameworkId) {
  AXNodeData root_ax_node_data;
  root_ax_node_data.id = 1;
  root_ax_node_data.role = ax::mojom::Role::kRootWebArea;
  Init(root_ax_node_data);

  ComPtr<IRawElementProviderSimple> root_raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  EXPECT_UIA_BSTR_EQ(root_raw_element_provider_simple,
                     UIA_FrameworkIdPropertyId, L"Chrome");
}

TEST_F(AXPlatformNodeWinTest, GetPropertyValue_LabeledByTest) {
  // ++1 root
  // ++++2 kGenericContainer LabeledBy 3
  // ++++++3 kStaticText "Hello"
  // ++++4 kGenericContainer LabeledBy 5
  // ++++++5 kGenericContainer
  // ++++++++6 kStaticText "3.14"
  // ++++7 kAlert LabeledBy 6
  AXNodeData root_1;
  AXNodeData gc_2;
  AXNodeData static_text_3;
  AXNodeData gc_4;
  AXNodeData gc_5;
  AXNodeData static_text_6;
  AXNodeData alert_7;

  root_1.id = 1;
  gc_2.id = 2;
  static_text_3.id = 3;
  gc_4.id = 4;
  gc_5.id = 5;
  static_text_6.id = 6;
  alert_7.id = 7;

  root_1.role = ax::mojom::Role::kRootWebArea;
  root_1.child_ids = {gc_2.id, gc_4.id, alert_7.id};

  gc_2.role = ax::mojom::Role::kGenericContainer;
  gc_2.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                           {static_text_3.id});
  gc_2.child_ids = {static_text_3.id};

  static_text_3.role = ax::mojom::Role::kStaticText;
  static_text_3.SetName("Hello");

  gc_4.role = ax::mojom::Role::kGenericContainer;
  gc_4.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                           {gc_5.id});
  gc_4.child_ids = {gc_5.id};

  gc_5.role = ax::mojom::Role::kGenericContainer;
  gc_5.child_ids = {static_text_6.id};

  static_text_6.role = ax::mojom::Role::kStaticText;
  static_text_6.SetName("3.14");

  alert_7.role = ax::mojom::Role::kAlert;
  alert_7.AddIntListAttribute(ax::mojom::IntListAttribute::kLabelledbyIds,
                              {static_text_6.id});

  Init(root_1, gc_2, static_text_3, gc_4, gc_5, static_text_6, alert_7);

  AXNode* root_node = GetRootAsAXNode();
  AXNode* gc_2_node = root_node->children()[0];
  AXNode* static_text_3_node = gc_2_node->children()[0];
  AXNode* gc_4_node = root_node->children()[1];
  AXNode* static_text_6_node = gc_4_node->children()[0]->children()[0];
  AXNode* alert_7_node = root_node->children()[2];

  // Case 1: |gc_2| is labeled by |static_text_3|.

  ComPtr<IRawElementProviderSimple> gc_2_provider =
      GetIRawElementProviderSimpleFromTree(gc_2_node->tree()->GetAXTreeID(),
                                           gc_2_node->id());
  ScopedVariant property_value;
  EXPECT_EQ(S_OK, gc_2_provider->GetPropertyValue(UIA_LabeledByPropertyId,
                                                  property_value.Receive()));
  ASSERT_EQ(property_value.type(), VT_UNKNOWN);
  ComPtr<IRawElementProviderSimple> static_text_3_provider;
  EXPECT_EQ(S_OK, property_value.ptr()->punkVal->QueryInterface(
                      IID_PPV_ARGS(&static_text_3_provider)));
  EXPECT_UIA_BSTR_EQ(static_text_3_provider, UIA_NamePropertyId, L"Hello");

  // Case 2: |gc_4| is labeled by |gc_5| and should return the first static text
  // child of that node, which is |static_text_6|.

  ComPtr<IRawElementProviderSimple> gc_4_provider =
      GetIRawElementProviderSimpleFromTree(gc_4_node->tree()->GetAXTreeID(),
                                           gc_4_node->id());
  property_value.Reset();
  EXPECT_EQ(S_OK, gc_4_provider->GetPropertyValue(UIA_LabeledByPropertyId,
                                                  property_value.Receive()));
  ASSERT_EQ(property_value.type(), VT_UNKNOWN);
  ComPtr<IRawElementProviderSimple> static_text_6_provider;
  EXPECT_EQ(S_OK, property_value.ptr()->punkVal->QueryInterface(
                      IID_PPV_ARGS(&static_text_6_provider)));
  EXPECT_UIA_BSTR_EQ(static_text_6_provider, UIA_NamePropertyId, L"3.14");

  // Case 3: Some UIA control types always expect an empty value for this
  // property. The role kAlert corresponds to UIA_TextControlTypeId, which
  // always expects an empty value. |alert_7| is marked as labeled by
  // |static_text_6|, but shouldn't expose it to the UIA_LabeledByPropertyId.

  ComPtr<IRawElementProviderSimple> alert_7_provider =
      GetIRawElementProviderSimpleFromTree(alert_7_node->tree()->GetAXTreeID(),
                                           alert_7_node->id());
  property_value.Reset();
  EXPECT_EQ(S_OK, alert_7_provider->GetPropertyValue(UIA_LabeledByPropertyId,
                                                     property_value.Receive()));
  ASSERT_EQ(property_value.type(), VT_EMPTY);

  // Remove the referenced nodes' native event targets and verify it's no longer
  // returned.

  // Case 1.
  TestAXNodeWrapper* static_text_3_node_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), static_text_3_node);
  static_text_3_node_wrapper->ResetNativeEventTarget();

  property_value.Reset();
  EXPECT_EQ(S_OK, gc_2_provider->GetPropertyValue(UIA_LabeledByPropertyId,
                                                  property_value.Receive()));
  EXPECT_EQ(property_value.type(), VT_EMPTY);

  // Case 2.
  TestAXNodeWrapper* static_text_6_node_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), static_text_6_node);
  static_text_6_node_wrapper->ResetNativeEventTarget();

  property_value.Reset();
  EXPECT_EQ(S_OK, gc_4_provider->GetPropertyValue(UIA_LabeledByPropertyId,
                                                  property_value.Receive()));
  EXPECT_EQ(property_value.type(), VT_EMPTY);
}

TEST_F(AXPlatformNodeWinTest, GetPropertyValue_HelpText) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  // Test Placeholder StringAttribute is exposed
  AXNodeData input1;
  input1.id = 2;
  input1.role = ax::mojom::Role::kTextField;
  input1.SetName("name-from-title");
  input1.AddIntAttribute(ax::mojom::IntAttribute::kNameFrom,
                         static_cast<int>(ax::mojom::NameFrom::kTitle));
  input1.AddStringAttribute(ax::mojom::StringAttribute::kPlaceholder,
                            "placeholder");
  root.child_ids.push_back(input1.id);

  // Test NameFrom Title is exposed
  AXNodeData input2;
  input2.id = 3;
  input2.role = ax::mojom::Role::kTextField;
  input2.SetName("name-from-title");
  input2.AddIntAttribute(ax::mojom::IntAttribute::kNameFrom,
                         static_cast<int>(ax::mojom::NameFrom::kTitle));
  root.child_ids.push_back(input2.id);

  // Test NameFrom Placeholder is exposed
  AXNodeData input3;
  input3.id = 4;
  input3.role = ax::mojom::Role::kTextField;
  input3.SetName("name-from-placeholder");
  input3.AddIntAttribute(ax::mojom::IntAttribute::kNameFrom,
                         static_cast<int>(ax::mojom::NameFrom::kPlaceholder));
  root.child_ids.push_back(input3.id);

  // Test Title StringAttribute is exposed
  AXNodeData input4;
  input4.id = 5;
  input4.role = ax::mojom::Role::kTextField;
  input4.SetName("name-from-attribute");
  input4.AddIntAttribute(ax::mojom::IntAttribute::kNameFrom,
                         static_cast<int>(ax::mojom::NameFrom::kAttribute));
  input4.AddStringAttribute(ax::mojom::StringAttribute::kTooltip, "tooltip");
  root.child_ids.push_back(input4.id);

  // Test NameFrom (other), without explicit
  // Title / Placeholder StringAttribute is not exposed
  AXNodeData input5;
  input5.id = 6;
  input5.role = ax::mojom::Role::kTextField;
  input5.SetName("name-from-attribute");
  input5.AddIntAttribute(ax::mojom::IntAttribute::kNameFrom,
                         static_cast<int>(ax::mojom::NameFrom::kAttribute));
  root.child_ids.push_back(input5.id);

  Init(root, input1, input2, input3, input4, input5);

  auto* root_node = GetRootAsAXNode();
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         root_node->children()[0]),
                     UIA_HelpTextPropertyId, L"placeholder");
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         root_node->children()[1]),
                     UIA_HelpTextPropertyId, L"name-from-title");
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         root_node->children()[2]),
                     UIA_HelpTextPropertyId, L"name-from-placeholder");
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         root_node->children()[3]),
                     UIA_HelpTextPropertyId, L"tooltip");
  EXPECT_UIA_VALUE_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                          root_node->children()[4]),
                      UIA_HelpTextPropertyId, ScopedVariant::kEmptyVariant);
}

TEST_F(AXPlatformNodeWinTest, GetPropertyValue_LocalizedControlType) {
  AXNodeData root;
  root.role = ax::mojom::Role::kUnknown;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kRoleDescription,
                          "root role description");

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kSearchBox;
  child1.AddStringAttribute(ax::mojom::StringAttribute::kRoleDescription,
                            "child1 role description");
  root.child_ids.push_back(2);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kSearchBox;
  root.child_ids.push_back(3);

  Init(root, child1, child2);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();
  EXPECT_UIA_BSTR_EQ(root_node, UIA_LocalizedControlTypePropertyId,
                     L"root role description");
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         GetRootAsAXNode()->children()[0]),
                     UIA_LocalizedControlTypePropertyId,
                     L"child1 role description");
  EXPECT_UIA_BSTR_EQ(QueryInterfaceFromNode<IRawElementProviderSimple>(
                         GetRootAsAXNode()->children()[1]),
                     UIA_LocalizedControlTypePropertyId, L"search box");
}

TEST_F(AXPlatformNodeWinTest, GetPropertyValue_IsControlElement) {
  AXTreeUpdate update;
  ui::AXTreeID tree_id = ui::AXTreeID::CreateNewAXTreeID();
  update.tree_data.tree_id = tree_id;
  update.has_tree_data = true;
  update.root_id = 1;
  update.nodes.resize(17);
  update.nodes[0].id = 1;
  update.nodes[0].role = ax::mojom::Role::kRootWebArea;
  update.nodes[0].child_ids = {2,  4,  6,  7,  8,  9,  10,
                               11, 12, 13, 14, 15, 16, 17};
  update.nodes[1].id = 2;
  update.nodes[1].role = ax::mojom::Role::kButton;
  update.nodes[1].child_ids = {3};
  update.nodes[2].id = 3;
  update.nodes[2].role = ax::mojom::Role::kStaticText;
  update.nodes[2].SetName("some text");
  update.nodes[3].id = 4;
  update.nodes[3].role = ax::mojom::Role::kGenericContainer;
  update.nodes[3].child_ids = {5};
  update.nodes[4].id = 5;
  update.nodes[4].role = ax::mojom::Role::kStaticText;
  update.nodes[4].SetName("more text");
  update.nodes[5].id = 6;
  update.nodes[5].role = ax::mojom::Role::kTable;
  update.nodes[6].id = 7;
  update.nodes[6].role = ax::mojom::Role::kList;
  update.nodes[7].id = 8;
  update.nodes[7].role = ax::mojom::Role::kForm;
  update.nodes[8].id = 9;
  update.nodes[8].role = ax::mojom::Role::kImage;
  update.nodes[9].id = 10;
  update.nodes[9].role = ax::mojom::Role::kImage;
  update.nodes[9].SetNameExplicitlyEmpty();
  update.nodes[10].id = 11;
  update.nodes[10].role = ax::mojom::Role::kArticle;
  update.nodes[11].id = 12;
  update.nodes[11].role = ax::mojom::Role::kGenericContainer;
  update.nodes[11].AddBoolAttribute(ax::mojom::BoolAttribute::kHasAriaAttribute,
                                    true);
  update.nodes[12].id = 13;
  update.nodes[12].role = ax::mojom::Role::kGenericContainer;
  update.nodes[12].AddBoolAttribute(ax::mojom::BoolAttribute::kEditableRoot,
                                    true);
  update.nodes[13].id = 14;
  update.nodes[13].role = ax::mojom::Role::kGenericContainer;
  update.nodes[13].SetName("name");
  update.nodes[14].id = 15;
  update.nodes[14].role = ax::mojom::Role::kGenericContainer;
  update.nodes[14].SetDescription("description");
  update.nodes[15].id = 16;
  update.nodes[15].role = ax::mojom::Role::kGenericContainer;
  update.nodes[15].AddState(ax::mojom::State::kFocusable);
  update.nodes[16].id = 17;
  update.nodes[16].role = ax::mojom::Role::kForm;
  update.nodes[16].SetName("name");

  Init(update);
  TestAXNodeWrapper::SetGlobalIsWebContent(true);

  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 2),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 3),
                     UIA_IsControlElementPropertyId, false);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 4),
                     UIA_IsControlElementPropertyId, false);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 5),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 6),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 7),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 8),
                     UIA_IsControlElementPropertyId, false);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 9),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 10),
                     UIA_IsControlElementPropertyId, false);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 11),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 12),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 13),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 14),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 15),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 16),
                     UIA_IsControlElementPropertyId, true);
  EXPECT_UIA_BOOL_EQ(GetIRawElementProviderSimpleFromTree(tree_id, 17),
                     UIA_IsControlElementPropertyId, true);
}

TEST_F(AXPlatformNodeWinTest, UIAGetProviderOptions) {
  AXNodeData root_data;
  Init(root_data);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();

  ProviderOptions provider_options = static_cast<ProviderOptions>(0);
  EXPECT_HRESULT_SUCCEEDED(root_node->get_ProviderOptions(&provider_options));
  EXPECT_EQ(ProviderOptions_ServerSideProvider |
                ProviderOptions_UseComThreading |
                ProviderOptions_RefuseNonClientSupport |
                ProviderOptions_HasNativeIAccessible,
            provider_options);
}

TEST_F(AXPlatformNodeWinTest, UIAGetHostRawElementProvider) {
  AXNodeData root_data;
  Init(root_data);

  ComPtr<IRawElementProviderSimple> root_node =
      GetRootIRawElementProviderSimple();

  ComPtr<IRawElementProviderSimple> host_provider;
  EXPECT_HRESULT_SUCCEEDED(
      root_node->get_HostRawElementProvider(&host_provider));
  EXPECT_EQ(nullptr, host_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, UIAGetBoundingRectangle) {
  AXNodeData root_data;
  root_data.id = 1;
  root_data.relative_bounds.bounds = gfx::RectF(10, 20, 30, 50);
  Init(root_data);

  ComPtr<IRawElementProviderFragment> root_node =
      GetRootIRawElementProviderFragment();

  UiaRect bounding_rectangle;
  EXPECT_HRESULT_SUCCEEDED(
      root_node->get_BoundingRectangle(&bounding_rectangle));
  EXPECT_EQ(10, bounding_rectangle.left);
  EXPECT_EQ(20, bounding_rectangle.top);
  EXPECT_EQ(30, bounding_rectangle.width);
  EXPECT_EQ(50, bounding_rectangle.height);
}

TEST_F(AXPlatformNodeWinTest, UIAGetFragmentRoot) {
  // This test needs to be run on a child node since AXPlatformRootNodeWin
  // overrides the method.
  AXNodeData root_data;
  root_data.id = 1;

  AXNodeData element1_data;
  element1_data.id = 2;
  root_data.child_ids.push_back(element1_data.id);

  Init(root_data, element1_data);
  InitFragmentRoot();

  AXNode* root_node = GetRootAsAXNode();
  AXNode* element1_node = root_node->children()[0];

  ComPtr<IRawElementProviderFragment> element1_provider =
      QueryInterfaceFromNode<IRawElementProviderFragment>(element1_node);
  ComPtr<IRawElementProviderFragmentRoot> expected_fragment_root =
      GetFragmentRoot();

  ComPtr<IRawElementProviderFragmentRoot> actual_fragment_root;
  EXPECT_HRESULT_SUCCEEDED(
      element1_provider->get_FragmentRoot(&actual_fragment_root));
  EXPECT_EQ(expected_fragment_root.Get(), actual_fragment_root.Get());

  // Test the case where the fragment root has gone away.
  ax_fragment_root_.reset();
  actual_fragment_root.Reset();
  EXPECT_UIA_ELEMENTNOTAVAILABLE(
      element1_provider->get_FragmentRoot(&actual_fragment_root));

  // Test the case where the widget has gone away.
  TestAXNodeWrapper* element1_wrapper =
      TestAXNodeWrapper::GetOrCreate(GetTree(), element1_node);
  element1_wrapper->ResetNativeEventTarget();
  EXPECT_UIA_ELEMENTNOTAVAILABLE(
      element1_provider->get_FragmentRoot(&actual_fragment_root));
}

TEST_F(AXPlatformNodeWinTest, UIAGetEmbeddedFragmentRoots) {
  AXNodeData root_data;
  root_data.id = 1;
  Init(root_data);

  ComPtr<IRawElementProviderFragment> root_provider =
      GetRootIRawElementProviderFragment();

  base::win::ScopedSafearray embedded_fragment_roots;
  EXPECT_HRESULT_SUCCEEDED(root_provider->GetEmbeddedFragmentRoots(
      embedded_fragment_roots.Receive()));
  EXPECT_EQ(nullptr, embedded_fragment_roots.Get());
}

TEST_F(AXPlatformNodeWinTest, UIAGetRuntimeId) {
  AXNodeData root_data;
  root_data.id = 1;
  Init(root_data);

  ComPtr<IRawElementProviderFragment> root_provider =
      GetRootIRawElementProviderFragment();

  base::win::ScopedSafearray runtime_id;
  EXPECT_HRESULT_SUCCEEDED(root_provider->GetRuntimeId(runtime_id.Receive()));

  LONG array_lower_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetLBound(runtime_id.Get(), 1, &array_lower_bound));
  EXPECT_EQ(0, array_lower_bound);

  LONG array_upper_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetUBound(runtime_id.Get(), 1, &array_upper_bound));
  EXPECT_EQ(1, array_upper_bound);

  int* array_data;
  EXPECT_HRESULT_SUCCEEDED(::SafeArrayAccessData(
      runtime_id.Get(), reinterpret_cast<void**>(&array_data)));
  EXPECT_EQ(UiaAppendRuntimeId, array_data[0]);
  EXPECT_NE(-1, array_data[1]);

  EXPECT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(runtime_id.Get()));
}

TEST_F(AXPlatformNodeWinTest, UIAIWindowProviderGetIsModalUnset) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<IWindowProvider> window_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_WindowPatternId, &window_provider));
  ASSERT_EQ(nullptr, window_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, UIAIWindowProviderGetIsModalFalse) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kModal, false);
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<IWindowProvider> window_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_WindowPatternId, &window_provider));
  ASSERT_NE(nullptr, window_provider.Get());

  BOOL is_modal;
  EXPECT_HRESULT_SUCCEEDED(window_provider->get_IsModal(&is_modal));
  ASSERT_FALSE(is_modal);
}

TEST_F(AXPlatformNodeWinTest, UIAIWindowProviderGetIsModalTrue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kModal, true);
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<IWindowProvider> window_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_WindowPatternId, &window_provider));
  ASSERT_NE(nullptr, window_provider.Get());

  BOOL is_modal;
  EXPECT_HRESULT_SUCCEEDED(window_provider->get_IsModal(&is_modal));
  ASSERT_TRUE(is_modal);
}

TEST_F(AXPlatformNodeWinTest, UIAIWindowProviderInvalidArgument) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kModal, true);
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<IWindowProvider> window_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_WindowPatternId, &window_provider));
  ASSERT_NE(nullptr, window_provider.Get());

  ASSERT_EQ(E_INVALIDARG, window_provider->WaitForInputIdle(0, nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_CanMaximize(nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_CanMinimize(nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_IsModal(nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_WindowVisualState(nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_WindowInteractionState(nullptr));
  ASSERT_EQ(E_INVALIDARG, window_provider->get_IsTopmost(nullptr));
}

TEST_F(AXPlatformNodeWinTest, UIAIWindowProviderNotSupported) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kModal, true);
  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<IWindowProvider> window_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_WindowPatternId, &window_provider));
  ASSERT_NE(nullptr, window_provider.Get());

  BOOL bool_result;
  WindowVisualState window_visual_state_result;
  WindowInteractionState window_interaction_state_result;

  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->SetVisualState(
                WindowVisualState::WindowVisualState_Normal));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED), window_provider->Close());
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->WaitForInputIdle(0, &bool_result));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->get_CanMaximize(&bool_result));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->get_CanMinimize(&bool_result));
  ASSERT_EQ(
      static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
      window_provider->get_WindowVisualState(&window_visual_state_result));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->get_WindowInteractionState(
                &window_interaction_state_result));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_NOTSUPPORTED),
            window_provider->get_IsTopmost(&bool_result));
}

TEST_F(AXPlatformNodeWinTest, UIANavigate) {
  AXNodeData root_data;
  root_data.id = 1;

  AXNodeData element1_data;
  element1_data.id = 2;
  root_data.child_ids.push_back(element1_data.id);

  AXNodeData element2_data;
  element2_data.id = 3;
  root_data.child_ids.push_back(element2_data.id);

  AXNodeData element3_data;
  element3_data.id = 4;
  element1_data.child_ids.push_back(element3_data.id);

  Init(root_data, element1_data, element2_data, element3_data);

  AXNode* root_node = GetRootAsAXNode();
  AXNode* element1_node = root_node->children()[0];
  AXNode* element2_node = root_node->children()[1];
  AXNode* element3_node = element1_node->children()[0];

  auto TestNavigate = [this](AXNode* element_node, AXNode* parent,
                             AXNode* next_sibling, AXNode* prev_sibling,
                             AXNode* first_child, AXNode* last_child) {
    ComPtr<IRawElementProviderFragment> element_provider =
        QueryInterfaceFromNode<IRawElementProviderFragment>(element_node);

    auto TestNavigateSingle = [&](NavigateDirection direction,
                                  AXNode* expected_node) {
      ComPtr<IRawElementProviderFragment> expected_provider =
          QueryInterfaceFromNode<IRawElementProviderFragment>(expected_node);

      ComPtr<IRawElementProviderFragment> navigated_to_fragment;
      EXPECT_HRESULT_SUCCEEDED(
          element_provider->Navigate(direction, &navigated_to_fragment));
      EXPECT_EQ(expected_provider.Get(), navigated_to_fragment.Get());
    };

    TestNavigateSingle(NavigateDirection_Parent, parent);
    TestNavigateSingle(NavigateDirection_NextSibling, next_sibling);
    TestNavigateSingle(NavigateDirection_PreviousSibling, prev_sibling);
    TestNavigateSingle(NavigateDirection_FirstChild, first_child);
    TestNavigateSingle(NavigateDirection_LastChild, last_child);
  };

  TestNavigate(root_node,
               nullptr,         // Parent
               nullptr,         // NextSibling
               nullptr,         // PreviousSibling
               element1_node,   // FirstChild
               element2_node);  // LastChild

  TestNavigate(element1_node, root_node, element2_node, nullptr, element3_node,
               element3_node);

  TestNavigate(element2_node, root_node, nullptr, element1_node, nullptr,
               nullptr);

  TestNavigate(element3_node, element1_node, nullptr, nullptr, nullptr,
               nullptr);
}

TEST_F(AXPlatformNodeWinTest, ISelectionProviderCanSelectMultipleDefault) {
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ false,
                    /*option_3_is_selected*/ false, {}));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));

  BOOL multiple = TRUE;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->get_CanSelectMultiple(&multiple));
  EXPECT_FALSE(multiple);
}

TEST_F(AXPlatformNodeWinTest, ISelectionProviderCanSelectMultipleTrue) {
  const std::vector<ax::mojom::State> state = {
      ax::mojom::State::kMultiselectable, ax::mojom::State::kFocusable};
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ false,
                    /*option_3_is_selected*/ false,
                    /*additional_state*/ state));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));

  BOOL multiple = FALSE;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->get_CanSelectMultiple(&multiple));
  EXPECT_TRUE(multiple);
}

TEST_F(AXPlatformNodeWinTest, ISelectionProviderIsSelectionRequiredDefault) {
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ false,
                    /*option_3_is_selected*/ false,
                    /*additional_state*/ {}));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));

  BOOL selection_required = TRUE;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->get_IsSelectionRequired(&selection_required));
  EXPECT_FALSE(selection_required);
}

TEST_F(AXPlatformNodeWinTest, ISelectionProviderIsSelectionRequiredTrue) {
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ false,
                    /*option_3_is_selected*/ false,
                    /*additional_state*/ {ax::mojom::State::kRequired}));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));

  BOOL selection_required = FALSE;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->get_IsSelectionRequired(&selection_required));
  EXPECT_TRUE(selection_required);
}

TEST_F(AXPlatformNodeWinTest, ISelectionProviderGetSelectionNoneSelected) {
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ false,
                    /*option_3_is_selected*/ false,
                    /*additional_state*/ {ax::mojom::State::kFocusable}));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));

  base::win::ScopedSafearray selected_items;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->GetSelection(selected_items.Receive()));
  EXPECT_NE(nullptr, selected_items.Get());

  LONG array_lower_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetLBound(selected_items.Get(), 1, &array_lower_bound));
  EXPECT_EQ(0, array_lower_bound);

  LONG array_upper_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetUBound(selected_items.Get(), 1, &array_upper_bound));
  EXPECT_EQ(-1, array_upper_bound);
}

TEST_F(AXPlatformNodeWinTest,
       ISelectionProviderGetSelectionSingleItemSelected) {
  Init(BuildListBox(/*option_1_is_selected*/ false,
                    /*option_2_is_selected*/ true,
                    /*option_3_is_selected*/ false,
                    /*additional_state*/ {ax::mojom::State::kFocusable}));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));
  ComPtr<IRawElementProviderSimple> option2_provider(
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[1]));

  base::win::ScopedSafearray selected_items;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->GetSelection(selected_items.Receive()));
  EXPECT_NE(nullptr, selected_items.Get());

  LONG array_lower_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetLBound(selected_items.Get(), 1, &array_lower_bound));
  EXPECT_EQ(0, array_lower_bound);

  LONG array_upper_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetUBound(selected_items.Get(), 1, &array_upper_bound));
  EXPECT_EQ(0, array_upper_bound);

  IRawElementProviderSimple** array_data;
  EXPECT_HRESULT_SUCCEEDED(::SafeArrayAccessData(
      selected_items.Get(), reinterpret_cast<void**>(&array_data)));
  EXPECT_EQ(option2_provider.Get(), array_data[0]);
  EXPECT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(selected_items.Get()));
}

TEST_F(AXPlatformNodeWinTest,
       ISelectionProviderGetSelectionMultipleItemsSelected) {
  const std::vector<ax::mojom::State> state = {
      ax::mojom::State::kMultiselectable, ax::mojom::State::kFocusable};
  Init(BuildListBox(/*option_1_is_selected*/ true,
                    /*option_2_is_selected*/ true,
                    /*option_3_is_selected*/ true,
                    /*additional_state*/ state));

  ComPtr<ISelectionProvider> selection_provider(
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode()));
  ComPtr<IRawElementProviderSimple> option1_provider(
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[0]));
  ComPtr<IRawElementProviderSimple> option2_provider(
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[1]));
  ComPtr<IRawElementProviderSimple> option3_provider(
      QueryInterfaceFromNode<IRawElementProviderSimple>(
          GetRootAsAXNode()->children()[2]));

  base::win::ScopedSafearray selected_items;
  EXPECT_HRESULT_SUCCEEDED(
      selection_provider->GetSelection(selected_items.Receive()));
  EXPECT_NE(nullptr, selected_items.Get());

  LONG array_lower_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetLBound(selected_items.Get(), 1, &array_lower_bound));
  EXPECT_EQ(0, array_lower_bound);

  LONG array_upper_bound;
  EXPECT_HRESULT_SUCCEEDED(
      ::SafeArrayGetUBound(selected_items.Get(), 1, &array_upper_bound));
  EXPECT_EQ(2, array_upper_bound);

  IRawElementProviderSimple** array_data;
  EXPECT_HRESULT_SUCCEEDED(::SafeArrayAccessData(
      selected_items.Get(), reinterpret_cast<void**>(&array_data)));
  EXPECT_EQ(option1_provider.Get(), array_data[0]);
  EXPECT_EQ(option2_provider.Get(), array_data[1]);
  EXPECT_EQ(option3_provider.Get(), array_data[2]);

  EXPECT_HRESULT_SUCCEEDED(::SafeArrayUnaccessData(selected_items.Get()));
}

TEST_F(AXPlatformNodeWinTest, ComputeUIAControlType) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  AXNode::AXID child1_id = 2;
  child1.id = child1_id;
  child1.role = ax::mojom::Role::kTable;
  root.child_ids.push_back(child1_id);

  AXNodeData child2;
  AXNode::AXID child2_id = 3;
  child2.id = child2_id;
  child2.role = ax::mojom::Role::kLayoutTable;
  root.child_ids.push_back(child2_id);

  AXNodeData child3;
  AXNode::AXID child3_id = 4;
  child3.id = child3_id;
  child3.role = ax::mojom::Role::kTextField;
  root.child_ids.push_back(child3_id);

  AXNodeData child4;
  AXNode::AXID child4_id = 5;
  child4.id = child4_id;
  child4.role = ax::mojom::Role::kSearchBox;
  root.child_ids.push_back(child4_id);

  Init(root, child1, child2, child3, child4);

  EXPECT_UIA_INT_EQ(
      QueryInterfaceFromNodeId<IRawElementProviderSimple>(child1_id),
      UIA_ControlTypePropertyId, int{UIA_TableControlTypeId});
  EXPECT_UIA_INT_EQ(
      QueryInterfaceFromNodeId<IRawElementProviderSimple>(child2_id),
      UIA_ControlTypePropertyId, int{UIA_TableControlTypeId});
  EXPECT_UIA_INT_EQ(
      QueryInterfaceFromNodeId<IRawElementProviderSimple>(child3_id),
      UIA_ControlTypePropertyId, int{UIA_EditControlTypeId});
  EXPECT_UIA_INT_EQ(
      QueryInterfaceFromNodeId<IRawElementProviderSimple>(child4_id),
      UIA_ControlTypePropertyId, int{UIA_EditControlTypeId});
}

TEST_F(AXPlatformNodeWinTest, UIALandmarkType) {
  auto TestLandmarkType = [this](ax::mojom::Role node_role,
                                 base::Optional<LONG> expected_landmark_type,
                                 const std::string& node_name = {}) {
    AXNodeData root_data;
    root_data.id = 1;
    root_data.role = node_role;
    if (!node_name.empty())
      root_data.SetName(node_name);
    Init(root_data);

    ComPtr<IRawElementProviderSimple> root_provider =
        GetRootIRawElementProviderSimple();

    if (expected_landmark_type) {
      EXPECT_UIA_INT_EQ(root_provider, UIA_LandmarkTypePropertyId,
                        expected_landmark_type.value());
    } else {
      EXPECT_UIA_EMPTY(root_provider, UIA_LandmarkTypePropertyId);
    }
  };

  TestLandmarkType(ax::mojom::Role::kBanner, UIA_CustomLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kComplementary, UIA_CustomLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kContentInfo, UIA_CustomLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kFooter, UIA_CustomLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kMain, UIA_MainLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kNavigation, UIA_NavigationLandmarkTypeId);
  TestLandmarkType(ax::mojom::Role::kSearch, UIA_SearchLandmarkTypeId);

  // Only named forms should be exposed as landmarks.
  TestLandmarkType(ax::mojom::Role::kForm, {});
  TestLandmarkType(ax::mojom::Role::kForm, UIA_FormLandmarkTypeId, "name");

  // Only named regions should be exposed as landmarks.
  TestLandmarkType(ax::mojom::Role::kRegion, {});
  TestLandmarkType(ax::mojom::Role::kRegion, UIA_CustomLandmarkTypeId, "name");

  TestLandmarkType(ax::mojom::Role::kGroup, {});
  TestLandmarkType(ax::mojom::Role::kHeading, {});
  TestLandmarkType(ax::mojom::Role::kList, {});
  TestLandmarkType(ax::mojom::Role::kTable, {});
}

TEST_F(AXPlatformNodeWinTest, UIALocalizedLandmarkType) {
  auto TestLocalizedLandmarkType =
      [this](ax::mojom::Role node_role,
             const std::wstring& expected_localized_landmark,
             const std::string& node_name = {}) {
        AXNodeData root_data;
        root_data.id = 1;
        root_data.role = node_role;
        if (!node_name.empty())
          root_data.SetName(node_name);
        Init(root_data);

        ComPtr<IRawElementProviderSimple> root_provider =
            GetRootIRawElementProviderSimple();

        if (expected_localized_landmark.empty()) {
          EXPECT_UIA_EMPTY(root_provider, UIA_LocalizedLandmarkTypePropertyId);
        } else {
          EXPECT_UIA_BSTR_EQ(root_provider, UIA_LocalizedLandmarkTypePropertyId,
                             expected_localized_landmark.c_str());
        }
      };

  TestLocalizedLandmarkType(ax::mojom::Role::kBanner, L"banner");
  TestLocalizedLandmarkType(ax::mojom::Role::kComplementary, L"complementary");
  TestLocalizedLandmarkType(ax::mojom::Role::kContentInfo,
                            L"content information");
  TestLocalizedLandmarkType(ax::mojom::Role::kFooter, L"content information");

  // Only named regions should be exposed as landmarks.
  TestLocalizedLandmarkType(ax::mojom::Role::kRegion, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kRegion, L"region", "name");

  TestLocalizedLandmarkType(ax::mojom::Role::kForm, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kGroup, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kHeading, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kList, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kMain, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kNavigation, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kSearch, {});
  TestLocalizedLandmarkType(ax::mojom::Role::kTable, {});
}

TEST_F(AXPlatformNodeWinTest, IRawElementProviderSimple2ShowContextMenu) {
  AXNodeData root_data;
  root_data.id = 1;

  AXNodeData element1_data;
  element1_data.id = 2;
  root_data.child_ids.push_back(element1_data.id);

  AXNodeData element2_data;
  element2_data.id = 3;
  root_data.child_ids.push_back(element2_data.id);

  Init(root_data, element1_data, element2_data);

  AXNode* root_node = GetRootAsAXNode();
  AXNode* element1_node = root_node->children()[0];
  AXNode* element2_node = root_node->children()[1];

  ComPtr<IRawElementProviderSimple2> root_provider =
      QueryInterfaceFromNode<IRawElementProviderSimple2>(root_node);
  ComPtr<IRawElementProviderSimple2> element1_provider =
      QueryInterfaceFromNode<IRawElementProviderSimple2>(element1_node);
  ComPtr<IRawElementProviderSimple2> element2_provider =
      QueryInterfaceFromNode<IRawElementProviderSimple2>(element2_node);

  EXPECT_HRESULT_SUCCEEDED(element1_provider->ShowContextMenu());
  EXPECT_EQ(element1_node, TestAXNodeWrapper::GetNodeFromLastShowContextMenu());
  EXPECT_HRESULT_SUCCEEDED(element2_provider->ShowContextMenu());
  EXPECT_EQ(element2_node, TestAXNodeWrapper::GetNodeFromLastShowContextMenu());
  EXPECT_HRESULT_SUCCEEDED(root_provider->ShowContextMenu());
  EXPECT_EQ(root_node, TestAXNodeWrapper::GetNodeFromLastShowContextMenu());
}

TEST_F(AXPlatformNodeWinTest, UIAErrorHandling) {
  AXNodeData root;
  Init(root);

  ComPtr<IRawElementProviderSimple> simple_provider =
      GetRootIRawElementProviderSimple();
  ComPtr<IRawElementProviderSimple2> simple2_provider =
      QueryInterfaceFromNode<IRawElementProviderSimple2>(GetRootAsAXNode());
  ComPtr<IRawElementProviderFragment> fragment_provider =
      GetRootIRawElementProviderFragment();
  ComPtr<IGridItemProvider> grid_item_provider =
      QueryInterfaceFromNode<IGridItemProvider>(GetRootAsAXNode());
  ComPtr<IGridProvider> grid_provider =
      QueryInterfaceFromNode<IGridProvider>(GetRootAsAXNode());
  ComPtr<IScrollItemProvider> scroll_item_provider =
      QueryInterfaceFromNode<IScrollItemProvider>(GetRootAsAXNode());
  ComPtr<IScrollProvider> scroll_provider =
      QueryInterfaceFromNode<IScrollProvider>(GetRootAsAXNode());
  ComPtr<ISelectionItemProvider> selection_item_provider =
      QueryInterfaceFromNode<ISelectionItemProvider>(GetRootAsAXNode());
  ComPtr<ISelectionProvider> selection_provider =
      QueryInterfaceFromNode<ISelectionProvider>(GetRootAsAXNode());
  ComPtr<ITableItemProvider> table_item_provider =
      QueryInterfaceFromNode<ITableItemProvider>(GetRootAsAXNode());
  ComPtr<ITableProvider> table_provider =
      QueryInterfaceFromNode<ITableProvider>(GetRootAsAXNode());
  ComPtr<IExpandCollapseProvider> expand_collapse_provider =
      QueryInterfaceFromNode<IExpandCollapseProvider>(GetRootAsAXNode());
  ComPtr<IToggleProvider> toggle_provider =
      QueryInterfaceFromNode<IToggleProvider>(GetRootAsAXNode());
  ComPtr<IValueProvider> value_provider =
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode());
  ComPtr<IRangeValueProvider> range_value_provider =
      QueryInterfaceFromNode<IRangeValueProvider>(GetRootAsAXNode());
  ComPtr<IWindowProvider> window_provider =
      QueryInterfaceFromNode<IWindowProvider>(GetRootAsAXNode());

  // Create an empty tree.
  SetTree(std::make_unique<AXTree>());

  // IGridItemProvider
  int int_result = 0;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_item_provider->get_Column(&int_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_item_provider->get_ColumnSpan(&int_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_item_provider->get_Row(&int_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_item_provider->get_RowSpan(&int_result));

  // IExpandCollapseProvider
  ExpandCollapseState expand_collapse_state;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            expand_collapse_provider->Collapse());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            expand_collapse_provider->Expand());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            expand_collapse_provider->get_ExpandCollapseState(
                &expand_collapse_state));

  // IGridProvider
  ComPtr<IRawElementProviderSimple> temp_simple_provider;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_provider->GetItem(0, 0, &temp_simple_provider));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_provider->get_RowCount(&int_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            grid_provider->get_ColumnCount(&int_result));

  // IScrollItemProvider
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_item_provider->ScrollIntoView());

  // IScrollProvider
  BOOL bool_result = TRUE;
  double double_result = 3.14;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->SetScrollPercent(0, 0));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_HorizontallyScrollable(&bool_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_HorizontalScrollPercent(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_HorizontalViewSize(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_VerticallyScrollable(&bool_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_VerticalScrollPercent(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            scroll_provider->get_VerticalViewSize(&double_result));

  // ISelectionItemProvider
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_item_provider->AddToSelection());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_item_provider->RemoveFromSelection());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_item_provider->Select());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_item_provider->get_IsSelected(&bool_result));
  EXPECT_EQ(
      static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
      selection_item_provider->get_SelectionContainer(&temp_simple_provider));

  // ISelectionProvider
  base::win::ScopedSafearray array_result;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_provider->GetSelection(array_result.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_provider->get_CanSelectMultiple(&bool_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            selection_provider->get_IsSelectionRequired(&bool_result));

  // ITableItemProvider
  RowOrColumnMajor row_or_column_major_result;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            table_item_provider->GetColumnHeaderItems(array_result.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            table_item_provider->GetRowHeaderItems(array_result.Receive()));

  // ITableProvider
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            table_provider->GetColumnHeaders(array_result.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            table_provider->GetRowHeaders(array_result.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            table_provider->get_RowOrColumnMajor(&row_or_column_major_result));

  // IRawElementProviderSimple
  ScopedVariant variant;
  ComPtr<IUnknown> unknown;
  ComPtr<IRawElementProviderSimple> host_provider;
  ProviderOptions options;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            simple_provider->GetPatternProvider(UIA_WindowPatternId, &unknown));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            simple_provider->GetPropertyValue(UIA_FrameworkIdPropertyId,
                                              variant.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            simple_provider->get_ProviderOptions(&options));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            simple_provider->get_HostRawElementProvider(&host_provider));

  // IRawElementProviderSimple2
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            simple2_provider->ShowContextMenu());

  // IRawElementProviderFragment
  ComPtr<IRawElementProviderFragment> navigated_to_fragment;
  base::win::ScopedSafearray safearray;
  UiaRect bounding_rectangle;
  ComPtr<IRawElementProviderFragmentRoot> fragment_root;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->Navigate(NavigateDirection_Parent,
                                        &navigated_to_fragment));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->GetRuntimeId(safearray.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->get_BoundingRectangle(&bounding_rectangle));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->GetEmbeddedFragmentRoots(safearray.Receive()));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->get_FragmentRoot(&fragment_root));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            fragment_provider->SetFocus());

  // IValueProvider
  ScopedBstr bstr_value;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            value_provider->SetValue(L"3.14"));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            value_provider->get_Value(bstr_value.Receive()));

  // IRangeValueProvider
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->SetValue(double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->get_LargeChange(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->get_Maximum(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->get_Minimum(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->get_SmallChange(&double_result));
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            range_value_provider->get_Value(&double_result));

  // IToggleProvider
  ToggleState toggle_state;
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            toggle_provider->Toggle());
  EXPECT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            toggle_provider->get_ToggleState(&toggle_state));

  // IWindowProvider
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->SetVisualState(
                WindowVisualState::WindowVisualState_Normal));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->Close());
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->WaitForInputIdle(0, nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_CanMaximize(nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_CanMinimize(nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_IsModal(nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_WindowVisualState(nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_WindowInteractionState(nullptr));
  ASSERT_EQ(static_cast<HRESULT>(UIA_E_ELEMENTNOTAVAILABLE),
            window_provider->get_IsTopmost(nullptr));
}

TEST_F(AXPlatformNodeWinTest, GetPatternProviderSupportedPatterns) {
  constexpr AXNode::AXID root_id = 1;
  constexpr AXNode::AXID text_field_with_combo_box_id = 2;
  constexpr AXNode::AXID meter_id = 3;
  constexpr AXNode::AXID group_with_scroll_id = 4;
  constexpr AXNode::AXID checkbox_id = 5;
  constexpr AXNode::AXID link_id = 6;
  constexpr AXNode::AXID table_without_header_id = 7;
  constexpr AXNode::AXID table_without_header_cell_id = 8;
  constexpr AXNode::AXID table_with_header_id = 9;
  constexpr AXNode::AXID table_with_header_row_1_id = 10;
  constexpr AXNode::AXID table_with_header_column_header_id = 11;
  constexpr AXNode::AXID table_with_header_row_2_id = 12;
  constexpr AXNode::AXID table_with_header_cell_id = 13;
  constexpr AXNode::AXID grid_without_header_id = 14;
  constexpr AXNode::AXID grid_without_header_cell_id = 15;
  constexpr AXNode::AXID grid_with_header_id = 16;
  constexpr AXNode::AXID grid_with_header_row_1_id = 17;
  constexpr AXNode::AXID grid_with_header_column_header_id = 18;
  constexpr AXNode::AXID grid_with_header_row_2_id = 19;
  constexpr AXNode::AXID grid_with_header_cell_id = 20;

  AXTreeUpdate update;
  update.tree_data.tree_id = ui::AXTreeID::CreateNewAXTreeID();
  update.has_tree_data = true;
  update.root_id = root_id;
  update.nodes.resize(20);
  update.nodes[0].id = root_id;
  update.nodes[0].role = ax::mojom::Role::kRootWebArea;
  update.nodes[0].child_ids = {text_field_with_combo_box_id,
                               meter_id,
                               group_with_scroll_id,
                               checkbox_id,
                               link_id,
                               table_without_header_id,
                               table_with_header_id,
                               grid_without_header_id,
                               grid_with_header_id};
  update.nodes[1].id = text_field_with_combo_box_id;
  update.nodes[1].role = ax::mojom::Role::kTextFieldWithComboBox;
  update.nodes[2].id = meter_id;
  update.nodes[2].role = ax::mojom::Role::kMeter;
  update.nodes[3].id = group_with_scroll_id;
  update.nodes[3].role = ax::mojom::Role::kGroup;
  update.nodes[3].AddIntAttribute(ax::mojom::IntAttribute::kScrollXMin, 10);
  update.nodes[3].AddIntAttribute(ax::mojom::IntAttribute::kScrollXMax, 10);
  update.nodes[3].AddIntAttribute(ax::mojom::IntAttribute::kScrollX, 10);
  update.nodes[4].id = checkbox_id;
  update.nodes[4].role = ax::mojom::Role::kCheckBox;
  update.nodes[5].id = link_id;
  update.nodes[5].role = ax::mojom::Role::kLink;
  update.nodes[6].id = table_without_header_id;
  update.nodes[6].role = ax::mojom::Role::kTable;
  update.nodes[6].child_ids = {table_without_header_cell_id};
  update.nodes[7].id = table_without_header_cell_id;
  update.nodes[7].role = ax::mojom::Role::kCell;
  update.nodes[8].id = table_with_header_id;
  update.nodes[8].role = ax::mojom::Role::kTable;
  update.nodes[8].child_ids = {table_with_header_row_1_id,
                               table_with_header_row_2_id};
  update.nodes[9].id = table_with_header_row_1_id;
  update.nodes[9].role = ax::mojom::Role::kRow;
  update.nodes[9].child_ids = {table_with_header_column_header_id};
  update.nodes[10].id = table_with_header_column_header_id;
  update.nodes[10].role = ax::mojom::Role::kColumnHeader;
  update.nodes[11].id = table_with_header_row_2_id;
  update.nodes[11].role = ax::mojom::Role::kRow;
  update.nodes[11].child_ids = {table_with_header_cell_id};
  update.nodes[12].id = table_with_header_cell_id;
  update.nodes[12].role = ax::mojom::Role::kCell;
  update.nodes[13].id = grid_without_header_id;
  update.nodes[13].role = ax::mojom::Role::kGrid;
  update.nodes[13].child_ids = {grid_without_header_cell_id};
  update.nodes[14].id = grid_without_header_cell_id;
  update.nodes[14].role = ax::mojom::Role::kCell;
  update.nodes[14].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  update.nodes[15].id = grid_with_header_id;
  update.nodes[15].role = ax::mojom::Role::kGrid;
  update.nodes[15].child_ids = {grid_with_header_row_1_id,
                                grid_with_header_row_2_id};
  update.nodes[16].id = grid_with_header_row_1_id;
  update.nodes[16].role = ax::mojom::Role::kRow;
  update.nodes[16].child_ids = {grid_with_header_column_header_id};
  update.nodes[17].id = grid_with_header_column_header_id;
  update.nodes[17].role = ax::mojom::Role::kColumnHeader;
  update.nodes[17].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  update.nodes[18].id = grid_with_header_row_2_id;
  update.nodes[18].role = ax::mojom::Role::kRow;
  update.nodes[18].child_ids = {grid_with_header_cell_id};
  update.nodes[19].id = grid_with_header_cell_id;
  update.nodes[19].role = ax::mojom::Role::kCell;
  update.nodes[19].AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);

  Init(update);

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_TextEditPatternId,
                        UIA_TextPatternId}),
            GetSupportedPatternsFromNodeId(root_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_ExpandCollapsePatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(text_field_with_combo_box_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_RangeValuePatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(meter_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ScrollPatternId,
                        UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(group_with_scroll_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_TextChildPatternId, UIA_TogglePatternId}),
            GetSupportedPatternsFromNodeId(checkbox_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_InvokePatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(link_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_GridPatternId,
                        UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(table_without_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_GridItemPatternId,
                        UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(table_without_header_cell_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_GridPatternId,
                        UIA_TablePatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(table_with_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_GridItemPatternId,
                        UIA_TableItemPatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(table_with_header_column_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_GridItemPatternId,
                        UIA_TableItemPatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(table_with_header_cell_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_SelectionPatternId, UIA_GridPatternId,
                        UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(grid_without_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_GridItemPatternId, UIA_TextChildPatternId,
                        UIA_SelectionItemPatternId}),
            GetSupportedPatternsFromNodeId(grid_without_header_cell_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_SelectionPatternId, UIA_GridPatternId,
                        UIA_TablePatternId, UIA_TextChildPatternId}),
            GetSupportedPatternsFromNodeId(grid_with_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_GridItemPatternId, UIA_TableItemPatternId,
                        UIA_TextChildPatternId, UIA_SelectionItemPatternId}),
            GetSupportedPatternsFromNodeId(grid_with_header_column_header_id));

  EXPECT_EQ(PatternSet({UIA_ScrollItemPatternId, UIA_ValuePatternId,
                        UIA_GridItemPatternId, UIA_TableItemPatternId,
                        UIA_TextChildPatternId, UIA_SelectionItemPatternId}),
            GetSupportedPatternsFromNodeId(grid_with_header_cell_id));
}

TEST_F(AXPlatformNodeWinTest, GetPatternProviderExpandCollapsePattern) {
  ui::AXNodeData root;
  root.id = 1;

  ui::AXNodeData list_box;
  ui::AXNodeData list_item;
  ui::AXNodeData menu_item;
  ui::AXNodeData menu_list_option;
  ui::AXNodeData tree_item;
  ui::AXNodeData combo_box_grouping;
  ui::AXNodeData combo_box_menu_button;
  ui::AXNodeData disclosure_triangle;
  ui::AXNodeData text_field_with_combo_box;

  list_box.id = 2;
  list_item.id = 3;
  menu_item.id = 4;
  menu_list_option.id = 5;
  tree_item.id = 6;
  combo_box_grouping.id = 7;
  combo_box_menu_button.id = 8;
  disclosure_triangle.id = 9;
  text_field_with_combo_box.id = 10;

  root.child_ids.push_back(list_box.id);
  root.child_ids.push_back(list_item.id);
  root.child_ids.push_back(menu_item.id);
  root.child_ids.push_back(menu_list_option.id);
  root.child_ids.push_back(tree_item.id);
  root.child_ids.push_back(combo_box_grouping.id);
  root.child_ids.push_back(combo_box_menu_button.id);
  root.child_ids.push_back(disclosure_triangle.id);
  root.child_ids.push_back(text_field_with_combo_box.id);

  // list_box HasPopup set to false, does not support expand collapse.
  list_box.role = ax::mojom::Role::kListBoxOption;
  list_box.SetHasPopup(ax::mojom::HasPopup::kFalse);

  // list_item HasPopup set to true, supports expand collapse.
  list_item.role = ax::mojom::Role::kListItem;
  list_item.SetHasPopup(ax::mojom::HasPopup::kTrue);

  // menu_item has expanded state and supports expand collapse.
  menu_item.role = ax::mojom::Role::kMenuItem;
  menu_item.AddState(ax::mojom::State::kExpanded);

  // menu_list_option has collapsed state and supports expand collapse.
  menu_list_option.role = ax::mojom::Role::kMenuListOption;
  menu_list_option.AddState(ax::mojom::State::kCollapsed);

  // These roles by default supports expand collapse.
  tree_item.role = ax::mojom::Role::kTreeItem;
  combo_box_grouping.role = ax::mojom::Role::kComboBoxGrouping;
  combo_box_menu_button.role = ax::mojom::Role::kComboBoxMenuButton;
  disclosure_triangle.role = ax::mojom::Role::kDisclosureTriangle;
  text_field_with_combo_box.role = ax::mojom::Role::kTextFieldWithComboBox;

  Init(root, list_box, list_item, menu_item, menu_list_option, tree_item,
       combo_box_grouping, combo_box_menu_button, disclosure_triangle,
       text_field_with_combo_box);

  // list_box HasPopup set to false, does not support expand collapse.
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetIRawElementProviderSimpleFromChildIndex(0);
  ComPtr<IExpandCollapseProvider> expandcollapse_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_EQ(nullptr, expandcollapse_provider.Get());

  // list_item HasPopup set to true, supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(1);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // menu_item has expanded state and supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(2);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // menu_list_option has collapsed state and supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(3);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // tree_item by default supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(4);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // combo_box_grouping by default supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(5);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // combo_box_menu_button by default supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(6);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // disclosure_triangle by default supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(7);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());

  // text_field_with_combo_box by default supports expand collapse.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(8);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  EXPECT_NE(nullptr, expandcollapse_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, GetPatternProviderInvokePattern) {
  ui::AXNodeData root;
  root.id = 1;

  ui::AXNodeData link;
  ui::AXNodeData generic_container;
  ui::AXNodeData combo_box_grouping;
  ui::AXNodeData check_box;

  link.id = 2;
  generic_container.id = 3;
  combo_box_grouping.id = 4;
  check_box.id = 5;

  root.child_ids.push_back(link.id);
  root.child_ids.push_back(generic_container.id);
  root.child_ids.push_back(combo_box_grouping.id);
  root.child_ids.push_back(check_box.id);

  // Role link is clickable and neither supports expand collapse nor supports
  // toggle. It should support invoke pattern.
  link.role = ax::mojom::Role::kLink;

  // Role generic container is not clickable. It should not support invoke
  // pattern.
  generic_container.role = ax::mojom::Role::kGenericContainer;

  // Role combo box grouping supports expand collapse. It should not support
  // invoke pattern.
  combo_box_grouping.role = ax::mojom::Role::kComboBoxGrouping;

  // Role check box supports toggle. It should not support invoke pattern.
  check_box.role = ax::mojom::Role::kCheckBox;

  Init(root, link, generic_container, combo_box_grouping, check_box);

  // Role link is clickable and neither supports expand collapse nor supports
  // toggle. It should support invoke pattern.
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetIRawElementProviderSimpleFromChildIndex(0);
  ComPtr<IInvokeProvider> invoke_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_NE(nullptr, invoke_provider.Get());

  // Role generic container is not clickable. It should not support invoke
  // pattern.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(1);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_EQ(nullptr, invoke_provider.Get());

  // Role combo box grouping supports expand collapse. It should not support
  // invoke pattern.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(2);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_EQ(nullptr, invoke_provider.Get());

  // Role check box supports toggle. It should not support invoke pattern.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(3);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_EQ(nullptr, invoke_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, IExpandCollapsePatternProviderAction) {
  ui::AXNodeData root;
  root.id = 1;

  ui::AXNodeData combo_box_grouping_has_popup;
  ui::AXNodeData combo_box_grouping_expanded;
  ui::AXNodeData combo_box_grouping_collapsed;
  ui::AXNodeData combo_box_grouping_disabled;
  ui::AXNodeData button_has_popup_menu;
  ui::AXNodeData button_has_popup_menu_pressed;
  ui::AXNodeData button_has_popup_true;
  ui::AXNodeData generic_container_has_popup_menu;

  combo_box_grouping_has_popup.id = 2;
  combo_box_grouping_expanded.id = 3;
  combo_box_grouping_collapsed.id = 4;
  combo_box_grouping_disabled.id = 5;
  button_has_popup_menu.id = 6;
  button_has_popup_menu_pressed.id = 7;
  button_has_popup_true.id = 8;
  generic_container_has_popup_menu.id = 9;

  root.child_ids = {
      combo_box_grouping_has_popup.id, combo_box_grouping_expanded.id,
      combo_box_grouping_collapsed.id, combo_box_grouping_disabled.id,
      button_has_popup_menu.id,        button_has_popup_menu_pressed.id,
      button_has_popup_true.id,        generic_container_has_popup_menu.id};

  // combo_box_grouping HasPopup set to true, can collapse, can expand.
  // state is ExpandCollapseState_LeafNode.
  combo_box_grouping_has_popup.role = ax::mojom::Role::kComboBoxGrouping;
  combo_box_grouping_has_popup.SetHasPopup(ax::mojom::HasPopup::kTrue);

  // combo_box_grouping Expanded set, can collapse, cannot expand.
  // state is ExpandCollapseState_Expanded.
  combo_box_grouping_expanded.role = ax::mojom::Role::kComboBoxGrouping;
  combo_box_grouping_expanded.AddState(ax::mojom::State::kExpanded);

  // combo_box_grouping Collapsed set, can expand, cannot collapse.
  // state is ExpandCollapseState_Collapsed.
  combo_box_grouping_collapsed.role = ax::mojom::Role::kComboBoxGrouping;
  combo_box_grouping_collapsed.AddState(ax::mojom::State::kCollapsed);

  // combo_box_grouping is disabled, can neither expand nor collapse.
  // state is ExpandCollapseState_LeafNode.
  combo_box_grouping_disabled.role = ax::mojom::Role::kComboBoxGrouping;
  combo_box_grouping_disabled.SetRestriction(ax::mojom::Restriction::kDisabled);

  // button_has_popup_menu HasPopup set to kMenu and is not STATE_PRESSED.
  // state is ExpandCollapseState_Collapsed.
  button_has_popup_menu.role = ax::mojom::Role::kButton;
  button_has_popup_menu.SetHasPopup(ax::mojom::HasPopup::kMenu);

  // button_has_popup_menu_pressed HasPopup set to kMenu and is STATE_PRESSED.
  // state is ExpandCollapseState_Expanded.
  button_has_popup_menu_pressed.role = ax::mojom::Role::kButton;
  button_has_popup_menu_pressed.SetHasPopup(ax::mojom::HasPopup::kMenu);
  button_has_popup_menu_pressed.SetCheckedState(ax::mojom::CheckedState::kTrue);

  // button_has_popup_true HasPopup set to true but is not a menu.
  // state is ExpandCollapseState_LeafNode.
  button_has_popup_true.role = ax::mojom::Role::kButton;
  button_has_popup_true.SetHasPopup(ax::mojom::HasPopup::kTrue);

  // generic_container_has_popup_menu HasPopup set to menu but with no expand
  // state set.
  // state is ExpandCollapseState_LeafNode.
  generic_container_has_popup_menu.role = ax::mojom::Role::kGenericContainer;
  generic_container_has_popup_menu.SetHasPopup(ax::mojom::HasPopup::kMenu);

  Init(root, combo_box_grouping_has_popup, combo_box_grouping_disabled,
       combo_box_grouping_expanded, combo_box_grouping_collapsed,
       combo_box_grouping_disabled, button_has_popup_menu,
       button_has_popup_menu_pressed, button_has_popup_true,
       generic_container_has_popup_menu);

  // combo_box_grouping HasPopup set to true, can collapse, can expand.
  // state is ExpandCollapseState_LeafNode.
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetIRawElementProviderSimpleFromChildIndex(0);
  ComPtr<IExpandCollapseProvider> expandcollapse_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(expandcollapse_provider->Collapse());
  EXPECT_HRESULT_SUCCEEDED(expandcollapse_provider->Expand());
  ExpandCollapseState state;
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_LeafNode, state);

  // combo_box_grouping Expanded set, can collapse, cannot expand.
  // state is ExpandCollapseState_Expanded.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(1);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(expandcollapse_provider->Collapse());
  EXPECT_HRESULT_FAILED(expandcollapse_provider->Expand());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_Expanded, state);

  // combo_box_grouping Collapsed set, can expand, cannot collapse.
  // state is ExpandCollapseState_Collapsed.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(2);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_FAILED(expandcollapse_provider->Collapse());
  EXPECT_HRESULT_SUCCEEDED(expandcollapse_provider->Expand());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_Collapsed, state);

  // combo_box_grouping is disabled, can neither expand nor collapse.
  // state is ExpandCollapseState_LeafNode.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(3);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_FAILED(expandcollapse_provider->Collapse());
  EXPECT_HRESULT_FAILED(expandcollapse_provider->Expand());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_LeafNode, state);

  // button_has_popup_menu HasPopup set to kMenu and is not STATE_PRESSED.
  // state is ExpandCollapseState_Collapsed.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(4);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_Collapsed, state);

  // button_has_popup_menu_pressed HasPopup set to kMenu and is STATE_PRESSED.
  // state is ExpandCollapseState_Expanded.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(5);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_Expanded, state);

  // button_has_popup_true HasPopup set to true but is not a menu.
  // state is ExpandCollapseState_LeafNode.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(6);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_LeafNode, state);

  // generic_container_has_popup_menu HasPopup set to menu but with no expand
  // state set.
  // state is ExpandCollapseState_LeafNode.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(7);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_ExpandCollapsePatternId, &expandcollapse_provider));
  ASSERT_NE(nullptr, expandcollapse_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(
      expandcollapse_provider->get_ExpandCollapseState(&state));
  EXPECT_EQ(ExpandCollapseState_LeafNode, state);
}

TEST_F(AXPlatformNodeWinTest, IInvokeProviderInvoke) {
  ui::AXNodeData root;
  root.id = 1;

  ui::AXNodeData button;
  ui::AXNodeData button_disabled;

  button.id = 2;
  button_disabled.id = 3;

  root.child_ids.push_back(button.id);
  root.child_ids.push_back(button_disabled.id);

  // generic button can be invoked.
  button.role = ax::mojom::Role::kButton;

  // disabled button, cannot be invoked.
  button_disabled.role = ax::mojom::Role::kButton;
  button_disabled.SetRestriction(ax::mojom::Restriction::kDisabled);

  Init(root, button, button_disabled);
  AXNode* button_node = GetRootAsAXNode()->children()[0];

  // generic button can be invoked.
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetIRawElementProviderSimpleFromChildIndex(0);
  ComPtr<IInvokeProvider> invoke_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_NE(nullptr, invoke_provider.Get());
  EXPECT_HRESULT_SUCCEEDED(invoke_provider->Invoke());
  EXPECT_EQ(button_node, TestAXNodeWrapper::GetNodeFromLastDefaultAction());

  // disabled button, cannot be invoked.
  raw_element_provider_simple = GetIRawElementProviderSimpleFromChildIndex(1);
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_InvokePatternId, &invoke_provider));
  EXPECT_NE(nullptr, invoke_provider.Get());
  EXPECT_UIA_ELEMENTNOTENABLED(invoke_provider->Invoke());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderNotSupported) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kNone;

  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<ISelectionItemProvider> selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &selection_item_provider));
  ASSERT_EQ(nullptr, selection_item_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderDisabled) {
  AXNodeData root;
  root.id = 1;
  root.AddIntAttribute(ax::mojom::IntAttribute::kRestriction,
                       static_cast<int>(ax::mojom::Restriction::kDisabled));
  root.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, true);
  root.role = ax::mojom::Role::kTab;

  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<ISelectionItemProvider> selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &selection_item_provider));
  ASSERT_NE(nullptr, selection_item_provider.Get());

  BOOL selected;

  EXPECT_UIA_ELEMENTNOTENABLED(selection_item_provider->AddToSelection());
  EXPECT_UIA_ELEMENTNOTENABLED(selection_item_provider->RemoveFromSelection());
  EXPECT_UIA_ELEMENTNOTENABLED(selection_item_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderNotSelectable) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTab;

  Init(root);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetRootIRawElementProviderSimple();
  ComPtr<ISelectionItemProvider> selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &selection_item_provider));
  ASSERT_EQ(nullptr, selection_item_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderSimple) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kListBox;

  AXNodeData option1;
  option1.id = 2;
  option1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  option1.role = ax::mojom::Role::kListBoxOption;
  root.child_ids.push_back(option1.id);

  Init(root, option1);

  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      GetIRawElementProviderSimpleFromChildIndex(0);
  ComPtr<ISelectionItemProvider> option1_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &option1_provider));
  ASSERT_NE(nullptr, option1_provider.Get());

  BOOL selected;

  // Note: TestAXNodeWrapper::AccessibilityPerformAction will
  // flip kSelected for kListBoxOption when the kDoDefault action is fired.

  // Initial State
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // AddToSelection should fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // AddToSelection should not fire event when selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // RemoveFromSelection should fire event when selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // RemoveFromSelection should not fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // Select should fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Select should not fire event when selected
  EXPECT_HRESULT_SUCCEEDED(option1_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(option1_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderRadioButton) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRadioGroup;

  // CheckedState::kNone
  AXNodeData option1;
  option1.id = 2;
  option1.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kNone));
  option1.role = ax::mojom::Role::kRadioButton;
  root.child_ids.push_back(option1.id);

  // CheckedState::kFalse
  AXNodeData option2;
  option2.id = 3;
  option2.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kFalse));
  option2.role = ax::mojom::Role::kRadioButton;
  root.child_ids.push_back(option2.id);

  // CheckedState::kTrue
  AXNodeData option3;
  option3.id = 4;
  option3.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kTrue));
  option3.role = ax::mojom::Role::kRadioButton;
  root.child_ids.push_back(option3.id);

  // CheckedState::kMixed
  AXNodeData option4;
  option4.id = 5;
  option4.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kMixed));
  option4.role = ax::mojom::Role::kRadioButton;
  root.child_ids.push_back(option4.id);

  Init(root, option1, option2, option3, option4);

  BOOL selected;

  // Option 1, CheckedState::kNone, ISelectionItemProvider is not supported.
  ComPtr<ISelectionItemProvider> option1_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(0)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option1_provider));
  ASSERT_EQ(nullptr, option1_provider.Get());

  // Option 2, CheckedState::kFalse.
  ComPtr<ISelectionItemProvider> option2_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(1)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option2_provider));
  ASSERT_NE(nullptr, option2_provider.Get());

  EXPECT_HRESULT_SUCCEEDED(option2_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  EXPECT_HRESULT_SUCCEEDED(option2_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(option2_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Option 3, CheckedState::kTrue.
  ComPtr<ISelectionItemProvider> option3_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(2)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option3_provider));
  ASSERT_NE(nullptr, option3_provider.Get());

  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  EXPECT_HRESULT_SUCCEEDED(option3_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  EXPECT_HRESULT_SUCCEEDED(option3_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Option 4, CheckedState::kMixed, ISelectionItemProvider is not supported.
  ComPtr<ISelectionItemProvider> option4_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(3)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option4_provider));
  ASSERT_EQ(nullptr, option4_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderMenuItemRadio) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kMenu;

  // CheckedState::kNone
  AXNodeData option1;
  option1.id = 2;
  option1.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kNone));
  option1.role = ax::mojom::Role::kMenuItemRadio;
  root.child_ids.push_back(option1.id);

  // CheckedState::kFalse
  AXNodeData option2;
  option2.id = 3;
  option2.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kFalse));
  option2.role = ax::mojom::Role::kMenuItemRadio;
  root.child_ids.push_back(option2.id);

  // CheckedState::kTrue
  AXNodeData option3;
  option3.id = 4;
  option3.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kTrue));
  option3.role = ax::mojom::Role::kMenuItemRadio;
  root.child_ids.push_back(option3.id);

  // CheckedState::kMixed
  AXNodeData option4;
  option4.id = 5;
  option4.AddIntAttribute(ax::mojom::IntAttribute::kCheckedState,
                          static_cast<int>(ax::mojom::CheckedState::kMixed));
  option4.role = ax::mojom::Role::kMenuItemRadio;
  root.child_ids.push_back(option4.id);

  Init(root, option1, option2, option3, option4);

  BOOL selected;

  // Option 1, CheckedState::kNone, ISelectionItemProvider is not supported.
  ComPtr<ISelectionItemProvider> option1_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(0)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option1_provider));
  ASSERT_EQ(nullptr, option1_provider.Get());

  // Option 2, CheckedState::kFalse.
  ComPtr<ISelectionItemProvider> option2_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(1)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option2_provider));
  ASSERT_NE(nullptr, option2_provider.Get());

  EXPECT_HRESULT_SUCCEEDED(option2_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  EXPECT_HRESULT_SUCCEEDED(option2_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(option2_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Option 3, CheckedState::kTrue.
  ComPtr<ISelectionItemProvider> option3_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(2)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option3_provider));
  ASSERT_NE(nullptr, option3_provider.Get());

  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  EXPECT_HRESULT_SUCCEEDED(option3_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  EXPECT_HRESULT_SUCCEEDED(option3_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(option3_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Option 4, CheckedState::kMixed, ISelectionItemProvider is not supported.
  ComPtr<ISelectionItemProvider> option4_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(3)->GetPatternProvider(
          UIA_SelectionItemPatternId, &option4_provider));
  ASSERT_EQ(nullptr, option4_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderTable) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTable;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData cell1;
  cell1.id = 3;
  cell1.role = ax::mojom::Role::kCell;
  cell1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  row1.child_ids.push_back(cell1.id);

  Init(root, row1, cell1);

  ComPtr<ISelectionItemProvider> selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(
      GetIRawElementProviderSimpleFromChildIndex(0)->GetPatternProvider(
          UIA_SelectionItemPatternId, &selection_item_provider));
  ASSERT_EQ(nullptr, selection_item_provider.Get());
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderGrid) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kGrid;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData cell1;
  cell1.id = 3;
  cell1.role = ax::mojom::Role::kCell;
  cell1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  row1.child_ids.push_back(cell1.id);

  Init(root, row1, cell1);

  const auto* row = GetRootAsAXNode()->children()[0];
  ComPtr<IRawElementProviderSimple> raw_element_provider_simple =
      QueryInterfaceFromNode<IRawElementProviderSimple>(row->children()[0]);

  ComPtr<ISelectionItemProvider> selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &selection_item_provider));
  ASSERT_NE(nullptr, selection_item_provider.Get());

  BOOL selected;

  // Note: TestAXNodeWrapper::AccessibilityPerformAction will
  // flip kSelected for kCell when the kDoDefault action is fired.

  // Initial State
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // AddToSelection should fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // AddToSelection should not fire event when selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->AddToSelection());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // RemoveFromSelection should fire event when selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // RemoveFromSelection should not fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->RemoveFromSelection());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_FALSE(selected);

  // Select should fire event when not selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);

  // Select should not fire event when selected
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->Select());
  EXPECT_HRESULT_SUCCEEDED(selection_item_provider->get_IsSelected(&selected));
  EXPECT_TRUE(selected);
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderGetSelectionContainer) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kGrid;

  AXNodeData row1;
  row1.id = 2;
  row1.role = ax::mojom::Role::kRow;
  root.child_ids.push_back(row1.id);

  AXNodeData cell1;
  cell1.id = 3;
  cell1.role = ax::mojom::Role::kCell;
  cell1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  row1.child_ids.push_back(cell1.id);

  Init(root, row1, cell1);

  ComPtr<IRawElementProviderSimple> container_provider =
      GetRootIRawElementProviderSimple();

  const auto* row = GetRootAsAXNode()->children()[0];
  ComPtr<ISelectionItemProvider> item_provider =
      QueryInterfaceFromNode<ISelectionItemProvider>(row->children()[0]);

  ComPtr<IRawElementProviderSimple> container;
  EXPECT_HRESULT_SUCCEEDED(item_provider->get_SelectionContainer(&container));
  EXPECT_NE(nullptr, container);
  EXPECT_EQ(container, container_provider);
}

TEST_F(AXPlatformNodeWinTest, ISelectionItemProviderSelectFollowFocus) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kTabList;

  AXNodeData tab1;
  tab1.id = 2;
  tab1.role = ax::mojom::Role::kTab;
  tab1.AddBoolAttribute(ax::mojom::BoolAttribute::kSelected, false);
  tab1.SetDefaultActionVerb(ax::mojom::DefaultActionVerb::kClick);
  root.child_ids.push_back(tab1.id);

  Init(root, tab1);

  auto* tab1_node = GetRootAsAXNode()->children()[0];
  ComPtr<IRawElementProviderSimple> tab1_raw_element_provider_simple =
      QueryInterfaceFromNode<IRawElementProviderSimple>(tab1_node);
  ASSERT_NE(nullptr, tab1_raw_element_provider_simple.Get());

  ComPtr<IRawElementProviderFragment> tab1_raw_element_provider_fragment =
      IRawElementProviderFragmentFromNode(tab1_node);
  ASSERT_NE(nullptr, tab1_raw_element_provider_fragment.Get());

  ComPtr<ISelectionItemProvider> tab1_selection_item_provider;
  EXPECT_HRESULT_SUCCEEDED(tab1_raw_element_provider_simple->GetPatternProvider(
      UIA_SelectionItemPatternId, &tab1_selection_item_provider));
  ASSERT_NE(nullptr, tab1_selection_item_provider.Get());

  BOOL is_selected;
  // Before setting focus to "tab1", validate that "tab1" has selected=false.
  tab1_selection_item_provider->get_IsSelected(&is_selected);
  EXPECT_FALSE(is_selected);

  // Setting focus on "tab1" will result in selected=true.
  tab1_raw_element_provider_fragment->SetFocus();
  tab1_selection_item_provider->get_IsSelected(&is_selected);
  EXPECT_TRUE(is_selected);

  // Verify that we can still trigger action::kDoDefault through Select().
  EXPECT_HRESULT_SUCCEEDED(tab1_selection_item_provider->Select());
  tab1_selection_item_provider->get_IsSelected(&is_selected);
  EXPECT_TRUE(is_selected);
  EXPECT_EQ(tab1_node, TestAXNodeWrapper::GetNodeFromLastDefaultAction());
  // Verify that after Select(), "tab1" is still selected.
  tab1_selection_item_provider->get_IsSelected(&is_selected);
  EXPECT_TRUE(is_selected);

  // Since last Select() performed |action::kDoDefault|, which set
  // |kSelectedFromFocus| to false. Calling Select() again will not perform
  // |action::kDoDefault| again.
  TestAXNodeWrapper::SetNodeFromLastDefaultAction(nullptr);
  EXPECT_HRESULT_SUCCEEDED(tab1_selection_item_provider->Select());
  tab1_selection_item_provider->get_IsSelected(&is_selected);
  EXPECT_TRUE(is_selected);
  // Verify that after Select(),|action::kDoDefault| was not triggered on
  // "tab1".
  EXPECT_EQ(nullptr, TestAXNodeWrapper::GetNodeFromLastDefaultAction());
}

TEST_F(AXPlatformNodeWinTest, IValueProvider_GetValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kProgressIndicator;
  child1.AddFloatAttribute(ax::mojom::FloatAttribute::kValueForRange, 3.0f);
  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kTextField;
  child2.AddState(ax::mojom::State::kEditable);
  child2.AddStringAttribute(ax::mojom::StringAttribute::kValue, "test");
  root.child_ids.push_back(child2.id);

  AXNodeData child3;
  child3.id = 4;
  child3.role = ax::mojom::Role::kTextField;
  child3.AddStringAttribute(ax::mojom::StringAttribute::kValue, "test");
  child3.AddIntAttribute(ax::mojom::IntAttribute::kRestriction,
                         static_cast<int>(ax::mojom::Restriction::kReadOnly));
  root.child_ids.push_back(child3.id);

  Init(root, child1, child2, child3);

  ScopedBstr bstr_value;

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[0])
          ->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"3", bstr_value.Get());
  bstr_value.Reset();

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[1])
          ->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"test", bstr_value.Get());
  bstr_value.Reset();

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[2])
          ->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"test", bstr_value.Get());
  bstr_value.Reset();
}

TEST_F(AXPlatformNodeWinTest, IAccessibleValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child;
  child.id = 2;
  child.role = ax::mojom::Role::kSlider;
  child.AddFloatAttribute(ax::mojom::FloatAttribute::kValueForRange, 3.0f);
  child.AddFloatAttribute(ax::mojom::FloatAttribute::kMinValueForRange, 1.0f);
  child.AddFloatAttribute(ax::mojom::FloatAttribute::kMaxValueForRange, 9.0f);
  root.child_ids.push_back(child.id);

  Init(root, child);

  ScopedVariant value;
  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IAccessibleValue>(GetRootAsAXNode()->children()[0])
          ->get_currentValue(value.Receive()));
  ASSERT_EQ(VT_R8, value.type());
  EXPECT_DOUBLE_EQ(3.0, V_R8(value.ptr()));
}

TEST_F(AXPlatformNodeWinTest, IValueProvider_SetValue) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kProgressIndicator;
  child1.AddFloatAttribute(ax::mojom::FloatAttribute::kValueForRange, 3.0f);
  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kTextField;
  child2.AddStringAttribute(ax::mojom::StringAttribute::kValue, "test");
  root.child_ids.push_back(child2.id);

  AXNodeData child3;
  child3.id = 4;
  child3.role = ax::mojom::Role::kTextField;
  child3.AddStringAttribute(ax::mojom::StringAttribute::kValue, "test");
  child3.AddIntAttribute(ax::mojom::IntAttribute::kRestriction,
                         static_cast<int>(ax::mojom::Restriction::kReadOnly));
  root.child_ids.push_back(child3.id);

  Init(root, child1, child2, child3);

  ComPtr<IValueProvider> root_provider =
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode());
  ComPtr<IValueProvider> provider1 =
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[0]);
  ComPtr<IValueProvider> provider2 =
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[1]);
  ComPtr<IValueProvider> provider3 =
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[2]);

  ScopedBstr bstr_value;

  // Note: TestAXNodeWrapper::AccessibilityPerformAction will
  // modify the value when the kSetValue action is fired.

  EXPECT_UIA_ELEMENTNOTENABLED(provider1->SetValue(L"2"));
  EXPECT_HRESULT_SUCCEEDED(provider1->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"3", bstr_value.Get());
  bstr_value.Reset();

  EXPECT_HRESULT_SUCCEEDED(provider2->SetValue(L"changed"));
  EXPECT_HRESULT_SUCCEEDED(provider2->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"changed", bstr_value.Get());
  bstr_value.Reset();

  EXPECT_UIA_ELEMENTNOTENABLED(provider3->SetValue(L"changed"));
  EXPECT_HRESULT_SUCCEEDED(provider3->get_Value(bstr_value.Receive()));
  EXPECT_STREQ(L"test", bstr_value.Get());
  bstr_value.Reset();
}

TEST_F(AXPlatformNodeWinTest, IValueProvider_IsReadOnly) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kRootWebArea;

  AXNodeData child1;
  child1.id = 2;
  child1.role = ax::mojom::Role::kTextField;
  child1.AddState(ax::mojom::State::kEditable);
  root.child_ids.push_back(child1.id);

  AXNodeData child2;
  child2.id = 3;
  child2.role = ax::mojom::Role::kTextField;
  child2.AddIntAttribute(ax::mojom::IntAttribute::kRestriction,
                         static_cast<int>(ax::mojom::Restriction::kReadOnly));
  root.child_ids.push_back(child2.id);

  AXNodeData child3;
  child3.id = 4;
  child3.role = ax::mojom::Role::kTextField;
  child3.AddIntAttribute(ax::mojom::IntAttribute::kRestriction,
                         static_cast<int>(ax::mojom::Restriction::kDisabled));
  root.child_ids.push_back(child3.id);

  AXNodeData child4;
  child4.id = 5;
  child4.role = ax::mojom::Role::kLink;
  root.child_ids.push_back(child4.id);

  Init(root, child1, child2, child3, child4);

  BOOL is_readonly = false;

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[0])
          ->get_IsReadOnly(&is_readonly));
  EXPECT_FALSE(is_readonly);

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[1])
          ->get_IsReadOnly(&is_readonly));
  EXPECT_TRUE(is_readonly);

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[2])
          ->get_IsReadOnly(&is_readonly));
  EXPECT_TRUE(is_readonly);

  EXPECT_HRESULT_SUCCEEDED(
      QueryInterfaceFromNode<IValueProvider>(GetRootAsAXNode()->children()[3])
          ->get_IsReadOnly(&is_readonly));
  EXPECT_TRUE(is_readonly);
}

TEST_F(AXPlatformNodeWinTest, IScrollProviderSetScrollPercent) {
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kGenericContainer;
  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollX, 0);
  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollXMin, 0);
  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollXMax, 100);

  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollY, 60);
  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollYMin, 10);
  root.AddIntAttribute(ax::mojom::IntAttribute::kScrollYMax, 60);

  Init(root);

  ComPtr<IScrollProvider> scroll_provider =
      QueryInterfaceFromNode<IScrollProvider>(GetRootAsAXNode());
  double x_scroll_percent;
  double y_scroll_percent;

  // Set x scroll percent: 0%, y scroll percent: 0%.
  // Expected x scroll percent: 0%, y scroll percent: 0%.
  EXPECT_HRESULT_SUCCEEDED(scroll_provider->SetScrollPercent(0, 0));
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_HorizontalScrollPercent(&x_scroll_percent));
  EXPECT_EQ(x_scroll_percent, 0);
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_VerticalScrollPercent(&y_scroll_percent));
  EXPECT_EQ(y_scroll_percent, 0);

  // Set x scroll percent: 100%, y scroll percent: 100%.
  // Expected x scroll percent: 100%, y scroll percent: 100%.
  EXPECT_HRESULT_SUCCEEDED(scroll_provider->SetScrollPercent(100, 100));
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_HorizontalScrollPercent(&x_scroll_percent));
  EXPECT_EQ(x_scroll_percent, 100);
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_VerticalScrollPercent(&y_scroll_percent));
  EXPECT_EQ(y_scroll_percent, 100);

  // Set x scroll percent: 500%, y scroll percent: 600%.
  // Expected x scroll percent: 100%, y scroll percent: 100%.
  EXPECT_HRESULT_SUCCEEDED(scroll_provider->SetScrollPercent(500, 600));
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_HorizontalScrollPercent(&x_scroll_percent));
  EXPECT_EQ(x_scroll_percent, 100);
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_VerticalScrollPercent(&y_scroll_percent));
  EXPECT_EQ(y_scroll_percent, 100);

  // Set x scroll percent: -100%, y scroll percent: -200%.
  // Expected x scroll percent: 0%, y scroll percent: 0%.
  EXPECT_HRESULT_SUCCEEDED(scroll_provider->SetScrollPercent(-100, -200));
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_HorizontalScrollPercent(&x_scroll_percent));
  EXPECT_EQ(x_scroll_percent, 0);
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_VerticalScrollPercent(&y_scroll_percent));
  EXPECT_EQ(y_scroll_percent, 0);

  // Set x scroll percent: 12%, y scroll percent: 34%.
  // Expected x scroll percent: 12%, y scroll percent: 34%.
  EXPECT_HRESULT_SUCCEEDED(scroll_provider->SetScrollPercent(12, 34));
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_HorizontalScrollPercent(&x_scroll_percent));
  EXPECT_EQ(x_scroll_percent, 12);
  EXPECT_HRESULT_SUCCEEDED(
      scroll_provider->get_VerticalScrollPercent(&y_scroll_percent));
  EXPECT_EQ(y_scroll_percent, 34);
}

TEST_F(AXPlatformNodeWinTest, SanitizeStringAttributeForIA2) {
  std::string input("\\:=,;");
  std::string output;
  AXPlatformNodeWin::SanitizeStringAttributeForIA2(input, &output);
  EXPECT_EQ("\\\\\\:\\=\\,\\;", output);
}

//
// IChromeAccessible tests
//

class TestIChromeAccessibleDelegate
    : public CComObjectRootEx<CComMultiThreadModel>,
      public IDispatchImpl<IChromeAccessibleDelegate> {
  using IDispatchImpl::Invoke;

 public:
  BEGIN_COM_MAP(TestIChromeAccessibleDelegate)
  COM_INTERFACE_ENTRY(IChromeAccessibleDelegate)
  END_COM_MAP()

  TestIChromeAccessibleDelegate() = default;
  ~TestIChromeAccessibleDelegate() = default;

  std::string WaitForBulkFetchResult(LONG expected_request_id) {
    if (bulk_fetch_result_.empty())
      WaitUsingRunLoop();
    CHECK_EQ(expected_request_id, request_id_);
    return bulk_fetch_result_;
  }

  IUnknown* WaitForHitTestResult(LONG expected_request_id) {
    if (!hit_test_result_)
      WaitUsingRunLoop();
    CHECK_EQ(expected_request_id, request_id_);
    return hit_test_result_.Get();
  }

 private:
  void WaitUsingRunLoop() {
    base::RunLoop run_loop;
    run_loop_quit_closure_ = run_loop.QuitClosure();
    run_loop.Run();
  }

  IFACEMETHODIMP put_bulkFetchResult(LONG request_id, BSTR result) override {
    bulk_fetch_result_ = base::WideToUTF8(result);
    request_id_ = request_id;
    if (run_loop_quit_closure_)
      run_loop_quit_closure_.Run();
    return S_OK;
  }

  IFACEMETHODIMP put_hitTestResult(LONG request_id, IUnknown* result) override {
    hit_test_result_ = result;
    request_id_ = request_id;
    if (run_loop_quit_closure_)
      run_loop_quit_closure_.Run();
    return S_OK;
  }

  std::string bulk_fetch_result_;
  ComPtr<IUnknown> hit_test_result_;
  LONG request_id_ = 0;
  base::RepeatingClosure run_loop_quit_closure_;
};

// http://crbug.com/1087206: failing on Win7 builders.
TEST_F(AXPlatformNodeWinTest, DISABLED_BulkFetch) {
  base::test::SingleThreadTaskEnvironment task_environment;
  AXNodeData root;
  root.id = 1;
  root.role = ax::mojom::Role::kScrollBar;

  Init(root);

  ComPtr<IChromeAccessible> chrome_accessible =
      QueryInterfaceFromNode<IChromeAccessible>(GetRootAsAXNode());

  CComObject<TestIChromeAccessibleDelegate>* delegate = nullptr;
  ASSERT_HRESULT_SUCCEEDED(
      CComObject<TestIChromeAccessibleDelegate>::CreateInstance(&delegate));
  ScopedBstr input_bstr(L"Potato");
  chrome_accessible->get_bulkFetch(input_bstr.Get(), 99, delegate);
  std::string response = delegate->WaitForBulkFetchResult(99);

  // Note: base::JSONReader is fine for unit tests, but production code
  // that parses untrusted JSON should always use DataDecoder instead.
  base::Optional<base::Value> result =
      base::JSONReader::Read(response, base::JSON_ALLOW_TRAILING_COMMAS);
  ASSERT_TRUE(result);
  ASSERT_TRUE(result->FindKey("role"));
  ASSERT_EQ("scrollBar", result->FindKey("role")->GetString());
}

TEST_F(AXPlatformNodeWinTest, AsyncHitTest) {
  base::test::SingleThreadTaskEnvironment task_environment;
  AXNodeData root;
  root.id = 50;
  root.role = ax::mojom::Role::kArticle;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 800, 600);

  Init(root);

  ComPtr<IChromeAccessible> chrome_accessible =
      QueryInterfaceFromNode<IChromeAccessible>(GetRootAsAXNode());

  CComObject<TestIChromeAccessibleDelegate>* delegate = nullptr;
  ASSERT_HRESULT_SUCCEEDED(
      CComObject<TestIChromeAccessibleDelegate>::CreateInstance(&delegate));
  ScopedBstr input_bstr(L"Potato");
  chrome_accessible->get_hitTest(400, 300, 12345, delegate);
  ComPtr<IUnknown> result = delegate->WaitForHitTestResult(12345);
  ComPtr<IAccessible2> accessible = ToIAccessible2(result);
  LONG result_unique_id = 0;
  ASSERT_HRESULT_SUCCEEDED(accessible->get_uniqueID(&result_unique_id));
  ComPtr<IAccessible2> root_accessible =
      QueryInterfaceFromNode<IAccessible2>(GetRootAsAXNode());
  LONG root_unique_id = 0;
  ASSERT_HRESULT_SUCCEEDED(root_accessible->get_uniqueID(&root_unique_id));
  ASSERT_EQ(root_unique_id, result_unique_id);
}

}  // namespace ui

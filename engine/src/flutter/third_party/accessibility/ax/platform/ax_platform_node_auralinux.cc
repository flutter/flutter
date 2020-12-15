// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_node_auralinux.h"

#include <dlfcn.h>
#include <stdint.h>

#include <algorithm>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/debug/leak_annotations.h"
#include "base/metrics/histogram_macros.h"
#include "base/no_destructor.h"
#include "base/numerics/ranges.h"
#include "base/optional.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversion_utils.h"
#include "base/strings/utf_string_conversions.h"
#include "build/build_config.h"
#include "ui/accessibility/ax_action_data.h"
#include "ui/accessibility/ax_enum_util.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_mode_observer.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/ax_role_properties.h"
#include "ui/accessibility/ax_tree_data.h"
#include "ui/accessibility/platform/atk_util_auralinux.h"
#include "ui/accessibility/platform/ax_platform_atk_hyperlink.h"
#include "ui/accessibility/platform/ax_platform_node_delegate.h"
#include "ui/accessibility/platform/ax_platform_node_delegate_base.h"
#include "ui/accessibility/platform/ax_platform_text_boundary.h"
#include "ui/gfx/geometry/rect_conversions.h"

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 10, 0)
#define ATK_210
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 12, 0)
#define ATK_212
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 16, 0)
#define ATK_216
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 26, 0)
#define ATK_226
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 30, 0)
#define ATK_230
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 32, 0)
#define ATK_232
#endif

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 34, 0)
#define ATK_234
#endif

namespace ui {

namespace {

// IMPORTANT!
// These values are written to logs.  Do not renumber or delete
// existing items; add new entries to the end of the list.
enum class UmaAtkApi {
  kGetName = 0,
  kGetDescription = 1,
  kGetNChildren = 2,
  kRefChild = 3,
  kGetIndexInParent = 4,
  kGetParent = 5,
  kRefRelationSet = 6,
  kGetAttributes = 7,
  kGetRole = 8,
  kRefStateSet = 9,
  // This must always be the last enum. It's okay for its value to
  // increase, but none of the other enum values may change.
  kMaxValue = kRefStateSet,
};

void RecordAccessibilityAtkApi(UmaAtkApi enum_value) {
  UMA_HISTOGRAM_ENUMERATION("Accessibility.ATK-APIs", enum_value);
}

// When accepting input from clients calling the API, an ATK character offset
// of -1 can often represent the length of the string.
static const int kStringLengthOffset = -1;

// We must forward declare this because it is used by the traditional GObject
// type manipulation macros.
namespace atk_object {
GType GetType();
}  // namespace atk_object

//
// ax_platform_node_auralinux AtkObject definition and implementation.
//
#define AX_PLATFORM_NODE_AURALINUX_TYPE (atk_object::GetType())
#define AX_PLATFORM_NODE_AURALINUX(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), AX_PLATFORM_NODE_AURALINUX_TYPE, \
                              AXPlatformNodeAuraLinuxObject))
#define AX_PLATFORM_NODE_AURALINUX_CLASS(klass)                      \
  (G_TYPE_CHECK_CLASS_CAST((klass), AX_PLATFORM_NODE_AURALINUX_TYPE, \
                           AXPlatformNodeAuraLinuxClass))
#define IS_AX_PLATFORM_NODE_AURALINUX(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), AX_PLATFORM_NODE_AURALINUX_TYPE))
#define IS_AX_PLATFORM_NODE_AURALINUX_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), AX_PLATFORM_NODE_AURALINUX_TYPE))
#define AX_PLATFORM_NODE_AURALINUX_GET_CLASS(obj)                    \
  (G_TYPE_INSTANCE_GET_CLASS((obj), AX_PLATFORM_NODE_AURALINUX_TYPE, \
                             AXPlatformNodeAuraLinuxClass))

typedef struct _AXPlatformNodeAuraLinuxObject AXPlatformNodeAuraLinuxObject;
typedef struct _AXPlatformNodeAuraLinuxClass AXPlatformNodeAuraLinuxClass;

struct _AXPlatformNodeAuraLinuxObject {
  AtkObject parent;
  AXPlatformNodeAuraLinux* m_object;
};

struct _AXPlatformNodeAuraLinuxClass {
  AtkObjectClass parent_class;
};

// The root-level Application object that's the parent of all top-level windows.
AXPlatformNode* g_root_application = nullptr;

// The last AtkObject with keyboard focus. Tracking this is required to emit the
// ATK_STATE_FOCUSED change to false.
AtkObject* g_current_focused = nullptr;

// The last AtkObject which was the active descendant in the currently-focused
// object (example: The highlighted option within a focused select element).
// As with g_current_focused, we track this to emit events when this object is
// no longer the active descendant.
AtkObject* g_current_active_descendant = nullptr;

// The last object which was selected. Tracking this is required because
// widgets in the browser UI only emit notifications upon becoming selected,
// but clients also expect notifications when items become unselected.
AXPlatformNodeAuraLinux* g_current_selected = nullptr;

// The AtkObject with role=ATK_ROLE_FRAME that represents the toplevel desktop
// window with focus. If this window is not one of our windows, this value
// should be null. This is a weak pointer as well, so its value will also be
// null if if the AtkObject is destroyed.
AtkObject* g_active_top_level_frame = nullptr;

AtkObject* g_active_views_dialog = nullptr;

#if defined(ATK_216)
constexpr AtkRole kStaticRole = ATK_ROLE_STATIC;
constexpr AtkRole kSubscriptRole = ATK_ROLE_SUBSCRIPT;
constexpr AtkRole kSuperscriptRole = ATK_ROLE_SUPERSCRIPT;
#else
constexpr AtkRole kStaticRole = ATK_ROLE_TEXT;
constexpr AtkRole kSubscriptRole = ATK_ROLE_TEXT;
constexpr AtkRole kSuperscriptRole = ATK_ROLE_TEXT;
#endif

#if defined(ATK_226)
constexpr AtkRole kAtkFootnoteRole = ATK_ROLE_FOOTNOTE;
#else
constexpr AtkRole kAtkFootnoteRole = ATK_ROLE_LIST_ITEM;
#endif

#if defined(ATK_234)
constexpr AtkRole kAtkRoleContentDeletion = ATK_ROLE_CONTENT_DELETION;
constexpr AtkRole kAtkRoleContentInsertion = ATK_ROLE_CONTENT_INSERTION;
#else
constexpr AtkRole kAtkRoleContentDeletion = ATK_ROLE_SECTION;
constexpr AtkRole kAtkRoleContentInsertion = ATK_ROLE_SECTION;
#endif

using GetTypeFunc = GType (*)();
using GetColumnHeaderCellsFunc = GPtrArray* (*)(AtkTableCell* cell);
using GetRowHeaderCellsFunc = GPtrArray* (*)(AtkTableCell* cell);
using GetRowColumnSpanFunc = bool (*)(AtkTableCell* cell,
                                      gint* row,
                                      gint* column,
                                      gint* row_span,
                                      gint* col_span);

static GetTypeFunc g_atk_table_cell_get_type;
static GetColumnHeaderCellsFunc g_atk_table_cell_get_column_header_cells;
static GetRowHeaderCellsFunc g_atk_table_cell_get_row_header_cells;
static GetRowColumnSpanFunc g_atk_table_cell_get_row_column_span;

// The ATK API often requires pointers to be used as out arguments, while
// allowing for those pointers to be null if the caller is not interested in
// the value. This function is a simpler helper to avoid continually checking
// for null and to help prevent forgetting to check for null.
void SetIntPointerValueIfNotNull(int* pointer, int value) {
  if (pointer)
    *pointer = value;
}

#if defined(ATK_230)
bool SupportsAtkComponentScrollingInterface() {
  return dlsym(RTLD_DEFAULT, "atk_component_scroll_to_point");
}
#endif

#if defined(ATK_232)
bool SupportsAtkTextScrollingInterface() {
  return dlsym(RTLD_DEFAULT, "atk_text_scroll_substring_to_point");
}
#endif

AtkObject* FindAtkObjectParentFrame(AtkObject* atk_object) {
  AXPlatformNodeAuraLinux* node =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  while (node) {
    if (node->GetAtkRole() == ATK_ROLE_FRAME)
      return node->GetNativeViewAccessible();
    node = AXPlatformNodeAuraLinux::FromAtkObject(node->GetParent());
  }
  return nullptr;
}

AtkObject* FindAtkObjectToplevelParentDocument(AtkObject* atk_object) {
  AXPlatformNodeAuraLinux* node =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  AtkObject* toplevel_document = nullptr;
  while (node) {
    if (node->GetAtkRole() == ATK_ROLE_DOCUMENT_WEB)
      toplevel_document = node->GetNativeViewAccessible();
    node = AXPlatformNodeAuraLinux::FromAtkObject(node->GetParent());
  }
  return toplevel_document;
}

bool IsFrameAncestorOfAtkObject(AtkObject* frame, AtkObject* atk_object) {
  AtkObject* current_frame = FindAtkObjectParentFrame(atk_object);
  while (current_frame) {
    if (current_frame == frame)
      return true;
    AXPlatformNodeAuraLinux* frame_node =
        AXPlatformNodeAuraLinux::FromAtkObject(current_frame);
    current_frame = FindAtkObjectParentFrame(frame_node->GetParent());
  }
  return false;
}

// Returns a stack of AtkObjects of activated popup menus. Since each popup
// menu and submenu has its own native window, we want to properly manage the
// activated state for their containing frames.
std::vector<AtkObject*>& GetActiveMenus() {
  static base::NoDestructor<std::vector<AtkObject*>> active_menus;
  return *active_menus;
}

std::map<AtkObject*, FindInPageResultInfo>& GetActiveFindInPageResults() {
  static base::NoDestructor<std::map<AtkObject*, FindInPageResultInfo>>
      active_results;
  return *active_results;
}

// The currently active frame is g_active_top_level_frame, unless there is an
// active menu. If there is an active menu the parent frame of the
// most-recently opened active menu should be the currently active frame.
AtkObject* ComputeActiveTopLevelFrame() {
  if (!GetActiveMenus().empty())
    return FindAtkObjectParentFrame(GetActiveMenus().back());
  return g_active_top_level_frame;
}

const char* GetUniqueAccessibilityGTypeName(
    ImplementedAtkInterfaces interface_mask) {
  // 37 characters is enough for "AXPlatformNodeAuraLinux%x" with any integer
  // value.
  static char name[37];
  snprintf(name, sizeof(name), "AXPlatformNodeAuraLinux%x",
           interface_mask.value());
  return name;
}

void SetWeakGPtrToAtkObject(AtkObject** weak_pointer, AtkObject* new_value) {
  DCHECK(weak_pointer);
  if (*weak_pointer == new_value)
    return;

  if (*weak_pointer) {
    g_object_remove_weak_pointer(G_OBJECT(*weak_pointer),
                                 reinterpret_cast<void**>(weak_pointer));
  }

  *weak_pointer = new_value;

  if (new_value) {
    g_object_add_weak_pointer(G_OBJECT(new_value),
                              reinterpret_cast<void**>(weak_pointer));
  }
}

void SetActiveTopLevelFrame(AtkObject* new_top_level_frame) {
  SetWeakGPtrToAtkObject(&g_active_top_level_frame, new_top_level_frame);
}

AXCoordinateSystem AtkCoordTypeToAXCoordinateSystem(
    AtkCoordType coordinate_type) {
  switch (coordinate_type) {
    case ATK_XY_SCREEN:
      return AXCoordinateSystem::kScreenDIPs;
    case ATK_XY_WINDOW:
      return AXCoordinateSystem::kRootFrame;
#if defined(ATK_230)
    case ATK_XY_PARENT:
      // AXCoordinateSystem does not support parent coordinates.
      NOTIMPLEMENTED();
      return AXCoordinateSystem::kFrame;
#endif
    default:
      return AXCoordinateSystem::kScreenDIPs;
  }
}

const char* BuildDescriptionFromHeaders(AXPlatformNodeDelegate* delegate,
                                        const std::vector<int32_t>& ids) {
  std::vector<std::string> names;
  for (const auto& node_id : ids) {
    if (AXPlatformNode* header = delegate->GetFromNodeID(node_id)) {
      if (AtkObject* atk_header = header->GetNativeViewAccessible())
        names.push_back(atk_object_get_name(atk_header));
    }
  }

  std::string result = base::JoinString(names, " ");

#if defined(LEAK_SANITIZER) && !defined(OS_NACL)
  // http://crbug.com/982839
  // atk_table_get_column_description and atk_table_get_row_description return
  // const gchar*, which suggests the caller does not gain ownership of the
  // returned string. The g_strdup below causes a new allocation, which does not
  // fit that pattern and causes a leak in tests.
  ScopedLeakSanitizerDisabler lsan_disabler;
#endif

  return g_strdup(result.c_str());
}

gfx::Point FindAtkObjectParentCoords(AtkObject* atk_object) {
  if (!atk_object)
    return gfx::Point(0, 0);

  AXPlatformNodeAuraLinux* node =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (node->GetAtkRole() == ATK_ROLE_FRAME) {
    int x, y;
    atk_component_get_extents(ATK_COMPONENT(atk_object), &x, &y, nullptr,
                              nullptr, ATK_XY_WINDOW);
    gfx::Point window_coords(x, y);
    return window_coords;
  }
  atk_object = node->GetParent();

  return FindAtkObjectParentCoords(atk_object);
}

AtkAttributeSet* PrependAtkAttributeToAtkAttributeSet(
    const char* name,
    const char* value,
    AtkAttributeSet* attribute_set) {
  AtkAttribute* attribute =
      static_cast<AtkAttribute*>(g_malloc(sizeof(AtkAttribute)));
  attribute->name = g_strdup(name);
  attribute->value = g_strdup(value);
  return g_slist_prepend(attribute_set, attribute);
}

AtkObject* GetActiveDescendantOfCurrentFocused() {
  if (!g_current_focused)
    return nullptr;

  auto* node = AXPlatformNodeAuraLinux::FromAtkObject(g_current_focused);
  if (!node)
    return nullptr;

  int32_t id =
      node->GetIntAttribute(ax::mojom::IntAttribute::kActivedescendantId);
  if (auto* descendant = node->GetDelegate()->GetFromNodeID(id))
    return descendant->GetNativeViewAccessible();

  return nullptr;
}

void PrependTextAttributeToSet(const std::string& attribute,
                               const std::string& value,
                               AtkAttributeSet** attributes) {
  DCHECK(attributes);

  AtkAttribute* new_attribute =
      static_cast<AtkAttribute*>(g_malloc(sizeof(AtkAttribute)));
  new_attribute->name = g_strdup(attribute.c_str());
  new_attribute->value = g_strdup(value.c_str());
  *attributes = g_slist_prepend(*attributes, new_attribute);
}

void PrependAtkTextAttributeToSet(const AtkTextAttribute attribute,
                                  const std::string& value,
                                  AtkAttributeSet** attributes) {
  PrependTextAttributeToSet(atk_text_attribute_get_name(attribute), value,
                            attributes);
}

std::string ToAtkTextAttributeColor(const std::string color) {
  // The platform-independent color string is in the form "rgb(r, g, b)",
  // but ATK expects a string like "r, g, b". We convert the string here
  // by stripping away the unnecessary characters.
  DCHECK(base::StartsWith(color, "rgb(", base::CompareCase::INSENSITIVE_ASCII));
  DCHECK(base::EndsWith(color, ")", base::CompareCase::INSENSITIVE_ASCII));
  return color.substr(4, color.length() - 5);
}

AtkAttributeSet* ToAtkAttributeSet(const TextAttributeList& attributes) {
  AtkAttributeSet* copied_attributes = nullptr;
  for (const auto& attribute : attributes) {
    if (attribute.first == "background-color") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_BG_COLOR,
                                   ToAtkTextAttributeColor(attribute.second),
                                   &copied_attributes);
    } else if (attribute.first == "color") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_FG_COLOR,
                                   ToAtkTextAttributeColor(attribute.second),
                                   &copied_attributes);
    } else if (attribute.first == "font-family") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_FAMILY_NAME, attribute.second,
                                   &copied_attributes);
    } else if (attribute.first == "font-size") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_SIZE, attribute.second,
                                   &copied_attributes);
    } else if (attribute.first == "font-weight" && attribute.second == "bold") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_WEIGHT, "700",
                                   &copied_attributes);
    } else if (attribute.first == "font-style") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_STYLE, "italic",
                                   &copied_attributes);
    } else if (attribute.first == "text-line-through-style") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_STRIKETHROUGH, "true",
                                   &copied_attributes);
    } else if (attribute.first == "text-underline-style") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_UNDERLINE, "single",
                                   &copied_attributes);
    } else if (attribute.first == "invalid") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_INVALID, attribute.second,
                                   &copied_attributes);
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_UNDERLINE, "error",
                                   &copied_attributes);
    } else if (attribute.first == "language") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_LANGUAGE, attribute.second,
                                   &copied_attributes);
    } else if (attribute.first == "writing-mode") {
      PrependAtkTextAttributeToSet(ATK_TEXT_ATTR_DIRECTION, attribute.second,
                                   &copied_attributes);
    } else if (attribute.first == "text-position") {
      PrependTextAttributeToSet(attribute.first, attribute.second,
                                &copied_attributes);
    }
  }

  return g_slist_reverse(copied_attributes);
}

namespace atk_component {

void GetExtents(AtkComponent* atk_component,
                gint* x,
                gint* y,
                gint* width,
                gint* height,
                AtkCoordType coord_type) {
  g_return_if_fail(ATK_IS_COMPONENT(atk_component));

  if (x)
    *x = 0;
  if (y)
    *y = 0;
  if (width)
    *width = 0;
  if (height)
    *height = 0;

  AtkObject* atk_object = ATK_OBJECT(atk_component);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetExtents(x, y, width, height, coord_type);
}

void GetPosition(AtkComponent* atk_component,
                 gint* x,
                 gint* y,
                 AtkCoordType coord_type) {
  g_return_if_fail(ATK_IS_COMPONENT(atk_component));

  if (x)
    *x = 0;
  if (y)
    *y = 0;

  AtkObject* atk_object = ATK_OBJECT(atk_component);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetPosition(x, y, coord_type);
}

void GetSize(AtkComponent* atk_component, gint* width, gint* height) {
  g_return_if_fail(ATK_IS_COMPONENT(atk_component));

  if (width)
    *width = 0;
  if (height)
    *height = 0;

  AtkObject* atk_object = ATK_OBJECT(atk_component);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetSize(width, height);
}

AtkObject* RefAccesibleAtPoint(AtkComponent* atk_component,
                               gint x,
                               gint y,
                               AtkCoordType coord_type) {
  g_return_val_if_fail(ATK_IS_COMPONENT(atk_component), nullptr);
  AtkObject* atk_object = ATK_OBJECT(atk_component);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  AtkObject* result = obj->HitTestSync(x, y, coord_type);
  if (result)
    g_object_ref(result);
  return result;
}

gboolean GrabFocus(AtkComponent* atk_component) {
  g_return_val_if_fail(ATK_IS_COMPONENT(atk_component), FALSE);
  AtkObject* atk_object = ATK_OBJECT(atk_component);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return FALSE;

  return obj->GrabFocus();
}

#if defined(ATK_230)
gboolean ScrollTo(AtkComponent* atk_component, AtkScrollType scroll_type) {
  g_return_val_if_fail(ATK_IS_COMPONENT(atk_component), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_component));
  if (!obj)
    return FALSE;

  obj->ScrollNodeIntoView(scroll_type);
  return TRUE;
}

gboolean ScrollToPoint(AtkComponent* atk_component,
                       AtkCoordType atk_coord_type,
                       gint x,
                       gint y) {
  g_return_val_if_fail(ATK_IS_COMPONENT(atk_component), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_component));
  if (!obj)
    return FALSE;

  obj->ScrollToPoint(atk_coord_type, x, y);
  return TRUE;
}
#endif

void Init(AtkComponentIface* iface) {
  iface->get_extents = GetExtents;
  iface->get_position = GetPosition;
  iface->get_size = GetSize;
  iface->ref_accessible_at_point = RefAccesibleAtPoint;
  iface->grab_focus = GrabFocus;
#if defined(ATK_230)
  if (SupportsAtkComponentScrollingInterface()) {
    iface->scroll_to = ScrollTo;
    iface->scroll_to_point = ScrollToPoint;
  }
#endif
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_component

namespace atk_action {

gboolean DoAction(AtkAction* atk_action, gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), FALSE);
  g_return_val_if_fail(!index, FALSE);

  AtkObject* atk_object = ATK_OBJECT(atk_action);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return FALSE;

  return obj->DoDefaultAction();
}

gint GetNActions(AtkAction* atk_action) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), 0);

  AtkObject* atk_object = ATK_OBJECT(atk_action);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return 0;

  return 1;
}

const gchar* GetDescription(AtkAction*, gint) {
  // Not implemented. Right now Orca does not provide this and
  // Chromium is not providing a string for the action description.
  return nullptr;
}

const gchar* GetName(AtkAction* atk_action, gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), nullptr);
  g_return_val_if_fail(!index, nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_action);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetDefaultActionName();
}

const gchar* GetKeybinding(AtkAction* atk_action, gint index) {
  g_return_val_if_fail(ATK_IS_ACTION(atk_action), nullptr);
  g_return_val_if_fail(!index, nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_action);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetStringAttribute(ax::mojom::StringAttribute::kAccessKey)
      .c_str();
}

void Init(AtkActionIface* iface) {
  iface->do_action = DoAction;
  iface->get_n_actions = GetNActions;
  iface->get_description = GetDescription;
  iface->get_name = GetName;
  iface->get_keybinding = GetKeybinding;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_action

namespace atk_document {

const gchar* GetDocumentAttributeValue(AtkDocument* atk_doc,
                                       const gchar* attribute) {
  g_return_val_if_fail(ATK_IS_DOCUMENT(atk_doc), nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_doc);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetDocumentAttributeValue(attribute);
}

AtkAttributeSet* GetDocumentAttributes(AtkDocument* atk_doc) {
  g_return_val_if_fail(ATK_IS_DOCUMENT(atk_doc), 0);

  AtkObject* atk_object = ATK_OBJECT(atk_doc);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetDocumentAttributes();
}

void Init(AtkDocumentIface* iface) {
  iface->get_document_attribute_value = GetDocumentAttributeValue;
  iface->get_document_attributes = GetDocumentAttributes;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_document

namespace atk_image {

void GetImagePosition(AtkImage* atk_img,
                      gint* x,
                      gint* y,
                      AtkCoordType coord_type) {
  g_return_if_fail(ATK_IMAGE(atk_img));

  AtkObject* atk_object = ATK_OBJECT(atk_img);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetPosition(x, y, coord_type);
}

const gchar* GetImageDescription(AtkImage* atk_img) {
  g_return_val_if_fail(ATK_IMAGE(atk_img), nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_img);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetStringAttribute(ax::mojom::StringAttribute::kDescription)
      .c_str();
}

void GetImageSize(AtkImage* atk_img, gint* width, gint* height) {
  g_return_if_fail(ATK_IMAGE(atk_img));

  AtkObject* atk_object = ATK_OBJECT(atk_img);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetSize(width, height);
}

void Init(AtkImageIface* iface) {
  iface->get_image_position = GetImagePosition;
  iface->get_image_description = GetImageDescription;
  iface->get_image_size = GetImageSize;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_image

namespace atk_value {

void GetCurrentValue(AtkValue* atk_value, GValue* value) {
  g_return_if_fail(ATK_IS_VALUE(atk_value));

  AtkObject* atk_object = ATK_OBJECT(atk_value);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetFloatAttributeInGValue(ax::mojom::FloatAttribute::kValueForRange,
                                 value);
}

void GetMinimumValue(AtkValue* atk_value, GValue* value) {
  g_return_if_fail(ATK_IS_VALUE(atk_value));

  AtkObject* atk_object = ATK_OBJECT(atk_value);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetFloatAttributeInGValue(ax::mojom::FloatAttribute::kMinValueForRange,
                                 value);
}

void GetMaximumValue(AtkValue* atk_value, GValue* value) {
  g_return_if_fail(ATK_IS_VALUE(atk_value));

  AtkObject* atk_object = ATK_OBJECT(atk_value);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetFloatAttributeInGValue(ax::mojom::FloatAttribute::kMaxValueForRange,
                                 value);
}

void GetMinimumIncrement(AtkValue* atk_value, GValue* value) {
  g_return_if_fail(ATK_IS_VALUE(atk_value));

  AtkObject* atk_object = ATK_OBJECT(atk_value);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return;

  obj->GetFloatAttributeInGValue(ax::mojom::FloatAttribute::kStepValueForRange,
                                 value);
}

gboolean SetCurrentValue(AtkValue* atk_value, const GValue* value) {
  g_return_val_if_fail(ATK_IS_VALUE(atk_value), FALSE);

  AtkObject* atk_object = ATK_OBJECT(atk_value);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return FALSE;

  std::string new_value;
  switch (G_VALUE_TYPE(value)) {
    case G_TYPE_FLOAT:
      new_value = base::NumberToString(g_value_get_float(value));
      break;
    case G_TYPE_INT:
      new_value = base::NumberToString(g_value_get_int(value));
      break;
    case G_TYPE_INT64:
      new_value = base::NumberToString(g_value_get_int64(value));
      break;
    case G_TYPE_STRING:
      new_value = g_value_get_string(value);
      break;
    default:
      return FALSE;
  }

  AXActionData data;
  data.action = ax::mojom::Action::kSetValue;
  data.value = new_value;
  obj->GetDelegate()->AccessibilityPerformAction(data);
  return TRUE;
}

void Init(AtkValueIface* iface) {
  iface->get_current_value = GetCurrentValue;
  iface->get_maximum_value = GetMaximumValue;
  iface->get_minimum_value = GetMinimumValue;
  iface->get_minimum_increment = GetMinimumIncrement;
  iface->set_current_value = SetCurrentValue;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_value

namespace atk_hyperlink {

AtkHyperlink* GetHyperlink(AtkHyperlinkImpl* atk_hyperlink_impl) {
  g_return_val_if_fail(ATK_HYPERLINK_IMPL(atk_hyperlink_impl), 0);

  AtkObject* atk_object = ATK_OBJECT(atk_hyperlink_impl);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return 0;

  AtkHyperlink* atk_hyperlink = obj->GetAtkHyperlink();
  g_object_ref(atk_hyperlink);

  return atk_hyperlink;
}

void Init(AtkHyperlinkImplIface* iface) {
  iface->get_hyperlink = GetHyperlink;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_hyperlink

namespace atk_hypertext {

AtkHyperlink* GetLink(AtkHypertext* hypertext, int index) {
  g_return_val_if_fail(ATK_HYPERTEXT(hypertext), 0);
  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(hypertext));
  if (!obj)
    return nullptr;

  const AXHypertext& ax_hypertext = obj->GetAXHypertext();
  if (index > static_cast<int>(ax_hypertext.hyperlinks.size()) || index < 0)
    return nullptr;

  int32_t id = ax_hypertext.hyperlinks[index];
  auto* link = static_cast<AXPlatformNodeAuraLinux*>(
      AXPlatformNodeBase::GetFromUniqueId(id));
  if (!link)
    return nullptr;

  return link->GetAtkHyperlink();
}

int GetNLinks(AtkHypertext* hypertext) {
  g_return_val_if_fail(ATK_HYPERTEXT(hypertext), 0);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(hypertext));
  return obj ? obj->GetAXHypertext().hyperlinks.size() : 0;
}

int GetLinkIndex(AtkHypertext* hypertext, int char_index) {
  g_return_val_if_fail(ATK_HYPERTEXT(hypertext), 0);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(hypertext));
  if (!obj)
    return -1;

  auto it = obj->GetAXHypertext().hyperlink_offset_to_index.find(char_index);
  if (it == obj->GetAXHypertext().hyperlink_offset_to_index.end())
    return -1;
  return it->second;
}

void Init(AtkHypertextIface* iface) {
  iface->get_link = GetLink;
  iface->get_n_links = GetNLinks;
  iface->get_link_index = GetLinkIndex;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_hypertext

namespace atk_text {

gchar* GetText(AtkText* atk_text, gint start_offset, gint end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  base::string16 text = obj->GetHypertext();

  start_offset = obj->UnicodeToUTF16OffsetInText(start_offset);
  if (start_offset < 0 || start_offset >= static_cast<int>(text.size()))
    return nullptr;

  if (end_offset < 0) {
    end_offset = text.size();
  } else {
    end_offset = obj->UnicodeToUTF16OffsetInText(end_offset);
    end_offset = base::ClampToRange(int{text.size()}, start_offset, end_offset);
  }

  DCHECK_GE(start_offset, 0);
  DCHECK_GE(end_offset, start_offset);

  return g_strdup(
      base::UTF16ToUTF8(text.substr(start_offset, end_offset - start_offset))
          .c_str());
}

gint GetCharacterCount(AtkText* atk_text) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), 0);

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return 0;

  return obj->UTF16ToUnicodeOffsetInText(obj->GetHypertext().length());
}

gunichar GetCharacterAtOffset(AtkText* atk_text, int offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), 0);

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return 0;

  base::string16 text = obj->GetHypertext();
  int32_t text_length = text.length();

  offset = obj->UnicodeToUTF16OffsetInText(offset);
  int32_t limited_offset = base::ClampToRange(offset, 0, text_length);

  uint32_t code_point;
  base::ReadUnicodeCharacter(text.c_str(), text_length + 1, &limited_offset,
                             &code_point);
  return code_point;
}

gint GetOffsetAtPoint(AtkText* text, gint x, gint y, AtkCoordType coords) {
  g_return_val_if_fail(ATK_IS_TEXT(text), -1);

  AtkObject* atk_object = ATK_OBJECT(text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return -1;

  return obj->GetTextOffsetAtPoint(x, y, coords);
}

// This function returns a single character as a UTF-8 encoded C string because
// the character may be encoded into more than one byte.
char* GetCharacter(AtkText* atk_text,
                   int offset,
                   int* start_offset,
                   int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  *start_offset = -1;
  *end_offset = -1;

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  if (offset < 0 || offset >= GetCharacterCount(atk_text))
    return nullptr;

  char* text = GetText(atk_text, offset, offset + 1);
  if (!text)
    return nullptr;

  *start_offset = offset;
  *end_offset = offset + 1;
  return text;
}

char* GetTextWithBoundaryType(AtkText* atk_text,
                              int offset,
                              ax::mojom::TextBoundary boundary,
                              int* start_offset_ptr,
                              int* end_offset_ptr) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  if (offset < 0 || offset >= atk_text_get_character_count(atk_text))
    return nullptr;

  // The offset that we receive from the API is a Unicode character offset.
  // Since we calculate boundaries in terms of UTF-16 code point offsets, we
  // need to convert this input value.
  offset = obj->UnicodeToUTF16OffsetInText(offset);

  int start_offset = obj->FindTextBoundary(
      boundary, offset, ax::mojom::MoveDirection::kBackward,
      ax::mojom::TextAffinity::kDownstream);
  int end_offset = obj->FindTextBoundary(boundary, offset,
                                         ax::mojom::MoveDirection::kForward,
                                         ax::mojom::TextAffinity::kDownstream);
  if (start_offset < 0 || end_offset < 0)
    return nullptr;

  DCHECK_LE(start_offset, end_offset)
      << "Start offset should be less than or equal the end offset.";

  // The ATK API is also expecting Unicode character offsets as output
  // values.
  *start_offset_ptr = obj->UTF16ToUnicodeOffsetInText(start_offset);
  *end_offset_ptr = obj->UTF16ToUnicodeOffsetInText(end_offset);

  base::string16 text = obj->GetHypertext();
  DCHECK_LE(end_offset, static_cast<int>(text.size()));

  base::string16 substr = text.substr(start_offset, end_offset - start_offset);
  return g_strdup(base::UTF16ToUTF8(substr).c_str());
}

char* GetTextAtOffset(AtkText* atk_text,
                      int offset,
                      AtkTextBoundary atk_boundary,
                      int* start_offset,
                      int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);
  ax::mojom::TextBoundary boundary = FromAtkTextBoundary(atk_boundary);
  return GetTextWithBoundaryType(atk_text, offset, boundary, start_offset,
                                 end_offset);
}

char* GetTextAfterOffset(AtkText* atk_text,
                         int offset,
                         AtkTextBoundary boundary,
                         int* start_offset,
                         int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  if (boundary != ATK_TEXT_BOUNDARY_CHAR) {
    *start_offset = -1;
    *end_offset = -1;
    return nullptr;
  }

  // ATK does not offer support for the special negative index and we don't
  // want to do arithmetic on that value below.
  if (offset == kStringLengthOffset)
    return nullptr;

  return GetCharacter(atk_text, offset + 1, start_offset, end_offset);
}

char* GetTextBeforeOffset(AtkText* atk_text,
                          int offset,
                          AtkTextBoundary boundary,
                          int* start_offset,
                          int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  if (boundary != ATK_TEXT_BOUNDARY_CHAR) {
    *start_offset = -1;
    *end_offset = -1;
    return nullptr;
  }

  // ATK does not offer support for the special negative index and we don't
  // want to do arithmetic on that value below.
  if (offset == kStringLengthOffset)
    return nullptr;

  return GetCharacter(atk_text, offset - 1, start_offset, end_offset);
}

gint GetCaretOffset(AtkText* atk_text) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), -1);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return -1;
  return obj->GetCaretOffset();
}

gboolean SetCaretOffset(AtkText* atk_text, gint offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return FALSE;
  if (!obj->SetCaretOffset(offset))
    return FALSE;

  // Orca expects atk_text_set_caret_offset to either focus the target element
  // or set the sequential focus navigation starting point there.
  int utf16_offset = obj->UnicodeToUTF16OffsetInText(offset);
  obj->GrabFocusOrSetSequentialFocusNavigationStartingPointAtOffset(
      utf16_offset);

  return TRUE;
}

int GetNSelections(AtkText* atk_text) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), 0);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return 0;

  if (obj->HasSelection())
    return 1;

  base::Optional<FindInPageResultInfo> result =
      obj->GetSelectionOffsetsFromFindInPage();
  if (result.has_value() && result->node == ATK_OBJECT(atk_text))
    return 1;

  return 0;
}

gchar* GetSelection(AtkText* atk_text,
                    int selection_num,
                    int* start_offset,
                    int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return nullptr;
  if (selection_num != 0)
    return nullptr;

  return obj->GetSelectionWithText(start_offset, end_offset);
}

gboolean RemoveSelection(AtkText* atk_text, int selection_num) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  if (selection_num != 0)
    return FALSE;

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return FALSE;

  // Simply collapse the selection to the position of the caret if a caret is
  // visible, otherwise set the selection to 0.
  int selection_end = obj->UTF16ToUnicodeOffsetInText(
      obj->GetIntAttribute(ax::mojom::IntAttribute::kTextSelEnd));
  return SetCaretOffset(atk_text, selection_end);
}

gboolean SetSelection(AtkText* atk_text,
                      int selection_num,
                      int start_offset,
                      int end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  if (selection_num != 0)
    return FALSE;

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return FALSE;

  return obj->SetTextSelectionForAtkText(start_offset, end_offset);
}

gboolean AddSelection(AtkText* atk_text, int start_offset, int end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  // We only support one selection.
  return SetSelection(atk_text, 0, start_offset, end_offset);
}

#if defined(ATK_210)
char* GetStringAtOffset(AtkText* atk_text,
                        int offset,
                        AtkTextGranularity atk_granularity,
                        int* start_offset,
                        int* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  *start_offset = -1;
  *end_offset = -1;

  ax::mojom::TextBoundary boundary = FromAtkTextGranularity(atk_granularity);
  return GetTextWithBoundaryType(atk_text, offset, boundary, start_offset,
                                 end_offset);
}
#endif

#if defined(ATK_230)
gfx::Rect GetUnclippedParentHypertextRangeBoundsRect(
    AXPlatformNodeDelegate* ax_platform_node_delegate,
    const int start_offset,
    const int end_offset) {
  const AXPlatformNode* parent_platform_node =
      AXPlatformNode::FromNativeViewAccessible(
          ax_platform_node_delegate->GetParent());
  if (!parent_platform_node)
    return gfx::Rect();

  const AXPlatformNodeDelegate* parent_ax_platform_node_delegate =
      parent_platform_node->GetDelegate();
  if (!parent_ax_platform_node_delegate)
    return gfx::Rect();

  return ax_platform_node_delegate->GetHypertextRangeBoundsRect(
             start_offset, end_offset, AXCoordinateSystem::kRootFrame,
             AXClippingBehavior::kUnclipped) -
         parent_ax_platform_node_delegate
             ->GetBoundsRect(AXCoordinateSystem::kRootFrame,
                             AXClippingBehavior::kClipped)
             .OffsetFromOrigin();
}
#endif

void GetCharacterExtents(AtkText* atk_text,
                         int offset,
                         int* x,
                         int* y,
                         int* width,
                         int* height,
                         AtkCoordType coordinate_type) {
  g_return_if_fail(ATK_IS_TEXT(atk_text));

  gfx::Rect rect;
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (obj) {
    switch (coordinate_type) {
#if defined(ATK_230)
      case ATK_XY_PARENT:
        rect = GetUnclippedParentHypertextRangeBoundsRect(obj->GetDelegate(),
                                                          offset, offset + 1);
        break;
#endif
      default:
        rect = obj->GetDelegate()->GetHypertextRangeBoundsRect(
            obj->UnicodeToUTF16OffsetInText(offset),
            obj->UnicodeToUTF16OffsetInText(offset + 1),
            AtkCoordTypeToAXCoordinateSystem(coordinate_type),
            AXClippingBehavior::kUnclipped);
        break;
    }
  }

  if (x)
    *x = rect.x();
  if (y)
    *y = rect.y();
  if (width)
    *width = rect.width();
  if (height)
    *height = rect.height();
}

void GetRangeExtents(AtkText* atk_text,
                     int start_offset,
                     int end_offset,
                     AtkCoordType coordinate_type,
                     AtkTextRectangle* out_rectangle) {
  g_return_if_fail(ATK_IS_TEXT(atk_text));

  if (!out_rectangle)
    return;

  gfx::Rect rect;
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (obj) {
    switch (coordinate_type) {
#if defined(ATK_230)
      case ATK_XY_PARENT:
        rect = GetUnclippedParentHypertextRangeBoundsRect(
            obj->GetDelegate(), start_offset, end_offset);
        break;
#endif
      default:
        rect = obj->GetDelegate()->GetHypertextRangeBoundsRect(
            obj->UnicodeToUTF16OffsetInText(start_offset),
            obj->UnicodeToUTF16OffsetInText(end_offset),
            AtkCoordTypeToAXCoordinateSystem(coordinate_type),
            AXClippingBehavior::kUnclipped);
        break;
    }
  }

  out_rectangle->x = rect.x();
  out_rectangle->y = rect.y();
  out_rectangle->width = rect.width();
  out_rectangle->height = rect.height();
}

AtkAttributeSet* GetRunAttributes(AtkText* atk_text,
                                  gint offset,
                                  gint* start_offset,
                                  gint* end_offset) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  SetIntPointerValueIfNotNull(start_offset, -1);
  SetIntPointerValueIfNotNull(end_offset, -1);

  if (offset < 0 || offset > GetCharacterCount(atk_text))
    return nullptr;

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return ToAtkAttributeSet(
      obj->GetTextAttributes(offset, start_offset, end_offset));
}

AtkAttributeSet* GetDefaultAttributes(AtkText* atk_text) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), nullptr);

  AtkObject* atk_object = ATK_OBJECT(atk_text);
  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;
  return ToAtkAttributeSet(obj->GetDefaultTextAttributes());
}

#if defined(ATK_232)
gboolean ScrollSubstringTo(AtkText* atk_text,
                           gint start_offset,
                           gint end_offset,
                           AtkScrollType scroll_type) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return FALSE;

  return obj->ScrollSubstringIntoView(scroll_type, start_offset, end_offset);
}

gboolean ScrollSubstringToPoint(AtkText* atk_text,
                                gint start_offset,
                                gint end_offset,
                                AtkCoordType atk_coord_type,
                                gint x,
                                gint y) {
  g_return_val_if_fail(ATK_IS_TEXT(atk_text), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(atk_text));
  if (!obj)
    return FALSE;

  return obj->ScrollSubstringToPoint(start_offset, end_offset, atk_coord_type,
                                     x, y);
}
#endif  // ATK_232

void Init(AtkTextIface* iface) {
  iface->get_text = GetText;
  iface->get_character_count = GetCharacterCount;
  iface->get_character_at_offset = GetCharacterAtOffset;
  iface->get_offset_at_point = GetOffsetAtPoint;
  iface->get_text_after_offset = GetTextAfterOffset;
  iface->get_text_before_offset = GetTextBeforeOffset;
  iface->get_text_at_offset = GetTextAtOffset;
  iface->get_caret_offset = GetCaretOffset;
  iface->set_caret_offset = SetCaretOffset;
  iface->get_character_extents = GetCharacterExtents;
  iface->get_range_extents = GetRangeExtents;
  iface->get_n_selections = GetNSelections;
  iface->get_selection = GetSelection;
  iface->add_selection = AddSelection;
  iface->remove_selection = RemoveSelection;
  iface->set_selection = SetSelection;

  iface->get_run_attributes = GetRunAttributes;
  iface->get_default_attributes = GetDefaultAttributes;

#if defined(ATK_210)
  iface->get_string_at_offset = GetStringAtOffset;
#endif

#if defined(ATK_232)
  if (SupportsAtkTextScrollingInterface()) {
    iface->scroll_substring_to = ScrollSubstringTo;
    iface->scroll_substring_to_point = ScrollSubstringToPoint;
  }
#endif
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_text

namespace atk_window {
void Init(AtkWindowIface* iface) {}
const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};
}  // namespace atk_window

namespace atk_selection {

gboolean AddSelection(AtkSelection* selection, gint index) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return FALSE;
  if (index < 0 || index >= obj->GetChildCount())
    return FALSE;

  AXPlatformNodeAuraLinux* child =
      AXPlatformNodeAuraLinux::FromAtkObject(obj->ChildAtIndex(index));
  if (!child)
    return FALSE;

  if (!child->SupportsSelectionWithAtkSelection())
    return FALSE;

  bool selected = child->GetBoolAttribute(ax::mojom::BoolAttribute::kSelected);
  if (selected)
    return TRUE;

  AXActionData data;
  data.action = ax::mojom::Action::kDoDefault;
  return child->GetDelegate()->AccessibilityPerformAction(data);
}

gboolean ClearSelection(AtkSelection* selection) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return FALSE;

  int child_count = obj->GetChildCount();
  bool success = true;
  for (int i = 0; i < child_count; ++i) {
    AXPlatformNodeAuraLinux* child =
        AXPlatformNodeAuraLinux::FromAtkObject(obj->ChildAtIndex(i));
    if (!child)
      continue;

    if (!child->SupportsSelectionWithAtkSelection())
      continue;

    bool selected =
        child->GetBoolAttribute(ax::mojom::BoolAttribute::kSelected);
    if (!selected)
      continue;

    AXActionData data;
    data.action = ax::mojom::Action::kDoDefault;
    success = success && child->GetDelegate()->AccessibilityPerformAction(data);
  }

  return success;
}

AtkObject* RefSelection(AtkSelection* selection, gint requested_child_index) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return nullptr;

  if (auto* selected_child = obj->GetSelectedItem(requested_child_index)) {
    if (AtkObject* atk_object = selected_child->GetNativeViewAccessible()) {
      g_object_ref(atk_object);
      return atk_object;
    }
  }

  return nullptr;
}

gint GetSelectionCount(AtkSelection* selection) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), 0);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return 0;

  return obj->GetSelectionCount();
}

gboolean IsChildSelected(AtkSelection* selection, gint index) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return FALSE;
  if (index < 0 || index >= obj->GetChildCount())
    return FALSE;

  AXPlatformNodeAuraLinux* child =
      AXPlatformNodeAuraLinux::FromAtkObject(obj->ChildAtIndex(index));
  return child && child->GetBoolAttribute(ax::mojom::BoolAttribute::kSelected);
}

gboolean RemoveSelection(AtkSelection* selection,
                         gint index_into_selected_children) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return FALSE;

  int child_count = obj->GetChildCount();
  for (int i = 0; i < child_count; ++i) {
    AXPlatformNodeAuraLinux* child =
        AXPlatformNodeAuraLinux::FromAtkObject(obj->ChildAtIndex(i));
    if (!child)
      continue;

    bool selected =
        child->GetBoolAttribute(ax::mojom::BoolAttribute::kSelected);
    if (selected && index_into_selected_children == 0) {
      if (!child->SupportsSelectionWithAtkSelection())
        return FALSE;

      AXActionData data;
      data.action = ax::mojom::Action::kDoDefault;
      return child->GetDelegate()->AccessibilityPerformAction(data);
    } else if (selected) {
      index_into_selected_children--;
    }
  }

  return FALSE;
}

gboolean SelectAllSelection(AtkSelection* selection) {
  g_return_val_if_fail(ATK_IS_SELECTION(selection), FALSE);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(selection));
  if (!obj)
    return FALSE;

  int child_count = obj->GetChildCount();
  bool success = true;
  for (int i = 0; i < child_count; ++i) {
    AXPlatformNodeAuraLinux* child =
        AXPlatformNodeAuraLinux::FromAtkObject(obj->ChildAtIndex(i));
    if (!child)
      continue;

    if (!child->SupportsSelectionWithAtkSelection())
      continue;

    bool selected =
        child->GetBoolAttribute(ax::mojom::BoolAttribute::kSelected);
    if (selected)
      continue;

    AXActionData data;
    data.action = ax::mojom::Action::kDoDefault;
    success = success && child->GetDelegate()->AccessibilityPerformAction(data);
  }

  return success;
}

void Init(AtkSelectionIface* iface) {
  iface->add_selection = AddSelection;
  iface->clear_selection = ClearSelection;
  iface->ref_selection = RefSelection;
  iface->get_selection_count = GetSelectionCount;
  iface->is_child_selected = IsChildSelected;
  iface->remove_selection = RemoveSelection;
  iface->select_all_selection = SelectAllSelection;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_selection

namespace atk_table {

AtkObject* RefAt(AtkTable* table, gint row, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (AXPlatformNodeBase* cell = obj->GetTableCell(row, column)) {
      if (AtkObject* atk_cell = cell->GetNativeViewAccessible()) {
        g_object_ref(atk_cell);
        return atk_cell;
      }
    }
  }

  return nullptr;
}

gint GetIndexAt(AtkTable* table, gint row, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), -1);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (const AXPlatformNodeBase* cell = obj->GetTableCell(row, column)) {
      DCHECK(cell->GetTableCellIndex().has_value());
      return cell->GetTableCellIndex().value();
    }
  }

  return -1;
}

gint GetColumnAtIndex(AtkTable* table, gint index) {
  g_return_val_if_fail(ATK_IS_TABLE(table), -1);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (const AXPlatformNodeBase* cell = obj->GetTableCell(index)) {
      DCHECK(cell->GetTableColumn().has_value());
      return cell->GetTableColumn().value();
    }
  }

  return -1;
}

gint GetRowAtIndex(AtkTable* table, gint index) {
  g_return_val_if_fail(ATK_IS_TABLE(table), -1);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (const AXPlatformNodeBase* cell = obj->GetTableCell(index)) {
      DCHECK(cell->GetTableRow().has_value());
      return cell->GetTableRow().value();
    }
  }

  return -1;
}

gint GetNColumns(AtkTable* table) {
  g_return_val_if_fail(ATK_IS_TABLE(table), 0);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    // If the object is not a table, we return 0.
    return obj->GetTableColumnCount().value_or(0);
  }

  return 0;
}

gint GetNRows(AtkTable* table) {
  g_return_val_if_fail(ATK_IS_TABLE(table), 0);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    // If the object is not a table, we return 0.
    return obj->GetTableRowCount().value_or(0);
  }

  return 0;
}

gint GetColumnExtentAt(AtkTable* table, gint row, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), 0);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (const AXPlatformNodeBase* cell = obj->GetTableCell(row, column)) {
      DCHECK(cell->GetTableColumnSpan().has_value());
      return cell->GetTableColumnSpan().value();
    }
  }

  return 0;
}

gint GetRowExtentAt(AtkTable* table, gint row, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), 0);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (const AXPlatformNodeBase* cell = obj->GetTableCell(row, column)) {
      DCHECK(cell->GetTableRowSpan().has_value());
      return cell->GetTableRowSpan().value();
    }
  }

  return 0;
}

AtkObject* GetColumnHeader(AtkTable* table, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table));
  if (!obj)
    return nullptr;

  // AtkTable supports only one column header object. So return the first one
  // we find. In the case of multiple headers, ATs can fall back on the column
  // description.
  std::vector<int32_t> ids = obj->GetDelegate()->GetColHeaderNodeIds(column);
  for (const auto& node_id : ids) {
    if (AXPlatformNode* header = obj->GetDelegate()->GetFromNodeID(node_id)) {
      if (AtkObject* atk_header = header->GetNativeViewAccessible()) {
        g_object_ref(atk_header);
        return atk_header;
      }
    }
  }

  return nullptr;
}

AtkObject* GetRowHeader(AtkTable* table, gint row) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table));
  if (!obj)
    return nullptr;

  // AtkTable supports only one row header object. So return the first one
  // we find. In the case of multiple headers, ATs can fall back on the row
  // description.
  std::vector<int32_t> ids = obj->GetDelegate()->GetRowHeaderNodeIds(row);
  for (const auto& node_id : ids) {
    if (AXPlatformNode* header = obj->GetDelegate()->GetFromNodeID(node_id)) {
      if (AtkObject* atk_header = header->GetNativeViewAccessible()) {
        g_object_ref(atk_header);
        return atk_header;
      }
    }
  }

  return nullptr;
}

AtkObject* GetCaption(AtkTable* table) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table))) {
    if (auto* caption = obj->GetTableCaption())
      return caption->GetNativeViewAccessible();
  }

  return nullptr;
}

const gchar* GetColumnDescription(AtkTable* table, gint column) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table));
  if (!obj)
    return nullptr;

  std::vector<int32_t> ids = obj->GetDelegate()->GetColHeaderNodeIds(column);
  return BuildDescriptionFromHeaders(obj->GetDelegate(), ids);
}

const gchar* GetRowDescription(AtkTable* table, gint row) {
  g_return_val_if_fail(ATK_IS_TABLE(table), nullptr);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(table));
  if (!obj)
    return nullptr;

  std::vector<int32_t> ids = obj->GetDelegate()->GetRowHeaderNodeIds(row);
  return BuildDescriptionFromHeaders(obj->GetDelegate(), ids);
}

void Init(AtkTableIface* iface) {
  iface->ref_at = RefAt;
  iface->get_index_at = GetIndexAt;
  iface->get_column_at_index = GetColumnAtIndex;
  iface->get_row_at_index = GetRowAtIndex;
  iface->get_n_columns = GetNColumns;
  iface->get_n_rows = GetNRows;
  iface->get_column_extent_at = GetColumnExtentAt;
  iface->get_row_extent_at = GetRowExtentAt;
  iface->get_column_header = GetColumnHeader;
  iface->get_row_header = GetRowHeader;
  iface->get_caption = GetCaption;
  iface->get_column_description = GetColumnDescription;
  iface->get_row_description = GetRowDescription;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_table

// The ATK table cell interface was added in ATK 2.12.
#if defined(ATK_212)

namespace atk_table_cell {

gint GetColumnSpan(AtkTableCell* cell) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()), 0);

  if (const AXPlatformNodeBase* obj =
          AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell))) {
    // If the object is not a cell, we return 0.
    return obj->GetTableColumnSpan().value_or(0);
  }

  return 0;
}

GPtrArray* GetColumnHeaderCells(AtkTableCell* cell) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()),
      nullptr);

  GPtrArray* array = g_ptr_array_new_with_free_func(g_object_unref);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell));
  if (!obj)
    return array;

  // AtkTableCell is implemented on cells, row headers, and column headers.
  // Calling GetColHeaderNodeIds() on a column header cell will include that
  // column header, along with any other column headers in the column which
  // may or may not describe the header cell in question. Therefore, just return
  // headers for non-header cells.
  if (obj->GetAtkRole() != ATK_ROLE_TABLE_CELL)
    return array;

  base::Optional<int> col_index = obj->GetTableColumn();
  if (!col_index)
    return array;

  const std::vector<int32_t> ids =
      obj->GetDelegate()->GetColHeaderNodeIds(*col_index);
  for (const auto& node_id : ids) {
    if (AXPlatformNode* node = obj->GetDelegate()->GetFromNodeID(node_id)) {
      if (AtkObject* atk_node = node->GetNativeViewAccessible()) {
        g_ptr_array_add(array, g_object_ref(atk_node));
      }
    }
  }

  return array;
}

gboolean GetCellPosition(AtkTableCell* cell, gint* row, gint* column) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()),
      FALSE);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell))) {
    base::Optional<int> row_index = obj->GetTableRow();
    base::Optional<int> col_index = obj->GetTableColumn();
    if (!row_index || !col_index)
      return false;

    *row = *row_index;
    *column = *col_index;
    return true;
  }

  return false;
}

gint GetRowSpan(AtkTableCell* cell) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()), 0);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell))) {
    // If the object is not a cell, we return 0.
    return obj->GetTableRowSpan().value_or(0);
  }

  return 0;
}

GPtrArray* GetRowHeaderCells(AtkTableCell* cell) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()),
      nullptr);

  GPtrArray* array = g_ptr_array_new_with_free_func(g_object_unref);

  auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell));
  if (!obj)
    return array;

  // AtkTableCell is implemented on cells, row headers, and column headers.
  // Calling GetRowHeaderNodeIds() on a row header cell will include that
  // row header, along with any other row headers in the row which may or
  // may not describe the header cell in question. Therefore, just return
  // headers for non-header cells.
  if (obj->GetAtkRole() != ATK_ROLE_TABLE_CELL)
    return array;

  base::Optional<int> row_index = obj->GetTableRow();
  if (!row_index)
    return array;

  const std::vector<int32_t> ids =
      obj->GetDelegate()->GetRowHeaderNodeIds(*row_index);
  for (const auto& node_id : ids) {
    if (AXPlatformNode* node = obj->GetDelegate()->GetFromNodeID(node_id)) {
      if (AtkObject* atk_node = node->GetNativeViewAccessible()) {
        g_ptr_array_add(array, g_object_ref(atk_node));
      }
    }
  }

  return array;
}

AtkObject* GetTable(AtkTableCell* cell) {
  DCHECK(g_atk_table_cell_get_type);
  g_return_val_if_fail(
      G_TYPE_CHECK_INSTANCE_TYPE((cell), AtkTableCellInterface::GetType()),
      nullptr);

  if (auto* obj = AXPlatformNodeAuraLinux::FromAtkObject(ATK_OBJECT(cell))) {
    if (auto* table = obj->GetTable())
      return table->GetNativeViewAccessible();
  }

  return nullptr;
}

using AtkTableCellIface = struct _AtkTableCellIface;

void Init(AtkTableCellIface* iface) {
  iface->get_column_span = GetColumnSpan;
  iface->get_column_header_cells = GetColumnHeaderCells;
  iface->get_position = GetCellPosition;
  iface->get_row_span = GetRowSpan;
  iface->get_row_header_cells = GetRowHeaderCells;
  iface->get_table = GetTable;
}

const GInterfaceInfo Info = {reinterpret_cast<GInterfaceInitFunc>(Init),
                             nullptr, nullptr};

}  // namespace atk_table_cell

#endif  // ATK_212

namespace atk_object {

gpointer kAXPlatformNodeAuraLinuxParentClass = nullptr;

const gchar* GetName(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  if (!obj->IsNameExposed())
    return nullptr;

  ax::mojom::NameFrom name_from = obj->GetData().GetNameFrom();
  if (obj->GetName().empty() &&
      name_from != ax::mojom::NameFrom::kAttributeExplicitlyEmpty)
    return nullptr;

  obj->accessible_name_ = obj->GetName();
  return obj->accessible_name_.c_str();
}

const gchar* AtkGetName(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetName);
  return GetName(atk_object);
}

const gchar* GetDescription(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetStringAttribute(ax::mojom::StringAttribute::kDescription)
      .c_str();
}

const gchar* AtkGetDescription(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetDescription);
  return GetDescription(atk_object);
}

gint GetNChildren(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), 0);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return 0;

  return obj->GetChildCount();
}

gint AtkGetNChildren(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetNChildren);
  return GetNChildren(atk_object);
}

AtkObject* RefChild(AtkObject* atk_object, gint index) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  if (index < 0 || index >= obj->GetChildCount())
    return nullptr;

  AtkObject* result = obj->ChildAtIndex(index);
  if (result)
    g_object_ref(result);
  return result;
}

AtkObject* AtkRefChild(AtkObject* atk_object, gint index) {
  RecordAccessibilityAtkApi(UmaAtkApi::kRefChild);
  return RefChild(atk_object, index);
}

gint GetIndexInParent(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), -1);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return -1;

  return obj->GetIndexInParent().value_or(-1);
}

gint AtkGetIndexInParent(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetIndexInParent);
  return GetIndexInParent(atk_object);
}

AtkObject* GetParent(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetParent();
}

AtkObject* AtkGetParent(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetParent);
  return GetParent(atk_object);
}

AtkRelationSet* RefRelationSet(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return atk_relation_set_new();
  return obj->GetAtkRelations();
}

AtkRelationSet* AtkRefRelationSet(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kRefRelationSet);
  // Enables AX mode. Most AT does not call AtkRefRelationSet, but Orca does,
  // which is why it's a good signal to enable accessibility for Orca users
  // without too many false positives.
  AXPlatformNodeAuraLinux::EnableAXMode();
  return RefRelationSet(atk_object);
}

AtkAttributeSet* GetAttributes(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return nullptr;

  return obj->GetAtkAttributes();
}

AtkAttributeSet* AtkGetAttributes(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetAttributes);
  // Enables AX mode. Most AT does not call AtkGetAttributes, but Orca does,
  // which is why it's a good signal to enable accessibility for Orca users
  // without too many false positives.
  AXPlatformNodeAuraLinux::EnableAXMode();
  return GetAttributes(atk_object);
}

AtkRole GetRole(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), ATK_ROLE_INVALID);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj)
    return ATK_ROLE_INVALID;
  return obj->GetAtkRole();
}

AtkRole AtkGetRole(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kGetRole);
  return GetRole(atk_object);
}

AtkStateSet* RefStateSet(AtkObject* atk_object) {
  g_return_val_if_fail(ATK_IS_OBJECT(atk_object), nullptr);

  AtkStateSet* atk_state_set =
      ATK_OBJECT_CLASS(kAXPlatformNodeAuraLinuxParentClass)
          ->ref_state_set(atk_object);

  AXPlatformNodeAuraLinux* obj =
      AXPlatformNodeAuraLinux::FromAtkObject(atk_object);
  if (!obj) {
    atk_state_set_add_state(atk_state_set, ATK_STATE_DEFUNCT);
  } else {
    obj->GetAtkState(atk_state_set);
  }
  return atk_state_set;
}

AtkStateSet* AtkRefStateSet(AtkObject* atk_object) {
  RecordAccessibilityAtkApi(UmaAtkApi::kRefStateSet);
  return RefStateSet(atk_object);
}

void Initialize(AtkObject* atk_object, gpointer data) {
  if (ATK_OBJECT_CLASS(kAXPlatformNodeAuraLinuxParentClass)->initialize) {
    ATK_OBJECT_CLASS(kAXPlatformNodeAuraLinuxParentClass)
        ->initialize(atk_object, data);
  }

  AX_PLATFORM_NODE_AURALINUX(atk_object)->m_object =
      reinterpret_cast<AXPlatformNodeAuraLinux*>(data);
}

void Finalize(GObject* atk_object) {
  G_OBJECT_CLASS(kAXPlatformNodeAuraLinuxParentClass)->finalize(atk_object);
}

void ClassInit(gpointer class_pointer, gpointer /* class_data */) {
  GObjectClass* gobject_class = G_OBJECT_CLASS(class_pointer);
  kAXPlatformNodeAuraLinuxParentClass = g_type_class_peek_parent(gobject_class);
  gobject_class->finalize = Finalize;

  AtkObjectClass* atk_object_class = ATK_OBJECT_CLASS(gobject_class);
  atk_object_class->initialize = Initialize;
  atk_object_class->get_name = AtkGetName;
  atk_object_class->get_description = AtkGetDescription;
  atk_object_class->get_parent = AtkGetParent;
  atk_object_class->get_n_children = AtkGetNChildren;
  atk_object_class->ref_child = AtkRefChild;
  atk_object_class->get_role = AtkGetRole;
  atk_object_class->ref_state_set = AtkRefStateSet;
  atk_object_class->get_index_in_parent = AtkGetIndexInParent;
  atk_object_class->ref_relation_set = AtkRefRelationSet;
  atk_object_class->get_attributes = AtkGetAttributes;
}

GType GetType() {
  AXPlatformNodeAuraLinux::EnsureGTypeInit();

  static volatile gsize type_volatile = 0;
  if (g_once_init_enter(&type_volatile)) {
    static const GTypeInfo type_info = {
        sizeof(AXPlatformNodeAuraLinuxClass),  // class_size
        nullptr,                               // base_init
        nullptr,                               // base_finalize
        atk_object::ClassInit,
        nullptr,                                // class_finalize
        nullptr,                                // class_data
        sizeof(AXPlatformNodeAuraLinuxObject),  // instance_size
        0,                                      // n_preallocs
        nullptr,                                // instance_init
        nullptr                                 // value_table
    };

    GType type = g_type_register_static(
        ATK_TYPE_OBJECT, "AXPlatformNodeAuraLinux", &type_info, GTypeFlags(0));
    g_once_init_leave(&type_volatile, type);
  }

  return type_volatile;
}

void Detach(AXPlatformNodeAuraLinuxObject* atk_object) {
  if (!atk_object->m_object)
    return;

  atk_object->m_object = nullptr;
  atk_object_notify_state_change(ATK_OBJECT(atk_object), ATK_STATE_DEFUNCT,
                                 TRUE);
}

}  //  namespace atk_object

}  // namespace

// static
NO_SANITIZE("cfi-icall")
GType AtkTableCellInterface::GetType() {
  return g_atk_table_cell_get_type();
}

// static
NO_SANITIZE("cfi-icall")
GPtrArray* AtkTableCellInterface::GetColumnHeaderCells(AtkTableCell* cell) {
  return g_atk_table_cell_get_column_header_cells(cell);
}

// static
NO_SANITIZE("cfi-icall")
GPtrArray* AtkTableCellInterface::GetRowHeaderCells(AtkTableCell* cell) {
  return g_atk_table_cell_get_row_header_cells(cell);
}

// static
NO_SANITIZE("cfi-icall")
bool AtkTableCellInterface::GetRowColumnSpan(AtkTableCell* cell,
                                             gint* row,
                                             gint* column,
                                             gint* row_span,
                                             gint* col_span) {
  return g_atk_table_cell_get_row_column_span(cell, row, column, row_span,
                                              col_span);
}

// static
bool AtkTableCellInterface::Exists() {
  g_atk_table_cell_get_type = reinterpret_cast<GetTypeFunc>(
      dlsym(RTLD_DEFAULT, "atk_table_cell_get_type"));
  g_atk_table_cell_get_column_header_cells =
      reinterpret_cast<GetColumnHeaderCellsFunc>(
          dlsym(RTLD_DEFAULT, "atk_table_cell_get_column_header_cells"));
  g_atk_table_cell_get_row_header_cells =
      reinterpret_cast<GetRowHeaderCellsFunc>(
          dlsym(RTLD_DEFAULT, "atk_table_cell_get_row_header_cells"));
  g_atk_table_cell_get_row_column_span = reinterpret_cast<GetRowColumnSpanFunc>(
      dlsym(RTLD_DEFAULT, "atk_table_cell_get_row_column_span"));
  return *g_atk_table_cell_get_type;
}

void AXPlatformNodeAuraLinux::EnsureGTypeInit() {
#if !GLIB_CHECK_VERSION(2, 36, 0)
  static bool first_time = true;
  if (UNLIKELY(first_time)) {
    g_type_init();
    first_time = false;
  }
#endif
}

// static
ImplementedAtkInterfaces AXPlatformNodeAuraLinux::GetGTypeInterfaceMask(
    const AXNodeData& data) {
  // The default implementation set includes the AtkComponent and AtkAction
  // interfaces, which are provided by all the AtkObjects that we produce.
  ImplementedAtkInterfaces interface_mask;

  if (!IsImageOrVideo(data.role)) {
    interface_mask.Add(ImplementedAtkInterfaces::Value::kText);
    if (!data.IsPlainTextField())
      interface_mask.Add(ImplementedAtkInterfaces::Value::kHypertext);
  }

  if (data.IsRangeValueSupported())
    interface_mask.Add(ImplementedAtkInterfaces::Value::kValue);

  if (ui::IsDocument(data.role))
    interface_mask.Add(ImplementedAtkInterfaces::Value::kDocument);

  if (IsImage(data.role))
    interface_mask.Add(ImplementedAtkInterfaces::Value::kImage);

  // The AtkHyperlinkImpl interface allows getting a AtkHyperlink from an
  // AtkObject. It is indeed implemented by actual web hyperlinks, but also by
  // objects that will become embedded objects in ATK hypertext, so the name is
  // a bit of a misnomer from the ATK API.
  if (IsLink(data.role) || data.role == ax::mojom::Role::kAnchor ||
      !ui::IsText(data.role)) {
    interface_mask.Add(ImplementedAtkInterfaces::Value::kHyperlink);
  }

  if (data.role == ax::mojom::Role::kWindow)
    interface_mask.Add(ImplementedAtkInterfaces::Value::kWindow);

  if (IsContainerWithSelectableChildren(data.role))
    interface_mask.Add(ImplementedAtkInterfaces::Value::kSelection);

  if (IsTableLike(data.role))
    interface_mask.Add(ImplementedAtkInterfaces::Value::kTable);

  // Because the TableCell Interface is only supported in ATK version 2.12 and
  // later, GetAccessibilityGType has a runtime check to verify we have a recent
  // enough version. If we don't, GetAccessibilityGType will exclude
  // AtkTableCell from the supported interfaces and none of its methods or
  // properties will be exposed to assistive technologies.
  if (IsCellOrTableHeader(data.role))
    interface_mask.Add(ImplementedAtkInterfaces::Value::kTableCell);

  return interface_mask;
}

GType AXPlatformNodeAuraLinux::GetAccessibilityGType() {
  static const GTypeInfo type_info = {
      sizeof(AXPlatformNodeAuraLinuxClass),
      (GBaseInitFunc) nullptr,
      (GBaseFinalizeFunc) nullptr,
      (GClassInitFunc) nullptr,
      (GClassFinalizeFunc) nullptr,
      nullptr,                               /* class data */
      sizeof(AXPlatformNodeAuraLinuxObject), /* instance size */
      0,                                     /* nb preallocs */
      (GInstanceInitFunc) nullptr,
      nullptr /* value table */
  };

  const char* atk_type_name = GetUniqueAccessibilityGTypeName(interface_mask_);
  GType type = g_type_from_name(atk_type_name);
  if (type)
    return type;

  type = g_type_register_static(AX_PLATFORM_NODE_AURALINUX_TYPE, atk_type_name,
                                &type_info, GTypeFlags(0));

  // The AtkComponent and AtkAction interfaces are always supported.
  g_type_add_interface_static(type, ATK_TYPE_COMPONENT, &atk_component::Info);
  g_type_add_interface_static(type, ATK_TYPE_ACTION, &atk_action::Info);

  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kDocument))
    g_type_add_interface_static(type, ATK_TYPE_DOCUMENT, &atk_document::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kImage))
    g_type_add_interface_static(type, ATK_TYPE_IMAGE, &atk_image::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kValue))
    g_type_add_interface_static(type, ATK_TYPE_VALUE, &atk_value::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kHyperlink)) {
    g_type_add_interface_static(type, ATK_TYPE_HYPERLINK_IMPL,
                                &atk_hyperlink::Info);
  }
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kHypertext))
    g_type_add_interface_static(type, ATK_TYPE_HYPERTEXT, &atk_hypertext::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kText))
    g_type_add_interface_static(type, ATK_TYPE_TEXT, &atk_text::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kWindow))
    g_type_add_interface_static(type, ATK_TYPE_WINDOW, &atk_window::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kSelection))
    g_type_add_interface_static(type, ATK_TYPE_SELECTION, &atk_selection::Info);
  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kTable))
    g_type_add_interface_static(type, ATK_TYPE_TABLE, &atk_table::Info);

  if (interface_mask_.Implements(ImplementedAtkInterfaces::Value::kTableCell)) {
    // Run-time check to ensure AtkTableCell is supported (requires ATK 2.12).
    if (AtkTableCellInterface::Exists()) {
      g_type_add_interface_static(type, AtkTableCellInterface::GetType(),
                                  &atk_table_cell::Info);
    }
  }

  return type;
}

void AXPlatformNodeAuraLinux::SetDocumentParentOnFrameIfNecessary() {
  if (GetAtkRole() != ATK_ROLE_DOCUMENT_WEB)
    return;

  if (!GetDelegate()->IsWebContent())
    return;

  AtkObject* parent_atk_object = GetParent();
  AXPlatformNodeAuraLinux* parent =
      AXPlatformNodeAuraLinux::FromAtkObject(parent_atk_object);
  if (!parent)
    return;

  if (parent->GetDelegate()->IsWebContent())
    return;

  AXPlatformNodeAuraLinux* frame = AXPlatformNodeAuraLinux::FromAtkObject(
      FindAtkObjectParentFrame(parent_atk_object));
  if (!frame)
    return;

  frame->SetDocumentParent(parent_atk_object);
}

AtkObject* AXPlatformNodeAuraLinux::FindPrimaryWebContentDocument() {
  // It could get multiple web contents since additional web content is added,
  // when the DevTools window is opened.
  std::vector<AtkObject*> web_content_candidates;
  for (auto child_iterator_ptr = GetDelegate()->ChildrenBegin();
       *child_iterator_ptr != *GetDelegate()->ChildrenEnd();
       ++(*child_iterator_ptr)) {
    AtkObject* child = child_iterator_ptr->GetNativeViewAccessible();
    auto* child_node = AXPlatformNodeAuraLinux::FromAtkObject(child);
    if (!child_node)
      continue;
    if (!child_node->GetDelegate()->IsWebContent())
      continue;
    if (child_node->GetAtkRole() != ATK_ROLE_DOCUMENT_WEB)
      continue;
    web_content_candidates.push_back(child);
  }

  if (web_content_candidates.empty())
    return nullptr;

  // If it finds just one web content, return it.
  if (web_content_candidates.size() == 1)
    return web_content_candidates[0];

  for (auto* object : web_content_candidates) {
    auto* child_node = AXPlatformNodeAuraLinux::FromAtkObject(object);
    // If it is a primary web contents, return it.
    if (child_node->IsPrimaryWebContentsForWindow())
      return object;
  }
  return nullptr;
}

bool AXPlatformNodeAuraLinux::IsWebDocumentForRelations() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return false;
  AXPlatformNodeAuraLinux* parent = FromAtkObject(GetParent());
  if (!parent || !GetDelegate()->IsWebContent() ||
      GetAtkRole() != ATK_ROLE_DOCUMENT_WEB)
    return false;
  return parent->FindPrimaryWebContentDocument() == atk_object;
}

AtkObject* AXPlatformNodeAuraLinux::CreateAtkObject() {
  if (GetData().role != ax::mojom::Role::kApplication &&
      !GetDelegate()->IsToplevelBrowserWindow() &&
      !GetAccessibilityMode().has_mode(AXMode::kNativeAPIs))
    return nullptr;
  if (GetDelegate()->IsChildOfLeaf())
    return nullptr;
  EnsureGTypeInit();
  interface_mask_ = GetGTypeInterfaceMask(GetData());
  GType type = GetAccessibilityGType();
  AtkObject* atk_object = static_cast<AtkObject*>(g_object_new(type, nullptr));

  atk_object_initialize(atk_object, this);

  SetDocumentParentOnFrameIfNecessary();

  return ATK_OBJECT(atk_object);
}

void AXPlatformNodeAuraLinux::DestroyAtkObjects() {
  if (atk_hyperlink_) {
    ax_platform_atk_hyperlink_set_object(
        AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink_), nullptr);
    g_object_unref(atk_hyperlink_);
    atk_hyperlink_ = nullptr;
  }

  if (atk_object_) {
    // We explicitly clear g_current_focused and g_current_active_descendant
    // just in case there is another reference to atk_object_ somewhere.
    if (atk_object_ == g_current_focused)
      SetWeakGPtrToAtkObject(&g_current_focused, nullptr);
    if (atk_object_ == g_current_active_descendant)
      SetWeakGPtrToAtkObject(&g_current_active_descendant, nullptr);
    atk_object::Detach(AX_PLATFORM_NODE_AURALINUX(atk_object_));

    g_object_unref(atk_object_);
    atk_object_ = nullptr;
  }
}

// static
AXPlatformNode* AXPlatformNode::Create(AXPlatformNodeDelegate* delegate) {
  AXPlatformNodeAuraLinux* node = new AXPlatformNodeAuraLinux();
  node->Init(delegate);
  return node;
}

// static
AXPlatformNode* AXPlatformNode::FromNativeViewAccessible(
    gfx::NativeViewAccessible accessible) {
  return AXPlatformNodeAuraLinux::FromAtkObject(accessible);
}

//
// AXPlatformNodeAuraLinux implementation.
//

// static
AXPlatformNodeAuraLinux* AXPlatformNodeAuraLinux::FromAtkObject(
    const AtkObject* atk_object) {
  if (!atk_object)
    return nullptr;

  if (IS_AX_PLATFORM_NODE_AURALINUX(atk_object)) {
    AXPlatformNodeAuraLinuxObject* platform_object =
        AX_PLATFORM_NODE_AURALINUX(atk_object);
    return platform_object->m_object;
  }

  return nullptr;
}

// static
void AXPlatformNodeAuraLinux::SetApplication(AXPlatformNode* application) {
  g_root_application = application;
}

// static
AXPlatformNode* AXPlatformNodeAuraLinux::application() {
  return g_root_application;
}

// static
void AXPlatformNodeAuraLinux::StaticInitialize() {
  AtkUtilAuraLinux::GetInstance()->InitializeAsync();
}

// static
void AXPlatformNodeAuraLinux::EnableAXMode() {
  AXPlatformNode::NotifyAddAXModeFlags(kAXModeComplete);
}

AtkRole AXPlatformNodeAuraLinux::GetAtkRole() const {
  switch (GetData().role) {
    case ax::mojom::Role::kAlert:
      return ATK_ROLE_NOTIFICATION;
    case ax::mojom::Role::kAlertDialog:
      return ATK_ROLE_ALERT;
    case ax::mojom::Role::kAnchor:
      return ATK_ROLE_LINK;
    case ax::mojom::Role::kComment:
    case ax::mojom::Role::kSuggestion:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kApplication:
      // Only use ATK_ROLE_APPLICATION for elements with no parent, since it
      // is only for top level app windows and not ARIA applications.
      if (!GetParent()) {
        return ATK_ROLE_APPLICATION;
      } else {
        return ATK_ROLE_EMBEDDED;
      }
    case ax::mojom::Role::kArticle:
      return ATK_ROLE_ARTICLE;
    case ax::mojom::Role::kAudio:
      return ATK_ROLE_AUDIO;
    case ax::mojom::Role::kBanner:
    case ax::mojom::Role::kHeader:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kBlockquote:
      return ATK_ROLE_BLOCK_QUOTE;
    case ax::mojom::Role::kCaret:
      return ATK_ROLE_UNKNOWN;
    case ax::mojom::Role::kButton:
      return ATK_ROLE_PUSH_BUTTON;
    case ax::mojom::Role::kCanvas:
      return ATK_ROLE_CANVAS;
    case ax::mojom::Role::kCaption:
      return ATK_ROLE_CAPTION;
    case ax::mojom::Role::kCell:
      return ATK_ROLE_TABLE_CELL;
    case ax::mojom::Role::kCheckBox:
      return ATK_ROLE_CHECK_BOX;
    case ax::mojom::Role::kSwitch:
      return ATK_ROLE_TOGGLE_BUTTON;
    case ax::mojom::Role::kColorWell:
      return ATK_ROLE_PUSH_BUTTON;
    case ax::mojom::Role::kColumn:
      return ATK_ROLE_UNKNOWN;
    case ax::mojom::Role::kColumnHeader:
      return ATK_ROLE_COLUMN_HEADER;
    case ax::mojom::Role::kComboBoxGrouping:
      return ATK_ROLE_COMBO_BOX;
    case ax::mojom::Role::kComboBoxMenuButton:
      return ATK_ROLE_COMBO_BOX;
    case ax::mojom::Role::kComplementary:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kContentDeletion:
      return kAtkRoleContentDeletion;
    case ax::mojom::Role::kContentInsertion:
      return kAtkRoleContentInsertion;
    case ax::mojom::Role::kContentInfo:
    case ax::mojom::Role::kFooter:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kDate:
      return ATK_ROLE_DATE_EDITOR;
    case ax::mojom::Role::kDateTime:
      return ATK_ROLE_DATE_EDITOR;
    case ax::mojom::Role::kDefinition:
    case ax::mojom::Role::kDescriptionListDetail:
      return ATK_ROLE_DESCRIPTION_VALUE;
    case ax::mojom::Role::kDescriptionList:
      return ATK_ROLE_DESCRIPTION_LIST;
    case ax::mojom::Role::kDescriptionListTerm:
      return ATK_ROLE_DESCRIPTION_TERM;
    case ax::mojom::Role::kDetails:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kDialog:
      return ATK_ROLE_DIALOG;
    case ax::mojom::Role::kDirectory:
      return ATK_ROLE_LIST;
    case ax::mojom::Role::kDisclosureTriangle:
      return ATK_ROLE_TOGGLE_BUTTON;
    case ax::mojom::Role::kDocCover:
      return ATK_ROLE_IMAGE;
    case ax::mojom::Role::kDocBackLink:
    case ax::mojom::Role::kDocBiblioRef:
    case ax::mojom::Role::kDocGlossRef:
    case ax::mojom::Role::kDocNoteRef:
      return ATK_ROLE_LINK;
    case ax::mojom::Role::kDocBiblioEntry:
    case ax::mojom::Role::kDocEndnote:
      return ATK_ROLE_LIST_ITEM;
    case ax::mojom::Role::kDocNotice:
    case ax::mojom::Role::kDocTip:
      return ATK_ROLE_COMMENT;
    case ax::mojom::Role::kDocFootnote:
      return kAtkFootnoteRole;
    case ax::mojom::Role::kDocPageBreak:
      return ATK_ROLE_SEPARATOR;
    case ax::mojom::Role::kDocAcknowledgments:
    case ax::mojom::Role::kDocAfterword:
    case ax::mojom::Role::kDocAppendix:
    case ax::mojom::Role::kDocBibliography:
    case ax::mojom::Role::kDocChapter:
    case ax::mojom::Role::kDocConclusion:
    case ax::mojom::Role::kDocCredits:
    case ax::mojom::Role::kDocEndnotes:
    case ax::mojom::Role::kDocEpilogue:
    case ax::mojom::Role::kDocErrata:
    case ax::mojom::Role::kDocForeword:
    case ax::mojom::Role::kDocGlossary:
    case ax::mojom::Role::kDocIndex:
    case ax::mojom::Role::kDocIntroduction:
    case ax::mojom::Role::kDocPageList:
    case ax::mojom::Role::kDocPart:
    case ax::mojom::Role::kDocPreface:
    case ax::mojom::Role::kDocPrologue:
    case ax::mojom::Role::kDocToc:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kDocAbstract:
    case ax::mojom::Role::kDocColophon:
    case ax::mojom::Role::kDocCredit:
    case ax::mojom::Role::kDocDedication:
    case ax::mojom::Role::kDocEpigraph:
    case ax::mojom::Role::kDocExample:
    case ax::mojom::Role::kDocPullquote:
    case ax::mojom::Role::kDocQna:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kDocSubtitle:
      return ATK_ROLE_HEADING;
    case ax::mojom::Role::kDocument:
      return ATK_ROLE_DOCUMENT_FRAME;
    case ax::mojom::Role::kEmbeddedObject:
      return ATK_ROLE_EMBEDDED;
    case ax::mojom::Role::kForm:
      // TODO(accessibility) Forms which lack an accessible name are no longer
      // exposed as forms. http://crbug.com/874384. Forms which have accessible
      // names should be exposed as ATK_ROLE_LANDMARK according to Core AAM.
      return ATK_ROLE_FORM;
    case ax::mojom::Role::kFigure:
    case ax::mojom::Role::kFeed:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kGenericContainer:
    case ax::mojom::Role::kFooterAsNonLandmark:
    case ax::mojom::Role::kHeaderAsNonLandmark:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kGraphicsDocument:
      return ATK_ROLE_DOCUMENT_FRAME;
    case ax::mojom::Role::kGraphicsObject:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kGraphicsSymbol:
      return ATK_ROLE_IMAGE;
    case ax::mojom::Role::kGrid:
      return ATK_ROLE_TABLE;
    case ax::mojom::Role::kGroup:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kHeading:
      return ATK_ROLE_HEADING;
    case ax::mojom::Role::kIframe:
    case ax::mojom::Role::kIframePresentational:
      return ATK_ROLE_INTERNAL_FRAME;
    case ax::mojom::Role::kIgnored:
      return ATK_ROLE_REDUNDANT_OBJECT;
    case ax::mojom::Role::kImage:
      return ATK_ROLE_IMAGE;
    case ax::mojom::Role::kImageMap:
      return ATK_ROLE_IMAGE_MAP;
    case ax::mojom::Role::kInlineTextBox:
      return kStaticRole;
    case ax::mojom::Role::kInputTime:
      return ATK_ROLE_DATE_EDITOR;
    case ax::mojom::Role::kLabelText:
      return ATK_ROLE_LABEL;
    case ax::mojom::Role::kLegend:
      return ATK_ROLE_LABEL;
    // Layout table objects are treated the same as Role::kGenericContainer.
    case ax::mojom::Role::kLayoutTable:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kLayoutTableCell:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kLayoutTableRow:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kLineBreak:
      // TODO(Accessibility) Having a separate accessible object for line breaks
      // is inconsistent with other implementations. http://crbug.com/873144#c1.
      return kStaticRole;
    case ax::mojom::Role::kLink:
      return ATK_ROLE_LINK;
    case ax::mojom::Role::kList:
      return ATK_ROLE_LIST;
    case ax::mojom::Role::kListBox:
      return ATK_ROLE_LIST_BOX;
    // TODO(Accessibility) Use ATK_ROLE_MENU_ITEM inside a combo box, see how
    // ax_platform_node_win.cc code does this.
    case ax::mojom::Role::kListBoxOption:
      return ATK_ROLE_LIST_ITEM;
    case ax::mojom::Role::kListGrid:
      return ATK_ROLE_TABLE;
    case ax::mojom::Role::kListItem:
      return ATK_ROLE_LIST_ITEM;
    case ax::mojom::Role::kListMarker:
      if (!GetChildCount()) {
        // There's only a name attribute when using Legacy layout. With Legacy
        // layout, list markers have no child and are considered as StaticText.
        // We consider a list marker as a group in LayoutNG since it has
        // a text child node.
        return kStaticRole;
      }
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kLog:
      return ATK_ROLE_LOG;
    case ax::mojom::Role::kMain:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kMark:
      return kStaticRole;
    case ax::mojom::Role::kMath:
      return ATK_ROLE_MATH;
    case ax::mojom::Role::kMarquee:
      return ATK_ROLE_MARQUEE;
    case ax::mojom::Role::kMenu:
      return ATK_ROLE_MENU;
    case ax::mojom::Role::kMenuBar:
      return ATK_ROLE_MENU_BAR;
    case ax::mojom::Role::kMenuItem:
      return ATK_ROLE_MENU_ITEM;
    case ax::mojom::Role::kMenuItemCheckBox:
      return ATK_ROLE_CHECK_MENU_ITEM;
    case ax::mojom::Role::kMenuItemRadio:
      return ATK_ROLE_RADIO_MENU_ITEM;
    case ax::mojom::Role::kMenuListPopup:
      return ATK_ROLE_MENU;
    case ax::mojom::Role::kMenuListOption:
      return ATK_ROLE_MENU_ITEM;
    case ax::mojom::Role::kMeter:
      return ATK_ROLE_LEVEL_BAR;
    case ax::mojom::Role::kNavigation:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kNote:
      return ATK_ROLE_COMMENT;
    case ax::mojom::Role::kPane:
    case ax::mojom::Role::kScrollView:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kParagraph:
      return ATK_ROLE_PARAGRAPH;
    case ax::mojom::Role::kPdfActionableHighlight:
      return ATK_ROLE_PUSH_BUTTON;
    case ax::mojom::Role::kPluginObject:
      return ATK_ROLE_EMBEDDED;
    case ax::mojom::Role::kPopUpButton: {
      std::string html_tag =
          GetData().GetStringAttribute(ax::mojom::StringAttribute::kHtmlTag);
      if (html_tag == "select")
        return ATK_ROLE_COMBO_BOX;
      return ATK_ROLE_PUSH_BUTTON;
    }
    case ax::mojom::Role::kPortal:
      return ATK_ROLE_PUSH_BUTTON;
    case ax::mojom::Role::kPre:
      return ATK_ROLE_SECTION;
    case ax::mojom::Role::kProgressIndicator:
      return ATK_ROLE_PROGRESS_BAR;
    case ax::mojom::Role::kRadioButton:
      return ATK_ROLE_RADIO_BUTTON;
    case ax::mojom::Role::kRadioGroup:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kRegion:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kRootWebArea:
      return ATK_ROLE_DOCUMENT_WEB;
    case ax::mojom::Role::kRow:
      return ATK_ROLE_TABLE_ROW;
    case ax::mojom::Role::kRowGroup:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kRowHeader:
      return ATK_ROLE_ROW_HEADER;
    case ax::mojom::Role::kRuby:
      return kStaticRole;
    case ax::mojom::Role::kRubyAnnotation:
      // TODO(accessibility) Panels are generally for containers of widgets.
      // This should probably be a section (if a container) or static if text.
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kSection: {
      if (GetName().empty()) {
        // Do not use ARIA mapping for nameless <section>.
        return ATK_ROLE_SECTION;
      } else {
        // Use ARIA mapping.
        return ATK_ROLE_LANDMARK;
      }
    }
    case ax::mojom::Role::kScrollBar:
      return ATK_ROLE_SCROLL_BAR;
    case ax::mojom::Role::kSearch:
      return ATK_ROLE_LANDMARK;
    case ax::mojom::Role::kSlider:
    case ax::mojom::Role::kSliderThumb:
      return ATK_ROLE_SLIDER;
    case ax::mojom::Role::kSpinButton:
      return ATK_ROLE_SPIN_BUTTON;
    case ax::mojom::Role::kSplitter:
      return ATK_ROLE_SEPARATOR;
    case ax::mojom::Role::kStaticText: {
      switch (static_cast<ax::mojom::TextPosition>(
          GetIntAttribute(ax::mojom::IntAttribute::kTextPosition))) {
        case ax::mojom::TextPosition::kSubscript:
          return kSubscriptRole;
        case ax::mojom::TextPosition::kSuperscript:
          return kSuperscriptRole;
        default:
          break;
      }
      return kStaticRole;
    }
    case ax::mojom::Role::kStatus:
      return ATK_ROLE_STATUSBAR;
    case ax::mojom::Role::kSvgRoot:
      return ATK_ROLE_DOCUMENT_FRAME;
    case ax::mojom::Role::kTab:
      return ATK_ROLE_PAGE_TAB;
    case ax::mojom::Role::kTable:
      return ATK_ROLE_TABLE;
    case ax::mojom::Role::kTableHeaderContainer:
      // TODO(accessibility) This mapping is correct, but it doesn't seem to be
      // used. We don't necessarily want to always expose these containers, but
      // we must do so if they are focusable. http://crbug.com/874043
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kTabList:
      return ATK_ROLE_PAGE_TAB_LIST;
    case ax::mojom::Role::kTabPanel:
      return ATK_ROLE_SCROLL_PANE;
    case ax::mojom::Role::kTerm:
      // TODO(accessibility) This mapping should also be applied to the dfn
      // element. http://crbug.com/874411
      return ATK_ROLE_DESCRIPTION_TERM;
    case ax::mojom::Role::kTitleBar:
      return ATK_ROLE_TITLE_BAR;
    case ax::mojom::Role::kTextField:
    case ax::mojom::Role::kSearchBox:
      if (GetData().HasState(ax::mojom::State::kProtected))
        return ATK_ROLE_PASSWORD_TEXT;
      return ATK_ROLE_ENTRY;
    case ax::mojom::Role::kTextFieldWithComboBox:
      return ATK_ROLE_COMBO_BOX;
    case ax::mojom::Role::kAbbr:
    case ax::mojom::Role::kCode:
    case ax::mojom::Role::kEmphasis:
    case ax::mojom::Role::kStrong:
    case ax::mojom::Role::kTime:
      return kStaticRole;
    case ax::mojom::Role::kTimer:
      return ATK_ROLE_TIMER;
    case ax::mojom::Role::kToggleButton:
      return ATK_ROLE_TOGGLE_BUTTON;
    case ax::mojom::Role::kToolbar:
      return ATK_ROLE_TOOL_BAR;
    case ax::mojom::Role::kTooltip:
      return ATK_ROLE_TOOL_TIP;
    case ax::mojom::Role::kTree:
      return ATK_ROLE_TREE;
    case ax::mojom::Role::kTreeItem:
      return ATK_ROLE_TREE_ITEM;
    case ax::mojom::Role::kTreeGrid:
      return ATK_ROLE_TREE_TABLE;
    case ax::mojom::Role::kVideo:
      return ATK_ROLE_VIDEO;
    case ax::mojom::Role::kWebArea:
    case ax::mojom::Role::kWebView:
      return ATK_ROLE_DOCUMENT_WEB;
    case ax::mojom::Role::kWindow:
      // In ATK elements with ATK_ROLE_FRAME are windows with titles and
      // buttons, while those with ATK_ROLE_WINDOW are windows without those
      // elements.
      return ATK_ROLE_FRAME;
    case ax::mojom::Role::kClient:
    case ax::mojom::Role::kDesktop:
      return ATK_ROLE_PANEL;
    case ax::mojom::Role::kFigcaption:
      return ATK_ROLE_CAPTION;
    case ax::mojom::Role::kUnknown:
      // When we are not in web content, assume that a node with an unknown
      // role is a view (which often have the unknown role).
      return !GetDelegate()->IsWebContent() ? ATK_ROLE_PANEL : ATK_ROLE_UNKNOWN;
    case ax::mojom::Role::kImeCandidate:
    case ax::mojom::Role::kKeyboard:
    case ax::mojom::Role::kNone:
    case ax::mojom::Role::kPresentational:
      return ATK_ROLE_REDUNDANT_OBJECT;
  }
}

void AXPlatformNodeAuraLinux::GetAtkState(AtkStateSet* atk_state_set) {
  AXNodeData data = GetData();

  bool menu_active = !GetActiveMenus().empty();
  if (!menu_active && atk_object_ == g_active_top_level_frame)
    atk_state_set_add_state(atk_state_set, ATK_STATE_ACTIVE);
  if (menu_active &&
      FindAtkObjectParentFrame(GetActiveMenus().back()) == atk_object_)
    atk_state_set_add_state(atk_state_set, ATK_STATE_ACTIVE);

  if (atk_object_ && atk_object_ == g_active_views_dialog)
    atk_state_set_add_state(atk_state_set, ATK_STATE_ACTIVE);

  bool is_minimized = delegate_->IsMinimized();
  if (is_minimized && data.role == ax::mojom::Role::kWindow)
    atk_state_set_add_state(atk_state_set, ATK_STATE_ICONIFIED);

  if (data.HasState(ax::mojom::State::kCollapsed))
    atk_state_set_add_state(atk_state_set, ATK_STATE_EXPANDABLE);
  if (data.HasState(ax::mojom::State::kDefault))
    atk_state_set_add_state(atk_state_set, ATK_STATE_DEFAULT);
  if ((data.HasState(ax::mojom::State::kEditable) ||
       data.HasState(ax::mojom::State::kRichlyEditable)) &&
      data.GetRestriction() != ax::mojom::Restriction::kReadOnly) {
    atk_state_set_add_state(atk_state_set, ATK_STATE_EDITABLE);
  }
  if (data.HasState(ax::mojom::State::kExpanded)) {
    atk_state_set_add_state(atk_state_set, ATK_STATE_EXPANDABLE);
    atk_state_set_add_state(atk_state_set, ATK_STATE_EXPANDED);
  }
  if (data.HasState(ax::mojom::State::kFocusable) ||
      SelectionAndFocusAreTheSame())
    atk_state_set_add_state(atk_state_set, ATK_STATE_FOCUSABLE);
  if (data.HasState(ax::mojom::State::kHorizontal))
    atk_state_set_add_state(atk_state_set, ATK_STATE_HORIZONTAL);
  if (!data.HasState(ax::mojom::State::kInvisible)) {
    atk_state_set_add_state(atk_state_set, ATK_STATE_VISIBLE);
    if (!delegate_->IsOffscreen() && !is_minimized)
      atk_state_set_add_state(atk_state_set, ATK_STATE_SHOWING);
  }
  if (data.HasState(ax::mojom::State::kMultiselectable))
    atk_state_set_add_state(atk_state_set, ATK_STATE_MULTISELECTABLE);
  if (data.HasState(ax::mojom::State::kRequired))
    atk_state_set_add_state(atk_state_set, ATK_STATE_REQUIRED);
  if (data.HasState(ax::mojom::State::kVertical))
    atk_state_set_add_state(atk_state_set, ATK_STATE_VERTICAL);
  if (data.HasState(ax::mojom::State::kVisited))
    atk_state_set_add_state(atk_state_set, ATK_STATE_VISITED);
  if (data.HasIntAttribute(ax::mojom::IntAttribute::kInvalidState) &&
      data.GetIntAttribute(ax::mojom::IntAttribute::kInvalidState) !=
          static_cast<int32_t>(ax::mojom::InvalidState::kFalse))
    atk_state_set_add_state(atk_state_set, ATK_STATE_INVALID_ENTRY);
#if defined(ATK_216)
  if (IsPlatformCheckable())
    atk_state_set_add_state(atk_state_set, ATK_STATE_CHECKABLE);
  if (data.HasIntAttribute(ax::mojom::IntAttribute::kHasPopup))
    atk_state_set_add_state(atk_state_set, ATK_STATE_HAS_POPUP);
#endif
  if (data.GetBoolAttribute(ax::mojom::BoolAttribute::kBusy))
    atk_state_set_add_state(atk_state_set, ATK_STATE_BUSY);
  if (data.GetBoolAttribute(ax::mojom::BoolAttribute::kModal))
    atk_state_set_add_state(atk_state_set, ATK_STATE_MODAL);
  if (data.IsSelectable())
    atk_state_set_add_state(atk_state_set, ATK_STATE_SELECTABLE);
  if (data.GetBoolAttribute(ax::mojom::BoolAttribute::kSelected))
    atk_state_set_add_state(atk_state_set, ATK_STATE_SELECTED);

  if (IsPlainTextField() || IsRichTextField()) {
    atk_state_set_add_state(atk_state_set, ATK_STATE_SELECTABLE_TEXT);
    if (data.HasState(ax::mojom::State::kMultiline))
      atk_state_set_add_state(atk_state_set, ATK_STATE_MULTI_LINE);
    else
      atk_state_set_add_state(atk_state_set, ATK_STATE_SINGLE_LINE);
  }

  if (!GetStringAttribute(ax::mojom::StringAttribute::kAutoComplete).empty() ||
      data.HasState(ax::mojom::State::kAutofillAvailable))
    atk_state_set_add_state(atk_state_set, ATK_STATE_SUPPORTS_AUTOCOMPLETION);

  // Checked state
  const auto checked_state = GetData().GetCheckedState();
  if (checked_state == ax::mojom::CheckedState::kTrue ||
      checked_state == ax::mojom::CheckedState::kMixed) {
    atk_state_set_add_state(atk_state_set, GetAtkStateTypeForCheckableNode());
  }

  if (data.GetRestriction() != ax::mojom::Restriction::kDisabled) {
    if (IsReadOnlySupported(data.role) && data.IsReadOnlyOrDisabled()) {
#if defined(ATK_216)
      atk_state_set_add_state(atk_state_set, ATK_STATE_READ_ONLY);
#endif
    } else {
      atk_state_set_add_state(atk_state_set, ATK_STATE_ENABLED);
      atk_state_set_add_state(atk_state_set, ATK_STATE_SENSITIVE);
    }
  }

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  if (delegate_->GetFocus() == atk_object)
    atk_state_set_add_state(atk_state_set, ATK_STATE_FOCUSED);

  // It is insufficient to compare with g_current_activedescendant due to both
  // timing and event ordering for objects which implement AtkSelection and also
  // have an active descendant. For instance, if we check the state set of a
  // selectable child, it will only have ATK_STATE_FOCUSED if we've processed
  // the activedescendant change.
  if (GetActiveDescendantOfCurrentFocused() == atk_object)
    atk_state_set_add_state(atk_state_set, ATK_STATE_FOCUSED);
}

struct AtkIntRelation {
  ax::mojom::IntAttribute attribute;
  AtkRelationType relation;
  base::Optional<AtkRelationType> reverse_relation;
};

static AtkIntRelation kIntRelations[] = {
    {ax::mojom::IntAttribute::kMemberOfId, ATK_RELATION_MEMBER_OF,
     base::nullopt},
    {ax::mojom::IntAttribute::kPopupForId, ATK_RELATION_POPUP_FOR,
     base::nullopt},
#if defined(ATK_226)
    {ax::mojom::IntAttribute::kErrormessageId, ATK_RELATION_ERROR_MESSAGE,
     ATK_RELATION_ERROR_FOR},
#endif
};

struct AtkIntListRelation {
  ax::mojom::IntListAttribute attribute;
  AtkRelationType relation;
  base::Optional<AtkRelationType> reverse_relation;
};

static AtkIntListRelation kIntListRelations[] = {
    {ax::mojom::IntListAttribute::kControlsIds, ATK_RELATION_CONTROLLER_FOR,
     ATK_RELATION_CONTROLLED_BY},
#if defined(ATK_226)
    {ax::mojom::IntListAttribute::kDetailsIds, ATK_RELATION_DETAILS,
     ATK_RELATION_DETAILS_FOR},
#endif
    {ax::mojom::IntListAttribute::kDescribedbyIds, ATK_RELATION_DESCRIBED_BY,
     ATK_RELATION_DESCRIPTION_FOR},
    {ax::mojom::IntListAttribute::kFlowtoIds, ATK_RELATION_FLOWS_TO,
     ATK_RELATION_FLOWS_FROM},
    {ax::mojom::IntListAttribute::kLabelledbyIds, ATK_RELATION_LABELLED_BY,
     ATK_RELATION_LABEL_FOR},
};

void AXPlatformNodeAuraLinux::AddRelationToSet(AtkRelationSet* relation_set,
                                               AtkRelationType relation,
                                               AXPlatformNode* target) {
  DCHECK(target);

  // Avoid adding self-referential relations.
  if (target == this)
    return;

  // If we were compiled with a newer version of ATK than the runtime version,
  // it's possible that we might try to add a relation that doesn't exist in
  // the runtime version of the AtkRelationType enum. This will cause a runtime
  // error, so return early here if we are about to do that.
  static base::Optional<int> max_relation_type = base::nullopt;
  if (!max_relation_type.has_value()) {
    GEnumClass* enum_class =
        G_ENUM_CLASS(g_type_class_ref(atk_relation_type_get_type()));
    max_relation_type = enum_class->maximum;
    g_type_class_unref(enum_class);
  }
  if (relation > max_relation_type.value())
    return;

  atk_relation_set_add_relation_by_type(relation_set, relation,
                                        target->GetNativeViewAccessible());
}

AtkRelationSet* AXPlatformNodeAuraLinux::GetAtkRelations() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return nullptr;

  AtkRelationSet* relation_set = atk_relation_set_new();

  if (IsWebDocumentForRelations()) {
    AtkObject* parent_frame = FindAtkObjectParentFrame(atk_object);
    if (parent_frame) {
      atk_relation_set_add_relation_by_type(
          relation_set, ATK_RELATION_EMBEDDED_BY, parent_frame);
    }
  }

  if (auto* document_parent = FromAtkObject(document_parent_)) {
    AtkObject* document = document_parent->FindPrimaryWebContentDocument();
    if (document) {
      atk_relation_set_add_relation_by_type(relation_set, ATK_RELATION_EMBEDS,
                                            document);
    }
  }

  // For each possible relation defined by an IntAttribute, we test that
  // attribute and then look for reverse relations. AddRelationToSet handles
  // discarding self-referential relations.
  for (unsigned i = 0; i < G_N_ELEMENTS(kIntRelations); i++) {
    const AtkIntRelation& relation = kIntRelations[i];

    if (AXPlatformNode* target =
            GetDelegate()->GetTargetNodeForRelation(relation.attribute))
      AddRelationToSet(relation_set, relation.relation, target);

    if (!relation.reverse_relation.has_value())
      continue;

    std::set<AXPlatformNode*> target_ids =
        GetDelegate()->GetReverseRelations(relation.attribute);
    for (AXPlatformNode* target : target_ids) {
      AddRelationToSet(relation_set, relation.reverse_relation.value(), target);
    }
  }

  // Now we do the same for each possible relation defined by an
  // IntListAttribute. In this case we need to handle each target in the list.
  for (const auto& relation : kIntListRelations) {
    std::vector<AXPlatformNode*> targets =
        GetDelegate()->GetTargetNodesForRelation(relation.attribute);
    for (AXPlatformNode* target : targets) {
      AddRelationToSet(relation_set, relation.relation, target);
    }

    if (!relation.reverse_relation.has_value())
      continue;

    std::set<AXPlatformNode*> reverse_target_ids =
        GetDelegate()->GetReverseRelations(relation.attribute);
    for (AXPlatformNode* target : reverse_target_ids) {
      AddRelationToSet(relation_set, relation.reverse_relation.value(), target);
    }
  }

  return relation_set;
}

AXPlatformNodeAuraLinux::AXPlatformNodeAuraLinux() = default;

AXPlatformNodeAuraLinux::~AXPlatformNodeAuraLinux() {
  if (g_current_selected == this)
    g_current_selected = nullptr;

  DestroyAtkObjects();

  if (window_activate_event_postponed_)
    AtkUtilAuraLinux::GetInstance()->CancelPostponedEventsFor(this);

  SetWeakGPtrToAtkObject(&document_parent_, nullptr);
}

void AXPlatformNodeAuraLinux::Destroy() {
  DestroyAtkObjects();
  AXPlatformNodeBase::Destroy();
}

void AXPlatformNodeAuraLinux::Init(AXPlatformNodeDelegate* delegate) {
  // Initialize ATK.
  AXPlatformNodeBase::Init(delegate);

  // Only create the AtkObject if we know enough information.
  if (GetData().role != ax::mojom::Role::kUnknown)
    GetOrCreateAtkObject();
}

bool AXPlatformNodeAuraLinux::IsPlatformCheckable() const {
  if (GetData().role == ax::mojom::Role::kToggleButton)
    return false;

  return AXPlatformNodeBase::IsPlatformCheckable();
}

base::Optional<int> AXPlatformNodeAuraLinux::GetIndexInParent() {
  AXPlatformNode* parent =
      AXPlatformNode::FromNativeViewAccessible(GetParent());
  // Even though the node doesn't have its parent, GetParent() could return the
  // application. Since the detached view has the kUnknown role and the
  // restriction is kDisabled, it early returns before finding the index.
  if (parent == AXPlatformNodeAuraLinux::application() &&
      GetData().role == ax::mojom::Role::kUnknown &&
      GetData().GetRestriction() == ax::mojom::Restriction::kDisabled) {
    return base::nullopt;
  }

  return AXPlatformNodeBase::GetIndexInParent();
}

void AXPlatformNodeAuraLinux::EnsureAtkObjectIsValid() {
  if (atk_object_) {
    // If the object's role changes and that causes its
    // interface mask to change, we need to create a new
    // AtkObject for it.
    ImplementedAtkInterfaces interface_mask = GetGTypeInterfaceMask(GetData());
    if (interface_mask != interface_mask_)
      DestroyAtkObjects();
  }

  if (!atk_object_) {
    GetOrCreateAtkObject();
  }
}

gfx::NativeViewAccessible AXPlatformNodeAuraLinux::GetNativeViewAccessible() {
  return GetOrCreateAtkObject();
}

gfx::NativeViewAccessible AXPlatformNodeAuraLinux::GetOrCreateAtkObject() {
  if (!atk_object_) {
    atk_object_ = CreateAtkObject();
  }
  return atk_object_;
}

void AXPlatformNodeAuraLinux::OnActiveDescendantChanged() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  // Active-descendant-changed notifications are typically only relevant when
  // the change is within the focused widget.
  if (!g_current_focused)
    return;
  if (auto* focused_node = FromAtkObject(g_current_focused)) {
    if (!focused_node->IsDescendantOf(this))
      return;
  }

  AtkObject* descendant = GetActiveDescendantOfCurrentFocused();
  if (descendant == g_current_active_descendant)
    return;

  // If selection and focus are the same, when the active descendant changes
  // as a result of selection, a focus event will be emitted. We don't want to
  // emit duplicate notifications.
  {
    auto* node = FromAtkObject(descendant);
    if (node && node->SelectionAndFocusAreTheSame())
      return;
  }

  // While there is an ATK active-descendant-changed event, it is meant for
  // objects which manage their descendants (and claim to do so). The Core-AAM
  // specification states that focus events should be emitted when the active
  // descendant changes. This behavior is also consistent with Gecko.
  if (g_current_active_descendant) {
    g_signal_emit_by_name(g_current_active_descendant, "focus-event", false);
    atk_object_notify_state_change(ATK_OBJECT(g_current_active_descendant),
                                   ATK_STATE_FOCUSED, false);
  }

  SetWeakGPtrToAtkObject(&g_current_active_descendant, descendant);
  if (g_current_active_descendant) {
    g_signal_emit_by_name(g_current_active_descendant, "focus-event", true);
    atk_object_notify_state_change(ATK_OBJECT(g_current_active_descendant),
                                   ATK_STATE_FOCUSED, true);
  }
}

void AXPlatformNodeAuraLinux::OnCheckedStateChanged() {
  AtkObject* obj = GetOrCreateAtkObject();
  if (!obj)
    return;

  atk_object_notify_state_change(
      ATK_OBJECT(obj), GetAtkStateTypeForCheckableNode(),
      GetData().GetCheckedState() != ax::mojom::CheckedState::kFalse);
}

void AXPlatformNodeAuraLinux::OnEnabledChanged() {
  AtkObject* obj = GetOrCreateAtkObject();
  if (!obj)
    return;

  atk_object_notify_state_change(
      obj, ATK_STATE_ENABLED,
      GetData().GetRestriction() != ax::mojom::Restriction::kDisabled);
}

void AXPlatformNodeAuraLinux::OnExpandedStateChanged(bool is_expanded) {
  // When a list box is expanded, it becomes visible. This means that it might
  // now have a different role (the role for hidden Views is kUnknown).  We
  // need to recreate the AtkObject in this case because a change in roles
  // might imply a change in ATK interfaces implemented.
  EnsureAtkObjectIsValid();

  AtkObject* obj = GetOrCreateAtkObject();
  if (!obj)
    return;

  atk_object_notify_state_change(obj, ATK_STATE_EXPANDED, is_expanded);
}

void AXPlatformNodeAuraLinux::OnMenuPopupStart() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  AtkObject* parent_frame = FindAtkObjectParentFrame(atk_object);
  if (!parent_frame)
    return;

  // Exit early if kMenuPopupStart is sent multiple times for the same menu.
  std::vector<AtkObject*>& active_menus = GetActiveMenus();
  bool menu_already_open = !active_menus.empty();
  if (menu_already_open && active_menus.back() == atk_object)
    return;

  // We also want to inform the AT that menu the is now showing. Normally this
  // event is not fired because the menu will be created with the
  // ATK_STATE_SHOWING already set to TRUE.
  atk_object_notify_state_change(atk_object, ATK_STATE_SHOWING, TRUE);

  // We need to compute this before modifying the active menu stack.
  AtkObject* previous_active_frame = ComputeActiveTopLevelFrame();

  active_menus.push_back(atk_object);

  // We exit early if the newly activated menu has the same AtkWindow as the
  // previous one.
  if (previous_active_frame == parent_frame)
    return;
  if (previous_active_frame) {
    g_signal_emit_by_name(previous_active_frame, "deactivate");
    atk_object_notify_state_change(previous_active_frame, ATK_STATE_ACTIVE,
                                   FALSE);
  }
  g_signal_emit_by_name(parent_frame, "activate");
  atk_object_notify_state_change(parent_frame, ATK_STATE_ACTIVE, TRUE);
}

void AXPlatformNodeAuraLinux::OnMenuPopupEnd() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  AtkObject* parent_frame = FindAtkObjectParentFrame(atk_object);
  if (!parent_frame)
    return;

  atk_object_notify_state_change(atk_object, ATK_STATE_SHOWING, FALSE);

  // kMenuPopupHide may be called multiple times for the same menu, so only
  // remove it if our parent frame matches the most recently opened menu.
  std::vector<AtkObject*>& active_menus = GetActiveMenus();
  DCHECK(!active_menus.empty())
      << "Asymmetrical menupopupend events -- too many";

  active_menus.pop_back();
  AtkObject* new_active_item = ComputeActiveTopLevelFrame();
  if (new_active_item != parent_frame) {
    // Newly activated menu has the different AtkWindow as the previous one.
    g_signal_emit_by_name(parent_frame, "deactivate");
    atk_object_notify_state_change(parent_frame, ATK_STATE_ACTIVE, FALSE);
    if (new_active_item) {
      g_signal_emit_by_name(new_active_item, "activate");
      atk_object_notify_state_change(new_active_item, ATK_STATE_ACTIVE, TRUE);
    }
  }

  // All menus are closed.
  if (active_menus.empty())
    OnAllMenusEnded();
}

void AXPlatformNodeAuraLinux::ResendFocusSignalsForCurrentlyFocusedNode() {
  auto* frame = FromAtkObject(g_active_top_level_frame);
  if (!frame)
    return;

  AtkObject* focused_node = frame->GetDelegate()->GetFocus();
  if (!focused_node)
    return;

  g_signal_emit_by_name(focused_node, "focus-event", true);
  atk_object_notify_state_change(focused_node, ATK_STATE_FOCUSED, true);
}

// All menus have closed.
void AXPlatformNodeAuraLinux::OnAllMenusEnded() {
  if (!GetActiveMenus().empty() && g_active_top_level_frame &&
      ComputeActiveTopLevelFrame() != g_active_top_level_frame) {
    g_signal_emit_by_name(g_active_top_level_frame, "activate");
    atk_object_notify_state_change(g_active_top_level_frame, ATK_STATE_ACTIVE,
                                   TRUE);
  }

  GetActiveMenus().clear();
  ResendFocusSignalsForCurrentlyFocusedNode();
}

void AXPlatformNodeAuraLinux::OnWindowActivated() {
  AtkObject* parent_frame = FindAtkObjectParentFrame(GetOrCreateAtkObject());
  if (!parent_frame || parent_frame == g_active_top_level_frame)
    return;

  SetActiveTopLevelFrame(parent_frame);

  g_signal_emit_by_name(parent_frame, "activate");
  atk_object_notify_state_change(parent_frame, ATK_STATE_ACTIVE, TRUE);

  // We also send a focus event for the currently focused element, so that
  // the user knows where the focus is when the toplevel window regains focus.
  if (g_current_focused &&
      IsFrameAncestorOfAtkObject(parent_frame, g_current_focused)) {
    g_signal_emit_by_name(g_current_focused, "focus-event", true);
    atk_object_notify_state_change(ATK_OBJECT(g_current_focused),
                                   ATK_STATE_FOCUSED, true);
  }
}

void AXPlatformNodeAuraLinux::OnWindowDeactivated() {
  AtkObject* parent_frame = FindAtkObjectParentFrame(GetOrCreateAtkObject());
  if (!parent_frame || parent_frame != g_active_top_level_frame)
    return;

  SetActiveTopLevelFrame(nullptr);

  g_signal_emit_by_name(parent_frame, "deactivate");
  atk_object_notify_state_change(parent_frame, ATK_STATE_ACTIVE, FALSE);
}

void AXPlatformNodeAuraLinux::OnWindowVisibilityChanged() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  if (GetAtkRole() != ATK_ROLE_FRAME)
    return;

  bool minimized = delegate_->IsMinimized();
  if (minimized == was_minimized_)
    return;

  was_minimized_ = minimized;
  if (minimized)
    g_signal_emit_by_name(atk_object, "minimize");
  else
    g_signal_emit_by_name(atk_object, "restore");
  atk_object_notify_state_change(atk_object, ATK_STATE_ICONIFIED, minimized);
}

void AXPlatformNodeAuraLinux::OnScrolledToAnchor() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;
  DCHECK(ATK_IS_TEXT(atk_object));
  g_signal_emit_by_name(atk_object, "text-caret-moved", 0);
}

void AXPlatformNodeAuraLinux::SetActiveViewsDialog() {
  AtkObject* old_views_dialog = g_active_views_dialog;
  AtkObject* new_views_dialog = nullptr;

  AtkObject* parent = GetOrCreateAtkObject();
  if (!parent)
    return;

  if (!GetDelegate()->IsWebContent()) {
    while (parent) {
      if (atk_object::GetRole(parent) == ATK_ROLE_DIALOG) {
        new_views_dialog = parent;
        break;
      }
      parent = atk_object::GetParent(parent);
    }
  }

  if (old_views_dialog == new_views_dialog)
    return;

  SetWeakGPtrToAtkObject(&g_active_views_dialog, new_views_dialog);
  if (old_views_dialog)
    atk_object_notify_state_change(old_views_dialog, ATK_STATE_ACTIVE, FALSE);
  if (new_views_dialog)
    atk_object_notify_state_change(new_views_dialog, ATK_STATE_ACTIVE, TRUE);
}

void AXPlatformNodeAuraLinux::OnFocused() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  if (atk_object::GetRole(atk_object) == ATK_ROLE_FRAME) {
    OnWindowActivated();
    return;
  }

  if (atk_object == g_current_focused)
    return;

  SetActiveViewsDialog();

  AtkObject* old_effective_focus = g_current_active_descendant
                                       ? g_current_active_descendant
                                       : g_current_focused;
  if (old_effective_focus) {
    g_signal_emit_by_name(old_effective_focus, "focus-event", false);
    atk_object_notify_state_change(ATK_OBJECT(old_effective_focus),
                                   ATK_STATE_FOCUSED, false);
  }

  SetWeakGPtrToAtkObject(&g_current_focused, atk_object);
  AtkObject* descendant = GetActiveDescendantOfCurrentFocused();
  SetWeakGPtrToAtkObject(&g_current_active_descendant, descendant);

  AtkObject* new_effective_focus = g_current_active_descendant
                                       ? g_current_active_descendant
                                       : g_current_focused;
  g_signal_emit_by_name(new_effective_focus, "focus-event", true);
  atk_object_notify_state_change(ATK_OBJECT(new_effective_focus),
                                 ATK_STATE_FOCUSED, true);
}

void AXPlatformNodeAuraLinux::OnSelected() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;
  if (g_current_selected && !g_current_selected->GetData().GetBoolAttribute(
                                ax::mojom::BoolAttribute::kSelected)) {
    atk_object_notify_state_change(
        ATK_OBJECT(g_current_selected->GetOrCreateAtkObject()),
        ATK_STATE_SELECTED, false);
  }

  g_current_selected = this;
  if (ATK_IS_OBJECT(atk_object)) {
    atk_object_notify_state_change(ATK_OBJECT(atk_object), ATK_STATE_SELECTED,
                                   true);
  }

  if (SelectionAndFocusAreTheSame())
    OnFocused();
}

void AXPlatformNodeAuraLinux::OnSelectedChildrenChanged() {
  AtkObject* obj = GetOrCreateAtkObject();
  if (!obj)
    return;

  g_signal_emit_by_name(obj, "selection-changed", true);
}

bool AXPlatformNodeAuraLinux::SelectionAndFocusAreTheSame() {
  if (AXPlatformNodeBase* container = GetSelectionContainer()) {
    ax::mojom::Role role = container->GetData().role;

    // In the browser UI, menus and their descendants emit selection-related
    // events only, but we also want to emit platform focus-related events,
    // so we treat selection and focus the same for browser UI.
    if (role == ax::mojom::Role::kMenuBar || role == ax::mojom::Role::kMenu)
      return !GetDelegate()->IsWebContent();
    if (role == ax::mojom::Role::kListBox &&
        !container->GetData().HasState(ax::mojom::State::kMultiselectable)) {
      return container->GetDelegate()->GetFocus() ==
             container->GetNativeViewAccessible();
    }
  }

  // TODO(accessibility): GetSelectionContainer returns nullptr when the current
  // object is a descendant of a select element with a size of 1. Intentional?
  // For now, handle that scenario here.
  //
  // If the selection is changing on a collapsed select element, focus remains
  // on the select element and not the newly-selected descendant.
  if (AXPlatformNodeBase* parent = FromAtkObject(GetParent())) {
    if (parent->GetData().role == ax::mojom::Role::kMenuListPopup)
      return !parent->GetData().HasState(ax::mojom::State::kInvisible);
  }

  return false;
}

bool AXPlatformNodeAuraLinux::EmitsAtkTextEvents() const {
  // Objects which do not implement AtkText cannot emit AtkText events.
  if (!atk_object_ || !ATK_IS_TEXT(atk_object_))
    return false;

  // Objects which do implement AtkText, but are ignored or invisible should not
  // emit AtkText events.
  if (IsInvisibleOrIgnored())
    return false;

  // If this node is not a static text node, it supports the full AtkText
  // interface.
  if (GetAtkRole() != kStaticRole)
    return true;

  // If this node has children it is not a static text leaf node and supports
  // the full AtkText interface.
  if (GetChildCount())
    return true;

  return false;
}

void AXPlatformNodeAuraLinux::GetFullSelection(int32_t* anchor_node_id,
                                               int* anchor_offset,
                                               int32_t* focus_node_id,
                                               int* focus_offset) {
  DCHECK(anchor_node_id);
  DCHECK(anchor_offset);
  DCHECK(focus_node_id);
  DCHECK(focus_offset);

  if (IsPlainTextField() &&
      GetIntAttribute(ax::mojom::IntAttribute::kTextSelStart, anchor_offset) &&
      GetIntAttribute(ax::mojom::IntAttribute::kTextSelEnd, focus_offset)) {
    int32_t node_id = GetData().id != -1 ? GetData().id : GetUniqueId();
    *anchor_node_id = *focus_node_id = node_id;
    return;
  }

  AXTree::Selection selection = GetDelegate()->GetUnignoredSelection();
  *anchor_node_id = selection.anchor_object_id;
  *anchor_offset = selection.anchor_offset;
  *focus_node_id = selection.focus_object_id;
  *focus_offset = selection.focus_offset;
}

AXPlatformNodeAuraLinux& AXPlatformNodeAuraLinux::FindEditableRootOrDocument() {
  if (GetAtkRole() == ATK_ROLE_DOCUMENT_WEB)
    return *this;
  if (GetData().GetBoolAttribute(ax::mojom::BoolAttribute::kEditableRoot))
    return *this;
  if (auto* parent = FromAtkObject(GetParent()))
    return parent->FindEditableRootOrDocument();
  return *this;
}

AXPlatformNodeAuraLinux* AXPlatformNodeAuraLinux::FindCommonAncestor(
    AXPlatformNodeAuraLinux* other) {
  if (this == other || other->IsDescendantOf(this))
    return this;
  if (auto* parent = FromAtkObject(GetParent()))
    return parent->FindCommonAncestor(other);
  return nullptr;
}

void AXPlatformNodeAuraLinux::UpdateSelectionInformation(int32_t anchor_node_id,
                                                         int anchor_offset,
                                                         int32_t focus_node_id,
                                                         int focus_offset) {
  had_nonzero_width_selection =
      focus_node_id != anchor_node_id || focus_offset != anchor_offset;
  current_caret_ = std::make_pair(focus_node_id, focus_offset);
}

void AXPlatformNodeAuraLinux::EmitSelectionChangedSignal(bool had_selection) {
  if (!EmitsAtkTextEvents()) {
    if (auto* parent = FromAtkObject(GetParent()))
      parent->EmitSelectionChangedSignal(had_selection);
    return;
  }

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;
  DCHECK(ATK_IS_TEXT(atk_object));

  // ATK does not consider a collapsed selection a selection, so
  // when the collapsed selection changes (caret movement), we should
  // avoid sending text-selection-changed events.
  if (HasSelection() || had_selection)
    g_signal_emit_by_name(atk_object, "text-selection-changed");
}

void AXPlatformNodeAuraLinux::EmitCaretChangedSignal() {
  if (!EmitsAtkTextEvents()) {
    if (auto* parent = FromAtkObject(GetParent()))
      parent->EmitCaretChangedSignal();
    return;
  }

  DCHECK(HasCaret());
  std::pair<int, int> selection = GetSelectionOffsetsForAtk();

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  DCHECK(ATK_IS_TEXT(atk_object));
  g_signal_emit_by_name(atk_object, "text-caret-moved",
                        UTF16ToUnicodeOffsetInText(selection.second));
}

void AXPlatformNodeAuraLinux::OnTextAttributesChanged() {
  if (!EmitsAtkTextEvents()) {
    if (auto* parent = FromAtkObject(GetParent()))
      parent->OnTextAttributesChanged();
    return;
  }

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  DCHECK(ATK_IS_TEXT(atk_object));
  g_signal_emit_by_name(atk_object, "text-attributes-changed");
}

void AXPlatformNodeAuraLinux::OnTextSelectionChanged() {
  int32_t anchor_node_id, focus_node_id;
  int anchor_offset, focus_offset;
  GetFullSelection(&anchor_node_id, &anchor_offset, &focus_node_id,
                   &focus_offset);

  auto* anchor_node = static_cast<AXPlatformNodeAuraLinux*>(
      GetDelegate()->GetFromNodeID(anchor_node_id));
  auto* focus_node = static_cast<AXPlatformNodeAuraLinux*>(
      GetDelegate()->GetFromNodeID(focus_node_id));
  if (!anchor_node || !focus_node)
    return;

  AXPlatformNodeAuraLinux& editable_root = FindEditableRootOrDocument();
  AXPlatformNodeAuraLinux* common_ancestor =
      focus_node->FindCommonAncestor(anchor_node);
  if (common_ancestor) {
    common_ancestor->EmitSelectionChangedSignal(
        editable_root.HadNonZeroWidthSelection());
  }

  // It's possible for the selection to change and for the caret to stay in
  // place. This might happen if the selection is totally reset with a
  // different anchor node, but the same focus node. We should avoid sending a
  // caret changed signal in that case.
  std::pair<int32_t, int> prev_caret = editable_root.GetCurrentCaret();
  if (prev_caret.first != focus_node_id || prev_caret.second != focus_offset)
    focus_node->EmitCaretChangedSignal();

  editable_root.UpdateSelectionInformation(anchor_node_id, anchor_offset,
                                           focus_node_id, focus_offset);
}

bool AXPlatformNodeAuraLinux::SupportsSelectionWithAtkSelection() {
  return SupportsToggle(GetData().role) ||
         GetData().role == ax::mojom::Role::kListBoxOption;
}

void AXPlatformNodeAuraLinux::OnDescriptionChanged() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  std::string description;
  GetStringAttribute(ax::mojom::StringAttribute::kDescription, &description);

  AtkPropertyValues property_values;
  property_values.property_name = "accessible-description";
  property_values.new_value = G_VALUE_INIT;
  g_value_init(&property_values.new_value, G_TYPE_STRING);
  g_value_set_string(&property_values.new_value, description.c_str());
  g_signal_emit_by_name(G_OBJECT(atk_object),
                        "property-change::accessible-description",
                        &property_values, nullptr);
  g_value_unset(&property_values.new_value);
}

void AXPlatformNodeAuraLinux::OnSortDirectionChanged() {
  AXPlatformNodeBase* table = GetTable();
  if (!table)
    return;

  AtkObject* atk_table = table->GetNativeViewAccessible();
  DCHECK(ATK_IS_TABLE(atk_table));

  if (GetData().role == ax::mojom::Role::kColumnHeader)
    g_signal_emit_by_name(atk_table, "row-reordered");
  else if (GetData().role == ax::mojom::Role::kRowHeader)
    g_signal_emit_by_name(atk_table, "column-reordered");
}

void AXPlatformNodeAuraLinux::OnValueChanged() {
  // For the AtkText interface to work on non-web content nodes, we need to
  // update the nodes' hypertext and trigger text change signals when the value
  // changes. Otherwise, for web and PDF content, this is handled by
  // "BrowserAccessibilityAuraLinux".
  if (!GetDelegate()->IsWebContent())
    UpdateHypertext();

  if (!GetData().IsRangeValueSupported())
    return;

  float float_val;
  if (!GetFloatAttribute(ax::mojom::FloatAttribute::kValueForRange, &float_val))
    return;

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  AtkPropertyValues property_values;
  property_values.property_name = "accessible-value";

  property_values.new_value = G_VALUE_INIT;
  g_value_init(&property_values.new_value, G_TYPE_DOUBLE);
  g_value_set_double(&property_values.new_value,
                     static_cast<double>(float_val));
  g_signal_emit_by_name(G_OBJECT(atk_object),
                        "property-change::accessible-value", &property_values,
                        nullptr);
}

void AXPlatformNodeAuraLinux::OnNameChanged() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object) {
    return;
  }
  std::string previous_accessible_name = accessible_name_;
  // Calling atk_object_get_name will update the value of accessible_name_.
  if (!g_strcmp0(atk_object::GetName(atk_object),
                 previous_accessible_name.c_str()))
    return;

  g_object_notify(G_OBJECT(atk_object), "accessible-name");
}

void AXPlatformNodeAuraLinux::OnDocumentTitleChanged() {
  if (!g_active_top_level_frame)
    return;

  // We always want to notify on the top frame.
  AXPlatformNodeAuraLinux* window = FromAtkObject(g_active_top_level_frame);
  if (window)
    window->OnNameChanged();
}

void AXPlatformNodeAuraLinux::OnSubtreeCreated() {
  // We might not have a parent, in that case we don't need to send the event.
  // We also don't want to notify if this is an ignored node
  if (!GetParent() || GetData().IsIgnored())
    return;

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  g_signal_emit_by_name(GetParent(), "children-changed::add",
                        GetIndexInParent().value_or(-1), atk_object);
}

void AXPlatformNodeAuraLinux::OnSubtreeWillBeDeleted() {
  // There is a chance there won't be a parent as we're in the deletion process.
  // We also don't want to notify if this is an ignored node
  if (!GetParent() || GetData().IsIgnored())
    return;

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  g_signal_emit_by_name(GetParent(), "children-changed::remove",
                        GetIndexInParent().value_or(-1), atk_object);
}

void AXPlatformNodeAuraLinux::OnParentChanged() {
  if (!atk_object_)
    return;

  AtkPropertyValues property_values;
  property_values.property_name = "accessible-parent";
  property_values.new_value = G_VALUE_INIT;
  g_value_init(&property_values.new_value, G_TYPE_OBJECT);
  g_value_set_object(&property_values.new_value, GetParent());
  g_signal_emit_by_name(G_OBJECT(atk_object_),
                        "property-change::accessible-parent", &property_values,
                        nullptr);
  g_value_unset(&property_values.new_value);
}

void AXPlatformNodeAuraLinux::OnInvalidStatusChanged() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  atk_object_notify_state_change(
      ATK_OBJECT(atk_object), ATK_STATE_INVALID_ENTRY,
      GetData().GetInvalidState() != ax::mojom::InvalidState::kFalse);
}

void AXPlatformNodeAuraLinux::OnAlertShown() {
  DCHECK(ui::IsAlert(GetData().role));
  atk_object_notify_state_change(ATK_OBJECT(GetOrCreateAtkObject()),
                                 ATK_STATE_SHOWING, TRUE);
}

void AXPlatformNodeAuraLinux::RunPostponedEvents() {
  if (window_activate_event_postponed_) {
    OnWindowActivated();
    window_activate_event_postponed_ = false;
  }
}

void AXPlatformNodeAuraLinux::NotifyAccessibilityEvent(
    ax::mojom::Event event_type) {
  if (!GetOrCreateAtkObject())
    return;
  AXPlatformNodeBase::NotifyAccessibilityEvent(event_type);
  switch (event_type) {
    // kMenuStart/kMenuEnd: the menu system has started / stopped.
    // kMenuPopupStart/kMenuPopupEnd: an individual menu/submenu has
    // opened/closed.
    case ax::mojom::Event::kMenuPopupStart:
      OnMenuPopupStart();
      break;
    case ax::mojom::Event::kMenuPopupEnd:
      OnMenuPopupEnd();
      break;
    case ax::mojom::Event::kActiveDescendantChanged:
      OnActiveDescendantChanged();
      break;
    case ax::mojom::Event::kCheckedStateChanged:
      OnCheckedStateChanged();
      break;
    case ax::mojom::Event::kExpandedChanged:
    case ax::mojom::Event::kStateChanged:
      OnExpandedStateChanged(GetData().HasState(ax::mojom::State::kExpanded));
      break;
    case ax::mojom::Event::kFocus:
    case ax::mojom::Event::kFocusContext:
      OnFocused();
      break;
    case ax::mojom::Event::kSelection:
      OnSelected();
      // When changing tabs also fire a name changed event.
      if (GetData().role == ax::mojom::Role::kTab)
        OnDocumentTitleChanged();
      break;
    case ax::mojom::Event::kSelectedChildrenChanged:
      OnSelectedChildrenChanged();
      break;
    case ax::mojom::Event::kTextChanged:
      OnNameChanged();
      break;
    case ax::mojom::Event::kTextSelectionChanged:
      OnTextSelectionChanged();
      break;
    case ax::mojom::Event::kValueChanged:
      OnValueChanged();
      break;
    case ax::mojom::Event::kInvalidStatusChanged:
      OnInvalidStatusChanged();
      break;
    case ax::mojom::Event::kWindowActivated:
      if (AtkUtilAuraLinux::GetInstance()->IsAtSpiReady()) {
        OnWindowActivated();
      } else {
        AtkUtilAuraLinux::GetInstance()->PostponeEventsFor(this);
        window_activate_event_postponed_ = true;
      }
      break;
    case ax::mojom::Event::kWindowDeactivated:
      if (AtkUtilAuraLinux::GetInstance()->IsAtSpiReady()) {
        OnWindowDeactivated();
      } else {
        AtkUtilAuraLinux::GetInstance()->CancelPostponedEventsFor(this);
        window_activate_event_postponed_ = false;
      }
      break;
    case ax::mojom::Event::kWindowVisibilityChanged:
      OnWindowVisibilityChanged();
      break;
    case ax::mojom::Event::kLoadComplete:
    case ax::mojom::Event::kDocumentTitleChanged:
      // Sometimes, e.g. upon navigating away from the page, the tree is
      // rebuilt rather than modified. The kDocumentTitleChanged event occurs
      // prior to the rebuild and so is added on the previous root node. When
      // the tree is rebuilt and the old node removed, the events on the old
      // node are removed and no new kDocumentTitleChanged will be emitted. To
      // ensure we still fire the event, though, we also pay attention to
      // kLoadComplete.
      OnDocumentTitleChanged();
      break;
    case ax::mojom::Event::kAlert:
      OnAlertShown();
      break;
    default:
      break;
  }
}

base::Optional<std::pair<int, int>>
AXPlatformNodeAuraLinux::GetEmbeddedObjectIndicesForId(int id) {
  auto iterator =
      std::find(hypertext_.hyperlinks.begin(), hypertext_.hyperlinks.end(), id);
  if (iterator == hypertext_.hyperlinks.end())
    return base::nullopt;
  int hyperlink_index = std::distance(hypertext_.hyperlinks.begin(), iterator);

  auto offset = std::find_if(hypertext_.hyperlink_offset_to_index.begin(),
                             hypertext_.hyperlink_offset_to_index.end(),
                             [&](const std::pair<int32_t, int32_t>& pair) {
                               return pair.second == hyperlink_index;
                             });
  if (offset == hypertext_.hyperlink_offset_to_index.end())
    return base::nullopt;

  return std::make_pair(UTF16ToUnicodeOffsetInText(offset->first),
                        UTF16ToUnicodeOffsetInText(offset->first + 1));
}

base::Optional<std::pair<int, int>>
AXPlatformNodeAuraLinux::GetEmbeddedObjectIndices() {
  auto* parent = FromAtkObject(GetParent());
  if (!parent)
    return base::nullopt;
  return parent->GetEmbeddedObjectIndicesForId(GetUniqueId());
}

void AXPlatformNodeAuraLinux::UpdateHypertext() {
  EnsureAtkObjectIsValid();
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  AXHypertext old_hypertext = hypertext_;
  base::OffsetAdjuster::Adjustments old_adjustments = GetHypertextAdjustments();

  UpdateComputedHypertext();
  text_unicode_adjustments_ = base::nullopt;
  offset_to_text_attributes_.clear();

  if ((!GetData().HasState(ax::mojom::State::kEditable) ||
       GetData().GetRestriction() == ax::mojom::Restriction::kReadOnly) &&
      !IsInLiveRegion()) {
    return;
  }

  if (!EmitsAtkTextEvents())
    return;

  size_t shared_prefix, old_len, new_len;
  ComputeHypertextRemovedAndInserted(old_hypertext, &shared_prefix, &old_len,
                                     &new_len);
  if (old_len > 0) {
    base::string16 removed_substring =
        old_hypertext.hypertext.substr(shared_prefix, old_len);

    size_t shared_unicode_prefix = shared_prefix;
    base::OffsetAdjuster::AdjustOffset(old_adjustments, &shared_unicode_prefix);
    size_t shared_unicode_suffix = shared_prefix + old_len;
    base::OffsetAdjuster::AdjustOffset(old_adjustments, &shared_unicode_suffix);

    g_signal_emit_by_name(
        atk_object, "text-remove",
        shared_unicode_prefix,                  // position of removal
        shared_unicode_suffix - shared_prefix,  // length of removal
        base::UTF16ToUTF8(removed_substring).c_str());
  }

  if (new_len > 0) {
    base::string16 inserted_substring =
        hypertext_.hypertext.substr(shared_prefix, new_len);
    size_t shared_unicode_prefix = UTF16ToUnicodeOffsetInText(shared_prefix);
    size_t shared_unicode_suffix =
        UTF16ToUnicodeOffsetInText(shared_prefix + new_len);
    g_signal_emit_by_name(
        atk_object, "text-insert",
        shared_unicode_prefix,                          // position of insertion
        shared_unicode_suffix - shared_unicode_prefix,  // length of insertion
        base::UTF16ToUTF8(inserted_substring).c_str());
  }
}

const AXHypertext& AXPlatformNodeAuraLinux::GetAXHypertext() {
  return hypertext_;
}

const base::OffsetAdjuster::Adjustments&
AXPlatformNodeAuraLinux::GetHypertextAdjustments() {
  if (text_unicode_adjustments_.has_value())
    return *text_unicode_adjustments_;

  text_unicode_adjustments_.emplace();

  base::string16 text = GetHypertext();
  int32_t text_length = text.size();
  for (int32_t i = 0; i < text_length; i++) {
    uint32_t code_point;
    size_t original_i = i;
    base::ReadUnicodeCharacter(text.c_str(), text_length + 1, &i, &code_point);

    if ((i - original_i + 1) != 1) {
      text_unicode_adjustments_->push_back(
          base::OffsetAdjuster::Adjustment(original_i, i - original_i + 1, 1));
    }
  }

  return *text_unicode_adjustments_;
}

size_t AXPlatformNodeAuraLinux::UTF16ToUnicodeOffsetInText(
    size_t utf16_offset) {
  size_t unicode_offset = utf16_offset;
  base::OffsetAdjuster::AdjustOffset(GetHypertextAdjustments(),
                                     &unicode_offset);
  return unicode_offset;
}

size_t AXPlatformNodeAuraLinux::UnicodeToUTF16OffsetInText(int unicode_offset) {
  if (unicode_offset == kStringLengthOffset)
    return GetHypertext().size();

  size_t utf16_offset = unicode_offset;
  base::OffsetAdjuster::UnadjustOffset(GetHypertextAdjustments(),
                                       &utf16_offset);
  return utf16_offset;
}

int AXPlatformNodeAuraLinux::GetTextOffsetAtPoint(int x,
                                                  int y,
                                                  AtkCoordType atk_coord_type) {
  if (!GetExtentsRelativeToAtkCoordinateType(atk_coord_type).Contains(x, y))
    return -1;

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return -1;

  int count = atk_text::GetCharacterCount(ATK_TEXT(atk_object));
  for (int i = 0; i < count; i++) {
    int out_x, out_y, out_width, out_height;
    atk_text::GetCharacterExtents(ATK_TEXT(atk_object), i, &out_x, &out_y,
                                  &out_width, &out_height, atk_coord_type);
    gfx::Rect rect(out_x, out_y, out_width, out_height);
    if (rect.Contains(x, y))
      return i;
  }
  return -1;
}

gfx::Vector2d AXPlatformNodeAuraLinux::GetParentOriginInScreenCoordinates()
    const {
  AtkObject* parent = GetParent();
  if (!parent)
    return gfx::Vector2d();

  const AXPlatformNode* parent_node =
      AXPlatformNode::FromNativeViewAccessible(parent);
  if (!parent)
    return gfx::Vector2d();

  return parent_node->GetDelegate()
      ->GetBoundsRect(AXCoordinateSystem::kScreenDIPs,
                      AXClippingBehavior::kUnclipped)
      .OffsetFromOrigin();
}

gfx::Vector2d AXPlatformNodeAuraLinux::GetParentFrameOriginInScreenCoordinates()
    const {
  AtkObject* frame = FindAtkObjectParentFrame(atk_object_);
  if (!frame)
    return gfx::Vector2d();

  const AXPlatformNode* frame_node =
      AXPlatformNode::FromNativeViewAccessible(frame);
  if (!frame_node)
    return gfx::Vector2d();

  return frame_node->GetDelegate()
      ->GetBoundsRect(AXCoordinateSystem::kScreenDIPs,
                      AXClippingBehavior::kUnclipped)
      .OffsetFromOrigin();
}

gfx::Rect AXPlatformNodeAuraLinux::GetExtentsRelativeToAtkCoordinateType(
    AtkCoordType coord_type) const {
  gfx::Rect extents = delegate_->GetBoundsRect(AXCoordinateSystem::kScreenDIPs,
                                               AXClippingBehavior::kUnclipped);
  switch (coord_type) {
    case ATK_XY_SCREEN:
      break;
    case ATK_XY_WINDOW: {
      gfx::Vector2d window_origin = -GetParentFrameOriginInScreenCoordinates();
      extents.Offset(window_origin);
      break;
    }
#if defined(ATK_230)
    case ATK_XY_PARENT: {
      gfx::Vector2d parent_origin = -GetParentOriginInScreenCoordinates();
      extents.Offset(parent_origin);
      break;
    }
#endif
  }

  return extents;
}

void AXPlatformNodeAuraLinux::GetExtents(gint* x,
                                         gint* y,
                                         gint* width,
                                         gint* height,
                                         AtkCoordType coord_type) {
  gfx::Rect extents = GetExtentsRelativeToAtkCoordinateType(coord_type);
  if (x)
    *x = extents.x();
  if (y)
    *y = extents.y();
  if (width)
    *width = extents.width();
  if (height)
    *height = extents.height();
}

void AXPlatformNodeAuraLinux::GetPosition(gint* x,
                                          gint* y,
                                          AtkCoordType coord_type) {
  gfx::Rect extents = GetExtentsRelativeToAtkCoordinateType(coord_type);
  if (x)
    *x = extents.x();
  if (y)
    *y = extents.y();
}

void AXPlatformNodeAuraLinux::GetSize(gint* width, gint* height) {
  gfx::Rect rect_size = gfx::ToEnclosingRect(GetData().relative_bounds.bounds);
  if (width)
    *width = rect_size.width();
  if (height)
    *height = rect_size.height();
}

gfx::NativeViewAccessible
AXPlatformNodeAuraLinux::HitTestSync(gint x, gint y, AtkCoordType coord_type) {
  gfx::Point scroll_to(x, y);
  scroll_to = ConvertPointToScreenCoordinates(scroll_to, coord_type);

  AXPlatformNode* current_result = this;
  while (true) {
    gfx::NativeViewAccessible hit_child =
        current_result->GetDelegate()->HitTestSync(scroll_to.x(),
                                                   scroll_to.y());
    if (!hit_child)
      return nullptr;
    AXPlatformNode* hit_child_node =
        AXPlatformNode::FromNativeViewAccessible(hit_child);
    if (!hit_child_node || !hit_child_node->IsDescendantOf(current_result))
      break;

    // If we get the same node, we're done.
    if (hit_child_node == current_result)
      break;

    // Continue to check recursively. That's because HitTestSync may have
    // returned the best result within a particular accessibility tree,
    // but we might need to recurse further in a tree of a different type
    // (for example, from Views to Web).
    current_result = hit_child_node;
  }
  return current_result->GetNativeViewAccessible();
}

bool AXPlatformNodeAuraLinux::GrabFocus() {
  AXActionData action_data;
  action_data.action = ax::mojom::Action::kFocus;
  return delegate_->AccessibilityPerformAction(action_data);
}

bool AXPlatformNodeAuraLinux::FocusFirstFocusableAncestorInWebContent() {
  if (!GetDelegate()->IsWebContent())
    return false;

  // Don't cross document boundaries in order to avoid having this operation
  // cross iframe boundaries or escape to non-document UI elements.
  if (GetAtkRole() == ATK_ROLE_DOCUMENT_WEB)
    return false;

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return false;

  if (GetData().HasState(ax::mojom::State::kFocusable) ||
      SelectionAndFocusAreTheSame()) {
    if (g_current_focused != atk_object)
      GrabFocus();
    return true;
  }

  auto* parent = FromAtkObject(GetParent());
  if (!parent)
    return false;

  // If any of the siblings of this element are focusable, focusing the parent
  // would be like moving the focus position backward, so we should fall back
  // to setting the sequential focus navigation starting point.
  for (auto child_iterator_ptr = parent->GetDelegate()->ChildrenBegin();
       *child_iterator_ptr != *parent->GetDelegate()->ChildrenEnd();
       ++(*child_iterator_ptr)) {
    auto* child = FromAtkObject(child_iterator_ptr->GetNativeViewAccessible());
    if (!child || child == this)
      continue;

    if (child->GetData().HasState(ax::mojom::State::kFocusable) ||
        child->SelectionAndFocusAreTheSame()) {
      return false;
    }
  }

  return parent->FocusFirstFocusableAncestorInWebContent();
}

bool AXPlatformNodeAuraLinux::SetSequentialFocusNavigationStartingPoint() {
  AXActionData action_data;
  action_data.action =
      ax::mojom::Action::kSetSequentialFocusNavigationStartingPoint;
  return delegate_->AccessibilityPerformAction(action_data);
}

bool AXPlatformNodeAuraLinux::
    GrabFocusOrSetSequentialFocusNavigationStartingPoint() {
  // First we try to grab focus on this node if any ancestor in the same
  // document is focusable. Otherwise we set the sequential navigation starting
  // point.
  if (!FocusFirstFocusableAncestorInWebContent())
    return SetSequentialFocusNavigationStartingPoint();
  else
    return true;
}

bool AXPlatformNodeAuraLinux::
    GrabFocusOrSetSequentialFocusNavigationStartingPointAtOffset(int offset) {
  int child_count = delegate_->GetChildCount();
  if (IsPlainTextField() || child_count == 0)
    return GrabFocusOrSetSequentialFocusNavigationStartingPoint();

  // When this node has children, we walk through them to figure out what child
  // node should get focus. We are essentially repeating the process used when
  // building the hypertext here.
  int current_offset = 0;
  for (int i = 0; i < child_count; ++i) {
    auto* child = FromAtkObject(delegate_->ChildAtIndex(i));
    if (!child)
      continue;

    if (child->IsText()) {
      current_offset += child->GetName().size();
    } else {
      // Add an offset for the embedded character.
      current_offset += 1;
    }

    // If the offset is larger than our size, try to work with the last child,
    // which is also the behavior of SetCaretOffset.
    if (offset <= current_offset || i == child_count - 1)
      return child->GrabFocusOrSetSequentialFocusNavigationStartingPoint();
  }

  NOTREACHED();
  return false;
}

bool AXPlatformNodeAuraLinux::DoDefaultAction() {
  AXActionData action_data;
  action_data.action = ax::mojom::Action::kDoDefault;
  return delegate_->AccessibilityPerformAction(action_data);
}

const gchar* AXPlatformNodeAuraLinux::GetDefaultActionName() {
  int action;
  if (!GetIntAttribute(ax::mojom::IntAttribute::kDefaultActionVerb, &action))
    return nullptr;

  std::string action_verb =
      ui::ToString(static_cast<ax::mojom::DefaultActionVerb>(action));
  ATK_AURALINUX_RETURN_STRING(action_verb);
}

AtkAttributeSet* AXPlatformNodeAuraLinux::GetAtkAttributes() {
  AtkAttributeSet* attribute_list = nullptr;
  ComputeAttributes(&attribute_list);
  return attribute_list;
}

AtkStateType AXPlatformNodeAuraLinux::GetAtkStateTypeForCheckableNode() {
  if (GetData().GetCheckedState() == ax::mojom::CheckedState::kMixed)
    return ATK_STATE_INDETERMINATE;
  if (IsPlatformCheckable())
    return ATK_STATE_CHECKED;
  return ATK_STATE_PRESSED;
}

// AtkDocumentHelpers

const gchar* AXPlatformNodeAuraLinux::GetDocumentAttributeValue(
    const gchar* attribute) const {
  if (!g_ascii_strcasecmp(attribute, "DocType"))
    return delegate_->GetTreeData().doctype.c_str();
  else if (!g_ascii_strcasecmp(attribute, "MimeType"))
    return delegate_->GetTreeData().mimetype.c_str();
  else if (!g_ascii_strcasecmp(attribute, "Title"))
    return delegate_->GetTreeData().title.c_str();
  else if (!g_ascii_strcasecmp(attribute, "URI"))
    return delegate_->GetTreeData().url.c_str();

  return nullptr;
}

AtkAttributeSet* AXPlatformNodeAuraLinux::GetDocumentAttributes() const {
  AtkAttributeSet* attribute_set = nullptr;
  const gchar* doc_attributes[] = {"DocType", "MimeType", "Title", "URI"};
  const gchar* value = nullptr;

  for (unsigned i = 0; i < G_N_ELEMENTS(doc_attributes); i++) {
    value = GetDocumentAttributeValue(doc_attributes[i]);
    if (value) {
      attribute_set = PrependAtkAttributeToAtkAttributeSet(
          doc_attributes[i], value, attribute_set);
    }
  }

  return attribute_set;
}

//
// AtkHyperlink helpers
//

AtkHyperlink* AXPlatformNodeAuraLinux::GetAtkHyperlink() {
  if (atk_hyperlink_)
    return atk_hyperlink_;

  atk_hyperlink_ =
      ATK_HYPERLINK(g_object_new(AX_PLATFORM_ATK_HYPERLINK_TYPE, 0));
  ax_platform_atk_hyperlink_set_object(
      AX_PLATFORM_ATK_HYPERLINK(atk_hyperlink_), this);
  return atk_hyperlink_;
}

//
// Misc helpers
//

void AXPlatformNodeAuraLinux::GetFloatAttributeInGValue(
    ax::mojom::FloatAttribute attr,
    GValue* value) {
  float float_val;
  if (GetFloatAttribute(attr, &float_val)) {
    memset(value, 0, sizeof(*value));
    g_value_init(value, G_TYPE_FLOAT);
    g_value_set_float(value, float_val);
  }
}

void AXPlatformNodeAuraLinux::AddAttributeToList(const char* name,
                                                 const char* value,
                                                 AtkAttributeSet** attributes) {
  *attributes = PrependAtkAttributeToAtkAttributeSet(name, value, *attributes);
}

void AXPlatformNodeAuraLinux::SetDocumentParent(
    AtkObject* new_document_parent) {
  DCHECK(GetAtkRole() == ATK_ROLE_FRAME);
  SetWeakGPtrToAtkObject(&document_parent_, new_document_parent);
}

bool AXPlatformNodeAuraLinux::IsNameExposed() {
  const AXNodeData& data = GetData();
  switch (data.role) {
    case ax::mojom::Role::kListMarker:
      return !GetChildCount();
    default:
      return true;
  }
}

int AXPlatformNodeAuraLinux::GetCaretOffset() {
  if (!HasCaret()) {
    base::Optional<FindInPageResultInfo> result =
        GetSelectionOffsetsFromFindInPage();
    AtkObject* atk_object = GetOrCreateAtkObject();
    if (!atk_object)
      return -1;
    if (result.has_value() && result->node == atk_object)
      return UTF16ToUnicodeOffsetInText(result->end_offset);
    return -1;
  }

  std::pair<int, int> selection = GetSelectionOffsetsForAtk();
  return UTF16ToUnicodeOffsetInText(selection.second);
}

bool AXPlatformNodeAuraLinux::SetCaretOffset(int offset) {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return false;

  int character_count = atk_text_get_character_count(ATK_TEXT(atk_object));
  if (offset < 0 || offset > character_count)
    offset = character_count;

  // Even if we don't change anything, we still want to act like we
  // were successful.
  if (offset == GetCaretOffset() && !HasSelection())
    return true;

  offset = UnicodeToUTF16OffsetInText(offset);
  if (!SetHypertextSelection(offset, offset))
    return false;

  return true;
}

bool AXPlatformNodeAuraLinux::SetTextSelectionForAtkText(int start_offset,
                                                         int end_offset) {
  start_offset = UnicodeToUTF16OffsetInText(start_offset);
  end_offset = UnicodeToUTF16OffsetInText(end_offset);

  base::string16 text = GetHypertext();
  if (start_offset < 0 || start_offset > int{text.length()})
    return false;
  if (end_offset < 0 || end_offset > int{text.length()})
    return false;

  // We must put these in the correct order so that we can do
  // a comparison with the existing start and end below.
  if (end_offset < start_offset)
    std::swap(start_offset, end_offset);

  // Even if we don't change anything, we still want to act like we
  // were successful.
  std::pair<int, int> old_offsets = GetSelectionOffsetsForAtk();
  if (old_offsets.first == start_offset && old_offsets.second == end_offset)
    return true;

  if (!SetHypertextSelection(start_offset, end_offset))
    return false;

  return true;
}

bool AXPlatformNodeAuraLinux::HasSelection() {
  std::pair<int, int> selection = GetSelectionOffsetsForAtk();
  return selection.first >= 0 && selection.second >= 0 &&
         selection.first != selection.second;
}

void AXPlatformNodeAuraLinux::GetSelectionExtents(int* start_offset,
                                                  int* end_offset) {
  if (start_offset)
    *start_offset = 0;
  if (end_offset)
    *end_offset = 0;

  std::pair<int, int> selection = GetSelectionOffsetsForAtk();
  if (selection.first < 0 || selection.second < 0 ||
      selection.first == selection.second)
    return;

  // We should ignore the direction of the selection when exposing start and
  // end offsets. According to the ATK documentation the end offset is always
  // the offset immediately past the end of the selection. This wouldn't make
  // sense if end < start.
  if (selection.second < selection.first)
    std::swap(selection.first, selection.second);

  selection.first = UTF16ToUnicodeOffsetInText(selection.first);
  selection.second = UTF16ToUnicodeOffsetInText(selection.second);

  if (start_offset)
    *start_offset = selection.first;
  if (end_offset)
    *end_offset = selection.second;
}

// Since this method doesn't return a static gchar*, we expect the caller of
// atk_text_get_selection to free the return value.
gchar* AXPlatformNodeAuraLinux::GetSelectionWithText(int* start_offset,
                                                     int* end_offset) {
  int selection_start, selection_end;
  GetSelectionExtents(&selection_start, &selection_end);

  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return nullptr;

  if (selection_start < 0 || selection_end < 0 ||
      selection_start == selection_end) {
    base::Optional<FindInPageResultInfo> find_in_page_result =
        GetSelectionOffsetsFromFindInPage();
    if (!find_in_page_result.has_value() ||
        find_in_page_result->node != atk_object) {
      *start_offset = 0;
      *end_offset = 0;
      return nullptr;
    }

    selection_start = find_in_page_result->start_offset;
    selection_end = find_in_page_result->end_offset;
  }

  selection_start = UTF16ToUnicodeOffsetInText(selection_start);
  selection_end = UTF16ToUnicodeOffsetInText(selection_end);
  if (selection_start < 0 || selection_end < 0 ||
      selection_start == selection_end) {
    return nullptr;
  }

  if (start_offset)
    *start_offset = selection_start;
  if (end_offset)
    *end_offset = selection_end;
  return atk_text::GetText(ATK_TEXT(atk_object), selection_start,
                           selection_end);
}

bool AXPlatformNodeAuraLinux::IsInLiveRegion() {
  return GetData().HasStringAttribute(
      ax::mojom::StringAttribute::kContainerLiveStatus);
}

#if defined(ATK_230)
void AXPlatformNodeAuraLinux::ScrollToPoint(AtkCoordType atk_coord_type,
                                            int x,
                                            int y) {
  gfx::Point scroll_to(x, y);
  scroll_to = ConvertPointToScreenCoordinates(scroll_to, atk_coord_type);

  AXActionData action_data;
  action_data.target_node_id = GetData().id;
  action_data.action = ax::mojom::Action::kScrollToPoint;
  action_data.target_point = scroll_to;
  GetDelegate()->AccessibilityPerformAction(action_data);
}

void AXPlatformNodeAuraLinux::ScrollNodeRectIntoView(
    gfx::Rect rect,
    AtkScrollType atk_scroll_type) {
  AXActionData action_data;
  action_data.target_node_id = GetData().id;
  action_data.action = ax::mojom::Action::kScrollToMakeVisible;
  action_data.target_rect = rect;

  action_data.scroll_behavior = ax::mojom::ScrollBehavior::kScrollIfVisible;
  action_data.horizontal_scroll_alignment = ax::mojom::ScrollAlignment::kNone;
  action_data.vertical_scroll_alignment = ax::mojom::ScrollAlignment::kNone;

  switch (atk_scroll_type) {
    case ATK_SCROLL_TOP_LEFT:
      action_data.vertical_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentTop;
      action_data.horizontal_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentLeft;
      break;
    case ATK_SCROLL_BOTTOM_RIGHT:
      action_data.horizontal_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentRight;
      action_data.vertical_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentBottom;
      break;
    case ATK_SCROLL_TOP_EDGE:
      action_data.vertical_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentTop;
      break;
    case ATK_SCROLL_BOTTOM_EDGE:
      action_data.vertical_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentBottom;
      break;
    case ATK_SCROLL_LEFT_EDGE:
      action_data.horizontal_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentLeft;
      break;
    case ATK_SCROLL_RIGHT_EDGE:
      action_data.horizontal_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentRight;
      break;
    case ATK_SCROLL_ANYWHERE:
      action_data.horizontal_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentClosestEdge;
      action_data.vertical_scroll_alignment =
          ax::mojom::ScrollAlignment::kScrollAlignmentClosestEdge;
      break;
  }

  GetDelegate()->AccessibilityPerformAction(action_data);
}

void AXPlatformNodeAuraLinux::ScrollNodeIntoView(
    AtkScrollType atk_scroll_type) {
  gfx::Rect rect = GetDelegate()->GetBoundsRect(AXCoordinateSystem::kScreenDIPs,
                                                AXClippingBehavior::kUnclipped);
  rect -= rect.OffsetFromOrigin();
  ScrollNodeRectIntoView(rect, atk_scroll_type);
}
#endif  // defined(ATK_230)

#if defined(ATK_232)
base::Optional<gfx::Rect>
AXPlatformNodeAuraLinux::GetUnclippedHypertextRangeBoundsRect(int start_offset,
                                                              int end_offset) {
  start_offset = UnicodeToUTF16OffsetInText(start_offset);
  end_offset = UnicodeToUTF16OffsetInText(end_offset);

  base::string16 text = GetHypertext();
  if (start_offset < 0 || start_offset > int{text.length()})
    return base::nullopt;
  if (end_offset < 0 || end_offset > int{text.length()})
    return base::nullopt;

  if (end_offset < start_offset)
    std::swap(start_offset, end_offset);

  return GetDelegate()->GetHypertextRangeBoundsRect(
      UnicodeToUTF16OffsetInText(start_offset),
      UnicodeToUTF16OffsetInText(end_offset), AXCoordinateSystem::kScreenDIPs,
      AXClippingBehavior::kUnclipped);
}

bool AXPlatformNodeAuraLinux::ScrollSubstringIntoView(
    AtkScrollType atk_scroll_type,
    int start_offset,
    int end_offset) {
  base::Optional<gfx::Rect> optional_rect =
      GetUnclippedHypertextRangeBoundsRect(start_offset, end_offset);
  if (!optional_rect.has_value())
    return false;

  gfx::Rect rect = *optional_rect;
  gfx::Rect node_rect = GetDelegate()->GetBoundsRect(
      AXCoordinateSystem::kScreenDIPs, AXClippingBehavior::kUnclipped);
  rect -= node_rect.OffsetFromOrigin();
  ScrollNodeRectIntoView(rect, atk_scroll_type);

  return true;
}

bool AXPlatformNodeAuraLinux::ScrollSubstringToPoint(
    int start_offset,
    int end_offset,
    AtkCoordType atk_coord_type,
    int x,
    int y) {
  base::Optional<gfx::Rect> optional_rect =
      GetUnclippedHypertextRangeBoundsRect(start_offset, end_offset);
  if (!optional_rect.has_value())
    return false;

  gfx::Rect rect = *optional_rect;
  gfx::Rect node_rect = GetDelegate()->GetBoundsRect(
      AXCoordinateSystem::kScreenDIPs, AXClippingBehavior::kUnclipped);
  ScrollToPoint(atk_coord_type, x - (rect.x() - node_rect.x()),
                y - (rect.y() - node_rect.y()));

  return true;
}
#endif  // defined(ATK_232)

void AXPlatformNodeAuraLinux::ComputeStylesIfNeeded() {
  if (!offset_to_text_attributes_.empty())
    return;

  default_text_attributes_ = ComputeTextAttributes();
  TextAttributeMap attributes_map =
      GetDelegate()->ComputeTextAttributeMap(default_text_attributes_);
  offset_to_text_attributes_.swap(attributes_map);
}

int AXPlatformNodeAuraLinux::FindStartOfStyle(
    int start_offset,
    ax::mojom::MoveDirection direction) {
  int text_length = GetHypertext().length();
  DCHECK_GE(start_offset, 0);
  DCHECK_LE(start_offset, text_length);
  DCHECK(!offset_to_text_attributes_.empty());

  switch (direction) {
    case ax::mojom::MoveDirection::kBackward: {
      auto iterator = offset_to_text_attributes_.upper_bound(start_offset);
      --iterator;
      return iterator->first;
    }
    case ax::mojom::MoveDirection::kForward: {
      const auto iterator =
          offset_to_text_attributes_.upper_bound(start_offset);
      if (iterator == offset_to_text_attributes_.end())
        return text_length;
      return iterator->first;
    }
  }

  NOTREACHED();
  return start_offset;
}

const TextAttributeList& AXPlatformNodeAuraLinux::GetTextAttributes(
    int offset,
    int* start_offset,
    int* end_offset) {
  ComputeStylesIfNeeded();
  DCHECK(!offset_to_text_attributes_.empty());

  int utf16_offset = UnicodeToUTF16OffsetInText(offset);
  int style_start =
      FindStartOfStyle(utf16_offset, ax::mojom::MoveDirection::kBackward);
  int style_end =
      FindStartOfStyle(utf16_offset, ax::mojom::MoveDirection::kForward);

  auto iterator = offset_to_text_attributes_.find(style_start);
  DCHECK(iterator != offset_to_text_attributes_.end());

  SetIntPointerValueIfNotNull(start_offset,
                              UTF16ToUnicodeOffsetInText(style_start));
  SetIntPointerValueIfNotNull(end_offset,
                              UTF16ToUnicodeOffsetInText(style_end));

  if (iterator == offset_to_text_attributes_.end())
    return default_text_attributes_;

  return iterator->second;
}

const TextAttributeList& AXPlatformNodeAuraLinux::GetDefaultTextAttributes() {
  ComputeStylesIfNeeded();
  return default_text_attributes_;
}

void AXPlatformNodeAuraLinux::TerminateFindInPage() {
  ForgetCurrentFindInPageResult();
}

void AXPlatformNodeAuraLinux::ActivateFindInPageResult(int start_offset,
                                                       int end_offset) {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  DCHECK(ATK_IS_TEXT(atk_object));

  if (!EmitsAtkTextEvents()) {
    ActivateFindInPageInParent(start_offset, end_offset);
    return;
  }

  AtkObject* parent_doc = FindAtkObjectToplevelParentDocument(atk_object);
  if (!parent_doc)
    return;

  std::map<AtkObject*, FindInPageResultInfo>& active_results =
      GetActiveFindInPageResults();
  auto iterator = active_results.find(parent_doc);
  FindInPageResultInfo new_info = {atk_object, start_offset, end_offset};
  if (iterator != active_results.end() && iterator->second == new_info)
    return;

  active_results[parent_doc] = new_info;
  g_signal_emit_by_name(atk_object, "text-selection-changed");
  g_signal_emit_by_name(atk_object, "text-caret-moved",
                        UTF16ToUnicodeOffsetInText(end_offset));
}

base::Optional<std::pair<int, int>>
AXPlatformNodeAuraLinux::GetHypertextExtentsOfChild(
    AXPlatformNodeAuraLinux* child_to_find) {
  int current_offset = 0;
  for (auto child_iterator_ptr = GetDelegate()->ChildrenBegin();
       *child_iterator_ptr != *GetDelegate()->ChildrenEnd();
       ++(*child_iterator_ptr)) {
    auto* child = FromAtkObject(child_iterator_ptr->GetNativeViewAccessible());
    if (!child)
      continue;

    // If this object is a text only object, it is included directly into this
    // node's hypertext, otherwise it is represented as an embedded object
    // character.
    int size = child->IsText() ? child->GetName().size() : 1;
    if (child == child_to_find)
      return std::make_pair(current_offset, current_offset + size);
    current_offset += size;
  }

  return base::nullopt;
}

void AXPlatformNodeAuraLinux::ActivateFindInPageInParent(int start_offset,
                                                         int end_offset) {
  auto* parent = FromAtkObject(GetParent());
  if (!parent)
    return;

  base::Optional<std::pair<int, int>> extents_in_parent =
      parent->GetHypertextExtentsOfChild(this);
  if (!extents_in_parent.has_value())
    return;

  DCHECK(IsText());
  parent->ActivateFindInPageResult(extents_in_parent->first + start_offset,
                                   extents_in_parent->first + end_offset);
}

void AXPlatformNodeAuraLinux::ForgetCurrentFindInPageResult() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return;

  AtkObject* parent_doc = FindAtkObjectToplevelParentDocument(atk_object);
  if (parent_doc)
    GetActiveFindInPageResults().erase(parent_doc);
}

base::Optional<FindInPageResultInfo>
AXPlatformNodeAuraLinux::GetSelectionOffsetsFromFindInPage() {
  AtkObject* atk_object = GetOrCreateAtkObject();
  if (!atk_object)
    return base::nullopt;

  AtkObject* parent_doc = FindAtkObjectToplevelParentDocument(atk_object);
  if (!parent_doc)
    return base::nullopt;

  std::map<AtkObject*, FindInPageResultInfo>& active_results =
      GetActiveFindInPageResults();
  auto iterator = active_results.find(parent_doc);
  if (iterator == active_results.end())
    return base::nullopt;

  return iterator->second;
}

gfx::Point AXPlatformNodeAuraLinux::ConvertPointToScreenCoordinates(
    const gfx::Point& point,
    AtkCoordType atk_coord_type) {
  switch (atk_coord_type) {
    case ATK_XY_WINDOW:
      return point + GetParentFrameOriginInScreenCoordinates();
#if defined(ATK_230)
    case ATK_XY_PARENT:
      return point + GetParentOriginInScreenCoordinates();
#endif
    case ATK_XY_SCREEN:
    default:
      return point;
  }
}

std::pair<int, int> AXPlatformNodeAuraLinux::GetSelectionOffsetsForAtk() {
  // In web content we always want to look at the selection from the tree
  // instead of the selection that might be set via node attributes. This is
  // because the tree selection is the absolute truth about what is visually
  // selected, whereas node attributes might contain selection extents that are
  // no longer part of the visual selection.
  std::pair<int, int> selection;
  if (GetDelegate()->IsWebContent()) {
    AXTree::Selection unignored_selection =
        GetDelegate()->GetUnignoredSelection();
    GetSelectionOffsetsFromTree(&unignored_selection, &selection.first,
                                &selection.second);
  } else {
    GetSelectionOffsets(&selection.first, &selection.second);
  }
  return selection;
}

}  // namespace ui

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_AURALINUX_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_AURALINUX_H_

#include <atk/atk.h>

#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/macros.h"
#include "base/optional.h"
#include "base/strings/utf_offset_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "ui/accessibility/ax_enums.mojom-forward.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_position.h"
#include "ui/accessibility/ax_range.h"
#include "ui/accessibility/platform/ax_platform_node_base.h"

// This deleter is used in order to ensure that we properly always free memory
// used by AtkAttributeSet.
struct AtkAttributeSetDeleter {
  void operator()(AtkAttributeSet* attributes) {
    atk_attribute_set_free(attributes);
  }
};

using AtkAttributes = std::unique_ptr<AtkAttributeSet, AtkAttributeSetDeleter>;

// Some ATK interfaces require returning a (const gchar*), use
// this macro to make it safe to return a pointer to a temporary
// string.
#define ATK_AURALINUX_RETURN_STRING(str_expr) \
  {                                           \
    static std::string result;                \
    result = (str_expr);                      \
    return result.c_str();                    \
  }

namespace ui {

struct FindInPageResultInfo {
  AtkObject* node;
  int start_offset;
  int end_offset;

  bool operator==(const FindInPageResultInfo& other) const {
    return (node == other.node) && (start_offset == other.start_offset) &&
           (end_offset == other.end_offset);
  }
};

// AtkTableCell was introduced in ATK 2.12. Ubuntu Trusty has ATK 2.10.
// Compile-time checks are in place for ATK versions that are older than 2.12.
// However, we also need runtime checks in case the version we are building
// against is newer than the runtime version. To prevent a runtime error, we
// check that we have a version of ATK that supports AtkTableCell. If we do,
// we dynamically load the symbol; if we don't, the interface is absent from
// the accessible object and its methods will not be exposed or callable.
// The definitions below ensure we have no missing symbols. Note that in
// environments where we have ATK > 2.12, the definitions of AtkTableCell and
// AtkTableCellIface below are overridden by the runtime version.
// TODO(accessibility) Remove AtkTableCellInterface when 2.12 is the minimum
// supported version.
struct AX_EXPORT AtkTableCellInterface {
  typedef struct _AtkTableCell AtkTableCell;
  static GType GetType();
  static GPtrArray* GetColumnHeaderCells(AtkTableCell* cell);
  static GPtrArray* GetRowHeaderCells(AtkTableCell* cell);
  static bool GetRowColumnSpan(AtkTableCell* cell,
                               gint* row,
                               gint* column,
                               gint* row_span,
                               gint* col_span);
  static bool Exists();
};

// This class with an enum is used to generate a bitmask which tracks the ATK
// interfaces that an AXPlatformNodeAuraLinux's ATKObject implements.
class ImplementedAtkInterfaces {
 public:
  enum class Value {
    kDefault = 1 << 1,
    kDocument = 1 << 1,
    kHyperlink = 1 << 2,
    kHypertext = 1 << 3,
    kImage = 1 << 4,
    kSelection = 1 << 5,
    kTableCell = 1 << 6,
    kTable = 1 << 7,
    kText = 1 << 8,
    kValue = 1 << 9,
    kWindow = 1 << 10,
  };

  bool Implements(Value interface) const {
    return value_ & static_cast<int>(interface);
  }

  void Add(Value other) { value_ |= static_cast<int>(other); }

  bool operator!=(const ImplementedAtkInterfaces& other) {
    return value_ != other.value_;
  }

  int value() const { return value_; }

 private:
  int value_ = static_cast<int>(Value::kDefault);
};

// Implements accessibility on Aura Linux using ATK.
class AX_EXPORT AXPlatformNodeAuraLinux : public AXPlatformNodeBase {
 public:
  AXPlatformNodeAuraLinux();
  ~AXPlatformNodeAuraLinux() override;

  static AXPlatformNodeAuraLinux* FromAtkObject(const AtkObject*);

  // Set or get the root-level Application object that's the parent of all
  // top-level windows.
  static void SetApplication(AXPlatformNode* application);
  static AXPlatformNode* application();

  static void EnsureGTypeInit();

  // Do asynchronous static initialization.
  static void StaticInitialize();

  // Enables AXMode calling AXPlatformNode::NotifyAddAXModeFlags. It's used
  // when ATK APIs are called.
  static void EnableAXMode();

  // EnsureAtkObjectIsValid will destroy and recreate |atk_object_| if the
  // interface mask is different. This partially relies on looking at the tree's
  // structure. This must not be called when the tree is unstable e.g. in the
  // middle of being unserialized.
  void EnsureAtkObjectIsValid();
  void Destroy() override;

  AtkRole GetAtkRole() const;
  void GetAtkState(AtkStateSet* state_set);
  AtkRelationSet* GetAtkRelations();
  void GetExtents(gint* x, gint* y, gint* width, gint* height,
                  AtkCoordType coord_type);
  void GetPosition(gint* x, gint* y, AtkCoordType coord_type);
  void GetSize(gint* width, gint* height);
  gfx::NativeViewAccessible HitTestSync(gint x,
                                        gint y,
                                        AtkCoordType coord_type);
  bool GrabFocus();
  bool FocusFirstFocusableAncestorInWebContent();
  bool GrabFocusOrSetSequentialFocusNavigationStartingPointAtOffset(int offset);
  bool GrabFocusOrSetSequentialFocusNavigationStartingPoint();
  bool SetSequentialFocusNavigationStartingPoint();
  bool DoDefaultAction();
  const gchar* GetDefaultActionName();
  AtkAttributeSet* GetAtkAttributes();

  gfx::Vector2d GetParentOriginInScreenCoordinates() const;
  gfx::Vector2d GetParentFrameOriginInScreenCoordinates() const;
  gfx::Rect GetExtentsRelativeToAtkCoordinateType(
      AtkCoordType coord_type) const;

  // AtkDocument helpers
  const gchar* GetDocumentAttributeValue(const gchar* attribute) const;
  AtkAttributeSet* GetDocumentAttributes() const;

  // AtkHyperlink helpers
  AtkHyperlink* GetAtkHyperlink();

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 30, 0)
  void ScrollToPoint(AtkCoordType atk_coord_type, int x, int y);
  void ScrollNodeRectIntoView(gfx::Rect rect, AtkScrollType atk_scroll_type);
  void ScrollNodeIntoView(AtkScrollType atk_scroll_type);
#endif  // defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 30, 0)

#if defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 32, 0)
  base::Optional<gfx::Rect> GetUnclippedHypertextRangeBoundsRect(
      int start_offset,
      int end_offset);
  bool ScrollSubstringIntoView(AtkScrollType atk_scroll_type,
                               int start_offset,
                               int end_offset);
  bool ScrollSubstringToPoint(int start_offset,
                              int end_offset,
                              AtkCoordType atk_coord_type,
                              int x,
                              int y);
#endif  // defined(ATK_CHECK_VERSION) && ATK_CHECK_VERSION(2, 32, 0)

  // Misc helpers
  void GetFloatAttributeInGValue(ax::mojom::FloatAttribute attr, GValue* value);

  // Event helpers
  void OnActiveDescendantChanged();
  void OnCheckedStateChanged();
  void OnEnabledChanged();
  void OnExpandedStateChanged(bool is_expanded);
  void OnFocused();
  void OnWindowActivated();
  void OnWindowDeactivated();
  void OnMenuPopupStart();
  void OnMenuPopupEnd();
  void OnAllMenusEnded();
  void OnSelected();
  void OnSelectedChildrenChanged();
  void OnTextAttributesChanged();
  void OnTextSelectionChanged();
  void OnValueChanged();
  void OnNameChanged();
  void OnDescriptionChanged();
  void OnSortDirectionChanged();
  void OnInvalidStatusChanged();
  void OnDocumentTitleChanged();
  void OnSubtreeCreated();
  void OnSubtreeWillBeDeleted();
  void OnParentChanged();
  void OnWindowVisibilityChanged();
  void OnScrolledToAnchor();
  void OnAlertShown();
  void RunPostponedEvents();

  void ResendFocusSignalsForCurrentlyFocusedNode();
  bool SupportsSelectionWithAtkSelection();
  bool SelectionAndFocusAreTheSame();
  void SetActiveViewsDialog();

  // AXPlatformNode overrides.
  // This has a side effect of creating the AtkObject if one does not already
  // exist.
  gfx::NativeViewAccessible GetNativeViewAccessible() override;
  void NotifyAccessibilityEvent(ax::mojom::Event event_type) override;

  // AXPlatformNodeBase overrides.
  void Init(AXPlatformNodeDelegate* delegate) override;
  bool IsPlatformCheckable() const override;
  base::Optional<int> GetIndexInParent() override;

  bool IsNameExposed();

  void UpdateHypertext();
  const AXHypertext& GetAXHypertext();
  const base::OffsetAdjuster::Adjustments& GetHypertextAdjustments();
  size_t UTF16ToUnicodeOffsetInText(size_t utf16_offset);
  size_t UnicodeToUTF16OffsetInText(int unicode_offset);
  int GetTextOffsetAtPoint(int x, int y, AtkCoordType atk_coord_type);

  // Called on a toplevel frame to set the document parent, which is the parent
  // of the toplevel document. This is used to properly express the ATK embeds
  // relationship between a toplevel frame and its embedded document.
  void SetDocumentParent(AtkObject* new_document_parent);

  int GetCaretOffset();
  bool SetCaretOffset(int offset);
  bool SetTextSelectionForAtkText(int start_offset, int end_offset);
  bool HasSelection();

  void GetSelectionExtents(int* start_offset, int* end_offset);
  gchar* GetSelectionWithText(int* start_offset, int* end_offset);

  // Return the text attributes for this node given an offset. The start
  // and end attributes will be assigned to the start_offset and end_offset
  // pointers if they are non-null. The return value AtkAttributeSet should
  // be freed with atk_attribute_set_free.
  const TextAttributeList& GetTextAttributes(int offset,
                                             int* start_offset,
                                             int* end_offset);

  // Return the default text attributes for this node. The default text
  // attributes are the ones that apply to the entire node. Attributes found at
  // a given offset can be thought of as overriding the default attribute.
  // The return value AtkAttributeSet should be freed with
  // atk_attribute_set_free.
  const TextAttributeList& GetDefaultTextAttributes();

  void ActivateFindInPageResult(int start_offset, int end_offset);
  void TerminateFindInPage();

  // If there is a find in page result for the toplevel document of this node,
  // return it, otherwise return base::nullopt;
  base::Optional<FindInPageResultInfo> GetSelectionOffsetsFromFindInPage();

  std::pair<int, int> GetSelectionOffsetsForAtk();

  // Get the embedded object ("hyperlink") indices for this object in the
  // parent. If this object doesn't have a parent or isn't embedded, return
  // nullopt.
  base::Optional<std::pair<int, int>> GetEmbeddedObjectIndices();

  std::string accessible_name_;

 protected:
  // Offsets for the AtkText API are calculated in UTF-16 code point offsets,
  // but the ATK APIs want all offsets to be in "characters," which we
  // understand to be Unicode character offsets. We keep a lazily generated set
  // of Adjustments to convert between UTF-16 and Unicode character offsets.
  base::Optional<base::OffsetAdjuster::Adjustments> text_unicode_adjustments_ =
      base::nullopt;

  void AddAttributeToList(const char* name,
                          const char* value,
                          PlatformAttributeList* attributes) override;

 private:
  using AXPositionInstance = AXNodePosition::AXPositionInstance;
  using AXPositionInstanceType = typename AXPositionInstance::element_type;
  using AXNodeRange = AXRange<AXPositionInstanceType>;

  // This is static to ensure that we aren't trying to access the rest of the
  // accessibility tree during node initialization.
  static ImplementedAtkInterfaces GetGTypeInterfaceMask(const AXNodeData& data);

  GType GetAccessibilityGType();
  AtkObject* CreateAtkObject();
  // Get or Create AtkObject. Note that it could return nullptr except
  // ax::mojom::Role::kApplication when the mode is not enabled.
  gfx::NativeViewAccessible GetOrCreateAtkObject();
  void DestroyAtkObjects();
  void AddRelationToSet(AtkRelationSet*,
                        AtkRelationType,
                        AXPlatformNode* target);
  bool IsInLiveRegion();
  base::Optional<std::pair<int, int>> GetEmbeddedObjectIndicesForId(int id);

  void ComputeStylesIfNeeded();
  int FindStartOfStyle(int start_offset, ax::mojom::MoveDirection direction);

  // Reset any find in page operations for the toplevel document of this node.
  void ForgetCurrentFindInPageResult();

  // Activate a find in page result for the toplevel document of this node.
  void ActivateFindInPageInParent(int start_offset, int end_offset);

  // If this node is the toplevel document node, find its parent and set it on
  // the toplevel frame which contains the node.
  void SetDocumentParentOnFrameIfNecessary();

  // Find the child which is a document containing the primary web content.
  AtkObject* FindPrimaryWebContentDocument();

  // Returns true if it is a web content for the relations.
  bool IsWebDocumentForRelations();

  // If a selection that intersects this node get the full selection
  // including start and end node ids.
  void GetFullSelection(int32_t* anchor_node_id,
                        int* anchor_offset,
                        int32_t* focus_node_id,
                        int* focus_offset);

  // Returns true if this node's AtkObject is suitable for emitting AtkText
  // signals. ATs don't expect static text objects to emit AtkText signals.
  bool EmitsAtkTextEvents() const;

  // Find the first ancestor which is an editable root or a document. This node
  // will be one which contains a single selection.
  AXPlatformNodeAuraLinux& FindEditableRootOrDocument();

  // Find the first common ancestor between this node and a given node.
  AXPlatformNodeAuraLinux* FindCommonAncestor(AXPlatformNodeAuraLinux* other);

  // Update the selection information stored in this node. This should be
  // called on the editable root, the root node of the accessibility tree, or
  // the document (ie the node returned by FindEditableRootOrDocument()).
  void UpdateSelectionInformation(int32_t anchor_node_id,
                                  int anchor_offset,
                                  int32_t focus_node_id,
                                  int focus_offset);

  // Emit a GObject signal indicating a selection change.
  void EmitSelectionChangedSignal(bool had_selection);

  // Emit a GObject signal indicating that the caret has moved.
  void EmitCaretChangedSignal();

  bool HadNonZeroWidthSelection() const { return had_nonzero_width_selection; }
  std::pair<int32_t, int> GetCurrentCaret() const { return current_caret_; }

  // If the given argument can be found as a child of this node, return its
  // hypertext extents, otherwise return base::nullopt;
  base::Optional<std::pair<int, int>> GetHypertextExtentsOfChild(
      AXPlatformNodeAuraLinux* child);

  // The AtkStateType for a checkable node can vary depending on the role.
  AtkStateType GetAtkStateTypeForCheckableNode();

  gfx::Point ConvertPointToScreenCoordinates(const gfx::Point& point,
                                             AtkCoordType atk_coord_type);

  // Keep information of latest ImplementedAtkInterfaces mask to rebuild the
  // ATK object accordingly when the platform node changes.
  ImplementedAtkInterfaces interface_mask_;

  // We own a reference to these ref-counted objects.
  AtkObject* atk_object_ = nullptr;
  AtkHyperlink* atk_hyperlink_ = nullptr;

  // A weak pointers which help us track the ATK embeds relation.
  AtkObject* document_parent_ = nullptr;

  // Whether or not this node (if it is a frame or a window) was
  // minimized the last time it's visibility changed.
  bool was_minimized_ = false;

  // Information about the selection meant to be stored on the return value of
  // FindEditableRootOrDocument().
  //
  // Whether or not we previously had a selection where the anchor and focus
  // were not equal. This is what ATK consider a "selection."
  bool had_nonzero_width_selection = false;

  // Information about the current caret location (a node id and an offset).
  // This is used to track when the caret actually moves during a selection
  // change.
  std::pair<int32_t, int> current_caret_ = {-1, -1};

  // A map which converts between an offset in the node's hypertext and the
  // ATK text attributes at that offset.
  TextAttributeMap offset_to_text_attributes_;

  // The default ATK text attributes for this node.
  TextAttributeList default_text_attributes_;

  bool window_activate_event_postponed_ = false;

  DISALLOW_COPY_AND_ASSIGN(AXPlatformNodeAuraLinux);
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_AURALINUX_H_

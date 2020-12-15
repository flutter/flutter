// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ui/accessibility/platform/ax_platform_node_mac.h"

#import <Cocoa/Cocoa.h>
#include <stddef.h>

#include "base/mac/foundation_util.h"
#include "base/macros.h"
#include "base/no_destructor.h"
#include "base/strings/sys_string_conversions.h"
#include "ui/accessibility/ax_action_data.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/ax_role_properties.h"
#include "ui/accessibility/platform/ax_platform_node.h"
#include "ui/accessibility/platform/ax_platform_node_delegate.h"
#include "ui/base/l10n/l10n_util.h"
#import "ui/gfx/mac/coordinate_conversion.h"
#include "ui/strings/grit/ui_strings.h"

namespace {

// Same length as web content/WebKit.
static int kLiveRegionDebounceMillis = 20;

using RoleMap = std::map<ax::mojom::Role, NSString*>;
using EventMap = std::map<ax::mojom::Event, NSString*>;
using ActionList = std::vector<std::pair<ax::mojom::Action, NSString*>>;

struct AnnouncementSpec {
  base::scoped_nsobject<NSString> announcement;
  base::scoped_nsobject<NSWindow> window;
  bool is_polite;
};

RoleMap BuildRoleMap() {
  const RoleMap::value_type roles[] = {
      {ax::mojom::Role::kAbbr, NSAccessibilityGroupRole},
      {ax::mojom::Role::kAlert, NSAccessibilityGroupRole},
      {ax::mojom::Role::kAlertDialog, NSAccessibilityGroupRole},
      {ax::mojom::Role::kAnchor, NSAccessibilityGroupRole},
      {ax::mojom::Role::kApplication, NSAccessibilityGroupRole},
      {ax::mojom::Role::kArticle, NSAccessibilityGroupRole},
      {ax::mojom::Role::kAudio, NSAccessibilityGroupRole},
      {ax::mojom::Role::kBanner, NSAccessibilityGroupRole},
      {ax::mojom::Role::kBlockquote, NSAccessibilityGroupRole},
      {ax::mojom::Role::kButton, NSAccessibilityButtonRole},
      {ax::mojom::Role::kCanvas, NSAccessibilityImageRole},
      {ax::mojom::Role::kCaption, NSAccessibilityGroupRole},
      {ax::mojom::Role::kCell, @"AXCell"},
      {ax::mojom::Role::kCheckBox, NSAccessibilityCheckBoxRole},
      {ax::mojom::Role::kCode, NSAccessibilityGroupRole},
      {ax::mojom::Role::kColorWell, NSAccessibilityColorWellRole},
      {ax::mojom::Role::kColumn, NSAccessibilityColumnRole},
      {ax::mojom::Role::kColumnHeader, @"AXCell"},
      {ax::mojom::Role::kComboBoxGrouping, NSAccessibilityGroupRole},
      {ax::mojom::Role::kComboBoxMenuButton, NSAccessibilityPopUpButtonRole},
      {ax::mojom::Role::kComment, NSAccessibilityGroupRole},
      {ax::mojom::Role::kComplementary, NSAccessibilityGroupRole},
      {ax::mojom::Role::kContentDeletion, NSAccessibilityGroupRole},
      {ax::mojom::Role::kContentInsertion, NSAccessibilityGroupRole},
      {ax::mojom::Role::kContentInfo, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDate, @"AXDateField"},
      {ax::mojom::Role::kDateTime, @"AXDateField"},
      {ax::mojom::Role::kDefinition, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDescriptionListDetail, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDescriptionList, NSAccessibilityListRole},
      {ax::mojom::Role::kDescriptionListTerm, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDialog, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDetails, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDirectory, NSAccessibilityListRole},
      // If Mac supports AXExpandedChanged event with
      // NSAccessibilityDisclosureTriangleRole, We should update
      // ax::mojom::Role::kDisclosureTriangle mapping to
      // NSAccessibilityDisclosureTriangleRole. http://crbug.com/558324
      {ax::mojom::Role::kDisclosureTriangle, NSAccessibilityButtonRole},
      {ax::mojom::Role::kDocAbstract, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocAcknowledgments, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocAfterword, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocAppendix, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocBackLink, NSAccessibilityLinkRole},
      {ax::mojom::Role::kDocBiblioEntry, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocBibliography, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocBiblioRef, NSAccessibilityLinkRole},
      {ax::mojom::Role::kDocChapter, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocColophon, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocConclusion, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocCover, NSAccessibilityImageRole},
      {ax::mojom::Role::kDocCredit, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocCredits, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocDedication, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocEndnote, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocEndnotes, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocEpigraph, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocEpilogue, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocErrata, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocExample, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocFootnote, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocForeword, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocGlossary, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocGlossRef, NSAccessibilityLinkRole},
      {ax::mojom::Role::kDocIndex, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocIntroduction, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocNoteRef, NSAccessibilityLinkRole},
      {ax::mojom::Role::kDocNotice, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocPageBreak, NSAccessibilitySplitterRole},
      {ax::mojom::Role::kDocPageList, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocPart, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocPreface, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocPrologue, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocPullquote, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocQna, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocSubtitle, @"AXHeading"},
      {ax::mojom::Role::kDocTip, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocToc, NSAccessibilityGroupRole},
      {ax::mojom::Role::kDocument, NSAccessibilityGroupRole},
      {ax::mojom::Role::kEmbeddedObject, NSAccessibilityGroupRole},
      {ax::mojom::Role::kEmphasis, NSAccessibilityGroupRole},
      {ax::mojom::Role::kFigcaption, NSAccessibilityGroupRole},
      {ax::mojom::Role::kFigure, NSAccessibilityGroupRole},
      {ax::mojom::Role::kFooter, NSAccessibilityGroupRole},
      {ax::mojom::Role::kFooterAsNonLandmark, NSAccessibilityGroupRole},
      {ax::mojom::Role::kForm, NSAccessibilityGroupRole},
      {ax::mojom::Role::kGenericContainer, NSAccessibilityGroupRole},
      {ax::mojom::Role::kGraphicsDocument, NSAccessibilityGroupRole},
      {ax::mojom::Role::kGraphicsObject, NSAccessibilityGroupRole},
      {ax::mojom::Role::kGraphicsSymbol, NSAccessibilityImageRole},
      // Should be NSAccessibilityGridRole but VoiceOver treating it like
      // a list as of 10.12.6, so following WebKit and using table role:
      {ax::mojom::Role::kGrid, NSAccessibilityTableRole},  // crbug.com/753925
      {ax::mojom::Role::kGroup, NSAccessibilityGroupRole},
      {ax::mojom::Role::kHeader, NSAccessibilityGroupRole},
      {ax::mojom::Role::kHeaderAsNonLandmark, NSAccessibilityGroupRole},
      {ax::mojom::Role::kHeading, @"AXHeading"},
      {ax::mojom::Role::kIframe, NSAccessibilityGroupRole},
      {ax::mojom::Role::kIframePresentational, NSAccessibilityGroupRole},
      {ax::mojom::Role::kIgnored, NSAccessibilityUnknownRole},
      {ax::mojom::Role::kImage, NSAccessibilityImageRole},
      {ax::mojom::Role::kImageMap, NSAccessibilityGroupRole},
      {ax::mojom::Role::kInputTime, @"AXTimeField"},
      {ax::mojom::Role::kLabelText, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLayoutTable, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLayoutTableCell, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLayoutTableRow, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLegend, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLineBreak, NSAccessibilityGroupRole},
      {ax::mojom::Role::kLink, NSAccessibilityLinkRole},
      {ax::mojom::Role::kList, NSAccessibilityListRole},
      {ax::mojom::Role::kListBox, NSAccessibilityListRole},
      {ax::mojom::Role::kListBoxOption, NSAccessibilityStaticTextRole},
      {ax::mojom::Role::kListItem, NSAccessibilityGroupRole},
      {ax::mojom::Role::kListMarker, @"AXListMarker"},
      {ax::mojom::Role::kLog, NSAccessibilityGroupRole},
      {ax::mojom::Role::kMain, NSAccessibilityGroupRole},
      {ax::mojom::Role::kMark, NSAccessibilityGroupRole},
      {ax::mojom::Role::kMarquee, NSAccessibilityGroupRole},
      {ax::mojom::Role::kMath, NSAccessibilityGroupRole},
      {ax::mojom::Role::kMenu, NSAccessibilityMenuRole},
      {ax::mojom::Role::kMenuBar, NSAccessibilityMenuBarRole},
      {ax::mojom::Role::kMenuItem, NSAccessibilityMenuItemRole},
      {ax::mojom::Role::kMenuItemCheckBox, NSAccessibilityMenuItemRole},
      {ax::mojom::Role::kMenuItemRadio, NSAccessibilityMenuItemRole},
      {ax::mojom::Role::kMenuListOption, NSAccessibilityMenuItemRole},
      {ax::mojom::Role::kMenuListPopup, NSAccessibilityMenuRole},
      {ax::mojom::Role::kMeter, NSAccessibilityLevelIndicatorRole},
      {ax::mojom::Role::kNavigation, NSAccessibilityGroupRole},
      {ax::mojom::Role::kNone, NSAccessibilityGroupRole},
      {ax::mojom::Role::kNote, NSAccessibilityGroupRole},
      {ax::mojom::Role::kParagraph, NSAccessibilityGroupRole},
      {ax::mojom::Role::kPdfActionableHighlight, NSAccessibilityButtonRole},
      {ax::mojom::Role::kPluginObject, NSAccessibilityGroupRole},
      {ax::mojom::Role::kPopUpButton, NSAccessibilityPopUpButtonRole},
      {ax::mojom::Role::kPortal, NSAccessibilityButtonRole},
      {ax::mojom::Role::kPre, NSAccessibilityGroupRole},
      {ax::mojom::Role::kPresentational, NSAccessibilityGroupRole},
      {ax::mojom::Role::kProgressIndicator,
       NSAccessibilityProgressIndicatorRole},
      {ax::mojom::Role::kRadioButton, NSAccessibilityRadioButtonRole},
      {ax::mojom::Role::kRadioGroup, NSAccessibilityRadioGroupRole},
      {ax::mojom::Role::kRegion, NSAccessibilityGroupRole},
      {ax::mojom::Role::kRootWebArea, @"AXWebArea"},
      {ax::mojom::Role::kRow, NSAccessibilityRowRole},
      {ax::mojom::Role::kRowGroup, NSAccessibilityGroupRole},
      {ax::mojom::Role::kRowHeader, @"AXCell"},
      // TODO(accessibility) What should kRuby be? It's not listed? Any others
      // missing? Maybe use switch statement so that compiler doesn't allow us
      // to miss any.
      {ax::mojom::Role::kRubyAnnotation, NSAccessibilityUnknownRole},
      {ax::mojom::Role::kScrollBar, NSAccessibilityScrollBarRole},
      {ax::mojom::Role::kSearch, NSAccessibilityGroupRole},
      {ax::mojom::Role::kSearchBox, NSAccessibilityTextFieldRole},
      {ax::mojom::Role::kSection, NSAccessibilityGroupRole},
      {ax::mojom::Role::kSlider, NSAccessibilitySliderRole},
      {ax::mojom::Role::kSliderThumb, NSAccessibilityValueIndicatorRole},
      {ax::mojom::Role::kSpinButton, NSAccessibilityIncrementorRole},
      {ax::mojom::Role::kSplitter, NSAccessibilitySplitterRole},
      {ax::mojom::Role::kStaticText, NSAccessibilityStaticTextRole},
      {ax::mojom::Role::kStatus, NSAccessibilityGroupRole},
      {ax::mojom::Role::kSuggestion, NSAccessibilityGroupRole},
      {ax::mojom::Role::kSvgRoot, NSAccessibilityGroupRole},
      {ax::mojom::Role::kSwitch, NSAccessibilityCheckBoxRole},
      {ax::mojom::Role::kStrong, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTab, NSAccessibilityRadioButtonRole},
      {ax::mojom::Role::kTable, NSAccessibilityTableRole},
      {ax::mojom::Role::kTableHeaderContainer, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTabList, NSAccessibilityTabGroupRole},
      {ax::mojom::Role::kTabPanel, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTerm, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTextField, NSAccessibilityTextFieldRole},
      {ax::mojom::Role::kTextFieldWithComboBox, NSAccessibilityComboBoxRole},
      {ax::mojom::Role::kTime, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTimer, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTitleBar, NSAccessibilityStaticTextRole},
      {ax::mojom::Role::kToggleButton, NSAccessibilityCheckBoxRole},
      {ax::mojom::Role::kToolbar, NSAccessibilityToolbarRole},
      {ax::mojom::Role::kTooltip, NSAccessibilityGroupRole},
      {ax::mojom::Role::kTree, NSAccessibilityOutlineRole},
      {ax::mojom::Role::kTreeGrid, NSAccessibilityTableRole},
      {ax::mojom::Role::kTreeItem, NSAccessibilityRowRole},
      {ax::mojom::Role::kVideo, NSAccessibilityGroupRole},
      {ax::mojom::Role::kWebArea, @"AXWebArea"},
      // Use the group role as the BrowserNativeWidgetWindow already provides
      // a kWindow role, and having extra window roles, which are treated
      // specially by screen readers, can break their ability to find the
      // content window. See http://crbug.com/875843 for more information.
      {ax::mojom::Role::kWindow, NSAccessibilityGroupRole},
  };

  return RoleMap(begin(roles), end(roles));
}

RoleMap BuildSubroleMap() {
  const RoleMap::value_type subroles[] = {
      {ax::mojom::Role::kAlert, @"AXApplicationAlert"},
      {ax::mojom::Role::kAlertDialog, @"AXApplicationAlertDialog"},
      {ax::mojom::Role::kApplication, @"AXLandmarkApplication"},
      {ax::mojom::Role::kArticle, @"AXDocumentArticle"},
      {ax::mojom::Role::kBanner, @"AXLandmarkBanner"},
      {ax::mojom::Role::kCode, @"AXCodeStyleGroup"},
      {ax::mojom::Role::kComplementary, @"AXLandmarkComplementary"},
      {ax::mojom::Role::kContentDeletion, @"AXDeleteStyleGroup"},
      {ax::mojom::Role::kContentInsertion, @"AXInsertStyleGroup"},
      {ax::mojom::Role::kContentInfo, @"AXLandmarkContentInfo"},
      {ax::mojom::Role::kDefinition, @"AXDefinition"},
      {ax::mojom::Role::kDescriptionListDetail, @"AXDefinition"},
      {ax::mojom::Role::kDescriptionListTerm, @"AXTerm"},
      {ax::mojom::Role::kDialog, @"AXApplicationDialog"},
      {ax::mojom::Role::kDocument, @"AXDocument"},
      {ax::mojom::Role::kEmphasis, @"AXEmphasisStyleGroup"},
      {ax::mojom::Role::kFooter, @"AXLandmarkContentInfo"},
      {ax::mojom::Role::kForm, @"AXLandmarkForm"},
      {ax::mojom::Role::kGraphicsDocument, @"AXDocument"},
      {ax::mojom::Role::kHeader, @"AXLandmarkBanner"},
      {ax::mojom::Role::kLog, @"AXApplicationLog"},
      {ax::mojom::Role::kMain, @"AXLandmarkMain"},
      {ax::mojom::Role::kMarquee, @"AXApplicationMarquee"},
      {ax::mojom::Role::kMath, @"AXDocumentMath"},
      {ax::mojom::Role::kNavigation, @"AXLandmarkNavigation"},
      {ax::mojom::Role::kNote, @"AXDocumentNote"},
      {ax::mojom::Role::kRegion, @"AXLandmarkRegion"},
      {ax::mojom::Role::kSearch, @"AXLandmarkSearch"},
      {ax::mojom::Role::kSearchBox, @"AXSearchField"},
      {ax::mojom::Role::kSection, @"AXLandmarkRegion"},
      {ax::mojom::Role::kStatus, @"AXApplicationStatus"},
      {ax::mojom::Role::kStrong, @"AXStrongStyleGroup"},
      {ax::mojom::Role::kSwitch, @"AXSwitch"},
      {ax::mojom::Role::kTabPanel, @"AXTabPanel"},
      {ax::mojom::Role::kTerm, @"AXTerm"},
      {ax::mojom::Role::kTime, @"AXTimeGroup"},
      {ax::mojom::Role::kTimer, @"AXApplicationTimer"},
      {ax::mojom::Role::kToggleButton, @"AXToggleButton"},
      {ax::mojom::Role::kTooltip, @"AXUserInterfaceTooltip"},
      {ax::mojom::Role::kTreeItem, NSAccessibilityOutlineRowSubrole},
  };

  return RoleMap(begin(subroles), end(subroles));
}

EventMap BuildEventMap() {
  const EventMap::value_type events[] = {
      {ax::mojom::Event::kCheckedStateChanged,
       NSAccessibilityValueChangedNotification},
      {ax::mojom::Event::kFocus,
       NSAccessibilityFocusedUIElementChangedNotification},
      {ax::mojom::Event::kFocusContext,
       NSAccessibilityFocusedUIElementChangedNotification},
      {ax::mojom::Event::kTextChanged, NSAccessibilityTitleChangedNotification},
      {ax::mojom::Event::kValueChanged,
       NSAccessibilityValueChangedNotification},
      {ax::mojom::Event::kTextSelectionChanged,
       NSAccessibilitySelectedTextChangedNotification},
      // TODO(patricialor): Add more events.
  };

  return EventMap(begin(events), end(events));
}

ActionList BuildActionList() {
  const ActionList::value_type entries[] = {
      // NSAccessibilityPressAction must come first in this list.
      {ax::mojom::Action::kDoDefault, NSAccessibilityPressAction},

      {ax::mojom::Action::kDecrement, NSAccessibilityDecrementAction},
      {ax::mojom::Action::kIncrement, NSAccessibilityIncrementAction},
      {ax::mojom::Action::kShowContextMenu, NSAccessibilityShowMenuAction},
  };
  return ActionList(begin(entries), end(entries));
}

const ActionList& GetActionList() {
  static const base::NoDestructor<ActionList> action_map(BuildActionList());
  return *action_map;
}

void PostAnnouncementNotification(NSString* announcement,
                                  NSWindow* window,
                                  bool is_polite) {
  NSAccessibilityPriorityLevel priority =
      is_polite ? NSAccessibilityPriorityMedium : NSAccessibilityPriorityHigh;
  NSDictionary* notification_info = @{
    NSAccessibilityAnnouncementKey : announcement,
    NSAccessibilityPriorityKey : @(priority)
  };
  // On Mojave, announcements from an inactive window aren't spoken.
  NSAccessibilityPostNotificationWithUserInfo(
      window, NSAccessibilityAnnouncementRequestedNotification,
      notification_info);
}
void NotifyMacEvent(AXPlatformNodeCocoa* target, ax::mojom::Event event_type) {
  NSString* notification =
      [AXPlatformNodeCocoa nativeNotificationFromAXEvent:event_type];
  if (notification)
    NSAccessibilityPostNotification(target, notification);
}

// Returns true if |action| should be added implicitly for |data|.
bool HasImplicitAction(const ui::AXNodeData& data, ax::mojom::Action action) {
  return action == ax::mojom::Action::kDoDefault && data.IsClickable();
}

// For roles that show a menu for the default action, ensure "show menu" also
// appears in available actions, but only if that's not already used for a
// context menu. It will be mapped back to the default action when performed.
bool AlsoUseShowMenuActionForDefaultAction(const ui::AXNodeData& data) {
  return HasImplicitAction(data, ax::mojom::Action::kDoDefault) &&
         !data.HasAction(ax::mojom::Action::kShowContextMenu) &&
         data.role == ax::mojom::Role::kPopUpButton;
}

}  // namespace

@interface AXPlatformNodeCocoa (Private)
// Helper function for string attributes that don't require extra processing.
- (NSString*)getStringAttribute:(ax::mojom::StringAttribute)attribute;
// Returns AXValue, or nil if AXValue isn't an NSString.
- (NSString*)getAXValueAsString;
// Returns the data necessary to queue an NSAccessibility announcement if
// |eventType| should be announced, or nullptr otherwise.
- (std::unique_ptr<AnnouncementSpec>)announcementForEvent:
    (ax::mojom::Event)eventType;
// Ask the system to announce |announcementText|. This is debounced to happen
// at most every |kLiveRegionDebounceMillis| per node, with only the most
// recent announcement text read, to account for situations with multiple
// notifications happening one after another (for example, results for
// find-in-page updating rapidly as they come in from subframes).
- (void)scheduleLiveRegionAnnouncement:
    (std::unique_ptr<AnnouncementSpec>)announcement;
@end

@implementation AXPlatformNodeCocoa {
  ui::AXPlatformNodeBase* _node;  // Weak. Retains us.
  std::unique_ptr<AnnouncementSpec> _pendingAnnouncement;
}

@synthesize node = _node;

+ (NSString*)nativeRoleFromAXRole:(ax::mojom::Role)role {
  static const base::NoDestructor<RoleMap> role_map(BuildRoleMap());
  RoleMap::const_iterator it = role_map->find(role);
  return it != role_map->end() ? it->second : NSAccessibilityUnknownRole;
}

+ (NSString*)nativeSubroleFromAXRole:(ax::mojom::Role)role {
  static const base::NoDestructor<RoleMap> subrole_map(BuildSubroleMap());
  RoleMap::const_iterator it = subrole_map->find(role);
  return it != subrole_map->end() ? it->second : nil;
}

+ (NSString*)nativeNotificationFromAXEvent:(ax::mojom::Event)event {
  static const base::NoDestructor<EventMap> event_map(BuildEventMap());
  EventMap::const_iterator it = event_map->find(event);
  return it != event_map->end() ? it->second : nil;
}

- (instancetype)initWithNode:(ui::AXPlatformNodeBase*)node {
  if ((self = [super init])) {
    _node = node;
  }
  return self;
}

- (void)detach {
  if (!_node)
    return;
  _node = nil;
  NSAccessibilityPostNotification(
      self, NSAccessibilityUIElementDestroyedNotification);
}

- (NSRect)boundsInScreen {
  if (!_node || !_node->GetDelegate())
    return NSZeroRect;
  return gfx::ScreenRectToNSRect(_node->GetDelegate()->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped));
}

- (NSString*)getStringAttribute:(ax::mojom::StringAttribute)attribute {
  std::string attributeValue;
  if (_node->GetStringAttribute(attribute, &attributeValue))
    return base::SysUTF8ToNSString(attributeValue);
  return nil;
}

- (NSString*)getAXValueAsString {
  id value = [self AXValue];
  return [value isKindOfClass:[NSString class]] ? value : nil;
}

- (NSString*)getName {
  return base::SysUTF8ToNSString(_node->GetName());
}

- (std::unique_ptr<AnnouncementSpec>)announcementForEvent:
    (ax::mojom::Event)eventType {
  // Only alerts and live region changes should be announced.
  DCHECK(eventType == ax::mojom::Event::kAlert ||
         eventType == ax::mojom::Event::kLiveRegionChanged);
  std::string liveStatus =
      _node->GetStringAttribute(ax::mojom::StringAttribute::kLiveStatus);
  // If live status is explicitly set to off, don't announce.
  if (liveStatus == "off")
    return nullptr;

  NSString* name = [self getName];
  NSString* announcementText =
      [name length] > 0 ? name
                        : base::SysUTF16ToNSString(_node->GetInnerText());
  if ([announcementText length] == 0)
    return nullptr;

  auto announcement = std::make_unique<AnnouncementSpec>();
  announcement->announcement =
      base::scoped_nsobject<NSString>([announcementText retain]);
  announcement->window =
      base::scoped_nsobject<NSWindow>([[self AXWindow] retain]);
  announcement->is_polite = liveStatus != "assertive";
  return announcement;
}

- (void)scheduleLiveRegionAnnouncement:
    (std::unique_ptr<AnnouncementSpec>)announcement {
  if (_pendingAnnouncement) {
    // An announcement is already in flight, so just reset the contents. This is
    // threadsafe because the dispatch is on the main queue.
    _pendingAnnouncement = std::move(announcement);
    return;
  }

  _pendingAnnouncement = std::move(announcement);
  dispatch_after(kLiveRegionDebounceMillis * NSEC_PER_MSEC,
                 dispatch_get_main_queue(), ^{
                   if (!_pendingAnnouncement) {
                     return;
                   }
                   PostAnnouncementNotification(
                       _pendingAnnouncement->announcement,
                       _pendingAnnouncement->window,
                       _pendingAnnouncement->is_polite);
                   _pendingAnnouncement.reset();
                 });
}
// NSAccessibility informal protocol implementation.

- (BOOL)accessibilityIsIgnored {
  if (!_node)
    return YES;

  return [[self AXRole] isEqualToString:NSAccessibilityUnknownRole] ||
         _node->GetData().HasState(ax::mojom::State::kInvisible);
}

- (id)accessibilityHitTest:(NSPoint)point {
  if (!NSPointInRect(point, [self boundsInScreen]))
    return nil;

  for (id child in [[self AXChildren] reverseObjectEnumerator]) {
    if (!NSPointInRect(point, [child accessibilityFrame]))
      continue;
    if (id foundChild = [child accessibilityHitTest:point])
      return foundChild;
  }

  // Hit self, but not any child.
  return NSAccessibilityUnignoredAncestor(self);
}

- (BOOL)accessibilityNotifiesWhenDestroyed {
  return YES;
}

- (id)accessibilityFocusedUIElement {
  return _node ? _node->GetDelegate()->GetFocus() : nil;
}

// This function and accessibilityPerformAction:, while deprecated, are a) still
// called by AppKit internally and b) not implemented by NSAccessibilityElement,
// so this class needs its own implementations.
- (NSArray*)accessibilityActionNames {
  if (!_node)
    return @[];

  base::scoped_nsobject<NSMutableArray> axActions(
      [[NSMutableArray alloc] init]);

  const ui::AXNodeData& data = _node->GetData();
  const ActionList& action_list = GetActionList();

  // VoiceOver expects the "press" action to be first. Note that some roles
  // should be given a press action implicitly.
  DCHECK([action_list[0].second isEqualToString:NSAccessibilityPressAction]);
  for (const auto& item : action_list) {
    if (data.HasAction(item.first) || HasImplicitAction(data, item.first))
      [axActions addObject:item.second];
  }

  if (AlsoUseShowMenuActionForDefaultAction(data))
    [axActions addObject:NSAccessibilityShowMenuAction];

  return axActions.autorelease();
}

- (void)accessibilityPerformAction:(NSString*)action {
  // Actions are performed asynchronously, so it's always possible for an object
  // to change its mind after previously reporting an action as available.
  if (![[self accessibilityActionNames] containsObject:action])
    return;

  ui::AXActionData data;
  if ([action isEqualToString:NSAccessibilityShowMenuAction] &&
      AlsoUseShowMenuActionForDefaultAction(_node->GetData())) {
    data.action = ax::mojom::Action::kDoDefault;
  } else {
    for (const ActionList::value_type& entry : GetActionList()) {
      if ([action isEqualToString:entry.second]) {
        data.action = entry.first;
        break;
      }
    }
  }

  // Note ui::AX_ACTIONs which are just overwriting an accessibility attribute
  // are already implemented in -accessibilitySetValue:forAttribute:, so ignore
  // those here.

  if (data.action != ax::mojom::Action::kNone)
    _node->GetDelegate()->AccessibilityPerformAction(data);
}

// This method, while deprecated, is still called internally by AppKit.
- (NSArray*)accessibilityAttributeNames {
  if (!_node)
    return @[];
  // These attributes are required on all accessibility objects.
  NSArray* const kAllRoleAttributes = @[
    NSAccessibilityChildrenAttribute,
    NSAccessibilityParentAttribute,
    NSAccessibilityPositionAttribute,
    NSAccessibilityRoleAttribute,
    NSAccessibilitySizeAttribute,
    NSAccessibilitySubroleAttribute,
    // Title is required for most elements. Cocoa asks for the value even if it
    // is omitted here, but won't present it to accessibility APIs without this.
    NSAccessibilityTitleAttribute,
    // Attributes which are not required, but are general to all roles.
    NSAccessibilityRoleDescriptionAttribute,
    NSAccessibilityEnabledAttribute,
    NSAccessibilityFocusedAttribute,
    NSAccessibilityHelpAttribute,
    NSAccessibilityTopLevelUIElementAttribute,
    NSAccessibilityWindowAttribute,
  ];
  // Attributes required for user-editable controls.
  NSArray* const kValueAttributes = @[ NSAccessibilityValueAttribute ];
  // Attributes required for unprotected textfields and labels.
  NSArray* const kUnprotectedTextAttributes = @[
    NSAccessibilityInsertionPointLineNumberAttribute,
    NSAccessibilityNumberOfCharactersAttribute,
    NSAccessibilitySelectedTextAttribute,
    NSAccessibilitySelectedTextRangeAttribute,
    NSAccessibilityVisibleCharacterRangeAttribute,
  ];
  // Required for all text, including protected textfields.
  NSString* const kTextAttributes = NSAccessibilityPlaceholderValueAttribute;
  base::scoped_nsobject<NSMutableArray> axAttributes(
      [[NSMutableArray alloc] init]);
  [axAttributes addObjectsFromArray:kAllRoleAttributes];
  switch (_node->GetData().role) {
    case ax::mojom::Role::kTextField:
    case ax::mojom::Role::kTextFieldWithComboBox:
    case ax::mojom::Role::kStaticText:
      [axAttributes addObject:kTextAttributes];
      if (!_node->GetData().HasState(ax::mojom::State::kProtected))
        [axAttributes addObjectsFromArray:kUnprotectedTextAttributes];
      FALLTHROUGH;
    case ax::mojom::Role::kCheckBox:
    case ax::mojom::Role::kComboBoxMenuButton:
    case ax::mojom::Role::kMenuItemCheckBox:
    case ax::mojom::Role::kMenuItemRadio:
    case ax::mojom::Role::kRadioButton:
    case ax::mojom::Role::kSearchBox:
    case ax::mojom::Role::kSlider:
    case ax::mojom::Role::kSliderThumb:
    case ax::mojom::Role::kToggleButton:
      [axAttributes addObjectsFromArray:kValueAttributes];
      break;
      // TODO(tapted): Add additional attributes based on role.
    default:
      break;
  }
  if (_node->GetData().HasBoolAttribute(ax::mojom::BoolAttribute::kSelected)) {
    [axAttributes addObjectsFromArray:@[ NSAccessibilitySelectedAttribute ]];
  }
  if (ui::IsMenuItem(_node->GetData().role)) {
    [axAttributes addObjectsFromArray:@[ @"AXMenuItemMarkChar" ]];
  }
  return axAttributes.autorelease();
}

// Despite it being deprecated, AppKit internally calls this function sometimes
// in unclear circumstances. It is implemented in terms of the new a11y API
// here.
- (void)accessibilitySetValue:(id)value forAttribute:(NSString*)attribute {
  if (!_node)
    return;

  if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
    [self setAccessibilityValue:value];
  } else if ([attribute isEqualToString:NSAccessibilitySelectedTextAttribute]) {
    [self setAccessibilitySelectedText:base::mac::ObjCCastStrict<NSString>(
                                           value)];
  } else if ([attribute
                 isEqualToString:NSAccessibilitySelectedTextRangeAttribute]) {
    [self setAccessibilitySelectedTextRange:base::mac::ObjCCastStrict<NSValue>(
                                                value)
                                                .rangeValue];
  } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
    [self setAccessibilityFocused:base::mac::ObjCCastStrict<NSNumber>(value)
                                      .boolValue];
  }
}

// This method, while deprecated, is still called internally by AppKit.
- (id)accessibilityAttributeValue:(NSString*)attribute {
  if (!_node)
    return nil;  // Return nil when detached. Even for ax::mojom::Role.

  SEL selector = NSSelectorFromString(attribute);
  if ([self respondsToSelector:selector])
    return [self performSelector:selector];
  return nil;
}

- (id)accessibilityAttributeValue:(NSString*)attribute
                     forParameter:(id)parameter {
  if (!_node)
    return nil;

  SEL selector = NSSelectorFromString([attribute stringByAppendingString:@":"]);
  if ([self respondsToSelector:selector])
    return [self performSelector:selector withObject:parameter];
  return nil;
}

// NSAccessibility attributes. Order them according to
// NSAccessibilityConstants.h, or see https://crbug.com/678898.

- (NSString*)AXRole {
  if (!_node)
    return nil;

  return [[self class] nativeRoleFromAXRole:_node->GetData().role];
}

- (NSString*)AXRoleDescription {
  switch (_node->GetData().role) {
    case ax::mojom::Role::kTab:
      // There is no NSAccessibilityTabRole or similar (AXRadioButton is used
      // instead). Do the same as NSTabView and put "tab" in the description.
      return [l10n_util::GetNSStringWithFixup(IDS_ACCNAME_TAB_ROLE_DESCRIPTION)
          lowercaseString];
    case ax::mojom::Role::kDisclosureTriangle:
      return [l10n_util::GetNSStringWithFixup(
          IDS_ACCNAME_DISCLOSURE_TRIANGLE_ROLE_DESCRIPTION) lowercaseString];
    default:
      break;
  }
  return NSAccessibilityRoleDescription([self AXRole], [self AXSubrole]);
}

- (NSString*)AXSubrole {
  ax::mojom::Role role = _node->GetData().role;
  switch (role) {
    case ax::mojom::Role::kTextField:
      if (_node->GetData().HasState(ax::mojom::State::kProtected))
        return NSAccessibilitySecureTextFieldSubrole;
      break;
    default:
      break;
  }
  return [AXPlatformNodeCocoa nativeSubroleFromAXRole:role];
}

- (NSString*)AXHelp {
  // TODO(aleventhal) Key shortcuts attribute should eventually get
  // its own field. Follow what WebKit does for aria-keyshortcuts, see
  // https://bugs.webkit.org/show_bug.cgi?id=159215 (WebKit bug).
  NSString* desc =
      [self getStringAttribute:ax::mojom::StringAttribute::kDescription];
  NSString* key =
      [self getStringAttribute:ax::mojom::StringAttribute::kKeyShortcuts];
  if (!desc.length)
    return key.length ? key : @"";
  if (!key.length)
    return desc;
  return [NSString stringWithFormat:@"%@ %@", desc, key];
}

- (id)AXValue {
  ax::mojom::Role role = _node->GetData().role;
  if (role == ax::mojom::Role::kTab)
    return [self AXSelected];

  if (ui::IsNameExposedInAXValueForRole(role))
    return [self getName];

  if (_node->IsPlatformCheckable()) {
    // Mixed checkbox state not currently supported in views, but could be.
    // See browser_accessibility_cocoa.mm for details.
    const auto checkedState = static_cast<ax::mojom::CheckedState>(
        _node->GetIntAttribute(ax::mojom::IntAttribute::kCheckedState));
    return checkedState == ax::mojom::CheckedState::kTrue ? @1 : @0;
  }
  return [self getStringAttribute:ax::mojom::StringAttribute::kValue];
}

- (NSNumber*)AXEnabled {
  return
      @(_node->GetData().GetRestriction() != ax::mojom::Restriction::kDisabled);
}

- (NSNumber*)AXFocused {
  if (_node->GetData().HasState(ax::mojom::State::kFocusable))
    return
        @(_node->GetDelegate()->GetFocus() == _node->GetNativeViewAccessible());
  return @NO;
}

- (id)AXParent {
  if (!_node)
    return nil;
  return NSAccessibilityUnignoredAncestor(_node->GetParent());
}

- (NSArray*)AXChildren {
  if (!_node)
    return @[];

  int count = _node->GetChildCount();
  NSMutableArray* children = [NSMutableArray arrayWithCapacity:count];
  for (auto child_iterator_ptr = _node->GetDelegate()->ChildrenBegin();
       *child_iterator_ptr != *_node->GetDelegate()->ChildrenEnd();
       ++(*child_iterator_ptr)) {
    [children addObject:child_iterator_ptr->GetNativeViewAccessible()];
  }
  return NSAccessibilityUnignoredChildren(children);
}

- (id)AXWindow {
  return _node->GetDelegate()->GetNSWindow();
}

- (id)AXTopLevelUIElement {
  return [self AXWindow];
}

- (NSValue*)AXPosition {
  return [NSValue valueWithPoint:self.boundsInScreen.origin];
}

- (NSValue*)AXSize {
  return [NSValue valueWithSize:self.boundsInScreen.size];
}

- (NSString*)AXTitle {
  if (ui::IsNameExposedInAXValueForRole(_node->GetData().role))
    return @"";

  return [self getName];
}

// Misc attributes.

- (NSNumber*)AXSelected {
  return
      @(_node->GetData().GetBoolAttribute(ax::mojom::BoolAttribute::kSelected));
}

- (NSString*)AXPlaceholderValue {
  return [self getStringAttribute:ax::mojom::StringAttribute::kPlaceholder];
}

- (NSString*)AXMenuItemMarkChar {
  if (!ui::IsMenuItem(_node->GetData().role))
    return nil;

  const auto checkedState = static_cast<ax::mojom::CheckedState>(
      _node->GetIntAttribute(ax::mojom::IntAttribute::kCheckedState));
  if (checkedState == ax::mojom::CheckedState::kTrue) {
    return @"\xE2\x9C\x93";  // UTF-8 for unicode 0x2713, "check mark"
  }

  return @"";
}

// Text-specific attributes.

- (NSString*)AXSelectedText {
  NSRange selectedTextRange;
  [[self AXSelectedTextRange] getValue:&selectedTextRange];
  return [[self getAXValueAsString] substringWithRange:selectedTextRange];
}

- (NSValue*)AXSelectedTextRange {
  // Selection might not be supported. Return (NSRange){0,0} in that case.
  int start = 0, end = 0;
  if (_node->IsPlainTextField()) {
    start = _node->GetIntAttribute(ax::mojom::IntAttribute::kTextSelStart);
    end = _node->GetIntAttribute(ax::mojom::IntAttribute::kTextSelEnd);
  }

  // NSRange cannot represent the direction the text was selected in.
  return [NSValue valueWithRange:{std::min(start, end), abs(end - start)}];
}

- (NSNumber*)AXNumberOfCharacters {
  return @([[self getAXValueAsString] length]);
}

- (NSValue*)AXVisibleCharacterRange {
  return [NSValue valueWithRange:{0, [[self getAXValueAsString] length]}];
}

- (NSNumber*)AXInsertionPointLineNumber {
  // Multiline is not supported on views.
  return @0;
}

// Parameterized text-specific attributes.

- (id)AXLineForIndex:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSNumber class]]);
  // Multiline is not supported on views.
  return @0;
}

- (id)AXRangeForLine:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSNumber class]]);
  DCHECK_EQ(0, [parameter intValue]);
  return [NSValue valueWithRange:{0, [[self getAXValueAsString] length]}];
}

- (id)AXStringForRange:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSValue class]]);
  return [[self getAXValueAsString] substringWithRange:[parameter rangeValue]];
}

- (id)AXRangeForPosition:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSValue class]]);
  // TODO(tapted): Hit-test [parameter pointValue] and return an NSRange.
  NOTIMPLEMENTED();
  return nil;
}

- (id)AXRangeForIndex:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSNumber class]]);
  NOTIMPLEMENTED();
  return nil;
}

- (id)AXBoundsForRange:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSValue class]]);
  // TODO(tapted): Provide an accessor on AXPlatformNodeDelegate to obtain this
  // from ui::TextInputClient::GetCompositionCharacterBounds().
  NOTIMPLEMENTED();
  return nil;
}

- (id)AXRTFForRange:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSValue class]]);
  NOTIMPLEMENTED();
  return nil;
}

- (id)AXStyleRangeForIndex:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSNumber class]]);
  NOTIMPLEMENTED();
  return nil;
}

- (id)AXAttributedStringForRange:(id)parameter {
  DCHECK([parameter isKindOfClass:[NSValue class]]);
  base::scoped_nsobject<NSAttributedString> attributedString(
      [[NSAttributedString alloc]
          initWithString:[self AXStringForRange:parameter]]);
  // TODO(tapted): views::WordLookupClient has a way to obtain the actual
  // decorations, and BridgedContentView has a conversion function that creates
  // an NSAttributedString. Refactor things so they can be used here.
  return attributedString.autorelease();
}

- (NSString*)description {
  return [NSString stringWithFormat:@"%@ - %@ (%@)", [super description],
                                    [self AXTitle], [self AXRole]];
}

// The methods below implement the NSAccessibility protocol. These methods
// appear to be the minimum needed to avoid AppKit refusing to handle the
// element or crashing internally. Most of the remaining old API methods (the
// ones from NSObject) are implemented in terms of the new NSAccessibility
// methods.
//
// TODO(https://crbug.com/386671): Does this class need to implement the various
// accessibilityPerformFoo methods, or are the stub implementations from
// NSAccessibilityElement sufficient?
- (NSArray*)accessibilityChildren {
  return [self AXChildren];
}

- (BOOL)isAccessibilityElement {
  if (!_node)
    return NO;

  return (![[self AXRole] isEqualToString:NSAccessibilityUnknownRole] &&
          !_node->GetData().HasState(ax::mojom::State::kInvisible));
}
- (BOOL)isAccessibilityEnabled {
  if (!_node)
    return NO;

  return _node->GetData().GetRestriction() != ax::mojom::Restriction::kDisabled;
}
- (NSRect)accessibilityFrame {
  return [self boundsInScreen];
}

- (NSString*)accessibilityLabel {
  // accessibilityLabel is "a short description of the accessibility element",
  // and accessibilityTitle is "the title of the accessibility element"; at
  // least in Chromium, the title usually is a short description of the element,
  // so it also functions as a label.
  return [self AXTitle];
}

- (NSString*)accessibilityTitle {
  return [self AXTitle];
}

- (id)accessibilityValue {
  return [self AXValue];
}

- (NSAccessibilityRole)accessibilityRole {
  return [self AXRole];
}

- (NSAccessibilitySubrole)accessibilitySubrole {
  return [self AXSubrole];
}

- (BOOL)isAccessibilitySelectorAllowed:(SEL)selector {
  if (!_node)
    return NO;

  const ax::mojom::Restriction restriction = _node->GetData().GetRestriction();
  if (restriction == ax::mojom::Restriction::kDisabled)
    return NO;

  if (selector == @selector(setAccessibilityValue:)) {
    // Tabs use the radio button role on Mac, so they are selected by calling
    // setSelected on an individual tab, rather than by setting the selected
    // element on the tabstrip as a whole.
    if (_node->GetData().role == ax::mojom::Role::kTab) {
      return !_node->GetData().GetBoolAttribute(
          ax::mojom::BoolAttribute::kSelected);
    }
    return restriction != ax::mojom::Restriction::kReadOnly;
  }

  // TODO(https://crbug.com/692362): Once the underlying bug in
  // views::Textfield::SetSelectionRange() described in that bug is fixed,
  // remove the check here; right now, this check serves to prevent
  // accessibility clients from trying to set the selection range, which won't
  // work because of 692362.
  if (selector == @selector(setAccessibilitySelectedText:) ||
      selector == @selector(setAccessibilitySelectedTextRange:)) {
    return restriction != ax::mojom::Restriction::kReadOnly;
  }

  if (selector == @selector(setAccessibilityFocused:))
    return _node->GetData().HasState(ax::mojom::State::kFocusable);

  // TODO(https://crbug.com/386671): What about role-specific selectors?
  return [super isAccessibilitySelectorAllowed:selector];
}

- (void)setAccessibilityValue:(id)value {
  if (!_node)
    return;

  ui::AXActionData data;
  data.action = _node->GetData().role == ax::mojom::Role::kTab
                    ? ax::mojom::Action::kSetSelection
                    : ax::mojom::Action::kSetValue;
  if ([value isKindOfClass:[NSString class]]) {
    data.value = base::SysNSStringToUTF8(value);
  } else if ([value isKindOfClass:[NSValue class]]) {
    // TODO(https://crbug.com/386671): Is this case actually needed? The
    // NSObject accessibility implementation supported this, but can it actually
    // occur?
    NSRange range = [value rangeValue];
    data.anchor_offset = range.location;
    data.focus_offset = NSMaxRange(range);
  }
  _node->GetDelegate()->AccessibilityPerformAction(data);
}

- (void)setAccessibilityFocused:(BOOL)isFocused {
  if (!_node)
    return;

  ui::AXActionData data;
  data.action =
      isFocused ? ax::mojom::Action::kFocus : ax::mojom::Action::kBlur;
  _node->GetDelegate()->AccessibilityPerformAction(data);
}

- (void)setAccessibilitySelectedText:(NSString*)text {
  if (!_node)
    return;

  ui::AXActionData data;
  data.action = ax::mojom::Action::kReplaceSelectedText;
  data.value = base::SysNSStringToUTF8(text);

  _node->GetDelegate()->AccessibilityPerformAction(data);
}

- (void)setAccessibilitySelectedTextRange:(NSRange)range {
  if (!_node)
    return;

  ui::AXActionData data;
  data.action = ax::mojom::Action::kSetSelection;
  data.anchor_offset = range.location;
  data.focus_offset = NSMaxRange(range);
  _node->GetDelegate()->AccessibilityPerformAction(data);
}

// "Configuring Text Elements" section of the NSAccessibility formal protocol.
// These are all "required" methods, although in practice the ones that are left
// NOTIMPLEMENTED() seem to not be called anywhere (and were NOTIMPLEMENTED in
// the old API as well).

- (NSInteger)accessibilityInsertionPointLineNumber {
  return 0;
}

- (NSInteger)accessibilityNumberOfCharacters {
  if (!_node)
    return 0;

  return [[self getAXValueAsString] length];
}

- (NSString*)accessibilityPlaceholderValue {
  if (!_node)
    return nil;

  return [self AXPlaceholderValue];
}

- (NSString*)accessibilitySelectedText {
  if (!_node)
    return nil;

  return [self AXSelectedText];
}

- (NSRange)accessibilitySelectedTextRange {
  if (!_node)
    return NSMakeRange(0, 0);

  NSRange r;
  [[self AXSelectedTextRange] getValue:&r];
  return r;
}

- (NSArray*)accessibilitySelectedTextRanges {
  if (!_node)
    return nil;

  return @[ [self AXSelectedTextRange] ];
}

- (NSRange)accessibilityVisibleCharacterRange {
  if (!_node)
    return NSMakeRange(0, 0);

  return NSMakeRange(0, [self accessibilityNumberOfCharacters]);
}

- (NSString*)accessibilityStringForRange:(NSRange)range {
  if (!_node)
    return nil;

  return [[self getAXValueAsString] substringWithRange:range];
}

- (NSAttributedString*)accessibilityAttributedStringForRange:(NSRange)range {
  if (!_node)
    return nil;

  // TODO(https://crbug.com/958811): Implement this for real.
  base::scoped_nsobject<NSAttributedString> attributedString(
      [[NSAttributedString alloc]
          initWithString:[self accessibilityStringForRange:range]]);
  return attributedString.autorelease();
}

- (NSInteger)accessibilityLineForIndex:(NSInteger)index {
  // Views textfields are single-line.
  return 0;
}

- (NSRange)accessibilityRangeForIndex:(NSInteger)index {
  NOTIMPLEMENTED();
  return NSMakeRange(0, 0);
}

- (NSRange)accessibilityStyleRangeForIndex:(NSInteger)index {
  if (!_node)
    return NSMakeRange(0, 0);

  // TODO(https://crbug.com/958811): Implement this for real.
  return NSMakeRange(0, [self accessibilityNumberOfCharacters]);
}

- (NSRange)accessibilityRangeForLine:(NSInteger)line {
  if (!_node)
    return NSMakeRange(0, 0);

  if (line != 0)
    NOTIMPLEMENTED() << "Views textfields are single-line.";
  return NSMakeRange(0, [self accessibilityNumberOfCharacters]);
}

- (NSRange)accessibilityRangeForPosition:(NSPoint)point {
  NOTIMPLEMENTED();
  return NSMakeRange(0, 0);
}

@end

namespace ui {

// static
AXPlatformNode* AXPlatformNode::Create(AXPlatformNodeDelegate* delegate) {
  AXPlatformNodeBase* node = new AXPlatformNodeMac();
  node->Init(delegate);
  return node;
}

// static
AXPlatformNode* AXPlatformNode::FromNativeViewAccessible(
    gfx::NativeViewAccessible accessible) {
  if ([accessible isKindOfClass:[AXPlatformNodeCocoa class]])
    return [accessible node];
  return nullptr;
}

AXPlatformNodeMac::AXPlatformNodeMac() {
}

AXPlatformNodeMac::~AXPlatformNodeMac() {
}

void AXPlatformNodeMac::Destroy() {
  if (native_node_)
    [native_node_ detach];
  AXPlatformNodeBase::Destroy();
}

// On Mac, the checked state is mapped to AXValue.
bool AXPlatformNodeMac::IsPlatformCheckable() const {
  if (GetData().role == ax::mojom::Role::kTab) {
    // On Mac, tabs are exposed as radio buttons, and are treated as checkable.
    // Also, the internal State::kSelected is be mapped to checked via AXValue.
    return true;
  }

  return AXPlatformNodeBase::IsPlatformCheckable();
}

gfx::NativeViewAccessible AXPlatformNodeMac::GetNativeViewAccessible() {
  if (!native_node_)
    native_node_.reset([[AXPlatformNodeCocoa alloc] initWithNode:this]);
  return native_node_.get();
}

void AXPlatformNodeMac::NotifyAccessibilityEvent(ax::mojom::Event event_type) {
  AXPlatformNodeBase::NotifyAccessibilityEvent(event_type);
  GetNativeViewAccessible();
  // Handle special cases.

  // Alerts and live regions go through the announcement API instead of the
  // regular NSAccessibility notification system.
  if (event_type == ax::mojom::Event::kAlert ||
      event_type == ax::mojom::Event::kLiveRegionChanged) {
    if (auto announcement = [native_node_ announcementForEvent:event_type]) {
      [native_node_ scheduleLiveRegionAnnouncement:std::move(announcement)];
    }
    return;
  }
  if (event_type == ax::mojom::Event::kSelection) {
    ax::mojom::Role role = GetData().role;
    if (ui::IsMenuItem(role)) {
      // On Mac, map menu item selection to a focus event.
      NotifyMacEvent(native_node_, ax::mojom::Event::kFocus);
      return;
    } else if (ui::IsListItem(role)) {
      if (AXPlatformNodeBase* container = GetSelectionContainer()) {
        const ui::AXNodeData& data = container->GetData();
        if (data.role == ax::mojom::Role::kListBox &&
            !data.HasState(ax::mojom::State::kMultiselectable) &&
            GetDelegate()->GetFocus() == GetNativeViewAccessible()) {
          NotifyMacEvent(native_node_, ax::mojom::Event::kFocus);
          return;
        }
      }
    }
  }
  // Otherwise, use mappings between ax::mojom::Event and NSAccessibility
  // notifications from the EventMap above.
  NotifyMacEvent(native_node_, event_type);
}

void AXPlatformNodeMac::AnnounceText(const base::string16& text) {
  PostAnnouncementNotification(base::SysUTF16ToNSString(text),
                               [native_node_ AXWindow], false);
}

bool IsNameExposedInAXValueForRole(ax::mojom::Role role) {
  switch (role) {
    case ax::mojom::Role::kListBoxOption:
    case ax::mojom::Role::kListMarker:
    case ax::mojom::Role::kMenuListOption:
    case ax::mojom::Role::kStaticText:
    case ax::mojom::Role::kTitleBar:
      return true;
    default:
      return false;
  }
}

void AXPlatformNodeMac::AddAttributeToList(const char* name,
                                           const char* value,
                                           PlatformAttributeList* attributes) {
  NOTREACHED();
}

}  // namespace ui

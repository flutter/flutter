/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebAXEnums_h
#define WebAXEnums_h

namespace blink {

// Accessibility events sent from Blink to the embedder.
// These values must match blink::AXObjectCache::AXNotification values.
// Enforced in AssertMatchingEnums.cpp.
enum WebAXEvent {
    WebAXEventActiveDescendantChanged,
    WebAXEventAlert,
    WebAXEventAriaAttributeChanged,
    WebAXEventAutocorrectionOccured,
    WebAXEventBlur,
    WebAXEventCheckedStateChanged,
    WebAXEventChildrenChanged,
    WebAXEventFocus,
    WebAXEventHide,
    WebAXEventInvalidStatusChanged,
    WebAXEventLayoutComplete,
    WebAXEventLiveRegionChanged,
    WebAXEventLoadComplete,
    WebAXEventLocationChanged,
    WebAXEventMenuListItemSelected,
    WebAXEventMenuListValueChanged,
    WebAXEventRowCollapsed,
    WebAXEventRowCountChanged,
    WebAXEventRowExpanded,
    WebAXEventScrollPositionChanged,
    WebAXEventScrolledToAnchor,
    WebAXEventSelectedChildrenChanged,
    WebAXEventSelectedTextChanged,
    WebAXEventShow,
    WebAXEventTextChanged,
    WebAXEventTextInserted,
    WebAXEventTextRemoved,
    WebAXEventValueChanged
};

// Accessibility roles.
// These values must match blink::AccessibilityRole values.
// Enforced in AssertMatchingEnums.cpp.
enum WebAXRole {
    WebAXRoleAlertDialog = 1,
    WebAXRoleAlert,
    WebAXRoleAnnotation,
    WebAXRoleApplication,
    WebAXRoleArticle,
    WebAXRoleBanner,
    WebAXRoleBrowser,
    WebAXRoleBusyIndicator,
    WebAXRoleButton,
    WebAXRoleCanvas,
    WebAXRoleCell,
    WebAXRoleCheckBox,
    WebAXRoleColorWell,
    WebAXRoleColumnHeader,
    WebAXRoleColumn,
    WebAXRoleComboBox,
    WebAXRoleComplementary,
    WebAXRoleContentInfo,
    WebAXRoleDefinition,
    WebAXRoleDescriptionListDetail,
    WebAXRoleDescriptionListTerm,
    WebAXRoleDialog,
    WebAXRoleDirectory,
    WebAXRoleDisclosureTriangle,
    WebAXRoleDiv,
    WebAXRoleDocument,
    WebAXRoleDrawer,
    WebAXRoleEditableText,
    WebAXRoleEmbeddedObject,
    WebAXRoleFigcaption,
    WebAXRoleFigure,
    WebAXRoleFooter,
    WebAXRoleForm,
    WebAXRoleGrid,
    WebAXRoleGroup,
    WebAXRoleGrowArea,
    WebAXRoleHeading,
    WebAXRoleHelpTag,
    WebAXRoleHorizontalRule,
    WebAXRoleIframe,
    WebAXRoleIgnored,
    WebAXRoleImageMapLink,
    WebAXRoleImageMap,
    WebAXRoleImage,
    WebAXRoleIncrementor,
    WebAXRoleInlineTextBox,
    WebAXRoleLabel,
    WebAXRoleLegend,
    WebAXRoleLink,
    WebAXRoleListBoxOption,
    WebAXRoleListBox,
    WebAXRoleListItem,
    WebAXRoleListMarker,
    WebAXRoleList,
    WebAXRoleLog,
    WebAXRoleMain,
    WebAXRoleMathElement,
    WebAXRoleMath,
    WebAXRoleMatte,
    WebAXRoleMenuBar,
    WebAXRoleMenuButton,
    WebAXRoleMenuItem,
    WebAXRoleMenuListOption,
    WebAXRoleMenuListPopup,
    WebAXRoleMenu,
    WebAXRoleNavigation,
    WebAXRoleNote,
    WebAXRoleOutline,
    WebAXRoleParagraph,
    WebAXRolePopUpButton,
    WebAXRolePresentational,
    WebAXRoleProgressIndicator,
    WebAXRoleRadioButton,
    WebAXRoleRadioGroup,
    WebAXRoleRegion,
    WebAXRoleRootWebArea,
    WebAXRoleRowHeader,
    WebAXRoleRow,
    WebAXRoleRulerMarker,
    WebAXRoleRuler,
    WebAXRoleSVGRoot,
    WebAXRoleScrollArea,
    WebAXRoleScrollBar,
    WebAXRoleSeamlessWebArea,
    WebAXRoleSearch,
    WebAXRoleSheet,
    WebAXRoleSlider,
    WebAXRoleSliderThumb,
    WebAXRoleSpinButtonPart,
    WebAXRoleSpinButton,
    WebAXRoleSplitGroup,
    WebAXRoleSplitter,
    WebAXRoleStaticText,
    WebAXRoleStatus,
    WebAXRoleSystemWide,
    WebAXRoleTabGroup,
    WebAXRoleTabList,
    WebAXRoleTabPanel,
    WebAXRoleTab,
    WebAXRoleTableHeaderContainer,
    WebAXRoleTable,
    WebAXRoleTextArea,
    WebAXRoleTextField,
    WebAXRoleTimer,
    WebAXRoleToggleButton,
    WebAXRoleToolbar,
    WebAXRoleTreeGrid,
    WebAXRoleTreeItem,
    WebAXRoleTree,
    WebAXRoleUnknown,
    WebAXRoleUserInterfaceTooltip,
    WebAXRoleValueIndicator,
    WebAXRoleWebArea,
    WebAXRoleWindow,
};

// Accessibility states, used as a bitmask.
enum WebAXState {
    WebAXStateBusy,
    WebAXStateChecked,
    WebAXStateCollapsed,
    WebAXStateEnabled,
    WebAXStateExpanded,
    WebAXStateFocusable,
    WebAXStateFocused,
    WebAXStateHaspopup,
    WebAXStateHovered,
    WebAXStateIndeterminate,
    WebAXStateInvisible,
    WebAXStateLinked,
    WebAXStateMultiselectable,
    WebAXStateOffscreen,
    WebAXStatePressed,
    WebAXStateProtected,
    WebAXStateReadonly,
    WebAXStateRequired,
    WebAXStateSelectable,
    WebAXStateSelected,
    WebAXStateVertical,
    WebAXStateVisited,
};

// Text direction, only used for role=WebAXRoleInlineTextBox.
enum WebAXTextDirection {
    WebAXTextDirectionLR,
    WebAXTextDirectionRL,
    WebAXTextDirectionTB,
    WebAXTextDirectionBT
};

} // namespace blink

#endif

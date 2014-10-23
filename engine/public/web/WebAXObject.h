/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebAXObject_h
#define WebAXObject_h

#include "../platform/WebCommon.h"
#include "../platform/WebPrivatePtr.h"
#include "../platform/WebVector.h"
#include "WebAXEnums.h"

#if BLINK_IMPLEMENTATION
namespace WTF { template <typename T> class PassRefPtr; }
#endif

namespace blink {

class AXObject;
class WebNode;
class WebDocument;
class WebString;
class WebURL;
struct WebPoint;
struct WebRect;

// A container for passing around a reference to AXObject.
class WebAXObject {
public:
    ~WebAXObject() { reset(); }

    WebAXObject() { }
    WebAXObject(const WebAXObject& o) { assign(o); }
    WebAXObject& operator=(const WebAXObject& o)
    {
        assign(o);
        return *this;
    }

    BLINK_EXPORT void reset();
    BLINK_EXPORT void assign(const WebAXObject&);
    BLINK_EXPORT bool equals(const WebAXObject&) const;

    bool isNull() const { return m_private.isNull(); }
    // isDetached also checks for null, so it's safe to just call isDetached.
    BLINK_EXPORT bool isDetached() const;

    BLINK_EXPORT int axID() const;

    // Update layout on the underlying tree, and return true if this object is
    // still valid (not detached). Note that calling this method
    // can cause other WebAXObjects to become invalid, too,
    // so always call isDetached if updateBackingStoreAndCheckValidity
    // has been called on any object, or if any other WebCore code has run.
    BLINK_EXPORT bool updateLayoutAndCheckValidity();

    // FIXME: Deprecated - remove once callers use updateLayoutAndCheckValidity, instead.
    BLINK_EXPORT bool updateBackingStoreAndCheckValidity();

    BLINK_EXPORT WebString accessibilityDescription() const;
    BLINK_EXPORT unsigned childCount() const;

    BLINK_EXPORT WebAXObject childAt(unsigned) const;
    BLINK_EXPORT WebAXObject parentObject() const;

    BLINK_EXPORT bool isAnchor() const;
    BLINK_EXPORT bool isAriaReadOnly() const;
    BLINK_EXPORT bool isButtonStateMixed() const;
    BLINK_EXPORT bool isChecked() const;
    BLINK_EXPORT bool isClickable() const;
    BLINK_EXPORT bool isCollapsed() const;
    BLINK_EXPORT bool isControl() const;
    BLINK_EXPORT bool isEnabled() const;
    BLINK_EXPORT bool isFocused() const;
    BLINK_EXPORT bool isHovered() const;
    BLINK_EXPORT bool isIndeterminate() const;
    BLINK_EXPORT bool isLinked() const;
    BLINK_EXPORT bool isLoaded() const;
    BLINK_EXPORT bool isMultiSelectable() const;
    BLINK_EXPORT bool isOffScreen() const;
    BLINK_EXPORT bool isPasswordField() const;
    BLINK_EXPORT bool isPressed() const;
    BLINK_EXPORT bool isReadOnly() const;
    BLINK_EXPORT bool isRequired() const;
    BLINK_EXPORT bool isSelected() const;
    BLINK_EXPORT bool isSelectedOptionActive() const;
    BLINK_EXPORT bool isVertical() const;
    BLINK_EXPORT bool isVisible() const;
    BLINK_EXPORT bool isVisited() const;

    BLINK_EXPORT WebString accessKey() const;
    BLINK_EXPORT WebAXObject ariaActiveDescendant() const;
    BLINK_EXPORT bool ariaControls(WebVector<WebAXObject>& controlsElements) const;
    BLINK_EXPORT bool ariaDescribedby(WebVector<WebAXObject>& describedbyElements) const;
    BLINK_EXPORT bool ariaFlowTo(WebVector<WebAXObject>& flowToElements) const;
    BLINK_EXPORT bool ariaHasPopup() const;
    BLINK_EXPORT bool ariaLabelledby(WebVector<WebAXObject>& labelledbyElements) const;
    BLINK_EXPORT bool ariaLiveRegionAtomic() const;
    BLINK_EXPORT bool ariaLiveRegionBusy() const;
    BLINK_EXPORT WebString ariaLiveRegionRelevant() const;
    BLINK_EXPORT WebString ariaLiveRegionStatus() const;
    BLINK_EXPORT bool ariaOwns(WebVector<WebAXObject>& ownsElements) const;
    BLINK_EXPORT WebRect boundingBoxRect() const;
    BLINK_EXPORT bool canvasHasFallbackContent() const;
    BLINK_EXPORT WebPoint clickPoint() const;
    BLINK_EXPORT void colorValue(int& r, int& g, int& b) const;
    BLINK_EXPORT double estimatedLoadingProgress() const;
    BLINK_EXPORT WebString helpText() const;
    BLINK_EXPORT int headingLevel() const;
    BLINK_EXPORT int hierarchicalLevel() const;
    BLINK_EXPORT WebAXObject hitTest(const WebPoint&) const;
    BLINK_EXPORT WebString keyboardShortcut() const;
    BLINK_EXPORT WebAXRole role() const;
    BLINK_EXPORT unsigned selectionEnd() const;
    BLINK_EXPORT unsigned selectionEndLineNumber() const;
    BLINK_EXPORT unsigned selectionStart() const;
    BLINK_EXPORT unsigned selectionStartLineNumber() const;
    BLINK_EXPORT WebString stringValue() const;
    BLINK_EXPORT WebString title() const;
    BLINK_EXPORT WebAXObject titleUIElement() const;
    BLINK_EXPORT WebURL url() const;

    BLINK_EXPORT bool supportsRangeValue() const;
    BLINK_EXPORT WebString valueDescription() const;
    BLINK_EXPORT float valueForRange() const;
    BLINK_EXPORT float maxValueForRange() const;
    BLINK_EXPORT float minValueForRange() const;

    BLINK_EXPORT WebNode node() const;
    BLINK_EXPORT WebDocument document() const;
    BLINK_EXPORT bool hasComputedStyle() const;
    BLINK_EXPORT WebString computedStyleDisplay() const;
    BLINK_EXPORT bool accessibilityIsIgnored() const;
    BLINK_EXPORT bool lineBreaks(WebVector<int>&) const;

    // Actions
    BLINK_EXPORT WebString actionVerb() const; // The verb corresponding to performDefaultAction.
    BLINK_EXPORT bool canDecrement() const;
    BLINK_EXPORT bool canIncrement() const;
    BLINK_EXPORT bool canPress() const;
    BLINK_EXPORT bool canSetFocusAttribute() const;
    BLINK_EXPORT bool canSetSelectedAttribute() const;
    BLINK_EXPORT bool canSetValueAttribute() const;
    BLINK_EXPORT bool performDefaultAction() const;
    BLINK_EXPORT bool press() const;
    BLINK_EXPORT bool increment() const;
    BLINK_EXPORT bool decrement() const;
    BLINK_EXPORT void setFocused(bool) const;
    BLINK_EXPORT void setSelectedTextRange(int selectionStart, int selectionEnd) const;

    // For a table
    BLINK_EXPORT unsigned columnCount() const;
    BLINK_EXPORT unsigned rowCount() const;
    BLINK_EXPORT WebAXObject cellForColumnAndRow(unsigned column, unsigned row) const;
    BLINK_EXPORT WebAXObject headerContainerObject() const;
    BLINK_EXPORT WebAXObject rowAtIndex(unsigned rowIndex) const;
    BLINK_EXPORT WebAXObject columnAtIndex(unsigned columnIndex) const;

    // For a table row
    BLINK_EXPORT unsigned rowIndex() const;
    BLINK_EXPORT WebAXObject rowHeader() const;

    // For a table column
    BLINK_EXPORT unsigned columnIndex() const;
    BLINK_EXPORT WebAXObject columnHeader() const;

    // For a table cell
    BLINK_EXPORT unsigned cellColumnIndex() const;
    BLINK_EXPORT unsigned cellColumnSpan() const;
    BLINK_EXPORT unsigned cellRowIndex() const;
    BLINK_EXPORT unsigned cellRowSpan() const;

    // For an inline text box.
    BLINK_EXPORT WebAXTextDirection textDirection() const;
    BLINK_EXPORT void characterOffsets(WebVector<int>&) const;
    BLINK_EXPORT void wordBoundaries(WebVector<int>& starts, WebVector<int>& ends) const;

    // Make this object visible by scrolling as many nested scrollable views as needed.
    BLINK_EXPORT void scrollToMakeVisible() const;
    // Same, but if the whole object can't be made visible, try for this subrect, in local coordinates.
    BLINK_EXPORT void scrollToMakeVisibleWithSubFocus(const WebRect&) const;
    // Scroll this object to a given point in global coordinates of the top-level window.
    BLINK_EXPORT void scrollToGlobalPoint(const WebPoint&) const;

#if BLINK_IMPLEMENTATION
    WebAXObject(const WTF::PassRefPtr<AXObject>&);
    WebAXObject& operator=(const WTF::PassRefPtr<AXObject>&);
    operator WTF::PassRefPtr<AXObject>() const;
#endif

private:
    WebPrivatePtr<AXObject> m_private;
};

} // namespace blink

#endif

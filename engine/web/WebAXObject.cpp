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

#include "config.h"
#include "public/web/WebAXObject.h"

#include "public/platform/WebPoint.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebString.h"
#include "public/platform/WebURL.h"
#include "public/web/WebDocument.h"
#include "public/web/WebNode.h"

using namespace blink;

namespace blink {

void WebAXObject::reset()
{
}

void WebAXObject::assign(const WebAXObject& other)
{
}

bool WebAXObject::equals(const WebAXObject& n) const
{
    return false;
}

bool WebAXObject::isDetached() const
{
    return true;
}

int WebAXObject::axID() const
{
    return -1;
}

bool WebAXObject::updateLayoutAndCheckValidity()
{
    return false;
}

bool WebAXObject::updateBackingStoreAndCheckValidity()
{
    return false;
}

WebString WebAXObject::accessibilityDescription() const
{
    return WebString();
}

WebString WebAXObject::actionVerb() const
{
    return WebString();
}

bool WebAXObject::canDecrement() const
{
    return false;
}

bool WebAXObject::canIncrement() const
{
    return false;
}

bool WebAXObject::canPress() const
{
    return false;
}

bool WebAXObject::canSetFocusAttribute() const
{
    return false;
}

bool WebAXObject::canSetValueAttribute() const
{
    return false;
}

unsigned WebAXObject::childCount() const
{
    return 0;
}

WebAXObject WebAXObject::childAt(unsigned index) const
{
    return WebAXObject();
}

WebAXObject WebAXObject::parentObject() const
{
    return WebAXObject();
}

bool WebAXObject::canSetSelectedAttribute() const
{
    return 0;
}

bool WebAXObject::isAnchor() const
{
    return 0;
}

bool WebAXObject::isAriaReadOnly() const
{
    return 0;
}

bool WebAXObject::isButtonStateMixed() const
{
    return 0;
}

bool WebAXObject::isChecked() const
{
    return 0;
}

bool WebAXObject::isClickable() const
{
    return 0;
}

bool WebAXObject::isCollapsed() const
{
    return 0;
}

bool WebAXObject::isControl() const
{
    return 0;
}

bool WebAXObject::isEnabled() const
{
    return 0;
}

bool WebAXObject::isFocused() const
{
    return 0;
}

bool WebAXObject::isHovered() const
{
    return 0;
}

bool WebAXObject::isIndeterminate() const
{
    return 0;
}

bool WebAXObject::isLinked() const
{
    return 0;
}

bool WebAXObject::isLoaded() const
{
    return 0;
}

bool WebAXObject::isMultiSelectable() const
{
    return 0;
}

bool WebAXObject::isOffScreen() const
{
    return 0;
}

bool WebAXObject::isPasswordField() const
{
    return 0;
}

bool WebAXObject::isPressed() const
{
    return 0;
}

bool WebAXObject::isReadOnly() const
{
    return 0;
}

bool WebAXObject::isRequired() const
{
    return 0;
}

bool WebAXObject::isSelected() const
{
    return 0;
}

bool WebAXObject::isSelectedOptionActive() const
{
    return false;
}

bool WebAXObject::isVertical() const
{
    return 0;
}

bool WebAXObject::isVisible() const
{
    return 0;
}

bool WebAXObject::isVisited() const
{
    return 0;
}

WebString WebAXObject::accessKey() const
{
    return WebString();
}

WebAXObject WebAXObject::ariaActiveDescendant() const
{
    return WebAXObject();
}

bool WebAXObject::ariaControls(WebVector<WebAXObject>& controlsElements) const
{
    return false;
}

bool WebAXObject::ariaDescribedby(WebVector<WebAXObject>& describedbyElements) const
{
    return false;
}

bool WebAXObject::ariaHasPopup() const
{
    return 0;
}

bool WebAXObject::ariaFlowTo(WebVector<WebAXObject>& flowToElements) const
{
    return false;
}

bool WebAXObject::ariaLabelledby(WebVector<WebAXObject>& labelledbyElements) const
{
    return false;
}

bool WebAXObject::ariaLiveRegionAtomic() const
{
    return 0;
}

bool WebAXObject::ariaLiveRegionBusy() const
{
    return 0;
}

WebString WebAXObject::ariaLiveRegionRelevant() const
{
    return WebString();
}

WebString WebAXObject::ariaLiveRegionStatus() const
{
    return WebString();
}

bool WebAXObject::ariaOwns(WebVector<WebAXObject>& ownsElements) const
{
    return false;
}

WebRect WebAXObject::boundingBoxRect() const
{
    return WebRect();
}

bool WebAXObject::canvasHasFallbackContent() const
{
    return false;
}

WebPoint WebAXObject::clickPoint() const
{
    return WebPoint();
}

void WebAXObject::colorValue(int& r, int& g, int& b) const
{
}

double WebAXObject::estimatedLoadingProgress() const
{
    return 0.0;
}

WebString WebAXObject::helpText() const
{
    return WebString();
}

int WebAXObject::headingLevel() const
{
    return 0;
}

int WebAXObject::hierarchicalLevel() const
{
    return 0;
}

WebAXObject WebAXObject::hitTest(const WebPoint& point) const
{
    return WebAXObject();
}

WebString WebAXObject::keyboardShortcut() const
{
    return WebString();
}

bool WebAXObject::performDefaultAction() const
{
    return false;
}

bool WebAXObject::increment() const
{
    return false;
}

bool WebAXObject::decrement() const
{
    return false;
}

bool WebAXObject::press() const
{
    return false;
}

WebAXRole WebAXObject::role() const
{
    return WebAXRoleUnknown;
}

unsigned WebAXObject::selectionEnd() const
{
    return 0;
}

unsigned WebAXObject::selectionStart() const
{
    return 0;
}

unsigned WebAXObject::selectionEndLineNumber() const
{
    return 0;
}

unsigned WebAXObject::selectionStartLineNumber() const
{
    return 0;
}

void WebAXObject::setFocused(bool on) const
{
}

void WebAXObject::setSelectedTextRange(int selectionStart, int selectionEnd) const
{
}

WebString WebAXObject::stringValue() const
{
    return WebString();
}

WebString WebAXObject::title() const
{
    return WebString();
}

WebAXObject WebAXObject::titleUIElement() const
{
    return WebAXObject();
}

WebURL WebAXObject::url() const
{
    return WebURL();
}

bool WebAXObject::supportsRangeValue() const
{
    return false;
}

WebString WebAXObject::valueDescription() const
{
    return WebString();
}

float WebAXObject::valueForRange() const
{
    return 0.0;
}

float WebAXObject::maxValueForRange() const
{
    return 0.0;
}

float WebAXObject::minValueForRange() const
{
    return 0.0;
}

WebNode WebAXObject::node() const
{
    return WebNode();
}

WebDocument WebAXObject::document() const
{
    return WebDocument();
}

bool WebAXObject::hasComputedStyle() const
{
    return false;
}

WebString WebAXObject::computedStyleDisplay() const
{
    return WebString();
}

bool WebAXObject::accessibilityIsIgnored() const
{
    return false;
}

bool WebAXObject::lineBreaks(WebVector<int>& result) const
{
    return false;
}

unsigned WebAXObject::columnCount() const
{
    return false;
}

unsigned WebAXObject::rowCount() const
{
    return false;
}

WebAXObject WebAXObject::cellForColumnAndRow(unsigned column, unsigned row) const
{
    return WebAXObject();
}

WebAXObject WebAXObject::headerContainerObject() const
{
    return WebAXObject();
}

WebAXObject WebAXObject::rowAtIndex(unsigned rowIndex) const
{
    return WebAXObject();
}

WebAXObject WebAXObject::columnAtIndex(unsigned columnIndex) const
{
    return WebAXObject();
}

unsigned WebAXObject::rowIndex() const
{
    return 0;
}

WebAXObject WebAXObject::rowHeader() const
{
    return WebAXObject();
}

unsigned WebAXObject::columnIndex() const
{
    return 0;
}

WebAXObject WebAXObject::columnHeader() const
{
    return WebAXObject();
}

unsigned WebAXObject::cellColumnIndex() const
{
    return 0;
}

unsigned WebAXObject::cellColumnSpan() const
{
    return 0;
}

unsigned WebAXObject::cellRowIndex() const
{
    return 0;
}

unsigned WebAXObject::cellRowSpan() const
{
    return 0;
}

WebAXTextDirection WebAXObject::textDirection() const
{
    return WebAXTextDirectionLR;
}

void WebAXObject::characterOffsets(WebVector<int>& offsets) const
{
}

void WebAXObject::wordBoundaries(WebVector<int>& starts, WebVector<int>& ends) const
{
}

void WebAXObject::scrollToMakeVisible() const
{
}

void WebAXObject::scrollToMakeVisibleWithSubFocus(const WebRect& subfocus) const
{
}

void WebAXObject::scrollToGlobalPoint(const WebPoint& point) const
{
}

} // namespace blink

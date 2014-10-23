/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2010 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/html/HTMLMetaElement.h"

#include "core/HTMLNames.h"
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/loader/FrameLoaderClient.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

#define DEFINE_ARRAY_FOR_MATCHING(name, source, maxMatchLength) \
const UChar* name; \
const unsigned uMaxMatchLength = maxMatchLength; \
UChar characterBuffer[uMaxMatchLength]; \
if (!source.is8Bit()) { \
    name = source.characters16(); \
} else { \
    unsigned bufferLength = std::min(uMaxMatchLength, source.length()); \
    const LChar* characters8 = source.characters8(); \
    for (unsigned i = 0; i < bufferLength; ++i) \
        characterBuffer[i] = characters8[i]; \
    name = characterBuffer; \
}

inline HTMLMetaElement::HTMLMetaElement(Document& document)
    : HTMLElement(HTMLNames::metaTag, document)
{
    ScriptWrappable::init(this);
}

DEFINE_NODE_FACTORY(HTMLMetaElement)

static bool isInvalidSeparator(UChar c)
{
    return c == ';';
}

// Though isspace() considers \t and \v to be whitespace, Win IE doesn't.
static bool isSeparator(UChar c)
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '=' || c == ',' || c == '\0';
}

void HTMLMetaElement::parseContentAttribute(const String& content, KeyValuePairCallback callback, void* data)
{
    bool error = false;

    // Tread lightly in this code -- it was specifically designed to mimic Win IE's parsing behavior.
    unsigned keyBegin, keyEnd;
    unsigned valueBegin, valueEnd;

    String buffer = content.lower();
    unsigned length = buffer.length();
    for (unsigned i = 0; i < length; /* no increment here */) {
        // skip to first non-separator, but don't skip past the end of the string
        while (isSeparator(buffer[i])) {
            if (i >= length)
                break;
            i++;
        }
        keyBegin = i;

        // skip to first separator
        while (!isSeparator(buffer[i])) {
            error |= isInvalidSeparator(buffer[i]);
            if (i >= length)
                break;
            i++;
        }
        keyEnd = i;

        // skip to first '=', but don't skip past a ',' or the end of the string
        while (buffer[i] != '=') {
            error |= isInvalidSeparator(buffer[i]);
            if (buffer[i] == ',' || i >= length)
                break;
            i++;
        }

        // skip to first non-separator, but don't skip past a ',' or the end of the string
        while (isSeparator(buffer[i])) {
            if (buffer[i] == ',' || i >= length)
                break;
            i++;
        }
        valueBegin = i;

        // skip to first separator
        while (!isSeparator(buffer[i])) {
            error |= isInvalidSeparator(buffer[i]);
            if (i >= length)
                break;
            i++;
        }
        valueEnd = i;

        ASSERT_WITH_SECURITY_IMPLICATION(i <= length);

        String keyString = buffer.substring(keyBegin, keyEnd - keyBegin);
        String valueString = buffer.substring(valueBegin, valueEnd - valueBegin);
        (this->*callback)(keyString, valueString, data);
    }
    if (error) {
        String message = "Error parsing a meta element's content: ';' is not a valid key-value pair separator. Please use ',' instead.";
        document().addConsoleMessage(ConsoleMessage::create(RenderingMessageSource, WarningMessageLevel, message));
    }
}

static inline float clampLengthValue(float value)
{
    // Limits as defined in the css-device-adapt spec.
    if (value != ViewportDescription::ValueAuto)
        return std::min(float(10000), std::max(value, float(1)));
    return value;
}

static inline float clampScaleValue(float value)
{
    // Limits as defined in the css-device-adapt spec.
    if (value != ViewportDescription::ValueAuto)
        return std::min(float(10), std::max(value, float(0.1)));
    return value;
}

float HTMLMetaElement::parsePositiveNumber(const String& keyString, const String& valueString, bool* ok)
{
    size_t parsedLength;
    float value;
    if (valueString.is8Bit())
        value = charactersToFloat(valueString.characters8(), valueString.length(), parsedLength);
    else
        value = charactersToFloat(valueString.characters16(), valueString.length(), parsedLength);
    if (!parsedLength) {
        reportViewportWarning(UnrecognizedViewportArgumentValueError, valueString, keyString);
        if (ok)
            *ok = false;
        return 0;
    }
    if (parsedLength < valueString.length())
        reportViewportWarning(TruncatedViewportArgumentValueError, valueString, keyString);
    if (ok)
        *ok = true;
    return value;
}

Length HTMLMetaElement::parseViewportValueAsLength(const String& keyString, const String& valueString)
{
    // 1) Non-negative number values are translated to px lengths.
    // 2) Negative number values are translated to auto.
    // 3) device-width and device-height are used as keywords.
    // 4) Other keywords and unknown values translate to 0.0.

    unsigned length = valueString.length();
    DEFINE_ARRAY_FOR_MATCHING(characters, valueString, 13);
    SWITCH(characters, length) {
        CASE("device-width") {
            return Length(DeviceWidth);
        }
        CASE("device-height") {
            return Length(DeviceHeight);
        }
    }

    float value = parsePositiveNumber(keyString, valueString);

    if (value < 0)
        return Length(); // auto

    return Length(clampLengthValue(value), Fixed);
}

float HTMLMetaElement::parseViewportValueAsZoom(const String& keyString, const String& valueString, bool& computedValueMatchesParsedValue)
{
    // 1) Non-negative number values are translated to <number> values.
    // 2) Negative number values are translated to auto.
    // 3) yes is translated to 1.0.
    // 4) device-width and device-height are translated to 10.0.
    // 5) no and unknown values are translated to 0.0

    computedValueMatchesParsedValue = false;
    unsigned length = valueString.length();
    DEFINE_ARRAY_FOR_MATCHING(characters, valueString, 13);
    SWITCH(characters, length) {
        CASE("yes") {
            return 1;
        }
        CASE("no") {
            return 0;
        }
        CASE("device-width") {
            return 10;
        }
        CASE("device-height") {
            return 10;
        }
    }

    float value = parsePositiveNumber(keyString, valueString);

    if (value < 0)
        return ViewportDescription::ValueAuto;

    if (value > 10.0)
        reportViewportWarning(MaximumScaleTooLargeError, String(), String());

    float clampedValue = clampScaleValue(value);
    if (clampedValue == value)
        computedValueMatchesParsedValue = true;

    return clampedValue;
}

bool HTMLMetaElement::parseViewportValueAsUserZoom(const String& keyString, const String& valueString, bool& computedValueMatchesParsedValue)
{
    // yes and no are used as keywords.
    // Numbers >= 1, numbers <= -1, device-width and device-height are mapped to yes.
    // Numbers in the range <-1, 1>, and unknown values, are mapped to no.

    computedValueMatchesParsedValue = false;
    unsigned length = valueString.length();
    DEFINE_ARRAY_FOR_MATCHING(characters, valueString, 13);
    SWITCH(characters, length) {
        CASE("yes") {
            computedValueMatchesParsedValue = true;
            return true;
        }
        CASE("no") {
            computedValueMatchesParsedValue = true;
            return false;
        }
        CASE("device-width") {
            return true;
        }
        CASE("device-height") {
            return true;
        }
    }

    float value = parsePositiveNumber(keyString, valueString);
    if (fabs(value) < 1)
        return false;

    return true;
}

float HTMLMetaElement::parseViewportValueAsDPI(const String& keyString, const String& valueString)
{
    unsigned length = valueString.length();
    DEFINE_ARRAY_FOR_MATCHING(characters, valueString, 10);
    SWITCH(characters, length) {
        CASE("device-dpi") {
            return ViewportDescription::ValueDeviceDPI;
        }
        CASE("low-dpi") {
            return ViewportDescription::ValueLowDPI;
        }
        CASE("medium-dpi") {
            return ViewportDescription::ValueMediumDPI;
        }
        CASE("high-dpi") {
            return ViewportDescription::ValueHighDPI;
        }
    }

    bool ok;
    float value = parsePositiveNumber(keyString, valueString, &ok);
    if (!ok || value < 70 || value > 400)
        return ViewportDescription::ValueAuto;

    return value;
}

void HTMLMetaElement::processViewportKeyValuePair(const String& keyString, const String& valueString, void* data)
{
    ViewportDescription* description = static_cast<ViewportDescription*>(data);

    unsigned length = keyString.length();

    DEFINE_ARRAY_FOR_MATCHING(characters, keyString, 17);
    SWITCH(characters, length) {
        CASE("width") {
            const Length& width = parseViewportValueAsLength(keyString, valueString);
            if (width.isAuto())
                return;
            description->minWidth = Length(ExtendToZoom);
            description->maxWidth = width;
            return;
        }
        CASE("height") {
            const Length& height = parseViewportValueAsLength(keyString, valueString);
            if (height.isAuto())
                return;
            description->minHeight = Length(ExtendToZoom);
            description->maxHeight = height;
            return;
        }
        CASE("initial-scale") {
            description->zoom = parseViewportValueAsZoom(keyString, valueString, description->zoomIsExplicit);
            return;
        }
        CASE("minimum-scale") {
            description->minZoom = parseViewportValueAsZoom(keyString, valueString, description->minZoomIsExplicit);
            return;
        }
        CASE("maximum-scale") {
            description->maxZoom = parseViewportValueAsZoom(keyString, valueString, description->maxZoomIsExplicit);
            return;
        }
        CASE("user-scalable") {
            description->userZoom = parseViewportValueAsUserZoom(keyString, valueString, description->userZoomIsExplicit);
            return;
        }
        CASE("target-densitydpi") {
            description->deprecatedTargetDensityDPI = parseViewportValueAsDPI(keyString, valueString);
            reportViewportWarning(TargetDensityDpiUnsupported, String(), String());
            return;
        }
        CASE("minimal-ui") {
            // Ignore vendor-specific argument.
            return;
        }
    }
    reportViewportWarning(UnrecognizedViewportArgumentKeyError, keyString, String());
}

static const char* viewportErrorMessageTemplate(ViewportErrorCode errorCode)
{
    static const char* const errors[] = {
        "The key \"%replacement1\" is not recognized and ignored.",
        "The value \"%replacement1\" for key \"%replacement2\" is invalid, and has been ignored.",
        "The value \"%replacement1\" for key \"%replacement2\" was truncated to its numeric prefix.",
        "The value for key \"maximum-scale\" is out of bounds and the value has been clamped.",
        "The key \"target-densitydpi\" is not supported.",
    };

    return errors[errorCode];
}

static MessageLevel viewportErrorMessageLevel(ViewportErrorCode errorCode)
{
    switch (errorCode) {
    case TruncatedViewportArgumentValueError:
    case TargetDensityDpiUnsupported:
    case UnrecognizedViewportArgumentKeyError:
    case UnrecognizedViewportArgumentValueError:
    case MaximumScaleTooLargeError:
        return WarningMessageLevel;
    }

    ASSERT_NOT_REACHED();
    return ErrorMessageLevel;
}

void HTMLMetaElement::reportViewportWarning(ViewportErrorCode errorCode, const String& replacement1, const String& replacement2)
{
    if (!document().frame())
        return;

    String message = viewportErrorMessageTemplate(errorCode);
    if (!replacement1.isNull())
        message.replace("%replacement1", replacement1);
    if (!replacement2.isNull())
        message.replace("%replacement2", replacement2);

    // FIXME: This message should be moved off the console once a solution to https://bugs.webkit.org/show_bug.cgi?id=103274 exists.
    document().addConsoleMessage(ConsoleMessage::create(RenderingMessageSource, viewportErrorMessageLevel(errorCode), message));
}

void HTMLMetaElement::processViewportContentAttribute(const String& content, ViewportDescription::Type origin)
{
    ASSERT(!content.isNull());

    if (!document().shouldOverrideLegacyDescription(origin))
        return;

    ViewportDescription descriptionFromLegacyTag(origin);

    parseContentAttribute(content, &HTMLMetaElement::processViewportKeyValuePair, (void*)&descriptionFromLegacyTag);

    if (descriptionFromLegacyTag.minZoom == ViewportDescription::ValueAuto)
        descriptionFromLegacyTag.minZoom = 0.25;

    if (descriptionFromLegacyTag.maxZoom == ViewportDescription::ValueAuto) {
        descriptionFromLegacyTag.maxZoom = 5;
        descriptionFromLegacyTag.minZoom = std::min(descriptionFromLegacyTag.minZoom, float(5));
    }

    document().setViewportDescription(descriptionFromLegacyTag);
}


void HTMLMetaElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::http_equivAttr || name == HTMLNames::contentAttr) {
        process();
        return;
    }

    if (name != HTMLNames::nameAttr)
        HTMLElement::parseAttribute(name, value);
}

Node::InsertionNotificationRequest HTMLMetaElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    return InsertionShouldCallDidNotifySubtreeInsertions;
}

void HTMLMetaElement::didNotifySubtreeInsertionsToDocument()
{
    process();
}

void HTMLMetaElement::process()
{
    if (!inDocument())
        return;

    // All below situations require a content attribute (which can be the empty string).
    const AtomicString& contentValue = getAttribute(HTMLNames::contentAttr);
    if (contentValue.isNull())
        return;

    const AtomicString& nameValue = getAttribute(HTMLNames::nameAttr);
    if (!nameValue.isEmpty()) {
        if (equalIgnoringCase(nameValue, "viewport"))
            processViewportContentAttribute(contentValue, ViewportDescription::ViewportMeta);
        else if (equalIgnoringCase(nameValue, "referrer"))
            document().processReferrerPolicy(contentValue);
        else if (equalIgnoringCase(nameValue, "handheldfriendly") && equalIgnoringCase(contentValue, "true"))
            processViewportContentAttribute("width=device-width", ViewportDescription::HandheldFriendlyMeta);
        else if (equalIgnoringCase(nameValue, "mobileoptimized"))
            processViewportContentAttribute("width=device-width, initial-scale=1", ViewportDescription::MobileOptimizedMeta);
    }

    // Get the document to process the tag, but only if we're actually part of DOM
    // tree (changing a meta tag while it's not in the tree shouldn't have any effect
    // on the document).

    const AtomicString& httpEquivValue = getAttribute(HTMLNames::http_equivAttr);
    if (!httpEquivValue.isEmpty())
        document().processHttpEquiv(httpEquivValue, contentValue, false);
}

const AtomicString& HTMLMetaElement::content() const
{
    return getAttribute(HTMLNames::contentAttr);
}

const AtomicString& HTMLMetaElement::httpEquiv() const
{
    return getAttribute(HTMLNames::http_equivAttr);
}

const AtomicString& HTMLMetaElement::name() const
{
    return getAttribute(HTMLNames::nameAttr);
}

}

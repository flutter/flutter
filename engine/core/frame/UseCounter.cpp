
/*
 * Copyright (C) 2012 Google, Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/frame/UseCounter.h"

#include "core/css/CSSStyleSheet.h"
#include "core/css/StyleSheetContents.h"
#include "core/dom/Document.h"
#include "core/dom/ExecutionContext.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/FrameHost.h"
#include "core/frame/LocalFrame.h"
#include "core/inspector/ConsoleMessage.h"
#include "public/platform/Platform.h"

namespace blink {

int UseCounter::m_muteCount = 0;

void UseCounter::muteForInspector()
{
    UseCounter::m_muteCount++;
}

void UseCounter::unmuteForInspector()
{
    UseCounter::m_muteCount--;
}

UseCounter::UseCounter()
{
    m_CSSFeatureBits.ensureSize(lastCSSProperty + 1);
    m_CSSFeatureBits.clearAll();
}

UseCounter::~UseCounter()
{
    // We always log PageDestruction so that we have a scale for the rest of the features.
    blink::Platform::current()->histogramEnumeration("WebCore.FeatureObserver", PageDestruction, NumberOfFeatures);

    updateMeasurements();
}

void UseCounter::updateMeasurements()
{
    blink::Platform::current()->histogramEnumeration("WebCore.FeatureObserver", PageVisits, NumberOfFeatures);

    if (m_countBits) {
        for (unsigned i = 0; i < NumberOfFeatures; ++i) {
            if (m_countBits->quickGet(i))
                blink::Platform::current()->histogramEnumeration("WebCore.FeatureObserver", i, NumberOfFeatures);
        }
        // Clearing count bits is timing sensitive.
        m_countBits->clearAll();
    }

    m_CSSFeatureBits.clearAll();
}

void UseCounter::didCommitLoad()
{
    updateMeasurements();
}

void UseCounter::count(const Document& document, Feature feature)
{
    FrameHost* host = document.frameHost();
    if (!host)
        return;

    ASSERT(host->useCounter().deprecationMessage(feature).isEmpty());
    host->useCounter().recordMeasurement(feature);
}

void UseCounter::count(const ExecutionContext* context, Feature feature)
{
    if (!context)
        return;
    count(*toDocument(context), feature);
}

void UseCounter::countDeprecation(ExecutionContext* context, Feature feature)
{
    if (!context)
        return;
    UseCounter::countDeprecation(*toDocument(context), feature);
}

void UseCounter::countDeprecation(const LocalDOMWindow* window, Feature feature)
{
    if (!window || !window->document())
        return;
    UseCounter::countDeprecation(*window->document(), feature);
}

void UseCounter::countDeprecation(const Document& document, Feature feature)
{
    FrameHost* host = document.frameHost();
    LocalFrame* frame = document.frame();
    if (!host || !frame)
        return;

    if (host->useCounter().recordMeasurement(feature)) {
        ASSERT(!host->useCounter().deprecationMessage(feature).isEmpty());
        frame->console().addMessage(ConsoleMessage::create(DeprecationMessageSource, WarningMessageLevel, host->useCounter().deprecationMessage(feature)));
    }
}

// FIXME: Update other UseCounter::deprecationMessage() cases to use this.
static String replacedBy(const char* oldString, const char* newString)
{
    return String::format("'%s' is deprecated. Please use '%s' instead.", oldString, newString);
}

String UseCounter::deprecationMessage(Feature feature)
{
    switch (feature) {
    // Quota
    case PrefixedStorageInfo:
        return "'window.webkitStorageInfo' is deprecated. Please use 'navigator.webkitTemporaryStorage' or 'navigator.webkitPersistentStorage' instead.";

    // Keyboard Event (DOM Level 3)
    case KeyboardEventKeyLocation:
        return replacedBy("KeyboardEvent.keyLocation", "KeyboardEvent.location");

    case ConsoleMarkTimeline:
        return "console.markTimeline is deprecated. Please use the console.timeStamp instead.";

    case FileError:
        return "FileError is deprecated. Please use the 'name' or 'message' attributes of DOMError rather than 'code'.";

    case CSSStyleSheetInsertRuleOptionalArg:
        return "Calling CSSStyleSheet.insertRule() with one argument is deprecated. Please pass the index argument as well: insertRule(x, 0).";

    case MediaErrorEncrypted:
        return "'MediaError.MEDIA_ERR_ENCRYPTED' is deprecated. This error code is never used.";

    case PrefixedIndexedDB:
        return replacedBy("webkitIndexedDB", "indexedDB");

    case PrefixedIDBCursorConstructor:
        return replacedBy("webkitIDBCursor", "IDBCursor");

    case PrefixedIDBDatabaseConstructor:
        return replacedBy("webkitIDBDatabase", "IDBDatabase");

    case PrefixedIDBFactoryConstructor:
        return replacedBy("webkitIDBFactory", "IDBFactory");

    case PrefixedIDBIndexConstructor:
        return replacedBy("webkitIDBIndex", "IDBIndex");

    case PrefixedIDBKeyRangeConstructor:
        return replacedBy("webkitIDBKeyRange", "IDBKeyRange");

    case PrefixedIDBObjectStoreConstructor:
        return replacedBy("webkitIDBObjectStore", "IDBObjectStore");

    case PrefixedIDBRequestConstructor:
        return replacedBy("webkitIDBRequest", "IDBRequest");

    case PrefixedIDBTransactionConstructor:
        return replacedBy("webkitIDBTransaction", "IDBTransaction");

    case PrefixedRequestAnimationFrame:
        return "'webkitRequestAnimationFrame' is vendor-specific. Please use the standard 'requestAnimationFrame' instead.";

    case PrefixedCancelAnimationFrame:
        return "'webkitCancelAnimationFrame' is vendor-specific. Please use the standard 'cancelAnimationFrame' instead.";

    case PrefixedCancelRequestAnimationFrame:
        return "'webkitCancelRequestAnimationFrame' is vendor-specific. Please use the standard 'cancelAnimationFrame' instead.";

    case DocumentCreateAttributeNS:
        return "'Document.createAttributeNS' is deprecated and has been removed from DOM4 (http://w3.org/tr/dom).";

    case AttributeOwnerElement:
        return "'Attr.ownerElement' is deprecated and has been removed from DOM4 (http://w3.org/tr/dom).";

    case AttrTextContent:
        return replacedBy("Attr.textContent", "value");

    case RangeDetach:
        return "'Range.detach' is now a no-op, as per DOM (http://dom.spec.whatwg.org/#dom-range-detach).";

    case HTMLHeadElementProfile:
        return "'HTMLHeadElement.profile' is deprecated. The reflected attribute has no effect.";

    case ElementSetPrefix:
        return "Setting 'Element.prefix' is deprecated, as it is read-only per DOM (http://dom.spec.whatwg.org/#element).";

    case OpenWebDatabaseInWorker:
        return "'openDatabase' in Workers is deprecated. Please switch to Indexed Database API.";

    case OpenWebDatabaseSyncInWorker:
        return "'openDatabaseSync' is deprecated. Please switch to Indexed Database API.";

    case WebSocketURL:
        return "'WebSocket.URL' is deprecated. Please use 'WebSocket.url' instead.";

    case PictureSourceSrc:
        return "<source src> with a <picture> parent is invalid and therefore ignored. Please use <source srcset> instead.";

    // Features that aren't deprecated don't have a deprecation message.
    default:
        return String();
    }
}

void UseCounter::count(CSSParserContext context, CSSPropertyID feature)
{
    ASSERT(feature >= firstCSSProperty);
    ASSERT(feature <= lastCSSProperty);
    ASSERT(!isInternalProperty(feature));

    m_CSSFeatureBits.quickSet(feature);
}

void UseCounter::count(Feature feature)
{
    ASSERT(deprecationMessage(feature).isEmpty());
    recordMeasurement(feature);
}

UseCounter* UseCounter::getFrom(const Document* document)
{
    if (document && document->frameHost())
        return &document->frameHost()->useCounter();
    return 0;
}

UseCounter* UseCounter::getFrom(const CSSStyleSheet* sheet)
{
    if (sheet)
        return getFrom(sheet->contents());
    return 0;
}

UseCounter* UseCounter::getFrom(const StyleSheetContents* sheetContents)
{
    // FIXME: We may want to handle stylesheets that have multiple owners
    //        http://crbug.com/242125
    if (sheetContents && sheetContents->hasSingleOwnerNode())
        return getFrom(sheetContents->singleOwnerDocument());
    return 0;
}

} // namespace blink

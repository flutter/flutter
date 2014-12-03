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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBFRAME_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBFRAME_H_

#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/public/platform/WebCanvas.h"
#include "sky/engine/public/platform/WebPrivateOwnPtr.h"
#include "sky/engine/public/platform/WebReferrerPolicy.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/WebURLRequest.h"
#include "sky/engine/public/web/WebCompositionUnderline.h"
#include "sky/engine/public/web/WebNode.h"
#include "sky/engine/public/web/WebURLLoaderOptions.h"


namespace v8 {
class Context;
class Function;
class Object;
class Value;
template <class T> class Handle;
template <class T> class Local;
}

namespace blink {

class Frame;
class WebData;
class WebDocument;
class WebElement;
class WebFrameClient;
class WebLayer;
class WebLocalFrame;
class WebRange;
class WebString;
class WebURL;
class WebURLLoader;
class WebURLRequest;
class WebView;
struct WebConsoleMessage;
struct WebFloatPoint;
struct WebFloatRect;
struct WebPoint;
struct WebRect;
struct WebScriptSource;
struct WebSize;
struct WebURLLoaderOptions;

template <typename T> class WebVector;

// FIXME(sky): fold WebLocalFrame into this class.
class WebFrame {
public:
    // Control of renderTreeAsText output
    enum RenderAsTextControl {
        RenderAsTextNormal = 0,
        RenderAsTextDebug = 1 << 0,
    };
    typedef unsigned RenderAsTextControls;

    // Returns the number of live WebFrame objects, used for leak checking.
    BLINK_EXPORT static int instanceCount();

    virtual bool isWebLocalFrame() const = 0;
    virtual WebLocalFrame* toWebLocalFrame() = 0;

    // This method closes and deletes the WebFrame.
    virtual void close() = 0;

    // Geometry -----------------------------------------------------------

    // NOTE: These routines do not force page layout so their results may
    // not be accurate if the page layout is out-of-date.

    // The size of the contents area.
    virtual WebSize contentsSize() const = 0;

    // Returns true if the contents (minus scrollbars) has non-zero area.
    virtual bool hasVisibleContent() const = 0;

    // Returns the visible content rect (minus scrollbars, in absolute coordinate)
    virtual WebRect visibleContentRect() const = 0;

    virtual bool hasHorizontalScrollbar() const = 0;
    virtual bool hasVerticalScrollbar() const = 0;

    // Hierarchy ----------------------------------------------------------

    // Returns the containing view.
    virtual WebView* view() const = 0;

    // Content ------------------------------------------------------------

    virtual WebDocument document() const = 0;


    // Closing -------------------------------------------------------------

    // Executes script in the context of the current page.
    virtual void executeScript(const WebScriptSource&) = 0;

    // Logs to the console associated with this frame.
    virtual void addMessageToConsole(const WebConsoleMessage&) = 0;

    // Calls window.gc() if it is defined.
    virtual void collectGarbage() = 0;

    // Executes script in the context of the current page and returns the value
    // that the script evaluated to.
    virtual v8::Handle<v8::Value> executeScriptAndReturnValue(
        const WebScriptSource&) = 0;

    // ONLY FOR TESTS: Same as above but sets a fake UserGestureIndicator before
    // execution.
    virtual v8::Handle<v8::Value> executeScriptAndReturnValueForTests(
        const WebScriptSource&);

    // Call the function with the given receiver and arguments, bypassing
    // canExecute().
    virtual v8::Handle<v8::Value> callFunctionEvenIfScriptDisabled(
        v8::Handle<v8::Function>,
        v8::Handle<v8::Value>,
        int argc,
        v8::Handle<v8::Value> argv[]) = 0;

    // Returns the V8 context for associated with the main world and this
    // frame. There can be many V8 contexts associated with this frame, one for
    // each isolated world and one for the main world. If you don't know what
    // the "main world" or an "isolated world" is, then you probably shouldn't
    // be calling this API.
    virtual v8::Local<v8::Context> mainWorldScriptContext() const = 0;

    // Navigation ----------------------------------------------------------

    virtual void load(const WebURL&, mojo::ScopedDataPipeConsumerHandle) = 0;

    // Sets the referrer for the given request to be the specified URL or
    // if that is null, then it sets the referrer to the referrer that the
    // frame would use for subresources.  NOTE: This method also filters
    // out invalid referrers (e.g., it is invalid to send a HTTPS URL as
    // the referrer for a HTTP request).
    virtual void setReferrerForRequest(WebURLRequest&, const WebURL&) = 0;

    // Returns the number of registered unload listeners.
    virtual unsigned unloadListenerCount() const = 0;


    // Editing -------------------------------------------------------------

    // Replaces the selection with the given text.
    virtual void replaceSelection(const WebString& text) = 0;

    virtual void insertText(const WebString& text) = 0;

    virtual void setMarkedText(const WebString& text, unsigned location, unsigned length) = 0;
    virtual void unmarkText() = 0;
    virtual bool hasMarkedText() const = 0;

    virtual WebRange markedRange() const = 0;

    // Returns the frame rectangle in window coordinate space of the given text
    // range.
    virtual bool firstRectForCharacterRange(unsigned location, unsigned length, WebRect&) const = 0;

    // Returns the index of a character in the Frame's text stream at the given
    // point. The point is in the window coordinate space. Will return
    // WTF::notFound if the point is invalid.
    virtual size_t characterIndexForPoint(const WebPoint&) const = 0;

    // Supports commands like Undo, Redo, Cut, Copy, Paste, SelectAll,
    // Unselect, etc. See EditorCommand.cpp for the full list of supported
    // commands.
    virtual bool executeCommand(const WebString&, const WebNode& = WebNode()) = 0;
    virtual bool executeCommand(const WebString&, const WebString& value, const WebNode& = WebNode()) = 0;
    virtual bool isCommandEnabled(const WebString&) const = 0;

    // Spell-checking support.
    virtual void enableContinuousSpellChecking(bool) = 0;
    virtual bool isContinuousSpellCheckingEnabled() const = 0;
    virtual void requestTextChecking(const WebElement&) = 0;
    virtual void replaceMisspelledRange(const WebString&) = 0;
    virtual void removeSpellingMarkers() = 0;

    // Selection -----------------------------------------------------------

    virtual bool hasSelection() const = 0;

    virtual WebRange selectionRange() const = 0;

    virtual WebString selectionAsText() const = 0;

    // Expands the selection to a word around the caret and returns
    // true. Does nothing and returns false if there is no caret or
    // there is ranged selection.
    virtual bool selectWordAroundCaret() = 0;

    // DEPRECATED: Use moveRangeSelection.
    virtual void selectRange(const WebPoint& base, const WebPoint& extent) = 0;

    virtual void selectRange(const WebRange&) = 0;

    // Move the current selection to the provided window point/points. If the
    // current selection is editable, the new selection will be restricted to
    // the root editable element.
    virtual void moveRangeSelection(const WebPoint& base, const WebPoint& extent) = 0;
    virtual void moveCaretSelection(const WebPoint&) = 0;

    virtual bool setEditableSelectionOffsets(int start, int end) = 0;
    virtual bool setCompositionFromExistingText(int compositionStart, int compositionEnd, const WebVector<WebCompositionUnderline>& underlines) = 0;
    virtual void extendSelectionAndDelete(int before, int after) = 0;

    virtual void setCaretVisible(bool) = 0;


    // Utility -------------------------------------------------------------

    // Returns the contents of this frame as a string.  If the text is
    // longer than maxChars, it will be clipped to that length.  WARNING:
    // This function may be slow depending on the number of characters
    // retrieved and page complexity.  For a typically sized page, expect
    // it to take on the order of milliseconds.
    //
    // If there is room, subframe text will be recursively appended. Each
    // frame will be separated by an empty line.
    virtual WebString contentAsText(size_t maxChars) const = 0;

    // Returns a text representation of the render tree.  This method is used
    // to support layout tests.
    virtual WebString renderTreeAsText(RenderAsTextControls toShow = RenderAsTextNormal) const = 0;

    // Only for testing purpose:
    // Returns true if selection.anchorNode has a marker on range from |from| with |length|.
    virtual bool selectionStartHasSpellingMarkerFor(int from, int length) const = 0;

#if BLINK_IMPLEMENTATION
    static WebFrame* fromFrame(Frame*);
#endif

protected:
    explicit WebFrame();
    virtual ~WebFrame();

private:
};

#if BLINK_IMPLEMENTATION
Frame* toCoreFrame(const WebFrame*);
#endif

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBFRAME_H_

/*
 * Copyright (C) 2009, 2012 Google Inc. All rights reserved.
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
#include "web/ContextMenuClientImpl.h"

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/CSSPropertyNames.h"
#include "core/HTMLNames.h"
#include "core/css/CSSStyleDeclaration.h"
#include "core/dom/Document.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/editing/Editor.h"
#include "core/editing/SpellChecker.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/PinchViewport.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLMediaElement.h"
#include "core/html/MediaError.h"
#include "core/page/ContextMenuController.h"
#include "core/page/EventHandler.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderWidget.h"
#include "platform/ContextMenu.h"
#include "platform/Widget.h"
#include "platform/text/TextBreakIterator.h"
#include "platform/weborigin/KURL.h"
#include "public/platform/WebPoint.h"
#include "public/platform/WebString.h"
#include "public/platform/WebURL.h"
#include "public/platform/WebURLResponse.h"
#include "public/platform/WebVector.h"
#include "public/web/WebContextMenuData.h"
#include "public/web/WebFrameClient.h"
#include "public/web/WebMenuItemInfo.h"
#include "public/web/WebSpellCheckClient.h"
#include "public/web/WebViewClient.h"
#include "web/WebLocalFrameImpl.h"
#include "web/WebViewImpl.h"
#include "wtf/text/WTFString.h"

namespace blink {

// Figure out the URL of a page or subframe. Returns |page_type| as the type,
// which indicates page or subframe, or ContextNodeType::NONE if the URL could not
// be determined for some reason.
static WebURL urlFromFrame(LocalFrame* frame)
{
    // FIXME(sky): This used to reach through the DocumentLoader but that made no sense.
    if (frame)
        return frame->document()->url();
    return WebURL();
}

// Helper function to determine whether text is a single word.
static bool isASingleWord(const String& text)
{
    TextBreakIterator* it = wordBreakIterator(text, 0, text.length());
    return it && it->next() == static_cast<int>(text.length());
}

// Helper function to get misspelled word on which context menu
// is to be invoked. This function also sets the word on which context menu
// has been invoked to be the selected word, as required. This function changes
// the selection only when there were no selected characters on OS X.
static String selectMisspelledWord(LocalFrame* selectedFrame)
{
    // First select from selectedText to check for multiple word selection.
    String misspelledWord = selectedFrame->selectedText().stripWhiteSpace();

    // If some texts were already selected, we don't change the selection.
    if (!misspelledWord.isEmpty()) {
        // Don't provide suggestions for multiple words.
        if (!isASingleWord(misspelledWord))
            return String();
        return misspelledWord;
    }

    // Selection is empty, so change the selection to the word under the cursor.
    HitTestResult hitTestResult = selectedFrame->eventHandler().
        hitTestResultAtPoint(selectedFrame->page()->contextMenuController().hitTestResult().pointInInnerNodeFrame());
    Node* innerNode = hitTestResult.innerNode();
    VisiblePosition pos(innerNode->renderer()->positionForPoint(
        hitTestResult.localPoint()));

    if (pos.isNull())
        return misspelledWord; // It is empty.

    WebLocalFrameImpl::selectWordAroundPosition(selectedFrame, pos);
    misspelledWord = selectedFrame->selectedText().stripWhiteSpace();

#if OS(MACOSX)
    // If misspelled word is still empty, then that portion should not be
    // selected. Set the selection to that position only, and do not expand.
    if (misspelledWord.isEmpty())
        selectedFrame->selection().setSelection(VisibleSelection(pos));
#else
    // On non-Mac, right-click should not make a range selection in any case.
    selectedFrame->selection().setSelection(VisibleSelection(pos));
#endif
    return misspelledWord;
}

static bool IsWhiteSpaceOrPunctuation(UChar c)
{
    return isSpaceOrNewline(c) || WTF::Unicode::isPunct(c);
}

static String selectMisspellingAsync(LocalFrame* selectedFrame, String& description, uint32_t& hash)
{
    VisibleSelection selection = selectedFrame->selection().selection();
    if (!selection.isCaretOrRange())
        return String();

    // Caret and range selections always return valid normalized ranges.
    RefPtrWillBeRawPtr<Range> selectionRange = selection.toNormalizedRange();
    DocumentMarkerVector markers = selectedFrame->document()->markers().markersInRange(selectionRange.get(), DocumentMarker::MisspellingMarkers());
    if (markers.size() != 1)
        return String();
    description = markers[0]->description();
    hash = markers[0]->hash();

    // Cloning a range fails only for invalid ranges.
    RefPtrWillBeRawPtr<Range> markerRange = selectionRange->cloneRange();
    markerRange->setStart(markerRange->startContainer(), markers[0]->startOffset());
    markerRange->setEnd(markerRange->endContainer(), markers[0]->endOffset());

    if (markerRange->text().stripWhiteSpace(&IsWhiteSpaceOrPunctuation) != selectionRange->text().stripWhiteSpace(&IsWhiteSpaceOrPunctuation))
        return String();

    return markerRange->text();
}

void ContextMenuClientImpl::showContextMenu(const ContextMenu* defaultMenu)
{
    // Displaying the context menu in this function is a big hack as we don't
    // have context, i.e. whether this is being invoked via a script or in
    // response to user input (Mouse event WM_RBUTTONDOWN,
    // Keyboard events KeyVK_APPS, Shift+F10). Check if this is being invoked
    // in response to the above input events before popping up the context menu.
    if (!m_webView->contextMenuAllowed())
        return;

    HitTestResult r = m_webView->page()->contextMenuController().hitTestResult();

    LocalFrame* selectedFrame = r.innerNodeFrame();

    WebContextMenuData data;
    IntPoint mousePoint = selectedFrame->view()->contentsToWindow(r.roundedPointInInnerNodeFrame());

    // FIXME(bokan): crbug.com/371902 - We shouldn't be making these scale
    // related coordinate transformatios in an ad hoc way.
    PinchViewport& pinchViewport = selectedFrame->host()->pinchViewport();
    mousePoint -= flooredIntSize(pinchViewport.visibleRect().location());
    data.mousePosition = mousePoint;

    // Compute edit flags.
    data.editFlags = WebContextMenuData::CanDoNone;
    Editor& editor = m_webView->focusedCoreFrame()->editor();
    if (editor.canUndo())
        data.editFlags |= WebContextMenuData::CanUndo;
    if (editor.canRedo())
        data.editFlags |= WebContextMenuData::CanRedo;
    if (editor.canCut())
        data.editFlags |= WebContextMenuData::CanCut;
    if (editor.canCopy())
        data.editFlags |= WebContextMenuData::CanCopy;
    if (editor.canPaste())
        data.editFlags |= WebContextMenuData::CanPaste;
    if (editor.canDelete())
        data.editFlags |= WebContextMenuData::CanDelete;
    data.editFlags |= WebContextMenuData::CanTranslate;

    // Links, Images, Media tags, and Image/Media-Links take preference over
    // all else.
    data.linkURL = r.absoluteLinkURL();

    if (isHTMLCanvasElement(r.innerNonSharedNode())) {
        data.mediaType = WebContextMenuData::MediaTypeCanvas;
        data.hasImageContents = true;
    } else if (!r.absoluteImageURL().isEmpty()) {
        data.srcURL = r.absoluteImageURL();
        data.mediaType = WebContextMenuData::MediaTypeImage;
        data.mediaFlags |= WebContextMenuData::MediaCanPrint;

        // An image can be null for many reasons, like being blocked, no image
        // data received from server yet.
        data.hasImageContents = r.image() && !r.image()->isNull();
    } else if (!r.absoluteMediaURL().isEmpty()) {
        data.srcURL = r.absoluteMediaURL();

        // We know that if absoluteMediaURL() is not empty, then this
        // is a media element.
        HTMLMediaElement* mediaElement = toHTMLMediaElement(r.innerNonSharedNode());
        if (isHTMLVideoElement(*mediaElement))
            data.mediaType = WebContextMenuData::MediaTypeVideo;
        else if (isHTMLAudioElement(*mediaElement))
            data.mediaType = WebContextMenuData::MediaTypeAudio;

        if (mediaElement->error())
            data.mediaFlags |= WebContextMenuData::MediaInError;
        if (mediaElement->paused())
            data.mediaFlags |= WebContextMenuData::MediaPaused;
        if (mediaElement->muted())
            data.mediaFlags |= WebContextMenuData::MediaMuted;
        if (mediaElement->loop())
            data.mediaFlags |= WebContextMenuData::MediaLoop;
        if (mediaElement->supportsSave())
            data.mediaFlags |= WebContextMenuData::MediaCanSave;
        if (mediaElement->hasAudio())
            data.mediaFlags |= WebContextMenuData::MediaHasAudio;
        // Media controls can be toggled only for video player. If we toggle
        // controls for audio then the player disappears, and there is no way to
        // return it back. Don't set this bit for fullscreen video, since
        // toggling is ignored in that case.
        if (mediaElement->hasVideo() && !mediaElement->isFullscreen())
            data.mediaFlags |= WebContextMenuData::MediaCanToggleControls;
    }

    // Send the frame and page URLs in any case.
    data.pageURL = urlFromFrame(m_webView->mainFrameImpl()->frame());
    if (selectedFrame != m_webView->mainFrameImpl()->frame()) {
        data.frameURL = urlFromFrame(selectedFrame);
    }

    if (r.isSelected())
        data.selectedText = selectedFrame->selectedText().stripWhiteSpace();

    if (r.isContentEditable()) {
        data.isEditable = true;

        // When Chrome enables asynchronous spellchecking, its spellchecker adds spelling markers to misspelled
        // words and attaches suggestions to these markers in the background. Therefore, when a user right-clicks
        // a mouse on a word, Chrome just needs to find a spelling marker on the word instead of spellchecking it.
        if (selectedFrame->settings() && selectedFrame->settings()->asynchronousSpellCheckingEnabled()) {
            String description;
            uint32_t hash = 0;
            data.misspelledWord = selectMisspellingAsync(selectedFrame, description, hash);
            data.misspellingHash = hash;
            if (description.length()) {
                Vector<String> suggestions;
                description.split('\n', suggestions);
                data.dictionarySuggestions = suggestions;
            } else if (m_webView->spellCheckClient()) {
                int misspelledOffset, misspelledLength;
                m_webView->spellCheckClient()->spellCheck(data.misspelledWord, misspelledOffset, misspelledLength, &data.dictionarySuggestions);
            }
        } else {
            SpellChecker& spellChecker = m_webView->focusedCoreFrame()->spellChecker();
            data.isSpellCheckingEnabled = spellChecker.isContinuousSpellCheckingEnabled();
            // Spellchecking might be enabled for the field, but could be disabled on the node.
            if (spellChecker.isSpellCheckingEnabledInFocusedNode()) {
                data.misspelledWord = selectMisspelledWord(selectedFrame);
                if (m_webView->spellCheckClient()) {
                    int misspelledOffset, misspelledLength;
                    m_webView->spellCheckClient()->spellCheck(
                        data.misspelledWord, misspelledOffset, misspelledLength,
                        &data.dictionarySuggestions);
                    if (!misspelledLength)
                        data.misspelledWord.reset();
                }
            }
        }
    }

    if (selectedFrame->editor().selectionHasStyle(CSSPropertyDirection, "ltr") != FalseTriState)
        data.writingDirectionLeftToRight |= WebContextMenuData::CheckableMenuItemChecked;
    if (selectedFrame->editor().selectionHasStyle(CSSPropertyDirection, "rtl") != FalseTriState)
        data.writingDirectionRightToLeft |= WebContextMenuData::CheckableMenuItemChecked;

    data.referrerPolicy = static_cast<WebReferrerPolicy>(selectedFrame->document()->referrerPolicy());

    // Filter out custom menu elements and add them into the data.
    populateCustomMenuItems(defaultMenu, &data);

    // Extract suggested filename for saving file.
    if (isHTMLAnchorElement(r.URLElement())) {
        HTMLAnchorElement* anchor = toHTMLAnchorElement(r.URLElement());
        data.suggestedFilename = anchor->getAttribute(HTMLNames::downloadAttr);
    }

    data.node = r.innerNonSharedNode();

    WebLocalFrameImpl* selectedWebFrame = WebLocalFrameImpl::fromFrame(selectedFrame);
    if (selectedWebFrame->client())
        selectedWebFrame->client()->showContextMenu(data);
}

void ContextMenuClientImpl::clearContextMenu()
{
    HitTestResult r = m_webView->page()->contextMenuController().hitTestResult();
    LocalFrame* selectedFrame = r.innerNodeFrame();
    if (!selectedFrame)
        return;

    WebLocalFrameImpl* selectedWebFrame = WebLocalFrameImpl::fromFrame(selectedFrame);
    if (selectedWebFrame->client())
        selectedWebFrame->client()->clearContextMenu();
}

static void populateSubMenuItems(const Vector<ContextMenuItem>& inputMenu, WebVector<WebMenuItemInfo>& subMenuItems)
{
    Vector<WebMenuItemInfo> subItems;
    for (size_t i = 0; i < inputMenu.size(); ++i) {
        const ContextMenuItem* inputItem = &inputMenu.at(i);
        if (inputItem->action() < ContextMenuItemBaseCustomTag || inputItem->action() > ContextMenuItemLastCustomTag)
            continue;

        WebMenuItemInfo outputItem;
        outputItem.label = inputItem->title();
        outputItem.enabled = inputItem->enabled();
        outputItem.checked = inputItem->checked();
        outputItem.action = static_cast<unsigned>(inputItem->action() - ContextMenuItemBaseCustomTag);
        switch (inputItem->type()) {
        case ActionType:
            outputItem.type = WebMenuItemInfo::Option;
            break;
        case CheckableActionType:
            outputItem.type = WebMenuItemInfo::CheckableOption;
            break;
        case SeparatorType:
            outputItem.type = WebMenuItemInfo::Separator;
            break;
        case SubmenuType:
            outputItem.type = WebMenuItemInfo::SubMenu;
            populateSubMenuItems(inputItem->subMenuItems(), outputItem.subMenuItems);
            break;
        }
        subItems.append(outputItem);
    }

    WebVector<WebMenuItemInfo> outputItems(subItems.size());
    for (size_t i = 0; i < subItems.size(); ++i)
        outputItems[i] = subItems[i];
    subMenuItems.swap(outputItems);
}

void ContextMenuClientImpl::populateCustomMenuItems(const ContextMenu* defaultMenu, WebContextMenuData* data)
{
    populateSubMenuItems(defaultMenu->items(), data->customItems);
}

} // namespace blink

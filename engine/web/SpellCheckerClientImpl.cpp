/*
 * Copyright (C) 2006, 2007 Apple, Inc.  All rights reserved.
 * Copyright (C) 2012 Google, Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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

#include "sky/engine/config.h"
#include "sky/engine/web/SpellCheckerClientImpl.h"

#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/SpellChecker.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/public/web/WebSpellCheckClient.h"
#include "sky/engine/public/web/WebTextCheckingResult.h"
#include "sky/engine/web/WebTextCheckingCompletionImpl.h"
#include "sky/engine/web/WebViewImpl.h"

namespace blink {

SpellCheckerClientImpl::SpellCheckerClientImpl(WebViewImpl* webview)
    : m_webView(webview)
    , m_spellCheckThisFieldStatus(SpellCheckAutomatic)
{
}

SpellCheckerClientImpl::~SpellCheckerClientImpl()
{
}

bool SpellCheckerClientImpl::shouldSpellcheckByDefault()
{
    // Spellcheck should be enabled for all editable areas (such as textareas,
    // contentEditable regions, designMode docs and inputs).
    const LocalFrame* frame = m_webView->focusedCoreFrame();
    if (!frame)
        return false;
    if (frame->spellChecker().isSpellCheckingEnabledInFocusedNode())
        return true;
    const Document* document = frame->document();
    if (!document)
        return false;
    const Element* element = document->focusedElement();
    // If |element| is null, we default to allowing spellchecking. This is done
    // in order to mitigate the issue when the user clicks outside the textbox,
    // as a result of which |element| becomes null, resulting in all the spell
    // check markers being deleted. Also, the LocalFrame will decide not to do
    // spellchecking if the user can't edit - so returning true here will not
    // cause any problems to the LocalFrame's behavior.
    if (!element)
        return true;
    const RenderObject* renderer = element->renderer();
    if (!renderer)
        return false;

    return true;
}

bool SpellCheckerClientImpl::isContinuousSpellCheckingEnabled()
{
    if (m_spellCheckThisFieldStatus == SpellCheckForcedOff)
        return false;
    if (m_spellCheckThisFieldStatus == SpellCheckForcedOn)
        return true;
    return shouldSpellcheckByDefault();
}

void SpellCheckerClientImpl::toggleContinuousSpellChecking()
{
    if (isContinuousSpellCheckingEnabled()) {
        m_spellCheckThisFieldStatus = SpellCheckForcedOff;
        if (Page* page = m_webView->page()) {
            LocalFrame* frame = page->mainFrame();
            frame->document()->markers().removeMarkers(DocumentMarker::MisspellingMarkers());
        }
    } else {
        m_spellCheckThisFieldStatus = SpellCheckForcedOn;
        if (LocalFrame* frame = m_webView->focusedCoreFrame()) {
            VisibleSelection frameSelection = frame->selection().selection();
            // If a selection is in an editable element spell check its content.
            if (Element* rootEditableElement = frameSelection.rootEditableElement()) {
                frame->spellChecker().didBeginEditing(rootEditableElement);
            }
        }
    }
}

bool SpellCheckerClientImpl::isGrammarCheckingEnabled()
{
    const LocalFrame* frame = m_webView->focusedCoreFrame();
    return frame && frame->settings() && (frame->settings()->asynchronousSpellCheckingEnabled() || frame->settings()->unifiedTextCheckerEnabled());
}

bool SpellCheckerClientImpl::shouldEraseMarkersAfterChangeSelection(TextCheckingType type) const
{
    const Frame* frame = m_webView->focusedCoreFrame();
    return !frame || !frame->settings() || (!frame->settings()->asynchronousSpellCheckingEnabled() && !frame->settings()->unifiedTextCheckerEnabled());
}

void SpellCheckerClientImpl::checkSpellingOfString(const String& text, int* misspellingLocation, int* misspellingLength)
{
    // SpellCheckWord will write (0, 0) into the output vars, which is what our
    // caller expects if the word is spelled correctly.
    int spellLocation = -1;
    int spellLength = 0;

    // Check to see if the provided text is spelled correctly.
    if (m_webView->spellCheckClient()) {
        m_webView->spellCheckClient()->spellCheck(text, spellLocation, spellLength, 0);
    } else {
        spellLocation = 0;
        spellLength = 0;
    }

    // Note: the Mac code checks if the pointers are null before writing to them,
    // so we do too.
    if (misspellingLocation)
        *misspellingLocation = spellLocation;
    if (misspellingLength)
        *misspellingLength = spellLength;
}

void SpellCheckerClientImpl::requestCheckingOfString(WTF::PassRefPtr<TextCheckingRequest> request)
{
    if (m_webView->spellCheckClient()) {
        const String& text = request->data().text();
        const Vector<uint32_t>& markers = request->data().markers();
        const Vector<unsigned>& markerOffsets = request->data().offsets();
        m_webView->spellCheckClient()->requestCheckingOfText(text, markers, markerOffsets, new WebTextCheckingCompletionImpl(request));
    }
}

String SpellCheckerClientImpl::getAutoCorrectSuggestionForMisspelledWord(const String& misspelledWord)
{
    if (!(isContinuousSpellCheckingEnabled() && m_webView->client()))
        return String();

    // Do not autocorrect words with capital letters in it except the
    // first letter. This will remove cases changing "IMB" to "IBM".
    for (size_t i = 1; i < misspelledWord.length(); i++) {
        if (u_isupper(static_cast<UChar32>(misspelledWord[i])))
            return String();
    }

    if (m_webView->spellCheckClient())
        return m_webView->spellCheckClient()->autoCorrectWord(WebString(misspelledWord));
    return String();
}

void SpellCheckerClientImpl::checkGrammarOfString(const String& text, WTF::Vector<GrammarDetail>& details, int* badGrammarLocation, int* badGrammarLength)
{
    if (badGrammarLocation)
        *badGrammarLocation = -1;
    if (badGrammarLength)
        *badGrammarLength = 0;

    if (!m_webView->spellCheckClient())
        return;
    WebVector<WebTextCheckingResult> webResults;
    m_webView->spellCheckClient()->checkTextOfParagraph(text, WebTextCheckingTypeGrammar, &webResults);
    if (!webResults.size())
        return;

    // Convert a list of WebTextCheckingResults to a list of GrammarDetails. If
    // the converted vector of GrammarDetails has grammar errors, we set
    // badGrammarLocation and badGrammarLength to tell WebKit that the input
    // text has grammar errors.
    for (size_t i = 0; i < webResults.size(); ++i) {
        if (webResults[i].decoration == WebTextDecorationTypeGrammar) {
            GrammarDetail detail;
            detail.location = webResults[i].location;
            detail.length = webResults[i].length;
            detail.userDescription = webResults[i].replacement;
            details.append(detail);
        }
    }
    if (!details.size())
        return;
    if (badGrammarLocation)
        *badGrammarLocation = 0;
    if (badGrammarLength)
        *badGrammarLength = text.length();
}

void SpellCheckerClientImpl::updateSpellingUIWithMisspelledWord(const String& misspelledWord)
{
    if (m_webView->spellCheckClient())
        m_webView->spellCheckClient()->updateSpellingUIWithMisspelledWord(WebString(misspelledWord));
}

void SpellCheckerClientImpl::showSpellingUI(bool show)
{
    if (m_webView->spellCheckClient())
        m_webView->spellCheckClient()->showSpellingUI(show);
}

bool SpellCheckerClientImpl::spellingUIIsShowing()
{
    if (m_webView->spellCheckClient())
        return m_webView->spellCheckClient()->isShowingSpellingUI();
    return false;
}

} // namespace blink

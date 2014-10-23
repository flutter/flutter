/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebSpellCheckClient_h
#define WebSpellCheckClient_h

#include "../platform/WebString.h"
#include "../platform/WebVector.h"
#include "WebTextCheckingType.h"

namespace blink {

class WebString;
class WebTextCheckingCompletion;
struct WebTextCheckingResult;

class WebSpellCheckClient {
public:
    // The client should perform spell-checking on the given text. If the
    // text contains a misspelled word, then upon return misspelledOffset
    // will point to the start of the misspelled word, and misspelledLength
    // will indicates its length. Otherwise, if there was not a spelling
    // error, then upon return misspelledLength is 0. If optional_suggestions
    // is given, then it will be filled with suggested words (not a cheap step).
    virtual void spellCheck(const WebString& text,
                            int& misspelledOffset,
                            int& misspelledLength,
                            WebVector<WebString>* optionalSuggestions) { }

    // The client should perform spell-checking on the given text. This function will
    // enumerate all misspellings at once.
    virtual void checkTextOfParagraph(const WebString&,
                                      WebTextCheckingTypeMask mask,
                                      WebVector<WebTextCheckingResult>* results) { }

    // Requests asynchronous spelling and grammar checking, whose result should be
    // returned by passed completion object.
    virtual void requestCheckingOfText(const WebString& textToCheck,
                                       const WebVector<uint32_t>& markersInText,
                                       const WebVector<unsigned>& markerOffsets,
                                       WebTextCheckingCompletion* completionCallback) { }

    // Computes an auto-corrected replacement for a misspelled word. If no
    // replacement is found, then an empty string is returned.
    virtual WebString autoCorrectWord(const WebString& misspelledWord) { return WebString(); }

    // Show or hide the spelling UI.
    virtual void showSpellingUI(bool show) { }

    // Returns true if the spelling UI is showing.
    virtual bool isShowingSpellingUI() { return false; }

    // Update the spelling UI with the given word.
    virtual void updateSpellingUIWithMisspelledWord(const WebString& word) { }

protected:
    ~WebSpellCheckClient() { }
};

} // namespace blink

#endif

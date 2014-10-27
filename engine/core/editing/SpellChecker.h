/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef SpellChecker_h
#define SpellChecker_h

#include "core/dom/DocumentMarker.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/VisibleSelection.h"
#include "platform/text/TextChecking.h"

namespace blink {

class LocalFrame;
class SpellCheckerClient;
class SpellCheckRequest;
class SpellCheckRequester;
class TextCheckerClient;
class TextCheckingParagraph;
struct TextCheckingResult;

class SpellChecker {
    WTF_MAKE_NONCOPYABLE(SpellChecker);
public:
    static PassOwnPtr<SpellChecker> create(LocalFrame&);

    ~SpellChecker();

    SpellCheckerClient& spellCheckerClient() const;
    TextCheckerClient& textChecker() const;

    bool isContinuousSpellCheckingEnabled() const;
    void toggleContinuousSpellChecking();
    bool isGrammarCheckingEnabled();
    void ignoreSpelling();
    bool isSpellCheckingEnabledInFocusedNode() const;
    bool isSpellCheckingEnabledFor(Node*) const;
    void markMisspellingsAfterLineBreak(const VisibleSelection& wordSelection);
    void markMisspellingsAfterTypingToWord(const VisiblePosition &wordStart, const VisibleSelection& selectionAfterTyping);
    void markMisspellings(const VisibleSelection&, RefPtr<Range>& firstMisspellingRange);
    void markBadGrammar(const VisibleSelection&);
    void markMisspellingsAndBadGrammar(const VisibleSelection& spellingSelection, bool markGrammar, const VisibleSelection& grammarSelection);
    void markAndReplaceFor(PassRefPtr<SpellCheckRequest>, const Vector<TextCheckingResult>&);
    void markAllMisspellingsAndBadGrammarInRanges(TextCheckingTypeMask, Range* spellingRange, Range* grammarRange);
    void advanceToNextMisspelling(bool startBeforeSelection = false);
    void showSpellingGuessPanel();
    void didBeginEditing(Element*);
    void clearMisspellingsAndBadGrammar(const VisibleSelection&);
    void markMisspellingsAndBadGrammar(const VisibleSelection&);
    void respondToChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions);
    void replaceMisspelledRange(const String&);
    void removeSpellingMarkers();
    void removeSpellingMarkersUnderWords(const Vector<String>& words);
    void spellCheckAfterBlur();
    void spellCheckOldSelection(const VisibleSelection& oldSelection, const VisibleSelection& newAdjacentWords);

    bool selectionStartHasMarkerFor(DocumentMarker::MarkerType, int from, int length) const;
    bool selectionStartHasSpellingMarkerFor(int from, int length) const;
    void updateMarkersForWordsAffectedByEditing(bool onlyHandleWordsContainingSelection);
    void cancelCheck();
    void chunkAndMarkAllMisspellingsAndBadGrammar(Node*);
    void requestTextChecking(const Element&);

    // Exposed for testing only
    SpellCheckRequester& spellCheckRequester() const { return *m_spellCheckRequester; }

private:
    LocalFrame& m_frame;
    const OwnPtr<SpellCheckRequester> m_spellCheckRequester;

    explicit SpellChecker(LocalFrame&);

    void markMisspellingsOrBadGrammar(const VisibleSelection&, bool checkSpelling, RefPtr<Range>& firstMisspellingRange);
    TextCheckingTypeMask resolveTextCheckingTypeMask(TextCheckingTypeMask);

    bool unifiedTextCheckerEnabled() const;

    void chunkAndMarkAllMisspellingsAndBadGrammar(TextCheckingTypeMask textCheckingOptions, const TextCheckingParagraph& fullParagraphToCheck, bool asynchronous);
    void markAllMisspellingsAndBadGrammarInRanges(TextCheckingTypeMask textCheckingOptions, Range* checkingRange, Range* paragraphRange, bool asynchronous, int requestNumber, int* checkingLength = 0);
};

} // namespace blink

#endif // SpellChecker_h

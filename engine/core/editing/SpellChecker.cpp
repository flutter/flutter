/*
 * Copyright (C) 2006, 2007, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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
#include "sky/engine/core/editing/SpellChecker.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentMarkerController.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/SpellCheckRequester.h"
#include "sky/engine/core/editing/TextCheckingHelper.h"
#include "sky/engine/core/editing/VisibleUnits.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/loader/EmptyClients.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/page/SpellCheckerClient.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/platform/text/TextCheckerClient.h"

namespace blink {

namespace {

bool isSelectionInTextField(const VisibleSelection& selection)
{
    return false;
}

bool isSelectionInTextArea(const VisibleSelection& selection)
{
    return false;
}

} // namespace

PassOwnPtr<SpellChecker> SpellChecker::create(LocalFrame& frame)
{
    return adoptPtr(new SpellChecker(frame));
}

static SpellCheckerClient& emptySpellCheckerClient()
{
    DEFINE_STATIC_LOCAL(EmptySpellCheckerClient, client, ());
    return client;
}

SpellCheckerClient& SpellChecker::spellCheckerClient() const
{
    if (Page* page = m_frame.page())
        return page->spellCheckerClient();
    return emptySpellCheckerClient();
}

TextCheckerClient& SpellChecker::textChecker() const
{
    return spellCheckerClient().textChecker();
}

SpellChecker::SpellChecker(LocalFrame& frame)
    : m_frame(frame)
    , m_spellCheckRequester(adoptPtr(new SpellCheckRequester(frame)))
{
}

SpellChecker::~SpellChecker()
{
}

bool SpellChecker::isContinuousSpellCheckingEnabled() const
{
    return spellCheckerClient().isContinuousSpellCheckingEnabled();
}

void SpellChecker::toggleContinuousSpellChecking()
{
    spellCheckerClient().toggleContinuousSpellChecking();
    if (isContinuousSpellCheckingEnabled())
        return;
    LocalFrame* frame = m_frame.page()->mainFrame();
    for (Node* node = &frame->document()->rootNode(); node; node = NodeTraversal::next(*node)) {
        node->setAlreadySpellChecked(false);
    }
}

bool SpellChecker::isGrammarCheckingEnabled()
{
    return spellCheckerClient().isGrammarCheckingEnabled();
}

void SpellChecker::didBeginEditing(Element* element)
{
    if (isContinuousSpellCheckingEnabled() && unifiedTextCheckerEnabled()) {
        if (!element->isAlreadySpellChecked()) {
            // We always recheck textfields because markers are removed from them on blur.
            VisibleSelection selection = VisibleSelection::selectionFromContentsOfNode(element);
            markMisspellingsAndBadGrammar(selection);
            element->setAlreadySpellChecked(true);
        }
    }
}

void SpellChecker::ignoreSpelling()
{
    if (RefPtr<Range> selectedRange = m_frame.selection().toNormalizedRange())
        m_frame.document()->markers().removeMarkers(selectedRange.get(), DocumentMarker::Spelling);
}

void SpellChecker::advanceToNextMisspelling(bool startBeforeSelection)
{
    // The basic approach is to search in two phases - from the selection end to the end of the doc, and
    // then we wrap and search from the doc start to (approximately) where we started.

    // Start at the end of the selection, search to edge of document. Starting at the selection end makes
    // repeated "check spelling" commands work.
    VisibleSelection selection(m_frame.selection().selection());
    RefPtr<Range> spellingSearchRange(rangeOfContents(m_frame.document()));

    bool startedWithSelection = false;
    if (selection.start().deprecatedNode()) {
        startedWithSelection = true;
        if (startBeforeSelection) {
            VisiblePosition start(selection.visibleStart());
            // We match AppKit's rule: Start 1 character before the selection.
            VisiblePosition oneBeforeStart = start.previous();
            setStart(spellingSearchRange.get(), oneBeforeStart.isNotNull() ? oneBeforeStart : start);
        } else {
            setStart(spellingSearchRange.get(), selection.visibleEnd());
        }
    }

    Position position = spellingSearchRange->startPosition();
    if (!isEditablePosition(position)) {
        // This shouldn't happen in very often because the Spelling menu items aren't enabled unless the
        // selection is editable.
        // This can happen in Mail for a mix of non-editable and editable content (like Stationary),
        // when spell checking the whole document before sending the message.
        // In that case the document might not be editable, but there are editable pockets that need to be spell checked.

        position = firstEditableVisiblePositionAfterPositionInRoot(position, m_frame.document()).deepEquivalent();
        if (position.isNull())
            return;

        Position rangeCompliantPosition = position.parentAnchoredEquivalent();
        spellingSearchRange->setStart(rangeCompliantPosition.deprecatedNode(), rangeCompliantPosition.deprecatedEditingOffset(), IGNORE_EXCEPTION);
        startedWithSelection = false; // won't need to wrap
    }

    // topNode defines the whole range we want to operate on
    ContainerNode* topNode = highestEditableRoot(position);
    // FIXME: lastOffsetForEditing() is wrong here if editingIgnoresContent(highestEditableRoot()) returns true (e.g. a <table>)
    spellingSearchRange->setEnd(topNode, lastOffsetForEditing(topNode), IGNORE_EXCEPTION);

    // If spellingSearchRange starts in the middle of a word, advance to the next word so we start checking
    // at a word boundary. Going back by one char and then forward by a word does the trick.
    if (startedWithSelection) {
        VisiblePosition oneBeforeStart = startVisiblePosition(spellingSearchRange.get(), DOWNSTREAM).previous();
        if (oneBeforeStart.isNotNull())
            setStart(spellingSearchRange.get(), endOfWord(oneBeforeStart));
        // else we were already at the start of the editable node
    }

    if (spellingSearchRange->collapsed())
        return; // nothing to search in

    // We go to the end of our first range instead of the start of it, just to be sure
    // we don't get foiled by any word boundary problems at the start. It means we might
    // do a tiny bit more searching.
    Node* searchEndNodeAfterWrap = spellingSearchRange->endContainer();
    int searchEndOffsetAfterWrap = spellingSearchRange->endOffset();

    int misspellingOffset = 0;
    GrammarDetail grammarDetail;
    int grammarPhraseOffset = 0;
    RefPtr<Range> grammarSearchRange = nullptr;
    String badGrammarPhrase;
    String misspelledWord;

    bool isSpelling = true;
    int foundOffset = 0;
    String foundItem;
    RefPtr<Range> firstMisspellingRange = nullptr;
    if (unifiedTextCheckerEnabled()) {
        grammarSearchRange = spellingSearchRange->cloneRange();
        foundItem = TextCheckingHelper(spellCheckerClient(), spellingSearchRange).findFirstMisspellingOrBadGrammar(isGrammarCheckingEnabled(), isSpelling, foundOffset, grammarDetail);
        if (isSpelling) {
            misspelledWord = foundItem;
            misspellingOffset = foundOffset;
        } else {
            badGrammarPhrase = foundItem;
            grammarPhraseOffset = foundOffset;
        }
    } else {
        misspelledWord = TextCheckingHelper(spellCheckerClient(), spellingSearchRange).findFirstMisspelling(misspellingOffset, false, firstMisspellingRange);
        grammarSearchRange = spellingSearchRange->cloneRange();
        if (!misspelledWord.isEmpty()) {
            // Stop looking at start of next misspelled word
            CharacterIterator chars(grammarSearchRange.get());
            chars.advance(misspellingOffset);
            grammarSearchRange->setEnd(chars.range()->startContainer(), chars.range()->startOffset(), IGNORE_EXCEPTION);
        }

        if (isGrammarCheckingEnabled())
            badGrammarPhrase = TextCheckingHelper(spellCheckerClient(), grammarSearchRange).findFirstBadGrammar(grammarDetail, grammarPhraseOffset, false);
    }

    // If we found neither bad grammar nor a misspelled word, wrap and try again (but don't bother if we started at the beginning of the
    // block rather than at a selection).
    if (startedWithSelection && !misspelledWord && !badGrammarPhrase) {
        spellingSearchRange->setStart(topNode, 0, IGNORE_EXCEPTION);
        // going until the end of the very first chunk we tested is far enough
        spellingSearchRange->setEnd(searchEndNodeAfterWrap, searchEndOffsetAfterWrap, IGNORE_EXCEPTION);

        if (unifiedTextCheckerEnabled()) {
            grammarSearchRange = spellingSearchRange->cloneRange();
            foundItem = TextCheckingHelper(spellCheckerClient(), spellingSearchRange).findFirstMisspellingOrBadGrammar(isGrammarCheckingEnabled(), isSpelling, foundOffset, grammarDetail);
            if (isSpelling) {
                misspelledWord = foundItem;
                misspellingOffset = foundOffset;
            } else {
                badGrammarPhrase = foundItem;
                grammarPhraseOffset = foundOffset;
            }
        } else {
            misspelledWord = TextCheckingHelper(spellCheckerClient(), spellingSearchRange).findFirstMisspelling(misspellingOffset, false, firstMisspellingRange);
            grammarSearchRange = spellingSearchRange->cloneRange();
            if (!misspelledWord.isEmpty()) {
                // Stop looking at start of next misspelled word
                CharacterIterator chars(grammarSearchRange.get());
                chars.advance(misspellingOffset);
                grammarSearchRange->setEnd(chars.range()->startContainer(), chars.range()->startOffset(), IGNORE_EXCEPTION);
            }

            if (isGrammarCheckingEnabled())
                badGrammarPhrase = TextCheckingHelper(spellCheckerClient(), grammarSearchRange).findFirstBadGrammar(grammarDetail, grammarPhraseOffset, false);
        }
    }

    if (!badGrammarPhrase.isEmpty()) {
        // We found bad grammar. Since we only searched for bad grammar up to the first misspelled word, the bad grammar
        // takes precedence and we ignore any potential misspelled word. Select the grammar detail, update the spelling
        // panel, and store a marker so we draw the green squiggle later.

        ASSERT(badGrammarPhrase.length() > 0);
        ASSERT(grammarDetail.location != -1 && grammarDetail.length > 0);

        // FIXME 4859190: This gets confused with doubled punctuation at the end of a paragraph
        RefPtr<Range> badGrammarRange = TextIterator::subrange(grammarSearchRange.get(), grammarPhraseOffset + grammarDetail.location, grammarDetail.length);
        m_frame.selection().setSelection(VisibleSelection(badGrammarRange.get(), SEL_DEFAULT_AFFINITY));
        m_frame.selection().revealSelection();

        m_frame.document()->markers().addMarker(badGrammarRange.get(), DocumentMarker::Grammar, grammarDetail.userDescription);
    } else if (!misspelledWord.isEmpty()) {
        // We found a misspelling, but not any earlier bad grammar. Select the misspelling, update the spelling panel, and store
        // a marker so we draw the red squiggle later.

        RefPtr<Range> misspellingRange = TextIterator::subrange(spellingSearchRange.get(), misspellingOffset, misspelledWord.length());
        m_frame.selection().setSelection(VisibleSelection(misspellingRange.get(), DOWNSTREAM));
        m_frame.selection().revealSelection();

        spellCheckerClient().updateSpellingUIWithMisspelledWord(misspelledWord);
        m_frame.document()->markers().addMarker(misspellingRange.get(), DocumentMarker::Spelling);
    }
}

void SpellChecker::showSpellingGuessPanel()
{
    if (spellCheckerClient().spellingUIIsShowing()) {
        spellCheckerClient().showSpellingUI(false);
        return;
    }

    advanceToNextMisspelling(true);
    spellCheckerClient().showSpellingUI(true);
}

void SpellChecker::clearMisspellingsAndBadGrammar(const VisibleSelection &movingSelection)
{
    RefPtr<Range> selectedRange = movingSelection.toNormalizedRange();
    if (selectedRange)
        m_frame.document()->markers().removeMarkers(selectedRange.get(), DocumentMarker::MisspellingMarkers());
}

void SpellChecker::markMisspellingsAndBadGrammar(const VisibleSelection &movingSelection)
{
    markMisspellingsAndBadGrammar(movingSelection, isContinuousSpellCheckingEnabled() && isGrammarCheckingEnabled(), movingSelection);
}

void SpellChecker::markMisspellingsAfterLineBreak(const VisibleSelection& wordSelection)
{
    if (unifiedTextCheckerEnabled()) {
        TextCheckingTypeMask textCheckingOptions = 0;

        if (isContinuousSpellCheckingEnabled())
            textCheckingOptions |= TextCheckingTypeSpelling;

        if (isGrammarCheckingEnabled())
            textCheckingOptions |= TextCheckingTypeGrammar;

        VisibleSelection wholeParagraph(
            startOfParagraph(wordSelection.visibleStart()),
            endOfParagraph(wordSelection.visibleEnd()));

        markAllMisspellingsAndBadGrammarInRanges(
            textCheckingOptions, wordSelection.toNormalizedRange().get(),
            wholeParagraph.toNormalizedRange().get());
    } else {
        RefPtr<Range> misspellingRange = wordSelection.firstRange();
        markMisspellings(wordSelection, misspellingRange);
    }
}

void SpellChecker::markMisspellingsAfterTypingToWord(const VisiblePosition &wordStart, const VisibleSelection& selectionAfterTyping)
{
    if (unifiedTextCheckerEnabled()) {
        TextCheckingTypeMask textCheckingOptions = 0;

        if (isContinuousSpellCheckingEnabled())
            textCheckingOptions |= TextCheckingTypeSpelling;

        if (!(textCheckingOptions & TextCheckingTypeSpelling))
            return;

        if (isGrammarCheckingEnabled())
            textCheckingOptions |= TextCheckingTypeGrammar;

        VisibleSelection adjacentWords = VisibleSelection(startOfWord(wordStart, LeftWordIfOnBoundary), endOfWord(wordStart, RightWordIfOnBoundary));
        if (textCheckingOptions & TextCheckingTypeGrammar) {
            VisibleSelection selectedSentence = VisibleSelection(startOfSentence(wordStart), endOfSentence(wordStart));
            markAllMisspellingsAndBadGrammarInRanges(textCheckingOptions, adjacentWords.toNormalizedRange().get(), selectedSentence.toNormalizedRange().get());
        } else {
            markAllMisspellingsAndBadGrammarInRanges(textCheckingOptions, adjacentWords.toNormalizedRange().get(), adjacentWords.toNormalizedRange().get());
        }
        return;
    }

    if (!isContinuousSpellCheckingEnabled())
        return;

    // Check spelling of one word
    RefPtr<Range> misspellingRange = nullptr;
    markMisspellings(VisibleSelection(startOfWord(wordStart, LeftWordIfOnBoundary), endOfWord(wordStart, RightWordIfOnBoundary)), misspellingRange);

    // Autocorrect the misspelled word.
    if (!misspellingRange)
        return;

    // Get the misspelled word.
    const String misspelledWord = plainText(misspellingRange.get());
    String autocorrectedString = textChecker().getAutoCorrectSuggestionForMisspelledWord(misspelledWord);

    // If autocorrected word is non empty, replace the misspelled word by this word.
    if (!autocorrectedString.isEmpty()) {
        VisibleSelection newSelection(misspellingRange.get(), DOWNSTREAM);
        if (newSelection != m_frame.selection().selection()) {
            m_frame.selection().setSelection(newSelection);
        }

        m_frame.editor().replaceSelectionWithText(autocorrectedString, false, false);

        // Reset the charet one character further.
        m_frame.selection().moveTo(m_frame.selection().selection().visibleEnd());
        m_frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, CharacterGranularity);
    }

    if (!isGrammarCheckingEnabled())
        return;

    // Check grammar of entire sentence
    markBadGrammar(VisibleSelection(startOfSentence(wordStart), endOfSentence(wordStart)));
}

void SpellChecker::markMisspellingsOrBadGrammar(const VisibleSelection& selection, bool checkSpelling, RefPtr<Range>& firstMisspellingRange)
{
    // This function is called with a selection already expanded to word boundaries.
    // Might be nice to assert that here.

    // This function is used only for as-you-type checking, so if that's off we do nothing. Note that
    // grammar checking can only be on if spell checking is also on.
    if (!isContinuousSpellCheckingEnabled())
        return;

    RefPtr<Range> searchRange(selection.toNormalizedRange());
    if (!searchRange)
        return;

    // If we're not in an editable node, bail.
    Node* editableNode = searchRange->startContainer();
    if (!editableNode || !editableNode->hasEditableStyle())
        return;

    if (!isSpellCheckingEnabledFor(editableNode))
        return;

    TextCheckingHelper checker(spellCheckerClient(), searchRange);
    if (checkSpelling)
        checker.markAllMisspellings(firstMisspellingRange);
    else if (isGrammarCheckingEnabled())
        checker.markAllBadGrammar();
}

bool SpellChecker::isSpellCheckingEnabledFor(Node* node) const
{
    if (!node)
        return false;
    const Element* focusedElement = node->isElementNode() ? toElement(node) : node->parentElement();
    if (!focusedElement)
        return false;
    return focusedElement->isSpellCheckingEnabled();
}

bool SpellChecker::isSpellCheckingEnabledInFocusedNode() const
{
    return isSpellCheckingEnabledFor(m_frame.selection().start().deprecatedNode());
}

void SpellChecker::markMisspellings(const VisibleSelection& selection, RefPtr<Range>& firstMisspellingRange)
{
    markMisspellingsOrBadGrammar(selection, true, firstMisspellingRange);
}

void SpellChecker::markBadGrammar(const VisibleSelection& selection)
{
    RefPtr<Range> firstMisspellingRange = nullptr;
    markMisspellingsOrBadGrammar(selection, false, firstMisspellingRange);
}

void SpellChecker::markAllMisspellingsAndBadGrammarInRanges(TextCheckingTypeMask textCheckingOptions, Range* spellingRange, Range* grammarRange)
{
    ASSERT(unifiedTextCheckerEnabled());

    bool shouldMarkGrammar = textCheckingOptions & TextCheckingTypeGrammar;

    // This function is called with selections already expanded to word boundaries.
    if (!spellingRange || (shouldMarkGrammar && !grammarRange))
        return;

    // If we're not in an editable node, bail.
    Node* editableNode = spellingRange->startContainer();
    if (!editableNode || !editableNode->hasEditableStyle())
        return;

    if (!isSpellCheckingEnabledFor(editableNode))
        return;

    Range* rangeToCheck = shouldMarkGrammar ? grammarRange : spellingRange;
    TextCheckingParagraph fullParagraphToCheck(rangeToCheck);

    bool asynchronous = m_frame.settings() && m_frame.settings()->asynchronousSpellCheckingEnabled();
    chunkAndMarkAllMisspellingsAndBadGrammar(textCheckingOptions, fullParagraphToCheck, asynchronous);
}

void SpellChecker::chunkAndMarkAllMisspellingsAndBadGrammar(Node* node)
{
    if (!node)
        return;
    RefPtr<Range> rangeToCheck = Range::create(*m_frame.document(), firstPositionInNode(node), lastPositionInNode(node));
    TextCheckingParagraph textToCheck(rangeToCheck, rangeToCheck);
    bool asynchronous = true;
    chunkAndMarkAllMisspellingsAndBadGrammar(resolveTextCheckingTypeMask(TextCheckingTypeSpelling | TextCheckingTypeGrammar), textToCheck, asynchronous);
}

void SpellChecker::chunkAndMarkAllMisspellingsAndBadGrammar(TextCheckingTypeMask textCheckingOptions, const TextCheckingParagraph& fullParagraphToCheck, bool asynchronous)
{
    if (fullParagraphToCheck.isRangeEmpty() || fullParagraphToCheck.isEmpty())
        return;

    // Since the text may be quite big chunk it up and adjust to the sentence boundary.
    const int kChunkSize = 16 * 1024;
    int start = fullParagraphToCheck.checkingStart();
    int end = fullParagraphToCheck.checkingEnd();
    start = std::min(start, end);
    end = std::max(start, end);
    const int kNumChunksToCheck = asynchronous ? (end - start + kChunkSize - 1) / (kChunkSize) : 1;
    int currentChunkStart = start;
    RefPtr<Range> checkRange = fullParagraphToCheck.checkingRange();
    if (kNumChunksToCheck == 1 && asynchronous) {
        markAllMisspellingsAndBadGrammarInRanges(textCheckingOptions, checkRange.get(), checkRange.get(), asynchronous, 0);
        return;
    }

    for (int iter = 0; iter < kNumChunksToCheck; ++iter) {
        checkRange = fullParagraphToCheck.subrange(currentChunkStart, kChunkSize);
        setStart(checkRange.get(), startOfSentence(VisiblePosition(checkRange->startPosition())));
        setEnd(checkRange.get(), endOfSentence(VisiblePosition(checkRange->endPosition())));

        int checkingLength = 0;
        markAllMisspellingsAndBadGrammarInRanges(textCheckingOptions, checkRange.get(), checkRange.get(), asynchronous, iter, &checkingLength);
        currentChunkStart += checkingLength;
    }
}

void SpellChecker::markAllMisspellingsAndBadGrammarInRanges(TextCheckingTypeMask textCheckingOptions, Range* checkRange, Range* paragraphRange, bool asynchronous, int requestNumber, int* checkingLength)
{
    TextCheckingParagraph sentenceToCheck(checkRange, paragraphRange);
    if (checkingLength)
        *checkingLength = sentenceToCheck.checkingLength();

    RefPtr<SpellCheckRequest> request = SpellCheckRequest::create(resolveTextCheckingTypeMask(textCheckingOptions), TextCheckingProcessBatch, checkRange, paragraphRange, requestNumber);

    if (asynchronous) {
        m_spellCheckRequester->requestCheckingFor(request);
    } else {
        Vector<TextCheckingResult> results;
        checkTextOfParagraph(textChecker(), sentenceToCheck.text(), resolveTextCheckingTypeMask(textCheckingOptions), results);
        markAndReplaceFor(request, results);
    }
}

void SpellChecker::markAndReplaceFor(PassRefPtr<SpellCheckRequest> request, const Vector<TextCheckingResult>& results)
{
    ASSERT(request);

    TextCheckingTypeMask textCheckingOptions = request->data().mask();
    TextCheckingParagraph paragraph(request->checkingRange(), request->paragraphRange());

    bool shouldMarkSpelling = textCheckingOptions & TextCheckingTypeSpelling;
    bool shouldMarkGrammar = textCheckingOptions & TextCheckingTypeGrammar;

    // Expand the range to encompass entire paragraphs, since text checking needs that much context.
    int selectionOffset = 0;
    int ambiguousBoundaryOffset = -1;
    bool selectionChanged = false;
    bool restoreSelectionAfterChange = false;
    bool adjustSelectionForParagraphBoundaries = false;

    if (shouldMarkSpelling) {
        if (m_frame.selection().isCaret()) {
            // Attempt to save the caret position so we can restore it later if needed
            Position caretPosition = m_frame.selection().end();
            selectionOffset = paragraph.offsetTo(caretPosition, ASSERT_NO_EXCEPTION);
            restoreSelectionAfterChange = true;
            if (selectionOffset > 0 && (static_cast<unsigned>(selectionOffset) > paragraph.text().length() || paragraph.textCharAt(selectionOffset - 1) == newlineCharacter))
                adjustSelectionForParagraphBoundaries = true;
            if (selectionOffset > 0 && static_cast<unsigned>(selectionOffset) <= paragraph.text().length() && isAmbiguousBoundaryCharacter(paragraph.textCharAt(selectionOffset - 1)))
                ambiguousBoundaryOffset = selectionOffset - 1;
        }
    }

    for (unsigned i = 0; i < results.size(); i++) {
        int spellingRangeEndOffset = paragraph.checkingEnd();
        const TextCheckingResult* result = &results[i];
        int resultLocation = result->location + paragraph.checkingStart();
        int resultLength = result->length;
        bool resultEndsAtAmbiguousBoundary = ambiguousBoundaryOffset >= 0 && resultLocation + resultLength == ambiguousBoundaryOffset;

        // Only mark misspelling if:
        // 1. Current text checking isn't done for autocorrection, in which case shouldMarkSpelling is false.
        // 2. Result falls within spellingRange.
        // 3. The word in question doesn't end at an ambiguous boundary. For instance, we would not mark
        //    "wouldn'" as misspelled right after apostrophe is typed.
        if (shouldMarkSpelling && result->decoration == TextDecorationTypeSpelling && resultLocation >= paragraph.checkingStart() && resultLocation + resultLength <= spellingRangeEndOffset && !resultEndsAtAmbiguousBoundary) {
            ASSERT(resultLength > 0 && resultLocation >= 0);
            RefPtr<Range> misspellingRange = paragraph.subrange(resultLocation, resultLength);
            misspellingRange->startContainer()->document().markers().addMarker(misspellingRange.get(), DocumentMarker::Spelling, result->replacement, result->hash);
        } else if (shouldMarkGrammar && result->decoration == TextDecorationTypeGrammar && paragraph.checkingRangeCovers(resultLocation, resultLength)) {
            ASSERT(resultLength > 0 && resultLocation >= 0);
            for (unsigned j = 0; j < result->details.size(); j++) {
                const GrammarDetail* detail = &result->details[j];
                ASSERT(detail->length > 0 && detail->location >= 0);
                if (paragraph.checkingRangeCovers(resultLocation + detail->location, detail->length)) {
                    RefPtr<Range> badGrammarRange = paragraph.subrange(resultLocation + detail->location, detail->length);
                    badGrammarRange->startContainer()->document().markers().addMarker(badGrammarRange.get(), DocumentMarker::Grammar, detail->userDescription, result->hash);
                }
            }
        } else if (result->decoration == TextDecorationTypeInvisibleSpellcheck && resultLocation >= paragraph.checkingStart() && resultLocation + resultLength <= spellingRangeEndOffset) {
            ASSERT(resultLength > 0 && resultLocation >= 0);
            RefPtr<Range> invisibleSpellcheckRange = paragraph.subrange(resultLocation, resultLength);
            invisibleSpellcheckRange->startContainer()->document().markers().addMarker(invisibleSpellcheckRange.get(), DocumentMarker::InvisibleSpellcheck, result->replacement, result->hash);
        }
    }

    if (selectionChanged) {
        TextCheckingParagraph extendedParagraph(paragraph);
        // Restore the caret position if we have made any replacements
        extendedParagraph.expandRangeToNextEnd();
        if (restoreSelectionAfterChange && selectionOffset >= 0 && selectionOffset <= extendedParagraph.rangeLength()) {
            RefPtr<Range> selectionRange = extendedParagraph.subrange(0, selectionOffset);
            m_frame.selection().moveTo(selectionRange->endPosition(), DOWNSTREAM);
            if (adjustSelectionForParagraphBoundaries)
                m_frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, CharacterGranularity);
        } else {
            // If this fails for any reason, the fallback is to go one position beyond the last replacement
            m_frame.selection().moveTo(m_frame.selection().selection().visibleEnd());
            m_frame.selection().modify(FrameSelection::AlterationMove, DirectionForward, CharacterGranularity);
        }
    }
}

void SpellChecker::markMisspellingsAndBadGrammar(const VisibleSelection& spellingSelection, bool markGrammar, const VisibleSelection& grammarSelection)
{
    if (unifiedTextCheckerEnabled()) {
        if (!isContinuousSpellCheckingEnabled())
            return;

        // markMisspellingsAndBadGrammar() is triggered by selection change, in which case we check spelling and grammar, but don't autocorrect misspellings.
        TextCheckingTypeMask textCheckingOptions = TextCheckingTypeSpelling;
        if (markGrammar && isGrammarCheckingEnabled())
            textCheckingOptions |= TextCheckingTypeGrammar;
        markAllMisspellingsAndBadGrammarInRanges(textCheckingOptions, spellingSelection.toNormalizedRange().get(), grammarSelection.toNormalizedRange().get());
        return;
    }

    RefPtr<Range> firstMisspellingRange = nullptr;
    markMisspellings(spellingSelection, firstMisspellingRange);
    if (markGrammar)
        markBadGrammar(grammarSelection);
}

void SpellChecker::updateMarkersForWordsAffectedByEditing(bool doNotRemoveIfSelectionAtWordBoundary)
{
    if (textChecker().shouldEraseMarkersAfterChangeSelection(TextCheckingTypeSpelling))
        return;

    // We want to remove the markers from a word if an editing command will change the word. This can happen in one of
    // several scenarios:
    // 1. Insert in the middle of a word.
    // 2. Appending non whitespace at the beginning of word.
    // 3. Appending non whitespace at the end of word.
    // Note that, appending only whitespaces at the beginning or end of word won't change the word, so we don't need to
    // remove the markers on that word.
    // Of course, if current selection is a range, we potentially will edit two words that fall on the boundaries of
    // selection, and remove words between the selection boundaries.
    //
    VisiblePosition startOfSelection = m_frame.selection().selection().visibleStart();
    VisiblePosition endOfSelection = m_frame.selection().selection().visibleEnd();
    if (startOfSelection.isNull())
        return;
    // First word is the word that ends after or on the start of selection.
    VisiblePosition startOfFirstWord = startOfWord(startOfSelection, LeftWordIfOnBoundary);
    VisiblePosition endOfFirstWord = endOfWord(startOfSelection, LeftWordIfOnBoundary);
    // Last word is the word that begins before or on the end of selection
    VisiblePosition startOfLastWord = startOfWord(endOfSelection, RightWordIfOnBoundary);
    VisiblePosition endOfLastWord = endOfWord(endOfSelection, RightWordIfOnBoundary);

    if (startOfFirstWord.isNull()) {
        startOfFirstWord = startOfWord(startOfSelection, RightWordIfOnBoundary);
        endOfFirstWord = endOfWord(startOfSelection, RightWordIfOnBoundary);
    }

    if (endOfLastWord.isNull()) {
        startOfLastWord = startOfWord(endOfSelection, LeftWordIfOnBoundary);
        endOfLastWord = endOfWord(endOfSelection, LeftWordIfOnBoundary);
    }

    // If doNotRemoveIfSelectionAtWordBoundary is true, and first word ends at the start of selection,
    // we choose next word as the first word.
    if (doNotRemoveIfSelectionAtWordBoundary && endOfFirstWord == startOfSelection) {
        startOfFirstWord = nextWordPosition(startOfFirstWord);
        endOfFirstWord = endOfWord(startOfFirstWord, RightWordIfOnBoundary);
        if (startOfFirstWord == endOfSelection)
            return;
    }

    // If doNotRemoveIfSelectionAtWordBoundary is true, and last word begins at the end of selection,
    // we choose previous word as the last word.
    if (doNotRemoveIfSelectionAtWordBoundary && startOfLastWord == endOfSelection) {
        startOfLastWord = previousWordPosition(startOfLastWord);
        endOfLastWord = endOfWord(startOfLastWord, RightWordIfOnBoundary);
        if (endOfLastWord == startOfSelection)
            return;
    }

    if (startOfFirstWord.isNull() || endOfFirstWord.isNull() || startOfLastWord.isNull() || endOfLastWord.isNull())
        return;

    // Now we remove markers on everything between startOfFirstWord and endOfLastWord.
    // However, if an autocorrection change a single word to multiple words, we want to remove correction mark from all the
    // resulted words even we only edit one of them. For example, assuming autocorrection changes "avantgarde" to "avant
    // garde", we will have CorrectionIndicator marker on both words and on the whitespace between them. If we then edit garde,
    // we would like to remove the marker from word "avant" and whitespace as well. So we need to get the continous range of
    // of marker that contains the word in question, and remove marker on that whole range.
    Document* document = m_frame.document();
    ASSERT(document);
    RefPtr<Range> wordRange = Range::create(*document, startOfFirstWord.deepEquivalent(), endOfLastWord.deepEquivalent());

    document->markers().removeMarkers(wordRange.get(), DocumentMarker::MisspellingMarkers(), DocumentMarkerController::RemovePartiallyOverlappingMarker);
}

void SpellChecker::replaceMisspelledRange(const String& text)
{
    RefPtr<Range> caretRange = m_frame.selection().toNormalizedRange();
    if (!caretRange)
        return;
    DocumentMarkerVector markers = m_frame.document()->markers().markersInRange(caretRange.get(), DocumentMarker::MisspellingMarkers());
    if (markers.size() < 1 || markers[0]->startOffset() >= markers[0]->endOffset())
        return;
    RefPtr<Range> markerRange = Range::create(caretRange->ownerDocument(), caretRange->startContainer(), markers[0]->startOffset(), caretRange->endContainer(), markers[0]->endOffset());
    if (!markerRange)
        return;
    m_frame.selection().setSelection(VisibleSelection(markerRange.get()), CharacterGranularity);
    m_frame.editor().replaceSelectionWithText(text, false, false);
}

void SpellChecker::respondToChangedSelection(const VisibleSelection& oldSelection, FrameSelection::SetSelectionOptions options)
{
    bool closeTyping = options & FrameSelection::CloseTyping;
    bool isContinuousSpellCheckingEnabled = this->isContinuousSpellCheckingEnabled();
    bool isContinuousGrammarCheckingEnabled = isContinuousSpellCheckingEnabled && isGrammarCheckingEnabled();
    if (isContinuousSpellCheckingEnabled) {
        VisibleSelection newAdjacentWords;
        VisibleSelection newSelectedSentence;
        const VisibleSelection newSelection = m_frame.selection().selection();
        VisiblePosition newStart(newSelection.visibleStart());
        newAdjacentWords = VisibleSelection(startOfWord(newStart, LeftWordIfOnBoundary), endOfWord(newStart, RightWordIfOnBoundary));
        if (isContinuousGrammarCheckingEnabled)
            newSelectedSentence = VisibleSelection(startOfSentence(newStart), endOfSentence(newStart));

        // Don't check spelling and grammar if the change of selection is triggered by spelling correction itself.
        bool shouldCheckSpellingAndGrammar = !(options & FrameSelection::SpellCorrectionTriggered);

        // When typing we check spelling elsewhere, so don't redo it here.
        // If this is a change in selection resulting from a delete operation,
        // oldSelection may no longer be in the document.
        // FIXME(http://crbug.com/382809): if oldSelection is on a textarea
        // element, we cause synchronous layout.
        if (shouldCheckSpellingAndGrammar
            && closeTyping
            && !isSelectionInTextField(oldSelection)
            && (isSelectionInTextArea(oldSelection) || oldSelection.isContentEditable())
            && oldSelection.start().inDocument()) {
            spellCheckOldSelection(oldSelection, newAdjacentWords);
        }

        // FIXME(http://crbug.com/382809):
        // shouldEraseMarkersAfterChangeSelection is true, we cause synchronous
        // layout.
        if (textChecker().shouldEraseMarkersAfterChangeSelection(TextCheckingTypeSpelling)) {
            if (RefPtr<Range> wordRange = newAdjacentWords.toNormalizedRange())
                m_frame.document()->markers().removeMarkers(wordRange.get(), DocumentMarker::Spelling);
        }
        if (textChecker().shouldEraseMarkersAfterChangeSelection(TextCheckingTypeGrammar)) {
            if (RefPtr<Range> sentenceRange = newSelectedSentence.toNormalizedRange())
                m_frame.document()->markers().removeMarkers(sentenceRange.get(), DocumentMarker::Grammar);
        }
    }

    // When continuous spell checking is off, existing markers disappear after the selection changes.
    if (!isContinuousSpellCheckingEnabled)
        m_frame.document()->markers().removeMarkers(DocumentMarker::Spelling);
    if (!isContinuousGrammarCheckingEnabled)
        m_frame.document()->markers().removeMarkers(DocumentMarker::Grammar);
}

void SpellChecker::removeSpellingMarkers()
{
    m_frame.document()->markers().removeMarkers(DocumentMarker::MisspellingMarkers());
}

void SpellChecker::removeSpellingMarkersUnderWords(const Vector<String>& words)
{
    MarkerRemoverPredicate removerPredicate(words);

    DocumentMarkerController& markerController = m_frame.document()->markers();
    markerController.removeMarkers(removerPredicate);
}

void SpellChecker::spellCheckAfterBlur()
{
    if (!m_frame.selection().selection().isContentEditable())
        return;

    if (isSelectionInTextField(m_frame.selection().selection())) {
        // textFieldDidEndEditing() and textFieldDidBeginEditing() handle this.
        return;
    }

    VisibleSelection empty;
    spellCheckOldSelection(m_frame.selection().selection(), empty);
}

void SpellChecker::spellCheckOldSelection(const VisibleSelection& oldSelection, const VisibleSelection& newAdjacentWords)
{
    VisiblePosition oldStart(oldSelection.visibleStart());
    VisibleSelection oldAdjacentWords = VisibleSelection(startOfWord(oldStart, LeftWordIfOnBoundary), endOfWord(oldStart, RightWordIfOnBoundary));
    if (oldAdjacentWords  != newAdjacentWords) {
        if (isContinuousSpellCheckingEnabled() && isGrammarCheckingEnabled()) {
            VisibleSelection selectedSentence = VisibleSelection(startOfSentence(oldStart), endOfSentence(oldStart));
            markMisspellingsAndBadGrammar(oldAdjacentWords, true, selectedSentence);
        } else {
            markMisspellingsAndBadGrammar(oldAdjacentWords, false, oldAdjacentWords);
        }
    }
}

static Node* findFirstMarkable(Node* node)
{
    while (node) {
        if (!node->renderer())
            return 0;
        if (node->renderer()->isText())
            return node;
        if (node->hasChildren())
            node = node->firstChild();
        else
            node = node->nextSibling();
    }

    return 0;
}

bool SpellChecker::selectionStartHasMarkerFor(DocumentMarker::MarkerType markerType, int from, int length) const
{
    Node* node = findFirstMarkable(m_frame.selection().start().deprecatedNode());
    if (!node)
        return false;

    unsigned startOffset = static_cast<unsigned>(from);
    unsigned endOffset = static_cast<unsigned>(from + length);
    DocumentMarkerVector markers = m_frame.document()->markers().markersFor(node);
    for (size_t i = 0; i < markers.size(); ++i) {
        DocumentMarker* marker = markers[i];
        if (marker->startOffset() <= startOffset && endOffset <= marker->endOffset() && marker->type() == markerType)
            return true;
    }

    return false;
}

bool SpellChecker::selectionStartHasSpellingMarkerFor(int from, int length) const
{
    return selectionStartHasMarkerFor(DocumentMarker::Spelling, from, length);
}

TextCheckingTypeMask SpellChecker::resolveTextCheckingTypeMask(TextCheckingTypeMask textCheckingOptions)
{
    bool shouldMarkSpelling = textCheckingOptions & TextCheckingTypeSpelling;
    bool shouldMarkGrammar = textCheckingOptions & TextCheckingTypeGrammar;

    TextCheckingTypeMask checkingTypes = 0;
    if (shouldMarkSpelling)
        checkingTypes |= TextCheckingTypeSpelling;
    if (shouldMarkGrammar)
        checkingTypes |= TextCheckingTypeGrammar;

    return checkingTypes;
}

bool SpellChecker::unifiedTextCheckerEnabled() const
{
    return blink::unifiedTextCheckerEnabled(&m_frame);
}

void SpellChecker::cancelCheck()
{
    m_spellCheckRequester->cancelCheck();
}

void SpellChecker::requestTextChecking(const Element& element)
{
    RefPtr<Range> rangeToCheck = rangeOfContents(const_cast<Element*>(&element));
    m_spellCheckRequester->requestCheckingFor(SpellCheckRequest::create(TextCheckingTypeSpelling | TextCheckingTypeGrammar, TextCheckingProcessBatch, rangeToCheck, rangeToCheck));
}


} // namespace blink

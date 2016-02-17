/*
 * Copyright (C) 2015 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define VERBOSE_DEBUG 0

#include <limits>
#include <unicode/utf16.h>

#define LOG_TAG "Minikin"
#include <cutils/log.h>

#include <minikin/Layout.h>
#include <minikin/LineBreaker.h>

using std::vector;

namespace android {

const int CHAR_TAB = 0x0009;
const uint16_t CHAR_SOFT_HYPHEN = 0x00AD;
const uint16_t CHAR_ZWJ = 0x200D;

// Large scores in a hierarchy; we prefer desperate breaks to an overfull line. All these
// constants are larger than any reasonable actual width score.
const float SCORE_INFTY = std::numeric_limits<float>::max();
const float SCORE_OVERFULL = 1e12f;
const float SCORE_DESPERATE = 1e10f;

// Multiplier for hyphen penalty on last line.
const float LAST_LINE_PENALTY_MULTIPLIER = 4.0f;
// Penalty assigned to each line break (to try to minimize number of lines)
// TODO: when we implement full justification (so spaces can shrink and stretch), this is
// probably not the most appropriate method.
const float LINE_PENALTY_MULTIPLIER = 2.0f;

// Very long words trigger O(n^2) behavior in hyphenation, so we disable hyphenation for
// unreasonably long words. This is somewhat of a heuristic because extremely long words
// are possible in some languages. This does mean that very long real words can get
// broken by desperate breaks, with no hyphens.
const size_t LONGEST_HYPHENATED_WORD = 45;

// When the text buffer is within this limit, capacity of vectors is retained at finish(),
// to avoid allocation.
const size_t MAX_TEXT_BUF_RETAIN = 32678;

void LineBreaker::setLocale(const icu::Locale& locale, Hyphenator* hyphenator) {
    delete mBreakIterator;
    UErrorCode status = U_ZERO_ERROR;
    mBreakIterator = icu::BreakIterator::createLineInstance(locale, status);
    // TODO: check status

    // TODO: load actual resource dependent on locale; letting Minikin do it is a hack
    mHyphenator = hyphenator;
}

void LineBreaker::setText() {
    UErrorCode status = U_ZERO_ERROR;
    utext_openUChars(&mUText, mTextBuf.data(), mTextBuf.size(), &status);
    mBreakIterator->setText(&mUText, status);
    mBreakIterator->first();

    // handle initial break here because addStyleRun may never be called
    mBreakIterator->next();
    mCandidates.clear();
    Candidate cand = {0, 0, 0.0, 0.0, 0.0, 0.0, 0, 0};
    mCandidates.push_back(cand);

    // reset greedy breaker state
    mBreaks.clear();
    mWidths.clear();
    mFlags.clear();
    mLastBreak = 0;
    mBestBreak = 0;
    mBestScore = SCORE_INFTY;
    mPreBreak = 0;
    mFirstTabIndex = INT_MAX;
}

void LineBreaker::setLineWidths(float firstWidth, int firstWidthLineCount, float restWidth) {
    mLineWidths.setWidths(firstWidth, firstWidthLineCount, restWidth);
}


void LineBreaker::setIndents(const std::vector<float>& indents) {
    mLineWidths.setIndents(indents);
}

// This function determines whether a character is a space that disappears at end of line.
// It is the Unicode set: [[:General_Category=Space_Separator:]-[:Line_Break=Glue:]],
// plus '\n'.
// Note: all such characters are in the BMP, so it's ok to use code units for this.
static bool isLineEndSpace(uint16_t c) {
    return c == '\n' || c == ' ' || c == 0x1680 || (0x2000 <= c && c <= 0x200A && c != 0x2007) ||
            c == 0x205F || c == 0x3000;
}

// This function determines whether a character is like U+2010 HYPHEN in
// line breaking and usage: a character immediately after which line breaks
// are allowed, but words containing it should not be automatically
// hyphenated. This is a curated set, created by manually inspecting all
// the characters that have the Unicode line breaking property of BA or HY
// and seeing which ones are hyphens.
static bool isLineBreakingHyphen(uint16_t c) {
    return (c == 0x002D || // HYPHEN-MINUS
            c == 0x058A || // ARMENIAN HYPHEN
            c == 0x05BE || // HEBREW PUNCTUATION MAQAF
            c == 0x1400 || // CANADIAN SYLLABICS HYPHEN
            c == 0x2010 || // HYPHEN
            c == 0x2013 || // EN DASH
            c == 0x2027 || // HYPHENATION POINT
            c == 0x2E17 || // DOUBLE OBLIQUE HYPHEN
            c == 0x2E40);  // DOUBLE HYPHEN
}

/**
 * Determine whether a line break at position i within the buffer buf is valid. This
 * represents customization beyond the ICU behavior, because plain ICU provides some
 * line break opportunities that we don't want.
 **/
static bool isBreakValid(uint16_t codeUnit, const uint16_t* buf, size_t bufEnd, size_t i) {
    if (codeUnit == CHAR_SOFT_HYPHEN) {
        return false;
    }
    if (codeUnit == CHAR_ZWJ) {
        // Possible emoji ZWJ sequence
        uint32_t next_codepoint;
        U16_NEXT(buf, i, bufEnd, next_codepoint);
        if (next_codepoint == 0x2764 ||       // HEAVY BLACK HEART
                next_codepoint == 0x1F466 ||  // BOY
                next_codepoint == 0x1F467 ||  // GIRL
                next_codepoint == 0x1F468 ||  // MAN
                next_codepoint == 0x1F469 ||  // WOMAN
                next_codepoint == 0x1F48B ||  // KISS MARK
                next_codepoint == 0x1F5E8) {  // LEFT SPEECH BUBBLE
            return false;
        }
    }
    return true;
}

// Ordinarily, this method measures the text in the range given. However, when paint
// is nullptr, it assumes the widths have already been calculated and stored in the
// width buffer.
// This method finds the candidate word breaks (using the ICU break iterator) and sends them
// to addCandidate.
float LineBreaker::addStyleRun(MinikinPaint* paint, const FontCollection* typeface,
        FontStyle style, size_t start, size_t end, bool isRtl) {
    Layout layout;  // performance TODO: move layout to self object to reduce allocation cost?
    float width = 0.0f;
    int bidiFlags = isRtl ? kBidi_Force_RTL : kBidi_Force_LTR;

    float hyphenPenalty = 0.0;
    if (paint != nullptr) {
        layout.setFontCollection(typeface);
        layout.doLayout(mTextBuf.data(), start, end - start, mTextBuf.size(), bidiFlags, style,
                *paint);
        layout.getAdvances(mCharWidths.data() + start);
        width = layout.getAdvance();

        // a heuristic that seems to perform well
        hyphenPenalty = 0.5 * paint->size * paint->scaleX * mLineWidths.getLineWidth(0);
        if (mHyphenationFrequency == kHyphenationFrequency_Normal) {
            hyphenPenalty *= 4.0; // TODO: Replace with a better value after some testing
        }

        mLinePenalty = std::max(mLinePenalty, hyphenPenalty * LINE_PENALTY_MULTIPLIER);
    }

    size_t current = (size_t)mBreakIterator->current();
    size_t wordEnd = start;
    size_t lastBreak = start;
    ParaWidth lastBreakWidth = mWidth;
    ParaWidth postBreak = mWidth;
    bool temporarilySkipHyphenation = false;
    for (size_t i = start; i < end; i++) {
        uint16_t c = mTextBuf[i];
        if (c == CHAR_TAB) {
            mWidth = mPreBreak + mTabStops.nextTab(mWidth - mPreBreak);
            if (mFirstTabIndex == INT_MAX) {
                mFirstTabIndex = (int)i;
            }
            // fall back to greedy; other modes don't know how to deal with tabs
            mStrategy = kBreakStrategy_Greedy;
        } else {
            mWidth += mCharWidths[i];
            if (!isLineEndSpace(c)) {
                postBreak = mWidth;
                wordEnd = i + 1;
            }
        }
        if (i + 1 == current) {
            // Override ICU's treatment of soft hyphen as a break opportunity, because we want it
            // to be a hyphen break, with penalty and drawing behavior. Also, suppress line
            // breaks within emoji ZWJ sequences.
            if (isBreakValid(c, mTextBuf.data(), end, i + 1)) {
                // TODO: Add a new type of HyphenEdit for breaks whose hyphen already exists, so
                // we can pass the whole word down to Hyphenator like the soft hyphen case.
                bool wordEndsInHyphen = isLineBreakingHyphen(c);
                if (paint != nullptr && mHyphenator != nullptr &&
                        mHyphenationFrequency != kHyphenationFrequency_None &&
                        !wordEndsInHyphen && !temporarilySkipHyphenation &&
                        wordEnd > lastBreak && wordEnd - lastBreak <= LONGEST_HYPHENATED_WORD) {
                    mHyphenator->hyphenate(&mHyphBuf, &mTextBuf[lastBreak], wordEnd - lastBreak);
    #if VERBOSE_DEBUG
                    std::string hyphenatedString;
                    for (size_t j = lastBreak; j < wordEnd; j++) {
                        if (mHyphBuf[j - lastBreak]) hyphenatedString.push_back('-');
                        // Note: only works with ASCII, should do UTF-8 conversion here
                        hyphenatedString.push_back(buffer()[j]);
                    }
                    ALOGD("hyphenated string: %s", hyphenatedString.c_str());
    #endif

                    // measure hyphenated substrings
                    for (size_t j = lastBreak; j < wordEnd; j++) {
                        uint8_t hyph = mHyphBuf[j - lastBreak];
                        if (hyph) {
                            paint->hyphenEdit = hyph;
                            layout.doLayout(mTextBuf.data(), lastBreak, j - lastBreak,
                                    mTextBuf.size(), bidiFlags, style, *paint);
                            ParaWidth hyphPostBreak = lastBreakWidth + layout.getAdvance();
                            paint->hyphenEdit = 0;
                            layout.doLayout(mTextBuf.data(), j, wordEnd - j,
                                    mTextBuf.size(), bidiFlags, style, *paint);
                            ParaWidth hyphPreBreak = postBreak - layout.getAdvance();
                            addWordBreak(j, hyphPreBreak, hyphPostBreak, hyphenPenalty, hyph);
                        }
                    }
                }
                // Skip hyphenating the next word if and only if the present word ends in a hyphen
                temporarilySkipHyphenation = wordEndsInHyphen;

                // Skip break for zero-width characters inside replacement span
                if (paint != nullptr || current == end || mCharWidths[current] > 0) {
                    addWordBreak(current, mWidth, postBreak, 0.0, 0);
                }
                lastBreak = current;
                lastBreakWidth = mWidth;
            }
            current = (size_t)mBreakIterator->next();
        }
    }

    return width;
}

// add a word break (possibly for a hyphenated fragment), and add desperate breaks if
// needed (ie when word exceeds current line width)
void LineBreaker::addWordBreak(size_t offset, ParaWidth preBreak, ParaWidth postBreak,
        float penalty, uint8_t hyph) {
    Candidate cand;
    ParaWidth width = mCandidates.back().preBreak;
    if (postBreak - width > currentLineWidth()) {
        // Add desperate breaks.
        // Note: these breaks are based on the shaping of the (non-broken) original text; they
        // are imprecise especially in the presence of kerning, ligatures, and Arabic shaping.
        size_t i = mCandidates.back().offset;
        width += mCharWidths[i++];
        for (; i < offset; i++) {
            float w = mCharWidths[i];
            if (w > 0) {
                cand.offset = i;
                cand.preBreak = width;
                cand.postBreak = width;
                cand.penalty = SCORE_DESPERATE;
                cand.hyphenEdit = 0;
#if VERBOSE_DEBUG
                ALOGD("desperate cand: %d %g:%g",
                        mCandidates.size(), cand.postBreak, cand.preBreak);
#endif
                addCandidate(cand);
                width += w;
            }
        }
    }

    cand.offset = offset;
    cand.preBreak = preBreak;
    cand.postBreak = postBreak;
    cand.penalty = penalty;
    cand.hyphenEdit = hyph;
#if VERBOSE_DEBUG
    ALOGD("cand: %d %g:%g", mCandidates.size(), cand.postBreak, cand.preBreak);
#endif
    addCandidate(cand);
}

// TODO performance: could avoid populating mCandidates if greedy only
void LineBreaker::addCandidate(Candidate cand) {
    size_t candIndex = mCandidates.size();
    mCandidates.push_back(cand);
    if (cand.postBreak - mPreBreak > currentLineWidth()) {
        // This break would create an overfull line, pick the best break and break there (greedy)
        if (mBestBreak == mLastBreak) {
            mBestBreak = candIndex;
        }
        pushBreak(mCandidates[mBestBreak].offset, mCandidates[mBestBreak].postBreak - mPreBreak,
                mCandidates[mBestBreak].hyphenEdit);
        mBestScore = SCORE_INFTY;
#if VERBOSE_DEBUG
        ALOGD("break: %d %g", mBreaks.back(), mWidths.back());
#endif
        mLastBreak = mBestBreak;
        mPreBreak = mCandidates[mBestBreak].preBreak;
    }
    if (cand.penalty <= mBestScore) {
        mBestBreak = candIndex;
        mBestScore = cand.penalty;
    }
}

void LineBreaker::pushBreak(int offset, float width, uint8_t hyph) {
    mBreaks.push_back(offset);
    mWidths.push_back(width);
    int flags = (mFirstTabIndex < mBreaks.back()) << kTab_Shift;
    flags |= hyph;
    mFlags.push_back(flags);
    mFirstTabIndex = INT_MAX;
}

void LineBreaker::addReplacement(size_t start, size_t end, float width) {
    mCharWidths[start] = width;
    std::fill(&mCharWidths[start + 1], &mCharWidths[end], 0.0f);
    addStyleRun(nullptr, nullptr, FontStyle(), start, end, false);
}

float LineBreaker::currentLineWidth() const {
    return mLineWidths.getLineWidth(mBreaks.size());
}

void LineBreaker::computeBreaksGreedy() {
    // All breaks but the last have been added in addCandidate already.
    size_t nCand = mCandidates.size();
    if (nCand == 1 || mLastBreak != nCand - 1) {
        pushBreak(mCandidates[nCand - 1].offset, mCandidates[nCand - 1].postBreak - mPreBreak, 0);
        // don't need to update mBestScore, because we're done
#if VERBOSE_DEBUG
        ALOGD("final break: %d %g", mBreaks.back(), mWidths.back());
#endif
    }
}

// Follow "prev" links in mCandidates array, and copy to result arrays.
void LineBreaker::finishBreaksOptimal() {
    // clear existing greedy break result
    mBreaks.clear();
    mWidths.clear();
    mFlags.clear();
    size_t nCand = mCandidates.size();
    size_t prev;
    for (size_t i = nCand - 1; i > 0; i = prev) {
        prev = mCandidates[i].prev;
        mBreaks.push_back(mCandidates[i].offset);
        mWidths.push_back(mCandidates[i].postBreak - mCandidates[prev].preBreak);
        mFlags.push_back(mCandidates[i].hyphenEdit);
    }
    std::reverse(mBreaks.begin(), mBreaks.end());
    std::reverse(mWidths.begin(), mWidths.end());
    std::reverse(mFlags.begin(), mFlags.end());
}

void LineBreaker::computeBreaksOptimal(bool isRectangle) {
    size_t active = 0;
    size_t nCand = mCandidates.size();
    float width = mLineWidths.getLineWidth(0);
    for (size_t i = 1; i < nCand; i++) {
        bool atEnd = i == nCand - 1;
        float best = SCORE_INFTY;
        size_t bestPrev = 0;
        size_t lineNumberLast = 0;

        if (!isRectangle) {
            size_t lineNumberLast = mCandidates[active].lineNumber;
            width = mLineWidths.getLineWidth(lineNumberLast);
        }
        ParaWidth leftEdge = mCandidates[i].postBreak - width;
        float bestHope = 0;

        for (size_t j = active; j < i; j++) {
            if (!isRectangle) {
                size_t lineNumber = mCandidates[j].lineNumber;
                if (lineNumber != lineNumberLast) {
                    float widthNew = mLineWidths.getLineWidth(lineNumber);
                    if (widthNew != width) {
                        leftEdge = mCandidates[i].postBreak - width;
                        bestHope = 0;
                        width = widthNew;
                    }
                    lineNumberLast = lineNumber;
                }
            }
            float jScore = mCandidates[j].score;
            if (jScore + bestHope >= best) continue;
            float delta = mCandidates[j].preBreak - leftEdge;

            // compute width score for line

            // Note: the "bestHope" optimization makes the assumption that, when delta is
            // non-negative, widthScore will increase monotonically as successive candidate
            // breaks are considered.
            float widthScore = 0.0f;
            float additionalPenalty = 0.0f;
            if (delta < 0) {
                widthScore = SCORE_OVERFULL;
            } else if (atEnd && mStrategy != kBreakStrategy_Balanced) {
                // increase penalty for hyphen on last line
                additionalPenalty = LAST_LINE_PENALTY_MULTIPLIER * mCandidates[j].penalty;
            } else {
                widthScore = delta * delta;
            }

            if (delta < 0) {
                active = j + 1;
            } else {
                bestHope = widthScore;
            }

            float score = jScore + widthScore + additionalPenalty;
            if (score <= best) {
                best = score;
                bestPrev = j;
            }
        }
        mCandidates[i].score = best + mCandidates[i].penalty + mLinePenalty;
        mCandidates[i].prev = bestPrev;
        mCandidates[i].lineNumber = mCandidates[bestPrev].lineNumber + 1;
#if VERBOSE_DEBUG
        ALOGD("break %d: score=%g, prev=%d", i, mCandidates[i].score, mCandidates[i].prev);
#endif
    }
    finishBreaksOptimal();
}

size_t LineBreaker::computeBreaks() {
    if (mStrategy == kBreakStrategy_Greedy) {
        computeBreaksGreedy();
    } else {
        computeBreaksOptimal(mLineWidths.isConstant());
    }
    return mBreaks.size();
}

void LineBreaker::finish() {
    mWidth = 0;
    mCandidates.clear();
    mBreaks.clear();
    mWidths.clear();
    mFlags.clear();
    if (mTextBuf.size() > MAX_TEXT_BUF_RETAIN) {
        mTextBuf.clear();
        mTextBuf.shrink_to_fit();
        mCharWidths.clear();
        mCharWidths.shrink_to_fit();
        mHyphBuf.clear();
        mHyphBuf.shrink_to_fit();
        mCandidates.shrink_to_fit();
        mBreaks.shrink_to_fit();
        mWidths.shrink_to_fit();
        mFlags.shrink_to_fit();
    }
    mStrategy = kBreakStrategy_Greedy;
    mHyphenationFrequency = kHyphenationFrequency_Normal;
    mLinePenalty = 0.0f;
}

}  // namespace android

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

#define LOG_TAG "Minikin"
#include <cutils/log.h>

#include <minikin/Layout.h>
#include <minikin/LineBreaker.h>

using std::vector;

namespace android {

const int CHAR_TAB = 0x0009;

// Large scores in a hierarchy; we prefer desperate breaks to an overfull line. All these
// constants are larger than any reasonable actual width score.
const float SCORE_INFTY = std::numeric_limits<float>::max();
const float SCORE_OVERFULL = 1e12f;
const float SCORE_DESPERATE = 1e10f;

// When the text buffer is within this limit, capacity of vectors is retained at finish(),
// to avoid allocation.
const size_t MAX_TEXT_BUF_RETAIN = 32678;

void LineBreaker::setText() {
    UErrorCode status = U_ZERO_ERROR;
    utext_openUChars(&mUText, mTextBuf.data(), mTextBuf.size(), &status);
    mBreakIterator->setText(&mUText, status);
    mBreakIterator->first();

    // handle initial break here because addStyleRun may never be called
    mBreakIterator->next();
    mCandidates.clear();
    Candidate cand = {0, 0, 0.0, 0.0, 0.0, 0.0};
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
    ALOGD("width %f", firstWidth);
    mLineWidths.setWidths(firstWidth, firstWidthLineCount, restWidth);
}

// This function determines whether a character is a space that disappears at end of line.
// It is the Unicode set: [[:General_Category=Space_Separator:]-[:Line_Break=Glue:]]
// Note: all such characters are in the BMP, so it's ok to use code units for this.
static bool isLineEndSpace(uint16_t c) {
    return c == ' ' || c == 0x1680 || (0x2000 <= c && c <= 0x200A && c != 0x2007) || c == 0x205F ||
            c == 0x3000;
}

// Ordinarily, this method measures the text in the range given. However, when paint
// is nullptr, it assumes the widths have already been calculated and stored in the
// width buffer.
// This method finds the candidate word breaks (using the ICU break iterator) and sends them
// to addCandidate.
float LineBreaker::addStyleRun(const MinikinPaint* paint, const FontCollection* typeface,
        FontStyle style, size_t start, size_t end, bool isRtl) {
    Layout layout;  // performance TODO: move layout to self object to reduce allocation cost?
    float width = 0.0f;
    int bidiFlags = isRtl ? kBidi_Force_RTL : kBidi_Force_LTR;

    if (paint != nullptr) {
        layout.setFontCollection(typeface);
        layout.doLayout(mTextBuf.data(), start, end - start, mTextBuf.size(), bidiFlags, style,
                *paint);
        layout.getAdvances(mCharWidths.data() + start);
        width = layout.getAdvance();
    }

    ParaWidth postBreak = mWidth;
    size_t current = (size_t)mBreakIterator->current();
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
            }
        }
        if (i + 1 == current) {
            // TODO: hyphenation goes here

            // Skip break for zero-width characters.
            if (current == mTextBuf.size() || mCharWidths[current] > 0) {
                addWordBreak(current, mWidth, postBreak, 0);
            }
            current = (size_t)mBreakIterator->next();
        }
    }

    return width;
}

// add a word break (possibly for a hyphenated fragment), and add desperate breaks if
// needed (ie when word exceeds current line width)
void LineBreaker::addWordBreak(size_t offset, ParaWidth preBreak, ParaWidth postBreak,
        float penalty) {
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
        mBreaks.push_back(mCandidates[mBestBreak].offset);
        mWidths.push_back(mCandidates[mBestBreak].postBreak - mPreBreak);
        mFlags.push_back(mFirstTabIndex < mBreaks.back());
        mFirstTabIndex = INT_MAX;
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
        mBreaks.push_back(mCandidates[nCand - 1].offset);
        mWidths.push_back(mCandidates[nCand - 1].postBreak - mPreBreak);
        mFlags.push_back(mFirstTabIndex < mBreaks.back());
        // don't need to update mFirstTabIndex or mBestScore, because we're done
#if VERBOSE_DEBUG
        ALOGD("final break: %d %g", mBreaks.back(), mWidths.back());
#endif
    }
}

void LineBreaker::computeBreaksOpt() {
    // clear existing greedy break result
    mBreaks.clear();
    mWidths.clear();
    mFlags.clear();
    size_t active = 0;
    size_t nCand = mCandidates.size();
    float width = mLineWidths.getLineWidth(0);
    // TODO: actually support non-constant width
    for (size_t i = 1; i < nCand; i++) {
        bool stretchIsFree = mStrategy != kBreakStrategy_Balanced && i == nCand - 1;
        float best = SCORE_INFTY;
        size_t bestPrev = 0;

        // Width-based component of score increases as line gets shorter, so score will always be
        // at least this.
        float bestHope = 0;

        ParaWidth leftEdge = mCandidates[i].postBreak - width;
        for (size_t j = active; j < i; j++) {
            float jScore = mCandidates[j].score;
            if (jScore + bestHope >= best) continue;
            float delta = mCandidates[j].preBreak - leftEdge;

            // TODO: for justified text, refine with shrink/stretch
            float widthScore;
            if (delta < 0) {
                widthScore = SCORE_OVERFULL;
                active = j + 1;
            } else {
                widthScore = stretchIsFree ? 0 : delta * delta;
                bestHope = widthScore;
            }

            float score = jScore + widthScore;
            if (score <= best) {
                best = score;
                bestPrev = j;
            }
        }
        mCandidates[i].score = best + mCandidates[i].penalty;
        mCandidates[i].prev = bestPrev;
    }
    size_t prev;
    for (size_t i = nCand - 1; i > 0; i = prev) {
        prev = mCandidates[i].prev;
        mBreaks.push_back(mCandidates[i].offset);
        mWidths.push_back(mCandidates[i].postBreak - mCandidates[prev].preBreak);
        mFlags.push_back(0);
    }
    std::reverse(mBreaks.begin(), mBreaks.end());
    std::reverse(mWidths.begin(), mWidths.end());
    std::reverse(mFlags.begin(), mFlags.end());
}

size_t LineBreaker::computeBreaks() {
    if (mStrategy == kBreakStrategy_Greedy) {
        computeBreaksGreedy();
    } else {
        computeBreaksOpt();
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
        mCandidates.shrink_to_fit();
        mBreaks.shrink_to_fit();
        mWidths.shrink_to_fit();
        mFlags.shrink_to_fit();
    }
    mStrategy = kBreakStrategy_Greedy;
}

}  // namespace android

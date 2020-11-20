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

/**
 * A module for breaking paragraphs into lines, supporting high quality
 * hyphenation and justification.
 */

#ifndef MINIKIN_LINE_BREAKER_H
#define MINIKIN_LINE_BREAKER_H

#ifndef U_USING_ICU_NAMESPACE
#define U_USING_ICU_NAMESPACE 0
#endif  //  U_USING_ICU_NAMESPACE

#include <cmath>
#include <vector>
#include "minikin/FontCollection.h"
#include "minikin/Hyphenator.h"
#include "minikin/MinikinFont.h"
#include "minikin/WordBreaker.h"
#include "unicode/brkiter.h"
#include "unicode/locid.h"

namespace minikin {

enum BreakStrategy {
  kBreakStrategy_Greedy = 0,
  kBreakStrategy_HighQuality = 1,
  kBreakStrategy_Balanced = 2
};

enum HyphenationFrequency {
  kHyphenationFrequency_None = 0,
  kHyphenationFrequency_Normal = 1,
  kHyphenationFrequency_Full = 2
};

bool isLineEndSpace(uint16_t c);

// TODO: want to generalize to be able to handle array of line widths
class LineWidths {
 public:
  void setWidths(float firstWidth, int firstWidthLineCount, float restWidth) {
    mFirstWidth = firstWidth;
    mFirstWidthLineCount = firstWidthLineCount;
    mRestWidth = restWidth;
  }
  void setIndents(const std::vector<float>& indents) { mIndents = indents; }
  bool isConstant() const {
    // technically mFirstWidthLineCount == 0 would count too, but doesn't
    // actually happen
    return mRestWidth == mFirstWidth && mIndents.empty();
  }
  float getLineWidth(int line) const {
    float width = (line < mFirstWidthLineCount) ? mFirstWidth : mRestWidth;
    if (!mIndents.empty()) {
      if ((size_t)line < mIndents.size()) {
        width -= mIndents[line];
      } else {
        width -= mIndents.back();
      }
    }
    return width;
  }
  void clear() { mIndents.clear(); }

 private:
  float mFirstWidth;
  int mFirstWidthLineCount;
  float mRestWidth;
  std::vector<float> mIndents;
};

class LineBreaker {
 public:
  const static int kTab_Shift =
      29;  // keep synchronized with TAB_MASK in StaticLayout.java

  // Note: Locale persists across multiple invocations (it is not cleaned up by
  // finish()), explicitly to avoid the cost of creating ICU BreakIterator
  // objects. It should always be set on the first invocation, but callers are
  // encouraged not to call again unless locale has actually changed. That logic
  // could be here but it's better for performance that it's upstream because of
  // the cost of constructing and comparing the ICU Locale object.
  // Note: caller is responsible for managing lifetime of hyphenator
  //
  // libtxt extension: always use the default locale so that a cached instance
  // of the ICU break iterator can be reused.
  void setLocale();

  void resize(size_t size) {
    mTextBuf.resize(size);
    mCharWidths.resize(size);
  }

  size_t size() const { return mTextBuf.size(); }

  uint16_t* buffer() { return mTextBuf.data(); }

  float* charWidths() { return mCharWidths.data(); }

  // set text to current contents of buffer
  void setText();

  void setLineWidths(float firstWidth,
                     int firstWidthLineCount,
                     float restWidth);

  void setIndents(const std::vector<float>& indents);

  BreakStrategy getStrategy() const { return mStrategy; }

  void setStrategy(BreakStrategy strategy) { mStrategy = strategy; }

  void setJustified(bool justified) { mJustified = justified; }

  HyphenationFrequency getHyphenationFrequency() const {
    return mHyphenationFrequency;
  }

  void setHyphenationFrequency(HyphenationFrequency frequency) {
    mHyphenationFrequency = frequency;
  }

  // TODO: this class is actually fairly close to being general and not tied to
  // using Minikin to do the shaping of the strings. The main thing that would
  // need to be changed is having some kind of callback (or virtual class, or
  // maybe even template), which could easily be instantiated with Minikin's
  // Layout. Future work for when needed.
  float addStyleRun(MinikinPaint* paint,
                    const std::shared_ptr<FontCollection>& typeface,
                    FontStyle style,
                    size_t start,
                    size_t end,
                    bool isRtl);

  void addReplacement(size_t start, size_t end, float width);

  size_t computeBreaks();

  // libtxt: Add ability to set custom char widths. This allows manual
  // definition of the widths of arbitrary glyphs. To linebreak properly, call
  // addStyleRun with nullptr as the paint property, which will lead it to
  // assume the width has already been calculated. Used for properly breaking
  // inline placeholders.
  void setCustomCharWidth(size_t offset, float width);

  const int* getBreaks() const { return mBreaks.data(); }

  const float* getWidths() const { return mWidths.data(); }

  const int* getFlags() const { return mFlags.data(); }

  void finish();

 private:
  // ParaWidth is used to hold cumulative width from beginning of paragraph.
  // Note that for very large paragraphs, accuracy could degrade using only
  // 32-bit float. Note however that float is used extensively on the Java side
  // for this. This is a typedef so that we can easily change it based on
  // performance/accuracy tradeoff.
  typedef double ParaWidth;

  // A single candidate break
  struct Candidate {
    size_t offset;        // offset to text buffer, in code units
    size_t prev;          // index to previous break
    ParaWidth preBreak;   // width of text until this point, if we decide to not
                          // break here
    ParaWidth postBreak;  // width of text until this point, if we decide to
                          // break here
    float penalty;        // penalty of this break (for example, hyphen penalty)
    float score;          // best score found for this break
    size_t lineNumber;    // only updated for non-constant line widths
    size_t preSpaceCount;   // preceding space count before breaking
    size_t postSpaceCount;  // preceding space count after breaking
    HyphenationType hyphenType;
  };

  float currentLineWidth() const;

  void addWordBreak(size_t offset,
                    ParaWidth preBreak,
                    ParaWidth postBreak,
                    size_t preSpaceCount,
                    size_t postSpaceCount,
                    float penalty,
                    HyphenationType hyph);

  void addCandidate(Candidate cand);
  void pushGreedyBreak();

  // push an actual break to the output. Takes care of setting flags for tab
  void pushBreak(int offset, float width, uint8_t hyphenEdit);

  float getSpaceWidth() const;

  void computeBreaksGreedy();

  void computeBreaksOptimal(bool isRectangular);

  void finishBreaksOptimal();

  WordBreaker mWordBreaker;
  icu::Locale mLocale;
  std::vector<uint16_t> mTextBuf;
  std::vector<float> mCharWidths;

  Hyphenator* mHyphenator;
  std::vector<HyphenationType> mHyphBuf;

  // layout parameters
  BreakStrategy mStrategy = kBreakStrategy_Greedy;
  HyphenationFrequency mHyphenationFrequency = kHyphenationFrequency_Normal;
  bool mJustified;
  LineWidths mLineWidths;

  // result of line breaking
  std::vector<int> mBreaks;
  std::vector<float> mWidths;
  std::vector<int> mFlags;

  ParaWidth mWidth = 0;
  std::vector<Candidate> mCandidates;
  float mLinePenalty = 0.0f;

  // the following are state for greedy breaker (updated while adding style
  // runs)
  size_t mLastBreak;
  size_t mBestBreak;
  float mBestScore;
  ParaWidth mPreBreak;        // prebreak of last break
  uint32_t mLastHyphenation;  // hyphen edit of last break kept for next line
  int mFirstTabIndex;
  size_t mSpaceCount;
};

}  // namespace minikin

#endif  // MINIKIN_LINE_BREAKER_H

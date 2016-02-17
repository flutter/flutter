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

#define LOG_TAG "Minikin"
#include <cutils/log.h>

#include "minikin/WordBreaker.h"

#include <unicode/uchar.h>
#include <unicode/utf16.h>

namespace android {

const uint32_t CHAR_SOFT_HYPHEN = 0x00AD;

void WordBreaker::setLocale(const icu::Locale& locale) {
    UErrorCode status = U_ZERO_ERROR;
    mBreakIterator.reset(icu::BreakIterator::createLineInstance(locale, status));
    // TODO: handle failure status
    if (mText != nullptr) {
        mBreakIterator->setText(&mUText, status);
    }
    mIteratorWasReset = true;
}

void WordBreaker::setText(const uint16_t* data, size_t size) {
    mText = data;
    mTextSize = size;
    mIteratorWasReset = false;
    mLast = 0;
    mCurrent = 0;
    mScanOffset = 0;
    mInEmailOrUrl = false;
    UErrorCode status = U_ZERO_ERROR;
    utext_openUChars(&mUText, data, size, &status);
    mBreakIterator->setText(&mUText, status);
    mBreakIterator->first();
}

ssize_t WordBreaker::current() const {
    return mCurrent;
}

enum ScanState {
    START,
    SAW_AT,
    SAW_COLON,
    SAW_COLON_SLASH,
    SAW_COLON_SLASH_SLASH,
};

// Chicago Manual of Style recommends breaking after these characters in URLs and email addresses
static bool breakAfter(uint16_t c) {
    return c == ':' || c == '=' || c == '&';
}

// Chicago Manual of Style recommends breaking before these characters in URLs and email addresses
static bool breakBefore(uint16_t c) {
    return c == '~' || c == '.' || c == ',' || c == '-' || c == '_' || c == '?' || c == '#'
            || c == '%' || c == '=' || c == '&';
}

ssize_t WordBreaker::next() {
    mLast = mCurrent;

    // scan forward from current ICU position for email address or URL
    if (mLast >= mScanOffset) {
        ScanState state = START;
        size_t i;
        for (i = mLast; i < mTextSize; i++) {
            uint16_t c = mText[i];
            // scan only ASCII characters, stop at space
            if (!(' ' < c && c <= 0x007E)) {
                break;
            }
            if (state == START && c == '@') {
                state = SAW_AT;
            } else if (state == START && c == ':') {
                state = SAW_COLON;
            } else if (state == SAW_COLON || state == SAW_COLON_SLASH) {
                if (c == '/') {
                    state = static_cast<ScanState>((int)state + 1);  // next state adds a slash
                } else {
                    state = START;
                }
            }
        }
        if (state == SAW_AT || state == SAW_COLON_SLASH_SLASH) {
            if (!mBreakIterator->isBoundary(i)) {
                i = mBreakIterator->following(i);
            }
            mInEmailOrUrl = true;
            mIteratorWasReset = true;
        } else {
            mInEmailOrUrl = false;
        }
        mScanOffset = i;
    }

    if (mInEmailOrUrl) {
        // special rules for email addresses and URL's as per Chicago Manual of Style (16th ed.)
        uint16_t lastChar = mText[mLast];
        ssize_t i;
        for (i = mLast + 1; i < mScanOffset; i++) {
            if (breakAfter(lastChar)) {
                break;
            }
            // break after double slash
            if (lastChar == '/' && i >= mLast + 2 && mText[i - 2] == '/') {
                break;
            }
            uint16_t thisChar = mText[i];
            // never break after hyphen
            if (lastChar != '-') {
                if (breakBefore(thisChar)) {
                    break;
                }
                // break before single slash
                if (thisChar == '/' && lastChar != '/' &&
                            !(i + 1 < mScanOffset && mText[i + 1] == '/')) {
                    break;
                }
            }
            lastChar = thisChar;
        }
        mCurrent = i;
        return mCurrent;
    }

    int32_t result;
    do {
        if (mIteratorWasReset) {
            result = mBreakIterator->following(mCurrent);
            mIteratorWasReset = false;
        } else {
            result = mBreakIterator->next();
        }
    } while (result != icu::BreakIterator::DONE && (size_t)result != mTextSize
             && mText[result - 1] == CHAR_SOFT_HYPHEN);
    mCurrent = (ssize_t)result;
    return mCurrent;
}

ssize_t WordBreaker::wordStart() const {
    if (mInEmailOrUrl) {
        return mLast;
    }
    ssize_t result = mLast;
    while (result < mCurrent) {
        UChar32 c;
        ssize_t ix = result;
        U16_NEXT(mText, ix, mCurrent, c);
        int32_t lb = u_getIntPropertyValue(c, UCHAR_LINE_BREAK);
        // strip leading punctuation, defined as OP and QU line breaking classes,
        // see UAX #14
        if (!(lb == U_LB_OPEN_PUNCTUATION || lb == U_LB_QUOTATION)) {
            break;
        }
        result = ix;
    }
    return result;
}

ssize_t WordBreaker::wordEnd() const {
    if (mInEmailOrUrl) {
        return mLast;
    }
    ssize_t result = mCurrent;
    while (result > mLast) {
        UChar32 c;
        ssize_t ix = result;
        U16_PREV(mText, mLast, ix, c);
        int32_t gc_mask = U_GET_GC_MASK(c);
        // strip trailing space and punctuation
        if ((gc_mask & (U_GC_ZS_MASK | U_GC_P_MASK)) == 0) {
            break;
        }
        result = ix;
    }
    return result;
}

void WordBreaker::finish() {
    mText = nullptr;
    // Note: calling utext_close multiply is safe
    utext_close(&mUText);
}

}  // namespace android

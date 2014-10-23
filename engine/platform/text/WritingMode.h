/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#ifndef WritingMode_h
#define WritingMode_h

namespace blink {

enum WritingMode {
    TopToBottomWritingMode, RightToLeftWritingMode, LeftToRightWritingMode, BottomToTopWritingMode
};

// Lines have horizontal orientation; modes horizontal-tb or horizontal-bt.
inline bool isHorizontalWritingMode(WritingMode writingMode)
{
    return writingMode == TopToBottomWritingMode || writingMode == BottomToTopWritingMode;
}

// Bottom of the line occurs earlier in the block; modes vertical-lr or horizontal-bt.
inline bool isFlippedLinesWritingMode(WritingMode writingMode)
{
    return writingMode == LeftToRightWritingMode || writingMode == BottomToTopWritingMode;
}

// Block progression increases in the opposite direction to normal; modes vertical-rl or horizontal-bt.
inline bool isFlippedBlocksWritingMode(WritingMode writingMode)
{
    return writingMode == RightToLeftWritingMode || writingMode == BottomToTopWritingMode;
}

} // namespace blink

#endif // WritingMode_h

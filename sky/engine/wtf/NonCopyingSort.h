/*
 * Copyright (C) 2010 Apple Inc. All Rights Reserved.
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
 *
 */

#ifndef SKY_ENGINE_WTF_NONCOPYINGSORT_H_
#define SKY_ENGINE_WTF_NONCOPYINGSORT_H_

namespace WTF {

using std::swap;

template <typename RandomAccessIterator, typename Predicate>
inline void siftDown(RandomAccessIterator array,
                     ptrdiff_t start,
                     ptrdiff_t end,
                     Predicate compareLess) {
  ptrdiff_t root = start;

  while (root * 2 + 1 <= end) {
    ptrdiff_t child = root * 2 + 1;
    if (child < end && compareLess(array[child], array[child + 1]))
      child++;

    if (compareLess(array[root], array[child])) {
      swap(array[root], array[child]);
      root = child;
    } else
      return;
  }
}

template <typename RandomAccessIterator, typename Predicate>
inline void heapify(RandomAccessIterator array,
                    ptrdiff_t count,
                    Predicate compareLess) {
  ptrdiff_t start = (count - 2) / 2;

  while (start >= 0) {
    siftDown(array, start, count - 1, compareLess);
    start--;
  }
}

template <typename RandomAccessIterator, typename Predicate>
void heapSort(RandomAccessIterator start,
              RandomAccessIterator end,
              Predicate compareLess) {
  ptrdiff_t count = end - start;
  heapify(start, count, compareLess);

  ptrdiff_t endIndex = count - 1;
  while (endIndex > 0) {
    swap(start[endIndex], start[0]);
    siftDown(start, 0, endIndex - 1, compareLess);
    endIndex--;
  }
}

template <typename RandomAccessIterator, typename Predicate>
inline void nonCopyingSort(RandomAccessIterator start,
                           RandomAccessIterator end,
                           Predicate compareLess) {
  // heapsort happens to use only swaps, not copies, but the essential thing
  // about this function is the fact that it does not copy, not the specific
  // algorithm
  heapSort(start, end, compareLess);
}

}  // namespace WTF

using WTF::nonCopyingSort;

#endif  // SKY_ENGINE_WTF_NONCOPYINGSORT_H_

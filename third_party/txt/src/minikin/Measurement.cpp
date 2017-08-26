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

#include <unicode/uchar.h>
#include <cmath>

#include <log/log.h>

#include <minikin/GraphemeBreak.h>
#include <minikin/Measurement.h>

namespace minikin {

// These could be considered helper methods of layout, but need only be loosely
// coupled, so are separate.

static float getRunAdvance(const float* advances,
                           const uint16_t* buf,
                           size_t layoutStart,
                           size_t start,
                           size_t count,
                           size_t offset) {
  float advance = 0.0f;
  size_t lastCluster = start;
  float clusterWidth = 0.0f;
  for (size_t i = start; i < offset; i++) {
    float charAdvance = advances[i - layoutStart];
    if (charAdvance != 0.0f) {
      advance += charAdvance;
      lastCluster = i;
      clusterWidth = charAdvance;
    }
  }
  if (offset < start + count && advances[offset - layoutStart] == 0.0f) {
    // In the middle of a cluster, distribute width of cluster so that each
    // grapheme cluster gets an equal share.
    // TODO: get caret information out of font when that's available
    size_t nextCluster;
    for (nextCluster = offset + 1; nextCluster < start + count; nextCluster++) {
      if (advances[nextCluster - layoutStart] != 0.0f)
        break;
    }
    int numGraphemeClusters = 0;
    int numGraphemeClustersAfter = 0;
    for (size_t i = lastCluster; i < nextCluster; i++) {
      bool isAfter = i >= offset;
      if (GraphemeBreak::isGraphemeBreak(advances + (start - layoutStart), buf,
                                         start, count, i)) {
        numGraphemeClusters++;
        if (isAfter) {
          numGraphemeClustersAfter++;
        }
      }
    }
    if (numGraphemeClusters > 0) {
      advance -= clusterWidth * numGraphemeClustersAfter / numGraphemeClusters;
    }
  }
  return advance;
}

float getRunAdvance(const float* advances,
                    const uint16_t* buf,
                    size_t start,
                    size_t count,
                    size_t offset) {
  return getRunAdvance(advances, buf, start, start, count, offset);
}

/**
 * Essentially the inverse of getRunAdvance. Compute the value of offset for
 * which the measured caret comes closest to the provided advance param, and
 * which is on a grapheme cluster boundary.
 *
 * The actual implementation fast-forwards through clusters to get "close", then
 * does a finer-grain search within the cluster and grapheme breaks.
 */
size_t getOffsetForAdvance(const float* advances,
                           const uint16_t* buf,
                           size_t start,
                           size_t count,
                           float advance) {
  float x = 0.0f, xLastClusterStart = 0.0f, xSearchStart = 0.0f;
  size_t lastClusterStart = start, searchStart = start;
  for (size_t i = start; i < start + count; i++) {
    if (GraphemeBreak::isGraphemeBreak(advances, buf, start, count, i)) {
      searchStart = lastClusterStart;
      xSearchStart = xLastClusterStart;
    }
    float width = advances[i - start];
    if (width != 0.0f) {
      lastClusterStart = i;
      xLastClusterStart = x;
      x += width;
      if (x > advance) {
        break;
      }
    }
  }
  size_t best = searchStart;
  float bestDist = FLT_MAX;
  for (size_t i = searchStart; i <= start + count; i++) {
    if (GraphemeBreak::isGraphemeBreak(advances, buf, start, count, i)) {
      // "getRunAdvance(layout, buf, start, count, i) - advance" but more
      // efficient
      float delta = getRunAdvance(advances, buf, start, searchStart,
                                  count - searchStart, i)

                    + xSearchStart - advance;
      if (std::abs(delta) < bestDist) {
        bestDist = std::abs(delta);
        best = i;
      }
      if (delta >= 0.0f) {
        break;
      }
    }
  }
  return best;
}

}  // namespace minikin

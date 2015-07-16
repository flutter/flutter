// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import org.chromium.base.metrics.RecordHistogram;

/**
 * Helpers for testing UMA metrics.
 */
public class MetricsUtils {
    /**
     * Helper class that snapshots the given bucket of the given UMA histogram on its creation,
     * allowing to inspect the number of samples recorded during its lifetime.
     */
    public static class HistogramDelta {
        private final String mHistogram;
        private final int mSampleValue;

        private final int mInitialCount;

        private int get() {
            return RecordHistogram.getHistogramValueCountForTesting(mHistogram, mSampleValue);
        }

        /**
         * Snapshots the given bucket of the given histogram.
         * @param histogram name of the histogram to snapshot
         * @param sampleValue the bucket that contains this value will be snapshot
         */
        public HistogramDelta(String histogram, int sampleValue) {
            mHistogram = histogram;
            mSampleValue = sampleValue;
            mInitialCount = get();
        }

        /** Returns the number of samples of the snapshot bucket recorded since creation */
        public int getDelta() {
            return get() - mInitialCount;
        }
    }
}

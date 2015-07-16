// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.metrics;

import org.chromium.base.JNINamespace;
import org.chromium.base.VisibleForTesting;

import java.util.concurrent.TimeUnit;

/**
 * Java API for recording UMA histograms. Internally, the histogram will be cached by
 * System.identityHashCode(name).
 *
 * Note: the JNI calls are relatively costly - avoid calling these methods in performance-critical
 * code.
 */
@JNINamespace("base::android")
public class RecordHistogram {
    /**
     * Records a sample in a boolean UMA histogram of the given name. Boolean histogram has two
     * buckets, corresponding to success (true) and failure (false). This is the Java equivalent of
     * the UMA_HISTOGRAM_BOOLEAN C++ macro.
     * @param name name of the histogram
     * @param sample sample to be recorded, either true or false
     */
    public static void recordBooleanHistogram(String name, boolean sample) {
        nativeRecordBooleanHistogram(name, System.identityHashCode(name), sample);
    }

    /**
     * Records a sample in an enumerated histogram of the given name and boundary. Note that
     * |boundary| identifies the histogram - it should be the same at every invocation. This is the
     * Java equivalent of the UMA_HISTOGRAM_ENUMERATION C++ macro.
     * @param name name of the histogram
     * @param sample sample to be recorded, at least 0 and at most |boundary| - 1
     * @param boundary upper bound for legal sample values - all sample values have to be strictly
     *        lower than |boundary|
     */
    public static void recordEnumeratedHistogram(String name, int sample, int boundary) {
        nativeRecordEnumeratedHistogram(name, System.identityHashCode(name), sample, boundary);
    }

    /**
     * Records a sample in a count histogram. This is the Java equivalent of the
     * UMA_HISTOGRAM_COUNTS C++ macro.
     * @param name name of the histogram
     * @param sample sample to be recorded, at least 1 and at most 999999
     */
    public static void recordCountHistogram(String name, int sample) {
        recordCustomCountHistogram(name, sample, 1, 1000000, 50);
    }

    /**
     * Records a sample in a count histogram. This is the Java equivalent of the
     * UMA_HISTOGRAM_COUNTS_100 C++ macro.
     * @param name name of the histogram
     * @param sample sample to be recorded, at least 1 and at most 99
     */
    public static void recordCount100Histogram(String name, int sample) {
        recordCustomCountHistogram(name, sample, 1, 100, 50);
    }

    /**
     * Records a sample in a count histogram. This is the Java equivalent of the
     * UMA_HISTOGRAM_CUSTOM_COUNTS C++ macro.
     * @param name name of the histogram
     * @param sample sample to be recorded, at least |min| and at most |max| - 1
     * @param min lower bound for expected sample values
     * @param max upper bounds for expected sample values
     * @param numBuckets the number of buckets
     */
    public static void recordCustomCountHistogram(
            String name, int sample, int min, int max, int numBuckets) {
        nativeRecordCustomCountHistogram(
                name, System.identityHashCode(name), sample, min, max, numBuckets);
    }

    /**
    * Records a sparse histogram. This is the Java equivalent of UMA_HISTOGRAM_SPARSE_SLOWLY.
    * @param name name of the histogram
    * @param sample sample to be recorded. All values of |sample| are valid, including negative
    *        values.
    */
    public static void recordSparseSlowlyHistogram(String name, int sample) {
        nativeRecordSparseHistogram(name, System.identityHashCode(name), sample);
    }

    /**
     * Records a sample in a histogram of times. Useful for recording short durations. This is the
     * Java equivalent of the UMA_HISTOGRAM_TIMES C++ macro.
     * @param name name of the histogram
     * @param duration duration to be recorded
     * @param timeUnit the unit of the duration argument
     */
    public static void recordTimesHistogram(String name, long duration, TimeUnit timeUnit) {
        recordCustomTimesHistogramMilliseconds(
                name, timeUnit.toMillis(duration), 1, TimeUnit.SECONDS.toMillis(10), 50);
    }

    /**
     * Records a sample in a histogram of times. Useful for recording medium durations. This is the
     * Java equivalent of the UMA_HISTOGRAM_MEDIUM_TIMES C++ macro.
     * @param name name of the histogram
     * @param duration duration to be recorded
     * @param timeUnit the unit of the duration argument
     */
    public static void recordMediumTimesHistogram(String name, long duration, TimeUnit timeUnit) {
        recordCustomTimesHistogramMilliseconds(
                name, timeUnit.toMillis(duration), 10, TimeUnit.MINUTES.toMillis(3), 50);
    }

    /**
     * Records a sample in a histogram of times. Useful for recording long durations. This is the
     * Java equivalent of the UMA_HISTOGRAM_LONG_TIMES C++ macro.
     * @param name name of the histogram
     * @param duration duration to be recorded
     * @param timeUnit the unit of the duration argument
     */
    public static void recordLongTimesHistogram(String name, long duration, TimeUnit timeUnit) {
        recordCustomTimesHistogramMilliseconds(
                name, timeUnit.toMillis(duration), 1, TimeUnit.HOURS.toMillis(1), 50);
    }

    /**
     * Records a sample in a histogram of times with custom buckets. This is the Java equivalent of
     * the UMA_HISTOGRAM_CUSTOM_TIMES C++ macro.
     * @param name name of the histogram
     * @param duration duration to be recorded
     * @param min the minimum bucket value
     * @param max the maximum bucket value
     * @param timeUnit the unit of the duration, min, and max arguments
     * @param numBuckets the number of buckets
     */
    public static void recordCustomTimesHistogram(
            String name, long duration, long min, long max, TimeUnit timeUnit, int numBuckets) {
        recordCustomTimesHistogramMilliseconds(name, timeUnit.toMillis(duration),
                timeUnit.toMillis(min), timeUnit.toMillis(max), numBuckets);
    }

    private static void recordCustomTimesHistogramMilliseconds(
            String name, long duration, long min, long max, int numBuckets) {
        nativeRecordCustomTimesHistogramMilliseconds(
                name, System.identityHashCode(name), duration, min, max, numBuckets);
    }

    /**
     * Returns the number of samples recorded in the given bucket of the given histogram.
     * @param name name of the histogram to look up
     * @param sample the bucket containing this sample value will be looked up
     */
    @VisibleForTesting
    public static int getHistogramValueCountForTesting(String name, int sample) {
        return nativeGetHistogramValueCountForTesting(name, sample);
    }

    /**
     * Initializes the metrics system.
     */
    public static void initialize() {
        nativeInitialize();
    }

    private static native void nativeRecordCustomTimesHistogramMilliseconds(
            String name, int key, long duration, long min, long max, int numBuckets);

    private static native void nativeRecordBooleanHistogram(String name, int key, boolean sample);
    private static native void nativeRecordEnumeratedHistogram(
            String name, int key, int sample, int boundary);
    private static native void nativeRecordCustomCountHistogram(
            String name, int key, int sample, int min, int max, int numBuckets);
    private static native void nativeRecordSparseHistogram(String name, int key, int sample);

    private static native int nativeGetHistogramValueCountForTesting(String name, int sample);
    private static native void nativeInitialize();
}

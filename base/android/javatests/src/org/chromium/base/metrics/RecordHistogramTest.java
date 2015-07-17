// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.metrics;

import android.test.InstrumentationTestCase;
import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.test.util.MetricsUtils.HistogramDelta;

import java.util.concurrent.TimeUnit;

/**
 * Tests for the Java API for recording UMA histograms.
 */
public class RecordHistogramTest extends InstrumentationTestCase {
    @Override
    protected void setUp() throws Exception {
        super.setUp();
        LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER)
                .ensureInitialized(getInstrumentation().getTargetContext());
        RecordHistogram.initialize();
    }

    /**
     * Tests recording of boolean histograms.
     */
    @SmallTest
    public void testRecordBooleanHistogram() {
        String histogram = "HelloWorld.BooleanMetric";
        HistogramDelta falseCount = new HistogramDelta(histogram, 0);
        HistogramDelta trueCount = new HistogramDelta(histogram, 1);
        assertEquals(0, trueCount.getDelta());
        assertEquals(0, falseCount.getDelta());

        RecordHistogram.recordBooleanHistogram(histogram, true);
        assertEquals(1, trueCount.getDelta());
        assertEquals(0, falseCount.getDelta());

        RecordHistogram.recordBooleanHistogram(histogram, true);
        assertEquals(2, trueCount.getDelta());
        assertEquals(0, falseCount.getDelta());

        RecordHistogram.recordBooleanHistogram(histogram, false);
        assertEquals(2, trueCount.getDelta());
        assertEquals(1, falseCount.getDelta());
    }

    /**
     * Tests recording of enumerated histograms.
     */
    @SmallTest
    public void testRecordEnumeratedHistogram() {
        String histogram = "HelloWorld.EnumeratedMetric";
        HistogramDelta zeroCount = new HistogramDelta(histogram, 0);
        HistogramDelta oneCount = new HistogramDelta(histogram, 1);
        HistogramDelta twoCount = new HistogramDelta(histogram, 2);
        final int boundary = 3;

        assertEquals(0, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordEnumeratedHistogram(histogram, 0, boundary);
        assertEquals(1, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordEnumeratedHistogram(histogram, 0, boundary);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordEnumeratedHistogram(histogram, 2, boundary);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(1, twoCount.getDelta());
    }

    /**
     * Tests recording of count histograms.
     */
    @SmallTest
    public void testRecordCountHistogram() {
        String histogram = "HelloWorld.CountMetric";
        HistogramDelta zeroCount = new HistogramDelta(histogram, 0);
        HistogramDelta oneCount = new HistogramDelta(histogram, 1);
        HistogramDelta twoCount = new HistogramDelta(histogram, 2);
        HistogramDelta eightThousandCount = new HistogramDelta(histogram, 8000);

        assertEquals(0, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());
        assertEquals(0, eightThousandCount.getDelta());

        RecordHistogram.recordCountHistogram(histogram, 0);
        assertEquals(1, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());
        assertEquals(0, eightThousandCount.getDelta());

        RecordHistogram.recordCountHistogram(histogram, 0);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());
        assertEquals(0, eightThousandCount.getDelta());

        RecordHistogram.recordCountHistogram(histogram, 2);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(1, twoCount.getDelta());
        assertEquals(0, eightThousandCount.getDelta());

        RecordHistogram.recordCountHistogram(histogram, 8000);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(1, twoCount.getDelta());
        assertEquals(1, eightThousandCount.getDelta());
    }

    /**
     * Tests recording of custom times histograms.
     */
    @SmallTest
    public void testRecordCustomTimesHistogram() {
        String histogram = "HelloWorld.CustomTimesMetric";
        HistogramDelta zeroCount = new HistogramDelta(histogram, 0);
        HistogramDelta oneCount = new HistogramDelta(histogram, 1);
        HistogramDelta twoCount = new HistogramDelta(histogram, 100);

        assertEquals(0, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        TimeUnit milli = TimeUnit.MILLISECONDS;

        RecordHistogram.recordCustomTimesHistogram(histogram, 0, 1, 100, milli, 3);
        assertEquals(1, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordCustomTimesHistogram(histogram, 0, 1, 100, milli, 3);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(0, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordCustomTimesHistogram(histogram, 95, 1, 100, milli, 3);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(1, oneCount.getDelta());
        assertEquals(0, twoCount.getDelta());

        RecordHistogram.recordCustomTimesHistogram(histogram, 200, 1, 100, milli, 3);
        assertEquals(2, zeroCount.getDelta());
        assertEquals(1, oneCount.getDelta());
        assertEquals(1, twoCount.getDelta());
    }
}

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * This annotation tells the test harness that this method will be used in a performance test.
 * This means that the test harness will use the parameters here to figure out which trace calls
 * to track specifically for this test.
 * <p>
 * Each of the lists ({@link #traceNames()}, {@link #graphNames()},
 * and {@link #seriesNames()}) should have the same number of
 * elements.
 * <p>
 * To write a performance test, you need to do the following:
 * <p><ol>
 * <li>Add TraceEvent calls to the code that you want to track.
 *   <ul>
 *   <li> For FPS, add a TraceEvent.instant call where you want to time and detect calls.
 *   <li> For code segment timing, add {@link org.chromium.base.TraceEvent#begin()}/
 * {@link org.chromium.base.TraceEvent#end()} calls around the code
 * segment (does not have to be in the same method).
 *   </ul>
 * <li> Write a Java Automated UI Test that instruments this code.
 * <li> Add this PerfTest annotation to the test method.
 *   <ul>
 *   <li> traceNames must be a list of the names of all of the TraceEvent calls you want to track.
 *   <li> graphNames must be a list, one for each traceName, of which graph the trace data should be
 *   placed in (does not have to be unique).
 *   <li> seriesNames must be a list, one for each traceName, of what the series should be called
 *   for this trace data (has to be unique per graphName).
 * <li> When checked in, the buildbots will automatically run this test and the results will show up
 * under the Java Automation UI Performance graph, where there will be tabs for each graphName
 * specified.
 * <li> To test your performance test, run the following command and you should see the performance
 * numbers printed to the console.
 * </ol>
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD})
public @interface PerfTest {
    /**
     * @return A list of the trace calls to track.
     */
    public String[] traceNames();

    /**
     * @return A list, one for each traceName, that represents which graph this trace call should
     *         be output on.  This does not have to be unique if there are multiple series per
     *         graph.
     */
    public String[] graphNames();

    /**
     * @return A list, one for each traceName, that represents the series this trace call should be
     *         on the corresponding graph.  This should be unique.
     */
    public String[] seriesNames();

    /**
     * @return Whether or not we should automatically start and stop tracing for the test.  This
     *         makes it easier to run some tests where tracing is started and stopped at the
     *         beginning and end of that particular test.
     */
    public boolean autoTrace() default false;

    /**
     * @return Whether this performance test should track memory usage in addition to time.  If
     *         true, this will track memory usage when tracking time deltas or instants.  With each
     *         graph defined in the annotation for tracking time, this will add an additional graph
     *         suffixed with a memory identifier containing the same series as those tracking the
     *         timing performance but instead will be tracking memory consumption.
     */
    public boolean traceMemory() default true;

    /**
     * @return Whether this performance test should track time or (optionally) only memory.  If
     *         false, this will not automatically track time deltas or instants when logging
     *         memory info.
     */
    public boolean traceTiming() default true;
}

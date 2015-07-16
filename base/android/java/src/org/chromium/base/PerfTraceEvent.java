// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.os.Debug;
import android.os.Debug.MemoryInfo;
import android.util.Log;

import org.chromium.base.annotations.SuppressFBWarnings;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.LinkedList;
import java.util.List;

/**
 * PerfTraceEvent can be used like TraceEvent, but is intended for
 * performance measurement.  By limiting the types of tracing we hope
 * to minimize impact on measurement.
 *
 * All PerfTraceEvent events funnel into TraceEvent. When not doing
 * performance measurements, they act the same.  However,
 * PerfTraceEvents can be enabled even when TraceEvent is not.
 *
 * Unlike TraceEvent, PerfTraceEvent data is sent to the system log,
 * not to a trace file.
 *
 * Performance events need to have very specific names so we find
 * the right ones.  For example, we specify the name exactly in
 * the @TracePerf annotation.  Thus, unlike TraceEvent, we do not
 * support an implicit trace name based on the callstack.
 */
@SuppressFBWarnings("CHROMIUM_SYNCHRONIZED_METHOD")
public class PerfTraceEvent {
    private static final int MAX_NAME_LENGTH = 40;
    private static final String MEMORY_TRACE_NAME_SUFFIX = "_BZR_PSS";
    private static File sOutputFile = null;

    /** The event types understood by the perf trace scripts. */
    private enum EventType {
        START("S"),
        FINISH("F"),
        INSTANT("I");

        // The string understood by the trace scripts.
        private final String mTypeStr;

        EventType(String typeStr) {
            mTypeStr = typeStr;
        }

        @Override
        public String toString() {
            return mTypeStr;
        }
    }

    private static boolean sEnabled = false;
    private static boolean sTrackTiming = true;
    private static boolean sTrackMemory = false;

    // A list of performance trace event strings.
    // Events are stored as a JSON dict much like TraceEvent.
    // E.g. timestamp is in microseconds.
    private static JSONArray sPerfTraceStrings;

    // A filter for performance tracing.  Only events that match a
    // string in the list are saved.  Presence of a filter does not
    // necessarily mean perf tracing is enabled.
    private static List<String> sFilter;

    // Nanosecond start time of performance tracing.
    private static long sBeginNanoTime;

    /**
     * Specifies what event names will be tracked.
     *
     * @param strings Event names we will record.
     */
    @VisibleForTesting
    public static synchronized void setFilter(List<String> strings) {
        sFilter = new LinkedList<String>(strings);
    }

    /**
     * Enable or disable perf tracing.
     * Disabling of perf tracing will dump trace data to the system log.
     */
    @VisibleForTesting
    public static synchronized void setEnabled(boolean enabled) {
        if (sEnabled == enabled) {
            return;
        }
        if (enabled) {
            sBeginNanoTime = System.nanoTime();
            sPerfTraceStrings = new JSONArray();
        } else {
            dumpPerf();
            sPerfTraceStrings = null;
            sFilter = null;
        }
        sEnabled = enabled;
    }

    /**
     * Enables memory tracking for all timing perf events tracked.
     *
     * <p>
     * Only works when called in combination with {@link #setEnabled(boolean)}.
     *
     * <p>
     * By enabling this feature, an additional perf event containing the memory usage will be
     * logged whenever {@link #instant(String)}, {@link #begin(String)}, or {@link #end(String)}
     * is called.
     *
     * @param enabled Whether to enable memory tracking for all perf events.
     */
    @VisibleForTesting
    public static synchronized void setMemoryTrackingEnabled(boolean enabled) {
        sTrackMemory = enabled;
    }

    /**
     * Enables timing tracking for all perf events tracked.
     *
     * <p>
     * Only works when called in combination with {@link #setEnabled(boolean)}.
     *
     * <p>
     * If this feature is enabled, whenever {@link #instant(String)}, {@link #begin(String)},
     * or {@link #end(String)} is called the time since start of tracking will be logged.
     *
     * @param enabled Whether to enable timing tracking for all perf events.
     */
    @VisibleForTesting
    public static synchronized void setTimingTrackingEnabled(boolean enabled) {
        sTrackTiming = enabled;
    }

    /**
     * @return True if tracing is enabled, false otherwise.
     * It is safe to call trace methods without checking if PerfTraceEvent
     * is enabled.
     */
    @VisibleForTesting
    public static synchronized boolean enabled() {
        return sEnabled;
    }

    /**
     * Record an "instant" perf trace event.  E.g. "screen update happened".
     */
    public static synchronized void instant(String name) {
        // Instant doesn't really need/take an event id, but this should be okay.
        final long eventId = name.hashCode();
        TraceEvent.instant(name);
        if (sEnabled && matchesFilter(name)) {
            savePerfString(name, eventId, EventType.INSTANT, false);
        }
    }


    /**
     * Record an "begin" perf trace event.
     * Begin trace events should have a matching end event.
     */
    @VisibleForTesting
    public static synchronized void begin(String name) {
        final long eventId = name.hashCode();
        TraceEvent.startAsync(name, eventId);
        if (sEnabled && matchesFilter(name)) {
            // Done before calculating the starting perf data to ensure calculating the memory usage
            // does not influence the timing data.
            if (sTrackMemory) {
                savePerfString(makeMemoryTraceNameFromTimingName(name), eventId, EventType.START,
                        true);
            }
            if (sTrackTiming) {
                savePerfString(name, eventId, EventType.START, false);
            }
        }
    }

    /**
     * Record an "end" perf trace event, to match a begin event.  The
     * time delta between begin and end is usually interesting to
     * graph code.
     */
    @VisibleForTesting
    public static synchronized void end(String name) {
        final long eventId = name.hashCode();
        TraceEvent.finishAsync(name, eventId);
        if (sEnabled && matchesFilter(name)) {
            if (sTrackTiming) {
                savePerfString(name, eventId, EventType.FINISH, false);
            }
            // Done after calculating the ending perf data to ensure calculating the memory usage
            // does not influence the timing data.
            if (sTrackMemory) {
                savePerfString(makeMemoryTraceNameFromTimingName(name), eventId, EventType.FINISH,
                        true);
            }
        }
    }

    /**
     * Record an "begin" memory trace event.
     * Begin trace events should have a matching end event.
     */
    @VisibleForTesting
    public static synchronized void begin(String name, MemoryInfo memoryInfo) {
        final long eventId = name.hashCode();
        TraceEvent.startAsync(name, eventId);
        if (sEnabled && matchesFilter(name)) {
            // Done before calculating the starting perf data to ensure calculating the memory usage
            // does not influence the timing data.
            long timestampUs = (System.nanoTime() - sBeginNanoTime) / 1000;
            savePerfString(makeMemoryTraceNameFromTimingName(name), eventId, EventType.START,
                    timestampUs, memoryInfo);
            if (sTrackTiming) {
                savePerfString(name, eventId, EventType.START, false);
            }
        }
    }

    /**
     * Record an "end" memory trace event, to match a begin event.  The
     * memory usage delta between begin and end is usually interesting to
     * graph code.
     */
    @VisibleForTesting
    public static synchronized void end(String name, MemoryInfo memoryInfo) {
        final long eventId = name.hashCode();
        TraceEvent.finishAsync(name, eventId);
        if (sEnabled && matchesFilter(name)) {
            if (sTrackTiming) {
                savePerfString(name, eventId, EventType.FINISH, false);
            }
            // Done after calculating the instant perf data to ensure calculating the memory usage
            // does not influence the timing data.
            long timestampUs = (System.nanoTime() - sBeginNanoTime) / 1000;
            savePerfString(makeMemoryTraceNameFromTimingName(name), eventId, EventType.FINISH,
                    timestampUs, memoryInfo);
        }
    }

    /**
     * Determine if we are interested in this trace event.
     * @return True if the name matches the allowed filter; else false.
     */
    private static boolean matchesFilter(String name) {
        return sFilter != null ? sFilter.contains(name) : false;
    }

    /**
     * Save a perf trace event as a JSON dict.  The format mirrors a TraceEvent dict.
     *
     * @param name The trace data
     * @param id The id of the event
     * @param type the type of trace event (I, S, F)
     * @param includeMemory Whether to include current browser process memory usage in the trace.
     */
    private static void savePerfString(String name, long id, EventType type,
            boolean includeMemory) {
        long timestampUs = (System.nanoTime() - sBeginNanoTime) / 1000;
        MemoryInfo memInfo = null;
        if (includeMemory) {
            memInfo = new MemoryInfo();
            Debug.getMemoryInfo(memInfo);
        }
        savePerfString(name, id, type, timestampUs, memInfo);
    }

    /**
     * Save a perf trace event as a JSON dict.  The format mirrors a TraceEvent dict.
     *
     * @param name The trace data
     * @param id The id of the event
     * @param type the type of trace event (I, S, F)
     * @param timestampUs The time stamp at which this event was recorded
     * @param memoryInfo Memory details to be included in this perf string, null if
     *                   no memory details are to be included.
     */
    private static void savePerfString(String name, long id, EventType type, long timestampUs,
            MemoryInfo memoryInfo) {
        try {
            JSONObject traceObj = new JSONObject();
            traceObj.put("cat", "Java");
            traceObj.put("ts", timestampUs);
            traceObj.put("ph", type);
            traceObj.put("name", name);
            traceObj.put("id", id);
            if (memoryInfo != null) {
                int pss = memoryInfo.nativePss + memoryInfo.dalvikPss + memoryInfo.otherPss;
                traceObj.put("mem", pss);
            }
            sPerfTraceStrings.put(traceObj);
        } catch (JSONException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Generating a trace name for tracking memory based on the timing name passed in.
     *
     * @param name The timing name to use as a base for the memory perf name.
     * @return The memory perf name to use.
     */
    public static String makeMemoryTraceNameFromTimingName(String name) {
        return makeSafeTraceName(name, MEMORY_TRACE_NAME_SUFFIX);
    }

    /**
     * Builds a name to be used in the perf trace framework.  The framework has length requirements
     * for names, so this ensures the generated name does not exceed the maximum (trimming the
     * base name if necessary).
     *
     * @param baseName The base name to use when generating the name.
     * @param suffix The required suffix to be appended to the name.
     * @return A name that is safe for the perf trace framework.
     */
    public static String makeSafeTraceName(String baseName, String suffix) {
        int suffixLength = suffix.length();

        if (baseName.length() + suffixLength > MAX_NAME_LENGTH) {
            baseName = baseName.substring(0, MAX_NAME_LENGTH - suffixLength);
        }
        return baseName + suffix;
    }

    /**
     * Sets a file to dump the results to.  If {@code file} is {@code null}, it will be dumped
     * to STDOUT, otherwise the JSON performance data will be appended to {@code file}.  This should
     * be called before the performance run starts.  When {@link #setEnabled(boolean)} is called
     * with {@code false}, the perf data will be dumped.
     *
     * @param file Which file to append the performance data to.  If {@code null}, the performance
     *             data will be sent to STDOUT.
     */
    @VisibleForTesting
    public static synchronized void setOutputFile(File file) {
        sOutputFile = file;
    }

    /**
     * Dump all performance data we have saved up to the log.
     * Output as JSON for parsing convenience.
     */
    private static void dumpPerf() {
        String json = sPerfTraceStrings.toString();

        if (sOutputFile == null) {
            System.out.println(json);
        } else {
            try {
                PrintStream stream = new PrintStream(new FileOutputStream(sOutputFile, true));
                try {
                    stream.print(json);
                } finally {
                    try {
                        stream.close();
                    } catch (Exception ex) {
                        Log.e("PerfTraceEvent", "Unable to close perf trace output file.");
                    }
                }
            } catch (FileNotFoundException ex) {
                Log.e("PerfTraceEvent", "Unable to dump perf trace data to output file.");
            }
        }
    }
}

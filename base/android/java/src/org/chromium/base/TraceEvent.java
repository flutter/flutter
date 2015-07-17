// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.os.Looper;
import android.os.MessageQueue;
import android.os.SystemClock;
import android.util.Log;
import android.util.Printer;
/**
 * Java mirror of Chrome trace event API. See base/trace_event/trace_event.h. Unlike the native
 * version, Java does not have stack objects, so a TRACE_EVENT() which does both TRACE_EVENT_BEGIN()
 * and TRACE_EVENT_END() in ctor/dtor is not possible.
 * It is OK to use tracing before the native library has loaded, but such traces will
 * be ignored. (Perhaps we could devise to buffer them up in future?).
 */
@JNINamespace("base::android")
public class TraceEvent {

    private static volatile boolean sEnabled = false;
    private static volatile boolean sATraceEnabled = false; // True when taking an Android systrace.

    private static class BasicLooperMonitor implements Printer {
        @Override
        public void println(final String line) {
            if (line.startsWith(">")) {
                beginHandling(line);
            } else {
                assert line.startsWith("<");
                endHandling(line);
            }
        }

        void beginHandling(final String line) {
            if (sEnabled) nativeBeginToplevel();
        }

        void endHandling(final String line) {
            if (sEnabled) nativeEndToplevel();
        }
    }

    /**
     * A class that records, traces and logs statistics about the UI thead's Looper.
     * The output of this class can be used in a number of interesting ways:
     * <p>
     * <ol><li>
     * When using chrometrace, there will be a near-continuous line of
     * measurements showing both event dispatches as well as idles;
     * </li><li>
     * Logging messages are output for events that run too long on the
     * event dispatcher, making it easy to identify problematic areas;
     * </li><li>
     * Statistics are output whenever there is an idle after a non-trivial
     * amount of activity, allowing information to be gathered about task
     * density and execution cadence on the Looper;
     * </li></ol>
     * <p>
     * The class attaches itself as an idle handler to the main Looper, and
     * monitors the execution of events and idle notifications. Task counters
     * accumulate between idle notifications and get reset when a new idle
     * notification is received.
     */
    private static final class IdleTracingLooperMonitor extends BasicLooperMonitor
            implements MessageQueue.IdleHandler {
        // Tags for dumping to logcat or TraceEvent
        private static final String TAG = "TraceEvent.LooperMonitor";
        private static final String IDLE_EVENT_NAME = "Looper.queueIdle";

        // Calculation constants
        private static final long FRAME_DURATION_MILLIS = 1000L / 60L; // 60 FPS
        // A reasonable threshold for defining a Looper event as "long running"
        private static final long MIN_INTERESTING_DURATION_MILLIS =
                FRAME_DURATION_MILLIS;
        // A reasonable threshold for a "burst" of tasks on the Looper
        private static final long MIN_INTERESTING_BURST_DURATION_MILLIS =
                MIN_INTERESTING_DURATION_MILLIS * 3;

        // Stats tracking
        private long mLastIdleStartedAt = 0L;
        private long mLastWorkStartedAt = 0L;
        private int mNumTasksSeen = 0;
        private int mNumIdlesSeen = 0;
        private int mNumTasksSinceLastIdle = 0;

        // State
        private boolean mIdleMonitorAttached = false;

        // Called from within the begin/end methods only.
        // This method can only execute on the looper thread, because that is
        // the only thread that is permitted to call Looper.myqueue().
        private final void syncIdleMonitoring() {
            if (sEnabled && !mIdleMonitorAttached) {
                // approximate start time for computational purposes
                mLastIdleStartedAt = SystemClock.elapsedRealtime();
                Looper.myQueue().addIdleHandler(this);
                mIdleMonitorAttached = true;
                Log.v(TAG, "attached idle handler");
            } else if (mIdleMonitorAttached && !sEnabled) {
                Looper.myQueue().removeIdleHandler(this);
                mIdleMonitorAttached = false;
                Log.v(TAG, "detached idle handler");
            }
        }

        @Override
        final void beginHandling(final String line) {
            // Close-out any prior 'idle' period before starting new task.
            if (mNumTasksSinceLastIdle == 0) {
                TraceEvent.end(IDLE_EVENT_NAME);
            }
            mLastWorkStartedAt = SystemClock.elapsedRealtime();
            syncIdleMonitoring();
            super.beginHandling(line);
        }

        @Override
        final void endHandling(final String line) {
            final long elapsed = SystemClock.elapsedRealtime()
                    - mLastWorkStartedAt;
            if (elapsed > MIN_INTERESTING_DURATION_MILLIS) {
                traceAndLog(Log.WARN, "observed a task that took "
                        + elapsed + "ms: " + line);
            }
            super.endHandling(line);
            syncIdleMonitoring();
            mNumTasksSeen++;
            mNumTasksSinceLastIdle++;
        }

        private static void traceAndLog(int level, String message) {
            TraceEvent.instant("TraceEvent.LooperMonitor:IdleStats", message);
            Log.println(level, TAG, message);
        }

        @Override
        public final boolean queueIdle() {
            final long now =  SystemClock.elapsedRealtime();
            if (mLastIdleStartedAt == 0) mLastIdleStartedAt = now;
            final long elapsed = now - mLastIdleStartedAt;
            mNumIdlesSeen++;
            TraceEvent.begin(IDLE_EVENT_NAME, mNumTasksSinceLastIdle + " tasks since last idle.");
            if (elapsed > MIN_INTERESTING_BURST_DURATION_MILLIS) {
                // Dump stats
                String statsString = mNumTasksSeen + " tasks and "
                        + mNumIdlesSeen + " idles processed so far, "
                        + mNumTasksSinceLastIdle + " tasks bursted and "
                        + elapsed + "ms elapsed since last idle";
                traceAndLog(Log.DEBUG, statsString);
            }
            mLastIdleStartedAt = now;
            mNumTasksSinceLastIdle = 0;
            return true; // stay installed
        }
    }

    // Holder for monitor avoids unnecessary construction on non-debug runs
    private static final class LooperMonitorHolder {
        private static final BasicLooperMonitor sInstance =
                CommandLine.getInstance().hasSwitch(BaseSwitches.ENABLE_IDLE_TRACING)
                ? new IdleTracingLooperMonitor() : new BasicLooperMonitor();
    }


    /**
     * Register an enabled observer, such that java traces are always enabled with native.
     */
    public static void registerNativeEnabledObserver() {
        nativeRegisterEnabledObserver();
    }

    /**
     * Notification from native that tracing is enabled/disabled.
     */
    @CalledByNative
    public static void setEnabled(boolean enabled) {
        sEnabled = enabled;
        // Android M+ systrace logs this on its own. Only log it if not writing to Android systrace.
        if (sATraceEnabled) return;
        ThreadUtils.getUiThreadLooper().setMessageLogging(
                enabled ? LooperMonitorHolder.sInstance : null);
    }

    /**
     * Enables or disabled Android systrace path of Chrome tracing. If enabled, all Chrome
     * traces will be also output to Android systrace. Because of the overhead of Android
     * systrace, this is for WebView only.
     */
    public static void setATraceEnabled(boolean enabled) {
        if (sATraceEnabled == enabled) return;
        sATraceEnabled = enabled;
        if (enabled) {
            // Calls TraceEvent.setEnabled(true) via
            // TraceLog::EnabledStateObserver::OnTraceLogEnabled
            nativeStartATrace();
        } else {
            // Calls TraceEvent.setEnabled(false) via
            // TraceLog::EnabledStateObserver::OnTraceLogDisabled
            nativeStopATrace();
        }
    }

    /**
     * @return True if tracing is enabled, false otherwise.
     * It is safe to call trace methods without checking if TraceEvent
     * is enabled.
     */
    public static boolean enabled() {
        return sEnabled;
    }

    /**
     * Triggers the 'instant' native trace event with no arguments.
     * @param name The name of the event.
     */
    public static void instant(String name) {
        if (sEnabled) nativeInstant(name, null);
    }

    /**
     * Triggers the 'instant' native trace event.
     * @param name The name of the event.
     * @param arg  The arguments of the event.
     */
    public static void instant(String name, String arg) {
        if (sEnabled) nativeInstant(name, arg);
    }

    /**
     * Triggers the 'start' native trace event with no arguments.
     * @param name The name of the event.
     * @param id   The id of the asynchronous event.
     */
    public static void startAsync(String name, long id) {
        if (sEnabled) nativeStartAsync(name, id);
    }

    /**
     * Triggers the 'finish' native trace event with no arguments.
     * @param name The name of the event.
     * @param id   The id of the asynchronous event.
     */
    public static void finishAsync(String name, long id) {
        if (sEnabled) nativeFinishAsync(name, id);
    }

    /**
     * Triggers the 'begin' native trace event with no arguments.
     * @param name The name of the event.
     */
    public static void begin(String name) {
        if (sEnabled) nativeBegin(name, null);
    }

    /**
     * Triggers the 'begin' native trace event.
     * @param name The name of the event.
     * @param arg  The arguments of the event.
     */
    public static void begin(String name, String arg) {
        if (sEnabled) nativeBegin(name, arg);
    }

    /**
     * Triggers the 'end' native trace event with no arguments.
     * @param name The name of the event.
     */
    public static void end(String name) {
        if (sEnabled) nativeEnd(name, null);
    }

    /**
     * Triggers the 'end' native trace event.
     * @param name The name of the event.
     * @param arg  The arguments of the event.
     */
    public static void end(String name, String arg) {
        if (sEnabled) nativeEnd(name, arg);
    }

    private static native void nativeRegisterEnabledObserver();
    private static native void nativeStartATrace();
    private static native void nativeStopATrace();
    private static native void nativeInstant(String name, String arg);
    private static native void nativeBegin(String name, String arg);
    private static native void nativeEnd(String name, String arg);
    private static native void nativeBeginToplevel();
    private static native void nativeEndToplevel();
    private static native void nativeStartAsync(String name, long id);
    private static native void nativeFinishAsync(String name, long id);
}

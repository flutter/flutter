// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import org.chromium.base.annotations.RemovableInRelease;

import java.util.Locale;

/**
 * Utility class for Logging.
 *
 * <p>
 * Defines logging access points for each feature. They format and forward the logs to
 * {@link android.util.Log}, allowing to standardize the output, to make it easy to identify
 * the origin of logs, and enable or disable logging in different parts of the code.
 * </p>
 * <p>
 * @see usage documentation: <a href="README_logging.md">README_logging.md</a>.
 * </p>
 */
public class Log {
    /** Convenience property, same as {@link android.util.Log#ASSERT}. */
    public static final int ASSERT = android.util.Log.ASSERT;

    /** Convenience property, same as {@link android.util.Log#DEBUG}. */
    public static final int DEBUG = android.util.Log.DEBUG;

    /** Convenience property, same as {@link android.util.Log#ERROR}. */
    public static final int ERROR = android.util.Log.ERROR;

    /** Convenience property, same as {@link android.util.Log#INFO}. */
    public static final int INFO = android.util.Log.INFO;

    /** Convenience property, same as {@link android.util.Log#VERBOSE}. */
    public static final int VERBOSE = android.util.Log.VERBOSE;

    /** Convenience property, same as {@link android.util.Log#WARN}. */
    public static final int WARN = android.util.Log.WARN;

    private Log() {
        // Static only access
    }

    /** Returns a formatted log message, using the supplied format and arguments.*/
    private static String formatLog(String messageTemplate, Object... params) {
        if (params != null && params.length != 0) {
            messageTemplate = String.format(Locale.US, messageTemplate, params);
        }

        return messageTemplate;
    }

    /**
     * Returns a formatted log message, using the supplied format and arguments.
     * The message will be prepended with the filename and line number of the call.
     */
    private static String formatLogWithStack(String messageTemplate, Object... params) {
        return "[" + getCallOrigin() + "] " + formatLog(messageTemplate, params);
    }

    /** Convenience function, forwards to {@link android.util.Log#isLoggable(String, int)}. */
    public static boolean isLoggable(String tag, int level) {
        return android.util.Log.isLoggable(tag, level);
    }

    /**
     * Sends a {@link android.util.Log#VERBOSE} log message.
     *
     * For optimization purposes, only the fixed parameters versions are visible. If you need more
     * than 7 parameters, consider building your log message using a function annotated with
     * {@link RemovableInRelease}.
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    private static void verbose(String tag, String messageTemplate, Object... args) {
        if (Log.isLoggable(tag, Log.VERBOSE)) {
            String message = formatLogWithStack(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.v(tag, message, tr);
            } else {
                android.util.Log.v(tag, message);
            }
        }
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 0 args version. */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String message) {
        verbose(tag, message);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 1 arg version. */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1) {
        verbose(tag, messageTemplate, arg1);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 2 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1, Object arg2) {
        verbose(tag, messageTemplate, arg1, arg2);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 3 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(
            String tag, String messageTemplate, Object arg1, Object arg2, Object arg3) {
        verbose(tag, messageTemplate, arg1, arg2, arg3);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 4 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4) {
        verbose(tag, messageTemplate, arg1, arg2, arg3, arg4);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 5 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5) {
        verbose(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 6 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5, Object arg6) {
        verbose(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5, arg6);
    }

    /** Sends a {@link android.util.Log#VERBOSE} log message. 7 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void v(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5, Object arg6, Object arg7) {
        verbose(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
    }

    /**
     * Sends a {@link android.util.Log#DEBUG} log message.
     *
     * For optimization purposes, only the fixed parameters versions are visible. If you need more
     * than 7 parameters, consider building your log message using a function annotated with
     * {@link RemovableInRelease}.
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    private static void debug(String tag, String messageTemplate, Object... args) {
        if (isLoggable(tag, Log.DEBUG)) {
            String message = formatLogWithStack(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.d(tag, message, tr);
            } else {
                android.util.Log.d(tag, message);
            }
        }
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 0 args version. */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String message) {
        debug(tag, message);
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 1 arg version. */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1) {
        debug(tag, messageTemplate, arg1);
    }
    /** Sends a {@link android.util.Log#DEBUG} log message. 2 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1, Object arg2) {
        debug(tag, messageTemplate, arg1, arg2);
    }
    /** Sends a {@link android.util.Log#DEBUG} log message. 3 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(
            String tag, String messageTemplate, Object arg1, Object arg2, Object arg3) {
        debug(tag, messageTemplate, arg1, arg2, arg3);
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 4 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4) {
        debug(tag, messageTemplate, arg1, arg2, arg3, arg4);
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 5 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5) {
        debug(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5);
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 6 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5, Object arg6) {
        debug(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5, arg6);
    }

    /** Sends a {@link android.util.Log#DEBUG} log message. 7 args version */
    @RemovableInRelease
    @VisibleForTesting
    public static void d(String tag, String messageTemplate, Object arg1, Object arg2, Object arg3,
            Object arg4, Object arg5, Object arg6, Object arg7) {
        debug(tag, messageTemplate, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
    }

    /**
     * Sends an {@link android.util.Log#INFO} log message.
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    @VisibleForTesting
    public static void i(String tag, String messageTemplate, Object... args) {
        if (Log.isLoggable(tag, Log.INFO)) {
            String message = formatLog(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.i(tag, message, tr);
            } else {
                android.util.Log.i(tag, message);
            }
        }
    }

    /**
     * Sends a {@link android.util.Log#WARN} log message.
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    @VisibleForTesting
    public static void w(String tag, String messageTemplate, Object... args) {
        if (Log.isLoggable(tag, Log.WARN)) {
            String message = formatLog(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.w(tag, message, tr);
            } else {
                android.util.Log.w(tag, message);
            }
        }
    }

    /**
     * Sends an {@link android.util.Log#ERROR} log message.
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    @VisibleForTesting
    public static void e(String tag, String messageTemplate, Object... args) {
        if (Log.isLoggable(tag, Log.ERROR)) {
            String message = formatLog(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.e(tag, message, tr);
            } else {
                android.util.Log.e(tag, message);
            }
        }
    }

    /**
     * What a Terrible Failure: Used for conditions that should never happen, and logged at
     * the {@link android.util.Log#ASSERT} level. Depending on the configuration, it might
     * terminate the process.
     *
     * @see android.util.Log#wtf(String, String, Throwable)
     *
     * @param tag Used to identify the source of a log message.
     * @param messageTemplate The message you would like logged. It is to be specified as a format
     *                        string.
     * @param args Arguments referenced by the format specifiers in the format string. If the last
     *             one is a {@link Throwable}, its trace will be printed.
     */
    @VisibleForTesting
    public static void wtf(String tag, String messageTemplate, Object... args) {
        if (Log.isLoggable(tag, Log.ASSERT)) {
            String message = formatLog(messageTemplate, args);
            Throwable tr = getThrowableToLog(args);
            if (tr != null) {
                android.util.Log.wtf(tag, message, tr);
            } else {
                android.util.Log.wtf(tag, message);
            }
        }
    }

    private static Throwable getThrowableToLog(Object[] args) {
        if (args == null || args.length == 0) return null;

        Object lastArg = args[args.length - 1];

        if (!(lastArg instanceof Throwable)) return null;
        return (Throwable) lastArg;
    }

    /** Returns a string form of the origin of the log call, to be used as secondary tag.*/
    private static String getCallOrigin() {
        StackTraceElement[] st = Thread.currentThread().getStackTrace();

        // The call stack should look like:
        //   n [a variable number of calls depending on the vm used]
        //  +0 getCallOrigin()
        //  +1 privateLogFunction: verbose or debug
        //  +2 formatLogWithStack()
        //  +3 logFunction: v or d
        //  +4 caller

        int callerStackIndex;
        String logClassName = Log.class.getName();
        for (callerStackIndex = 0; callerStackIndex < st.length; callerStackIndex++) {
            if (st[callerStackIndex].getClassName().equals(logClassName)) {
                callerStackIndex += 4;
                break;
            }
        }

        return st[callerStackIndex].getFileName() + ":" + st[callerStackIndex].getLineNumber();
    }
}

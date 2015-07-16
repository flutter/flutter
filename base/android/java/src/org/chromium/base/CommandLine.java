// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Java mirror of base/command_line.h.
 * Android applications don't have command line arguments. Instead, they're "simulated" by reading a
 * file at a specific location early during startup. Applications each define their own files, e.g.,
 * ContentShellApplication.COMMAND_LINE_FILE or ChromeShellApplication.COMMAND_LINE_FILE.
**/
public abstract class CommandLine {
    // Public abstract interface, implemented in derived classes.
    // All these methods reflect their native-side counterparts.
    /**
     *  Returns true if this command line contains the given switch.
     *  (Switch names ARE case-sensitive).
     */
    @VisibleForTesting
    public abstract boolean hasSwitch(String switchString);

    /**
     * Return the value associated with the given switch, or null.
     * @param switchString The switch key to lookup. It should NOT start with '--' !
     * @return switch value, or null if the switch is not set or set to empty.
     */
    public abstract String getSwitchValue(String switchString);

    /**
     * Return the value associated with the given switch, or {@code defaultValue} if the switch
     * was not specified.
     * @param switchString The switch key to lookup. It should NOT start with '--' !
     * @param defaultValue The default value to return if the switch isn't set.
     * @return Switch value, or {@code defaultValue} if the switch is not set or set to empty.
     */
    public String getSwitchValue(String switchString, String defaultValue) {
        String value = getSwitchValue(switchString);
        return TextUtils.isEmpty(value) ? defaultValue : value;
    }

    /**
     * Append a switch to the command line.  There is no guarantee
     * this action happens before the switch is needed.
     * @param switchString the switch to add.  It should NOT start with '--' !
     */
    @VisibleForTesting
    public abstract void appendSwitch(String switchString);

    /**
     * Append a switch and value to the command line.  There is no
     * guarantee this action happens before the switch is needed.
     * @param switchString the switch to add.  It should NOT start with '--' !
     * @param value the value for this switch.
     * For example, --foo=bar becomes 'foo', 'bar'.
     */
    public abstract void appendSwitchWithValue(String switchString, String value);

    /**
     * Append switch/value items in "command line" format (excluding argv[0] program name).
     * E.g. { '--gofast', '--username=fred' }
     * @param array an array of switch or switch/value items in command line format.
     *   Unlike the other append routines, these switches SHOULD start with '--' .
     *   Unlike init(), this does not include the program name in array[0].
     */
    public abstract void appendSwitchesAndArguments(String[] array);

    /**
     * Determine if the command line is bound to the native (JNI) implementation.
     * @return true if the underlying implementation is delegating to the native command line.
     */
    public boolean isNativeImplementation() {
        return false;
    }

    private static final AtomicReference<CommandLine> sCommandLine =
            new AtomicReference<CommandLine>();

    /**
     * @returns true if the command line has already been initialized.
     */
    public static boolean isInitialized() {
        return sCommandLine.get() != null;
    }

    // Equivalent to CommandLine::ForCurrentProcess in C++.
    @VisibleForTesting
    public static CommandLine getInstance() {
        CommandLine commandLine = sCommandLine.get();
        assert commandLine != null;
        return commandLine;
    }

    /**
     * Initialize the singleton instance, must be called exactly once (either directly or
     * via one of the convenience wrappers below) before using the static singleton instance.
     * @param args command line flags in 'argv' format: args[0] is the program name.
     */
    public static void init(String[] args) {
        setInstance(new JavaCommandLine(args));
    }

    /**
     * Initialize the command line from the command-line file.
     *
     * @param file The fully qualified command line file.
     */
    public static void initFromFile(String file) {
        // Arbitrary clamp of 8k on the amount of file we read in.
        char[] buffer = readUtf8FileFully(file, 8 * 1024);
        init(buffer == null ? null : tokenizeQuotedAruments(buffer));
    }

    /**
     * Resets both the java proxy and the native command lines. This allows the entire
     * command line initialization to be re-run including the call to onJniLoaded.
     */
    @VisibleForTesting
    public static void reset() {
        setInstance(null);
    }

    /**
     * Public for testing (TODO: why are the tests in a different package?)
     * Parse command line flags from a flat buffer, supporting double-quote enclosed strings
     * containing whitespace. argv elements are derived by splitting the buffer on whitepace;
     * double quote characters may enclose tokens containing whitespace; a double-quote literal
     * may be escaped with back-slash. (Otherwise backslash is taken as a literal).
     * @param buffer A command line in command line file format as described above.
     * @return the tokenized arguments, suitable for passing to init().
     */
    public static String[] tokenizeQuotedAruments(char[] buffer) {
        ArrayList<String> args = new ArrayList<String>();
        StringBuilder arg = null;
        final char noQuote = '\0';
        final char singleQuote = '\'';
        final char doubleQuote = '"';
        char currentQuote = noQuote;
        for (char c : buffer) {
            // Detect start or end of quote block.
            if ((currentQuote == noQuote && (c == singleQuote || c == doubleQuote))
                    || c == currentQuote) {
                if (arg != null && arg.length() > 0 && arg.charAt(arg.length() - 1) == '\\') {
                    // Last char was a backslash; pop it, and treat c as a literal.
                    arg.setCharAt(arg.length() - 1, c);
                } else {
                    currentQuote = currentQuote == noQuote ? c : noQuote;
                }
            } else if (currentQuote == noQuote && Character.isWhitespace(c)) {
                if (arg != null) {
                    args.add(arg.toString());
                    arg = null;
                }
            } else {
                if (arg == null) arg = new StringBuilder();
                arg.append(c);
            }
        }
        if (arg != null) {
            if (currentQuote != noQuote) {
                Log.w(TAG, "Unterminated quoted string: " + arg);
            }
            args.add(arg.toString());
        }
        return args.toArray(new String[args.size()]);
    }

    private static final String TAG = "CommandLine";
    private static final String SWITCH_PREFIX = "--";
    private static final String SWITCH_TERMINATOR = SWITCH_PREFIX;
    private static final String SWITCH_VALUE_SEPARATOR = "=";

    public static void enableNativeProxy() {
        // Make a best-effort to ensure we make a clean (atomic) switch over from the old to
        // the new command line implementation. If another thread is modifying the command line
        // when this happens, all bets are off. (As per the native CommandLine).
        sCommandLine.set(new NativeCommandLine());
    }

    public static String[] getJavaSwitchesOrNull() {
        CommandLine commandLine = sCommandLine.get();
        if (commandLine != null) {
            assert !commandLine.isNativeImplementation();
            return ((JavaCommandLine) commandLine).getCommandLineArguments();
        }
        return null;
    }

    private static void setInstance(CommandLine commandLine) {
        CommandLine oldCommandLine = sCommandLine.getAndSet(commandLine);
        if (oldCommandLine != null && oldCommandLine.isNativeImplementation()) {
            nativeReset();
        }
    }

    /**
     * @param fileName the file to read in.
     * @param sizeLimit cap on the file size.
     * @return Array of chars read from the file, or null if the file cannot be read
     *         or if its length exceeds |sizeLimit|.
     */
    private static char[] readUtf8FileFully(String fileName, int sizeLimit) {
        Reader reader = null;
        File f = new File(fileName);
        long fileLength = f.length();

        if (fileLength == 0) {
            return null;
        }

        if (fileLength > sizeLimit) {
            Log.w(TAG, "File " + fileName + " length " + fileLength + " exceeds limit "
                    + sizeLimit);
            return null;
        }

        try {
            char[] buffer = new char[(int) fileLength];
            reader = new InputStreamReader(new FileInputStream(f), "UTF-8");
            int charsRead = reader.read(buffer);
            // Debug check that we've exhausted the input stream (will fail e.g. if the
            // file grew after we inspected its length).
            assert !reader.ready();
            return charsRead < buffer.length ? Arrays.copyOfRange(buffer, 0, charsRead) : buffer;
        } catch (FileNotFoundException e) {
            return null;
        } catch (IOException e) {
            return null;
        } finally {
            try {
                if (reader != null) reader.close();
            } catch (IOException e) {
                Log.e(TAG, "Unable to close file reader.", e);
            }
        }
    }

    private CommandLine() {}

    private static class JavaCommandLine extends CommandLine {
        private HashMap<String, String> mSwitches = new HashMap<String, String>();
        private ArrayList<String> mArgs = new ArrayList<String>();

        // The arguments begin at index 1, since index 0 contains the executable name.
        private int mArgsBegin = 1;

        JavaCommandLine(String[] args) {
            if (args == null || args.length == 0 || args[0] == null) {
                mArgs.add("");
            } else {
                mArgs.add(args[0]);
                appendSwitchesInternal(args, 1);
            }
            // Invariant: we always have the argv[0] program name element.
            assert mArgs.size() > 0;
        }

        /**
         * Returns the switches and arguments passed into the program, with switches and their
         * values coming before all of the arguments.
         */
        private String[] getCommandLineArguments() {
            return mArgs.toArray(new String[mArgs.size()]);
        }

        @Override
        public boolean hasSwitch(String switchString) {
            return mSwitches.containsKey(switchString);
        }

        @Override
        public String getSwitchValue(String switchString) {
            // This is slightly round about, but needed for consistency with the NativeCommandLine
            // version which does not distinguish empty values from key not present.
            String value = mSwitches.get(switchString);
            return value == null || value.isEmpty() ? null : value;
        }

        @Override
        public void appendSwitch(String switchString) {
            appendSwitchWithValue(switchString, null);
        }

        /**
         * Appends a switch to the current list.
         * @param switchString the switch to add.  It should NOT start with '--' !
         * @param value the value for this switch.
         */
        @Override
        public void appendSwitchWithValue(String switchString, String value) {
            mSwitches.put(switchString, value == null ? "" : value);

            // Append the switch and update the switches/arguments divider mArgsBegin.
            String combinedSwitchString = SWITCH_PREFIX + switchString;
            if (value != null && !value.isEmpty()) {
                combinedSwitchString += SWITCH_VALUE_SEPARATOR + value;
            }

            mArgs.add(mArgsBegin++, combinedSwitchString);
        }

        @Override
        public void appendSwitchesAndArguments(String[] array) {
            appendSwitchesInternal(array, 0);
        }

        // Add the specified arguments, but skipping the first |skipCount| elements.
        private void appendSwitchesInternal(String[] array, int skipCount) {
            boolean parseSwitches = true;
            for (String arg : array) {
                if (skipCount > 0) {
                    --skipCount;
                    continue;
                }

                if (arg.equals(SWITCH_TERMINATOR)) {
                    parseSwitches = false;
                }

                if (parseSwitches && arg.startsWith(SWITCH_PREFIX)) {
                    String[] parts = arg.split(SWITCH_VALUE_SEPARATOR, 2);
                    String value = parts.length > 1 ? parts[1] : null;
                    appendSwitchWithValue(parts[0].substring(SWITCH_PREFIX.length()), value);
                } else {
                    mArgs.add(arg);
                }
            }
        }
    }

    private static class NativeCommandLine extends CommandLine {
        @Override
        public boolean hasSwitch(String switchString) {
            return nativeHasSwitch(switchString);
        }

        @Override
        public String getSwitchValue(String switchString) {
            return nativeGetSwitchValue(switchString);
        }

        @Override
        public void appendSwitch(String switchString) {
            nativeAppendSwitch(switchString);
        }

        @Override
        public void appendSwitchWithValue(String switchString, String value) {
            nativeAppendSwitchWithValue(switchString, value);
        }

        @Override
        public void appendSwitchesAndArguments(String[] array) {
            nativeAppendSwitchesAndArguments(array);
        }

        @Override
        public boolean isNativeImplementation() {
            return true;
        }
    }

    private static native void nativeReset();
    private static native boolean nativeHasSwitch(String switchString);
    private static native String nativeGetSwitchValue(String switchString);
    private static native void nativeAppendSwitch(String switchString);
    private static native void nativeAppendSwitchWithValue(String switchString, String value);
    private static native void nativeAppendSwitchesAndArguments(String[] array);
}

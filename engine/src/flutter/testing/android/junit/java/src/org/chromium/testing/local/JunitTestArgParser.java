// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import java.io.File;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Pattern;

/**
 *  Parses command line arguments for JunitTestMain.
 */
public class JunitTestArgParser {

    private static final Pattern COLON = Pattern.compile(":");

    private final Set<String> mPackageFilters;
    private final Set<Class<?>> mRunnerFilters;
    private final Set<String> mGtestFilters;
    private File mJsonOutput;
    private String[] mTestJars;

    public static JunitTestArgParser parse(String[] args) {

        JunitTestArgParser parsed = new JunitTestArgParser();

        for (int i = 0; i < args.length; ++i) {
            if (args[i].startsWith("-")) {
                String argName;
                if (args[i].startsWith("-", 1)) {
                    argName = args[i].substring(2, args[i].length());
                } else {
                    argName = args[i].substring(1, args[i].length());
                }
                try {
                    if ("package-filter".equals(argName)) {
                        // Read the command line argument after the flag.
                        parsed.addPackageFilter(args[++i]);
                    } else if ("runner-filter".equals(argName)) {
                        // Read the command line argument after the flag.
                        parsed.addRunnerFilter(Class.forName(args[++i]));
                    } else if ("gtest-filter".equals(argName)) {
                        // Read the command line argument after the flag.
                        parsed.addGtestFilter(args[++i]);
                    } else if ("json-results-file".equals(argName)) {
                        // Read the command line argument after the flag.
                        parsed.setJsonOutputFile(args[++i]);
                    } else if ("test-jars".equals(argName)) {
                        // Read the command line argument after the flag.
                        parsed.setTestJars(args[++i]);
                    } else {
                        System.out.println("Ignoring flag: \"" + argName + "\"");
                    }
                } catch (ArrayIndexOutOfBoundsException e) {
                    System.err.println("No value specified for argument \"" + argName + "\"");
                    System.exit(1);
                } catch (ClassNotFoundException e) {
                    System.err.println("Class not found. (" + e.toString() + ")");
                    System.exit(1);
                }
            } else {
                System.out.println("Ignoring argument: \"" + args[i] + "\"");
            }
        }

        return parsed;
    }

    private JunitTestArgParser() {
        mPackageFilters = new HashSet<String>();
        mRunnerFilters = new HashSet<Class<?>>();
        mGtestFilters = new HashSet<String>();
        mJsonOutput = null;
    }

    public Set<String> getPackageFilters() {
        return mPackageFilters;
    }

    public Set<Class<?>> getRunnerFilters() {
        return mRunnerFilters;
    }

    public Set<String> getGtestFilters() {
        return mGtestFilters;
    }

    public File getJsonOutputFile() {
        return mJsonOutput;
    }

    public String[] getTestJars() {
        return mTestJars;
    }

    private void addPackageFilter(String packageFilter) {
        mPackageFilters.add(packageFilter);
    }

    private void addRunnerFilter(Class<?> runnerFilter) {
        mRunnerFilters.add(runnerFilter);
    }

    private void addGtestFilter(String gtestFilter) {
        mGtestFilters.add(gtestFilter);
    }

    private void setJsonOutputFile(String path) {
        mJsonOutput = new File(path);
    }

    private void setTestJars(String jars) {
        mTestJars = COLON.split(jars);
    }
}
// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.testing.local;

import org.junit.runner.Description;
import org.junit.runner.manipulation.Filter;

import java.util.HashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *  Filters tests based on a googletest-style filter string.
 */
class GtestFilter extends Filter {

    private final String mFilterString;

    private final Set<Pattern> mPositiveRegexes;
    private final Set<Pattern> mNegativeRegexes;

    private static final Pattern ASTERISK = Pattern.compile("\\*");
    private static final Pattern COLON = Pattern.compile(":");
    private static final Pattern DASH = Pattern.compile("-");
    private static final Pattern DOLLAR = Pattern.compile("\\$");
    private static final Pattern PERIOD = Pattern.compile("\\.");

    /**
     *  Creates the filter and converts the provided googletest-style filter
     *  string into positive and negative regexes.
     */
    public GtestFilter(String filterString) {
        mFilterString = filterString;
        mPositiveRegexes = new HashSet<Pattern>();
        mNegativeRegexes = new HashSet<Pattern>();

        String[] filterStrings = COLON.split(filterString);
        for (String f : filterStrings) {
            if (f.isEmpty()) continue;

            String sanitized = PERIOD.matcher(f).replaceAll(Matcher.quoteReplacement("\\."));
            sanitized = DOLLAR.matcher(sanitized).replaceAll(Matcher.quoteReplacement("\\$"));
            sanitized = ASTERISK.matcher(sanitized).replaceAll(".*");
            int negIndex = sanitized.indexOf('-');
            if (negIndex == 0) {
                mNegativeRegexes.add(Pattern.compile(sanitized.substring(1)));
            } else if (negIndex != -1) {
                String[] c = DASH.split(sanitized, 2);
                mPositiveRegexes.add(Pattern.compile(c[0]));
                mNegativeRegexes.add(Pattern.compile(c[1]));
            } else {
                mPositiveRegexes.add(Pattern.compile(sanitized));
            }
        }
    }

    /**
     *  Determines whether or not a test with the provided description should
     *  run based on the configured positive and negative regexes.
     *
     *  A test should run if:
     *    - it's just a class, OR
     *    - it doesn't match any of the negative regexes, AND
     *    - either:
     *      - there are no configured positive regexes, OR
     *      - it matches at least one of the positive regexes.
     */
    @Override
    public boolean shouldRun(Description description) {
        if (description.getMethodName() == null) return true;

        String gtestName = description.getClassName() + "." + description.getMethodName();
        for (Pattern p : mNegativeRegexes) {
            if (p.matcher(gtestName).matches()) return false;
        }

        if (mPositiveRegexes.isEmpty()) return true;

        for (Pattern p : mPositiveRegexes) {
            if (p.matcher(gtestName).matches()) return true;
        }

        return false;
    }

    /**
     *  Returns a description of this filter.
     */
    @Override
    public String describe() {
        return "gtest-filter: " + mFilterString;
    }

}


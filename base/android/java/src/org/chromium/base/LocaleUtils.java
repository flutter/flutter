// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import java.util.Locale;

/**
 * This class provides the locale related methods.
 */
public class LocaleUtils {
    /**
     * Guards this class from being instantiated.
     */
    private LocaleUtils() {
    }

    /**
     * @return the default locale, translating Android deprecated
     * language codes into the modern ones used by Chromium.
     */
    @CalledByNative
    public static String getDefaultLocale() {
        Locale locale = Locale.getDefault();
        String language = locale.getLanguage();
        String country = locale.getCountry();

        // Android uses deprecated lanuages codes for Hebrew and Indonesian but Chromium uses the
        // updated codes. Also, Android uses "tl" while Chromium uses "fil" for Tagalog/Filipino.
        // So apply a mapping.
        // See http://developer.android.com/reference/java/util/Locale.html
        if ("iw".equals(language)) {
            language = "he";
        } else if ("in".equals(language)) {
            language = "id";
        } else if ("tl".equals(language)) {
            language = "fil";
        }
        return country.isEmpty() ? language : language + "-" + country;
    }

    /**
     * Get the default country code set during install.
     * @return country code.
     */
    @CalledByNative
    private static String getDefaultCountryCode() {
        CommandLine commandLine = CommandLine.getInstance();
        return commandLine.hasSwitch(BaseSwitches.DEFAULT_COUNTRY_CODE_AT_INSTALL)
                ? commandLine.getSwitchValue(BaseSwitches.DEFAULT_COUNTRY_CODE_AT_INSTALL)
                : Locale.getDefault().getCountry();
    }

}

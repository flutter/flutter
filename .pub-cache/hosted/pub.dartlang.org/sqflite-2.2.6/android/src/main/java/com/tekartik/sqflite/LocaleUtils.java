package com.tekartik.sqflite;

import android.os.Build;

import androidx.annotation.RequiresApi;

import java.util.Locale;

public class LocaleUtils {


    static Locale localeForLanguateTag(String localeString) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return localeForLanguageTag21(localeString);
        } else {
            return localeForLanguageTagPre21(localeString);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    static Locale localeForLanguageTag21(String localeString) {
        return Locale.forLanguageTag(localeString);
    }

    /**
     * Really basic implementation, hopefully not so many dev/apps with such requirements
     * should be impacted.
     *
     * @param localeString
     * @return
     */
    static Locale localeForLanguageTagPre21(String localeString) {
        //Locale.Builder builder = new Locale().Builder();
        String[] parts = localeString.split("-");
        String language = "";
        String country = "";
        String variant = "";
        if (parts.length > 0) {
            language = parts[0];
            if (parts.length > 1) {
                country = parts[1];

                if (parts.length > 2) {
                    variant = parts[parts.length - 1];
                }
            }
        }
        return new Locale(language, country, variant);
    }
}

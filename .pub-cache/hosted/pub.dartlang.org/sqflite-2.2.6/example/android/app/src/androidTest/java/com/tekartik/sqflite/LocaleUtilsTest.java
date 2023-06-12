package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Locale;

/**
 * Instrumented test, which will execute on an Android device.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
@RunWith(AndroidJUnit4.class)
public class LocaleUtilsTest {

    interface CheckLocaleRunnable {
        void run(Locale locale);
    }

    private void check(String languageTag, CheckLocaleRunnable runnable) {
        Locale locale = Utils.localeForLanguageTag21(languageTag);
        runnable.run(locale);
        locale = Utils.localeForLanguageTagPre21(languageTag);
        runnable.run(locale);
        locale = Utils.localeForLanguateTag(languageTag);
        runnable.run(locale);
    }

    @Test
    public void localeForLanguateTag() {
        String enUsPosixTag = "en-US-x-lvariant-POSIX";
        check(enUsPosixTag, locale -> {
            assertEquals("en", locale.getLanguage());
            assertEquals("US", locale.getCountry());
            assertEquals("POSIX", locale.getVariant());
            assertEquals(null, locale.getExtension('x'));
            assertEquals("en-US-POSIX", locale.toLanguageTag());
            assertEquals("en_US_POSIX", locale.toString());
        });


        String chineseTag = Locale.CHINESE.toLanguageTag();
        assertEquals("zh", chineseTag);
        check(chineseTag, locale -> {
            assertEquals("zh", locale.getLanguage());
            assertEquals("", locale.getCountry());
            assertEquals("", locale.getVariant());
            assertEquals("zh", locale.toLanguageTag());
            assertEquals("zh", locale.toString());
        });

        chineseTag = Locale.SIMPLIFIED_CHINESE.toLanguageTag();
        assertEquals("zh-CN", chineseTag);
        check(chineseTag, locale -> {
            assertEquals("zh", locale.getLanguage());
            assertEquals("CN", locale.getCountry());
            assertEquals("", locale.getVariant());
            assertEquals("zh-CN", locale.toLanguageTag());
            assertEquals("zh_CN", locale.toString());
        });

        String franceTag = Locale.FRANCE.toLanguageTag();
        assertEquals("fr-FR", franceTag);
        check(franceTag, locale -> {
            assertEquals("fr", locale.getLanguage());
            assertEquals("FR", locale.getCountry());
            assertEquals("", locale.getVariant());
            assertEquals("fr-FR", locale.toLanguageTag());
            assertEquals("fr_FR", locale.toString());
        });
    }
}

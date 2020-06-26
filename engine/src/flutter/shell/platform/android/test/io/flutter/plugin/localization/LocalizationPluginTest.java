// Part of the embedding.engine package to allow access to FlutterJNI methods.
package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;
import android.os.LocaleList;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.plugin.localization.LocalizationPlugin;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Locale;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
@TargetApi(24) // LocaleList and scriptCode are API 24+.
public class LocalizationPluginTest {
  // This test should be synced with the version for API 24.
  @Test
  public void computePlatformResolvedLocaleAPI26() {
    // --- Test Setup ---
    setApiVersion(26);
    FlutterJNI flutterJNI = new FlutterJNI();

    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    Configuration config = mock(Configuration.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocaleList localeList =
        new LocaleList(new Locale("es", "MX"), new Locale("zh", "CN"), new Locale("en", "US"));
    when(context.getResources()).thenReturn(resources);
    when(resources.getConfiguration()).thenReturn(config);
    when(config.getLocales()).thenReturn(localeList);

    flutterJNI.setLocalizationPlugin(
        new LocalizationPlugin(context, new LocalizationChannel(dartExecutor)));

    // Empty supportedLocales.
    String[] supportedLocales = new String[] {};
    String[] result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 0);

    // Empty preferredLocales.
    supportedLocales =
        new String[] {
          "fr", "FR", "",
          "zh", "", "",
          "en", "CA", ""
        };
    localeList = new LocaleList();
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The first locale is default.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "FR");
    assertEquals(result[2], "");

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "FR");
    assertEquals(result[2], "");

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "fr", "", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "");
    assertEquals(result[2], "");

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"), new Locale("it", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "it");
    assertEquals(result[1], "IT");
    assertEquals(result[2], "");
  }

  // This test should be synced with the version for API 26.
  @Test
  public void computePlatformResolvedLocaleAPI24() {
    // --- Test Setup ---
    setApiVersion(24);
    FlutterJNI flutterJNI = new FlutterJNI();

    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    Configuration config = mock(Configuration.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocaleList localeList =
        new LocaleList(new Locale("es", "MX"), new Locale("zh", "CN"), new Locale("en", "US"));
    when(context.getResources()).thenReturn(resources);
    when(resources.getConfiguration()).thenReturn(config);
    when(config.getLocales()).thenReturn(localeList);

    flutterJNI.setLocalizationPlugin(
        new LocalizationPlugin(context, new LocalizationChannel(dartExecutor)));

    // Empty supportedLocales.
    String[] supportedLocales = new String[] {};
    String[] result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 0);

    // Empty preferredLocales.
    supportedLocales =
        new String[] {
          "fr", "FR", "",
          "zh", "", "",
          "en", "CA", ""
        };
    localeList = new LocaleList();
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The first locale is default.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "FR");
    assertEquals(result[2], "");

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "FR");
    assertEquals(result[2], "");

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "fr", "", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "");
    assertEquals(result[2], "");

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale("fr", "CH"), new Locale("it", "CH"));
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(result.length, 3);
    assertEquals(result[0], "it");
    assertEquals(result[1], "IT");
    assertEquals(result[2], "");
  }

  // Tests the legacy pre API 24 algorithm.
  @Test
  public void computePlatformResolvedLocaleAPI16() {
    // --- Test Setup ---
    setApiVersion(16);
    FlutterJNI flutterJNI = new FlutterJNI();

    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    Configuration config = mock(Configuration.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    Locale userLocale = new Locale("es", "MX");
    when(context.getResources()).thenReturn(resources);
    when(resources.getConfiguration()).thenReturn(config);
    setLegacyLocale(config, userLocale);

    flutterJNI.setLocalizationPlugin(
        new LocalizationPlugin(context, new LocalizationChannel(dartExecutor)));

    // Empty supportedLocales.
    String[] supportedLocales = new String[] {};
    String[] result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 0);

    // Empty null preferred locale.
    supportedLocales =
        new String[] {
          "fr", "FR", "",
          "zh", "", "",
          "en", "CA", ""
        };
    userLocale = null;
    setLegacyLocale(config, userLocale);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The first locale is default.
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "FR");
    assertEquals(result[2], "");

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    userLocale = new Locale("fr", "CH");
    setLegacyLocale(config, userLocale);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 3);
    assertEquals(result[0], "en");
    assertEquals(result[1], "");
    assertEquals(result[2], "");

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    userLocale = new Locale("it", "IT");
    setLegacyLocale(config, userLocale);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 3);
    assertEquals(result[0], "it");
    assertEquals(result[1], "IT");
    assertEquals(result[2], "");

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "fr", "", "",
          "it", "IT", ""
        };
    userLocale = new Locale("fr", "CH");
    setLegacyLocale(config, userLocale);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(result.length, 3);
    assertEquals(result[0], "fr");
    assertEquals(result[1], "");
    assertEquals(result[2], "");
  }

  private static void setApiVersion(int apiVersion) {
    try {
      Field field = Build.VERSION.class.getField("SDK_INT");

      field.setAccessible(true);
      Field modifiersField = Field.class.getDeclaredField("modifiers");
      modifiersField.setAccessible(true);
      modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

      field.set(null, apiVersion);
    } catch (Exception e) {
      assertTrue(false);
    }
  }

  private static void setLegacyLocale(Configuration config, Locale locale) {
    try {
      Field field = config.getClass().getField("locale");
      field.setAccessible(true);
      Field modifiersField = Field.class.getDeclaredField("modifiers");
      modifiersField.setAccessible(true);
      modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

      field.set(config, locale);
    } catch (Exception e) {
      assertTrue(false);
    }
  }
}

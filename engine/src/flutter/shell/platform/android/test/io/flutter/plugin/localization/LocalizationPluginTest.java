package io.flutter.plugin.localization;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.LocaleList;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.Locale;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_24) // LocaleList and scriptCode are API 24+.
public class LocalizationPluginTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  // This test should be synced with the version for API 24.
  @Test
  @Config(sdk = API_LEVELS.API_26)
  public void computePlatformResolvedLocaleAPI26() {
    // --- Test Setup ---
    FlutterJNI flutterJNI = new FlutterJNI();

    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    Configuration config = mock(Configuration.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocaleList localeList =
        new LocaleList(
            new Locale.Builder().setLanguage("es").setRegion("MX").build(),
            new Locale.Builder().setLanguage("zh").setRegion("CN").build(),
            new Locale.Builder().setLanguage("en").setRegion("US").build());
    when(context.getResources()).thenReturn(resources);
    when(resources.getConfiguration()).thenReturn(config);
    when(config.getLocales()).thenReturn(localeList);

    flutterJNI.setLocalizationPlugin(
        new LocalizationPlugin(context, new LocalizationChannel(dartExecutor)));

    // Empty supportedLocales.
    String[] supportedLocales = new String[] {};
    String[] result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(0, result.length);

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
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("FR", result[1]);
    assertEquals("", result[2]);

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale.Builder().setLanguage("fr").setRegion("CH").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("FR", result[1]);
    assertEquals("", result[2]);

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "fr", "", "",
          "it", "IT", ""
        };
    Locale testSecondLocaleFrCh = new Locale.Builder().setLanguage("fr").setRegion("CH").build();
    localeList = new LocaleList(testSecondLocaleFrCh);
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("", result[1]);
    assertEquals("", result[2]);

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "it", "IT", ""
        };
    localeList =
        new LocaleList(
            new Locale.Builder().setLanguage("fr").setRegion("CH").build(),
            new Locale.Builder().setLanguage("it").setRegion("CH").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("it", result[0]);
    assertEquals("IT", result[1]);
    assertEquals("", result[2]);

    supportedLocales =
        new String[] {
          "zh", "CN", "Hans",
          "zh", "HK", "Hant",
        };
    localeList = new LocaleList(new Locale.Builder().setLanguage("zh").setRegion("CN").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(3, result.length);
    assertEquals("zh", result[0]);
    assertEquals("CN", result[1]);
    assertEquals("Hans", result[2]);
  }

  // This test should be synced with the version for API 26.
  @Test
  @Config(minSdk = API_LEVELS.API_24)
  public void computePlatformResolvedLocale_fromAndroidN() {
    // --- Test Setup ---
    FlutterJNI flutterJNI = new FlutterJNI();

    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    Configuration config = mock(Configuration.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocaleList localeList =
        new LocaleList(
            new Locale.Builder().setLanguage("es").setRegion("MX").build(),
            new Locale.Builder().setLanguage("zh").setRegion("CN").build(),
            new Locale.Builder().setLanguage("en").setRegion("US").build());
    when(context.getResources()).thenReturn(resources);
    when(resources.getConfiguration()).thenReturn(config);
    when(config.getLocales()).thenReturn(localeList);

    flutterJNI.setLocalizationPlugin(
        new LocalizationPlugin(context, new LocalizationChannel(dartExecutor)));

    // Empty supportedLocales.
    String[] supportedLocales = new String[] {};
    String[] result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    assertEquals(0, result.length);

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
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("FR", result[1]);
    assertEquals("", result[2]);

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale.Builder().setLanguage("fr").setRegion("CH").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("FR", result[1]);
    assertEquals("", result[2]);

    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "fr", "FR", "",
          "fr", "", "",
          "it", "IT", ""
        };
    localeList = new LocaleList(new Locale.Builder().setLanguage("fr").setRegion("CH").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("fr", result[0]);
    assertEquals("", result[1]);
    assertEquals("", result[2]);

    // Example from https://developer.android.com/guide/topics/resources/multilingual-support#postN
    supportedLocales =
        new String[] {
          "en", "", "",
          "de", "DE", "",
          "es", "ES", "",
          "it", "IT", ""
        };
    localeList =
        new LocaleList(
            new Locale.Builder().setLanguage("fr").setRegion("CH").build(),
            new Locale.Builder().setLanguage("it").setRegion("CH").build());
    when(config.getLocales()).thenReturn(localeList);
    result = flutterJNI.computePlatformResolvedLocale(supportedLocales);
    // The call will use the new (> API 24) algorithm.
    assertEquals(3, result.length);
    assertEquals("it", result[0]);
    assertEquals("IT", result[1]);
    assertEquals("", result[2]);
  }

  @Test
  public void localeFromString_languageOnly() {
    Locale locale = LocalizationPlugin.localeFromString("en");
    assertEquals(locale, new Locale.Builder().setLanguage("en").build());
  }

  @Test
  public void localeFromString_languageAndCountry() {
    Locale locale = LocalizationPlugin.localeFromString("en-US");
    assertEquals(locale, new Locale.Builder().setLanguage("en").setRegion("US").build());
  }

  @Test
  public void localeFromString_languageCountryAndVariant() {
    Locale locale = LocalizationPlugin.localeFromString("zh-Hans-CN");
    Locale testLocale =
        new Locale.Builder().setLanguage("zh").setRegion("CN").setScript("Hans").build();
    assertEquals(locale, testLocale);
  }

  @Test
  public void localeFromString_underscore() {
    Locale locale = LocalizationPlugin.localeFromString("zh_Hans_CN");
    Locale testLocale =
        new Locale.Builder().setLanguage("zh").setRegion("CN").setScript("Hans").build();
    assertEquals(locale, testLocale);
  }

  @Test
  public void localeFromString_additionalVariantsAreIgnored() {
    Locale locale = LocalizationPlugin.localeFromString("de-DE-u-co-phonebk");
    assertEquals(locale, new Locale.Builder().setLanguage("de").setRegion("DE").build());
  }

  @Test
  public void getStringResource_withoutLocale() throws JSONException {
    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocalizationChannel localizationChannel = new LocalizationChannel(dartExecutor);
    LocalizationPlugin plugin = new LocalizationPlugin(context, localizationChannel);

    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    String fakePackageName = "package_name";
    String fakeKey = "test_key";
    int fakeId = 123;

    when(context.getPackageName()).thenReturn(fakePackageName);
    when(context.getResources()).thenReturn(resources);
    when(resources.getIdentifier(fakeKey, "string", fakePackageName)).thenReturn(fakeId);
    when(resources.getString(fakeId)).thenReturn("test_value");

    JSONObject param = new JSONObject();
    param.put("key", fakeKey);

    localizationChannel.handler.onMethodCall(
        new MethodCall("Localization.getStringResource", param), mockResult);

    verify(mockResult).success("test_value");
  }

  @Test
  public void getStringResource_withLocale() throws JSONException {
    Context context = mock(Context.class);
    Context localContext = mock(Context.class);
    Resources resources = mock(Resources.class);
    Resources localResources = mock(Resources.class);
    Configuration configuration = new Configuration();
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocalizationChannel localizationChannel = new LocalizationChannel(dartExecutor);
    LocalizationPlugin plugin = new LocalizationPlugin(context, localizationChannel);

    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    String fakePackageName = "package_name";
    String fakeKey = "test_key";
    int fakeId = 123;

    when(context.getPackageName()).thenReturn(fakePackageName);
    when(context.createConfigurationContext(any())).thenReturn(localContext);
    when(context.getResources()).thenReturn(resources);
    when(localContext.getResources()).thenReturn(localResources);
    when(resources.getConfiguration()).thenReturn(configuration);
    when(localResources.getIdentifier(fakeKey, "string", fakePackageName)).thenReturn(fakeId);
    when(localResources.getString(fakeId)).thenReturn("test_value");

    JSONObject param = new JSONObject();
    param.put("key", fakeKey);
    param.put("locale", "en-US");

    localizationChannel.handler.onMethodCall(
        new MethodCall("Localization.getStringResource", param), mockResult);

    verify(mockResult).success("test_value");
  }

  @Test
  public void getStringResource_nonExistentKey() throws JSONException {
    Context context = mock(Context.class);
    Resources resources = mock(Resources.class);
    DartExecutor dartExecutor = mock(DartExecutor.class);
    LocalizationChannel localizationChannel = new LocalizationChannel(dartExecutor);
    LocalizationPlugin plugin = new LocalizationPlugin(context, localizationChannel);

    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);

    String fakePackageName = "package_name";
    String fakeKey = "test_key";

    when(context.getPackageName()).thenReturn(fakePackageName);
    when(context.getResources()).thenReturn(resources);
    when(resources.getIdentifier(fakeKey, "string", fakePackageName))
        .thenReturn(0); // 0 means not exist

    JSONObject param = new JSONObject();
    param.put("key", fakeKey);

    localizationChannel.handler.onMethodCall(
        new MethodCall("Localization.getStringResource", param), mockResult);

    verify(mockResult).success(null);
  }
}

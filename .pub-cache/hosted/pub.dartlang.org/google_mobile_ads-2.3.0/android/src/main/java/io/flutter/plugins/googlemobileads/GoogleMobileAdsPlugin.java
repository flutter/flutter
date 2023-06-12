// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package io.flutter.plugins.googlemobileads;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import com.google.android.gms.ads.AdInspectorError;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.OnAdInspectorClosedListener;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugins.googlemobileads.FlutterAd.FlutterOverlayAd;
import io.flutter.plugins.googlemobileads.usermessagingplatform.UserMessagingPlatformManager;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Flutter plugin accessing Google Mobile Ads API.
 *
 * <p>Instantiate this in an add to app scenario to gracefully handle activity and context changes.
 */
public class GoogleMobileAdsPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

  private static final String TAG = "GoogleMobileAdsPlugin";

  private static <T> T requireNonNull(T obj) {
    if (obj == null) {
      throw new IllegalArgumentException();
    }
    return obj;
  }

  // This is always null when not using v2 embedding.
  @Nullable private FlutterPluginBinding pluginBinding;
  @Nullable private AdInstanceManager instanceManager;
  @Nullable private AdMessageCodec adMessageCodec;
  @Nullable private AppStateNotifier appStateNotifier;
  @Nullable private UserMessagingPlatformManager userMessagingPlatformManager;
  private final Map<String, NativeAdFactory> nativeAdFactories = new HashMap<>();
  @Nullable private MediationNetworkExtrasProvider mediationNetworkExtrasProvider;
  private final FlutterMobileAdsWrapper flutterMobileAds;
  /**
   * Public constructor for the plugin. Dependency initialization is handled in lifecycle methods
   * below.
   */
  public GoogleMobileAdsPlugin() {
    this.flutterMobileAds = new FlutterMobileAdsWrapper();
  }

  /** Constructor for testing. */
  @VisibleForTesting
  protected GoogleMobileAdsPlugin(
      @Nullable FlutterPluginBinding pluginBinding,
      @Nullable AdInstanceManager instanceManager,
      @NonNull FlutterMobileAdsWrapper flutterMobileAds) {
    this.pluginBinding = pluginBinding;
    this.instanceManager = instanceManager;
    this.flutterMobileAds = flutterMobileAds;
  }

  @VisibleForTesting
  protected GoogleMobileAdsPlugin(@NonNull AppStateNotifier appStateNotifier) {
    this.appStateNotifier = appStateNotifier;
    this.flutterMobileAds = new FlutterMobileAdsWrapper();
  }

  /**
   * Interface used to display a {@link com.google.android.gms.ads.nativead.NativeAd}.
   *
   * <p>Added to a {@link io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin} and creates
   * {@link com.google.android.gms.ads.nativead.NativeAdView}s from Native Ads created in Dart.
   */
  public interface NativeAdFactory {
    /**
     * Creates a {@link com.google.android.gms.ads.nativead.NativeAdView} with a {@link
     * com.google.android.gms.ads.nativead.NativeAd}.
     *
     * @param nativeAd Ad information used to create a {@link
     *     com.google.android.gms.ads.nativead.NativeAd}
     * @param customOptions Used to pass additional custom options to create the {@link
     *     com.google.android.gms.ads.nativead.NativeAdView}. Nullable.
     * @return a {@link com.google.android.gms.ads.nativead.NativeAdView} that is overlaid on top of
     *     the FlutterView
     */
    NativeAdView createNativeAd(NativeAd nativeAd, Map<String, Object> customOptions);
  }

  /**
   * Registers a {@link io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory}
   * used to create {@link com.google.android.gms.ads.nativead.NativeAdView}s from a Native Ad
   * created in Dart.
   *
   * @param engine maintains access to a GoogleMobileAdsPlugin instance
   * @param factoryId a unique identifier for the ad factory. The Native Ad created in Dart includes
   *     a parameter that refers to this.
   * @param nativeAdFactory creates {@link com.google.android.gms.ads.nativead.NativeAdView}s when
   *     Flutter NativeAds are created
   * @return whether the factoryId is unique and the nativeAdFactory was successfully added
   */
  public static boolean registerNativeAdFactory(
      FlutterEngine engine, String factoryId, NativeAdFactory nativeAdFactory) {
    final GoogleMobileAdsPlugin gmaPlugin =
        (GoogleMobileAdsPlugin) engine.getPlugins().get(GoogleMobileAdsPlugin.class);
    return registerNativeAdFactory(gmaPlugin, factoryId, nativeAdFactory);
  }

  /**
   * Registers a {@link MediationNetworkExtrasProvider} used to provide network extras to the plugin
   * when it creates ad requests.
   *
   * @param engine The {@link FlutterEngine} which should have an attached instance of this plugin
   * @param mediationNetworkExtrasProvider The {@link MediationNetworkExtrasProvider} which will be
   *     used to provide network extras when ad requests are created
   * @return whether {@code mediationNetworkExtrasProvider} was registered to a {@code
   *     GoogleMobileAdsPlugin} associated with {@code engine}
   */
  public static boolean registerMediationNetworkExtrasProvider(
      FlutterEngine engine, MediationNetworkExtrasProvider mediationNetworkExtrasProvider) {
    final GoogleMobileAdsPlugin gmaPlugin =
        (GoogleMobileAdsPlugin) engine.getPlugins().get(GoogleMobileAdsPlugin.class);
    if (gmaPlugin == null) {
      return false;
    }
    gmaPlugin.mediationNetworkExtrasProvider = mediationNetworkExtrasProvider;
    if (gmaPlugin.adMessageCodec != null) {
      gmaPlugin.adMessageCodec.setMediationNetworkExtrasProvider(mediationNetworkExtrasProvider);
    }
    return true;
  }

  /**
   * Unregisters any {@link MediationNetworkExtrasProvider} that have been previously registered
   * with the plugin using {@code unregisterMediationNetworkExtrasProvider}.
   *
   * @param engine The {@link FlutterEngine} which should have an attached instance of this plugin
   */
  public static void unregisterMediationNetworkExtrasProvider(FlutterEngine engine) {
    final GoogleMobileAdsPlugin gmaPlugin =
        (GoogleMobileAdsPlugin) engine.getPlugins().get(GoogleMobileAdsPlugin.class);
    if (gmaPlugin == null) {
      return;
    }

    if (gmaPlugin.adMessageCodec != null) {
      gmaPlugin.adMessageCodec.setMediationNetworkExtrasProvider(null);
    }
    gmaPlugin.mediationNetworkExtrasProvider = null;
  }

  private static boolean registerNativeAdFactory(
      GoogleMobileAdsPlugin plugin, String factoryId, NativeAdFactory nativeAdFactory) {
    if (plugin == null) {
      final String message =
          String.format(
              "Could not find a %s instance. The plugin may have not been registered.",
              GoogleMobileAdsPlugin.class.getSimpleName());
      throw new IllegalStateException(message);
    }

    return plugin.addNativeAdFactory(factoryId, nativeAdFactory);
  }

  /**
   * Unregisters a {@link io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory}
   * used to create {@link com.google.android.gms.ads.nativead.NativeAdView}s from a Native Ad
   * created in Dart.
   *
   * @param engine maintains access to a GoogleMobileAdsPlugin instance
   * @param factoryId a unique identifier for the ad factory. The Native ad created in Dart includes
   *     a parameter that refers to this
   * @return the previous {@link
   *     io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory} associated with
   *     this factoryId, or null if there was none for this factoryId
   */
  @Nullable
  public static NativeAdFactory unregisterNativeAdFactory(FlutterEngine engine, String factoryId) {
    final FlutterPlugin gmaPlugin = engine.getPlugins().get(GoogleMobileAdsPlugin.class);
    if (gmaPlugin != null) {
      return ((GoogleMobileAdsPlugin) gmaPlugin).removeNativeAdFactory(factoryId);
    }

    return null;
  }

  private boolean addNativeAdFactory(String factoryId, NativeAdFactory nativeAdFactory) {
    if (nativeAdFactories.containsKey(factoryId)) {
      final String errorMessage =
          String.format(
              "A NativeAdFactory with the following factoryId already exists: %s", factoryId);
      Log.e(GoogleMobileAdsPlugin.class.getSimpleName(), errorMessage);
      return false;
    }

    nativeAdFactories.put(factoryId, nativeAdFactory);
    return true;
  }

  private NativeAdFactory removeNativeAdFactory(String factoryId) {
    return nativeAdFactories.remove(factoryId);
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    pluginBinding = binding;
    adMessageCodec =
        new AdMessageCodec(
            binding.getApplicationContext(),
            new FlutterRequestAgentProvider(binding.getApplicationContext()));
    if (mediationNetworkExtrasProvider != null) {
      adMessageCodec.setMediationNetworkExtrasProvider(mediationNetworkExtrasProvider);
    }
    final MethodChannel channel =
        new MethodChannel(
            binding.getBinaryMessenger(),
            "plugins.flutter.io/google_mobile_ads",
            new StandardMethodCodec(adMessageCodec));
    channel.setMethodCallHandler(this);
    instanceManager = new AdInstanceManager(channel);
    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            "plugins.flutter.io/google_mobile_ads/ad_widget",
            new GoogleMobileAdsViewFactory(instanceManager));
    appStateNotifier = new AppStateNotifier(binding.getBinaryMessenger());
    userMessagingPlatformManager =
        new UserMessagingPlatformManager(
            binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    if (appStateNotifier != null) {
      appStateNotifier.stop();
      appStateNotifier = null;
    }
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    if (instanceManager != null) {
      instanceManager.setActivity(binding.getActivity());
    }
    if (adMessageCodec != null) {
      adMessageCodec.setContext(binding.getActivity());
    }
    if (userMessagingPlatformManager != null) {
      userMessagingPlatformManager.setActivity(binding.getActivity());
    }
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // Use the application context
    if (adMessageCodec != null && pluginBinding != null) {
      adMessageCodec.setContext(pluginBinding.getApplicationContext());
    }
    if (instanceManager != null) {
      instanceManager.setActivity(null);
    }
    if (userMessagingPlatformManager != null) {
      userMessagingPlatformManager.setActivity(null);
    }
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    if (instanceManager != null) {
      instanceManager.setActivity(binding.getActivity());
    }
    if (adMessageCodec != null) {
      adMessageCodec.setContext(binding.getActivity());
    }
    if (userMessagingPlatformManager != null) {
      userMessagingPlatformManager.setActivity(binding.getActivity());
    }
  }

  @Override
  public void onDetachedFromActivity() {
    if (adMessageCodec != null && pluginBinding != null) {
      adMessageCodec.setContext(pluginBinding.getApplicationContext());
    }
    if (instanceManager != null) {
      instanceManager.setActivity(null);
    }
    if (userMessagingPlatformManager != null) {
      userMessagingPlatformManager.setActivity(null);
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    if (instanceManager == null || pluginBinding == null) {
      Log.e(TAG, "method call received before instanceManager initialized: " + call.method);
      return;
    }
    // Use activity as context if available.
    Context context =
        (instanceManager.getActivity() != null)
            ? instanceManager.getActivity()
            : pluginBinding.getApplicationContext();
    switch (call.method) {
      case "_init":
        // Internal init. This is necessary to cleanup state on hot restart.
        instanceManager.disposeAllAds();
        result.success(null);
        break;
      case "MobileAds#initialize":
        flutterMobileAds.initialize(context, new FlutterInitializationListener(result));
        break;
      case "MobileAds#openAdInspector":
        flutterMobileAds.openAdInspector(
            context,
            new OnAdInspectorClosedListener() {
              @Override
              public void onAdInspectorClosed(@Nullable AdInspectorError adInspectorError) {
                if (adInspectorError != null) {
                  String errorCode = Integer.toString(adInspectorError.getCode());
                  result.error(
                      errorCode, adInspectorError.getMessage(), adInspectorError.getDomain());
                } else {
                  result.success(null);
                }
              }
            });
        break;
      case "MobileAds#getRequestConfiguration":
        result.success(flutterMobileAds.getRequestConfiguration());
        break;
      case "MobileAds#updateRequestConfiguration":
        RequestConfiguration.Builder builder = MobileAds.getRequestConfiguration().toBuilder();
        String maxAdContentRating = call.argument("maxAdContentRating");
        Integer tagForChildDirectedTreatment = call.argument("tagForChildDirectedTreatment");
        Integer tagForUnderAgeOfConsent = call.argument("tagForUnderAgeOfConsent");
        List<String> testDeviceIds = call.argument("testDeviceIds");
        if (maxAdContentRating != null) {
          builder.setMaxAdContentRating(maxAdContentRating);
        }
        if (tagForChildDirectedTreatment != null) {
          builder.setTagForChildDirectedTreatment(tagForChildDirectedTreatment);
        }
        if (tagForUnderAgeOfConsent != null) {
          builder.setTagForUnderAgeOfConsent(tagForUnderAgeOfConsent);
        }
        if (testDeviceIds != null) {
          builder.setTestDeviceIds(testDeviceIds);
        }
        MobileAds.setRequestConfiguration(builder.build());
        result.success(null);
        break;
      case "loadBannerAd":
        final FlutterBannerAd bannerAd =
            new FlutterBannerAd(
                call.<Integer>argument("adId"),
                instanceManager,
                call.<String>argument("adUnitId"),
                call.<FlutterAdRequest>argument("request"),
                call.<FlutterAdSize>argument("size"),
                getBannerAdCreator(context));
        instanceManager.trackAd(bannerAd, call.<Integer>argument("adId"));
        bannerAd.load();
        result.success(null);
        break;
      case "loadNativeAd":
        final String factoryId = call.argument("factoryId");
        final NativeAdFactory factory = nativeAdFactories.get(factoryId);
        if (factory == null) {
          final String message = String.format("Can't find NativeAdFactory with id: %s", factoryId);
          result.error("NativeAdError", message, null);
          break;
        }

        final FlutterNativeAd nativeAd =
            new FlutterNativeAd.Builder()
                .setManager(instanceManager)
                .setAdUnitId(call.<String>argument("adUnitId"))
                .setAdFactory(factory)
                .setRequest(call.<FlutterAdRequest>argument("request"))
                .setAdManagerRequest(call.<FlutterAdManagerAdRequest>argument("adManagerRequest"))
                .setCustomOptions(call.<Map<String, Object>>argument("customOptions"))
                .setId(call.<Integer>argument("adId"))
                .setNativeAdOptions(call.<FlutterNativeAdOptions>argument("nativeAdOptions"))
                .setFlutterAdLoader(new FlutterAdLoader(context))
                .build();
        instanceManager.trackAd(nativeAd, call.<Integer>argument("adId"));
        nativeAd.load();
        result.success(null);
        break;
      case "loadInterstitialAd":
        final FlutterInterstitialAd interstitial =
            new FlutterInterstitialAd(
                call.<Integer>argument("adId"),
                instanceManager,
                call.<String>argument("adUnitId"),
                call.<FlutterAdRequest>argument("request"),
                new FlutterAdLoader(context));
        instanceManager.trackAd(interstitial, call.<Integer>argument("adId"));
        interstitial.load();
        result.success(null);
        break;
      case "loadRewardedAd":
        final String rewardedAdUnitId = requireNonNull(call.<String>argument("adUnitId"));
        final FlutterAdRequest rewardedAdRequest = call.argument("request");
        final FlutterAdManagerAdRequest rewardedAdManagerRequest =
            call.argument("adManagerRequest");

        final FlutterRewardedAd rewardedAd;
        if (rewardedAdRequest != null) {
          rewardedAd =
              new FlutterRewardedAd(
                  call.<Integer>argument("adId"),
                  requireNonNull(instanceManager),
                  rewardedAdUnitId,
                  rewardedAdRequest,
                  new FlutterAdLoader(context));
        } else if (rewardedAdManagerRequest != null) {
          rewardedAd =
              new FlutterRewardedAd(
                  call.<Integer>argument("adId"),
                  requireNonNull(instanceManager),
                  rewardedAdUnitId,
                  rewardedAdManagerRequest,
                  new FlutterAdLoader(context));
        } else {
          result.error("InvalidRequest", "A null or invalid ad request was provided.", null);
          break;
        }

        instanceManager.trackAd(rewardedAd, requireNonNull(call.<Integer>argument("adId")));
        rewardedAd.load();
        result.success(null);
        break;
      case "loadAdManagerBannerAd":
        final FlutterAdManagerBannerAd adManagerBannerAd =
            new FlutterAdManagerBannerAd(
                call.<Integer>argument("adId"),
                instanceManager,
                call.<String>argument("adUnitId"),
                call.<List<FlutterAdSize>>argument("sizes"),
                call.<FlutterAdManagerAdRequest>argument("request"),
                getBannerAdCreator(context));
        instanceManager.trackAd(adManagerBannerAd, call.<Integer>argument("adId"));
        adManagerBannerAd.load();
        result.success(null);
        break;
      case "loadFluidAd":
        final FluidAdManagerBannerAd fluidAd =
            new FluidAdManagerBannerAd(
                call.<Integer>argument("adId"),
                instanceManager,
                call.<String>argument("adUnitId"),
                call.<FlutterAdManagerAdRequest>argument("request"),
                getBannerAdCreator(context));
        instanceManager.trackAd(fluidAd, call.<Integer>argument("adId"));
        fluidAd.load();
        result.success(null);
        break;
      case "loadAdManagerInterstitialAd":
        final FlutterAdManagerInterstitialAd adManagerInterstitialAd =
            new FlutterAdManagerInterstitialAd(
                call.<Integer>argument("adId"),
                requireNonNull(instanceManager),
                requireNonNull(call.<String>argument("adUnitId")),
                call.<FlutterAdManagerAdRequest>argument("request"),
                new FlutterAdLoader(context));
        instanceManager.trackAd(
            adManagerInterstitialAd, requireNonNull(call.<Integer>argument("adId")));
        adManagerInterstitialAd.load();
        result.success(null);
        break;
      case "loadRewardedInterstitialAd":
        final String rewardedInterstitialAdUnitId =
            requireNonNull(call.<String>argument("adUnitId"));
        final FlutterAdRequest rewardedInterstitialAdRequest = call.argument("request");
        final FlutterAdManagerAdRequest rewardedInterstitialAdManagerRequest =
            call.argument("adManagerRequest");

        final FlutterRewardedInterstitialAd rewardedInterstitialAd;
        if (rewardedInterstitialAdRequest != null) {
          rewardedInterstitialAd =
              new FlutterRewardedInterstitialAd(
                  call.<Integer>argument("adId"),
                  requireNonNull(instanceManager),
                  rewardedInterstitialAdUnitId,
                  rewardedInterstitialAdRequest,
                  new FlutterAdLoader(context));
        } else if (rewardedInterstitialAdManagerRequest != null) {
          rewardedInterstitialAd =
              new FlutterRewardedInterstitialAd(
                  call.<Integer>argument("adId"),
                  requireNonNull(instanceManager),
                  rewardedInterstitialAdUnitId,
                  rewardedInterstitialAdManagerRequest,
                  new FlutterAdLoader(context));
        } else {
          result.error("InvalidRequest", "A null or invalid ad request was provided.", null);
          break;
        }

        instanceManager.trackAd(
            rewardedInterstitialAd, requireNonNull(call.<Integer>argument("adId")));
        rewardedInterstitialAd.load();
        result.success(null);
        break;
      case "loadAppOpenAd":
        final FlutterAppOpenAd appOpenAd =
            new FlutterAppOpenAd(
                call.<Integer>argument("adId"),
                call.<Integer>argument("orientation"),
                requireNonNull(instanceManager),
                requireNonNull(call.<String>argument("adUnitId")),
                call.<FlutterAdRequest>argument("request"),
                call.<FlutterAdManagerAdRequest>argument("adManagerRequest"),
                new FlutterAdLoader(context));
        instanceManager.trackAd(appOpenAd, call.<Integer>argument("adId"));
        appOpenAd.load();
        result.success(null);
        break;
      case "disposeAd":
        instanceManager.disposeAd(call.<Integer>argument("adId"));
        result.success(null);
        break;
      case "showAdWithoutView":
        final boolean adShown = instanceManager.showAdWithId(call.<Integer>argument("adId"));
        if (!adShown) {
          result.error("AdShowError", "Ad failed to show.", null);
          break;
        }
        result.success(null);
        break;
      case "AdSize#getAnchoredAdaptiveBannerAdSize":
        final FlutterAdSize.AnchoredAdaptiveBannerAdSize size =
            new FlutterAdSize.AnchoredAdaptiveBannerAdSize(
                context,
                new FlutterAdSize.AdSizeFactory(),
                call.<String>argument("orientation"),
                call.<Integer>argument("width"));
        if (AdSize.INVALID.equals(size.size)) {
          result.success(null);
        } else {
          result.success(size.height);
        }
        break;
      case "MobileAds#setAppMuted":
        flutterMobileAds.setAppMuted(call.<Boolean>argument("muted"));
        result.success(null);
        break;
      case "MobileAds#setAppVolume":
        flutterMobileAds.setAppVolume(call.<Double>argument("volume"));
        result.success(null);
        break;
      case "setImmersiveMode":
        ((FlutterOverlayAd) instanceManager.adForId(call.<Integer>argument("adId")))
            .setImmersiveMode(call.<Boolean>argument("immersiveModeEnabled"));
        result.success(null);
        break;
      case "MobileAds#disableMediationInitialization":
        flutterMobileAds.disableMediationInitialization(context);
        result.success(null);
        break;
      case "MobileAds#getVersionString":
        result.success(flutterMobileAds.getVersionString());
        break;
      case "MobileAds#openDebugMenu":
        String adUnitId = call.argument("adUnitId");
        flutterMobileAds.openDebugMenu(context, adUnitId);
        result.success(null);
        break;
      case "getAdSize":
        {
          FlutterAd ad = instanceManager.adForId(call.<Integer>argument("adId"));
          if (ad == null) {
            // This was called on a dart ad container that hasn't been loaded yet.
            result.success(null);
          } else if (ad instanceof FlutterBannerAd) {
            result.success(((FlutterBannerAd) ad).getAdSize());
          } else if (ad instanceof FlutterAdManagerBannerAd) {
            result.success(((FlutterAdManagerBannerAd) ad).getAdSize());
          } else {
            result.error(
                Constants.ERROR_CODE_UNEXPECTED_AD_TYPE,
                "Unexpected ad type for getAdSize: " + ad,
                null);
          }
          break;
        }
      case "setServerSideVerificationOptions":
        {
          FlutterAd ad = instanceManager.adForId(call.<Integer>argument("adId"));
          final FlutterServerSideVerificationOptions options =
              call.argument("serverSideVerificationOptions");
          if (ad == null) {
            Log.w(TAG, "Error - null ad in setServerSideVerificationOptions");
          } else if (ad instanceof FlutterRewardedAd) {
            ((FlutterRewardedAd) ad).setServerSideVerificationOptions(options);
          } else if (ad instanceof FlutterRewardedInterstitialAd) {
            ((FlutterRewardedInterstitialAd) ad).setServerSideVerificationOptions(options);
          } else {
            Log.w(TAG, "Error - setServerSideVerificationOptions called on " + "non-rewarded ad");
          }
          result.success(null);
          break;
        }
      default:
        result.notImplemented();
    }
  }

  @VisibleForTesting
  BannerAdCreator getBannerAdCreator(@NonNull Context context) {
    return new BannerAdCreator(context);
  }

  /** An {@link OnInitializationCompleteListener} that invokes result.success() at most once. */
  private static final class FlutterInitializationListener
      implements OnInitializationCompleteListener {

    private final Result result;
    private boolean isInitializationCompleted;

    private FlutterInitializationListener(@NonNull final Result result) {
      this.result = result;
      isInitializationCompleted = false;
    }

    @Override
    public void onInitializationComplete(@NonNull InitializationStatus initializationStatus) {
      // Make sure not to invoke this more than once, since Dart will throw an exception if success
      // is invoked more than once. See b/193418432.
      if (isInitializationCompleted) {
        return;
      }
      result.success(new FlutterInitializationStatus(initializationStatus));
      isInitializationCompleted = true;
    }
  }
}

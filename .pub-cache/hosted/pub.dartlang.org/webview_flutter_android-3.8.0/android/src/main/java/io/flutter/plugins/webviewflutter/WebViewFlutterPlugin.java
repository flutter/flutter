// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.CookieManagerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.DownloadListenerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.FlutterAssetManagerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.GeolocationPermissionsCallbackHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.InstanceManagerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.JavaObjectHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.JavaScriptChannelHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.PermissionRequestHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebChromeClientHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebSettingsHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebStorageHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewClientHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewHostApi;

/**
 * Java platform implementation of the webview_flutter plugin.
 *
 * <p>Register this in an add to app scenario to gracefully handle activity and context changes.
 *
 * <p>Call {@link #registerWith} to use the stable {@code io.flutter.plugin.common} package instead.
 */
public class WebViewFlutterPlugin implements FlutterPlugin, ActivityAware {
  @Nullable private InstanceManager instanceManager;

  private FlutterPluginBinding pluginBinding;
  private WebViewHostApiImpl webViewHostApi;
  private JavaScriptChannelHostApiImpl javaScriptChannelHostApi;

  /**
   * Add an instance of this to {@link io.flutter.embedding.engine.plugins.PluginRegistry} to
   * register it.
   *
   * <p>THIS PLUGIN CODE PATH DEPENDS ON A NEWER VERSION OF FLUTTER THAN THE ONE DEFINED IN THE
   * PUBSPEC.YAML. Text input will fail on some Android devices unless this is used with at least
   * flutter/flutter@1d4d63ace1f801a022ea9ec737bf8c15395588b9. Use the V1 embedding with {@link
   * #registerWith} to use this plugin with older Flutter versions.
   *
   * <p>Registration should eventually be handled automatically by v2 of the
   * GeneratedPluginRegistrant. https://github.com/flutter/flutter/issues/42694
   */
  public WebViewFlutterPlugin() {}

  /**
   * Registers a plugin implementation that uses the stable {@code io.flutter.plugin.common}
   * package.
   *
   * <p>Calling this automatically initializes the plugin. However plugins initialized this way
   * won't react to changes in activity or context, unlike {@link WebViewFlutterPlugin}.
   */
  @SuppressWarnings({"unused", "deprecation"})
  public static void registerWith(
      @NonNull io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    new WebViewFlutterPlugin()
        .setUp(
            registrar.messenger(),
            registrar.platformViewRegistry(),
            registrar.activity(),
            new FlutterAssetManager.RegistrarFlutterAssetManager(
                registrar.context().getAssets(), registrar));
  }

  private void setUp(
      BinaryMessenger binaryMessenger,
      PlatformViewRegistry viewRegistry,
      Context context,
      FlutterAssetManager flutterAssetManager) {
    instanceManager =
        InstanceManager.create(
            identifier ->
                new GeneratedAndroidWebView.JavaObjectFlutterApi(binaryMessenger)
                    .dispose(identifier, reply -> {}));

    InstanceManagerHostApi.setup(binaryMessenger, () -> instanceManager.clear());

    viewRegistry.registerViewFactory(
        "plugins.flutter.io/webview", new FlutterWebViewFactory(instanceManager));

    webViewHostApi =
        new WebViewHostApiImpl(
            instanceManager, binaryMessenger, new WebViewHostApiImpl.WebViewProxy(), context);
    javaScriptChannelHostApi =
        new JavaScriptChannelHostApiImpl(
            instanceManager,
            new JavaScriptChannelHostApiImpl.JavaScriptChannelCreator(),
            new JavaScriptChannelFlutterApiImpl(binaryMessenger, instanceManager),
            new Handler(context.getMainLooper()));

    JavaObjectHostApi.setup(binaryMessenger, new JavaObjectHostApiImpl(instanceManager));
    WebViewHostApi.setup(binaryMessenger, webViewHostApi);
    JavaScriptChannelHostApi.setup(binaryMessenger, javaScriptChannelHostApi);
    WebViewClientHostApi.setup(
        binaryMessenger,
        new WebViewClientHostApiImpl(
            instanceManager,
            new WebViewClientHostApiImpl.WebViewClientCreator(),
            new WebViewClientFlutterApiImpl(binaryMessenger, instanceManager)));
    WebChromeClientHostApi.setup(
        binaryMessenger,
        new WebChromeClientHostApiImpl(
            instanceManager,
            new WebChromeClientHostApiImpl.WebChromeClientCreator(),
            new WebChromeClientFlutterApiImpl(binaryMessenger, instanceManager)));
    DownloadListenerHostApi.setup(
        binaryMessenger,
        new DownloadListenerHostApiImpl(
            instanceManager,
            new DownloadListenerHostApiImpl.DownloadListenerCreator(),
            new DownloadListenerFlutterApiImpl(binaryMessenger, instanceManager)));
    WebSettingsHostApi.setup(
        binaryMessenger,
        new WebSettingsHostApiImpl(
            instanceManager, new WebSettingsHostApiImpl.WebSettingsCreator()));
    FlutterAssetManagerHostApi.setup(
        binaryMessenger, new FlutterAssetManagerHostApiImpl(flutterAssetManager));
    CookieManagerHostApi.setup(
        binaryMessenger, new CookieManagerHostApiImpl(binaryMessenger, instanceManager));
    WebStorageHostApi.setup(
        binaryMessenger,
        new WebStorageHostApiImpl(instanceManager, new WebStorageHostApiImpl.WebStorageCreator()));

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      PermissionRequestHostApi.setup(
          binaryMessenger, new PermissionRequestHostApiImpl(binaryMessenger, instanceManager));
    }
    GeolocationPermissionsCallbackHostApi.setup(
        binaryMessenger,
        new GeolocationPermissionsCallbackHostApiImpl(binaryMessenger, instanceManager));
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
    setUp(
        binding.getBinaryMessenger(),
        binding.getPlatformViewRegistry(),
        binding.getApplicationContext(),
        new FlutterAssetManager.PluginBindingFlutterAssetManager(
            binding.getApplicationContext().getAssets(), binding.getFlutterAssets()));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (instanceManager != null) {
      instanceManager.stopFinalizationListener();
      instanceManager = null;
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
    updateContext(activityPluginBinding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    updateContext(pluginBinding.getApplicationContext());
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding activityPluginBinding) {
    updateContext(activityPluginBinding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    updateContext(pluginBinding.getApplicationContext());
  }

  private void updateContext(Context context) {
    webViewHostApi.setContext(context);
    javaScriptChannelHostApi.setPlatformThreadHandler(new Handler(context.getMainLooper()));
  }

  /** Maintains instances used to communicate with the corresponding objects in Dart. */
  @Nullable
  public InstanceManager getInstanceManager() {
    return instanceManager;
  }
}

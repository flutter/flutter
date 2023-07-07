// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Build;
import android.webkit.CookieManager;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.CookieManagerHostApi;
import java.util.Objects;

/**
 * Host API implementation for `CookieManager`.
 *
 * <p>This class may handle instantiating and adding native object instances that are attached to a
 * Dart instance or handle method calls on the associated native class or an instance of the class.
 */
public class CookieManagerHostApiImpl implements CookieManagerHostApi {
  // To ease adding additional methods, this value is added prematurely.
  @SuppressWarnings({"unused", "FieldCanBeLocal"})
  private final BinaryMessenger binaryMessenger;

  private final InstanceManager instanceManager;
  private final CookieManagerProxy proxy;

  /** Proxy for constructors and static method of `CookieManager`. */
  @VisibleForTesting
  static class CookieManagerProxy {
    /** Handles the Dart static method `MyClass.myStaticMethod`. */
    @NonNull
    public CookieManager getInstance() {
      return CookieManager.getInstance();
    }
  }

  /**
   * Constructs a {@link CookieManagerHostApiImpl}.
   *
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param instanceManager maintains instances stored to communicate with attached Dart objects
   */
  public CookieManagerHostApiImpl(
      @NonNull BinaryMessenger binaryMessenger, @NonNull InstanceManager instanceManager) {
    this(binaryMessenger, instanceManager, new CookieManagerProxy());
  }

  /**
   * Constructs a {@link CookieManagerHostApiImpl}.
   *
   * @param binaryMessenger used to communicate with Dart over asynchronous messages
   * @param instanceManager maintains instances stored to communicate with attached Dart objects
   * @param proxy proxy for constructors and static methods of `CookieManager`
   */
  public CookieManagerHostApiImpl(
      @NonNull BinaryMessenger binaryMessenger,
      @NonNull InstanceManager instanceManager,
      @NonNull CookieManagerProxy proxy) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    this.proxy = proxy;
  }

  @Override
  public void attachInstance(@NonNull Long instanceIdentifier) {
    instanceManager.addDartCreatedInstance(proxy.getInstance(), instanceIdentifier);
  }

  @Override
  public void setCookie(@NonNull Long identifier, @NonNull String url, @NonNull String value) {
    getCookieManagerInstance(identifier).setCookie(url, value);
  }

  @Override
  public void removeAllCookies(
      @NonNull Long identifier, @NonNull GeneratedAndroidWebView.Result<Boolean> result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      getCookieManagerInstance(identifier).removeAllCookies(result::success);
    } else {
      result.success(removeCookiesPreL(getCookieManagerInstance(identifier)));
    }
  }

  @Override
  public void setAcceptThirdPartyCookies(
      @NonNull Long identifier, @NonNull Long webViewIdentifier, @NonNull Boolean accept) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      getCookieManagerInstance(identifier)
          .setAcceptThirdPartyCookies(
              Objects.requireNonNull(instanceManager.getInstance(webViewIdentifier)), accept);
    } else {
      throw new UnsupportedOperationException(
          "`setAcceptThirdPartyCookies` is unsupported on versions below `Build.VERSION_CODES.LOLLIPOP`.");
    }
  }

  /**
   * Removes all cookies from the given cookie manager, using the deprecated (pre-Lollipop)
   * implementation.
   *
   * @param cookieManager The cookie manager to clear all cookies from.
   * @return Whether any cookies were removed.
   */
  @SuppressWarnings("deprecation")
  private boolean removeCookiesPreL(CookieManager cookieManager) {
    final boolean hasCookies = cookieManager.hasCookies();
    if (hasCookies) {
      cookieManager.removeAllCookie();
    }
    return hasCookies;
  }

  @NonNull
  private CookieManager getCookieManagerInstance(@NonNull Long identifier) {
    return Objects.requireNonNull(instanceManager.getInstance(identifier));
  }
}

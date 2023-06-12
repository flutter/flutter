/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.auth;

import static io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin.parseAuthCredential;

import androidx.annotation.NonNull;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseAuthUserCollisionException;
import com.google.firebase.auth.FirebaseAuthWeakPasswordException;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class FlutterFirebaseAuthPluginException extends Exception {

  private final String code;
  private final String message;
  private Map<String, Object> additionalData = new HashMap<>();

  FlutterFirebaseAuthPluginException(@NonNull String code, @NonNull String message) {
    super(message, null);

    this.code = code;
    this.message = message;
  }

  FlutterFirebaseAuthPluginException(
      @NonNull String code, @NonNull String message, @NonNull Map<String, Object> additionalData) {
    super(message, null);

    this.code = code;
    this.message = message;
    this.additionalData = additionalData;
  }

  FlutterFirebaseAuthPluginException(@NonNull Exception nativeException, Throwable cause) {
    super(nativeException.getMessage(), cause);

    String code = "UNKNOWN";
    String message = nativeException.getMessage();
    Map<String, Object> additionalData = new HashMap<>();

    if (nativeException instanceof FirebaseAuthException) {
      code = ((FirebaseAuthException) nativeException).getErrorCode();
    }

    if (nativeException instanceof FirebaseAuthWeakPasswordException) {
      message = ((FirebaseAuthWeakPasswordException) nativeException).getReason();
    }

    if (nativeException instanceof FirebaseAuthUserCollisionException) {
      String email = ((FirebaseAuthUserCollisionException) nativeException).getEmail();

      if (email != null) {
        additionalData.put("email", email);
      }

      AuthCredential authCredential =
          ((FirebaseAuthUserCollisionException) nativeException).getUpdatedCredential();

      if (authCredential != null) {
        additionalData.put("authCredential", parseAuthCredential(authCredential));
      }
    }

    this.code = code;
    this.message = message;
    this.additionalData = additionalData;
  }

  static FlutterFirebaseAuthPluginException noUser() {
    return new FlutterFirebaseAuthPluginException(
        "NO_CURRENT_USER", "No user currently signed in.");
  }

  static FlutterFirebaseAuthPluginException invalidCredential() {
    return new FlutterFirebaseAuthPluginException(
        "INVALID_CREDENTIAL",
        "The supplied auth credential is malformed, has expired or is not currently supported.");
  }

  static FlutterFirebaseAuthPluginException noSuchProvider() {
    return new FlutterFirebaseAuthPluginException(
        "NO_SUCH_PROVIDER", "User was not linked to an account with the given provider.");
  }

  static FlutterFirebaseAuthPluginException alreadyLinkedProvider() {
    return new FlutterFirebaseAuthPluginException(
        "PROVIDER_ALREADY_LINKED", "User has already been linked to the given provider.");
  }

  public String getCode() {
    return code.toLowerCase(Locale.ROOT).replace("error_", "").replace("_", "-");
  }

  @Override
  public String getMessage() {
    return message;
  }

  public Map<String, Object> getAdditionalData() {
    return additionalData;
  }
}

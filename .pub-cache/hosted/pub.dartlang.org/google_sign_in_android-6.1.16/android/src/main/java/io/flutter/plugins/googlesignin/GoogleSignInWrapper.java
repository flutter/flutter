// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlesignin;

import android.app.Activity;
import android.content.Context;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.Scope;

/**
 * A wrapper object that calls static method in GoogleSignIn.
 *
 * <p>Because GoogleSignIn uses static method mostly, which is hard for unit testing. We use this
 * wrapper class to use instance method which calls the corresponding GoogleSignIn static methods.
 *
 * <p>Warning! This class should stay true that each method calls a GoogleSignIn static method with
 * the same name and same parameters.
 */
public class GoogleSignInWrapper {

  GoogleSignInClient getClient(Context context, GoogleSignInOptions options) {
    return GoogleSignIn.getClient(context, options);
  }

  GoogleSignInAccount getLastSignedInAccount(Context context) {
    return GoogleSignIn.getLastSignedInAccount(context);
  }

  boolean hasPermissions(GoogleSignInAccount account, Scope scope) {
    return GoogleSignIn.hasPermissions(account, scope);
  }

  void requestPermissions(
      Activity activity, int requestCode, GoogleSignInAccount account, Scope[] scopes) {
    GoogleSignIn.requestPermissions(activity, requestCode, account, scopes);
  }
}

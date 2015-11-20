// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.firebase;

import android.content.Context;
import android.util.Log;

import java.io.IOException;

import com.firebase.client.ValueEventListener;
import com.firebase.client.FirebaseError;
import com.firebase.client.Firebase.AuthResultHandler;
import com.firebase.client.AuthData;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.firebase.DataSnapshot;
import org.chromium.mojom.firebase.Firebase;
import org.chromium.mojom.firebase.EventType;

public class FirebaseImpl implements org.chromium.mojom.firebase.Firebase {
    private static final String TAG = "FirebaseImpl";
    static private Context mContext;
    private com.firebase.client.Firebase mClient;

    public FirebaseImpl(Context context) {
      if (context != mContext)
          com.firebase.client.Firebase.setAndroidContext(context);
      mContext = context;
      Log.v(TAG, "constructed");
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void initWithUrl(String url) {
        mClient = new com.firebase.client.Firebase(url);
    }

    @Override
    public void getRoot(InterfaceRequest<Firebase> request) {
        FirebaseImpl root = new FirebaseImpl(mContext);
        root.mClient = mClient.getRoot();
        Firebase.MANAGER.bind(root, request);
    }

    @Override
    public void getChild(String path, InterfaceRequest<Firebase> request) {
        FirebaseImpl child = new FirebaseImpl(mContext);
        child.mClient = mClient.child(path);
        Firebase.MANAGER.bind(child, request);
    }

    @Override
    public void observeSingleEventOfType(int eventType, ObserveSingleEventOfTypeResponse response) {
        final ObserveSingleEventOfTypeResponse responseCopy = response;
        mClient.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(com.firebase.client.DataSnapshot dataSnapshot) {
                DataSnapshot mojoSnapshot = new DataSnapshot();
                mojoSnapshot.key = dataSnapshot.getKey();
                mojoSnapshot.value = (String)dataSnapshot.getValue();
                responseCopy.call(mojoSnapshot);
            }

            @Override
            public void onCancelled(FirebaseError error) {
                // No-op
            }
        });
    }

    @Override
    public void authWithOAuthToken(String provider, String credentials, AuthWithOAuthTokenResponse response) {
        final AuthWithOAuthTokenResponse responseCopy = response;
        Log.v(TAG, "Authenticating " + mContext + " " + provider + " " + credentials);
        mClient.authWithOAuthToken(provider, credentials, new AuthResultHandler() {
          @Override
          public void onAuthenticated(AuthData authData) {
            org.chromium.mojom.firebase.AuthData mojoAuthData =
              new org.chromium.mojom.firebase.AuthData();
            mojoAuthData.uid = authData.getUid();
            mojoAuthData.provider = authData.getProvider();
            mojoAuthData.token = authData.getToken();
            responseCopy.call(null, mojoAuthData);
          }
          public void onAuthenticationError(FirebaseError error) {
            org.chromium.mojom.firebase.Error mojoError =
              new org.chromium.mojom.firebase.Error();
            mojoError.code = error.getCode();
            mojoError.message = error.getMessage();
            responseCopy.call(mojoError, null);
          }
        });
    }
}

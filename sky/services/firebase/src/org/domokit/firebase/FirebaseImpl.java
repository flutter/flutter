// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.firebase;

import android.content.Context;
import android.util.Log;

import java.io.IOException;

import com.firebase.client.FirebaseError;
import com.firebase.client.Firebase.AuthResultHandler;
import com.firebase.client.AuthData;

import org.chromium.mojo.bindings.ConnectionErrorHandler;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.firebase.DataSnapshot;
import org.chromium.mojom.firebase.EventType;
import org.chromium.mojom.firebase.Firebase;
import org.chromium.mojom.firebase.ValueEventListener;

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
    public void addValueEventListener(org.chromium.mojom.firebase.ValueEventListener listener) {
        final org.chromium.mojom.firebase.ValueEventListener.Proxy proxy =
            (org.chromium.mojom.firebase.ValueEventListener.Proxy)listener;
        final com.firebase.client.ValueEventListener firebaseListener =
            new com.firebase.client.ValueEventListener() {
            @Override
            public void onCancelled(FirebaseError error) {
                proxy.onCancelled(toMojoError(error));
            }
            @Override
            public void onDataChange(com.firebase.client.DataSnapshot snapshot) {
                proxy.onDataChange(toMojoSnapshot(snapshot));
            }
        };
        proxy.getProxyHandler().setErrorHandler(new ConnectionErrorHandler() {
            @Override
            public void onConnectionError(MojoException e) {
                mClient.removeEventListener(firebaseListener);
            }
        });
        mClient.addValueEventListener(firebaseListener);
    }

    @Override
    public void addChildEventListener(org.chromium.mojom.firebase.ChildEventListener listener) {
        final org.chromium.mojom.firebase.ChildEventListener.Proxy proxy =
            (org.chromium.mojom.firebase.ChildEventListener.Proxy)listener;
        final com.firebase.client.ChildEventListener firebaseListener =
            new com.firebase.client.ChildEventListener() {
            @Override
            public void onCancelled(FirebaseError error) {
                proxy.onCancelled(toMojoError(error));
            }
            @Override
            public void onChildAdded(com.firebase.client.DataSnapshot snapshot, String previousChildName) {
                proxy.onChildAdded(toMojoSnapshot(snapshot), previousChildName);
            }
            @Override
            public void onChildChanged(com.firebase.client.DataSnapshot snapshot, String previousChildName) {
                proxy.onChildChanged(toMojoSnapshot(snapshot), previousChildName);
            }
            @Override
            public void onChildMoved(com.firebase.client.DataSnapshot snapshot, String previousChildName) {
                proxy.onChildMoved(toMojoSnapshot(snapshot), previousChildName);
            }
            @Override
            public void onChildRemoved(com.firebase.client.DataSnapshot snapshot) {
                proxy.onChildRemoved(toMojoSnapshot(snapshot));
            }
        };
        proxy.getProxyHandler().setErrorHandler(new ConnectionErrorHandler() {
            @Override
            public void onConnectionError(MojoException e) {
                mClient.removeEventListener(firebaseListener);
            }
        });
        mClient.addChildEventListener(firebaseListener);
    }

    @Override
    public void observeSingleEventOfType(int eventType, ObserveSingleEventOfTypeResponse response) {
        final ObserveSingleEventOfTypeResponse responseCopy = response;
        mClient.addListenerForSingleValueEvent(new com.firebase.client.ValueEventListener() {
            @Override
            public void onDataChange(com.firebase.client.DataSnapshot snapshot) {
                responseCopy.call(toMojoSnapshot(snapshot));
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

    DataSnapshot toMojoSnapshot(com.firebase.client.DataSnapshot snapshot) {
        DataSnapshot mojoSnapshot = new DataSnapshot();
        mojoSnapshot.key = snapshot.getKey();
        mojoSnapshot.value = (String)snapshot.getValue();
        return mojoSnapshot;
    }

    org.chromium.mojom.firebase.Error toMojoError(FirebaseError error) {
        org.chromium.mojom.firebase.Error mojoError =
          new org.chromium.mojom.firebase.Error();
        mojoError.code = error.getCode();
        mojoError.message = error.getMessage();
        return mojoError;
    }
}

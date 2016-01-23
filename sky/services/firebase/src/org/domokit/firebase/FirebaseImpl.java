// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.firebase;

import android.content.Context;
import android.util.Log;

import com.firebase.client.AuthData;
import com.firebase.client.FirebaseError;
import com.firebase.client.Firebase.AuthResultHandler;
import com.firebase.client.Firebase.CompletionListener;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

import org.chromium.mojo.bindings.ConnectionErrorHandler;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.firebase.DataSnapshot;
import org.chromium.mojom.firebase.EventType;
import org.chromium.mojom.firebase.Firebase;
import org.chromium.mojom.firebase.ValueEventListener;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

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

    public static void connectToService(Context context, Core core, MessagePipeHandle pipe) {
        Firebase.MANAGER.bind(new FirebaseImpl(context), pipe);
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
            responseCopy.call(toMojoError(error), null);
          }
        });
    }

    @Override
    public void setValue(String jsonValue, SetValueResponse response) {
        final SetValueResponse responseCopy = response;
        try {
          JSONObject root = new JSONObject(jsonValue);
          Object value = toMap(root).get("value");
          mClient.setValue(value, null, new CompletionListener() {
              @Override
              public void onComplete(FirebaseError error, com.firebase.client.Firebase ref) {
                  responseCopy.call(toMojoError(error));
              }
          });
        } catch(JSONException e) {
          org.chromium.mojom.firebase.Error mojoError =
            new org.chromium.mojom.firebase.Error();
          mojoError.code = -1;
          mojoError.message = "setValue JSONException";
          Log.e(TAG, "setValue JSONException", e);
          responseCopy.call(mojoError);
        }
    }

    DataSnapshot toMojoSnapshot(com.firebase.client.DataSnapshot snapshot) {
        DataSnapshot mojoSnapshot = new DataSnapshot();
        mojoSnapshot.key = snapshot.getKey();
        Map<String, Object> jsonValue = new HashMap<String, Object>();
        jsonValue.put("value", snapshot.getValue());
        mojoSnapshot.jsonValue = new JSONObject(jsonValue).toString();
        return mojoSnapshot;
    }

    org.chromium.mojom.firebase.Error toMojoError(FirebaseError error) {
        if (error == null)
          return null;
        org.chromium.mojom.firebase.Error mojoError =
          new org.chromium.mojom.firebase.Error();
        mojoError.code = error.getCode();
        mojoError.message = error.getMessage();
        return mojoError;
    }

    // public domain code from https://gist.github.com/codebutler/2339666
    @SuppressWarnings({ "rawtypes", "unchecked" })
    static Map<String, Object> toMap(JSONObject object) throws JSONException {
        Map<String, Object> map = new HashMap();
        Iterator keys = object.keys();
        while (keys.hasNext()) {
            String key = (String) keys.next();
            map.put(key, fromJson(object.get(key)));
        }
        return map;
    }

    @SuppressWarnings({ "rawtypes", "unchecked" })
    static List toList(JSONArray array) throws JSONException {
        List list = new ArrayList();
        for (int i = 0; i < array.length(); i++) {
            list.add(fromJson(array.get(i)));
        }
        return list;
    }

    static Object fromJson(Object json) throws JSONException {
        if (json == JSONObject.NULL) {
            return null;
        } else if (json instanceof JSONObject) {
            return toMap((JSONObject) json);
        } else if (json instanceof JSONArray) {
            return toList((JSONArray) json);
        } else {
            return json;
        }
    }
}

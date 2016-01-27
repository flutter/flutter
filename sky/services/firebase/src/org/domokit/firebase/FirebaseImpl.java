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
import com.firebase.client.Firebase.ResultHandler;
import com.firebase.client.Firebase.ValueResultHandler;

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
    public void observeSingleEventOfType(int eventType, final ObserveSingleEventOfTypeResponse response) {
        mClient.addListenerForSingleValueEvent(new com.firebase.client.ValueEventListener() {
            @Override
            public void onDataChange(com.firebase.client.DataSnapshot snapshot) {
                response.call(toMojoSnapshot(snapshot));
            }

            @Override
            public void onCancelled(FirebaseError error) {
                // No-op
            }
        });
    }

    @Override
    public void authWithCustomToken(String token, final AuthWithCustomTokenResponse response) {
      mClient.authWithCustomToken(token, new AuthResultHandler() {
          @Override
          public void onAuthenticated(AuthData authData) {
              response.call(null, toMojoAuthData(authData));
          }
          public void onAuthenticationError(FirebaseError error) {
              response.call(toMojoError(error), null);
          }
      });
    }

    @Override
    public void authAnonymously(final AuthAnonymouslyResponse response) {
      mClient.authAnonymously(new AuthResultHandler() {
          @Override
          public void onAuthenticated(AuthData authData) {
              response.call(null, toMojoAuthData(authData));
          }
          public void onAuthenticationError(FirebaseError error) {
              response.call(toMojoError(error), null);
          }
      });
    }

    @Override
    public void authWithOAuthToken(String provider, String credentials, final AuthWithOAuthTokenResponse response) {
        mClient.authWithOAuthToken(provider, credentials, new AuthResultHandler() {
            @Override
            public void onAuthenticated(AuthData authData) {
                response.call(null, toMojoAuthData(authData));
            }
            public void onAuthenticationError(FirebaseError error) {
                response.call(toMojoError(error), null);
            }
        });
    }

    @Override
    public void authWithPassword(String email, String password, final AuthWithPasswordResponse response) {
        mClient.authWithPassword(email, password, new AuthResultHandler() {
            @Override
            public void onAuthenticated(AuthData authData) {
                response.call(null, toMojoAuthData(authData));
            }
            public void onAuthenticationError(FirebaseError error) {
                response.call(toMojoError(error), null);
            }
        });
    }

    @Override
    public void unauth(final UnauthResponse response) {
      mClient.unauth(new CompletionListener() {
          @Override
          public void onComplete(FirebaseError error, com.firebase.client.Firebase ref) {
              response.call(toMojoError(error));
          }
      });
    }

    @Override
    public void getChild(String path, InterfaceRequest<Firebase> request) {
        FirebaseImpl child = new FirebaseImpl(mContext);
        child.mClient = mClient.child(path);
        Firebase.MANAGER.bind(child, request);
    }

    @Override
    public void getParent(InterfaceRequest<Firebase> request) {
        FirebaseImpl parent = new FirebaseImpl(mContext);
        parent.mClient = mClient.getParent();
        Firebase.MANAGER.bind(parent, request);
    }

    @Override
    public void getRoot(InterfaceRequest<Firebase> request) {
        FirebaseImpl root = new FirebaseImpl(mContext);
        root.mClient = mClient.getRoot();
        Firebase.MANAGER.bind(root, request);
    }

    @Override
    public void setValue(String jsonValue, int priority, boolean hasPriority, final SetValueResponse response) {
        try {
          JSONObject root = new JSONObject(jsonValue);
          Object value = toMap(root).get("value");
          mClient.setValue(value, hasPriority ? priority : null, new CompletionListener() {
              @Override
              public void onComplete(FirebaseError error, com.firebase.client.Firebase ref) {
                  response.call(toMojoError(error));
              }
          });
        } catch(JSONException e) {
          org.chromium.mojom.firebase.Error mojoError =
            new org.chromium.mojom.firebase.Error();
          mojoError.code = -1;
          mojoError.message = "setValue JSONException";
          Log.e(TAG, "setValue JSONException", e);
          response.call(mojoError);
        }
    }

    @Override
    public void removeValue(final RemoveValueResponse response) {
      mClient.removeValue(new CompletionListener() {
          @Override
          public void onComplete(FirebaseError error, com.firebase.client.Firebase ref) {
              response.call(toMojoError(error));
          }
      });
    }

    @Override
    public void push(InterfaceRequest<Firebase> request, final PushResponse response) {
        FirebaseImpl child = new FirebaseImpl(mContext);
        child.mClient = mClient.push();
        Firebase.MANAGER.bind(child, request);
        response.call(child.mClient.getKey());
    }

    @Override
    public void setPriority(int priority, final SetPriorityResponse response) {
      mClient.setPriority(priority, new CompletionListener() {
          @Override
          public void onComplete(FirebaseError error, com.firebase.client.Firebase ref) {
              response.call(toMojoError(error));
          }
      });
    }

    @Override
    public void createUser(String email, String password, final CreateUserResponse response) {
      mClient.createUser(email, password, new ValueResultHandler<Map<String,Object>>() {
          @Override
          public void onError(FirebaseError error) {
              response.call(toMojoError(error), null);
          }
          @Override
          public void onSuccess(Map<String,Object> result) {
              response.call(null, new JSONObject(result).toString());
          }
      });
    }

    @Override
    public void changeEmail(String oldEmail, String password, String newExample, final ChangeEmailResponse response) {
      mClient.changeEmail(oldEmail, password, newExample, new ResultHandler() {
          @Override
          public void onError(FirebaseError error) {
              response.call(toMojoError(error));
          }
          @Override
          public void onSuccess() {
              response.call(null);
          }
      });
    }

    @Override
    public void changePassword(String newPassword, String email, String oldPassword, final ChangePasswordResponse response) {
      mClient.changePassword(newPassword, email, oldPassword, new ResultHandler() {
          @Override
          public void onError(FirebaseError error) {
              response.call(toMojoError(error));
          }
          @Override
          public void onSuccess() {
              response.call(null);
          }
      });
    }

    @Override
    public void removeUser(String email, String password, final RemoveUserResponse response) {
      mClient.removeUser(email, password, new ResultHandler() {
          @Override
          public void onError(FirebaseError error) {
              response.call(toMojoError(error));
          }
          @Override
          public void onSuccess() {
              response.call(null);
          }
      });
    }

    @Override
    public void resetPassword(String email, final ResetPasswordResponse response) {
      mClient.resetPassword(email, new ResultHandler() {
          @Override
          public void onError(FirebaseError error) {
              response.call(toMojoError(error));
          }
          @Override
          public void onSuccess() {
              response.call(null);
          }
      });
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

    org.chromium.mojom.firebase.AuthData toMojoAuthData(AuthData authData) {
      org.chromium.mojom.firebase.AuthData mojoAuthData =
        new org.chromium.mojom.firebase.AuthData();
      mojoAuthData.uid = authData.getUid();
      mojoAuthData.provider = authData.getProvider();
      mojoAuthData.token = authData.getToken();
      return mojoAuthData;
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

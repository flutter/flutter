// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.gcm;

import android.app.IntentService;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.google.android.gms.gcm.GcmPubSub;
import com.google.android.gms.gcm.GoogleCloudMessaging;
import com.google.android.gms.iid.InstanceID;

import java.io.IOException;

import org.chromium.base.ThreadUtils;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.gcm.GcmListener;
import org.chromium.mojom.gcm.GcmService;

public class RegistrationIntentService extends IntentService {
    private static final String TAG = "RegistrationIntentService";
    private static final String REGISTER_EXTRA = "register";
    private static final String TOKEN_EXTRA = "token";
    private static final String SUBSCRIBE_EXTRA = "subscribe";
    private static final String UNSUBSCRIBE_EXTRA = "unsubscribe";

    private static GcmListener sListener;
    private static GcmService.RegisterResponse sRegisterResponse;

    public static class MojoService implements GcmService {
        private Context context;

        public MojoService(Context context) {
            this.context = context;
        }

        @Override
        public void close() {}

        @Override
        public void onConnectionError(MojoException e) {}

        @Override
        public void register(String senderId, GcmListener listener, RegisterResponse response) {
            if (checkPlayServices()) {
                // Start IntentService to register this application with GCM.
                RegistrationIntentService.sListener = listener;
                RegistrationIntentService.sRegisterResponse = response;
                Intent intent = new Intent(context, RegistrationIntentService.class);
                intent.putExtra(REGISTER_EXTRA, senderId);
                context.startService(intent);
            }
        }

        public void subscribeTopics(String token, String[] topics) {
            Intent intent = new Intent(context, RegistrationIntentService.class);
            intent.putExtra(TOKEN_EXTRA, token);
            intent.putExtra(SUBSCRIBE_EXTRA, topics);
            context.startService(intent);
        }

        public void unsubscribeTopics(String token, String[] topics) {
            Intent intent = new Intent(context, RegistrationIntentService.class);
            intent.putExtra(TOKEN_EXTRA, token);
            intent.putExtra(UNSUBSCRIBE_EXTRA, topics);
            context.startService(intent);
        }

        private boolean checkPlayServices() {
            // TODO(mpcomplete): implement? This would check if the user has the Google Play Services
            // library installed, and if not, prompt them to download it.
            return true;
        }
    }

    public RegistrationIntentService() {
        super(TAG);
    }

    public static void notifyMessageReceived(final String from, final String message) {
        ThreadUtils.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (sListener != null)
                    sListener.onMessageReceived(from, message);
            }
        });
    }

    public static void notifyRegistered(final String token) {
        ThreadUtils.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (sRegisterResponse != null)
                    sRegisterResponse.call(token);
            }
        });
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        try {
            if (intent.hasExtra(REGISTER_EXTRA)) {
                register(intent.getStringExtra(REGISTER_EXTRA));
            } else if (intent.hasExtra(SUBSCRIBE_EXTRA)) {
              subscribeTopics(
                  intent.getStringExtra(TOKEN_EXTRA),
                  intent.getStringArrayExtra(SUBSCRIBE_EXTRA));
            } else if (intent.hasExtra(UNSUBSCRIBE_EXTRA)) {
              unsubscribeTopics(
                  intent.getStringExtra(TOKEN_EXTRA),
                  intent.getStringArrayExtra(UNSUBSCRIBE_EXTRA));
            } else {
              Log.d(TAG, "Unexpected intent.");
            }
        } catch (Exception e) {
            Log.d(TAG, "Failed to process GCM request", e);
        }
    }

    private void register(String senderId) {
        try {
            InstanceID instanceID = InstanceID.getInstance(this);
            String token = instanceID.getToken(senderId,
                GoogleCloudMessaging.INSTANCE_ID_SCOPE, null);
            notifyRegistered(token);
        } catch (Exception e) {
            Log.d(TAG, "Failed to complete token refresh", e);
            // TODO(mpcomplete): callback error code.
        }
    }

    private void subscribeTopics(String token, String[] topics) throws IOException {
        GcmPubSub pubSub = GcmPubSub.getInstance(this);
        for (String topic : topics) {
            pubSub.subscribe(token, "/topics/" + topic, null);
        }
    }

    private void unsubscribeTopics(String token, String[] topics) throws IOException {
        GcmPubSub pubSub = GcmPubSub.getInstance(this);
        for (String topic : topics) {
            pubSub.unsubscribe(token, "/topics/" + topic);
        }
    }
}

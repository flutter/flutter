// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.os.Handler;
import android.os.Message;
import android.util.Log;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

class SystemMessageHandler extends Handler {

    private static final String TAG = "SystemMessageHandler";

    private static final int SCHEDULED_WORK = 1;
    private static final int DELAYED_SCHEDULED_WORK = 2;

    // Native class pointer set by the constructor of the SharedClient native class.
    private long mMessagePumpDelegateNative = 0;
    private long mDelayedScheduledTimeTicks = 0;

    // Reflected API for marking a message as asynchronous. This is a workaround
    // to provide fair Chromium task dispatch when served by the Android UI
    // thread's Looper, avoiding stalls when the Looper has a sync barrier.
    // Note: Use of this API is experimental and likely to evolve in the future.
    private Method mMessageMethodSetAsynchronous;

    private SystemMessageHandler(long messagePumpDelegateNative) {
        mMessagePumpDelegateNative = messagePumpDelegateNative;

        try {
            Class<?> messageClass = Class.forName("android.os.Message");
            mMessageMethodSetAsynchronous = messageClass.getMethod(
                    "setAsynchronous", new Class[]{boolean.class});
        } catch (ClassNotFoundException e) {
            Log.e(TAG, "Failed to find android.os.Message class:" + e);
        } catch (NoSuchMethodException e) {
            Log.e(TAG, "Failed to load Message.setAsynchronous method:" + e);
        } catch (RuntimeException e) {
            Log.e(TAG, "Exception while loading Message.setAsynchronous method: " + e);
        }

    }

    @Override
    public void handleMessage(Message msg) {
        if (msg.what == DELAYED_SCHEDULED_WORK) {
            mDelayedScheduledTimeTicks = 0;
        }
        nativeDoRunLoopOnce(mMessagePumpDelegateNative, mDelayedScheduledTimeTicks);
    }

    @SuppressWarnings("unused")
    @CalledByNative
    private void scheduleWork() {
        sendMessage(obtainAsyncMessage(SCHEDULED_WORK));
    }

    @SuppressWarnings("unused")
    @CalledByNative
    private void scheduleDelayedWork(long delayedTimeTicks, long millis) {
        if (mDelayedScheduledTimeTicks != 0) {
            removeMessages(DELAYED_SCHEDULED_WORK);
        }
        mDelayedScheduledTimeTicks = delayedTimeTicks;
        sendMessageDelayed(obtainAsyncMessage(DELAYED_SCHEDULED_WORK), millis);
    }

    @SuppressWarnings("unused")
    @CalledByNative
    private void removeAllPendingMessages() {
        removeMessages(SCHEDULED_WORK);
        removeMessages(DELAYED_SCHEDULED_WORK);
    }

    private Message obtainAsyncMessage(int what) {
        Message msg = Message.obtain();
        msg.what = what;
        if (mMessageMethodSetAsynchronous != null) {
            // If invocation fails, assume this is indicative of future
            // failures, and avoid log spam by nulling the reflected method.
            try {
                mMessageMethodSetAsynchronous.invoke(msg, true);
            } catch (IllegalAccessException e) {
                Log.e(TAG, "Illegal access to asynchronous message creation, disabling.");
                mMessageMethodSetAsynchronous = null;
            } catch (IllegalArgumentException e) {
                Log.e(TAG, "Illegal argument for asynchronous message creation, disabling.");
                mMessageMethodSetAsynchronous = null;
            } catch (InvocationTargetException e) {
                Log.e(TAG, "Invocation exception during asynchronous message creation, disabling.");
                mMessageMethodSetAsynchronous = null;
            } catch (RuntimeException e) {
                Log.e(TAG, "Runtime exception during asynchronous message creation, disabling.");
                mMessageMethodSetAsynchronous = null;
            }
        }
        return msg;
    }

    @CalledByNative
    private static SystemMessageHandler create(long messagePumpDelegateNative) {
        return new SystemMessageHandler(messagePumpDelegateNative);
    }

    private native void nativeDoRunLoopOnce(
            long messagePumpDelegateNative, long delayedScheduledTimeTicks);
}

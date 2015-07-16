// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.memconsumer;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.widget.EditText;
import android.widget.NumberPicker;
import android.widget.TextView;

public class MemConsumer extends Activity {
    public static final String NOTIFICATION_ACTION =
            MemConsumer.class.toString() + ".NOTIFICATION";

    private ResidentService mResidentService;
    private int mMemory = 0;
    private NumberPicker mMemoryPicker;

    private ServiceConnection mServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder binder) {
            mResidentService = ((ResidentService.ServiceBinder) binder).getService();
            mResidentService.useMemory(mMemory);
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            mResidentService = null;
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mMemoryPicker = new NumberPicker(this);
        mMemoryPicker.setGravity(Gravity.CENTER);
        mMemoryPicker.setMaxValue(Integer.MAX_VALUE);
        mMemoryPicker.setMinValue(0);
        mMemoryPicker.setOnValueChangedListener(new NumberPicker.OnValueChangeListener() {
            @Override
            public void onValueChange(NumberPicker picker, int oldVal, int newVal) {
                updateMemoryConsumption(picker.getValue());
            }
        });
        for (int i = 0; i < mMemoryPicker.getChildCount(); i++) {
            View child = mMemoryPicker.getChildAt(i);
            if (child instanceof EditText) {
                EditText editText = (EditText) child;
                editText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
                    @Override
                    public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                        if (v.getText().length() > 0) {
                            updateMemoryConsumption(Integer.parseInt(v.getText().toString()));
                        }
                        return false;
                    }
                });
            }
        }
        setContentView(mMemoryPicker);
        onNewIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (intent.getAction() == NOTIFICATION_ACTION) {
            updateMemoryConsumption(0);
            return;
        }
        if (!intent.hasExtra("memory")) return;
        updateMemoryConsumption(intent.getIntExtra("memory", 0));
    }

    void updateMemoryConsumption(int memory) {
        if (memory == mMemory || memory < 0) return;
        mMemory = memory;
        mMemoryPicker.setValue(mMemory);
        if (mResidentService == null) {
            if (mMemory > 0) {
                Intent resident = new Intent();
                resident.setClass(this, ResidentService.class);
                startService(resident);
                bindService(new Intent(this, ResidentService.class),
                            mServiceConnection,
                            Context.BIND_AUTO_CREATE);
            }
        } else {
            mResidentService.useMemory(mMemory);
            if (mMemory == 0) {
                unbindService(mServiceConnection);
                stopService(new Intent(this, ResidentService.class));
                mResidentService = null;
            }
        }
    }
}

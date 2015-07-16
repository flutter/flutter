// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test.util;

import android.content.ComponentCallbacks;
import android.content.ContentResolver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.SharedPreferences;
import android.test.mock.MockContentResolver;
import android.test.mock.MockContext;

import java.util.HashMap;
import java.util.Map;

/**
 * ContextWrapper that adds functionality for SharedPreferences and a way to set and retrieve flags.
 */
public class AdvancedMockContext extends ContextWrapper {

    private final MockContentResolver mMockContentResolver = new MockContentResolver();

    private final Map<String, SharedPreferences> mSharedPreferences =
            new HashMap<String, SharedPreferences>();

    private final Map<String, Boolean> mFlags = new HashMap<String, Boolean>();

    public AdvancedMockContext(Context base) {
        super(base);
    }

    public AdvancedMockContext() {
        super(new MockContext());
    }

    @Override
    public String getPackageName() {
        return getBaseContext().getPackageName();
    }

    @Override
    public Context getApplicationContext() {
        return this;
    }

    @Override
    public ContentResolver getContentResolver() {
        return mMockContentResolver;
    }

    public MockContentResolver getMockContentResolver() {
        return mMockContentResolver;
    }

    @Override
    public SharedPreferences getSharedPreferences(String name, int mode) {
        synchronized (mSharedPreferences) {
            if (!mSharedPreferences.containsKey(name)) {
                // Auto-create shared preferences to mimic Android Context behavior
                mSharedPreferences.put(name, new InMemorySharedPreferences());
            }
            return mSharedPreferences.get(name);
        }
    }

    @Override
    public void registerComponentCallbacks(ComponentCallbacks callback) {
        getBaseContext().registerComponentCallbacks(callback);
    }

    @Override
    public void unregisterComponentCallbacks(ComponentCallbacks callback) {
        getBaseContext().unregisterComponentCallbacks(callback);
    }

    public void addSharedPreferences(String name, Map<String, Object> data) {
        synchronized (mSharedPreferences) {
            mSharedPreferences.put(name, new InMemorySharedPreferences(data));
        }
    }

    public void setFlag(String key) {
        mFlags.put(key, true);
    }

    public void clearFlag(String key) {
        mFlags.remove(key);
    }

    public boolean isFlagSet(String key) {
        return mFlags.containsKey(key) && mFlags.get(key);
    }

    /**
     * Builder for maps of type Map<String, Object> to be used with
     * {@link #addSharedPreferences(String, java.util.Map)}.
     */
    public static class MapBuilder {

        private final Map<String, Object> mData = new HashMap<String, Object>();

        public static MapBuilder create() {
            return new MapBuilder();
        }

        public MapBuilder add(String key, Object value) {
            mData.put(key, value);
            return this;
        }

        public Map<String, Object> build() {
            return mData;
        }

    }
}

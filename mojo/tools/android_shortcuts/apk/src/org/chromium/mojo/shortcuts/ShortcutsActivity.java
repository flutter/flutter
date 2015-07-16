// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.shortcuts;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.Bundle;
import android.util.JsonWriter;
import android.util.Log;

import java.io.IOException;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;

/**
 * Main activity for the shortcuts application. It installs default shortcuts and sets up the alarm
 * for the auto-update process.
 */
public class ShortcutsActivity extends Activity {
    private static final String TAG = "ShortcutsActivity";

    private static class Shortcut {
        private final String mName;
        private final String mUrl;

        public Shortcut(String name, String url) {
            mName = name;
            mUrl = url;
        }

        public String getName() {
            return mName;
        }

        public String getUrl() {
            return mUrl;
        }

        public Intent getIntent() throws IOException {
            List<String> commandLine = new ArrayList<String>();
            commandLine.add("--origin=https://domokit.github.io/mojo");
            commandLine.add("--url-mappings=mojo:window_manager=mojo:kiosk_wm");
            commandLine.add("--args-for=mojo:window_manager " + getUrl());
            commandLine.add("mojo:window_manager");
            Intent intent = new Intent();
            intent.setComponent(new ComponentName(
                    "org.chromium.mojo.shell", "org.chromium.mojo.shell.MojoShellActivity"));
            intent.setAction(Intent.ACTION_VIEW);
            intent.putExtra("encodedParameters", jsonEncode(commandLine));
            return intent;
        }

        private static String jsonEncode(List<String> list) throws IOException {
            StringWriter sw = new StringWriter();
            JsonWriter json = new JsonWriter(sw);
            json.beginArray();
            for (String p : list) {
                json.value(p);
            }
            json.endArray();
            json.close();
            return sw.toString();
        }
    }

    private static final Shortcut[] SHORTCUTS = {
            new Shortcut("Home", "https://domokit.github.io/home")};

    /**
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences shortcuts = getSharedPreferences("shortcuts", MODE_PRIVATE);
        Editor editor = shortcuts.edit();

        for (Shortcut shortcut : SHORTCUTS) {
            try {
                Intent intent = new Intent();
                intent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcut.getIntent());
                intent.putExtra(Intent.EXTRA_SHORTCUT_NAME, shortcut.getName());
                intent.setAction("com.android.launcher.action.UNINSTALL_SHORTCUT");
                sendBroadcast(intent);

                intent = new Intent();
                intent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcut.getIntent());
                intent.putExtra(Intent.EXTRA_SHORTCUT_NAME, shortcut.getName());
                intent.setAction("com.android.launcher.action.INSTALL_SHORTCUT");
                sendBroadcast(intent);
            } catch (IOException e) {
                Log.e(TAG, "Unable to install shortcut", e);
            }
            editor.putString(shortcut.getName(), shortcut.getUrl());
        }
        editor.apply();
        AlarmReceiver.setupAlarm(this);
        finish();
    }
}

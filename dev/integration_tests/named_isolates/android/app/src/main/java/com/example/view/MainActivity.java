// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.view;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BasicMessageChannel.MessageHandler;
import io.flutter.plugin.common.BasicMessageChannel.Reply;
import io.flutter.plugin.common.StringCodec;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterView;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {
    private FlutterView firstFlutterView;
    private FlutterView secondFlutterView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FlutterMain.ensureInitializationComplete(getApplicationContext(), null);
        setContentView(R.layout.flutter_view_layout);
        ActionBar supportActionBar = getSupportActionBar();
        if (supportActionBar != null) {
            supportActionBar.hide();
        }

        FlutterRunArguments firstRunArguments = new FlutterRunArguments();
        firstRunArguments.bundlePath = FlutterMain.findAppBundlePath(getApplicationContext());
        firstRunArguments.entrypoint = "first";
        firstFlutterView = findViewById(R.id.first);
        firstFlutterView.runFromBundle(firstRunArguments);

        FlutterRunArguments secondRunArguments = new FlutterRunArguments();
        secondRunArguments.bundlePath = FlutterMain.findAppBundlePath(getApplicationContext());
        secondRunArguments.entrypoint = "second";
        secondFlutterView = findViewById(R.id.second);
        secondFlutterView.runFromBundle(secondRunArguments);
    }

    @Override
    protected void onDestroy() {
        if (firstFlutterView != null) {
            firstFlutterView.destroy();
        }
        if (secondFlutterView != null) {
            secondFlutterView.destroy();
        }
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        firstFlutterView.onPause();
        secondFlutterView.onPause();
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        firstFlutterView.onPostResume();
        secondFlutterView.onPostResume();
    }
}

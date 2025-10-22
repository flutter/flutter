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
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BasicMessageChannel.MessageHandler;
import io.flutter.plugin.common.BasicMessageChannel.Reply;
import io.flutter.plugin.common.StringCodec;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {
    private static FlutterEngine flutterEngine;

    private FlutterView flutterView;
    private int counter;
    private static final String CHANNEL = "increment";
    private static final String EMPTY_MESSAGE = "";
    private static final String PING = "ping";
    private BasicMessageChannel<String> messageChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (flutterEngine == null) {
            flutterEngine = new FlutterEngine(this);
            flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartEntrypoint.createDefault()
            );
        }
        setContentView(R.layout.flutter_view_layout);
        ActionBar supportActionBar = getSupportActionBar();
        if (supportActionBar != null) {
            supportActionBar.hide();
        }

        flutterView = findViewById(R.id.flutter_view);
        flutterView.attachToFlutterEngine(flutterEngine);

        messageChannel = new BasicMessageChannel<>(flutterEngine.getDartExecutor(), CHANNEL, StringCodec.INSTANCE);
        messageChannel.
            setMessageHandler(new MessageHandler<String>() {
                @Override
                public void onMessage(String s, Reply<String> reply) {
                    onFlutterIncrement();
                    reply.reply(EMPTY_MESSAGE);
                }
            });

        FloatingActionButton fab = findViewById(R.id.button);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                sendAndroidIncrement();
            }
        });
    }

    private void sendAndroidIncrement() {
        messageChannel.send(PING);
    }

    private void onFlutterIncrement() {
        counter++;
        TextView textView = findViewById(R.id.button_tap);
        String value = "Flutter button tapped " + counter + (counter == 1 ? " time" : " times");
        textView.setText(value);
    }

    @Override
    protected void onResume() {
        super.onResume();
        flutterEngine.getLifecycleChannel().appIsResumed();
    }

    @Override
    protected void onPause() {
        super.onPause();
        flutterEngine.getLifecycleChannel().appIsInactive();
    }

    @Override
    protected void onStop() {
        super.onStop();
        flutterEngine.getLifecycleChannel().appIsPaused();
    }

    @Override
    protected void onDestroy() {
        flutterView.detachFromFlutterEngine();
        super.onDestroy();
    }
}

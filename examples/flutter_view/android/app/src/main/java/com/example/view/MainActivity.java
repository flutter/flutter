package com.example.view;

import android.content.Intent;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.TextView;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BasicMessageChannel.MessageHandler;
import io.flutter.plugin.common.BasicMessageChannel.Reply;
import io.flutter.plugin.common.StringCodec;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterView;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {
    private FlutterView flutterView;
    private int counter;
    private static final String CHANNEL = "increment";
    private static final String EMPTY_MESSAGE = "";
    private static final String PING = "ping";
    private BasicMessageChannel<String> messageChannel;

    private String[] getArgsFromIntent(Intent intent) {
        // Before adding more entries to this list, consider that arbitrary
        // Android applications can generate intents with extra data and that
        // there are many security-sensitive args in the binary.
        ArrayList<String> args = new ArrayList<>();
        if (intent.getBooleanExtra("trace-startup", false)) {
            args.add("--trace-startup");
        }
        if (intent.getBooleanExtra("start-paused", false)) {
            args.add("--start-paused");
        }
        if (intent.getBooleanExtra("enable-dart-profiling", false)) {
            args.add("--enable-dart-profiling");
        }
        if (!args.isEmpty()) {
            String[] argsArray = new String[args.size()];
            return args.toArray(argsArray);
        }
        return null;
    }



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        String[] args = getArgsFromIntent(getIntent());
        FlutterMain.ensureInitializationComplete(getApplicationContext(), args);
        setContentView(R.layout.flutter_view_layout);
        ActionBar supportActionBar = getSupportActionBar();
        if (supportActionBar != null) {
            supportActionBar.hide();
        }

        FlutterRunArguments runArguments = new FlutterRunArguments();
        runArguments.bundlePath = FlutterMain.findAppBundlePath(getApplicationContext());
        runArguments.entrypoint = "main";

        flutterView = findViewById(R.id.flutter_view);
        flutterView.runFromBundle(runArguments);

        messageChannel = new BasicMessageChannel<>(flutterView, CHANNEL, StringCodec.INSTANCE);
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
    protected void onDestroy() {
        if (flutterView != null) {
            flutterView.destroy();
        }
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        flutterView.onPause();
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        flutterView.onPostResume();
    }
}

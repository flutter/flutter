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

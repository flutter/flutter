package com.yourcompany.full_platform_view;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
//
import java.util.ArrayList;
//
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

public class MainActivity extends AppCompatActivity  {
  private FlutterView flutterView;

  private static final String CHANNEL = "samples.flutter.io/full_screen";
  private static final String EMPTY_MESSAGE = "";
  static final int COUNT_REQUEST = 42;

  private BasicMessageChannel messageChannel;
  private String[] getArgsFromIntent(Intent intent) {
    // Before adding more entries to this list, consider that arbitrary
    // Android applications can generate intents with extra data and that
    // there are many security-sensitive args in the binary.
    ArrayList<String> args = new ArrayList<String>();
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
   // GeneratedPluginRegistrant.registerWith(this);

    String[] args = getArgsFromIntent(getIntent());
    FlutterMain.ensureInitializationComplete(getApplicationContext(), args);
    setContentView(R.layout.flutter_view_layout);

    flutterView = (FlutterView) findViewById(R.id.flutter_view);
    flutterView.runFromBundle(FlutterMain.findAppBundlePath(getApplicationContext()), null);
    messageChannel = new BasicMessageChannel<>(flutterView, CHANNEL, StringCodec.INSTANCE);
    messageChannel.
            setMessageHandler(new BasicMessageChannel.MessageHandler<String>() {
              @Override
              public void onMessage(String s, BasicMessageChannel.Reply<String> reply) {
                onlaunchFullScreen(5);
                reply.reply(EMPTY_MESSAGE);
              }
            });
  }

  private void onlaunchFullScreen(int count) {
    Intent fullScreenIntent = new Intent(this, CountActivity.class);
    fullScreenIntent.putExtra("count", count);
    startActivityForResult(fullScreenIntent,COUNT_REQUEST);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {

    System.out.println("JUHUUUU result" + resultCode + "request code " + requestCode + "data " + data.getIntExtra("count", 0));
    System.out.println("Flutter view : " + flutterView);
    if (requestCode == COUNT_REQUEST) {
      if (resultCode == RESULT_OK) {
        messageChannel.send("7");
      }
    }
   // flutterView.onPostResume();
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

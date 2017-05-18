package com.yourcompany.full_platform_view;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
//
import java.util.ArrayList;
//
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StringCodec;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

public class MainActivity extends FlutterActivity  {
  private FlutterView flutterView;

  private static final String CHANNEL = "samples.flutter.io/full_screen";
  private static final String METHOD_CHANNEL = "samples.flutter.io/full";

  private static final String EMPTY_MESSAGE = "";
  static final int COUNT_REQUEST = 42;

  private BasicMessageChannel messageChannel;


  private MethodChannel.Result result;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

//    flutterView = getFlutterView();
//    messageChannel = new BasicMessageChannel<>(flutterView, CHANNEL, StringCodec.INSTANCE);
//    messageChannel.
//            setMessageHandler(new BasicMessageChannel.MessageHandler<String>() {
//              @Override
//              public void onMessage(String s, BasicMessageChannel.Reply<String> reply) {
//                onlaunchFullScreen(5);
//                reply.reply(EMPTY_MESSAGE);
//              }
//            });

    new MethodChannel(getFlutterView(), METHOD_CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {

              @Override
              public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                MainActivity.this.result = result;
                int count = methodCall.arguments();
                if (methodCall.method.equals("launch")) {
                  onlaunchFullScreen(count);
                } else {
                  result.notImplemented();
                }
              }
            }
    );
  }

  private void onlaunchFullScreen(int count) {
    System.out.println("launch full screen with count  " + count);
    Intent fullScreenIntent = new Intent(this, CountActivity.class);
    fullScreenIntent.putExtra("count", count);
    startActivityForResult(fullScreenIntent,COUNT_REQUEST);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == COUNT_REQUEST) {
      if (resultCode == RESULT_OK) {
        System.out.println("Getting back with counter " + data.getIntExtra("count", 0));
        result.success(data.getIntExtra("count", 0));
     //   messageChannel.send("7");
      } else {
        result.error(null, null, null);

      }
    }
  }
}

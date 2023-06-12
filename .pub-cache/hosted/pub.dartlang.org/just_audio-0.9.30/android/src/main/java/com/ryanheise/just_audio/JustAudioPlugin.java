package com.ryanheise.just_audio;

import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngine.EngineLifecycleListener;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * JustAudioPlugin
 */
public class JustAudioPlugin implements FlutterPlugin {
    private MethodChannel channel;
    private MainMethodCallHandler methodCallHandler;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Context applicationContext = binding.getApplicationContext();
        BinaryMessenger messenger = binding.getBinaryMessenger();
        methodCallHandler = new MainMethodCallHandler(applicationContext, messenger);

        channel = new MethodChannel(messenger, "com.ryanheise.just_audio.methods");
        channel.setMethodCallHandler(methodCallHandler);
        @SuppressWarnings("deprecation")
        FlutterEngine engine = binding.getFlutterEngine();
        engine.addEngineLifecycleListener(new EngineLifecycleListener() {
            @Override
            public void onPreEngineRestart() {
                methodCallHandler.dispose();
            }

            @Override
            public void onEngineWillDestroy() {
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodCallHandler.dispose();
        methodCallHandler = null;

        channel.setMethodCallHandler(null);
    }
}

package com.ryanheise.audio_session;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/** AudioSessionPlugin */
public class AudioSessionPlugin implements FlutterPlugin, MethodCallHandler {
    private static Map<?, ?> configuration;
    private static List<AudioSessionPlugin> instances = new ArrayList<>();
    private MethodChannel channel;
    private AndroidAudioManager androidAudioManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        BinaryMessenger messenger = flutterPluginBinding.getBinaryMessenger();
        channel = new MethodChannel(messenger, "com.ryanheise.audio_session");
        channel.setMethodCallHandler(this);
        androidAudioManager = new AndroidAudioManager(flutterPluginBinding.getApplicationContext(), messenger);
        instances.add(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        androidAudioManager.dispose();
        androidAudioManager = null;
        instances.remove(this);
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        List<?> args = (List<?>)call.arguments;
        switch (call.method) {
        case "setConfiguration": {
            configuration = (Map<?, ?>)args.get(0);
            result.success(null);
            invokeMethod("onConfigurationChanged", configuration);
            break;
        }
        case "getConfiguration": {
            result.success(configuration);
            break;
        }
        default:
            result.notImplemented();
            break;
        }
    }

    private void invokeMethod(String method, Object... args) {
        for (AudioSessionPlugin instance : instances) {
            ArrayList<Object> list = new ArrayList<Object>(Arrays.asList(args));
            instance.channel.invokeMethod(method, list);
        }
    }
}

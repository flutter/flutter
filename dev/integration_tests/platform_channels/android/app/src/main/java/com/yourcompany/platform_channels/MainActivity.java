package com.yourcompany.platform_channels;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.StringCodec;
import io.flutter.plugins.PluginRegistry;

public class MainActivity extends FlutterActivity {
    PluginRegistry pluginRegistry;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        pluginRegistry = new PluginRegistry();
        pluginRegistry.registerAll(this);

        final BasicMessageChannel<String> basicStringChannel = new BasicMessageChannel<>(getFlutterView(), "basic-msg-string", StringCodec.INSTANCE);
        basicStringChannel.setMessageHandler(new BasicMessageChannel.MessageHandler<String>() {
            @Override
            public void onMessage(final String message, final BasicMessageChannel.Reply<String> reply) {
                basicStringChannel.send(message, new BasicMessageChannel.Reply<String>() {
                    @Override
                    public void reply(String replyMessage) {
                        basicStringChannel.send(replyMessage);
                        reply.reply(message);
                    }
                });
            }
        });

        final BasicMessageChannel<Object> basicJsonChannel = new BasicMessageChannel<>(getFlutterView(), "basic-msg-json", JSONMessageCodec.INSTANCE);
        basicJsonChannel.setMessageHandler(new BasicMessageChannel.MessageHandler<Object>() {
            @Override
            public void onMessage(final Object message, final BasicMessageChannel.Reply<Object> reply) {
                basicJsonChannel.send(message, new BasicMessageChannel.Reply<Object>() {
                    @Override
                    public void reply(Object replyMessage) {
                        basicJsonChannel.send(replyMessage);
                        reply.reply(message);
                    }
                });
            }
        });
    }
}

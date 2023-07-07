package com.itsclicking.clickapp.fluttersocketio;

import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public interface ISocketIOManager {
    void init(MethodChannel channel, String domain, String namespace, String query, String callback);
    void connect(String domain, String namespace);
    void subscribes(String domain, String namespace, Map<String, String> subscribes);
    void unSubscribes(String domain, String namespace, Map<String, String> subscribes);
    void unSubscribesAll(String domain, String namespace);
    void sendMessage(String domain, String namespace, String event, String message, String callback);
    void disconnect(String domain, String namespace);
    void destroySocket(String domain, String namespace);
    void destroyAllSockets();
}

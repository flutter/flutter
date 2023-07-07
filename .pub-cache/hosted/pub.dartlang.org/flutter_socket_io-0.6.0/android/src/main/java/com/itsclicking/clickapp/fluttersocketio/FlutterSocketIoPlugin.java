package com.itsclicking.clickapp.fluttersocketio;

import com.google.gson.Gson;

import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterSocketIoPlugin
 */
public class FlutterSocketIoPlugin implements MethodCallHandler {

    private static final String TAG = "FlutterSocketIoPlugin";
    private MethodChannel _channel;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_socket_io");
        channel.setMethodCallHandler(new FlutterSocketIoPlugin(channel));
    }

    private FlutterSocketIoPlugin(MethodChannel channel) {
        _channel = channel;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        String socketNameSpace = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_NAME_SPACE);
        String socketDomain = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_DOMAIN);
        String callback = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_CALLBACK);

        Utils.log(TAG, "onMethodCall: " + call.method + " - domain: " + socketDomain + " - with namespace: " + socketNameSpace);

        switch (call.method) {
            case SocketIOManager.MethodCallName.SOCKET_INIT:
                String query = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_QUERY);
                SocketIOManager.getInstance().init(_channel, socketDomain, socketNameSpace, query, callback);
                break;

            case SocketIOManager.MethodCallName.SOCKET_CONNECT:
                SocketIOManager.getInstance().connect(socketDomain, socketNameSpace);
                break;

            case SocketIOManager.MethodCallName.SOCKET_DISCONNECT:
                SocketIOManager.getInstance().disconnect(socketDomain, socketNameSpace);
                break;

            case SocketIOManager.MethodCallName.SOCKET_SUBSCRIBES:
                String socketData = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_DATA);
                Map<String, String> map = Utils.convertJsonToMap(socketData);
                Utils.log(TAG, "socketData: " + new Gson().toJson(map));
                SocketIOManager.getInstance().subscribes(socketDomain, socketNameSpace, map);
                break;

            case SocketIOManager.MethodCallName.SOCKET_UNSUBSCRIBES_ALL:
                SocketIOManager.getInstance().unSubscribesAll(socketDomain, socketNameSpace);
                break;

            case SocketIOManager.MethodCallName.SOCKET_UNSUBSCRIBES:
                String jsonData = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_DATA);
                Map<String, String> params = Utils.convertJsonToMap(jsonData);
                SocketIOManager.getInstance().unSubscribes(socketDomain, socketNameSpace, params);
                break;

            case SocketIOManager.MethodCallName.SOCKET_SEND_MESSAGE:
                String event = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_EVENT);
                String message = call.argument(SocketIOManager.MethodCallArgumentsName.SOCKET_MESSAGE);
                if (!Utils.isNullOrEmpty(event) && message != null) {
                    SocketIOManager.getInstance().sendMessage(socketDomain, socketNameSpace, event, message, callback);
                } else {
                    Utils.log(TAG, "send message with invalid params:" + "Event: " + event + " - with message: " + new Gson().toJson(message));
                }
                break;

            case SocketIOManager.MethodCallName.SOCKET_DESTROY:
                SocketIOManager.getInstance().destroySocket(socketDomain, socketNameSpace);
                break;

            case SocketIOManager.MethodCallName.SOCKET_DESTROY_ALL:
                SocketIOManager.getInstance().destroyAllSockets();
                break;

            default:
                result.notImplemented();
                break;
        }
    }
}

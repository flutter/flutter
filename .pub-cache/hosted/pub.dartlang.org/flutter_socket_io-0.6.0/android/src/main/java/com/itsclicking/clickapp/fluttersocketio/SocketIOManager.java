package com.itsclicking.clickapp.fluttersocketio;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class SocketIOManager implements ISocketIOManager {

    private static final String TAG = "SocketIOManager";
    private static ISocketIOManager mInstance;
    private Map<String, SocketIO> mSockets;


    public synchronized static ISocketIOManager getInstance() {
        if (mInstance == null) {
            mInstance = new SocketIOManager();
        }
        return mInstance;
    }

    private SocketIOManager() {
        mSockets = new HashMap<>();
    }

    private SocketIO getSocket(String socketId) {
        if(mSockets != null && !Utils.isNullOrEmpty(socketId)) {
            Utils.log("TOTAL SOCKETS: ", String.valueOf(mSockets.size()));
            return mSockets.get(socketId);
        } else {
            Utils.log("TOTAL SOCKETS: ", "NULL");
        }
        return null;
    }

    private boolean isExistedSocketIO(String socketId) {
        SocketIO socketIO = getSocket(socketId);
        return (socketIO != null);
    }

    private void addSocketIO(SocketIO socketIO) {
        if(mSockets == null) {
            mSockets = new HashMap<>();
        }
        if(!isExistedSocketIO(socketIO.getId())) {
            Utils.log("added SocketIO", socketIO.getId());
            mSockets.put(socketIO.getId(), socketIO);
        }
    }

    private void removeSocketIO(SocketIO socketIO) {
        if(mSockets != null) {
            mSockets.remove(socketIO.getId());
        }
    }

    private boolean isConnected(SocketIO socketIO) {
        return socketIO != null && socketIO.isConnected();
    }

    private String getSocketId(String domain, String namespace) {
        if(!Utils.isNullOrEmpty(domain)) {
            return domain + (namespace != null ? namespace : "");
        }
        return null;
    }

    private SocketIO createSocketIO(MethodChannel channel, String domain,
                                    String namespace, String query, String callback) {
        return new SocketIO(channel, domain, namespace, query, callback);
    }

    @Override
    public void init(MethodChannel channel, String domain, String namespace, String query, String callback) {
        if(isExistedSocketIO(getSocketId(domain, namespace))) {
            Utils.log(TAG, "socket: " + getSocketId(domain, namespace) + " already existed!");
        } else {
            SocketIO socketIO = createSocketIO(channel, domain, namespace, query, callback);
            addSocketIO(socketIO);
            socketIO.init();
        }
    }

    @Override
    public void connect(String domain, String namespace) {
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.connect();
        } else {
            Utils.log(TAG, "socket: " + getSocketId(domain, namespace) + " is not initialized!");
        }
    }

    @Override
    public void sendMessage(String domain, String namespace, String event, String message, String callback) {
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.sendMessage(event, message, callback);
        } else {
            Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
        }
    }

    @Override
    public void subscribes(String domain, String namespace, Map<String, String> subscribes) {
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.subscribes(subscribes);
        } else {
            Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
        }
    }

    @Override
    public void unSubscribes(String domain, String namespace, Map<String, String> subscribes) {
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.unSubscribes(subscribes);
        } else {
            Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
        }
    }

    @Override
    public void unSubscribesAll(String domain, String namespace) {
        Utils.log(TAG, "--- START unSubscribesAll ---");
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.unSubscribesAll();
        } else {
            Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
        }
        Utils.log(TAG, "--- END unSubscribesAll ---");
    }

    @Override
    public void disconnect(String domain, String namespace) {
        Utils.log(TAG, "--- START disconnect ---");
        SocketIO socketIO = getSocket(getSocketId(domain, namespace));
        if(socketIO != null) {
            socketIO.disconnect();
        } else {
            Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
        }
        Utils.log(TAG, "--- END disconnect ---");
    }

    @Override
    public void destroySocket(String domain, String namespace) {
        if(!Utils.isNullOrEmpty(mSockets)) {
            SocketIO socketIO = getSocket(getSocketId(domain, namespace));
            if(socketIO != null) {
                removeSocketIO(socketIO);
                socketIO.destroy();
            }  else {
                Utils.log(TAG, " not found socket: " + getSocketId(domain, namespace));
            }
        }
    }

    @Override
    public void destroyAllSockets() {
        if(!Utils.isNullOrEmpty(mSockets)) {
            for(Map.Entry<String, SocketIO> item : mSockets.entrySet()) {
                if(item != null) {
                    SocketIO socket = item.getValue();
                    if(socket != null) {
                        socket.destroy();
                    }
                }
            }
            mSockets.clear();
        }
    }

    public static class MethodCallArgumentsName {
        public static final String SOCKET_DOMAIN = "socketDomain";
        public static final String SOCKET_NAME_SPACE = "socketNameSpace";
        public static final String SOCKET_CALLBACK = "socketCallback";
        public static final String SOCKET_EVENT = "socketEvent";
        public static final String SOCKET_MESSAGE = "socketMessage";
        public static final String SOCKET_DATA = "socketData";
        public static final String SOCKET_QUERY = "socketQuery";
    }

    public static class MethodCallName {
        public static final String SOCKET_INIT = "socketInit";
        public static final String SOCKET_CONNECT = "socketConnect";
        public static final String SOCKET_DISCONNECT = "socketDisconnect";
        public static final String SOCKET_SUBSCRIBES = "socketSubcribes";
        public static final String SOCKET_UNSUBSCRIBES = "socketUnsubcribes";
        public static final String SOCKET_UNSUBSCRIBES_ALL = "socketUnsubcribesAll";
        public static final String SOCKET_SEND_MESSAGE = "socketSendMessage";
        public static final String SOCKET_DESTROY = "socketDestroy";
        public static final String SOCKET_DESTROY_ALL = "socketDestroyAll";
    }
}

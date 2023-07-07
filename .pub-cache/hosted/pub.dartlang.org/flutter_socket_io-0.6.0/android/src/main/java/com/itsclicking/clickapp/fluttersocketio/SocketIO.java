package com.itsclicking.clickapp.fluttersocketio;

import android.os.Handler;
import android.os.Looper;

import com.google.gson.Gson;

import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentMap;

import io.flutter.plugin.common.MethodChannel;
import io.socket.client.Ack;
import io.socket.client.IO;
import io.socket.client.Manager;
import io.socket.client.Socket;
import io.socket.client.Url;
import io.socket.emitter.Emitter;
import io.socket.engineio.client.transports.WebSocket;

public class SocketIO {

    private static final String TAG = "SocketIO";

    private MethodChannel _methodChannel;
    private String _domain;
    private String _namespace;
    private String _statusCallback;
    private String _query;
    private Socket _socket;
    private IO.Options mOptions;
    private ConcurrentMap<String, ConcurrentLinkedQueue<SocketListener>> _subscribes;
    private static final ConcurrentHashMap<String, Manager> managers = new ConcurrentHashMap<String, Manager>();

    public SocketIO(MethodChannel methodChannel, String domain,
                    String namespace, String query, String statusCallback) {
        _methodChannel = methodChannel;
        _domain = domain;
        _namespace = namespace;
        _query = query;
        _statusCallback = statusCallback;
        _subscribes = new ConcurrentHashMap<>();
    }

    private void removeChannelAll() {
        if (_subscribes != null) {
            _subscribes.clear();
        }
    }

    private String getSocketUrl() {
        return _domain + (_namespace == null ? "" : _namespace);
    }

    private void dumpChannelsCount() {
        if (!Utils.isNullOrEmpty(_subscribes)) {
            Utils.log("socketInfo", "SUBSCRIBES SIZES: " + _subscribes.size());
            for (Map.Entry<String, ConcurrentLinkedQueue<SocketListener>> item : _subscribes.entrySet()) {
                ConcurrentLinkedQueue<SocketListener> listeners = item.getValue();
                if (listeners == null) {
                    Utils.log("socketInfo", "CHANNEL: " + item.getKey() + " with TOTAL LISTENERS: NULL");
                } else {
                    Utils.log("socketInfo", "CHANNEL: " + item.getKey() + " with TOTAL LISTENERS: " + listeners.size());
                }
            }
        } else {
            Utils.log("socketInfo", "SUBSCRIBES SIZES: NULL or EMPTY");
        }
    }

    private Socket getSocket() {
        URI source;
        URL parsed;

        try {
            URI uri = new URI(getSocketUrl());
            parsed = Url.parse(uri);
            source = parsed.toURI();
        } catch (URISyntaxException e) {
            throw new RuntimeException(e);
        }

        mOptions = new IO.Options();
        mOptions.transports = new String[]{WebSocket.NAME};

        if (!Utils.isNullOrEmpty(_query)) {
            Utils.log(TAG, "query: " + _query);
            mOptions.query = _query;
        }

        String id = Url.extractId(parsed);
        boolean newConnection = !managers.containsKey(id);
        Manager io;

        if (newConnection) {
            io = new Manager(source, mOptions);
            managers.putIfAbsent(id, io);
        } else {
            if (!managers.containsKey(id)) {
                managers.putIfAbsent(id, new Manager(source, mOptions));
            }
            io = managers.get(id);
        }

        return io.socket(_namespace, mOptions);
    }

    public String getId() {
        return getSocketUrl();
    }

    private void onSocketCallback(final String status, Object... args) {
        if (_methodChannel != null && !Utils.isNullOrEmpty(_statusCallback)) {
            final Handler _handler = new Handler(Looper.getMainLooper());
            _handler.post(new Runnable() {
                @Override
                public void run() {
                    _methodChannel.invokeMethod(getId() + "|" + _statusCallback + "|" + _statusCallback, status);
                }
            });
        }
        if (args != null) {
            Utils.log(TAG, status + ": " + new Gson().toJson(args));
        }
    }

    public void init() {
        if (_socket != null) {
            if (_socket.connected()) {
                _socket.disconnect();
            }
            _socket = null;
        }

        _socket = getSocket();

        Utils.log(TAG, "connecting..." + _socket.id());

        //start listen connection events
        _socket.on(Socket.EVENT_CONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_CONNECT, args);
            }
        }).on(Socket.EVENT_RECONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_RECONNECT, args);
            }
        }).on(Socket.EVENT_RECONNECTING, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_RECONNECTING, args);
            }
        }).on(Socket.EVENT_RECONNECT_ATTEMPT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_RECONNECT_ATTEMPT, args);
            }
        }).on(Socket.EVENT_RECONNECT_FAILED, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_RECONNECT_FAILED, args);
            }
        }).on(Socket.EVENT_RECONNECT_ERROR, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_RECONNECT_ERROR, args);
            }
        }).on(Socket.EVENT_CONNECT_TIMEOUT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_CONNECT_TIMEOUT, args);
            }
        }).on(Socket.EVENT_DISCONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_DISCONNECT, args);
            }
        }).on(Socket.EVENT_CONNECT_ERROR, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                onSocketCallback(Socket.EVENT_CONNECT_ERROR, args);
            }
        });
        //end listen connection events
    }

    public void connect() {
        if (_socket == null) {
            Utils.log(TAG, "socket: " + getId() + " is not initialized!");
            return;
        }
        if (_socket.connected()) {
            Utils.log(TAG, "socket: " + getId() + " is already connected");
            return;
        }
        Utils.log(TAG, "connecting socket: " + getId());
        _socket.connect();
    }

    public void sendMessage(String event, String message, final String callback) {

        if (Utils.isNullOrEmpty(event) || Utils.isNullOrEmpty(message)) {
            Utils.log("sendMessage", "Invalid params: event or message is NULL or EMPTY!");
        } else if (isConnected()) {
            Utils.log("sendMessage", "Event: " + event + " - with message: " + message);
            JSONObject jb = null;
            try {
                jb = new JSONObject(message);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            if (jb != null) {
                final SocketListener listener = new SocketListener(_methodChannel, getId(), event, callback);
                _socket.emit(event, jb, new Ack() {
                    @Override
                    public void call(Object... args) {
                        listener.call(args);
                    }
                });
            }
        }

    }

    public void subscribe(String event, final String callback) {
        Utils.log("subscribe", "channel: " + event + " - with callback: " + callback);
        if (Utils.isNullOrEmpty(event)) {
            Utils.log("subscribe", "Invalid params: event is NULL/EMPTY!");
        } else {
            if (_socket != null) {
                dumpChannelsCount();
                ConcurrentLinkedQueue<SocketListener> listeners = _subscribes.get(event);

                if (listeners == null) {
                    listeners = new ConcurrentLinkedQueue<>();
                }

                SocketListener listener = new SocketListener(_methodChannel, getId(), event, callback);

                if (!Utils.isNullOrEmpty(callback) && !Utils.isExisted(listeners, callback)) {
                    listeners.add(listener);
                }

                _subscribes.put(event, listeners);
                _socket.on(event, listener);

                dumpChannelsCount();
            } else {
                Utils.log("subscribe", "socket is NULL");
            }
        }
    }

    public void subscribes(Map<String, String> subscribes) {
        if (Utils.isNullOrEmpty(subscribes)) {
            Utils.log("subscribes", "Subscribes list is NULL or EMPTY!");
        } else if (_socket != null) {
            Utils.log(TAG, "--- subscribes ---" + new Gson().toJson(subscribes));
            for (Map.Entry<String, String> sub : subscribes.entrySet()) {
                if (!Utils.isNullOrEmpty(sub.getKey())) {
                    subscribe(sub.getKey(), sub.getValue());
                }
            }
        }
    }

    public void unSubscribe(String eventName, final String callback) {
        Utils.log("unSubscribe", "channel: " + eventName + " - with callback: " + callback);
        if (Utils.isNullOrEmpty(eventName)) {
            Utils.log("unSubscribe", "Invalid params: event is NULL or EMPTY!");
        } else {
            if (_socket != null) {
                dumpChannelsCount();
                ConcurrentLinkedQueue<SocketListener> listeners = _subscribes.get(eventName);
                if (listeners == null || Utils.isNullOrEmpty(callback)) {
                    _subscribes.remove(eventName);
                    _socket.off(eventName);
                } else {
                    SocketListener listener = Utils.findListener(listeners, callback);
                    if (listener != null) {
                        listeners.remove(listener);
                        if (listeners.size() < 1) {
                            _subscribes.remove(eventName);
                            _socket.off(eventName);
                        } else {
                            _subscribes.put(eventName, listeners);
                            _socket.off(eventName, listener);
                        }
                    }
                }
                dumpChannelsCount();
            } else {
                Utils.log("unSubscribe", "socket is NULL");
            }
        }
    }

    public void unSubscribes(Map<String, String> unSubscribes) {
        if (Utils.isNullOrEmpty(unSubscribes)) {
            Utils.log("unSubscribes", "unSubscribes list is NULL or EMPTY!");
        } else if (_socket != null) {
            Utils.log(TAG, "--- unSubscribes ---" + new Gson().toJson(unSubscribes));
            for (Map.Entry<String, String> sub : unSubscribes.entrySet()) {
                if (!Utils.isNullOrEmpty(sub.getKey())) {
                    unSubscribe(sub.getKey(), sub.getValue());
                }
            }
        }
    }

    public void unSubscribesAll() {
        if (_socket != null && !Utils.isNullOrEmpty(_subscribes)) {
            for (Map.Entry<String, ConcurrentLinkedQueue<SocketListener>> sub : _subscribes.entrySet()) {
                if (!Utils.isNullOrEmpty(sub.getKey())) {
                    unSubscribe(sub.getKey(), null);
                }
            }
        }
    }

    public boolean isConnected() {
        if (_socket != null) {
            Utils.log(TAG, "socket id: " + getId() + " is connected: " + _socket.connected());
            return _socket.connected();
        } else {
            Utils.log(TAG, "socket id: " + getId() + " is NULL");
        }
        return false;
    }

    public void disconnect() {
        if (_socket != null) {
            _socket.disconnect();
        }
    }

    public void destroy() {
        Utils.log(TAG, "--- START destroy ---");
        disconnect();
        unSubscribesAll();
        removeChannelAll();
        _socket = null;
        _namespace = null;
        _statusCallback = null;
        mOptions = null;
        _methodChannel = null;
        _subscribes = null;
        managers.clear();
        Utils.log(TAG, "--- END destroy ---");
    }
}

package com.itsclicking.clickapp.fluttersocketio;

import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentMap;

public class Utils {

    public static boolean isExisted(ConcurrentMap<String, ConcurrentLinkedQueue<SocketListener>> subscribes, String channel) {
        return !Utils.isNullOrEmpty(subscribes) && subscribes.containsKey(channel);
    }

    public static boolean isExisted(ConcurrentLinkedQueue<SocketListener> listeners, SocketListener listener) {
        if(!Utils.isNullOrEmpty(listeners)) {
            for (SocketListener item : listeners) {
                if(item != null && item.equals(listener)) {
                    return true;
                }
            }
        }
        return false;
    }

    public static SocketListener findListener(ConcurrentLinkedQueue<SocketListener> listeners, String callback) {
        if(!Utils.isNullOrEmpty(listeners)) {
            for (SocketListener item : listeners) {
                if(item != null && item.getCallback().equals(callback)) {
                    return item;
                }
            }
        }
        return null;
    }

    public static boolean isExisted(ConcurrentLinkedQueue<SocketListener> listeners, String callback) {
        if(!Utils.isNullOrEmpty(listeners)) {
            for (SocketListener item : listeners) {
                if(item != null && item.getCallback().equals(callback)) {
                    return true;
                }
            }
        }
        return false;
    }

    public static Map<String, String> convertJsonToMap(String json) {
        if (!isNullOrEmpty(json)) {
            Gson gson = new Gson();
            Type dataType = new TypeToken<HashMap<String, String>>(){}.getType();
            try {
                return gson.fromJson(json, dataType);
            } catch (JsonSyntaxException ex) {
                ex.printStackTrace();
                return null;
            }
        }
        return null;
    }

    public static boolean isNullOrEmpty(String text) {
        return text == null || text.isEmpty();
    }

    public static boolean isNullOrEmpty(Map map) {
        return map == null || map.isEmpty();
    }

    public static boolean isNullOrEmpty(ConcurrentLinkedQueue list) {
        return list == null || list.isEmpty();
    }

    public static boolean isNullOrEmpty(List list) {
        return list == null || list.isEmpty();
    }

    public static void log(String tag, String text) {
        if (BuildConfig.DEBUG) {
            Log.d("FlutterSocketIoPlugin: " + tag, text);
        }
    }
}

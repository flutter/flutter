package io.flutter.plugin.common;

import java.lang.reflect.Array;
import java.util.Collection;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;

public class JSONUtil {
    private JSONUtil() {
    }

    /**
     * Backport of {@link JSONObject#wrap(Object)} for use on pre-KitKat
     * systems.
     */
    public static Object wrap(Object o) {
        if (o == null) {
            return JSONObject.NULL;
        }
        if (o instanceof JSONArray || o instanceof JSONObject) {
            return o;
        }
        if (o.equals(JSONObject.NULL)) {
            return o;
        }
        try {
            if (o instanceof Collection) {
                JSONArray result = new JSONArray();
                for (Object e : (Collection) o)
                    result.put(wrap(e));
                return result;
            } else if (o.getClass().isArray()) {
                JSONArray result = new JSONArray();
                int length = Array.getLength(o);
                for (int i = 0; i < length; i++)
                    result.put(wrap(Array.get(o, i)));
                return result;
            }
            if (o instanceof Map) {
                JSONObject result = new JSONObject();
                for (Map.Entry<?, ?> entry: ((Map<?, ?>) o).entrySet())
                    result.put((String) entry.getKey(), wrap(entry.getValue()));
                return result;
            }
            if (o instanceof Boolean ||
                o instanceof Byte ||
                o instanceof Character ||
                o instanceof Double ||
                o instanceof Float ||
                o instanceof Integer ||
                o instanceof Long ||
                o instanceof Short ||
                o instanceof String) {
                return o;
            }
            if (o.getClass().getPackage().getName().startsWith("java.")) {
                return o.toString();
            }
        } catch (Exception ignored) {
        }
        return null;
    }
}

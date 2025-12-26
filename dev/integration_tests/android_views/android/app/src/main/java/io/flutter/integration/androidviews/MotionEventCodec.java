// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.integration.platformviews;

import android.annotation.TargetApi;
import android.os.Build;
import android.view.MotionEvent;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import static android.view.MotionEvent.PointerCoords;
import static android.view.MotionEvent.PointerProperties;

@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
public class MotionEventCodec {
    private static long MOTION_EVENT_ID = 1;

    public static HashMap<String, Object> encode(MotionEvent event) {
        ArrayList<HashMap<String,Object>> pointerProperties = new ArrayList<>();
        ArrayList<HashMap<String,Object>> pointerCoords = new ArrayList<>();

        for (int i = 0; i < event.getPointerCount(); i++) {
            MotionEvent.PointerProperties properties = new MotionEvent.PointerProperties();
            event.getPointerProperties(i, properties);
            pointerProperties.add(encodePointerProperties(properties));

            MotionEvent.PointerCoords coords = new MotionEvent.PointerCoords();
            event.getPointerCoords(i, coords);
            pointerCoords.add(encodePointerCoords(coords));
        }

        HashMap<String, Object> eventMap = new HashMap<>();
        eventMap.put("downTime", event.getDownTime());
        eventMap.put("eventTime", event.getEventTime());
        eventMap.put("action", event.getAction());
        eventMap.put("pointerCount", event.getPointerCount());
        eventMap.put("pointerProperties", pointerProperties);
        eventMap.put("pointerCoords", pointerCoords);
        eventMap.put("metaState", event.getMetaState());
        eventMap.put("buttonState", event.getButtonState());
        eventMap.put("xPrecision", event.getXPrecision());
        eventMap.put("yPrecision", event.getYPrecision());
        eventMap.put("deviceId", event.getDeviceId());
        eventMap.put("edgeFlags", event.getEdgeFlags());
        eventMap.put("source", event.getSource());
        eventMap.put("flags", event.getFlags());
        eventMap.put("motionEventId", MOTION_EVENT_ID++);

        return eventMap;
    }

    private static HashMap<String, Object> encodePointerProperties(PointerProperties properties) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("id", properties.id);
        map.put("toolType", properties.toolType);
        return map;
    }

    private static HashMap<String, Object> encodePointerCoords(PointerCoords coords) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("orientation", coords.orientation);
        map.put("pressure", coords.pressure);
        map.put("size", coords.size);
        map.put("toolMajor", coords.toolMajor);
        map.put("toolMinor", coords.toolMinor);
        map.put("touchMajor", coords.touchMajor);
        map.put("touchMinor", coords.touchMinor);
        map.put("x", coords.x);
        map.put("y", coords.y);
        return map;
    }

    @SuppressWarnings("unchecked")
    public static MotionEvent decode(HashMap<String, Object> data) {
        List<PointerProperties> pointerProperties = new ArrayList<>();
        List<PointerCoords> pointerCoords = new ArrayList<>();

        for (HashMap<String, Object> property : (List<HashMap<String, Object>>) data.get("pointerProperties")) {
            pointerProperties.add(decodePointerProperties(property)) ;
        }

        for (HashMap<String, Object> coord : (List<HashMap<String, Object>>) data.get("pointerCoords")) {
            pointerCoords.add(decodePointerCoords(coord)) ;
        }

        return MotionEvent.obtain(
                (int) data.get("downTime"),
                (int) data.get("eventTime"),
                (int) data.get("action"),
                (int) data.get("pointerCount"),
                pointerProperties.toArray(new PointerProperties[pointerProperties.size()]),
                pointerCoords.toArray(new PointerCoords[pointerCoords.size()]),
                (int) data.get("metaState"),
                (int) data.get("buttonState"),
                (float) (double) data.get("xPrecision"),
                (float) (double) data.get("yPrecision"),
                (int) data.get("deviceId"),
                (int) data.get("edgeFlags"),
                (int) data.get("source"),
                (int) data.get("flags")
        );
    }

    private static PointerProperties decodePointerProperties(HashMap<String, Object> data) {
        PointerProperties properties = new PointerProperties();
        properties.id = (int) data.get("id");
        properties.toolType = (int) data.get("toolType");
        return properties;
    }

    private static PointerCoords decodePointerCoords(HashMap<String, Object> data) {
        PointerCoords coords = new PointerCoords();
        coords.orientation = (float) (double) data.get("orientation");
        coords.pressure = (float) (double) data.get("pressure");
        coords.size = (float) (double) data.get("size");
        coords.toolMajor = (float) (double) data.get("toolMajor");
        coords.toolMinor = (float) (double) data.get("toolMinor");
        coords.touchMajor = (float) (double) data.get("touchMajor");
        coords.touchMinor = (float) (double) data.get("touchMinor");
        coords.x = (float) (double) data.get("x");
        coords.y = (float) (double) data.get("y");
        return coords;
    }
}

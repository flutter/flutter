// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yourcompany.platforminteraction;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.lang.StringBuilder;

import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.WindowManager;
import android.content.Context;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterView;

import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeProvider;
import android.view.accessibility.AccessibilityNodeInfo;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      GeneratedPluginRegistrant.registerWith(this);
      new MethodChannel(getFlutterView(), "semantics").setMethodCallHandler(new SemanticsTesterMethodHandler());
  }

  class SemanticsTesterMethodHandler implements MethodCallHandler {
    Float mScreenDensity = 1.0f;

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        FlutterView flutterView = getFlutterView();
        AccessibilityNodeProvider provider = flutterView.getAccessibilityNodeProvider();
        DisplayMetrics displayMetrics = new DisplayMetrics();
        WindowManager wm = (WindowManager) getApplicationContext().getSystemService(Context.WINDOW_SERVICE);
        wm.getDefaultDisplay().getMetrics(displayMetrics);
        mScreenDensity = displayMetrics.density;
        if (methodCall.method.equals("getSemanticsNode")) {
            Map<String, Object> data = methodCall.arguments();
            @SuppressWarnings("unchecked")
            Integer id = (Integer) data.get("id");
            if (id == null) {
                result.error("No ID provided", "", null);
                return;
            }
            if (provider == null) {
                result.error("Semantics not enabled", "", null);
                return;
            }
            AccessibilityNodeInfo node = provider.createAccessibilityNodeInfo(id);
            result.success(convertSemantics(node, id));
            return;
        }
        result.notImplemented();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> convertSemantics(AccessibilityNodeInfo node, int id) {
        if (node == null)
            return null;
        Map<String, Object> result = new HashMap<>();
        Map<String, Object> flags = new HashMap<>();
        Map<String, Object> rect = new HashMap<>();
        result.put("id", id);
        result.put("text", node.getText());
        result.put("contentDescription", node.getContentDescription());
        flags.put("isChecked", node.isChecked());
        flags.put("isCheckable", node.isCheckable());
        flags.put("isDismissable", node.isDismissable());
        flags.put("isEditable", node.isEditable());
        flags.put("isEnabled", node.isEnabled());
        flags.put("isFocusable", node.isFocusable());
        flags.put("isFocused", node.isFocused());
        // heading flag is only available on Android Pie or newer
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            flags.put("isHeading", node.isHeading());
        }
        flags.put("isPassword", node.isPassword());
        flags.put("isLongClickable", node.isLongClickable());
        result.put("flags", flags);
        Rect nodeRect = new Rect();
        node.getBoundsInScreen(nodeRect);
        rect.put("left", nodeRect.left / mScreenDensity);
        rect.put("top", nodeRect.top/ mScreenDensity);
        rect.put("right", nodeRect.right / mScreenDensity);
        rect.put("bottom", nodeRect.bottom/ mScreenDensity);
        rect.put("width", nodeRect.width());
        rect.put("height", nodeRect.height());
        result.put("rect", rect);
        result.put("className", node.getClassName());
        result.put("contentDescription", node.getContentDescription());
        result.put("liveRegion", node.getLiveRegion());
        List<AccessibilityNodeInfo.AccessibilityAction> actionList = node.getActionList();
        if (actionList.size() > 0) {
            ArrayList<Integer> actions = new ArrayList<>();
            for (AccessibilityNodeInfo.AccessibilityAction action : actionList) {
                actions.add(action.getId());
            }
            result.put("actions", actions);
        }
        return result;
    }
  }
}

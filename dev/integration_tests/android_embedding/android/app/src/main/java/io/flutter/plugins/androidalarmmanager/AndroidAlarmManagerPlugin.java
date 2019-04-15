// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.androidalarmmanager;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;

import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.ViewDestroyListener;
import io.flutter.view.FlutterNativeView;

/**
 * Flutter plugin for running one-shot and periodic tasks sometime in the future on Android.
 *
 * <p>Plugin initialization goes through these steps:
 *
 * <ol>
 *   <li>Flutter app instructs this plugin to initialize() on the Dart side.
 *   <li>The Dart side of this plugin sends the Android side a "AlarmService.start" message, along
 *       with a Dart callback handle for a Dart callback that should be immediately invoked by a
 *       background Dart isolate.
 *   <li>The Android side of this plugin spins up a background {@link FlutterNativeView}, which
 *       includes a background Dart isolate.
 *   <li>The Android side of this plugin instructs the new background Dart isolate to execute the
 *       callback that was received in the "AlarmService.start" message.
 *   <li>The Dart side of this plugin, running within the new background isolate, executes the
 *       designated callback. This callback prepares the background isolate to then execute any
 *       given Dart callback from that point forward. Thus, at this moment the plugin is fully
 *       initialized and ready to execute arbitrary Dart tasks in the background. The Dart side of
 *       this plugin sends the Android side a "AlarmService.initialized" message to signify that the
 *       Dart is ready to execute tasks.
 * </ol>
 */
public class AndroidAlarmManagerPlugin implements MethodCallHandler, ViewDestroyListener {
  /**
   * Registers this plugin with an associated Flutter execution context, represented by the given
   * {@link Registrar}.
   *
   * <p>Once this method is executed, an instance of {@code AndroidAlarmManagerPlugin} will be
   * connected to, and running against, the associated Flutter execution context.
   */
  public static void registerWith(Registrar registrar) {
    // alarmManagerPluginChannel is the channel responsible for receiving the following messages
    // from the main Flutter app:
    // - "AlarmService.start"
    // - "Alarm.oneShot"
    // - "Alarm.periodic"
    // - "Alarm.cancel"
    final MethodChannel alarmManagerPluginChannel =
        new MethodChannel(
            registrar.messenger(),
            "plugins.flutter.io/android_alarm_manager",
            JSONMethodCodec.INSTANCE);

    // backgroundCallbackChannel is the channel responsible for receiving the following messages
    // from the background isolate that was setup by this plugin:
    // - "AlarmService.initialized"
    //
    // This channel is also responsible for sending requests from Android to Dart to execute Dart
    // callbacks in the background isolate. Those messages are sent with an empty method name because
    // they are the only messages that this channel sends to Dart.
    final MethodChannel backgroundCallbackChannel =
        new MethodChannel(
            registrar.messenger(),
            "plugins.flutter.io/android_alarm_manager_background",
            JSONMethodCodec.INSTANCE);

    // Instantiate a new AndroidAlarmManagerPlugin, connect the primary and background
    // method channels for Android/Flutter communication, and listen for FlutterView
    // destruction so that this plugin can move itself to background mode.
    AndroidAlarmManagerPlugin plugin = new AndroidAlarmManagerPlugin(registrar.context());
    alarmManagerPluginChannel.setMethodCallHandler(plugin);
    backgroundCallbackChannel.setMethodCallHandler(plugin);
    registrar.addViewDestroyListener(plugin);

    // The AlarmService expects to hold a static reference to the plugin's background
    // method channel.
    // TODO(mattcarroll): this static reference implies that only one instance of this plugin
    //                    can exist at a time. Moreover, calling registerWith() a 2nd time would
    //                    seem to overwrite the previously registered background channel without
    //                    notice.
    AlarmService.setBackgroundChannel(backgroundCallbackChannel);
  }

  private Context mContext;

  private AndroidAlarmManagerPlugin(Context context) {
    this.mContext = context;
  }

  /** Invoked when the Flutter side of this plugin sends a message to the Android side. */
  @Override
  public void onMethodCall(MethodCall call, Result result) {
    String method = call.method;
    Object arguments = call.arguments;
    try {
      if (method.equals("AlarmService.start")) {
        // This message is sent when the Dart side of this plugin is told to initialize.
        long callbackHandle = ((JSONArray) arguments).getLong(0);
        // In response, this (native) side of the plugin needs to spin up a background
        // Dart isolate by using the given callbackHandle, and then setup a background
        // method channel to communicate with the new background isolate. Once completed,
        // this onMethodCall() method will receive messages from both the primary and background
        // method channels.
        AlarmService.setCallbackDispatcher(mContext, callbackHandle);
        AlarmService.startBackgroundIsolate(mContext, callbackHandle);
        result.success(true);
      } else if (method.equals("AlarmService.initialized")) {
        // This message is sent by the background method channel as soon as the background isolate
        // is running. From this point forward, the Android side of this plugin can send
        // callback handles through the background method channel, and the Dart side will execute
        // the Dart methods corresponding to those callback handles.
        AlarmService.onInitialized();
        result.success(true);
      } else if (method.equals("Alarm.periodic")) {
        // This message indicates that the Flutter app would like to schedule a periodic
        // task.
        PeriodicRequest periodicRequest = PeriodicRequest.fromJson((JSONArray) arguments);
        AlarmService.setPeriodic(mContext, periodicRequest);
        result.success(true);
      } else if (method.equals("Alarm.oneShot")) {
        // This message indicates that the Flutter app would like to schedule a one-time
        // task.
        OneShotRequest oneShotRequest = OneShotRequest.fromJson((JSONArray) arguments);
        AlarmService.setOneShot(mContext, oneShotRequest);
        result.success(true);
      } else if (method.equals("Alarm.cancel")) {
        // This message indicates that the Flutter app would like to cancel a previously
        // scheduled task.
        int requestCode = ((JSONArray) arguments).getInt(0);
        AlarmService.cancel(mContext, requestCode);
        result.success(true);
      } else {
        result.notImplemented();
      }
    } catch (JSONException e) {
      result.error("error", "JSON error: " + e.getMessage(), null);
    } catch (PluginRegistrantException e) {
      result.error("error", "AlarmManager error: " + e.getMessage(), null);
    }
  }

  /**
   * Transitions the Flutter execution context that owns this plugin from foreground execution to
   * background execution.
   *
   * <p>Invoked when the {@link FlutterView} connected to the given {@link FlutterNativeView} is
   * destroyed.
   *
   * <p>Returns true if the given {@code nativeView} was successfully stored by this plugin, or
   * false if a different {@link FlutterNativeView} was already registered with this plugin.
   */
  @Override
  public boolean onViewDestroy(FlutterNativeView nativeView) {
    return AlarmService.setBackgroundFlutterView(nativeView);
  }

  /** A request to schedule a one-shot Dart task. */
  static final class OneShotRequest {
    static OneShotRequest fromJson(JSONArray json) throws JSONException {
      int requestCode = json.getInt(0);
      boolean exact = json.getBoolean(1);
      boolean wakeup = json.getBoolean(2);
      long startMillis = json.getLong(3);
      boolean rescheduleOnReboot = json.getBoolean(4);
      long callbackHandle = json.getLong(5);

      return new OneShotRequest(
          requestCode, exact, wakeup, startMillis, rescheduleOnReboot, callbackHandle);
    }

    final int requestCode;
    final boolean exact;
    final boolean wakeup;
    final long startMillis;
    final boolean rescheduleOnReboot;
    final long callbackHandle;

    OneShotRequest(
        int requestCode,
        boolean exact,
        boolean wakeup,
        long startMillis,
        boolean rescheduleOnReboot,
        long callbackHandle) {
      this.requestCode = requestCode;
      this.exact = exact;
      this.wakeup = wakeup;
      this.startMillis = startMillis;
      this.rescheduleOnReboot = rescheduleOnReboot;
      this.callbackHandle = callbackHandle;
    }
  }

  /** A request to schedule a periodic Dart task. */
  static final class PeriodicRequest {
    static PeriodicRequest fromJson(JSONArray json) throws JSONException {
      int requestCode = json.getInt(0);
      boolean exact = json.getBoolean(1);
      boolean wakeup = json.getBoolean(2);
      long startMillis = json.getLong(3);
      long intervalMillis = json.getLong(4);
      boolean rescheduleOnReboot = json.getBoolean(5);
      long callbackHandle = json.getLong(6);

      return new PeriodicRequest(
          requestCode,
          exact,
          wakeup,
          startMillis,
          intervalMillis,
          rescheduleOnReboot,
          callbackHandle);
    }

    final int requestCode;
    final boolean exact;
    final boolean wakeup;
    final long startMillis;
    final long intervalMillis;
    final boolean rescheduleOnReboot;
    final long callbackHandle;

    PeriodicRequest(
        int requestCode,
        boolean exact,
        boolean wakeup,
        long startMillis,
        long intervalMillis,
        boolean rescheduleOnReboot,
        long callbackHandle) {
      this.requestCode = requestCode;
      this.exact = exact;
      this.wakeup = wakeup;
      this.startMillis = startMillis;
      this.intervalMillis = intervalMillis;
      this.rescheduleOnReboot = rescheduleOnReboot;
      this.callbackHandle = callbackHandle;
    }
  }
}

// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package io.flutter.plugins.googlemobileads;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle.Event;
import androidx.lifecycle.LifecycleEventObserver;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.ProcessLifecycleOwner;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** Listens to changes in app foreground/background and forwards events to Flutter. */
final class AppStateNotifier implements LifecycleEventObserver, MethodCallHandler, StreamHandler {

  private static final String METHOD_CHANNEL_NAME =
      "plugins.flutter.io/google_mobile_ads/app_state_method";
  private static final String EVENT_CHANNEL_NAME =
      "plugins.flutter.io/google_mobile_ads/app_state_event";

  @NonNull private final MethodChannel methodChannel;
  @NonNull private final EventChannel eventChannel;

  @Nullable private EventSink events;

  AppStateNotifier(BinaryMessenger binaryMessenger) {
    methodChannel = new MethodChannel(binaryMessenger, METHOD_CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);
    eventChannel = new EventChannel(binaryMessenger, EVENT_CHANNEL_NAME);
    eventChannel.setStreamHandler(this);
  }

  /** Starts listening for app lifecycle changes. */
  void start() {
    ProcessLifecycleOwner.get().getLifecycle().addObserver(this);
  }

  /** Stops listening for app lifecycle changes. */
  void stop() {
    ProcessLifecycleOwner.get().getLifecycle().removeObserver(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "start":
        start();
        break;
      case "stop":
        stop();
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onStateChanged(@NonNull LifecycleOwner source, @NonNull Event event) {
    if (event == Event.ON_START && events != null) {
      events.success("foreground");
    } else if (event == Event.ON_STOP && events != null) {
      events.success("background");
    }
  }

  @Override
  public void onListen(Object arguments, EventSink events) {
    this.events = events;
  }

  @Override
  public void onCancel(Object arguments) {
    this.events = null;
  }
}

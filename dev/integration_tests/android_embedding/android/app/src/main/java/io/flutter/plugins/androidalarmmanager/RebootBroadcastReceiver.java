// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.androidalarmmanager;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

/**
 * Reschedules background work after the Android device reboots.
 *
 * <p>When an Android device reboots, all previously scheduled {@link AlarmManager} timers are
 * cleared.
 *
 * <p>Timer callbacks registered with the android_alarm_manager plugin can be designated
 * "persistent" and therefore, upon device reboot, should be rescheduled for execution. To
 * accomplish this rescheduling, {@code RebootBroadcastReceiver} is scheduled by {@link
 * AlarmService} to run on {@code BOOT_COMPLETED} and do the rescheduling.
 */
public class RebootBroadcastReceiver extends BroadcastReceiver {
  /**
   * Invoked by the OS whenever a broadcast is received by this app.
   *
   * <p>If the broadcast's action is {@code BOOT_COMPLETED} then this {@code
   * RebootBroadcastReceiver} reschedules all persistent timer callbacks. That rescheduling work is
   * handled by {@link AlarmService#reschedulePersistentAlarms(Context)}.
   */
  @Override
  public void onReceive(Context context, Intent intent) {
    if (intent.getAction().equals("android.intent.action.BOOT_COMPLETED")) {
      Log.i("AlarmService", "Rescheduling after boot!");
      AlarmService.reschedulePersistentAlarms(context);
    }
  }

  /**
   * Schedules this {@code RebootBroadcastReceiver} to be run whenever the Android device reboots.
   */
  public static void enableRescheduleOnReboot(Context context) {
    scheduleOnReboot(context, PackageManager.COMPONENT_ENABLED_STATE_ENABLED);
  }

  /**
   * Unschedules this {@code RebootBroadcastReceiver} to be run whenever the Android device reboots.
   * This {@code RebootBroadcastReceiver} will no longer be run upon reboot.
   */
  public static void disableRescheduleOnReboot(Context context) {
    scheduleOnReboot(context, PackageManager.COMPONENT_ENABLED_STATE_DISABLED);
  }

  private static void scheduleOnReboot(Context context, int state) {
    ComponentName receiver = new ComponentName(context, RebootBroadcastReceiver.class);
    PackageManager pm = context.getPackageManager();
    pm.setComponentEnabledSetting(receiver, state, PackageManager.DONT_KILL_APP);
  }
}

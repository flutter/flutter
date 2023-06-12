// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
*  The attribute values to check for compatibility with Chrome OS.
*
*/

const String ACTIVITY_TAG = 'activity';

const String ANDROID_NAME = 'android:name';

const String ANDROID_PERMISSION_CAMERA = 'android.permission.CAMERA';

const String ANDROID_REQUIRED = 'android:required';

const String APPLICATION_TAG = 'application';

/// The Android resizeableActivity attribute.
// The parser does not maintain camelcase for attributes. Uses
// 'resizeableactivity' instead of 'resizeableActivity'
const String ATTRIBUTE_RESIZEABLE_ACTIVITY = 'android:resizeableactivity';

/// The Android screenOrientation attribute.
// The parser does not maintain camelcase for attributes. Uses
// 'screenorientation' instead of 'screenOrientation'.
const String ATTRIBUTE_SCREEN_ORIENTATION = 'android:screenorientation';

const String HARDWARE_FEATURE_CAMERA = 'android.hardware.camera';

const String HARDWARE_FEATURE_CAMERA_AUTOFOCUS =
    'android.hardware.camera.autofocus';

const String HARDWARE_FEATURE_TELEPHONY = 'android.hardware.telephony';

const String HARDWARE_FEATURE_TOUCHSCREEN = 'android.hardware.touchscreen';

const String MANIFEST_TAG = 'manifest';

const UNSUPPORTED_HARDWARE_FEATURES = <String>[
  HARDWARE_FEATURE_CAMERA,
  HARDWARE_FEATURE_CAMERA_AUTOFOCUS,
  'android.hardware.camera.capability.manual_post_processing',
  'android.hardware.camera.capability.manual_sensor',
  'android.hardware.camera.capability.raw',
  'android.hardware.camera.flash',
  'android.hardware.camera.level.full',
  'android.hardware.consumerir',
  'android.hardware.location.gps',
  'android.hardware.nfc',
  'android.hardware.nfc.hce',
  'android.hardware.sensor.barometer',
  HARDWARE_FEATURE_TELEPHONY,
  'android.hardware.telephony.cdma',
  'android.hardware.telephony.gsm',
  'android.hardware.type.automotive',
  'android.hardware.type.television',
  'android.hardware.usb.accessory',
  'android.hardware.usb.host',
  // Partially-supported, only on some Chrome OS devices.
  'android.hardware.sensor.accelerometer',
  'android.hardware.sensor.compass',
  'android.hardware.sensor.gyroscope',
  'android.hardware.sensor.light',
  'android.hardware.sensor.proximity',
  'android.hardware.sensor.stepcounter',
  'android.hardware.sensor.stepdetector',
  // Software features that are not supported
  'android.software.app_widgets',
  'android.software.device_admin',
  'android.software.home_screen',
  'android.software.input_methods',
  'android.software.leanback',
  'android.software.live_wallpaper',
  'android.software.live_tv',
  'android.software.managed_users',
  'android.software.midi',
  'android.software.sip',
  'android.software.sip.voip',
];

const UNSUPPORTED_ORIENTATIONS = <String>[
  'landscape',
  'portrait',
  'reverseLandscape',
  'reversePortrait',
  'sensorLandscape',
  'sensorPortrait',
  'userLandscape',
  'userPortrait'
];

const String USES_FEATURE_TAG = 'uses-feature';

const String USES_PERMISSION_TAG = 'uses-permission';

String? getImpliedUnsupportedHardware(String? permission) {
  switch (permission) {
    case ANDROID_PERMISSION_CAMERA:
      return HARDWARE_FEATURE_CAMERA;
    case 'android.permission.CALL_PHONE':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.CALL_PRIVILEGED':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.MODIFY_PHONE_STATE':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.PROCESS_OUTGOING_CALLS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.READ_SMS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.RECEIVE_SMS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.RECEIVE_MMS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.RECEIVE_WAP_PUSH':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.SEND_SMS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.WRITE_APN_SETTINGS':
      return HARDWARE_FEATURE_TELEPHONY;
    case 'android.permission.WRITE_SMS':
      return HARDWARE_FEATURE_TELEPHONY;
    default:
      return null;
  }
}

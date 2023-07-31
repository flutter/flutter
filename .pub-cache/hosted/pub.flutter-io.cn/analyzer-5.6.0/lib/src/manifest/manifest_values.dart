// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The attribute values to check for compatibility with Chrome OS.

const String activityTag = 'activity';

const String androidName = 'android:name';

const String androidPermissionCamera = 'android.permission.CAMERA';

const String androidRequired = 'android:required';

const String applicationTag = 'application';

/// The Android resizeableActivity attribute.
// The parser does not maintain camelcase for attributes. Uses
// 'resizeableactivity' instead of 'resizeableActivity'
const String attributeResizableActivity = 'android:resizeableactivity';

/// The Android screenOrientation attribute.
// The parser does not maintain camelcase for attributes. Uses
// 'screenorientation' instead of 'screenOrientation'.
const String attributeScreenOrientation = 'android:screenorientation';

const String hardwareFeatureCamera = 'android.hardware.camera';

const String hardwareFeatureCameraAutofocus =
    'android.hardware.camera.autofocus';

const String hardwareFeatureTelephony = 'android.hardware.telephony';

const String hardwareFeatureTouchscreen = 'android.hardware.touchscreen';

const String manifestTag = 'manifest';

const unsupportedHardwareFeatures = <String>[
  hardwareFeatureCamera,
  hardwareFeatureCameraAutofocus,
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
  hardwareFeatureTelephony,
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

const unsupportedOrientations = <String>[
  'landscape',
  'portrait',
  'reverseLandscape',
  'reversePortrait',
  'sensorLandscape',
  'sensorPortrait',
  'userLandscape',
  'userPortrait'
];

const String usesFeatureTag = 'uses-feature';

const String usesPermissionTag = 'uses-permission';

String? getImpliedUnsupportedHardware(String? permission) {
  switch (permission) {
    case androidPermissionCamera:
      return hardwareFeatureCamera;
    case 'android.permission.CALL_PHONE':
      return hardwareFeatureTelephony;
    case 'android.permission.CALL_PRIVILEGED':
      return hardwareFeatureTelephony;
    case 'android.permission.MODIFY_PHONE_STATE':
      return hardwareFeatureTelephony;
    case 'android.permission.PROCESS_OUTGOING_CALLS':
      return hardwareFeatureTelephony;
    case 'android.permission.READ_SMS':
      return hardwareFeatureTelephony;
    case 'android.permission.RECEIVE_SMS':
      return hardwareFeatureTelephony;
    case 'android.permission.RECEIVE_MMS':
      return hardwareFeatureTelephony;
    case 'android.permission.RECEIVE_WAP_PUSH':
      return hardwareFeatureTelephony;
    case 'android.permission.SEND_SMS':
      return hardwareFeatureTelephony;
    case 'android.permission.WRITE_APN_SETTINGS':
      return hardwareFeatureTelephony;
    case 'android.permission.WRITE_SMS':
      return hardwareFeatureTelephony;
    default:
      return null;
  }
}

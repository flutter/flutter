// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('android_device', () {
    testUsingContext('stores the requested id', () {
      const String deviceId = '1234';
      final AndroidDevice device = new AndroidDevice(deviceId);
      expect(device.id, deviceId);
    });
  });

  group('getAdbDevices', () {
    testUsingContext('physical devices', () {
      final List<AndroidDevice> devices = <AndroidDevice>[];
      parseADBDeviceOutput('''
List of devices attached
05a02bac               device usb:336592896X product:razor model:Nexus_7 device:flo

''', devices: devices);
      expect(devices, hasLength(1));
      expect(devices.first.name, 'Nexus 7');
    });

    testUsingContext('emulators and short listings', () {
      final List<AndroidDevice> devices = <AndroidDevice>[];
      parseADBDeviceOutput('''
List of devices attached
localhost:36790        device
0149947A0D01500C       device usb:340787200X
emulator-5612          host features:shell_2

''', devices: devices);
      expect(devices, hasLength(3));
      expect(devices.first.name, 'localhost:36790');
    });

    testUsingContext('android n', () {
      final List<AndroidDevice> devices = <AndroidDevice>[];
      parseADBDeviceOutput('''
List of devices attached
ZX1G22JJWR             device usb:3-3 product:shamu model:Nexus_6 device:shamu features:cmd,shell_v2
''', devices: devices);
      expect(devices, hasLength(1));
      expect(devices.first.name, 'Nexus 6');
    });

    testUsingContext('adb error message', () {
      final List<AndroidDevice> devices = <AndroidDevice>[];
      final List<String> diagnostics = <String>[];
      parseADBDeviceOutput('''
It appears you do not have 'Android SDK Platform-tools' installed.
Use the 'android' tool to install them:
    android update sdk --no-ui --filter 'platform-tools'
''', devices: devices, diagnostics: diagnostics);
      expect(devices, hasLength(0));
      expect(diagnostics, hasLength(1));
      expect(diagnostics.first, contains('you do not have'));
    });
  });

  group('parseAdbDeviceProperties', () {
    test('parse adb shell output', () {
      final Map<String, String> properties = parseAdbDeviceProperties(kAdbShellGetprop);
      expect(properties, isNotNull);
      expect(properties['ro.build.characteristics'], 'emulator');
      expect(properties['ro.product.cpu.abi'], 'x86_64');
      expect(properties['ro.build.version.sdk'], '23');
    });
  });

  group('isLocalEmulator', () {
    final ProcessManager mockProcessManager = new MockProcessManager();
    String hardware;
    String buildCharacteristics;

    setUp(() {
      hardware = 'unknown';
      buildCharacteristics = 'unused';
      when(mockProcessManager.run(argThat(contains('getprop')), stderrEncoding: any, stdoutEncoding: any)).thenAnswer((_) {
        final StringBuffer buf = new StringBuffer()
          ..writeln('[ro.hardware]: [$hardware]')
          ..writeln('[ro.build.characteristics]: [$buildCharacteristics]');
        final ProcessResult result = new ProcessResult(1, 0, buf.toString(), '');
        return new Future<ProcessResult>.value(result);
      });
    });

    testUsingContext('knownPhysical', () async {
      hardware = 'samsungexynos7420';
      final AndroidDevice device = new AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('knownEmulator', () async {
      hardware = 'goldfish';
      final AndroidDevice device = new AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
      expect(await device.supportsHardwareRendering, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('unknownPhysical', () async {
      buildCharacteristics = 'att';
      final AndroidDevice device = new AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('unknownEmulator', () async {
      buildCharacteristics = 'att,emulator';
      final AndroidDevice device = new AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
      expect(await device.supportsHardwareRendering, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

const String kAdbShellGetprop = '''
[dalvik.vm.dex2oat-Xms]: [64m]
[dalvik.vm.dex2oat-Xmx]: [512m]
[dalvik.vm.heapsize]: [384m]
[dalvik.vm.image-dex2oat-Xms]: [64m]
[dalvik.vm.image-dex2oat-Xmx]: [64m]
[dalvik.vm.isa.x86.variant]: [dalvik.vm.isa.x86.features=default]
[dalvik.vm.isa.x86_64.features]: [default]
[dalvik.vm.isa.x86_64.variant]: [x86_64]
[dalvik.vm.lockprof.threshold]: [500]
[dalvik.vm.stack-trace-file]: [/data/anr/traces.txt]
[debug.atrace.tags.enableflags]: [0]
[debug.force_rtl]: [0]
[gsm.current.phone-type]: [1]
[gsm.network.type]: [Unknown]
[gsm.nitz.time]: [1473102078793]
[gsm.operator.alpha]: []
[gsm.operator.iso-country]: []
[gsm.operator.isroaming]: [false]
[gsm.operator.numeric]: []
[gsm.sim.operator.alpha]: []
[gsm.sim.operator.iso-country]: []
[gsm.sim.operator.numeric]: []
[gsm.sim.state]: [NOT_READY]
[gsm.version.ril-impl]: [android reference-ril 1.0]
[init.svc.adbd]: [running]
[init.svc.bootanim]: [running]
[init.svc.console]: [running]
[init.svc.debuggerd]: [running]
[init.svc.debuggerd64]: [running]
[init.svc.drm]: [running]
[init.svc.fingerprintd]: [running]
[init.svc.gatekeeperd]: [running]
[init.svc.goldfish-logcat]: [stopped]
[init.svc.goldfish-setup]: [stopped]
[init.svc.healthd]: [running]
[init.svc.installd]: [running]
[init.svc.keystore]: [running]
[init.svc.lmkd]: [running]
[init.svc.logd]: [running]
[init.svc.logd-reinit]: [stopped]
[init.svc.media]: [running]
[init.svc.netd]: [running]
[init.svc.perfprofd]: [running]
[init.svc.qemu-props]: [stopped]
[init.svc.ril-daemon]: [running]
[init.svc.servicemanager]: [running]
[init.svc.surfaceflinger]: [running]
[init.svc.ueventd]: [running]
[init.svc.vold]: [running]
[init.svc.zygote]: [running]
[init.svc.zygote_secondary]: [running]
[net.bt.name]: [Android]
[net.change]: [net.qtaguid_enabled]
[net.eth0.dns1]: [10.0.2.3]
[net.eth0.gw]: [10.0.2.2]
[net.gprs.local-ip]: [10.0.2.15]
[net.hostname]: [android-ccd858aa3d3825ee]
[net.qtaguid_enabled]: [1]
[net.tcp.default_init_rwnd]: [60]
[persist.sys.dalvik.vm.lib.2]: [libart.so]
[persist.sys.profiler_ms]: [0]
[persist.sys.timezone]: [America/Los_Angeles]
[persist.sys.usb.config]: [adb]
[qemu.gles]: [1]
[qemu.hw.mainkeys]: [0]
[qemu.sf.fake_camera]: [none]
[qemu.sf.lcd_density]: [420]
[rild.libargs]: [-d /dev/ttyS0]
[rild.libpath]: [/system/lib/libreference-ril.so]
[ro.allow.mock.location]: [0]
[ro.baseband]: [unknown]
[ro.board.platform]: []
[ro.boot.hardware]: [ranchu]
[ro.bootimage.build.date]: [Wed Jul 20 21:03:09 UTC 2016]
[ro.bootimage.build.date.utc]: [1469048589]
[ro.bootimage.build.fingerprint]: [Android/sdk_google_phone_x86_64/generic_x86_64:6.0/MASTER/3079352:userdebug/test-keys]
[ro.bootloader]: [unknown]
[ro.bootmode]: [unknown]
[ro.build.characteristics]: [emulator]
[ro.build.date]: [Wed Jul 20 21:02:14 UTC 2016]
[ro.build.date.utc]: [1469048534]
[ro.build.description]: [sdk_google_phone_x86_64-userdebug 6.0 MASTER 3079352 test-keys]
[ro.build.display.id]: [sdk_google_phone_x86_64-userdebug 6.0 MASTER 3079352 test-keys]
[ro.build.fingerprint]: [Android/sdk_google_phone_x86_64/generic_x86_64:6.0/MASTER/3079352:userdebug/test-keys]
[ro.build.flavor]: [sdk_google_phone_x86_64-userdebug]
[ro.build.host]: [vpba14.mtv.corp.google.com]
[ro.build.id]: [MASTER]
[ro.build.product]: [generic_x86_64]
[ro.build.tags]: [test-keys]
[ro.build.type]: [userdebug]
[ro.build.user]: [android-build]
[ro.build.version.all_codenames]: [REL]
[ro.build.version.base_os]: []
[ro.build.version.codename]: [REL]
[ro.build.version.incremental]: [3079352]
[ro.build.version.preview_sdk]: [0]
[ro.build.version.release]: [6.0]
[ro.build.version.sdk]: [23]
[ro.build.version.security_patch]: [2015-10-01]
[ro.com.google.locationfeatures]: [1]
[ro.config.alarm_alert]: [Alarm_Classic.ogg]
[ro.config.nocheckin]: [yes]
[ro.config.notification_sound]: [OnTheHunt.ogg]
[ro.crypto.state]: [unencrypted]
[ro.dalvik.vm.native.bridge]: [0]
[ro.debuggable]: [1]
[ro.hardware]: [ranchu]
[ro.hardware.audio.primary]: [goldfish]
[ro.hwui.drop_shadow_cache_size]: [6]
[ro.hwui.gradient_cache_size]: [1]
[ro.hwui.layer_cache_size]: [48]
[ro.hwui.path_cache_size]: [32]
[ro.hwui.r_buffer_cache_size]: [8]
[ro.hwui.text_large_cache_height]: [1024]
[ro.hwui.text_large_cache_width]: [2048]
[ro.hwui.text_small_cache_height]: [1024]
[ro.hwui.text_small_cache_width]: [1024]
[ro.hwui.texture_cache_flushrate]: [0.4]
[ro.hwui.texture_cache_size]: [72]
[ro.kernel.android.checkjni]: [1]
[ro.kernel.android.qemud]: [1]
[ro.kernel.androidboot.hardware]: [ranchu]
[ro.kernel.clocksource]: [pit]
[ro.kernel.qemu]: [1]
[ro.kernel.qemu.gles]: [1]
[ro.opengles.version]: [131072]
[ro.product.board]: []
[ro.product.brand]: [Android]
[ro.product.cpu.abi]: [x86_64]
[ro.product.cpu.abilist]: [x86_64,x86]
[ro.product.cpu.abilist32]: [x86]
[ro.product.cpu.abilist64]: [x86_64]
[ro.product.device]: [generic_x86_64]
[ro.product.locale]: [en-US]
[ro.product.manufacturer]: [unknown]
[ro.product.model]: [Android SDK built for x86_64]
[ro.product.name]: [sdk_google_phone_x86_64]
[ro.radio.use-ppp]: [no]
[ro.revision]: [0]
[ro.secure]: [1]
[ro.serialno]: []
[ro.wifi.channels]: []
[ro.zygote]: [zygote64_32]
[selinux.reload_policy]: [1]
[service.bootanim.exit]: [0]
[status.battery.level]: [5]
[status.battery.level_raw]: [50]
[status.battery.level_scale]: [9]
[status.battery.state]: [Slow]
[sys.sysctl.extra_free_kbytes]: [24300]
[sys.usb.config]: [adb]
[sys.usb.state]: [adb]
[vold.has_adoptable]: [1]
[wlan.driver.status]: [unloaded]
[xmpp.auto-presence]: [true]
''';

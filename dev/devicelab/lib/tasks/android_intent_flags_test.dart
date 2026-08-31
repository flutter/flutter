import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

TaskFunction createAndroidIntentFlagsTest() {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String deviceId = device.deviceId;
    final String testDirectory = path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ui');
    
    Future<void> testMode({required String mode, required bool expectVerbose}) async {
      print('\n--- Testing $mode mode ---');
      await inDirectory<void>(testDirectory, () async {
        // Build the APK
        await exec('flutter', <String>['build', 'apk', '--$mode']);
        final String apkPath = path.join('build', 'app', 'outputs', 'flutter-apk', 'app-$mode.apk');
        
        // Ensure clean state
        await exec('adb', <String>['-s', deviceId, 'uninstall', 'com.yourcompany.integration_ui'], canFail: true);
        await exec('adb', <String>['-s', deviceId, 'install', '-r', apkPath]);
        
        // Clear logcat
        await exec('adb', <String>['-s', deviceId, 'logcat', '-c']);
        
        // Launch via intent with verbose-logging flag
        await exec('adb', <String>[
          '-s', deviceId, 
          'shell', 'am', 'start', 
          '-n', 'com.yourcompany.integration_ui/.MainActivity', 
          '-a', 'android.intent.action.RUN', 
          '--ez', 'verbose-logging', 'true'
        ]);
        
        // Poll logcat for engine INFO logs
        bool foundInfoLog = false;
        for (int i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          final String logcat = await eval('adb', <String>['-s', deviceId, 'logcat', '-d']);
          // The C++ engine logs format as "[INFO:..." when verbose-logging is enabled.
          if (logcat.contains('[INFO:flutter')) {
             foundInfoLog = true;
             break;
          }
        }
        
        if (expectVerbose && !foundInfoLog) {
           throw 'Expected [INFO:flutter logs to be present in $mode mode when passing verbose-logging intent, but they were not found in logcat.';
        } else if (!expectVerbose && foundInfoLog) {
           throw 'Expected [INFO:flutter logs to be stripped in $mode mode, but they were found in logcat!';
        }
        
        print('Success: $mode mode behaves as expected (expectVerbose: $expectVerbose, foundInfoLog: $foundInfoLog)');
      });
    }
    
    await testMode(mode: 'debug', expectVerbose: true);
    await testMode(mode: 'profile', expectVerbose: true);
    await testMode(mode: 'release', expectVerbose: false);
    
    return TaskResult.success(null);
  };
}

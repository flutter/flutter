// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"

#include "flutter/common/task_runners.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/common/command_line.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

static const char* kScriptSnapshotFileName = "snapshot_blob.bin";
static const char* kVMKernelSnapshotFileName = "platform.dill";
static const char* kApplicationKernelSnapshotFileName = "kernel_blob.bin";

static blink::Settings DefaultSettingsForProcess() {
  auto command_line = shell::CommandLineFromNSProcessInfo();

  // Settings passed in explicitly via command line arguments take priority.
  auto settings = shell::SettingsFromCommandLine(command_line);

  settings.task_observer_add = [](intptr_t key, fxl::Closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  // The command line arguments may not always be complete. If they aren't, attempt to fill in
  // defaults.

  // Flutter ships the ICU data file in the the bundle of the engine. Look for it there.
  if (settings.icu_data_path.size() == 0) {
    NSBundle* bundle = [NSBundle bundleForClass:[FlutterViewController class]];
    NSString* icuDataPath = [bundle pathForResource:@"icudtl" ofType:@"dat"];
    if (icuDataPath.length > 0) {
      settings.icu_data_path = icuDataPath.UTF8String;
    }
  }

  if (blink::DartVM::IsRunningPrecompiledCode()) {
    // The application bundle could be specified in the Info.plist.
    if (settings.application_library_path.size() == 0) {
      NSString* libraryName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTLibraryPath"];
      NSString* libraryPath = [[NSBundle mainBundle] pathForResource:libraryName ofType:nil];
      if (libraryPath.length > 0) {
        settings.application_library_path =
            [NSBundle bundleWithPath:libraryPath].executablePath.UTF8String;
      }
    }

    // In case the application bundle is still not specified, look for the App.framework in the
    // Frameworks directory.
    if (settings.application_library_path.size() == 0) {
      NSString* applicationFrameworkPath =
          [[NSBundle mainBundle] pathForResource:@"Frameworks/App.framework" ofType:@""];
      if (applicationFrameworkPath.length > 0) {
        settings.application_library_path =
            [NSBundle bundleWithPath:applicationFrameworkPath].executablePath.UTF8String;
      }
    }
  }

  // Checks to see if the flutter assets directory is already present.
  if (settings.assets_path.size() == 0) {
    NSString* assetsPath = [[NSBundle mainBundle] pathForResource:@"flutter_assets" ofType:@""];

    if (assetsPath.length > 0) {
      settings.assets_path = assetsPath.UTF8String;

      if (!blink::DartVM::IsRunningPrecompiledCode()) {
        // Looking for the various script and kernel snapshot buffers only makes sense if we have a
        // VM that can use these buffers.
        {
          // Check if there is a script snapshot in the assets directory we could potentially use.
          NSURL* scriptSnapshotURL = [NSURL URLWithString:@(kScriptSnapshotFileName)
                                            relativeToURL:[NSURL fileURLWithPath:assetsPath]];
          if ([[NSFileManager defaultManager] fileExistsAtPath:scriptSnapshotURL.path]) {
            settings.script_snapshot_path = scriptSnapshotURL.path.UTF8String;
          }
        }

        {
          // Check if there is a VM kernel snapshot in the assets directory we could potentially
          // use.
          NSURL* vmKernelSnapshotURL = [NSURL URLWithString:@(kVMKernelSnapshotFileName)
                                              relativeToURL:[NSURL fileURLWithPath:assetsPath]];
          if ([[NSFileManager defaultManager] fileExistsAtPath:vmKernelSnapshotURL.path]) {
            settings.kernel_snapshot_path = vmKernelSnapshotURL.path.UTF8String;
          }
        }

        {
          // Check if there is an application kernel snapshot in the assets directory we could
          // potentially use.
          NSURL* applicationKernelSnapshotURL =
              [NSURL URLWithString:@(kApplicationKernelSnapshotFileName)
                     relativeToURL:[NSURL fileURLWithPath:assetsPath]];
          if ([[NSFileManager defaultManager] fileExistsAtPath:applicationKernelSnapshotURL.path]) {
            settings.application_kernel_asset = applicationKernelSnapshotURL.path.UTF8String;
          }
        }
      }
    }
  }

  return settings;
}

@implementation FlutterDartProject {
  fml::scoped_nsobject<NSBundle> _precompiledDartBundle;
  blink::Settings _settings;
}

#pragma mark - Override base class designated initializers

- (instancetype)init {
  return [self initWithFlutterAssets:nil dartMain:nil packages:nil];
}

#pragma mark - Designated initializers

- (instancetype)initWithPrecompiledDartBundle:(NSBundle*)bundle {
  self = [super init];

  if (self) {
    _precompiledDartBundle.reset([bundle retain]);

    _settings = DefaultSettingsForProcess();

    if (bundle != nil) {
      NSString* executablePath = _precompiledDartBundle.get().executablePath;
      if ([[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
        _settings.application_library_path = executablePath.UTF8String;
      }
    }
  }

  return self;
}

- (instancetype)initWithFlutterAssets:(NSURL*)flutterAssetsURL
                             dartMain:(NSURL*)dartMainURL
                             packages:(NSURL*)dartPackages {
  self = [super init];

  if (self) {
    _settings = DefaultSettingsForProcess();

    if ([[NSFileManager defaultManager] fileExistsAtPath:dartMainURL.path]) {
      _settings.main_dart_file_path = dartMainURL.path.UTF8String;
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:dartPackages.path]) {
      _settings.packages_file_path = dartPackages.path.UTF8String;
    }
  }

  return self;
}

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssetsURL {
  self = [super init];

  if (self) {
    _settings = DefaultSettingsForProcess();

    if ([[NSFileManager defaultManager] fileExistsAtPath:flutterAssetsURL.path]) {
      _settings.assets_path = flutterAssetsURL.path.UTF8String;

      NSURL* scriptSnapshotPath =
          [NSURL URLWithString:@(kScriptSnapshotFileName) relativeToURL:flutterAssetsURL];
      if ([[NSFileManager defaultManager] fileExistsAtPath:scriptSnapshotPath.path]) {
        _settings.script_snapshot_path = scriptSnapshotPath.path.UTF8String;
      }
    }
  }

  return self;
}

#pragma mark - Convenience initializers

- (instancetype)initFromDefaultSourceForConfiguration {
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    return [self initWithPrecompiledDartBundle:nil];
  } else {
    return [self initWithFlutterAssets:nil dartMain:nil packages:nil];
  }
}

- (const blink::Settings&)settings {
  return _settings;
}

- (shell::RunConfiguration)runConfiguration {
  return shell::RunConfiguration::InferFromSettings(_settings);
}

#pragma mark - Assets-related utilities

+ (NSString*)flutterAssetsName:(NSBundle*)bundle {
  NSString* flutterAssetsName = [bundle objectForInfoDictionaryKey:@"FLTAssetsPath"];
  if (flutterAssetsName == nil) {
    // Default to "flutter_assets"
    flutterAssetsName = @"flutter_assets";
  }
  return flutterAssetsName;
}

+ (NSString*)pathForFlutterAssetsFromBundle:(NSBundle*)bundle {
  NSString* flutterAssetsName = [FlutterDartProject flutterAssetsName:bundle];
  return [bundle pathForResource:flutterAssetsName ofType:nil];
}

+ (NSString*)lookupKeyForAsset:(NSString*)asset {
  NSString* flutterAssetsName = [FlutterDartProject flutterAssetsName:[NSBundle mainBundle]];
  return [NSString stringWithFormat:@"%@/%@", flutterAssetsName, asset];
}

+ (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package {
  return [self lookupKeyForAsset:[NSString stringWithFormat:@"packages/%@/%@", package, asset]];
}

@end

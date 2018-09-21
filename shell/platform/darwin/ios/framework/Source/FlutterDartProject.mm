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

static const char* kApplicationKernelSnapshotFileName = "kernel_blob.bin";

static blink::Settings DefaultSettingsForProcess(NSBundle* bundle = nil) {
  auto command_line = shell::CommandLineFromNSProcessInfo();

  // Precedence:
  // 1. Settings from the specified NSBundle.
  // 2. Settings passed explicitly via command-line arguments.
  // 3. Settings from the NSBundle with the default bundle ID.
  // 4. Settings from the main NSBundle and default values.

  NSBundle* mainBundle = [NSBundle mainBundle];
  NSBundle* engineBundle = [NSBundle bundleForClass:[FlutterViewController class]];

  bool hasExplicitBundle = bundle != nil;
  if (bundle == nil) {
    bundle = [NSBundle bundleWithIdentifier:[FlutterDartProject defaultBundleIdentifier]];
  }
  if (bundle == nil) {
    bundle = mainBundle;
  }

  auto settings = shell::SettingsFromCommandLine(command_line);

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  // The command line arguments may not always be complete. If they aren't, attempt to fill in
  // defaults.

  // Flutter ships the ICU data file in the the bundle of the engine. Look for it there.
  if (settings.icu_data_path.size() == 0) {
    NSString* icuDataPath = [engineBundle pathForResource:@"icudtl" ofType:@"dat"];
    if (icuDataPath.length > 0) {
      settings.icu_data_path = icuDataPath.UTF8String;
    }
  }

  if (blink::DartVM::IsRunningPrecompiledCode()) {
    if (hasExplicitBundle) {
      NSString* executablePath = bundle.executablePath;
      if ([[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
        settings.application_library_path = executablePath.UTF8String;
      }
    }

    // No application bundle specified.  Try a known location from the main bundle's Info.plist.
    if (settings.application_library_path.size() == 0) {
      NSString* libraryName = [mainBundle objectForInfoDictionaryKey:@"FLTLibraryPath"];
      NSString* libraryPath = [mainBundle pathForResource:libraryName ofType:@""];
      if (libraryPath.length > 0) {
        NSString* executablePath = [NSBundle bundleWithPath:libraryPath].executablePath;
        if (executablePath.length > 0) {
          settings.application_library_path = executablePath.UTF8String;
        }
      }
    }

    // In case the application bundle is still not specified, look for the App.framework in the
    // Frameworks directory.
    if (settings.application_library_path.size() == 0) {
      NSString* applicationFrameworkPath = [mainBundle pathForResource:@"Frameworks/App.framework"
                                                                ofType:@""];
      if (applicationFrameworkPath.length > 0) {
        NSString* executablePath =
            [NSBundle bundleWithPath:applicationFrameworkPath].executablePath;
        if (executablePath.length > 0) {
          settings.application_library_path = executablePath.UTF8String;
        }
      }
    }
  }

  // Checks to see if the flutter assets directory is already present.
  if (settings.assets_path.size() == 0) {
    NSString* assetsName = [FlutterDartProject flutterAssetsName:bundle];
    NSString* assetsPath = [mainBundle pathForResource:assetsName ofType:@""];

    if (assetsPath.length == 0) {
      NSLog(@"Failed to find assets path for \"%@\"", assetsName);
    } else {
      settings.assets_path = assetsPath.UTF8String;

      // Check if there is an application kernel snapshot in the assets directory we could
      // potentially use.  Looking for the snapshot makes sense only if we have a VM that can use
      // it.
      if (!blink::DartVM::IsRunningPrecompiledCode()) {
        NSURL* applicationKernelSnapshotURL =
            [NSURL URLWithString:@(kApplicationKernelSnapshotFileName)
                   relativeToURL:[NSURL fileURLWithPath:assetsPath]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:applicationKernelSnapshotURL.path]) {
          settings.application_kernel_asset = applicationKernelSnapshotURL.path.UTF8String;
        } else {
          NSLog(@"Failed to find snapshot: %@", applicationKernelSnapshotURL.path);
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
    _settings = DefaultSettingsForProcess(bundle);
  }

  return self;
}

- (instancetype)initWithFlutterAssets:(NSURL*)flutterAssetsURL
                             dartMain:(NSURL*)dartMainURL
                             packages:(NSURL*)dartPackages {
  self = [super init];

  if (self) {
    _settings = DefaultSettingsForProcess();

    if (dartMainURL != nil && [[NSFileManager defaultManager] fileExistsAtPath:dartMainURL.path]) {
      _settings.main_dart_file_path = dartMainURL.path.UTF8String;
    }

    if (dartPackages.path != nil &&
        [[NSFileManager defaultManager] fileExistsAtPath:dartPackages.path]) {
      _settings.packages_file_path = dartPackages.path.UTF8String;
    }
  }

  return self;
}

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssetsURL {
  self = [super init];

  if (self) {
    _settings = DefaultSettingsForProcess();

    if (flutterAssetsURL != nil &&
        [[NSFileManager defaultManager] fileExistsAtPath:flutterAssetsURL.path]) {
      _settings.assets_path = flutterAssetsURL.path.UTF8String;
    }
  }

  return self;
}

#pragma mark - Settings accessors

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

+ (NSString*)lookupKeyForAsset:(NSString*)asset {
  NSString* flutterAssetsName = [FlutterDartProject flutterAssetsName:[NSBundle mainBundle]];
  return [NSString stringWithFormat:@"%@/%@", flutterAssetsName, asset];
}

+ (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package {
  return [self lookupKeyForAsset:[NSString stringWithFormat:@"packages/%@/%@", package, asset]];
}

+ (NSString*)defaultBundleIdentifier {
  return @"io.flutter.flutter.app";
}

@end

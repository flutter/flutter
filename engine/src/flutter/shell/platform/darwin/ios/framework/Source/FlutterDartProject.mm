// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"

#include "flutter/common/threads.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartSource.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/flutter_main_ios.h"
#include "lib/fxl/strings/string_view.h"
#include "third_party/dart/runtime/include/dart_api.h"

static NSURL* URLForSwitch(const fxl::StringView name) {
  const auto& cmd = shell::Shell::Shared().GetCommandLine();
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  std::string switch_value;
  if (cmd.GetOptionValue(name, &switch_value)) {
    auto url = [NSURL fileURLWithPath:@(switch_value.c_str())];
    [defaults setURL:url forKey:@(name.data())];
    [defaults synchronize];
    return url;
  }

  return [defaults URLForKey:@(name.data())];
}

@implementation FlutterDartProject {
  NSBundle* _precompiledDartBundle;
  FlutterDartSource* _dartSource;

  VMType _vmTypeRequirement;
}

+ (void)initialize {
  if (self == [FlutterDartProject class]) {
    shell::FlutterMain();
  }
}

#pragma mark - Override base class designated initializers

- (instancetype)init {
  return [self initWithFlutterAssets:nil dartMain:nil packages:nil];
}

#pragma mark - Designated initializers

- (instancetype)initWithPrecompiledDartBundle:(NSBundle*)bundle {
  self = [super init];

  if (self) {
    _precompiledDartBundle = [bundle retain];

    [self checkReadiness];
  }

  return self;
}

- (instancetype)initWithFLXArchive:(NSURL*)archiveURL
                          dartMain:(NSURL*)dartMainURL
                          packages:(NSURL*)dartPackages {
  return nil;
}

- (instancetype)initWithFLXArchiveWithScriptSnapshot:(NSURL*)archiveURL {
  return nil;
}

- (instancetype)initWithFlutterAssets:(NSURL*)flutterAssetsURL
                             dartMain:(NSURL*)dartMainURL
                             packages:(NSURL*)dartPackages {
  self = [super init];

  if (self) {
    _dartSource = [[FlutterDartSource alloc] initWithDartMain:dartMainURL
                                                     packages:dartPackages
                                                flutterAssets:flutterAssetsURL];

    [self checkReadiness];
  }

  return self;
}

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssetsURL {
  self = [super init];

  if (self) {
    _dartSource =
        [[FlutterDartSource alloc] initWithFlutterAssetsWithScriptSnapshot:flutterAssetsURL];

    [self checkReadiness];
  }

  return self;
}

#pragma mark - Convenience initializers

- (instancetype)initFromDefaultSourceForConfiguration {
  NSBundle* bundle = [NSBundle mainBundle];

  if (Dart_IsPrecompiledRuntime()) {
    // Load from an AOTC snapshot.
    return [self initWithPrecompiledDartBundle:bundle];
  } else {
    // Load directly from sources if the appropriate command line flags are
    // specified. If not, try loading from a script snapshot in the framework
    // bundle.
    NSURL* flutterAssetsURL = URLForSwitch(shell::FlagForSwitch(shell::Switch::FlutterAssetsDir));

    if (flutterAssetsURL == nil) {
      // If the URL was not specified on the command line, look inside the
      // FlutterApplication bundle.
      NSString* flutterAssetsPath = [FlutterDartProject pathForFlutterAssetsFromBundle:bundle];
      if (flutterAssetsPath != nil) {
        flutterAssetsURL = [NSURL fileURLWithPath:flutterAssetsPath isDirectory:NO];
      }
    }

    if (flutterAssetsURL == nil) {
      NSLog(@"Error: flutterAssets directory not present in bundle; unable to start app.");
      [self release];
      return nil;
    }

    NSURL* dartMainURL = URLForSwitch(shell::FlagForSwitch(shell::Switch::MainDartFile));
    NSURL* dartPackagesURL = URLForSwitch(shell::FlagForSwitch(shell::Switch::Packages));

    return
        [self initWithFlutterAssets:flutterAssetsURL dartMain:dartMainURL packages:dartPackagesURL];
  }

  NSAssert(NO, @"Unreachable");
  [self release];
  return nil;
}

#pragma mark - Common initialization tasks

- (void)checkReadiness {
  if (_precompiledDartBundle != nil) {
    _vmTypeRequirement = VMTypePrecompilation;
    return;
  }

  if (_dartSource != nil) {
    _vmTypeRequirement = VMTypeInterpreter;
    return;
  }
}

#pragma mark - Assets-related utilities

+ (NSString*)pathForFlutterAssetsFromBundle:(NSBundle*)bundle {
  NSString* flutterAssetsName = [bundle objectForInfoDictionaryKey:@"FLTAssetsPath"];
  if (flutterAssetsName == nil) {
    // Default to "flutter_assets"
    flutterAssetsName = @"flutter_assets";
  }

  return [bundle pathForResource:flutterAssetsName ofType:nil];
}

#pragma mark - Launching the project in a preconfigured engine.

static NSString* NSStringFromVMType(VMType type) {
  switch (type) {
    case VMTypeInvalid:
      return @"Invalid";
    case VMTypeInterpreter:
      return @"Interpreter";
    case VMTypePrecompilation:
      return @"Precompilation";
  }

  return @"Unknown";
}

- (void)launchInEngine:(shell::Engine*)engine
        withEntrypoint:(NSString*)entrypoint
        embedderVMType:(VMType)embedderVMType
                result:(LaunchResult)result {
  if (_vmTypeRequirement == VMTypeInvalid) {
    result(NO, @"The Dart project is invalid and cannot be loaded by any VM.");
    return;
  }

  if (embedderVMType == VMTypeInvalid) {
    result(NO, @"The embedder is invalid.");
    return;
  }

  if (_vmTypeRequirement != embedderVMType) {
    NSString* message =
        [NSString stringWithFormat:
                      @"Could not load the project because of differing project type. "
                      @"The project can run in '%@' but the embedder is configured as "
                      @"'%@'",
                      NSStringFromVMType(_vmTypeRequirement), NSStringFromVMType(embedderVMType)];
    result(NO, message);
    return;
  }

  switch (_vmTypeRequirement) {
    case VMTypeInterpreter:
      [self runFromSourceInEngine:engine withEntrypoint:entrypoint result:result];
      return;
    case VMTypePrecompilation:
      [self runFromPrecompiledSourceInEngine:engine withEntrypoint:entrypoint result:result];
      return;
    case VMTypeInvalid:
      break;
  }

  return result(NO, @"Internal error");
}

- (void)launchInEngine:(shell::Engine*)engine
        embedderVMType:(VMType)embedderVMType
                result:(LaunchResult)result {
  if (_vmTypeRequirement == VMTypeInvalid) {
    result(NO, @"The Dart project is invalid and cannot be loaded by any VM.");
    return;
  }

  if (embedderVMType == VMTypeInvalid) {
    result(NO, @"The embedder is invalid.");
    return;
  }

  if (_vmTypeRequirement != embedderVMType) {
    NSString* message =
        [NSString stringWithFormat:
                      @"Could not load the project because of differing project type. "
                      @"The project can run in '%@' but the embedder is configured as "
                      @"'%@'",
                      NSStringFromVMType(_vmTypeRequirement), NSStringFromVMType(embedderVMType)];
    result(NO, message);
    return;
  }

  switch (_vmTypeRequirement) {
    case VMTypeInterpreter:
      [self runFromSourceInEngine:engine withEntrypoint:@"main" result:result];
      return;
    case VMTypePrecompilation:
      [self runFromPrecompiledSourceInEngine:engine withEntrypoint:@"main" result:result];
      return;
    case VMTypeInvalid:
      break;
  }

  return result(NO, @"Internal error");
}

#pragma mark - Running from precompiled application bundles

- (void)runFromPrecompiledSourceInEngine:(shell::Engine*)engine
                          withEntrypoint:(NSString*)entrypoint
                                  result:(LaunchResult)result {
  if (![_precompiledDartBundle load]) {
    NSString* message = [NSString
        stringWithFormat:@"Could not load the framework ('%@') containing precompiled code.",
                         _precompiledDartBundle.bundleIdentifier];
    result(NO, message);
    return;
  }

  NSString* path = [FlutterDartProject pathForFlutterAssetsFromBundle:_precompiledDartBundle];
  if (path.length == 0) {
    NSString* message = [NSString stringWithFormat:
                                      @"Could not find the 'flutter_assets' dir in "
                                      @"the precompiled Dart bundle with ID '%@'",
                                      _precompiledDartBundle.bundleIdentifier];
    result(NO, message);
    return;
  }

  std::string bundle_path = path.UTF8String;
  blink::Threads::UI()->PostTask([
    engine = engine->GetWeakPtr(), bundle_path, entrypoint = std::string([entrypoint UTF8String])
  ] {
    if (engine)
      engine->RunBundle(bundle_path, entrypoint);
  });

  result(YES, @"Success");
}

#pragma mark - Running from source

- (void)runFromSourceInEngine:(shell::Engine*)engine
               withEntrypoint:(NSString*)entrypoint
                       result:(LaunchResult)result {
  if (_dartSource == nil) {
    result(NO, @"Dart source not specified.");
    return;
  }

  [_dartSource validate:^(BOOL success, NSString* message) {
    if (!success) {
      return result(NO, message);
    }

    std::string bundle_path = _dartSource.flutterAssets.absoluteURL.path.UTF8String;

    if (_dartSource.assetsDirContainsScriptSnapshot) {
      blink::Threads::UI()->PostTask([
        engine = engine->GetWeakPtr(), bundle_path,
        entrypoint = std::string([entrypoint UTF8String])
      ] {
        if (engine)
          engine->RunBundle(bundle_path, entrypoint);
      });
    } else {
      std::string main = _dartSource.dartMain.absoluteURL.path.UTF8String;
      std::string packages = _dartSource.packages.absoluteURL.path.UTF8String;
      blink::Threads::UI()->PostTask(
          [ engine = engine->GetWeakPtr(), bundle_path, main, packages ] {
            if (engine)
              engine->RunBundleAndSource(bundle_path, main, packages);
          });
    }

    result(YES, @"Success");
  }];
}

#pragma mark - Misc.

- (void)dealloc {
  [_precompiledDartBundle unload];
  [_precompiledDartBundle release];
  [_dartSource release];

  [super dealloc];
}

@end

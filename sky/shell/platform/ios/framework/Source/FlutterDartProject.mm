// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/framework/Source/FlutterDartProject_Internal.h"

#include "base/command_line.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/shell/platform/ios/framework/Source/FlutterDartSource.h"
#include "sky/shell/switches.h"

static NSURL* URLForSwitch(const char* name) {
  auto cmd = *base::CommandLine::ForCurrentProcess();
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  if (cmd.HasSwitch(name)) {
    auto url = [NSURL fileURLWithPath:@(cmd.GetSwitchValueASCII(name).c_str())];
    [defaults setURL:url forKey:@(name)];
    [defaults synchronize];
    return url;
  }

  return [defaults URLForKey:@(name)];
}

@implementation FlutterDartProject {
  NSBundle* _precompiledDartBundle;
  FlutterDartSource* _dartSource;

  VMType _vmTypeRequirement;
}

#pragma mark - Override base class designated initializers

- (instancetype)init {
  return [self initWithFLXArchive:nil dartMain:nil packages:nil];
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
  self = [super init];

  if (self) {
    _dartSource = [[FlutterDartSource alloc] initWithDartMain:dartMainURL
                                                     packages:dartPackages
                                                   flxArchive:archiveURL];

    [self checkReadiness];
  }

  return self;
}

- (instancetype)initWithFLXArchiveWithScriptSnapshot:(NSURL*)archiveURL {
  self = [super init];

  if (self) {
    _dartSource = [[FlutterDartSource alloc]
        initWithFLXArchiveWithScriptSnapshot:archiveURL];

    [self checkReadiness];
  }

  return self;
}

#pragma mark - Convenience initializers

- (instancetype)initFromDefaultSourceForConfiguration {
  NSString* bundlePath =
      [[NSBundle mainBundle] pathForResource:@"FlutterApplication"
                                      ofType:@"framework"
                                 inDirectory:@"Frameworks"];
  NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];

  // In both precompilation and non-precompilation cases, we need to bundle
  // loaded since at least the FLX archive is present in it.
  [bundle load];

  if (Dart_IsPrecompiledRuntime()) {
    // Load from an AOTC snapshot.
    return [self initWithPrecompiledDartBundle:bundle];
  } else {
    // Load directly from sources if the appropriate command line flags are
    // specified. If not, try loading from a script snapshot in the framework
    // bundle.
    NSURL* flxURL = URLForSwitch(sky::shell::switches::kFLX);

    if (flxURL == nil) {
      // If the URL was not specified on the command line, look inside the
      // FlutterApplication bundle.
      flxURL =
          [NSURL fileURLWithPath:[bundle pathForResource:@"app" ofType:@"flx"]
                     isDirectory:NO];
    }

    NSURL* dartMainURL = URLForSwitch(sky::shell::switches::kMainDartFile);
    NSURL* dartPackagesURL = URLForSwitch(sky::shell::switches::kPackages);

    return [self initWithFLXArchive:flxURL
                           dartMain:dartMainURL
                           packages:dartPackagesURL];
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

- (void)launchInEngine:(sky::SkyEnginePtr&)engine
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
    NSString* message = [NSString
        stringWithFormat:
            @"Could not load the project because of differing project type. "
            @"The project can run in '%@' but the embedder is configured as "
            @"'%@'",
            NSStringFromVMType(_vmTypeRequirement),
            NSStringFromVMType(embedderVMType)];
    result(NO, message);
    return;
  }

  switch (_vmTypeRequirement) {
    case VMTypeInterpreter:
      [self runFromSourceInEngine:engine result:result];
      return;
    case VMTypePrecompilation:
      [self runFromPrecompiledSourceInEngine:engine result:result];
      return;
    case VMTypeInvalid:
      break;
  }

  return result(NO, @"Internal error");
}

#pragma mark - Running from precompiled application bundles

- (void)runFromPrecompiledSourceInEngine:(sky::SkyEnginePtr&)engine
                                  result:(LaunchResult)result {
  if (![_precompiledDartBundle load]) {
    NSString* message = [NSString
        stringWithFormat:
            @"Could not load the framework ('%@') containing precompiled code.",
            _precompiledDartBundle.bundleIdentifier];
    result(NO, message);
    return;
  }

  NSString* path =
      [_precompiledDartBundle pathForResource:@"app" ofType:@"flx"];

  if (path.length == 0) {
    NSString* message =
        [NSString stringWithFormat:@"Could not find the 'app.flx' archive in "
                                   @"the precompiled Dart bundle with ID '%@'",
                                   _precompiledDartBundle.bundleIdentifier];
    result(NO, message);
    return;
  }

  engine->RunFromPrecompiledSnapshot(path.UTF8String);
  result(YES, @"Success");
}

#pragma mark - Running from source

- (void)runFromSourceInEngine:(sky::SkyEnginePtr&)engine
                       result:(LaunchResult)result {
  if (_dartSource == nil) {
    result(NO, @"Dart source not specified.");
    return;
  }

  [_dartSource validate:^(BOOL success, NSString* message) {
    if (!success) {
      return result(NO, message);
    }

    if (_dartSource.archiveContainsScriptSnapshot) {
      engine->RunFromBundle("file://script_snapshot",
                            _dartSource.flxArchive.absoluteURL.path.UTF8String);
    } else {
      engine->RunFromFile(_dartSource.dartMain.absoluteURL.path.UTF8String,
                          _dartSource.packages.absoluteURL.path.UTF8String,
                          _dartSource.flxArchive.absoluteURL.path.UTF8String);
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

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <SafariServices/SafariServices.h>

#import "FLTURLLauncherPlugin.h"
#import "FLTURLLauncherPlugin_Test.h"
#import "FULLauncher.h"
#import "messages.g.h"

typedef void (^OpenInSafariVCResponse)(NSNumber *_Nullable, FlutterError *_Nullable);

@interface FLTURLLaunchSession : NSObject <SFSafariViewControllerDelegate>

@property(copy, nonatomic) OpenInSafariVCResponse completion;
@property(strong, nonatomic) NSURL *url;
@property(strong, nonatomic) SFSafariViewController *safari;
@property(nonatomic, copy) void (^didFinish)(void);

@end

@implementation FLTURLLaunchSession

- (instancetype)initWithURL:url completion:completion {
  self = [super init];
  if (self) {
    self.url = url;
    self.completion = completion;
    self.safari = [[SFSafariViewController alloc] initWithURL:url];
    self.safari.delegate = self;
  }
  return self;
}

- (void)safariViewController:(SFSafariViewController *)controller
      didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
  if (didLoadSuccessfully) {
    self.completion(@YES, nil);
  } else {
    self.completion(
        nil, [FlutterError
                 errorWithCode:@"Error"
                       message:[NSString stringWithFormat:@"Error while launching %@", self.url]
                       details:nil]);
  }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
  [controller dismissViewControllerAnimated:YES completion:nil];
  self.didFinish();
}

- (void)close {
  [self safariViewControllerDidFinish:self.safari];
}

@end

#pragma mark -

/// Default implementation of FULLancher, using UIApplication.
@interface FULUIApplicationLauncher : NSObject <FULLauncher>
@end

@implementation FULUIApplicationLauncher
- (BOOL)canOpenURL:(nonnull NSURL *)url {
  return [[UIApplication sharedApplication] canOpenURL:url];
}

- (void)openURL:(nonnull NSURL *)url
              options:(nonnull NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
    completionHandler:(void (^_Nullable)(BOOL))completion {
  [[UIApplication sharedApplication] openURL:url options:options completionHandler:completion];
}

@end

#pragma mark -

@interface FLTURLLauncherPlugin ()

@property(strong, nonatomic) FLTURLLaunchSession *currentSession;
@property(strong, nonatomic) NSObject<FULLauncher> *launcher;

@end

@implementation FLTURLLauncherPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] init];
  FULUrlLauncherApiSetup(registrar.messenger, plugin);
}

- (instancetype)init {
  return [self initWithLauncher:[[FULUIApplicationLauncher alloc] init]];
}

- (instancetype)initWithLauncher:(NSObject<FULLauncher> *)launcher {
  if (self = [super init]) {
    _launcher = launcher;
  }
  return self;
}

- (nullable NSNumber *)canLaunchURL:(NSString *)urlString
                              error:(FlutterError *_Nullable *_Nonnull)error {
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    *error = [self invalidURLErrorForURLString:urlString];
    return nil;
  }
  return @([self.launcher canOpenURL:url]);
}

- (void)launchURL:(NSString *)urlString
    universalLinksOnly:(NSNumber *)universalLinksOnly
            completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    completion(nil, [self invalidURLErrorForURLString:urlString]);
    return;
  }
  NSDictionary *options = @{UIApplicationOpenURLOptionUniversalLinksOnly : universalLinksOnly};
  [self.launcher openURL:url
                 options:options
       completionHandler:^(BOOL success) {
         completion(@(success), nil);
       }];
}

- (void)openSafariViewControllerWithURL:(NSString *)urlString
                             completion:(OpenInSafariVCResponse)completion {
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    completion(nil, [self invalidURLErrorForURLString:urlString]);
    return;
  }
  self.currentSession = [[FLTURLLaunchSession alloc] initWithURL:url completion:completion];
  __weak typeof(self) weakSelf = self;
  self.currentSession.didFinish = ^(void) {
    weakSelf.currentSession = nil;
  };
  [self.topViewController presentViewController:self.currentSession.safari
                                       animated:YES
                                     completion:nil];
}

- (void)closeSafariViewControllerWithError:(FlutterError *_Nullable *_Nonnull)error {
  [self.currentSession close];
}

- (UIViewController *)topViewController {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO(stuartmorgan) Provide a non-deprecated codepath. See
  // https://github.com/flutter/flutter/issues/104117
  return [self topViewControllerFromViewController:[UIApplication sharedApplication]
                                                       .keyWindow.rootViewController];
#pragma clang diagnostic pop
}

/**
 * This method recursively iterate through the view hierarchy
 * to return the top most view controller.
 *
 * It supports the following scenarios:
 *
 * - The view controller is presenting another view.
 * - The view controller is a UINavigationController.
 * - The view controller is a UITabBarController.
 *
 * @return The top most view controller.
 */
- (UIViewController *)topViewControllerFromViewController:(UIViewController *)viewController {
  if ([viewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController *)viewController;
    return [self
        topViewControllerFromViewController:[navigationController.viewControllers lastObject]];
  }
  if ([viewController isKindOfClass:[UITabBarController class]]) {
    UITabBarController *tabController = (UITabBarController *)viewController;
    return [self topViewControllerFromViewController:tabController.selectedViewController];
  }
  if (viewController.presentedViewController) {
    return [self topViewControllerFromViewController:viewController.presentedViewController];
  }
  return viewController;
}

/**
 * Creates an error for an invalid URL string.
 *
 * @param url The invalid URL string
 * @return The error to return
 */
- (FlutterError *)invalidURLErrorForURLString:(NSString *)url {
  return [FlutterError errorWithCode:@"argument_error"
                             message:@"Unable to parse URL"
                             details:[NSString stringWithFormat:@"Provided URL: %@", url]];
}
@end

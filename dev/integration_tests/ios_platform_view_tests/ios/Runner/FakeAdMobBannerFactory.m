// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FakeAdMobBannerFactory.h"
#import "LinkNavigationWebView.h"

static const int kAdMobBannerNestedWebViewDepth = 7;

// A real AdMob request could be throttled by AdMob server (even using test Ad ID).
// To avoid flakiness, we use a "fake" banner, with a web view in the 7th level of nested views to mimic a similar structure.
@interface FakeAdMobBanner: UIView
@end

@implementation FakeAdMobBanner

- (instancetype)init {
  self = [super init];
  if (self) {
    UIView *currentView = self;
    for (int i = 0; i < kAdMobBannerNestedWebViewDepth - 1; i++) {
      UIView *nestedView = [[UIView alloc] initWithFrame:currentView.bounds];
      nestedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      [currentView addSubview:nestedView];
      currentView = nestedView;
    }

    LinkNavigationWebView *webView = [[LinkNavigationWebView alloc] init];
    webView.frame = currentView.bounds;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [currentView addSubview:webView];
  }
  return self;
}
@end

@interface PlatformFakeAdMobBanner: NSObject<FlutterPlatformView>
@property (strong, nonatomic) FakeAdMobBanner *banner;
@end

@implementation PlatformFakeAdMobBanner

- (instancetype)init {
  self = [super init];
  if (self) {
    _banner = [[FakeAdMobBanner alloc] init];
  }
  return self;
}

- (UIView *)view {
  return _banner;
}

@end


@implementation FakeAdMobBannerFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[PlatformFakeAdMobBanner alloc] init];
}

@end

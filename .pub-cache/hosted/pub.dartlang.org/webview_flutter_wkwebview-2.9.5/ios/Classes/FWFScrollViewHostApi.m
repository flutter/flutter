// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFScrollViewHostApi.h"
#import "FWFWebViewHostApi.h"

@interface FWFScrollViewHostApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFScrollViewHostApiImpl
- (instancetype)initWithInstanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (UIScrollView *)scrollViewForIdentifier:(NSNumber *)identifier {
  return (UIScrollView *)[self.instanceManager instanceForIdentifier:identifier.longValue];
}

- (void)createFromWebViewWithIdentifier:(nonnull NSNumber *)identifier
                      webViewIdentifier:(nonnull NSNumber *)webViewIdentifier
                                  error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  WKWebView *webView =
      (WKWebView *)[self.instanceManager instanceForIdentifier:webViewIdentifier.longValue];
  [self.instanceManager addDartCreatedInstance:webView.scrollView
                                withIdentifier:identifier.longValue];
}

- (NSArray<NSNumber *> *)
    contentOffsetForScrollViewWithIdentifier:(nonnull NSNumber *)identifier
                                       error:(FlutterError *_Nullable *_Nonnull)error {
  CGPoint point = [[self scrollViewForIdentifier:identifier] contentOffset];
  return @[ @(point.x), @(point.y) ];
}

- (void)scrollByForScrollViewWithIdentifier:(nonnull NSNumber *)identifier
                                          x:(nonnull NSNumber *)x
                                          y:(nonnull NSNumber *)y
                                      error:(FlutterError *_Nullable *_Nonnull)error {
  UIScrollView *scrollView = [self scrollViewForIdentifier:identifier];
  CGPoint contentOffset = scrollView.contentOffset;
  [scrollView setContentOffset:CGPointMake(contentOffset.x + x.doubleValue,
                                           contentOffset.y + y.doubleValue)];
}

- (void)setContentOffsetForScrollViewWithIdentifier:(nonnull NSNumber *)identifier
                                                toX:(nonnull NSNumber *)x
                                                  y:(nonnull NSNumber *)y
                                              error:(FlutterError *_Nullable *_Nonnull)error {
  [[self scrollViewForIdentifier:identifier]
      setContentOffset:CGPointMake(x.doubleValue, y.doubleValue)];
}
@end

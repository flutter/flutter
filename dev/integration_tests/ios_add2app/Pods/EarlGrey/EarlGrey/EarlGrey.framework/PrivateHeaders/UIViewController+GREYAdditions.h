//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (GREYAdditions)

/**
 *  Tracks this view controller as the root view controller of @c window, setting up the desired
 *  states so that EarlGrey can decide when to wait for this view controller to appear. This method
 *  should be called each time window's @c hidden property changes. Passing @c nil for @c window
 *  indicates this view controller is no longer a root view controller.
 *  @todo Use KVO for the hidden property.
 *
 *  @param window The window to which to associate this view controller as the root view controller.
 */
- (void)grey_trackAsRootViewControllerForWindow:(UIWindow *_Nullable)window;

@end

NS_ASSUME_NONNULL_END

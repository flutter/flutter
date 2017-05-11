// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.Copyright © 2017 The Chromium Authors. All rights reserved.


#import <Foundation/Foundation.h>

#import "MainViewController.h"
#import "NativeViewController.h"

@interface MainViewController ()

@property (nonatomic) NativeViewController* nativeViewController;
@property (nonatomic) FlutterViewController* flutterViewController;
@property (nonatomic) FlutterBasicMessageChannel* messageChannel;
@end

static NSString* const emptyString = @"";
static NSString* const ping = @"ping";
static NSString* const channel = @"increment";

@implementation MainViewController

- (NSString*) messageName {
  return channel;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {

  if ([segue.identifier isEqualToString: @"NativeViewControllerSegue"]) {
    self.nativeViewController = segue.destinationViewController;
    self.nativeViewController.delegate = self;
  }

  if ([segue.identifier isEqualToString:@"FlutterViewControllerSegue"]) {
    self.flutterViewController = segue.destinationViewController;

    self.messageChannel = [FlutterBasicMessageChannel messageChannelWithName:channel
                                                             binaryMessenger:self.flutterViewController
                                                                       codec:[FlutterStringCodec sharedInstance]];

    MainViewController*  __weak weakSelf = self;
    [self.messageChannel setMessageHandler:^(id message, FlutterReply reply) {
      [weakSelf.nativeViewController didReceiveIncrement];
      reply(emptyString);
    }];
  }
}

- (void)didTapIncrementButton {
  [self.messageChannel sendMessage:ping];
}

@end

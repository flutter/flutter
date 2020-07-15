// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "NativeViewController.h"

@interface NativeViewController ()

@end

@implementation NativeViewController {
  int _counter;
  UILabel* _incrementLabel;
}

- (instancetype)initWithDelegate:(id<NativeViewControllerDelegate>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.delegate = delegate;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  return [self initWithDelegate:nil];
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
   return [self initWithDelegate:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Native iOS View";
    self.view.backgroundColor = UIColor.lightGrayColor;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                                initWithTitle:@"Back"
                                                        style:UIBarButtonItemStylePlain
                                                       target:nil
                                                       action:nil];

    _incrementLabel = [self addIncrementLabel];
    UIStackView* footer = [self addFooter];

    _incrementLabel.translatesAutoresizingMaskIntoConstraints = false;
    footer.translatesAutoresizingMaskIntoConstraints = false;
    UILayoutGuide* marginsGuide = self.view.layoutMarginsGuide;
    NSMutableArray* array = [[NSMutableArray alloc] init];
    [array addObject:[_incrementLabel.centerXAnchor
                         constraintEqualToAnchor:self.view.centerXAnchor]];
    [array addObject:[_incrementLabel.centerYAnchor
                         constraintEqualToAnchor:self.view.centerYAnchor]];
    [array addObject:[footer.centerXAnchor
                         constraintEqualToAnchor:self.view.centerXAnchor]];
    [array addObject:[footer.widthAnchor
                         constraintEqualToAnchor:marginsGuide.widthAnchor]];
    [array addObject:[footer.bottomAnchor
                         constraintEqualToAnchor:marginsGuide.bottomAnchor]];

    [NSLayoutConstraint activateConstraints:array];
    [self updateIncrementLabel];
}

/// Adds a label to the view that will contain the counter text.
///
/// - Returns: The new label.
-(UILabel*) addIncrementLabel {
  UILabel* incrementLabel = [[UILabel alloc] init];
  incrementLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  incrementLabel.textColor = UIColor.blackColor;
  incrementLabel.accessibilityIdentifier = @"counter_on_iOS";
  [self.view addSubview:incrementLabel];
  return incrementLabel;
}

/// Adds a horizontal stack to the view, anchored to the bottom.
///
/// - Returns: The new stack.
-(UIStackView*) addFooter {
  UILabel* mainLabel = [self createMainLabel];
  UIButton* incrementButton = [self createIncrementButton];
  UIStackView* stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  [stackView addArrangedSubview:mainLabel];
  [stackView addArrangedSubview:incrementButton];
  stackView.axis = UILayoutConstraintAxisHorizontal;
  stackView.alignment = UIStackViewAlignmentBottom;
  [self.view addSubview:stackView];
  return stackView;
}

/// Creates a label identifying this view.  Does not add it to the view.
///
/// - Returns: The new label.
-(UILabel*) createMainLabel {
  UILabel* mainLabel = [[UILabel alloc] init];
  mainLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
  mainLabel.textColor = UIColor.blackColor;
  mainLabel.text = @"Native";
  return mainLabel;
}

/// Creates a button that will increment a counter.  Does not add it to the view.
///
/// - Returns: The new button.
-(UIButton*) createIncrementButton {
  UIButton *incrementButton = [UIButton buttonWithType:UIButtonTypeSystem];
  incrementButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
  [incrementButton setTitle:@"Add" forState:UIControlStateNormal];
  incrementButton.accessibilityLabel = @"Increment via iOS";
  incrementButton.layer.cornerRadius = 15.0;
  [incrementButton addTarget:self
                      action:@selector(handleIncrement:)
            forControlEvents:UIControlEventTouchUpInside];
  return incrementButton;
}

// MARK: - Actions

/// Action triggered from tapping on the increment button.  Triggers a corresponding event in the
/// delegate if one is available, otherwise increments our internal counter.
-(void) handleIncrement:(UIButton*)sender {
  if (self.delegate) {
    [self.delegate didTapIncrementButton];
  } else {
    [self didReceiveIncrement];
  }
}

/// Updates the increment label text to match the increment counter.
-(void) updateIncrementLabel {
  _incrementLabel.text = [NSString
      stringWithFormat:@"%@ tapped %d %@.",
                       self.delegate == nil ? @"Button" : @"Flutter button",
                       _counter, _counter == 1 ? @"time" : @"times"];
}

/// Increments our internal counter and updates the view.
-(void) didReceiveIncrement {
  _counter += 1;
  [self updateIncrementLabel];
}

@end

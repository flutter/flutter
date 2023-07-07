#import "FluttertoastPlugin.h"
#import <Toast/UIView+Toast.h>

static NSString *const CHANNEL_NAME = @"PonnamKarthik/fluttertoast";

@interface FluttertoastPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, assign) BOOL isKeyboardVisible;
@end

@implementation FluttertoastPlugin {
    FlutterResult _result;

}

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:CHANNEL_NAME
                  binaryMessenger:[registrar messenger]];
    FluttertoastPlugin *instance = [[FluttertoastPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];

}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardWillShow {
    self.isKeyboardVisible = YES;
}

- (void)keyboardWillHide {
    self.isKeyboardVisible = NO;
}

- (UIColor*) colorWithHex: (NSUInteger)hex {
    CGFloat red, green, blue, alpha;

    red = ((CGFloat)((hex >> 16) & 0xFF)) / ((CGFloat)0xFF);
    green = ((CGFloat)((hex >> 8) & 0xFF)) / ((CGFloat)0xFF);
    blue = ((CGFloat)((hex >> 0) & 0xFF)) / ((CGFloat)0xFF);
    alpha = hex > 0xFFFFFF ? ((CGFloat)((hex >> 24) & 0xFF)) / ((CGFloat)0xFF) : 1;

    return [UIColor colorWithRed: red green:green blue:blue alpha:alpha];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if([@"cancel" isEqualToString:call.method]) {
        __weak typeof(self) weakSelf = self;
        [[weakSelf _readKeyWindow] hideAllToasts];
        result([NSNumber numberWithBool:true]);
    } else if ([@"showToast" isEqualToString:call.method]) {
        NSString *msg = call.arguments[@"msg"];
        NSString *gravity = call.arguments[@"gravity"];
        NSString *durationTime = call.arguments[@"time"];
        NSNumber *bgcolor = call.arguments[@"bgcolor"];
        NSNumber *textcolor = call.arguments[@"textcolor"];
//        NSNumber *size = call.arguments[@"size"];
        NSNumber *fontSize = call.arguments[@"fontSize"];

        if ([fontSize isKindOfClass:[NSNull class]]) {
            fontSize = [[NSNumber alloc] initWithInt:16];
        }
        
        CGFloat cgf = [fontSize doubleValue];
        int time = 1;
        @try {
            time = [durationTime intValue];
        } @catch (NSException *e) {
            time = 3;
        }

        if (time > 10) time = 10;
        else if (time < 1) time = 1;


        CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
        style.messageFont = [UIFont systemFontOfSize:cgf];
        style.backgroundColor = [self colorWithHex:bgcolor.unsignedIntegerValue];
        style.messageColor = [self colorWithHex:textcolor.unsignedIntegerValue];

//        if (@available(iOS 11.0, *)) {
//            UIWindow *window = UIApplication.sharedApplication.keyWindow;
//        }

        if ([gravity isEqualToString:@"top"]) {
            
            [self makeToast:msg duration:time position:CSToastPositionTop style:style];
            
        } else if ([gravity isEqualToString:@"center"]) {
            
            [self makeToast:msg duration:time position:CSToastPositionCenter style:style];
            
        } else {
            
            [self makeToast:msg duration:time position:CSToastPositionBottom style:style];
            
        }
        result([NSNumber numberWithBool:true]);

    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position style:(CSToastStyle *)style {
    __weak typeof(self) weakSelf = self;
    // Fixed if the keyboard disappear, the toast disappear at once, because the window where the keyboard is is gone.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[weakSelf _readKeyWindow] makeToast:message duration:duration position:position style:style];
    });
}

#pragma mark - read the key window

- (UIWindow *)_readKeyWindow {
    NSArray *windows = UIApplication.sharedApplication.windows;
    if (self.isKeyboardVisible) {
        return windows.lastObject;
    }
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return nil;
}

@end

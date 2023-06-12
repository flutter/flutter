#import <Flutter/Flutter.h>

@interface AudioSessionPlugin : NSObject<FlutterPlugin>

@property (readonly, nonatomic) FlutterMethodChannel *channel;

@end

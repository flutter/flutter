#import <FlutterMacOS/FlutterMacOS.h>

@interface AudioSessionPlugin : NSObject<FlutterPlugin>

@property (readonly, nonatomic) FlutterMethodChannel *channel;

@end

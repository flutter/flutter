#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
    #import <Flutter/Flutter.h>
#else
    #import <FlutterMacOS/FlutterMacOS.h>
#endif

@interface AudioplayersPlugin : NSObject<FlutterPlugin>
@end

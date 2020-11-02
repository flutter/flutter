#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/** A Flutter plugin that's responsible for communicating the test results back
 * to iOS XCTest. */
@interface IntegrationTestPlugin : NSObject <FlutterPlugin>

/**
 * Test results that are sent from Dart when integration test completes. Before the
 * completion, it is
 * @c nil.
 */
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *testResults;

/** Fetches the singleton instance of the plugin. */
+ (IntegrationTestPlugin *)instance;

- (void)setupChannels:(id<FlutterBinaryMessenger>)binaryMessenger;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#import "IntegrationTestIosTest.h"
#import "IntegrationTestPlugin.h"

@implementation IntegrationTestIosTest

- (BOOL)testIntegrationTest:(NSString **)testResult {
  IntegrationTestPlugin *integrationTestPlugin = [IntegrationTestPlugin instance];
  UIViewController *rootViewController =
      [[[[UIApplication sharedApplication] delegate] window] rootViewController];
  if (![rootViewController isKindOfClass:[FlutterViewController class]]) {
    NSLog(@"expected FlutterViewController as rootViewController.");
    return NO;
  }
  FlutterViewController *flutterViewController = (FlutterViewController *)rootViewController;
  [integrationTestPlugin setupChannels:flutterViewController.engine.binaryMessenger];
  while (!integrationTestPlugin.testResults) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.f, NO);
  }
  NSDictionary<NSString *, NSString *> *testResults = integrationTestPlugin.testResults;
  NSMutableArray<NSString *> *passedTests = [NSMutableArray array];
  NSMutableArray<NSString *> *failedTests = [NSMutableArray array];
  NSLog(@"==================== Test Results =====================");
  for (NSString *test in testResults.allKeys) {
    NSString *result = testResults[test];
    if ([result isEqualToString:@"success"]) {
      NSLog(@"%@ passed.", test);
      [passedTests addObject:test];
    } else {
      NSLog(@"%@ failed: %@", test, result);
      [failedTests addObject:test];
    }
  }
  NSLog(@"================== Test Results End ====================");
  BOOL testPass = failedTests.count == 0;
  if (!testPass && testResult) {
    *testResult =
        [NSString stringWithFormat:@"Detected failed integration test(s) %@ among %@",
                                   failedTests.description, testResults.allKeys.description];
  }
  return testPass;
}

@end

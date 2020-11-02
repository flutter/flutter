#import <Foundation/Foundation.h>

@interface IntegrationTestIosTest : NSObject

- (BOOL)testIntegrationTest:(NSString **)testResult;

@end

#define INTEGRATION_TEST_IOS_RUNNER(__test_class)                                           \
  @interface __test_class : XCTestCase                                                      \
  @end                                                                                      \
                                                                                            \
  @implementation __test_class                                                              \
                                                                                            \
  -(void)testIntegrationTest {                                                              \
    NSString *testResult;                                                                   \
    IntegrationTestIosTest *integrationTestIosTest = [[IntegrationTestIosTest alloc] init]; \
    BOOL testPass = [integrationTestIosTest testIntegrationTest:&testResult];               \
    XCTAssertTrue(testPass, @"%@", testResult);                                             \
  }                                                                                         \
                                                                                            \
  @end

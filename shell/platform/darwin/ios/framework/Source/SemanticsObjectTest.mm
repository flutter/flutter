#import <XCTest/XCTest.h>

#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_ARC

namespace flutter {
namespace {
class MockAccessibilityBridge : public AccessibilityBridgeIos {
 public:
  MockAccessibilityBridge() { view_ = [[UIView alloc] init]; }
  UIView* view() const override { return view_; }
  UIView<UITextInput>* textInputView() override { return nil; }
  void DispatchSemanticsAction(int32_t id, SemanticsAction action) override {}
  void DispatchSemanticsAction(int32_t id,
                               SemanticsAction action,
                               std::vector<uint8_t> args) override {}
  FlutterPlatformViewsController* GetPlatformViewsController() const override { return nil; }

 private:
  UIView* view_;
};
}  // namespace
}  // namespace flutter

@interface SemanticsObjectTest : XCTestCase
@end

@implementation SemanticsObjectTest

- (void)testCreate {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  XCTAssertNotNil(object);
}

@end

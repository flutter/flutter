from pathlib import Path
path = Path(r'C:\Users\Mohit joshi\flutter\engine\src\flutter\shell\platform\darwin\ios\framework\Source\FlutterPlatformViewsTest.mm')
text = path.read_text(encoding='utf-8')
old = '''  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  UIGestureRecognizer* forwardGectureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGectureRecognizer = gestureRecognizer;
      break;
    }
  }
'''
new = '''  UIView* touchInteceptorView = GetFlutterTouchInterceptingView(gMockPlatformView);
  XCTAssertNotNil(touchInteceptorView);
  UIGestureRecognizer* forwardGectureRecognizer = GetForwardingGestureRecognizer(touchInteceptorView);
  XCTAssertNotNil(forwardGectureRecognizer);
'''
count_before = text.count(old)
print('count_before', count_before)
text = text.replace(old, new)
count_after = text.count(old)
path.write_text(text, encoding='utf-8')
print('count_after', count_after)
print('helper_exists', 'GetFlutterTouchInterceptingView' in text, 'forward_exists', 'GetForwardingGestureRecognizer' in text)

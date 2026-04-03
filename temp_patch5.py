import re
from pathlib import Path
path = Path('C:\\Users\\Mohit joshi\\flutter\\engine\\src\\flutter\\shell\\platform\\darwin\\ios\\framework\\Source\\FlutterPlatformViewsTest.mm')
text = path.read_text(encoding='utf-8')
pattern = re.compile(r'''^\s*// Find touch inteceptor view\s*\n(?:.*\n)*?^\s*// Find ForwardGestureRecognizer\s*\n(?:.*\n)*?^\s*\}\s*\n''', re.MULTILINE)
new_block = '  UIView* touchInteceptorView = GetFlutterTouchInterceptingView(gMockPlatformView);\n  XCTAssertNotNil(touchInteceptorView);\n  UIGestureRecognizer* forwardGectureRecognizer = GetForwardingGestureRecognizer(touchInteceptorView);\n  XCTAssertNotNil(forwardGectureRecognizer);\n'
text2, count = pattern.subn(new_block, text)
path.write_text(text2, encoding='utf-8')
print('replaced blocks', count)
print('remaining marker', text2.count('UIView* touchInteceptorView = gMockPlatformView'))

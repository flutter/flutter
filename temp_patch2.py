from pathlib import Path
path = Path(r'C:\Users\Mohit joshi\flutter\engine\src\flutter\shell\platform\darwin\ios\framework\Source\FlutterPlatformViewsTest.mm')
text = path.read_text(encoding='utf-8')
lines = text.splitlines(True)
new_lines = []
i = 0
replacements = 0
while i < len(lines):
    if lines[i].strip() == '// Find touch inteceptor view':
        # find for-loop start
        j = i + 1
        while j < len(lines) and 'for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers)' not in lines[j]:
            j += 1
        if j >= len(lines):
            new_lines.append(lines[i]); i += 1; continue
        # count braces from current line
        stack = 0
        while j < len(lines):
            stack += lines[j].count('{')
            stack -= lines[j].count('}')
            j += 1
            if stack <= 0:
                break
        # Replace from i to j (exclusive j) with helper block
        new_lines.append('  UIView* touchInteceptorView = GetFlutterTouchInterceptingView(gMockPlatformView);\n')
        new_lines.append('  XCTAssertNotNil(touchInteceptorView);\n')
        new_lines.append('  UIGestureRecognizer* forwardGectureRecognizer = GetForwardingGestureRecognizer(touchInteceptorView);\n')
        new_lines.append('  XCTAssertNotNil(forwardGectureRecognizer);\n')
        replacements += 1
        i = j
    else:
        new_lines.append(lines[i])
        i += 1
path.write_text(''.join(new_lines), encoding='utf-8')
print('replacements', replacements)
print('helper_exists', 'GetFlutterTouchInterceptingView' in ''.join(new_lines), 'forward_exists', 'GetForwardingGestureRecognizer' in ''.join(new_lines))

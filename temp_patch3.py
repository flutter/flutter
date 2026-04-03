from pathlib import Path
path = Path(r'C:\Users\Mohit joshi\flutter\engine\src\flutter\shell\platform\darwin\ios\framework\Source\FlutterPlatformViewsTest.mm')
text = path.read_text(encoding='utf-8')
lines = text.splitlines(True)
new_lines = []
i = 0
replacements = 0
while i < len(lines):
    if lines[i].strip() == '// Find touch inteceptor view':
        # find third comment marker after start
        comment_count = 0
        j = i
        while j < len(lines) and comment_count < 3:
            if lines[j].strip().startswith('//'):
                comment_count += 1
                if comment_count == 3:
                    break
            j += 1
        if comment_count < 3 or j >= len(lines):
            new_lines.append(lines[i]); i += 1; continue
        # replace block with helper-style block
        new_lines.append('  UIView* touchInteceptorView = GetFlutterTouchInterceptingView(gMockPlatformView);\n')
        new_lines.append('  XCTAssertNotNil(touchInteceptorView);\n')
        new_lines.append('  UIGestureRecognizer* forwardGectureRecognizer = GetForwardingGestureRecognizer(touchInteceptorView);\n')
        new_lines.append('  XCTAssertNotNil(forwardGectureRecognizer);\n')
        replacements += 1
        i = j
    else:
        new_lines.append(lines[i]); i += 1
path.write_text(''.join(new_lines), encoding='utf-8')
print('replacements', replacements)
if replacements == 0:
    print('No replacements made. 1st lines near olds:')
    for idx in range(2800, 2920):
        if idx < len(lines):
            if '// Find touch inteceptor view' in lines[idx]:
                print('found at', idx, lines[idx])

print('helper_exists', 'GetFlutterTouchInterceptingView' in ''.join(new_lines), 'forward_exists', 'GetForwardingGestureRecognizer' in ''.join(new_lines))

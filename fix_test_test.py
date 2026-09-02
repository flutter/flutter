import re

with open('packages/flutter_tools/test/commands.shard/hermetic/test_test.dart', 'r') as f:
    text = f.read()

# Fix 612 and 632
text = re.sub(r'final testCommand = TestCommand\(testWrapper: fakePackageTest\);', r'final testCommand = TestCommand(toolContext: toolContext, testWrapper: fakePackageTest);', text)

# Fix 1637, 1654, 1824 which were wrongly substituted before
text = text.replace('TestCommand(toolContext: toolContext ?? _FallbackToolContext(), testRunner: testRunner)', 'TestCommand(toolContext: toolContext, testRunner: testRunner)')

with open('packages/flutter_tools/test/commands.shard/hermetic/test_test.dart', 'w') as f:
    f.write(text)

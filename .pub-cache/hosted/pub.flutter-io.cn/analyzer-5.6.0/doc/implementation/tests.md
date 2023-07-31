# Testing the analyzer

## Test mechanics

The analyzer uses the `test_reflective_loader` package for most of its tests.
The `test_reflective_loader` package uses the `test` package to actually run the
tests, but it provides a JUnit style mechanism for writing the tests.

### Directory layout

The tests, as expected, are in the top-level `test` directory. The structure of
the directories within the `test` directory should match the structure of the
`lib` directory whenever possible. The tests are in files whose name ends with
`_test.dart`. This convention is used by the test runner on the bots to identify
the files to be run, so a failure to follow this convention will cause the tests
to not be run on the bots.

For convenience, every directory in the `test` directory (including the `test`
directory) contains a file named `test_all.dart`. That file isn't run on the
bots, but can be run manually in order to run all the tests in the containing
directory and all subdirectories.

### Test file content

Within a test file, the tests are defined in one or more classes. By convention,
the class name should end with `Test`. The class must be annotated with
`@reflectiveTest`.

In order for the file to be executable, it must define a `main` method that
looks something like the following, with one invocation of
`defineReflectiveTests` for every reflective test class in the file:

```dart
void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitImplTest);
    // ...
  });
}

@reflectiveTest
class CompilationUnitImplTest {
  // ...
}
```

When the tests are run the test loader will reflect on the specified class
(`CompilationUnitImplTest` in the example above) to find all the zero parameter
instance methods whose name starts with 'test_'. These methods should have a
return type of either `void` or `Future<void>`.

There are a couple of useful annotations defined for test methods.

- You can annotate a test with `@FailingTest()` to indicate that it is expected
  to fail when run. This allows us to commit tests for bugs before working on a
  fix for those bugs. The constructor has some optional parameters that allow
  you to specify the reason for the failure and an issue URL.

- You can annotate a test with `@SkippedTest()` if the test should not be run.
  The constructor has the same optional parameters for specifying the reason and
  an issue URL.

- During development, you can mark one or more tests with `@soloTest` to cause
  those tests to be the only tests that are run.

### Test names

Defining tests as methods on a class rather than as invocations of the `test`
and `group` functions has the advantage that we can define common test utilities
and share them across a large number of tests. To do that without classes would
be much harder.

But this style of test also has the disadvantage that we can't organize the
tests into groups. In order to overcome this disadvantage we have adopted an
uncommon naming convention for the test methods that combines the camel case and
snake case conventions.

Let's start with an example. Assume that we have a class named `ToSourceVisitor`
that is a visitor with a separate method for every class of AST node, and that
we want to test every method. Using `group` and `test`, we'd probably create a
group for the class, then a subgroup for each visit method. For nodes with
optional children, such as a list literal (where the `const` modifier and type
arguments are both optional) you might have a group for literals with or without
the type arguments, and then tests both with and without the modifier. In other
words, you might end up with a structure like this:

```dart
void main() {
  group('ToSourceVisitor', () {
    group('visitListLiteral', () {
      group('with type arguments', () {
        test('with const', () { /* ... */ });
        test('without const', () { /* ... */ });
      });
      group('without type arguments', () {
        test('with const', () { /* ... */ });
        test('without const', () { /* ... */ });
      });
    });
  });
}
```

In out tests, the top-level group is replaced by the class, which would be
named `ToSourceVisitorTest`. The methods would all start with `test`, and each
group's name would be converted to a camelCase identifier with groups being
separated with an underscore. So the equivalent to the code above would be:

```dart
class ToSourceVisitorTest {
  void test_visitListLiteral_withTypeArguments_withConst() { /* ... */ }

  void test_visitListLiteral_withTypeArguments_withoutConst() { /* ... */ }

  void test_visitListLiteral_withoutTypeArguments_withConst() { /* ... */ }

  void test_visitListLiteral_withoutTypeArguments_withoutConst() { /* ... */ }
}
```

### Test cases

Most of our tests take a small piece of Dart code and test the behavior of some
piece of functionality. In most cases the Dart code is required to be a whole
compilation unit, though there are a few tests where only a snippet of code is
required. We have a couple of conventions that, while not strictly enforced, are
generally followed.

Test code generally appears in a multi-line string, even when it would fit on a
single line, with the text fully left justified, and with the closing quotes on
a separate line. For example:

```dart
  Future<void> test_final_noInitializer() async {
    await assertNoErrorsInCode('''
abstract class C {
  abstract final int x;
}
''');
  }
```

Test code should be kept as short as possible. Use short names and don't
include code that isn't required in order to test what's being tested.

Test code should generally follow best practices unless the deviation from best
practices is a necessary part of what's being tested.

Don't use a name with a special meaning, like `main`, unless it's important that
you do so for the test.

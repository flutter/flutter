# Unit testing Java code

All Java code in the engine should now be able to be tested with Robolectric 3.8
and JUnit 4. The test suite has been added after the bulk of the Java code was
first written, so most of these classes do not have existing tests. Ideally code
after this point should be tested, either with unit tests here or with
integration tests in other repos.

## Adding a new test

1. Create a file under `test/` matching the path and name of the class under
   test. For example,
   `shell/platform/android/io/flutter/util/Preconditions.java` ->
   `shell/platform/android/**test**/io/flutter/util/Preconditions**Test**.java`.
2. Add your file to the `sources` of the `robolectric_tests` build target in
   `/shell/platform/android/BUILD.gn`. This compiles the test class into the
   test jar.
3. Add your class to the `@SuiteClasses` annotation in `FlutterTestSuite.java`.
   This makes sure the test is actually executed at run time.
4. Write your test.
5. Build and run with `testing/run_tests.py [--type=java] [--java-filter=<test_class_name>]`.

## Q&A

### My new test won't run. There's a "ClassNotFoundException".

See [Updating Embedding Dependencies](../embedding_bundle).

### My new test won't compile. It can't find one of my imports.

See [Updating Embedding Dependencies](../embedding_bundle).

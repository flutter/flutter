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

### Why are we using Robolectric 3.8 when Robolectric 4+ is current?

Robolectric 4+ uses the AndroidX libraries, and the engine sources use the
deprecated android.support ones. See
[flutter/flutter#23586](https://github.com/flutter/flutter/issues/23586). If
this is an issue we could use Jetifier on `flutter.jar` first and _then_ run
the tests, but it would add an extra point of failure.

### My new test won't run. There's a "ClassNotFoundException".

Your test is probably using a dependency that we haven't needed yet. You
probably need to find the dependency you need, add it to the
`flutter/android/robolectric_bundle` CIPD package, and then re-run `gclient
sync`. See ["Updating a CIPD dependency"](#Updating-a-CIPD-dependency) below.

### My new test won't compile. It can't find one of my imports.

You could be using a brand new dependency. If so, you'll need to add it to the
CIPD package for the robolectric tests. See ["Updating a CIPD
dependency"](#Updating-a-CIPD-dependency) below.

Then you'll also need to add the jar to the `robolectric_tests` build target.
Add `//third_party/robolectric/lib/<dependency.jar>` to
`robolectric_tests._jar_dependencies` in `/shell/platform/android/BUILD.gn`.

There's also a chance that you're using a dependency that we're relying on at
runtime, but not compile time. If so you'll just need to update
`_jar_dependencies` in `BUILD.gn`.

### Updating a CIPD dependency

See the Chromium instructions on ["Updating a CIPD
dependency"](https://chromium.googlesource.com/chromium/src/+/master/docs/cipd.md#Updating-a-CIPD-dependency)
for how to upload a package update to CIPD. Download and extract the latest
package from CIPD and then copy
[shell/platform/android/test/cipd.yaml](cipd.yaml) into the extracted directory
to use as the base for the pre-existing package. Add new dependencies to `lib/`.

Once you've uploaded the new version, also make sure to tag it with the updated
timestamp and robolectric version (most likely still 3.8, unless you've migrated
all the packages to 4+).

    $ cipd set-tag flutter/android/robolectric --version=<new_version_hash> -tag=last_updated:<timestamp>

Example of a last-updated timestamp: 2019-07-29T15:27:42-0700

You can generate the same date format with `date +%Y-%m-%dT%T%z`.

    $ cipd set-tag flutter/android/robolectric --version=<new_version_hash> -tag=robolectric_version:<robolectric_version>

You can run `cipd describe flutter/android/robolectric_bundle
--version=<new_version_hash>` to verify. You should see:

```
Package:       flutter/android/robolectric_bundle
Instance ID:   <new_version_hash>
...
Tags:
 last_updated:<timestamp>
 robolectric_version:<robolectric_version>
```

Then update the `DEPS` file (located at /src/flutter/DEPS) to use the new version by pointing to
your new `last_updated_at` tag.

```
  'src/third_party/robolectric': {
     'packages': [
       {
        'package': 'flutter/android/robolectric_bundle',
        'version': 'last_updated:<timestamp>'
       }
     ],
     'condition': 'download_android_deps',
     'dep_type': 'cipd',
   },
```

You can now re-run `gclient sync` to fetch the latest package version.

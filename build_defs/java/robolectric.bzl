# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The Android embedding's Java tests, compiled by javac and run under Robolectric on the engine's JDK.

GN has no counterpart: `testing/run_tests.py --type java` runs Gradle in
shell/platform/android/test_runner (AGP, the test dependencies from Maven at
run time) over the build's flutter.jar. Here the same tests are Bazel's
(D12, option b): `java_classes` compiles sources with `@openjdk`'s javac
against `android.jar`, the embedding's jar and the pinned Maven jars
(@maven_android_tests; maven.bzl) into one jar, and `robolectric_test` runs
one test class with `@openjdk`'s java -- JUnit's console runner,
Robolectric offline over the pinned android-all jar, Mockito's agent, the
`--add-opens` set Robolectric wants on JDK 17+, and a classpath directory
holding `robolectric.properties` and the `com/android/tools/test_config.properties`
AGP would write (the merged manifest, the resource APK). One target per
test class, as Gradle forks one JVM per class.

Nothing of rules_java is used: the engine's JDK is the one CI's Gradle
runs with, and the root module's graph stays as it is (maven.bzl).
"""

# The flags test_runner/build.gradle gives the test JVM: Robolectric's
# recommendation for JDK 17 and later, and the heap Gradle allows.
JVM_FLAGS = [
    "-Xmx8g",
    "--add-opens=java.base/java.lang=ALL-UNNAMED",
    "--add-opens=java.base/java.util=ALL-UNNAMED",
    "--add-opens=java.base/java.io=ALL-UNNAMED",
    "--add-opens=java.base/java.net=ALL-UNNAMED",
    "--add-opens=java.base/java.security=ALL-UNNAMED",
    "--add-opens=java.base/java.text=ALL-UNNAMED",
    "--add-opens=java.base/jdk.internal.access=ALL-UNNAMED",
    "--add-opens=java.desktop/java.awt.font=ALL-UNNAMED",
    "--add-opens=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
]

def _java_classes_impl(ctx):
    jar = ctx.actions.declare_file(ctx.label.name + ".jar")
    classes = ctx.actions.declare_directory(ctx.label.name + ".classes")

    # android.jar goes first on the class path rather than as the boot class
    # path, which javac refuses for a release past 8 (the JDK's own java.*
    # stand in, as AGP compiles a Java 17 Android module).
    classpath = ([ctx.file.bootclasspath] if ctx.file.bootclasspath else []) + ctx.files.classpath
    args = ctx.actions.args()
    args.add_all(["-encoding", "UTF-8", "--release", ctx.attr.java_version])
    args.add("-nowarn")
    args.add("-Xlint:-options")
    args.add_joined("-classpath", classpath, join_with = ":")
    args.add("-d", classes.path)
    args.add_all(ctx.files.srcs)
    ctx.actions.run_shell(
        outputs = [classes, jar],
        inputs = ctx.files.srcs + classpath,
        tools = [ctx.executable.javac, ctx.executable.jar] + ctx.files._jdk,
        arguments = [args],
        command = '"%s" "$@" && "%s" cf "%s" -C "%s" .' % (
            ctx.executable.javac.path,
            ctx.executable.jar.path,
            jar.path,
            classes.path,
        ),
        mnemonic = "Javac",
        progress_message = "Compiling %{label}",
        env = {"HOME": "/tmp"},
    )
    return [DefaultInfo(files = depset([jar]))]

java_classes = rule(
    implementation = _java_classes_impl,
    doc = "Java sources compiled by the engine's javac into one jar.",
    attrs = {
        "srcs": attr.label_list(allow_files = [".java"], mandatory = True, doc = "The sources."),
        "classpath": attr.label_list(allow_files = [".jar"], doc = "The jars compiled against."),
        "bootclasspath": attr.label(allow_single_file = [".jar"], doc = "android.jar, put first on the class path."),
        "java_version": attr.string(default = "17", doc = "javac's --release."),
        "javac": attr.label(default = "@openjdk//:bin/javac", executable = True, cfg = "exec", allow_single_file = True),
        "jar": attr.label(default = "@openjdk//:bin/jar", executable = True, cfg = "exec", allow_single_file = True),
        "_jdk": attr.label(default = "@openjdk//:runtime"),
    },
)

AndroidTestApkInfo = provider(
    doc = "What AGP's unit tests give Robolectric: the merged manifest, the resource APK and the R classes.",
    fields = {
        "manifest": "The merged AndroidManifest.xml (File).",
        "apk": "The resource APK (File): aapt2's link of the manifest and the libraries' resources.",
        "r_jar": "The R classes (File, a jar): the module's and every library's, over the APK's ids.",
    },
)

def _android_test_apk_impl(ctx):
    # The merged manifest: the source file with the module's namespace as its
    # package and the SDK levels AGP adds (the source file has neither;
    # Robolectric reads both).
    manifest = ctx.actions.declare_file(ctx.label.name + "/AndroidManifest.xml")
    args = ctx.actions.args()
    args.add(ctx.file.manifest)
    args.add(manifest)
    args.add(ctx.attr.namespace)
    args.add(ctx.attr.min_sdk)
    args.add(ctx.attr.target_sdk)
    ctx.actions.run_shell(
        outputs = [manifest],
        inputs = [ctx.file.manifest],
        command = 'sed -e "s|<manifest |<manifest package=\\"$3\\" |" ' +
                  '-e "s|<application>|<uses-sdk android:minSdkVersion=\\"$4\\" android:targetSdkVersion=\\"$5\\" />\\n  <application>|" "$1" > "$2"',
        arguments = [args],
        mnemonic = "AndroidTestManifest",
    )

    # The resource APK and the R classes: each library's res/ compiled, all
    # linked with the manifest against android.jar into one table (AGP's
    # includeAndroidResources), R.java for the module's package and every
    # library's (--extra-packages; a library's R holds the whole table, a
    # superset of AGP's per-library R, with the same ids), compiled to a jar.
    apk = ctx.actions.declare_file(ctx.label.name + ".ap_")
    r_jar = ctx.actions.declare_file(ctx.label.name + ".R.jar")
    args = ctx.actions.args()
    args.add(ctx.executable.aapt2)
    args.add(ctx.executable.javac)
    args.add(ctx.executable.jar)
    args.add(manifest)
    args.add(ctx.file.android_jar)
    args.add(ctx.attr.min_sdk)
    args.add(ctx.attr.target_sdk)
    args.add(apk)
    args.add(r_jar)
    args.add(ctx.attr.java_version)
    args.add_all(ctx.files.library_manifests)
    ctx.actions.run_shell(
        outputs = [apk, r_jar],
        inputs = [manifest, ctx.file.android_jar] + ctx.files.library_manifests + ctx.files.library_resources,
        tools = [ctx.executable.aapt2, ctx.executable.javac, ctx.executable.jar] + ctx.files._jdk,
        arguments = [args],
        command = """
set -euo pipefail
aapt2="$1"; javac="$2"; jar="$3"; manifest="$4"; android_jar="$5"; min_sdk="$6"; target_sdk="$7"; apk="$8"; r_jar="$9"; release="${10}"; shift 10
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
compiled=()
packages=""
i=0
for library_manifest in "$@"; do
  directory=$(dirname "$library_manifest")
  package=$(sed -n 's/.*package="\\([^"]*\\)".*/\\1/p' "$library_manifest" | head -1)
  if [ -d "$directory/res" ] && [ -n "$(ls -A "$directory/res")" ]; then
    i=$((i + 1))
    "$aapt2" compile --dir "$directory/res" -o "$work/$i.zip"
    compiled+=("$work/$i.zip")
    case ":$packages:" in *":$package:"*) ;; *) packages="$packages:$package";; esac
  fi
done
mkdir -p "$work/gen" "$work/classes"
"$aapt2" link -o "$apk" --manifest "$manifest" -I "$android_jar" --min-sdk-version "$min_sdk" --target-sdk-version "$target_sdk" \
    --auto-add-overlay --no-version-vectors --java "$work/gen" --extra-packages "${packages#:}" "${compiled[@]}"
find "$work/gen" -name '*.java' > "$work/sources"
"$javac" -nowarn --release "$release" -d "$work/classes" @"$work/sources"
"$jar" cf "$r_jar" -C "$work/classes" .
""",
        mnemonic = "AndroidTestResources",
        progress_message = "Linking %{label}",
        env = {"HOME": "/tmp"},
    )
    return [
        AndroidTestApkInfo(manifest = manifest, apk = apk, r_jar = r_jar),
        DefaultInfo(files = depset([apk, manifest, r_jar])),
    ]

android_test_apk = rule(
    implementation = _android_test_apk_impl,
    doc = "The merged manifest, the resource APK and the R classes of a Robolectric test module, as AGP's unit tests get them.",
    attrs = {
        "manifest": attr.label(allow_single_file = [".xml"], mandatory = True, doc = "The module's AndroidManifest.xml."),
        "namespace": attr.string(mandatory = True, doc = "The module's namespace: the manifest's package."),
        "min_sdk": attr.string(default = "24", doc = "minSdkVersion."),
        "target_sdk": attr.string(default = "37", doc = "targetSdkVersion."),
        "library_manifests": attr.label_list(allow_files = [".xml"], doc = "The libraries' (AARs') manifests, each naming its package."),
        "library_resources": attr.label_list(allow_files = True, doc = "The libraries' res/ directories, beside their manifests."),
        "android_jar": attr.label(allow_single_file = [".jar"], mandatory = True, doc = "The platform's android.jar."),
        "aapt2": attr.label(mandatory = True, executable = True, cfg = "exec", allow_single_file = True, doc = "The build tools' aapt2."),
        "java_version": attr.string(default = "17", doc = "javac's --release for the R classes."),
        "javac": attr.label(default = "@openjdk//:bin/javac", executable = True, cfg = "exec", allow_single_file = True),
        "jar": attr.label(default = "@openjdk//:bin/jar", executable = True, cfg = "exec", allow_single_file = True),
        "_jdk": attr.label(default = "@openjdk//:runtime"),
    },
)

def _robolectric_test_impl(ctx):
    # The classpath directory: robolectric.properties as the test_runner's
    # resources carry it, and AGP's test_config.properties pointing
    # Robolectric at the manifest (and the resource APK when there is one),
    # by paths under the runfiles root.
    # The classpath directory: robolectric.properties as the test_runner's
    # resources carry it, and AGP's test_config.properties pointing
    # Robolectric at the merged manifest and the resource APK, by paths under
    # the runfiles root.
    apk = ctx.attr.apk[AndroidTestApkInfo]
    config = ctx.actions.declare_directory(ctx.label.name + ".config")
    test_config = [
        "android_merged_manifest=%s" % apk.manifest.short_path,
        "android_resource_apk=%s" % apk.apk.short_path,
        "android_custom_package=%s" % ctx.attr.namespace,
    ]
    args = ctx.actions.args()
    args.add(config.path)
    args.add(ctx.file.robolectric_properties)
    args.add("\n".join(test_config) + "\n")
    ctx.actions.run_shell(
        outputs = [config],
        inputs = [ctx.file.robolectric_properties],
        command = 'mkdir -p "$1/com/android/tools" && cp "$2" "$1/robolectric.properties" && printf "%s" "$3" > "$1/com/android/tools/test_config.properties"',
        arguments = [args],
        mnemonic = "RobolectricConfig",
    )

    android_all = ctx.files.android_all
    if not android_all:
        fail("%s: android_all is empty" % ctx.label)
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    classpath = [ctx.file.classes, apk.r_jar] + ctx.files.runtime_classpath
    ctx.actions.write(launcher, """#!/bin/bash
# {label}: {test_class} under Robolectric.
set -euo pipefail
root="$PWD"
export HOME="${{TEST_TMPDIR:-$(mktemp -d)}}/home"
mkdir -p "$HOME"
# The class by its simple name among the jar's: a test file's package need
# not match its directory (KeyboardChannelTest.java declares
# io.flutter.embedding.android under engine/systemchannels/), and Gradle finds
# the class, not the file.
classes=$("$root/{jar_tool}" tf "$root/{classes}" | sed -n 's|/|.|g; s|^\\(.*\\.{simple_name}\\)\\.class$|\\1|p')
if [ "$(printf '%s\\n' "$classes" | grep -c .)" != 1 ]; then
  echo "{label}: expected one class named {simple_name} in {classes}, found: $classes" >&2
  exit 1
fi
# test_config.properties names its files by paths under the runfiles root.
cd "$root"
exec "$root/{java}" {jvm_flags} \\
    -javaagent:"$root/{agent}" \\
    -Drobolectric.offline=true \\
    -Drobolectric.dependency.dir="$root/{android_all_dir}" \\
    -Drobolectric.logging.enabled=true \\
    -cp "$root/{config}:{classpath}" \\
    org.junit.runner.JUnitCore "$classes" "$@"
""".format(
        label = ctx.label,
        test_class = ctx.attr.test_class,
        simple_name = ctx.attr.test_class.rsplit(".", 1)[-1],
        jar_tool = ctx.executable.jar.short_path,
        classes = ctx.file.classes.short_path,
        java = ctx.executable.java.short_path,
        jvm_flags = " ".join(ctx.attr.jvm_flags),
        agent = ctx.file.javaagent.short_path,
        android_all_dir = android_all[0].short_path[:-len(android_all[0].basename) - 1],
        config = config.short_path,
        classpath = ":".join(["$root/" + f.short_path for f in classpath]),
    ), is_executable = True)
    runfiles = ctx.runfiles(
        files = [config, ctx.file.javaagent, ctx.executable.java, ctx.executable.jar, apk.manifest, apk.apk] + android_all + classpath + ctx.files._jdk + ctx.files.data,
    )
    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

robolectric_test = rule(
    implementation = _robolectric_test_impl,
    test = True,
    doc = "One test class run by JUnit under Robolectric on the engine's JDK, offline over the pinned android-all jar.",
    attrs = {
        "test_class": attr.string(
            mandatory = True,
            doc = "The test class, as its file's path spells it; the run finds the class of that simple name in the jar " +
                  "(a file's package need not match its directory).",
        ),
        "classes": attr.label(allow_single_file = [".jar"], mandatory = True, doc = "The tests' jar (java_classes)."),
        "runtime_classpath": attr.label_list(allow_files = [".jar"], doc = "The jars on the class path at run time."),
        "android_all": attr.label(
            allow_files = [".jar"],
            mandatory = True,
            doc = "Robolectric's android-all-instrumented jars (@maven_android_tests//:android_all), all in one directory, " +
                  "which is robolectric.dependency.dir: one per SDK a test may run on.",
        ),
        "javaagent": attr.label(allow_single_file = [".jar"], mandatory = True, doc = "Mockito's jar, as the -javaagent."),
        "robolectric_properties": attr.label(allow_single_file = True, mandatory = True, doc = "robolectric.properties (sdk=, shadows=)."),
        "apk": attr.label(providers = [AndroidTestApkInfo], mandatory = True, doc = "The merged manifest and resource APK (android_test_apk)."),
        "namespace": attr.string(
            default = "io.flutter.app.test",
            doc = "The test module's namespace (test_runner/build.gradle's): the R class's package.",
        ),
        "data": attr.label_list(allow_files = True, doc = "Other files the tests read."),
        "jvm_flags": attr.string_list(default = JVM_FLAGS, doc = "The JVM's flags."),
        "java": attr.label(default = "@openjdk//:bin/java", executable = True, cfg = "target", allow_single_file = True),
        "jar": attr.label(default = "@openjdk//:bin/jar", executable = True, cfg = "target", allow_single_file = True),
        "_jdk": attr.label(default = "@openjdk//:runtime"),
    },
)

def robolectric_tests(name, tests, classes, prefix = "test/", tags = [], size = "large", memory_mb = 12288, **kwargs):
    """One robolectric_test per test file, and a test_suite over them.

    Args:
      name: the suite's name; each test is `<name>/<class>`.
      tests: the test files (`test/**/*Test.java`), whose paths under `prefix` are their classes.
      classes: the java_classes jar holding them.
      prefix: the source root the class names start after.
      tags: each test's tags, and the suite's.
      size: each test's size.
      memory_mb: what one test's JVM may take (an 8 GB heap, and a sandbox per SDK a class runs on),
        told to Bazel's scheduler as `resources:memory:` so that it runs as many at once as the
        machine holds (four at once on a 94 GB host left it swapping).
      **kwargs: robolectric_test's other attributes, the same for every class.
    """
    names = []
    for test in tests:
        if not test.startswith(prefix) or not test.endswith(".java"):
            fail("%s: %s is not a Java file under %s" % (name, test, prefix))
        test_class = test[len(prefix):-len(".java")].replace("/", ".")
        target = "%s/%s" % (name, test_class)
        robolectric_test(
            name = target,
            test_class = test_class,
            classes = classes,
            size = size,
            tags = tags + ["resources:memory:%d" % memory_mb],
            **kwargs
        )
        names.append(":" + target)
    native.test_suite(
        name = name,
        tests = names,
        tags = tags,
    )

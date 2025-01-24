// This script is used to warm the Gradle cache by downloading the Flutter dependencies
// used during the build. This script is invoked when `flutter precache` is run.
//
// Command:
//  gradle -b <flutter-sdk>packages/flutter_tools/gradle/resolve_dependencies.gradle.kts
//      resolveDependencies
//
// This way, Gradle can run with the `--offline` flag later on to eliminate any
// network request during the build process.
//
// This includes:
//   1. The embedding
//   2. libflutter.so

import java.nio.file.Paths

val storageUrl: String = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"

val flutterRoot: File = projectDir.parentFile.parentFile.parentFile

check(flutterRoot.isDirectory())

var engineRealm: String =
    Paths.get(flutterRoot.absolutePath, "bin", "internal", "engine.realm").toFile().readText().trim()
if (engineRealm.isNotEmpty()) {
    engineRealm += "/"
}

repositories {
    google()
    mavenCentral()
    maven(url = "$storageUrl/${engineRealm}download.flutter.io")
}

val engineVersion: String =
    Paths.get(flutterRoot.absolutePath, "bin", "internal", "engine.version").toFile().readText().trim()

val flutterRelease by configurations.creating {
    extendsFrom(configurations.getByName("releaseImplementation"))
}

val flutterDebug by configurations.creating {
    extendsFrom(configurations.getByName("debugImplementation"))
}

val flutterProfile by configurations.creating {
    extendsFrom(configurations.getByName("debugImplementation"))
}

dependencies {
    flutterRelease("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
    flutterRelease("io.flutter:armeabi_v7a_release:1.0.0-$engineVersion")
    flutterRelease("io.flutter:arm64_v8a_release:1.0.0-$engineVersion")

    flutterProfile("io.flutter:flutter_embedding_profile:1.0.0-$engineVersion")
    flutterProfile("io.flutter:armeabi_v7a_profile:1.0.0-$engineVersion")
    flutterProfile("io.flutter:arm64_v8a_profile:1.0.0-$engineVersion")

    flutterDebug("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
    flutterDebug("io.flutter:armeabi_v7a_debug:1.0.0-$engineVersion")
    flutterDebug("io.flutter:arm64_v8a_debug:1.0.0-$engineVersion")
    flutterDebug("io.flutter:x86_debug:1.0.0-$engineVersion")
    flutterDebug("io.flutter:x86_64_debug:1.0.0-$engineVersion")
}

tasks.register("resolveDependencies") {
    configurations.forEach { configuration ->
        if (configuration.name.startsWith("flutter")) {
            configuration.resolve()
        }
    }
}

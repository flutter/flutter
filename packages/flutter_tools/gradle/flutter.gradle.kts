// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file exists solely for compatibility with projects that have
// not migrated to the declarative apply of the Flutter Gradle Plugin.


val pathToThisDirectory = buildscript.sourceFile?.parentFile
apply(from = "$pathToThisDirectory/src/main/groovy/flutter.groovy")

tasks.matching { it.name == "preBuild" }.configureEach {
    doFirst {
        println("uh uh")
    }
}

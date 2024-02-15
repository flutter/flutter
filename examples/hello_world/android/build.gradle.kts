// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Contents of this file should be generated automatically by
// dev/tools/bin/generate_gradle_lockfiles.dart, but currently are not.
// See #141540.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
    dependencyLocking {
        ignoredDependencies.add("io.flutter:*")
        lockFile = file("${rootProject.projectDir}/project-${project.name}.lockfile")
        if (!project.hasProperty("local-engine-repo")) {
            lockAllConfigurations()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}

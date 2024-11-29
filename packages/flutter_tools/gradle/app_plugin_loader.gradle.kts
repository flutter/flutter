// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file exists solely for the compatibility with projects that have
// not migrated to the declarative apply of the Flutter App Plugin Loader Gradle Plugin.

logger.error("You are applying Flutter"s app_plugin_loader Gradle plugin \
imperatively using the apply script method, which is deprecated and will be \
removed in a future release. Migrate to applying Gradle plugins with the \
declarative plugins block: https://flutter.dev/to/flutter-gradle-plugin-apply\n\
")

val pathToThisDirectory = buildscript.sourceFile.parentFile
apply(from = "$pathToThisDirectory/src/main/groovy/app_plugin_loader.groovy")

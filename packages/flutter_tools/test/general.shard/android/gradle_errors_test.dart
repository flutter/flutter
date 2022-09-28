// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  late FileSystem fileSystem;
  late FakeProcessManager processManager;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
  });

  group('gradleErrors', () {
    testWithoutContext('list of errors', () {
      // If you added a new Gradle error, please update this test.
      expect(gradleErrors,
        equals(<GradleHandledError>[
          licenseNotAcceptedHandler,
          networkErrorHandler,
          permissionDeniedErrorHandler,
          flavorUndefinedHandler,
          r8FailureHandler,
          minSdkVersionHandler,
          transformInputIssueHandler,
          lockFileDepMissingHandler,
          multidexErrorHandler,
          incompatibleKotlinVersionHandler,
          minCompileSdkVersionHandler,
          jvm11RequiredHandler,
          outdatedGradleHandler,
          sslExceptionHandler,
          zipExceptionHandler,
        ])
      );
    });
  });

  group('network errors', () {
    testUsingContext('retries if gradle fails while downloading', () async {
      const String errorMessage = r'''
Exception in thread "main" java.io.FileNotFoundException: https://downloads.gradle.org/distributions/gradle-4.1.1-all.zip
at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1872)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1474)
at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:254)
at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install$1.call(Install.java:61)
at org.gradle.wrapper.Install$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if gradle fails downloading with proxy error', () async {
      const String errorMessage = r'''
Exception in thread "main" java.io.IOException: Unable to tunnel through proxy. Proxy returns "HTTP/1.1 400 Bad Request"
at sun.net.www.protocol.http.HttpURLConnection.doTunneling(HttpURLConnection.java:2124)
at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:183)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1546)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1474)
at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:254)
at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install$1.call(Install.java:61)
at org.gradle.wrapper.Install$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if gradle times out waiting for exclusive access to zip', () async {
      const String errorMessage = '''
Exception in thread "main" java.lang.RuntimeException: Timeout of 120000 reached waiting for exclusive access to file: /User/documents/gradle-5.6.2-all.zip
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:61)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if remote host closes connection', () async {
      const String errorMessage = r'''
Downloading https://services.gradle.org/distributions/gradle-5.6.2-all.zip
Exception in thread "main" javax.net.ssl.SSLHandshakeException: Remote host closed connection during handshake
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:994)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at sun.net.www.protocol.https.HttpsClient.afterConnect(HttpsClient.java:559)
	at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:185)
	at sun.net.www.protocol.http.HttpURLConnection.followRedirect0(HttpURLConnection.java:2729)
	at sun.net.www.protocol.http.HttpURLConnection.followRedirect(HttpURLConnection.java:2641)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1824)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1492)
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:263)
	at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
	at org.gradle.wrapper.Download.download(Download.java:44)
	at org.gradle.wrapper.Install$1.call(Install.java:61)
	at org.gradle.wrapper.Install$1.call(Install.java:48)
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if file opening fails', () async {
      const String errorMessage = r'''
Downloading https://services.gradle.org/distributions/gradle-3.5.0-all.zip
Exception in thread "main" java.io.FileNotFoundException: https://downloads.gradle-dn.com/distributions/gradle-3.5.0-all.zip
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1890)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1492)
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:263)
	at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
	at org.gradle.wrapper.Download.download(Download.java:44)
	at org.gradle.wrapper.Install$1.call(Install.java:61)
	at org.gradle.wrapper.Install$1.call(Install.java:48)
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if the connection is reset', () async {
      const String errorMessage = r'''
Downloading https://services.gradle.org/distributions/gradle-5.6.2-all.zip
Exception in thread "main" java.net.SocketException: Connection reset
	at java.net.SocketInputStream.read(SocketInputStream.java:210)
	at java.net.SocketInputStream.read(SocketInputStream.java:141)
	at sun.security.ssl.InputRecord.readFully(InputRecord.java:465)
	at sun.security.ssl.InputRecord.readV3Record(InputRecord.java:593)
	at sun.security.ssl.InputRecord.read(InputRecord.java:532)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:975)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at sun.net.www.protocol.https.HttpsClient.afterConnect(HttpsClient.java:559)
	at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:185)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1564)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1492)
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:263)
	at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
	at org.gradle.wrapper.Download.download(Download.java:44)
	at org.gradle.wrapper.Install$1.call(Install.java:61)
	at org.gradle.wrapper.Install$1.call(Install.java:48)
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if Gradle could not get a resource', () async {
      const String errorMessage = '''
A problem occurred configuring root project 'android'.
> Could not resolve all artifacts for configuration ':classpath'.
   > Could not resolve net.sf.proguard:proguard-gradle:6.0.3.
     Required by:
         project : > com.android.tools.build:gradle:3.3.0
      > Could not resolve net.sf.proguard:proguard-gradle:6.0.3.
         > Could not parse POM https://jcenter.bintray.com/net/sf/proguard/proguard-gradle/6.0.3/proguard-gradle-6.0.3.pom
            > Could not resolve net.sf.proguard:proguard-parent:6.0.3.
               > Could not resolve net.sf.proguard:proguard-parent:6.0.3.
                  > Could not get resource 'https://jcenter.bintray.com/net/sf/proguard/proguard-parent/6.0.3/proguard-parent-6.0.3.pom'.
                     > Could not GET 'https://jcenter.bintray.com/net/sf/proguard/proguard-parent/6.0.3/proguard-parent-6.0.3.pom'. Received status code 504 from server: Gateway Time-out''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('retries if Gradle could not get a resource (non-Gateway)', () async {
      const String errorMessage = '''
* Error running Gradle:
Exit code 1 from: /home/travis/build/flutter/flutter sdk/examples/flutter_gallery/android/gradlew app:properties:
Starting a Gradle Daemon (subsequent builds will be faster)
Picked up _JAVA_OPTIONS: -Xmx2048m -Xms512m
FAILURE: Build failed with an exception.
* What went wrong:
A problem occurred configuring root project 'android'.
> Could not resolve all files for configuration ':classpath'.
   > Could not resolve com.android.tools.build:gradle:3.1.2.
     Required by:
         project :
      > Could not resolve com.android.tools.build:gradle:3.1.2.
         > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/3.1.2/gradle-3.1.2.pom'.
            > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/3.1.2/gradle-3.1.2.pom'.
               > Remote host closed connection during handshake''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
        usesAndroidX: true,
      ), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('multidex errors', () {
    testUsingContext('exits if multidex AndroidManifest not detected', () async {
      const String errorMessage = r'''
Caused by: com.android.tools.r8.utils.b: Cannot fit requested classes in a single dex file (# methods: 85091 > 65536)
  at com.android.tools.r8.utils.T0.error(SourceFile:1)
  at com.android.tools.r8.utils.T0.a(SourceFile:2)
  at com.android.tools.r8.dex.P.a(SourceFile:740)
  at com.android.tools.r8.dex.P$h.a(SourceFile:7)
  at com.android.tools.r8.dex.b.a(SourceFile:14)
  at com.android.tools.r8.dex.b.b(SourceFile:25)
  at com.android.tools.r8.D8.d(D8.java:133)
  at com.android.tools.r8.D8.b(D8.java:1)
  at com.android.tools.r8.utils.Y.a(SourceFile:36)
  ... 38 more


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDexDebug'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
   > com.android.builder.dexing.DexArchiveMergerException: Error while merging dex archives:
     The number of method references in a .dex file cannot exceed 64K.
     Learn how to resolve this issue at https://developer.android.com/tools/building/multidex.html''';

      expect(formatTestErrorMessage(errorMessage, multidexErrorHandler), isTrue);
      expect(await multidexErrorHandler.handler(project: FlutterProject.fromDirectory(fileSystem.currentDirectory), multidexEnabled: true, usesAndroidX: true, line: ''), equals(GradleBuildStatus.exit));

      expect(testLogger.statusText,
        contains(
          'Multidex support is required for your android app to build since the number of methods has exceeded 64k.'
        )
      );
      expect(testLogger.statusText,
        contains(
          'See https://docs.flutter.dev/deployment/android#enabling-multidex-support for more information.'
        )
      );
      expect(testLogger.statusText,
        contains(
          'Your `android/app/src/main/AndroidManifest.xml` does not contain'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
    testUsingContext('retries if multidex support enabled', () async {
      const String errorMessage = r'''
Caused by: com.android.tools.r8.utils.b: Cannot fit requested classes in a single dex file (# methods: 85091 > 65536)
  at com.android.tools.r8.utils.T0.error(SourceFile:1)
  at com.android.tools.r8.utils.T0.a(SourceFile:2)
  at com.android.tools.r8.dex.P.a(SourceFile:740)
  at com.android.tools.r8.dex.P$h.a(SourceFile:7)
  at com.android.tools.r8.dex.b.a(SourceFile:14)
  at com.android.tools.r8.dex.b.b(SourceFile:25)
  at com.android.tools.r8.D8.d(D8.java:133)
  at com.android.tools.r8.D8.b(D8.java:1)
  at com.android.tools.r8.utils.Y.a(SourceFile:36)
  ... 38 more


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDexDebug'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
   > com.android.builder.dexing.DexArchiveMergerException: Error while merging dex archives:
     The number of method references in a .dex file cannot exceed 64K.
     Learn how to resolve this issue at https://developer.android.com/tools/building/multidex.html''';

      final File manifest = fileSystem.currentDirectory
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('main')
          .childFile('AndroidManifest.xml');
      manifest.createSync(recursive: true);
      manifest.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
''', flush: true);

      expect(formatTestErrorMessage(errorMessage, multidexErrorHandler), isTrue);
      expect(await multidexErrorHandler.handler(project: FlutterProject.fromDirectory(fileSystem.currentDirectory), multidexEnabled: true, line: '', usesAndroidX: true), equals(GradleBuildStatus.retry));

      expect(testLogger.statusText,
        contains(
          'Multidex support is required for your android app to build since the number of methods has exceeded 64k.'
        )
      );
      expect(testLogger.statusText,
        contains(
          'android/app/src/main/java/io/flutter/app/FlutterMultiDexApplication.java'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      AnsiTerminal: () => _TestPromptTerminal('y'),
    });

    testUsingContext('exits if multidex support skipped', () async {
      const String errorMessage = r'''
Caused by: com.android.tools.r8.utils.b: Cannot fit requested classes in a single dex file (# methods: 85091 > 65536)
  at com.android.tools.r8.utils.T0.error(SourceFile:1)
  at com.android.tools.r8.utils.T0.a(SourceFile:2)
  at com.android.tools.r8.dex.P.a(SourceFile:740)
  at com.android.tools.r8.dex.P$h.a(SourceFile:7)
  at com.android.tools.r8.dex.b.a(SourceFile:14)
  at com.android.tools.r8.dex.b.b(SourceFile:25)
  at com.android.tools.r8.D8.d(D8.java:133)
  at com.android.tools.r8.D8.b(D8.java:1)
  at com.android.tools.r8.utils.Y.a(SourceFile:36)
  ... 38 more


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDexDebug'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
   > com.android.builder.dexing.DexArchiveMergerException: Error while merging dex archives:
     The number of method references in a .dex file cannot exceed 64K.
     Learn how to resolve this issue at https://developer.android.com/tools/building/multidex.html''';

      final File manifest = fileSystem.currentDirectory
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('main')
          .childFile('AndroidManifest.xml');
      manifest.createSync(recursive: true);
      manifest.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
''', flush: true);

      expect(formatTestErrorMessage(errorMessage, multidexErrorHandler), isTrue);
      expect(await multidexErrorHandler.handler(project: FlutterProject.fromDirectory(fileSystem.currentDirectory), multidexEnabled: true, line: '', usesAndroidX: true), equals(GradleBuildStatus.exit));

      expect(testLogger.statusText,
        contains(
          'Multidex support is required for your android app to build since the number of methods has exceeded 64k.'
        )
      );
      expect(testLogger.statusText,
        contains(
          'Flutter tool can add multidex support. The following file will be added by flutter:'
        )
      );
      expect(testLogger.statusText,
        contains(
          'android/app/src/main/java/io/flutter/app/FlutterMultiDexApplication.java'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      AnsiTerminal: () => _TestPromptTerminal('n'),
    });

    testUsingContext('exits if multidex support disabled', () async {
      const String errorMessage = r'''
Caused by: com.android.tools.r8.utils.b: Cannot fit requested classes in a single dex file (# methods: 85091 > 65536)
  at com.android.tools.r8.utils.T0.error(SourceFile:1)
  at com.android.tools.r8.utils.T0.a(SourceFile:2)
  at com.android.tools.r8.dex.P.a(SourceFile:740)
  at com.android.tools.r8.dex.P$h.a(SourceFile:7)
  at com.android.tools.r8.dex.b.a(SourceFile:14)
  at com.android.tools.r8.dex.b.b(SourceFile:25)
  at com.android.tools.r8.D8.d(D8.java:133)
  at com.android.tools.r8.D8.b(D8.java:1)
  at com.android.tools.r8.utils.Y.a(SourceFile:36)
  ... 38 more


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDexDebug'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.Workers$ActionFacade
   > com.android.builder.dexing.DexArchiveMergerException: Error while merging dex archives:
     The number of method references in a .dex file cannot exceed 64K.
     Learn how to resolve this issue at https://developer.android.com/tools/building/multidex.html''';

      expect(formatTestErrorMessage(errorMessage, multidexErrorHandler), isTrue);
      expect(await multidexErrorHandler.handler(project: FlutterProject.fromDirectory(fileSystem.currentDirectory), multidexEnabled: false, line: '', usesAndroidX: true), equals(GradleBuildStatus.exit));

      expect(testLogger.statusText,
        contains(
          'Flutter multidex handling is disabled.'
        )
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('permission errors', () {
    testUsingContext('throws toolExit if gradle is missing execute permissions', () async {
      const String errorMessage = '''
Permission denied
Command: /home/android/gradlew assembleRelease
''';
      expect(formatTestErrorMessage(errorMessage, permissionDeniedErrorHandler), isTrue);
      expect(await permissionDeniedErrorHandler.handler(
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
      ), equals(GradleBuildStatus.exit));

      expect(
        testLogger.statusText,
        contains('Gradle does not have execution permission.'),
      );
      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Gradle does not have execution permission.                                                  │\n'
          '│ You should change the ownership of the project directory to your user, or move the project to a │\n'
          '│ directory with execute permissions.                                                             │\n'
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    });
  });

  group('permission errors', () {
    testUsingContext('pattern', () async {
      const String errorMessage = '''
Permission denied
Command: /home/android/gradlew assembleRelease
''';
      expect(formatTestErrorMessage(errorMessage, permissionDeniedErrorHandler), isTrue);
    });

    testUsingContext('handler', () async {
      expect(await permissionDeniedErrorHandler.handler(
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
        project: FakeFlutterProject(),
      ), equals(GradleBuildStatus.exit));

      expect(
        testLogger.statusText,
        contains('Gradle does not have execution permission.'),
      );
      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Gradle does not have execution permission.                                                  │\n'
          '│ You should change the ownership of the project directory to your user, or move the project to a │\n'
          '│ directory with execute permissions.                                                             │\n'
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    });
  });

  group('license not accepted', () {
    testWithoutContext('pattern', () {
      expect(
        licenseNotAcceptedHandler.test(
          'You have not accepted the license agreements of the following SDK components'
        ),
        isTrue,
      );
    });

    testUsingContext('handler', () async {
      await licenseNotAcceptedHandler.handler(
        line: 'You have not accepted the license agreements of the following SDK components: [foo, bar]',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Unable to download needed Android SDK components, as the following licenses have not been │\n'
          '│ accepted: foo, bar                                                                            │\n'
          '│                                                                                               │\n'
          '│ To resolve this, please run the following command in a Terminal:                              │\n'
          '│ flutter doctor --android-licenses                                                             │\n'
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    });
  });

  group('flavor undefined', () {
    testWithoutContext('pattern', () {
      expect(
        flavorUndefinedHandler.test(
          'Task assembleFooRelease not found in root project.'
        ),
        isTrue,
      );
      expect(
        flavorUndefinedHandler.test(
          'Task assembleBarRelease not found in root project.'
        ),
        isTrue,
      );
      expect(
        flavorUndefinedHandler.test(
          'Task assembleBar not found in root project.'
        ),
        isTrue,
      );
      expect(
        flavorUndefinedHandler.test(
          'Task assembleBar_foo not found in root project.'
        ),
        isTrue,
      );
    });

    testUsingContext('handler - with flavor', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>[
      'gradlew',
        'app:tasks' ,
        '--all',
        '--console=auto',
        ],
        stdout: '''
assembleRelease
assembleFlavor1
assembleFlavor1Release
assembleFlavor_2
assembleFlavor_2Release
assembleDebug
assembleProfile
assembles
assembleFooTest
          ''',
      ));

      await flavorUndefinedHandler.handler(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          'Gradle project does not define a task suitable '
          'for the requested build.'
        )
      );
      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!]  Gradle project does not define a task suitable for the requested build.                    │\n'
          '│                                                                                                 │\n'
          '│ The /android/app/build.gradle file defines product flavors: flavor1, flavor_2. You must specify │\n'
          '│ a --flavor option to select one of them.                                                        │\n'
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });

    testUsingContext('handler - without flavor', () async {
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          'app:tasks' ,
          '--all',
          '--console=auto',
        ],
        stdout: '''
assembleRelease
assembleDebug
assembleProfile
          ''',
      ));

      await flavorUndefinedHandler.handler(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!]  Gradle project does not define a task suitable for the requested build.                  │\n'
          '│                                                                                               │\n'
          '│ The /android/app/build.gradle file does not define any custom product flavors. You cannot use │\n'
          '│ the --flavor option.                                                                          │\n'
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('higher minSdkVersion', () {
    const String stdoutLine = 'uses-sdk:minSdkVersion 16 cannot be smaller than version 19 declared in library [:webview_flutter] /tmp/cirrus-ci-build/all_plugins/build/webview_flutter/intermediates/library_manifest/release/AndroidManifest.xml as the library might be using APIs not available in 16';

    testWithoutContext('pattern', () {
      expect(
        minSdkVersionHandler.test(stdoutLine),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await minSdkVersionHandler.handler(
        line: stdoutLine,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ The plugin webview_flutter requires a higher Android SDK version.                             │\n'
          '│ Fix this issue by adding the following to the file /android/app/build.gradle:                 │\n'
          '│ android {                                                                                     │\n'
          '│   defaultConfig {                                                                             │\n'
          '│     minSdkVersion 19                                                                          │\n'
          '│   }                                                                                           │\n'
          '│ }                                                                                             │\n'
          '│                                                                                               │\n'
          "│ Note that your app won't be available to users running Android SDKs below 19.                 │\n"
          '│ Alternatively, try to find a version of this plugin that supports these lower versions of the │\n'
          '│ Android SDK.                                                                                  │\n'
          '│ For more information, see:                                                                    │\n'
          '│ https://docs.flutter.dev/deployment/android#reviewing-the-build-configuration                 │\n'
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  // https://issuetracker.google.com/issues/141126614
  group('transform input issue', () {
    testWithoutContext('pattern', () {
      expect(
        transformInputIssueHandler.test(
          'https://issuetracker.google.com/issues/158753935'
        ),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await transformInputIssueHandler.handler(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────┐\n'
          '│ This issue appears to be https://github.com/flutter/flutter/issues/58247.     │\n'
          '│ Fix this issue by adding the following to the file /android/app/build.gradle: │\n'
          '│ android {                                                                     │\n'
          '│   lintOptions {                                                               │\n'
          '│     checkReleaseBuilds false                                                  │\n'
          '│   }                                                                           │\n'
          '│ }                                                                             │\n'
          '└───────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Dependency mismatch', () {
    testWithoutContext('pattern', () {
      expect(
        lockFileDepMissingHandler.test('''
* What went wrong:
Execution failed for task ':app:generateDebugFeatureTransitiveDeps'.
> Could not resolve all artifacts for configuration ':app:debugRuntimeClasspath'.
   > Resolved 'androidx.lifecycle:lifecycle-common:2.2.0' which is not part of the dependency lock state
   > Resolved 'androidx.customview:customview:1.0.0' which is not part of the dependency lock state'''
        ),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await lockFileDepMissingHandler.handler(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────┐\n'
          '│ You need to update the lockfile, or disable Gradle dependency locking.                   │\n'
          '│ To regenerate the lockfiles run: `./gradlew :generateLockfiles` in /android/build.gradle │\n'
          '│ To remove dependency locking, remove the `dependencyLocking` from /android/build.gradle  │\n'
          '└──────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Incompatible Kotlin version', () {
    testWithoutContext('pattern', () {
      expect(
        incompatibleKotlinVersionHandler.test('Module was compiled with an incompatible version of Kotlin. The binary version of its metadata is 1.5.1, expected version is 1.1.15.'),
        isTrue,
      );
      expect(
        incompatibleKotlinVersionHandler.test("class 'kotlin.Unit' was compiled with an incompatible version of Kotlin."),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await incompatibleKotlinVersionHandler.handler(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Your project requires a newer version of the Kotlin Gradle plugin.                       │\n'
          '│ Find the latest version on https://kotlinlang.org/docs/gradle.html#plugin-and-versions, then │\n'
          '│ update /android/build.gradle:                                                                │\n'
          "│ ext.kotlin_version = '<latest-version>'                                                      │\n"
          '└──────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Bump Gradle', () {
    const String errorMessage = '''
A problem occurred evaluating project ':app'.
> Failed to apply plugin [id 'kotlin-android']
   > The current Gradle version 4.10.2 is not compatible with the Kotlin Gradle plugin. Please use Gradle 6.1.1 or newer, or the previous version of the Kotlin plugin.
''';

    testWithoutContext('pattern', () {
      expect(
        outdatedGradleHandler.test(errorMessage),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await outdatedGradleHandler.handler(
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Your project needs to upgrade Gradle and the Android Gradle plugin.          │\n'
          '│                                                                                  │\n'
          '│ To fix this issue, replace the following content:                                │\n'
          '│ /android/build.gradle:                                                           │\n'
          "│     - classpath 'com.android.tools.build:gradle:<current-version>'               │\n"
          "│     + classpath 'com.android.tools.build:gradle:7.2.0'                           │\n"
          '│ /android/gradle/wrapper/gradle-wrapper.properties:                               │\n'
          '│     - https://services.gradle.org/distributions/gradle-<current-version>-all.zip │\n'
          '│     + https://services.gradle.org/distributions/gradle-7.5-all.zip               │\n'
          '└──────────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Required compileSdkVersion', () {
    const String errorMessage = '''
Execution failed for task ':app:checkDebugAarMetadata'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.CheckAarMetadataWorkAction
   > One or more issues found when checking AAR metadata values:

     The minCompileSdk (31) specified in a
     dependency's AAR metadata (META-INF/com/android/build/gradle/aar-metadata.properties)
     is greater than this module's compileSdkVersion (android-30).
     Dependency: androidx.window:window-java:1.0.0-beta04.
     AAR metadata file: ~/.gradle/caches/transforms-3/2adc32c5b3f24bed763d33fbfb203338/transformed/jetified-window-java-1.0.0-beta04/META-INF/com/android/build/gradle/aar-metadata.properties.

     The minCompileSdk (31) specified in a
     dependency's AAR metadata (META-INF/com/android/build/gradle/aar-metadata.properties)
     is greater than this module's compileSdkVersion (android-30).
     Dependency: androidx.window:window:1.0.0-beta04.
     AAR metadata file: ~/.gradle/caches/transforms-3/88f7e476ef68cecca729426edff955b5/transformed/jetified-window-1.0.0-beta04/META-INF/com/android/build/gradle/aar-metadata.properties.
''';

    testWithoutContext('pattern', () {
      expect(
        minCompileSdkVersionHandler.test(errorMessage),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await minCompileSdkVersionHandler.handler(
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        usesAndroidX: true,
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Your project requires a higher compileSdkVersion.                         │\n'
          '│ Fix this issue by bumping the compileSdkVersion in /android/app/build.gradle: │\n'
          '│ android {                                                                     │\n'
          '│   compileSdkVersion 31                                                        │\n'
          '│ }                                                                             │\n'
          '└───────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Java 11 requirement', () {
    testWithoutContext('pattern', () {
      expect(
        jvm11RequiredHandler.test('''
* What went wrong:
A problem occurred evaluating project ':flutter'.
> Failed to apply plugin 'com.android.internal.library'.
   > Android Gradle plugin requires Java 11 to run. You are currently using Java 1.8.
     You can try some of the following options:
       - changing the IDE settings.
       - changing the JAVA_HOME environment variable.
       - changing `org.gradle.java.home` in `gradle.properties`.'''
        ),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      await jvm11RequiredHandler.handler(
        project: FakeFlutterProject(),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ─────────────────────────────────────────────────────────────────┐\n'
          '│ [!] You need Java 11 or higher to build your app with this version of Gradle. │\n'
          '│                                                                               │\n'
          '│ To get Java 11, update to the latest version of Android Studio on             │\n'
          '│ https://developer.android.com/studio/install.                                 │\n'
          '│                                                                               │\n'
          '│ To check the Java version used by Flutter, run `flutter doctor -v`.           │\n'
          '└───────────────────────────────────────────────────────────────────────────────┘\n'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('SSLException', () {
    testWithoutContext('pattern', () {
      expect(
        sslExceptionHandler.test(r'''
Exception in thread "main" javax.net.ssl.SSLException: Tag mismatch!
at java.base/sun.security.ssl.Alert.createSSLException(Alert.java:129)
at java.base/sun.security.ssl.TransportContext.fatal(TransportContext.java:321)
at java.base/sun.security.ssl.TransportContext.fatal(TransportContext.java:264)
at java.base/sun.security.ssl.TransportContext.fatal(TransportContext.java:259)
at java.base/sun.security.ssl.SSLTransport.decode(SSLTransport.java:129)
at java.base/sun.security.ssl.SSLSocketImpl.decode(SSLSocketImpl.java:1155)
at java.base/sun.security.ssl.SSLSocketImpl.readApplicationRecord(SSLSocketImpl.java:1125)
at java.base/sun.security.ssl.SSLSocketImpl$AppInputStream.read(SSLSocketImpl.java:823)
at java.base/java.io.BufferedInputStream.read1(BufferedInputStream.java:290)
at java.base/java.io.BufferedInputStream.read(BufferedInputStream.java:351)
at java.base/sun.net.www.MeteredStream.read(MeteredStream.java:134)
at java.base/java.io.FilterInputStream.read(FilterInputStream.java:133)
at java.base/sun.net.www.protocol.http.HttpURLConnection$HttpInputStream.read(HttpURLConnection.java:3444)
at java.base/sun.net.www.protocol.http.HttpURLConnection$HttpInputStream.read(HttpURLConnection.java:3437)
at org.gradle.wrapper.Download.downloadInternal(Download.java:62)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install$1.call(Install.java:61)
at org.gradle.wrapper.Install$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)'''
        ),
        isTrue,
      );

      expect(
        sslExceptionHandler.test(r'''
Caused by: javax.crypto.AEADBadTagException: Tag mismatch!
at java.base/com.sun.crypto.provider.GaloisCounterMode.decryptFinal(GaloisCounterMode.java:580)
at java.base/com.sun.crypto.provider.CipherCore.finalNoPadding(CipherCore.java:1049)
at java.base/com.sun.crypto.provider.CipherCore.doFinal(CipherCore.java:985)
at java.base/com.sun.crypto.provider.AESCipher.engineDoFinal(AESCipher.java:491)
at java.base/javax.crypto.CipherSpi.bufferCrypt(CipherSpi.java:779)
at java.base/javax.crypto.CipherSpi.engineDoFinal(CipherSpi.java:730)
at java.base/javax.crypto.Cipher.doFinal(Cipher.java:2497)
at java.base/sun.security.ssl.SSLCipher$T12GcmReadCipherGenerator$GcmReadCipher.decrypt(SSLCipher.java:1613)
at java.base/sun.security.ssl.SSLSocketInputRecord.decodeInputRecord(SSLSocketInputRecord.java:262)
at java.base/sun.security.ssl.SSLSocketInputRecord.decode(SSLSocketInputRecord.java:190)
at java.base/sun.security.ssl.SSLTransport.decode(SSLTransport.java:108)'''
        ),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      final GradleBuildStatus status = await sslExceptionHandler.handler(
        project: FakeFlutterProject(),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(status, GradleBuildStatus.retry);
      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network.'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('Zip exception', () {
    testWithoutContext('pattern', () {
      expect(
        zipExceptionHandler.test(r'''
Exception in thread "main" java.util.zip.ZipException: error in opening zip file
at java.util.zip.ZipFile.open(Native Method)
at java.util.zip.ZipFile.(ZipFile.java:225)
at java.util.zip.ZipFile.(ZipFile.java:155)
at java.util.zip.ZipFile.(ZipFile.java:169)
at org.gradle.wrapper.Install.unzip(Install.java:214)
at org.gradle.wrapper.Install.access$600(Install.java:27)
at org.gradle.wrapper.Install$1.call(Install.java:74)
at org.gradle.wrapper.Install$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)'''
        ),
        isTrue,
      );
    });

    testUsingContext('suggestion', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        project: FakeFlutterProject(),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), exists);
      expect(
        testLogger.errorText,
        contains(
          '[!] Your .gradle directory under the home directory might be corrupted.\n'
        )
      );
       expect(testLogger.statusText, '');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      BotDetector: () => const FakeBotDetector(false),
    });

    testUsingContext('suggestion if running as bot', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        project: FakeFlutterProject(),
        usesAndroidX: true,
        line: '',
        multidexEnabled: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), isNot(exists));

      expect(
        testLogger.errorText,
        contains(
          '[!] Your .gradle directory under the home directory might be corrupted.\n'
        )
      );
      expect(
        testLogger.statusText,
        contains('Deleting foo/.gradle\n'),
      );
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      BotDetector: () => const FakeBotDetector(true),
    });

    testUsingContext('suggestion if stdin has terminal and user entered y', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        line: '',
        usesAndroidX: true,
        multidexEnabled: true,
        project: FakeFlutterProject(),
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), isNot(exists));
      expect(
        testLogger.errorText,
        contains(
          '[!] Your .gradle directory under the home directory might be corrupted.\n'
        )
      );
      expect(
        testLogger.statusText,
        contains('Deleting foo/.gradle\n'),
      );
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      AnsiTerminal: () => _TestPromptTerminal('y'),
      BotDetector: () => const FakeBotDetector(false),
    });

    testUsingContext('suggestion if stdin has terminal and user entered n', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        line: '',
        usesAndroidX: true,
        multidexEnabled: true,
        project: FakeFlutterProject(),
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), exists);
      expect(
        testLogger.errorText,
        contains(
          '[!] Your .gradle directory under the home directory might be corrupted.\n'
        )
      );
      expect(testLogger.statusText, '');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      AnsiTerminal: () => _TestPromptTerminal('n'),
      BotDetector: () => const FakeBotDetector(false),
    });
  });
}

bool formatTestErrorMessage(String errorMessage, GradleHandledError error) {
  return errorMessage
    .split('\n')
    .any((String line) => error.test(line));
}

Platform fakePlatform(String name) {
  return FakePlatform(
    environment: <String, String>{
      'HOME': '/',
    },
    operatingSystem: name,
  );
}

class FakeGradleUtils extends Fake implements GradleUtils {
  @override
  String getExecutable(FlutterProject project) {
    return 'gradlew';
  }
}

/// Simple terminal that returns the specified string when
/// promptForCharInput is called.
class _TestPromptTerminal extends Fake implements AnsiTerminal {
  _TestPromptTerminal(this.promptResult);

  final String promptResult;

  @override
  bool get stdinHasTerminal => true;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    required Logger logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) {
    return Future<String>.value(promptResult);
  }
}

class FakeFlutterProject extends Fake implements FlutterProject {}

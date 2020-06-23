// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('gradleErrors', () {
    test('list of errors', () {
      // If you added a new Gradle error, please update this test.
      expect(gradleErrors,
        equals(<GradleHandledError>[
          licenseNotAcceptedHandler,
          networkErrorHandler,
          permissionDeniedErrorHandler,
          flavorUndefinedHandler,
          r8FailureHandler,
          androidXFailureHandler,
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
    });

    testUsingContext('retries if gradle times out waiting for exclusive access to zip', () async {
      const String errorMessage = '''
Exception in thread "main" java.lang.RuntimeException: Timeout of 120000 reached waiting for exclusive access to file: /User/documents/gradle-5.6.2-all.zip
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:61)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
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
      expect(await networkErrorHandler.handler(), equals(GradleBuildStatus.retry));

      expect(testLogger.errorText,
        contains(
          'Gradle threw an error while downloading artifacts from the network. '
          'Retrying to download...'
        )
      );
    });
  });

  group('permission errors', () {
    testUsingContext('throws toolExit if gradle is missing execute permissions', () async {
      const String errorMessage = '''
Permission denied
Command: /home/android/gradlew assembleRelease
''';
      expect(formatTestErrorMessage(errorMessage, permissionDeniedErrorHandler), isTrue);
      expect(await permissionDeniedErrorHandler.handler(), equals(GradleBuildStatus.exit));

      expect(
        testLogger.statusText,
        contains('Gradle does not have execution permission.'),
      );
      expect(
        testLogger.statusText,
        contains(
          'You should change the ownership of the project directory to your user, '
          'or move the project to a directory with execute permissions.'
        )
      );
    });
  });

  group('AndroidX', () {
    final Usage mockUsage = MockUsage();

    test('pattern', () {
      expect(androidXFailureHandler.test(
        'AAPT: error: resource android:attr/fontVariationSettings not found.'
      ), isTrue);

      expect(androidXFailureHandler.test(
        'AAPT: error: resource android:attr/ttcIndex not found.'
      ), isTrue);

      expect(androidXFailureHandler.test(
        'error: package android.support.annotation does not exist'
      ), isTrue);

      expect(androidXFailureHandler.test(
        'import android.support.annotation.NonNull;'
      ), isTrue);

      expect(androidXFailureHandler.test(
        'import androidx.annotation.NonNull;'
      ), isTrue);

      expect(androidXFailureHandler.test(
        'Daemon:  AAPT2 aapt2-3.2.1-4818971-linux Daemon #0'
      ), isTrue);
    });

    testUsingContext('handler - no plugins', () async {
      final GradleBuildStatus status = await androidXFailureHandler
        .handler(line: '', project: FlutterProject.current());

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-android-x-failure',
        parameters: <String, String>{
          'cd43': 'app-not-using-plugins',
        },
      )).called(1);

      expect(status, equals(GradleBuildStatus.exit));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => MockProcessManager(),
      Usage: () => mockUsage,
    });

    testUsingContext('handler - plugins and no AndroidX', () async {
      globals.fs.file('.flutter-plugins').createSync(recursive: true);

      final GradleBuildStatus status = await androidXFailureHandler
        .handler(
          line: '',
          project: FlutterProject.current(),
          usesAndroidX: false,
        );

      expect(testLogger.statusText,
        contains(
          'AndroidX incompatibilities may have caused this build to fail. '
          'Please migrate your app to AndroidX. See https://goo.gl/CP92wY .'
        )
      );
      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-android-x-failure',
        parameters: <String, String>{
          'cd43': 'app-not-using-androidx',
        },
      )).called(1);

      expect(status, equals(GradleBuildStatus.exit));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => MockProcessManager(),
      Usage: () => mockUsage,
    });

    testUsingContext('handler - plugins, AndroidX, and AAR', () async {
      globals.fs.file('.flutter-plugins').createSync(recursive: true);

      final GradleBuildStatus status = await androidXFailureHandler.handler(
        line: '',
        project: FlutterProject.current(),
        usesAndroidX: true,
        shouldBuildPluginAsAar: true,
      );

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-android-x-failure',
        parameters: <String, String>{
          'cd43': 'using-jetifier',
        },
      )).called(1);

      expect(status, equals(GradleBuildStatus.exit));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => MockProcessManager(),
      Usage: () => mockUsage,
    });

    testUsingContext('handler - plugins, AndroidX, and no AAR', () async {
      globals.fs.file('.flutter-plugins').createSync(recursive: true);

      final GradleBuildStatus status = await androidXFailureHandler.handler(
        line: '',
        project: FlutterProject.current(),
        usesAndroidX: true,
        shouldBuildPluginAsAar: false,
      );

      expect(testLogger.statusText,
        contains(
          'The built failed likely due to AndroidX incompatibilities in a plugin. '
          'The tool is about to try using Jetfier to solve the incompatibility.'
        )
      );
      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-android-x-failure',
        parameters: <String, String>{
          'cd43': 'not-using-jetifier',
        },
      )).called(1);
      expect(status, equals(GradleBuildStatus.retryWithAarPlugins));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => MockProcessManager(),
      Usage: () => mockUsage,
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
      expect(await permissionDeniedErrorHandler.handler(), equals(GradleBuildStatus.exit));

      expect(
        testLogger.statusText,
        contains('Gradle does not have execution permission.'),
      );
      expect(
        testLogger.statusText,
        contains(
          'You should change the ownership of the project directory to your user, '
          'or move the project to a directory with execute permissions.'
        )
      );
    });
  });

  group('license not accepted', () {
    test('pattern', () {
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
        project: FlutterProject.current(),
      );

      expect(
        testLogger.statusText,
        contains(
          'Unable to download needed Android SDK components, as the '
          'following licenses have not been accepted:\n'
          'foo, bar\n\n'
          'To resolve this, please run the following command in a Terminal:\n'
          'flutter doctor --android-licenses'
        )
      );
    });
  });

  group('flavor undefined', () {
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    test('pattern', () {
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
      when(mockProcessManager.run(
        <String>[
          'gradlew',
          'app:tasks' ,
          '--all',
          '--console=auto',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) async {
        return ProcessResult(
          1,
          0,
          '''
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
          '',
        );
      });

      await flavorUndefinedHandler.handler(
        project: FlutterProject.current(),
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
          'The android/app/build.gradle file defines product '
          'flavors: flavor1, flavor_2 '
          'You must specify a --flavor option to select one of them.'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      ProcessManager: () => mockProcessManager,
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('handler - without flavor', () async {
      when(mockProcessManager.run(
        <String>[
          'gradlew',
          'app:tasks' ,
          '--all',
          '--console=auto',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) async {
        return ProcessResult(
          1,
          0,
          '''
assembleRelease
assembleDebug
assembleProfile
          ''',
          '',
        );
      });

      await flavorUndefinedHandler.handler(
        project: FlutterProject.current(),
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
          'The android/app/build.gradle file does not define any custom product flavors. '
          'You cannot use the --flavor option.'
        )
      );
    }, overrides: <Type, Generator>{
      GradleUtils: () => FakeGradleUtils(),
      Platform: () => fakePlatform('android'),
      ProcessManager: () => mockProcessManager,
      FileSystem: () => MemoryFileSystem.test(),
    });
  });
}

class MockUsage extends Mock implements Usage {}

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

class FakeGradleUtils extends GradleUtils {
  @override
  String getExecutable(FlutterProject project) {
    return 'gradlew';
  }
}

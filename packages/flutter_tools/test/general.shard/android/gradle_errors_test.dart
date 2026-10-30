// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  late FileSystem fileSystem;
  late FakeProcessManager processManager;
  late BufferLogger testLogger;
  late FakeToolContext toolContext;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
    testLogger = BufferLogger.test();
    toolContext = FakeToolContext(
      fs: fileSystem,
      logger: testLogger,
      platform: FakePlatform(),
      processManager: processManager,
    );
  });

  group('gradleErrors', () {
    testWithoutContext('list of errors', () {
      // If you added a new Gradle error, please update this test.
      expect(
        gradleErrors,
        equals(<GradleHandledError>[
          licenseNotAcceptedHandler,
          networkErrorHandler,
          permissionDeniedErrorHandler,
          flavorUndefinedHandler,
          r8DexingBugInAgp73Handler,
          minSdkVersionHandler,
          transformInputIssueHandler,
          javaHeapSpaceHandler,
          lockFileDepMissingHandler,
          minCompileSdkVersionHandler,
          incompatibleJavaAndAgpVersionsHandler,
          outdatedGradleHandler,
          sslExceptionHandler,
          zipExceptionHandler,
          incompatibleJavaAndGradleVersionsHandler,
          remoteTerminatedHandshakeHandler,
          couldNotOpenCacheDirectoryHandler,
          incompatibleCompileSdk35AndAgpVersionHandler,
          usageOfV1EmbeddingReferencesHandler,
          jlinkErrorWithJava21AndSourceCompatibility,
          missingNdkSourcePropertiesFile,
          applyingKotlinAndroidPluginErrorHandler,
          kotlinAndroidPluginWithNewDslErrorHandler,
          legacyVariantApiErrorHandler,
          useNewAgpDslErrorHandler,
          incompatibleKotlinVersionHandler,
        ]),
      );
      expect(
        gradleErrors.indexOf(kotlinAndroidPluginWithNewDslErrorHandler),
        lessThan(gradleErrors.indexOf(legacyVariantApiErrorHandler)),
      );
      expect(
        gradleErrors.indexOf(legacyVariantApiErrorHandler),
        lessThan(gradleErrors.indexOf(useNewAgpDslErrorHandler)),
      );
    });
  });

  group('network errors', () {
    testWithoutContext('retries if gradle fails while downloading', () async {
      const errorMessage = r'''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if remote host terminated ssl handshake', () async {
      const errorMessage = r'''
Exception in thread "main" javax.net.ssl.SSLHandshakeException: Remote host terminated the handshake
	at java.base/sun.security.ssl.SSLSocketImpl.handleEOF(SSLSocketImpl.java:1696)
	at java.base/sun.security.ssl.SSLSocketImpl.decode(SSLSocketImpl.java:1514)
	at java.base/sun.security.ssl.SSLSocketImpl.readHandshakeRecord(SSLSocketImpl.java:1416)
	at java.base/sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:456)
	at java.base/sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:427)
	at java.base/sun.net.www.protocol.https.HttpsClient.afterConnect(HttpsClient.java:572)
	at java.base/sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:197)
	at java.base/sun.net.www.protocol.http.HttpURLConnection.followRedirect0(HttpURLConnection.java:2783)
	at java.base/sun.net.www.protocol.http.HttpURLConnection.followRedirect(HttpURLConnection.java:2695)
	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1854)
	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1520)
	at java.base/sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:250)
	at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
	at org.gradle.wrapper.Download.download(Download.java:44)
	at org.gradle.wrapper.Install$1.call(Install.java:61)
	at org.gradle.wrapper.Install$1.call(Install.java:48)
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)
Caused by: java.io.EOFException: SSL peer shut down incorrectly
	at java.base/sun.security.ssl.SSLSocketInputRecord.read(SSLSocketInputRecord.java:483)
	at java.base/sun.security.ssl.SSLSocketInputRecord.readHeader(SSLSocketInputRecord.java:472)
	at java.base/sun.security.ssl.SSLSocketInputRecord.decode(SSLSocketInputRecord.java:160)
	at java.base/sun.security.ssl.SSLTransport.decode(SSLTransport.java:111)
	at java.base/sun.security.ssl.SSLSocketImpl.decode(SSLSocketImpl.java:1506)''';

      expect(formatTestErrorMessage(errorMessage, remoteTerminatedHandshakeHandler), isTrue);
      expect(
        await remoteTerminatedHandshakeHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if gradle fails downloading with proxy error', () async {
      const errorMessage = r'''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if gradle fails downloading with bad gateway error', () async {
      const errorMessage = r'''
Exception in thread "main" java.io.IOException: Server returned HTTP response code: 502 for URL: https://objects.githubusercontent.com/github-production-release-asset-2e65be/696192900/1e77bbfb-4cde-4376-92ea-fc4ff57b8362?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=FFFF%2F20231220%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231220T160553Z&X-Amz-Expires=300&X-Amz-Signature=ffff&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=696192900&response-content-disposition=attachment%3B%20filename%3Dgradle-8.2.1-all.zip&response-content-type=application%2Foctet-stream
at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1997)
at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1589)
at java.base/sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:224)
at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install$1.call(Install.java:61)
at org.gradle.wrapper.Install$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if gradle times out waiting for exclusive access to zip', () async {
      const errorMessage = '''
Exception in thread "main" java.lang.RuntimeException: Timeout of 120000 reached waiting for exclusive access to file: /User/documents/gradle-5.6.2-all.zip
	at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:61)
	at org.gradle.wrapper.Install.createDist(Install.java:48)
	at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
	at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if remote host closes connection', () async {
      const errorMessage = r'''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if file opening fails', () async {
      const errorMessage = r'''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if the connection is reset', () async {
      const errorMessage = r'''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if Gradle could not get a resource', () async {
      const errorMessage = '''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if Gradle could not get a resource (non-Gateway)', () async {
      const errorMessage = '''
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
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });

    testWithoutContext('retries if connection times out', () async {
      const errorMessage = r'''
Exception in thread "main" java.net.ConnectException: Connection timed out
java.base/sun.nio.ch.Net.connect0(Native Method)
  at java.base/sun.nio.ch.Net.connect(Net.java:579)
  at java.base/sun.nio.ch.Net.connect(Net.java:568)
  at java.base/sun.nio.ch.NioSocketImpl.connect(NioSocketImpl.java:588)
  at java.base/java.net.SocksSocketImpl.connect(SocksSocketImpl.java:327)
  at java.base/java.net.Socket.connect(Socket.java:633)
  at java.base/sun.security.ssl.SSLSocketImpl.connect(SSLSocketImpl.java:299)
  at java.base/sun.security.ssl.BaseSSLSocketImpl.connect(BaseSSLSocketImpl.java:174)
  at java.base/sun.net.NetworkClient.doConnect(NetworkClient.java:183)
  at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:498)
  at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:603)
  at java.base/sun.net.www.protocol.https.HttpsClient.<init>(HttpsClient.java:266)
  at java.base/sun.net.www.protocol.https.HttpsClient.New(HttpsClient.java:380)''';

      expect(formatTestErrorMessage(errorMessage, networkErrorHandler), isTrue);
      expect(
        await networkErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.retry),
      );

      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
    });
  });

  group('permission errors', () {
    testWithoutContext('throws toolExit if gradle is missing execute permissions', () async {
      const errorMessage = '''
Permission denied
Command: /home/android/gradlew assembleRelease
''';
      expect(formatTestErrorMessage(errorMessage, permissionDeniedErrorHandler), isTrue);
      expect(
        await permissionDeniedErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.exit),
      );

      expect(testLogger.statusText, contains('Gradle does not have execution permission.'));
      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Gradle does not have execution permission.                                                  │\n'
          '│ You should change the ownership of the project directory to your user, or move the project to a │\n'
          '│ directory with execute permissions.                                                             │\n'
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });

    testWithoutContext('pattern', () async {
      const errorMessage = '''
Permission denied
Command: /home/android/gradlew assembleRelease
''';
      expect(formatTestErrorMessage(errorMessage, permissionDeniedErrorHandler), isTrue);
    });

    testWithoutContext('handler', () async {
      expect(
        await permissionDeniedErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line: '',
          project: FakeFlutterProject(),
          toolContext: toolContext,
          usesAndroidX: true,
        ),
        equals(GradleBuildStatus.exit),
      );

      expect(testLogger.statusText, contains('Gradle does not have execution permission.'));
      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ───────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Gradle does not have execution permission.                                                  │\n'
          '│ You should change the ownership of the project directory to your user, or move the project to a │\n'
          '│ directory with execute permissions.                                                             │\n'
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('license not accepted', () {
    testWithoutContext('pattern', () {
      expect(
        licenseNotAcceptedHandler.test(
          'You have not accepted the license agreements of the following SDK components',
        ),
        isTrue,
      );
    });

    testWithoutContext('handler', () async {
      await licenseNotAcceptedHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: 'You have not accepted the license agreements of the following SDK components: [foo, bar]',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
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
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('flavor undefined', () {
    testWithoutContext('pattern', () {
      expect(
        flavorUndefinedHandler.test('Task assembleFooRelease not found in root project.'),
        isTrue,
      );
      expect(
        flavorUndefinedHandler.test('Task assembleBarRelease not found in root project.'),
        isTrue,
      );
      expect(flavorUndefinedHandler.test('Task assembleBar not found in root project.'), isTrue);
      expect(
        flavorUndefinedHandler.test('Task assembleBar_foo not found in root project.'),
        isTrue,
      );
    });

    testWithoutContext('handler - with flavor', () async {
      processManager.addCommand(
        const FakeCommand(
          command: <String>['gradlew', 'app:tasks', '--all', '--console=auto'],
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
        ),
      );

      await flavorUndefinedHandler.handler(
        gradleUtils: FakeGradleUtils(),
        java: FakeJava(),
        line: '',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      expect(
        testLogger.statusText,
        contains(
          'Gradle project does not define a task suitable '
          'for the requested build.',
        ),
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
          '└─────────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('handler - without flavor', () async {
      processManager.addCommand(
        const FakeCommand(
          command: <String>['gradlew', 'app:tasks', '--all', '--console=auto'],
          stdout: '''
assembleRelease
assembleDebug
assembleProfile
          ''',
        ),
      );

      await flavorUndefinedHandler.handler(
        gradleUtils: FakeGradleUtils(),
        java: FakeJava(),
        line: '',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
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
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });
  });

  group('higher minSdkVersion', () {
    const stdoutLine =
        'uses-sdk:minSdkVersion 16 cannot be smaller than version 21 declared in library [:webview_flutter] /tmp/cirrus-ci-build/all_plugins/build/webview_flutter/intermediates/library_manifest/release/AndroidManifest.xml as the library might be using APIs not available in 21';

    testWithoutContext('pattern', () {
      expect(minSdkVersionHandler.test(stdoutLine), isTrue);
    });

    testWithoutContext('suggestion', () async {
      await minSdkVersionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: stdoutLine,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
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
          '│     minSdkVersion 21                                                                          │\n'
          '│   }                                                                                           │\n'
          '│ }                                                                                             │\n'
          '│                                                                                               │\n'
          '│ Following this change, your app will not be available to users running Android SDKs below 21. │\n'
          '│ Consider searching for a version of this plugin that supports these lower versions of the     │\n'
          '│ Android SDK instead.                                                                          │\n'
          '│ For more information, see: https://flutter.dev/to/review-gradle-config                        │\n'
          '└───────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  // https://issuetracker.google.com/issues/141126614
  group('transform input issue', () {
    testWithoutContext('pattern', () {
      expect(
        transformInputIssueHandler.test('https://issuetracker.google.com/issues/158753935'),
        isTrue,
      );
    });

    testWithoutContext('suggestion', () async {
      await transformInputIssueHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
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
          '└───────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('java heap space', () {
    testWithoutContext('pattern', () {
      expect(javaHeapSpaceHandler.test('> Java heap space'), isTrue);
      expect(javaHeapSpaceHandler.test('java.lang.OutOfMemoryError: Java heap space'), isTrue);
    });

    testWithoutContext('suggestion', () async {
      final GradleBuildStatus status = await javaHeapSpaceHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '> Java heap space',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      expect(status, GradleBuildStatus.exit);
      expect(testLogger.statusText, contains('Java heap space'));
      expect(
        testLogger.statusText,
        contains(
          'https://docs.gradle.org/current/userguide/config_gradle.html#sec:configuring_jvm_memory',
        ),
      );
    });
  });

  group('Dependency mismatch', () {
    testWithoutContext('pattern', () {
      expect(
        lockFileDepMissingHandler.test(
          '''
* What went wrong:
Execution failed for task ':app:generateDebugFeatureTransitiveDeps'.
> Could not resolve all artifacts for configuration ':app:debugRuntimeClasspath'.
   > Resolved 'androidx.lifecycle:lifecycle-common:2.2.0' which is not part of the dependency lock state
   > Resolved 'androidx.customview:customview:1.0.0' which is not part of the dependency lock state''',
        ),
        isTrue,
      );
    });

    testWithoutContext('suggestion', () async {
      await lockFileDepMissingHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: FakeToolContext(
          fs: fileSystem,
          logger: testLogger,
          platform: fakePlatform('android'),
          processManager: processManager,
        ),
        usesAndroidX: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────┐\n'
          '│ You need to update the lockfile, or disable Gradle dependency locking.                   │\n'
          '│ To regenerate the lockfiles run: `./gradlew :generateLockfiles` in /android/build.gradle │\n'
          '│ To remove dependency locking, remove the `dependencyLocking` from /android/build.gradle  │\n'
          '└──────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  testWithoutContext('generates correct gradle command for Unix-like environment', () async {
    await lockFileDepMissingHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: '',
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      toolContext: FakeToolContext(
        fs: fileSystem,
        logger: testLogger,
        platform: fakePlatform('linux'),
        processManager: processManager,
      ),
      usesAndroidX: true,
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
        '',
      ),
    );
  });

  testWithoutContext('generates correct gradle command for windows environment', () async {
    await lockFileDepMissingHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: '',
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      toolContext: FakeToolContext(
        fs: fileSystem,
        logger: testLogger,
        platform: fakePlatform('windows'),
        processManager: processManager,
      ),
      usesAndroidX: true,
    );
    expect(
      testLogger.statusText,
      contains(
        '\n'
        '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────┐\n'
        '│ You need to update the lockfile, or disable Gradle dependency locking.                       │\n'
        '│ To regenerate the lockfiles run: `.\\gradlew.bat :generateLockfiles` in /android/build.gradle │\n'
        '│ To remove dependency locking, remove the `dependencyLocking` from /android/build.gradle      │\n'
        '└──────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        '',
      ),
    );
  });

  group('Incompatible Kotlin version', () {
    testWithoutContext('pattern', () {
      expect(
        incompatibleKotlinVersionHandler.test(
          'Module was compiled with an incompatible version of Kotlin. The binary version of its metadata is 1.5.1, expected version is 1.1.15.',
        ),
        isTrue,
      );
      expect(
        incompatibleKotlinVersionHandler.test(
          "class 'kotlin.Unit' was compiled with an incompatible version of Kotlin.",
        ),
        isTrue,
      );
    });

    testWithoutContext('suggestion', () async {
      await incompatibleKotlinVersionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Your project requires a newer version of the Kotlin Gradle plugin.                       │\n'
          '│ Find the latest version on https://kotlinlang.org/docs/releases.html#release-details, then   │\n'
          '│ update the                                                                                   │\n'
          '│ version number of the plugin with id "org.jetbrains.kotlin.android" in the plugins block of  │\n'
          '│ /android/settings.gradle.                                                                    │\n'
          '│                                                                                              │\n'
          '│ Alternatively (if your project was created before Flutter 3.19), update                      │\n'
          '│ /android/build.gradle                                                                        │\n'
          "│ ext.kotlin_version = '<latest-version>'                                                      │\n"
          '└──────────────────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('Bump Gradle', () {
    const errorMessage = '''
A problem occurred evaluating project ':app'.
> Failed to apply plugin [id 'kotlin-android']
   > The current Gradle version 4.10.2 is not compatible with the Kotlin Gradle plugin. Please use Gradle 6.1.1 or newer, or the previous version of the Kotlin plugin.
''';

    testWithoutContext('pattern', () {
      expect(outdatedGradleHandler.test(errorMessage), isTrue);
    });

    testWithoutContext('suggestion', () async {
      await outdatedGradleHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
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
          "│     + classpath 'com.android.tools.build:gradle:$templateAndroidGradlePluginVersion'                           │\n"
          '│ /android/gradle/wrapper/gradle-wrapper.properties:                               │\n'
          '│     - https://services.gradle.org/distributions/gradle-<current-version>-all.zip │\n'
          '│     + https://services.gradle.org/distributions/gradle-$templateDefaultGradleVersion-all.zip             │\n'
          '└──────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('Required compileSdkVersion', () {
    const errorMessage = '''
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
      expect(minCompileSdkVersionHandler.test(errorMessage), isTrue);
    });

    testWithoutContext('suggestion', () async {
      await minCompileSdkVersionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      expect(
        testLogger.statusText,
        contains(
          '\n'
          '┌─ Flutter Fix ──────────────────────────────────────────────────────────────────┐\n'
          '│ [!] Your project requires a higher compileSdk version.                         │\n'
          '│ Fix this issue by bumping the compileSdk version in /android/app/build.gradle: │\n'
          '│ android {                                                                      │\n'
          '│   compileSdk 31                                                                │\n'
          '│ }                                                                              │\n'
          '└────────────────────────────────────────────────────────────────────────────────┘\n',
        ),
      );
    });
  });

  group('incompatible java and android gradle plugin versions error', () {
    const errorMessage = '''
* What went wrong:
An exception occurred applying plugin request [id: 'com.android.application']
> Failed to apply plugin 'com.android.internal.application'.
   > Android Gradle plugin requires Java 17 to run. You are currently using Java 11.
      You can try some of the following options:
       - changing the IDE settings.
       - changing the JAVA_HOME environment variable.
       - changing `org.gradle.java.home` in `gradle.properties`.
''';

    testWithoutContext('pattern', () {
      expect(incompatibleJavaAndAgpVersionsHandler.test(errorMessage), isTrue);
    });

    testWithoutContext('suggestion', () async {
      await incompatibleJavaAndAgpVersionsHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      // Ensure the error notes the required Java version, the Java version currently used,
      // the android studio and android sdk installation link, the flutter command to set
      // the Java version Flutter uses, and the flutter doctor command.
      expect(
        testLogger.statusText,
        contains('Android Gradle plugin requires Java 17 to run. You are currently using Java 11.'),
      );
      expect(testLogger.statusText, contains('https://developer.android.com/studio/install'));
      expect(testLogger.statusText, contains('`flutter config --jdk-dir=“</path/to/jdk>“`'));
      expect(testLogger.statusText, contains('`flutter doctor --verbose`'));
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
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)'''),
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
at java.base/sun.security.ssl.SSLTransport.decode(SSLTransport.java:108)'''),
        isTrue,
      );
    });

    testWithoutContext('suggestion', () async {
      final GradleBuildStatus status = await sslExceptionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FakeFlutterProject(),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      expect(status, GradleBuildStatus.retry);
      expect(
        testLogger.errorText,
        contains('Gradle threw an error while downloading artifacts from the network.'),
      );
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
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)'''),
        isTrue,
      );
    });

    testWithoutContext('suggestion', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FakeFlutterProject(),
        toolContext: FakeToolContext(
          botDetector: const FakeBotDetector(false),
          fs: fileSystem,
          logger: testLogger,
          platform: FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
          processManager: processManager,
        ),
        usesAndroidX: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), exists);
      expect(
        testLogger.errorText,
        contains('[!] Your .gradle directory under the home directory might be corrupted.\n'),
      );
      expect(testLogger.statusText, '');
    });

    testWithoutContext('suggestion if running as bot', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FakeFlutterProject(),
        toolContext: FakeToolContext(
          botDetector: const FakeBotDetector(true),
          fs: fileSystem,
          logger: testLogger,
          platform: FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
          processManager: processManager,
        ),
        usesAndroidX: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), isNot(exists));

      expect(
        testLogger.errorText,
        contains('[!] Your .gradle directory under the home directory might be corrupted.\n'),
      );
      expect(testLogger.statusText, contains('Deleting foo/.gradle\n'));
    });

    testWithoutContext('suggestion if stdin has terminal and user entered y', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);
      final promptLogger = BufferLogger.test(terminal: _TestPromptTerminal('y'));

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FakeFlutterProject(),
        toolContext: FakeToolContext(
          botDetector: const FakeBotDetector(false),
          fs: fileSystem,
          logger: promptLogger,
          platform: FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
          processManager: processManager,
        ),
        usesAndroidX: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), isNot(exists));
      expect(
        promptLogger.errorText,
        contains('[!] Your .gradle directory under the home directory might be corrupted.\n'),
      );
      expect(promptLogger.statusText, contains('Deleting foo/.gradle\n'));
    });

    testWithoutContext('suggestion if stdin has terminal and user entered n', () async {
      fileSystem.file('foo/.gradle/fizz.zip').createSync(recursive: true);
      final promptLogger = BufferLogger.test(terminal: _TestPromptTerminal('n'));

      final GradleBuildStatus result = await zipExceptionHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: '',
        project: FakeFlutterProject(),
        toolContext: FakeToolContext(
          botDetector: const FakeBotDetector(false),
          fs: fileSystem,
          logger: promptLogger,
          platform: FakePlatform(environment: <String, String>{'HOME': 'foo/'}),
          processManager: processManager,
        ),
        usesAndroidX: true,
      );

      expect(result, equals(GradleBuildStatus.retry));
      expect(fileSystem.file('foo/.gradle/fizz.zip'), exists);
      expect(
        promptLogger.errorText,
        contains('[!] Your .gradle directory under the home directory might be corrupted.\n'),
      );
      expect(promptLogger.statusText, '');
    });
  });

  group('incompatible java and gradle versions error', () {
    const errorMessage = '''
Could not compile build file '…/example/android/build.gradle'.
> startup failed:
  General error during conversion: Unsupported class file major version 61
  java.lang.IllegalArgumentException: Unsupported class file major version 61
''';

    testWithoutContext('pattern', () {
      expect(incompatibleJavaAndGradleVersionsHandler.test(errorMessage), isTrue);
    });

    testWithoutContext('suggestion', () async {
      await incompatibleJavaAndGradleVersionsHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: errorMessage,
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        toolContext: toolContext,
        usesAndroidX: true,
      );

      // Ensure the error notes the incompatible Gradle/AGP/Java versions, links to related resources,
      // and a portion of the path to where to change their gradle version.
      expect(
        testLogger.statusText,
        contains('Gradle version is incompatible with the Java version'),
      );
      expect(testLogger.statusText, contains('gradle-wrapper.properties'));
      expect(
        testLogger.statusText,
        contains('https://docs.gradle.org/current/userguide/compatibility.html#java'),
      );
    });
  });

  testWithoutContext('couldNotOpenCacheDirectoryHandler', () async {
    final GradleBuildStatus status = await couldNotOpenCacheDirectoryHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: '''
FAILURE: Build failed with an exception.

* Where:
Script '/Volumes/Work/s/w/ir/x/w/flutter/packages/flutter_tools/gradle/src/main/groovy/flutter.groovy' line: 276

* What went wrong:
A problem occurred evaluating script.
> Failed to apply plugin class 'FlutterPlugin'.
   > Could not open cache directory 41rl0ui7kgmsyfwn97o2jypl6 (/Volumes/Work/s/w/ir/cache/gradle/caches/6.7/gradle-kotlin-dsl/41rl0ui7kgmsyfwn97o2jypl6).
      > Failed to create Jar file /Volumes/Work/s/w/ir/cache/gradle/caches/6.7/generated-gradle-jars/gradle-api-6.7.jar.''',
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      toolContext: toolContext,
      usesAndroidX: true,
    );
    expect(testLogger.errorText, contains('Gradle threw an error while resolving dependencies'));
    expect(status, GradleBuildStatus.retry);
  });

  testWithoutContext('compileSdk 35 and AGP < 8.1', () async {
    const errorExample = r'''
Execution failed for task ':app:bundleReleaseResources'.
> A failure occurred while executing com.android.build.gradle.internal.res.Aapt2ProcessResourcesRunnable
   > Android resource linking failed
     aapt2 E 08-19 15:06:26 76078 5921862 LoadedArsc.cpp:94] RES_TABLE_TYPE_TYPE entry offsets overlap actual entry data.
     aapt2 E 08-19 15:06:26 76078 5921862 ApkAssets.cpp:152] Failed to load resources table in APK '/Users/mackall/Library/Android/sdk/platforms/android-35/android.jar'.
     error: failed to load include path /Users/mackall/Library/Android/sdk/platforms/android-35/android.jar.
    ''';

    await incompatibleCompileSdk35AndAgpVersionHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: errorExample,
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(
      testLogger.statusText,
      contains(
        '\n'
        '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────────┐\n'
        '│ [!] Using compileSdk 35 requires Android Gradle Plugin (AGP) 8.1.0 or higher.                    │\n'
        '│  Please upgrade to a newer AGP version. The version of AGP that your project uses is likely      │\n'
        '│  defined in:                                                                                     │\n'
        '│ /android/settings.gradle,                                                                        │\n'
        '│ in the \'plugins\' closure (by the number following "com.android.application").                    │\n'
        '│  Alternatively, if your project was created with an older version of the templates, it is likely │\n'
        '│ in the buildscript.dependencies closure of the top-level build.gradle:                           │\n'
        '│ /android/build.gradle,                                                                           │\n'
        '│ as the number following "com.android.tools.build:gradle:".                                       │\n'
        '│                                                                                                  │\n'
        '│  Finally, if you have a strong reason to avoid upgrading AGP, you can temporarily lower the      │\n'
        '│  compileSdk version in the following file:                                                       │\n'
        '│ /android/app/build.gradle                                                                        │\n'
        '└──────────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        '',
      ),
    );
  });

  testWithoutContext('AGP 7.3.0 R8 bug', () async {
    const errorExample = r'''
ERROR:/Users/mackall/.gradle/caches/transforms-3/bd2c84591857c6d4c308221ffece862e/transformed/jetified-media3-exoplayer-dash-1.4.0-runtime.jar: R8: com.android.tools.r8.internal.Y10: Unused argument with users in androidx
    ''';

    await r8DexingBugInAgp73Handler.handler(
      gradleUtils: FakeGradleUtils(),
      line: errorExample,
      project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(
      testLogger.statusText,
      contains(
        '\n'
        '┌─ Flutter Fix ────────────────────────────────────────────────────────────────────────────────────┐\n'
        '│ [!] Version 7.3 of the Android Gradle Plugin (AGP) uses a version of R8 that contains a bug      │\n'
        '│ which causes this error (see more info at https://issuetracker.google.com/issues/242308990).     │\n'
        '│ To fix this error, update to a newer version of AGP (at least 7.4.0).                            │\n'
        '│                                                                                                  │\n'
        '│  The version of AGP that your project uses is likely defined in:                                 │\n'
        '│ /android/settings.gradle,                                                                        │\n'
        '│ in the \'plugins\' closure (by the number following "com.android.application").                    │\n'
        '│  Alternatively, if your project was created with an older version of the templates, it is likely │\n'
        '│ in the buildscript.dependencies closure of the top-level build.gradle:                           │\n'
        '│ /android/build.gradle,                                                                           │\n'
        '│ as the number following "com.android.tools.build:gradle:".                                       │\n'
        '└──────────────────────────────────────────────────────────────────────────────────────────────────┘\n'
        '',
      ),
    );
  });

  testWithoutContext('Usage of removed v1 embedding references', () async {
    const errorExample = r'''
/Users/jesswon/.pub-cache/hosted/pub.dev/video_player_android-2.5.0/android/src/main/java/io/flutter/plugins/videoplayer/VideoPlayerPlugin.java:42: error: cannot find symbol
  private VideoPlayerPlugin(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
                                                                   ^
  symbol:   class Registrar
  location: interface PluginRegistry
1 error

FAILURE: Build failed with an exception.
    ''';

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    await usageOfV1EmbeddingReferencesHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: errorExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    // Main fix text.
    expect(
      testLogger.statusText,
      contains(
        "To fix this error, please upgrade your current package's dependencies to latest versions by",
      ),
    );
    expect(testLogger.statusText, contains('running `flutter pub upgrade`.'));
    // Text and link to file an issue.
    expect(
      testLogger.statusText,
      contains('If that does not work, please file an issue for the problematic plugin(s) here:'),
    );
    expect(testLogger.statusText, contains('https://github.com/flutter/flutter/issues'));
  });

  testWithoutContext('Java 21 and jlink bug', () async {
    const errorExample = r'''
* What went wrong:
Execution failed for task ':shared_preferences_android:compileReleaseJavaWithJavac'.
> Could not resolve all files for configuration ':shared_preferences_android:androidJdkImage'.
   > Failed to transform core-for-system-modules.jar to match attributes {artifactType=_internal_android_jdk_image, org.gradle.libraryelements=jar, org.gradle.usage=java-runtime}.
      > Execution failed for JdkImageTransform: /Users/mackall/Library/Android/sdk/platforms/android-34/core-for-system-modules.jar.
         > Error while executing process /Users/mackall/Desktop/JDKs/21/jdk-21.0.2.jdk/Contents/Home/bin/jlink with arguments {--module-path /Users/mackall/.gradle/caches/8.9/transforms/2890fec03da42154757073d3208548e5-79660961-f91d-4df2-90bc-b9a3f2a270bd/transformed/output/temp/jmod --add-modules java.base --output /Users/mackall/.gradle/caches/8.9/transforms/2890fec03da42154757073d3208548e5-79660961-f91d-4df2-90bc-b9a3f2a270bd/transformed/output/jdkImage --disable-plugin system-modules}
    ''';

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    await jlinkErrorWithJava21AndSourceCompatibility.handler(
      gradleUtils: FakeGradleUtils(),
      line: errorExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    // Main fix text.
    expect(
      testLogger.statusText,
      contains('To fix this error, please upgrade your AGP version to at least 8.2.1.'),
    );
    // Paths to AGP location.
    expect(testLogger.statusText, contains('/android/settings.gradle'));
    expect(testLogger.statusText, contains('/android/build.gradle'));
    // Links to info.
    expect(testLogger.statusText, contains('https://issuetracker.google.com/issues/294137077'));
    expect(testLogger.statusText, contains('https://github.com/flutter/flutter/issues/156304'));
  });

  testWithoutContext('Missing NDK source.properties file', () async {
    const unixErrorExample = r'''
* What went wrong:
A problem occurred configuring project ':app'.
> [CXX1101] NDK at /Users/mackall/Library/Android/sdk/ndk/26.3.11579264 did not have a source.properties file
    ''';

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    await missingNdkSourcePropertiesFile.handler(
      gradleUtils: FakeGradleUtils(),
      line: unixErrorExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(testLogger.statusText, contains('This can be fixed by deleting the local NDK copy at'));
    expect(testLogger.statusText, contains('/Users/mackall/Library/Android/sdk/ndk/26.3.11579264'));

    const windowsErrorExample = r'''
* What went wrong:
A problem occurred configuring project ':app'.
> [CXX1101] NDK at C:\Users\mackall\Library\Android\sdk\ndk\26.3.11579264 did not have a source.properties file
    ''';
    await missingNdkSourcePropertiesFile.handler(
      gradleUtils: FakeGradleUtils(),
      line: windowsErrorExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(testLogger.statusText, contains('This can be fixed by deleting the local NDK copy at'));
    expect(
      testLogger.statusText,
      contains(r'C:\Users\mackall\Library\Android\sdk\ndk\26.3.11579264'),
    );
  });

  testWithoutContext('Failure to apply kotlin-android plugin', () async {
    const applyingKotlinAndroidPluginErrorExample = r'''
FAILURE: Build failed with an exception.

* Where:
Build file '/Users/jesswon/Desktop/fresh_flutter_app/android/app/build.gradle.kts'

* What went wrong:
An exception occurred applying plugin request [id: 'kotlin-android']
> Failed to apply plugin 'kotlin-android'.
   > ⛔ Failed to apply plugin 'com.jetbrains.kotlin.android'
     The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0.
     Solution: Remove the 'org.jetbrains.kotlin.android' plugin from this project's build file: app/build.gradle.kts.
     See https://issuetracker.google.com/438678642 for more details.
      > java.lang.Throwable (no error message)
    ''';

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    await applyingKotlinAndroidPluginErrorHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: applyingKotlinAndroidPluginErrorExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(
      testLogger.statusText,
      contains('Starting AGP 9+, the default has become built-in Kotlin.'),
    );
    expect(
      testLogger.statusText,
      contains(' This results in a build failure when applying the kotlin-android plugin'),
    );
    expect(testLogger.statusText, contains('applying the kotlin-android plugin'));
    expect(testLogger.statusText, contains('For instructions on how to migrate, see:'));
    expect(testLogger.statusText, contains(kMigrateToBuiltInKotlinDocsUrl));
  });

  group('new AGP DSL error', () {
    const useNewAgpDslErrorExample = r'''
FAILURE: Build failed with an exception.

* Where:
Build file '/Users/jesswon/Desktop/fresh_flutter_app/android/app/build.gradle.kts'

* What went wrong:
An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
   > java.lang.NullPointerException (no error message)
''';

    testWithoutContext('matches the new AGP DSL failure', () {
      expect(formatTestErrorMessage(useNewAgpDslErrorExample, useNewAgpDslErrorHandler), isTrue);
    });

    testWithoutContext('does not match unsupported dependency version errors', () {
      const unsupportedAgpVersionErrorExample = r'''
FAILURE: Build failed with an exception.

* Where:
Build file '/path/to/my_app/android/app/build.gradle.kts' line: 1

* What went wrong:
An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
   > Error: Your project's Android Gradle Plugin version (10.0.0) is not yet supported. Flutter does not support Android Gradle Plugin 10, and support will be added in a future Flutter release. Please downgrade your Android Gradle Plugin version to a version below 10.0.0 to continue.
     Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check (unsupported; your build may fail).
''';
      expect(
        formatTestErrorMessage(unsupportedAgpVersionErrorExample, useNewAgpDslErrorHandler),
        isFalse,
      );
    });

    testWithoutContext('does not match other errors thrown while applying the plugin', () {
      const minimumGradleVersionErrorExample = r'''
FAILURE: Build failed with an exception.

* What went wrong:
An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
   > Error: Your project's Gradle version (8.13.0) is lower than Flutter's minimum supported version of 8.14.0. Please upgrade your Gradle version.
''';
      expect(
        formatTestErrorMessage(minimumGradleVersionErrorExample, useNewAgpDslErrorHandler),
        isFalse,
      );
    });
  });

  testWithoutContext('Failure to apply Flutter Gradle plugin with the new AGP DSL', () async {
    const useNewAgpDslErrorHandlerExample = r'''
FAILURE: Build failed with an exception.

* Where:
Build file '/Users/jesswon/Desktop/fresh_flutter_app/android/app/build.gradle.kts'

* What went wrong:
An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
   > java.lang.NullPointerException (no error message)
    ''';

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    await useNewAgpDslErrorHandler.handler(
      gradleUtils: FakeGradleUtils(),
      line: useNewAgpDslErrorHandlerExample,
      project: project,
      toolContext: toolContext,
      usesAndroidX: true,
    );

    expect(
      testLogger.statusText,
      contains('Starting AGP 9+, only the new DSL interface will be read.'),
    );
    expect(
      testLogger.statusText,
      contains('This results in a build failure when applying the Flutter Gradle plugin'),
    );
    expect(testLogger.statusText, contains('For instructions on how to opt out, see:'));
    expect(testLogger.statusText, contains(kOptOutOfNewDslDocsUrl));
    expect(
      testLogger.statusText,
      contains('If you are not upgrading to AGP 9+, run `flutter analyze --suggestions`'),
    );
  });

  group('kotlin-android plugin with new AGP DSL error', () {
    const kotlinAndroidWithNewDslStacktraceExample = r'''
FAILURE: Build failed with an exception.

* Where:
Build file '/path/to/my_app/android/app/build.gradle.kts'

* What went wrong:
An exception occurred applying plugin request [id: 'org.jetbrains.kotlin.android', version: '2.4.20']
> Failed to apply plugin 'org.jetbrains.kotlin.android'.
   > ⛔ Failed to apply plugin 'org.jetbrains.kotlin.android'
     The 'org.jetbrains.kotlin.android' plugin is not compatible with AGP's 9.0 new DSL (`android.newDsl=true` is enabled by default).
     Solution: Set `android.builtInKotlin=true` in `gradle.properties` and migrate to built-in Kotlin (see https://kotl.in/gradle/agp-built-in-kotlin for guidance), or set `android.newDsl=false` in `gradle.properties` to temporarily bypass this issue.
     See https://kotl.in/gradle/agp-new-dsl for more details.
      > class com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.BaseExtension (com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated and com.android.build.gradle.BaseExtension are in unnamed module of loader org.gradle.internal.classloader.VisitableURLClassLoader$InstrumentingVisitableURLClassLoader @5a20f9cc)

* Exception is:
org.gradle.api.plugins.InvalidPluginException: An exception occurred applying plugin request [id: 'org.jetbrains.kotlin.android', version: '2.4.20']
Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.BaseExtension
''';

    testWithoutContext('matches Kotlin Gradle plugin incompatibility with AGP new DSL', () {
      expect(
        formatTestErrorMessage(
          kotlinAndroidWithNewDslStacktraceExample,
          kotlinAndroidPluginWithNewDslErrorHandler,
        ),
        isTrue,
      );
      // Future-proofed against KGP fixing the "AGP's 9.0" typo in newer releases.
      expect(
        kotlinAndroidPluginWithNewDslErrorHandler.test(
          "The 'org.jetbrains.kotlin.android' plugin is not compatible with AGP 9.0 new DSL.",
        ),
        isTrue,
      );
    });

    testWithoutContext('does not match built-in Kotlin duplicate plugin error', () {
      const builtInKotlinErrorExample = r'''
> Failed to apply plugin 'kotlin-android'.
   > ⛔ Failed to apply plugin 'com.jetbrains.kotlin.android'
     The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0.
''';
      expect(
        formatTestErrorMessage(
          builtInKotlinErrorExample,
          kotlinAndroidPluginWithNewDslErrorHandler,
        ),
        isFalse,
      );
    });

    testWithoutContext('prioritizes kotlinAndroidPluginWithNewDslErrorHandler ahead of legacyVariantApiErrorHandler on stacktraces with BaseExtension cast', () {
      GradleHandledError? firstMatchedLineHandler;
      for (final String line in kotlinAndroidWithNewDslStacktraceExample.split('\n')) {
        for (final GradleHandledError error in gradleErrors) {
          if (error.test(line)) {
            firstMatchedLineHandler = error;
            break;
          }
        }
        if (firstMatchedLineHandler != null) {
          break;
        }
      }
      expect(firstMatchedLineHandler, same(kotlinAndroidPluginWithNewDslErrorHandler));

      final GradleHandledError combinedChunkHandler = gradleErrors.firstWhere(
        (GradleHandledError error) => error.test(kotlinAndroidWithNewDslStacktraceExample),
      );
      expect(combinedChunkHandler, same(kotlinAndroidPluginWithNewDslErrorHandler));
    });

    testWithoutContext('prints android.newDsl=false workaround, automatic builtInKotlin=false context, and migration guidance', () async {
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
      final GradleBuildStatus status = await kotlinAndroidPluginWithNewDslErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: "     The 'org.jetbrains.kotlin.android' plugin is not compatible with AGP's 9.0 new DSL (`android.newDsl=true` is enabled by default).",
        project: project,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by kotlinAndroidPluginWithNewDslErrorHandler.
      );

      expect(
        kotlinAndroidPluginWithNewDslErrorHandler.eventLabel,
        equals('kotlin-android-plugin-with-new-dsl-error'),
      );
      expect(status, equals(GradleBuildStatus.exit));
      expect(testLogger.statusText, contains('┌─ Flutter Fix'));
      final String unwrappedBox = unwrapBoxText(testLogger.statusText);
      expect(
        unwrappedBox,
        contains(
          "The 'org.jetbrains.kotlin.android' (kotlin-android) Gradle plugin does not support "
          'android.newDsl=true.',
        ),
      );
      expect(
        unwrappedBox,
        contains(
          'Flutter applies kotlin-android automatically when android.builtInKotlin=false is set '
          'in android/gradle.properties, or a Gradle build script in the app or in a Flutter '
          'plugin may apply kotlin-android directly.',
        ),
      );
      expect(
        unwrappedBox,
        contains(
          'Gradle identifies the build script or project under "* Where:" or '
          '"* What went wrong:" above.',
        ),
      );
      expect(
        testLogger.statusText,
        contains('To build now, set android.newDsl=false in android/gradle.properties.'),
      );
      expect(
        testLogger.statusText,
        contains('Android Gradle Plugin 10.0 removes the android.newDsl=false option.'),
      );
      expect(testLogger.statusText, contains(kOptOutOfNewDslDocsUrl));
      expect(
        unwrappedBox,
        contains(
          'If a Flutter plugin applies kotlin-android, upgrade the Flutter plugin or file an '
          'issue with the plugin asking for built-in Kotlin support.',
        ),
      );
      expect(
        unwrappedBox,
        contains(
          'Otherwise, set android.builtInKotlin=true in android/gradle.properties and remove '
          "any 'org.jetbrains.kotlin.android' (kotlin-android) declaration from the app's "
          'Gradle build script.',
        ),
      );
      expect(testLogger.statusText, contains(kMigrateToBuiltInKotlinDocsUrl));
    });

    testWithoutContext('points add-to-app module projects to .android/gradle.properties', () async {
      fileSystem.currentDirectory
          .childFile('pubspec.yaml')
          .writeAsStringSync('name: my_module\nflutter:\n  module:\n    androidX: true\n');
      final FlutterProject moduleProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );

      await kotlinAndroidPluginWithNewDslErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: "The 'org.jetbrains.kotlin.android' plugin is not compatible with AGP's 9.0 new DSL.",
        project: moduleProject,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by kotlinAndroidPluginWithNewDslErrorHandler.
      );

      expect(
        testLogger.statusText,
        contains('To build now, set android.newDsl=false in .android/gradle.properties.'),
      );
      expect(
        unwrapBoxText(testLogger.statusText),
        contains('set android.builtInKotlin=true in .android/gradle.properties'),
      );
      expect(testLogger.statusText, isNot(contains('in android/gradle.properties')));
    });

    testWithoutContext(
      'notes external override when gradle.properties already sets android.newDsl=false',
      () async {
        fileSystem.currentDirectory
            .childDirectory('android')
            .childFile('gradle.properties')
            .createSync(recursive: true);
        fileSystem.currentDirectory
            .childDirectory('android')
            .childFile('gradle.properties')
            .writeAsStringSync('android.newDsl=false\n');
        final FlutterProject project = FlutterProject.fromDirectoryTest(
          fileSystem.currentDirectory,
        );

        await kotlinAndroidPluginWithNewDslErrorHandler.handler(
          gradleUtils: FakeGradleUtils(),
          line:
              "The 'org.jetbrains.kotlin.android' plugin is not compatible with AGP's 9.0 new DSL.",
          project: project,
          toolContext: toolContext,
          usesAndroidX: true, // Unused by kotlinAndroidPluginWithNewDslErrorHandler.
        );

        expect(
          unwrapBoxText(testLogger.statusText),
          contains(
            'android/gradle.properties already sets android.newDsl=false; check '
            '~/.gradle/gradle.properties and -Pandroid.newDsl command-line flags for an override.',
          ),
        );
      },
    );
  });

  group('legacy AGP variant and extension API errors with new DSL', () {
    testWithoutContext(
      'matches Groovy unknown variant properties on AGP ExtensionImpl objects',
      () {
        const groovyVariantPropertyExamples = <String>[
          r"> Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
          r"> Could not get unknown property 'libraryVariants' for object of type com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated.",
          r"> Could not get unknown property 'testVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
          r"> Could not get unknown property 'unitTestVariants' for object of type com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated.",
        ];
        for (final example in groovyVariantPropertyExamples) {
          expect(
            formatTestErrorMessage(example, legacyVariantApiErrorHandler),
            isTrue,
            reason: example,
          );
        }
      },
    );

    testWithoutContext(
      'matches Groovy variantFilter and variant closure calls on AGP ExtensionImpl objects',
      () {
        const groovyVariantMethodExamples = <String>[
          r'> Could not find method variantFilter() for arguments [build_abc123$_run_closure1$_closure2@25d18118] on object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.',
          r'> Could not find method applicationVariants() for arguments [build_abc123$_run_closure1@25d18118] on object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.',
          r'> Could not find method libraryVariants() for arguments [build_abc123$_run_closure1@25d18118] on object of type com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated.',
          r'> Could not find method testVariants() for arguments [build_abc123$_run_closure1@25d18118] on object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.',
          r'> Could not find method unitTestVariants() for arguments [build_abc123$_run_closure1@25d18118] on object of type com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated.',
        ];
        for (final example in groovyVariantMethodExamples) {
          expect(
            formatTestErrorMessage(example, legacyVariantApiErrorHandler),
            isTrue,
            reason: example,
          );
        }
      },
    );

    testWithoutContext('matches Groovy variant containers nested inside sourceSets', () {
      const sourceSetVariantExamples = <String>[
        r'> Could not find method all() for arguments [build_abc123$_run_closure1$_closure2$_closure3@6b68870d] on source set application variants of type com.android.build.gradle.internal.api.DefaultAndroidSourceSet.',
        r'> Could not find method all() for arguments [build_abc123$_run_closure1$_closure2$_closure3@208dfc0] on source set library variants of type com.android.build.gradle.internal.api.DefaultAndroidLibrarySourceSet.',
      ];
      for (final example in sourceSetVariantExamples) {
        expect(
          formatTestErrorMessage(example, legacyVariantApiErrorHandler),
          isTrue,
          reason: example,
        );
      }
    });

    testWithoutContext(
      'matches Kotlin build script .gradle.kts unresolved variant API references',
      () {
        const kotlinDslVariantExamples = <String>[
          "e: file:///path/to/my_app/android/app/build.gradle.kts:5:5: Unresolved reference 'applicationVariants'.",
          "e: file:///path/to/plugin/android/build.gradle.kts:8:5: Unresolved reference 'libraryVariants'.",
          "e: file:///path/to/my_app/android/app/build.gradle.kts:9:5: Unresolved reference 'testVariants'.",
          "e: file:///path/to/my_app/android/app/build.gradle.kts:10:5: Unresolved reference 'unitTestVariants'.",
          "e: file:///path/to/my_app/android/app/build.gradle.kts:11:5: Unresolved reference 'variantFilter'.",
        ];
        for (final example in kotlinDslVariantExamples) {
          expect(
            formatTestErrorMessage(example, legacyVariantApiErrorHandler),
            isTrue,
            reason: example,
          );
        }
      },
    );

    testWithoutContext(
      'matches missing legacy extension types when AGP 9 new DSL types are registered',
      () {
        const missingExtensionExamples = <String>[
          "Extension of type 'LibraryExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, FlutterExtension, VersionCatalogsExtension, BasePluginExtension, SourceSetContainer, ReportingExtension, JavaToolchainService, JavaPluginExtension, KotlinAndroidProjectExtension, LibraryExtensionImpl, LibraryAndroidComponentsExtension, LintLifecycleExtension]",
          "Extension of type 'com.android.build.gradle.LibraryExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, LibraryExtensionImpl, LibraryAndroidComponentsExtension]",
          "Extension of type 'AppExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, FlutterExtension, ApplicationExtension, ApplicationAndroidComponentsExtension, LintLifecycleExtension]",
          "Extension of type 'BaseAppModuleExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, FlutterExtension, ApplicationExtension, ApplicationAndroidComponentsExtension, LintLifecycleExtension]",
          "Extension of type 'com.android.build.gradle.internal.dsl.BaseAppModuleExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, ApplicationExtension, ApplicationAndroidComponentsExtension]",
          "Extension of type 'BaseExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, ApplicationExtension, ApplicationAndroidComponentsExtension]",
          "Extension of type 'BaseExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, DynamicFeatureExtensionImpl]",
          "Extension of type 'TestedExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, TestExtensionImpl]",
          "Extension of type 'TestExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, TestExtensionImpl]",
        ];
        for (final example in missingExtensionExamples) {
          expect(
            formatTestErrorMessage(example, legacyVariantApiErrorHandler),
            isTrue,
            reason: example,
          );
        }
      },
    );

    testWithoutContext('matches JVM ClassCastException and GroovyCastException from ExtensionImpl to legacy AGP extension types', () {
      const castExamples = <String>[
        r'> class com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.BaseExtension (com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated_Decorated and com.android.build.gradle.BaseExtension are in unnamed module of loader org.gradle.internal.classloader.VisitableURLClassLoader$InstrumentingVisitableURLClassLoader @1a2b3c4d)',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.AppExtension',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.internal.dsl.BaseAppModuleExtension',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.LibraryExtension',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.TestExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.TestedExtension',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.TestExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.TestExtension',
        r"> Cannot cast object 'extension 'android'' with class 'com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated' to class 'com.android.build.gradle.BaseExtension'",
        r"> Cannot cast object 'extension 'android'' with class 'com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated' to class 'com.android.build.gradle.internal.dsl.BaseAppModuleExtension'",
        r"> Cannot cast object 'extension 'android'' with class 'com.android.build.gradle.internal.dsl.LibraryExtensionImpl$AgpDecorated' to class 'com.android.build.gradle.LibraryExtension'",
        r"> Cannot cast object 'extension 'android'' with class 'com.android.build.gradle.internal.dsl.TestExtensionImpl$AgpDecorated' to class 'com.android.build.gradle.TestExtension'",
      ];
      for (final example in castExamples) {
        expect(
          formatTestErrorMessage(example, legacyVariantApiErrorHandler),
          isTrue,
          reason: example,
        );
      }
    });

    testWithoutContext('does not match kotlinOptions errors caused by built-in Kotlin', () {
      const kotlinOptionsExamples = <String>[
        r"> Could not get unknown property 'kotlinOptions' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
        r'> Could not find method kotlinOptions() for arguments [build_abc123$_run_closure1@1234] on object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.',
        "e: file:///path/to/my_app/android/app/build.gradle.kts:12:5: Unresolved reference 'kotlinOptions'.",
      ];
      for (final example in kotlinOptionsExamples) {
        expect(
          formatTestErrorMessage(example, legacyVariantApiErrorHandler),
          isFalse,
          reason: example,
        );
      }
    });

    testWithoutContext('does not match Kotlin app or plugin .kt source compilation errors or unrelated Gradle properties', () {
      const unrelatedExamples = <String>[
        "e: file:///path/to/my_app/android/app/src/main/kotlin/com/example/MainActivity.kt:10:5: Unresolved reference 'testVariants'.",
        "e: file:///path/to/plugin/android/src/main/kotlin/com/example/Plugin.kt:4:12: Unresolved reference 'applicationVariants'.",
        r"> Could not get unknown property 'flutterVersionCode' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
        r"> Could not get unknown property 'libraryVariants' for object of type com.android.build.gradle.internal.dsl.BaseAppModuleExtension$AgpDecorated.",
        "> Could not get unknown property 'applicationVariants' for root project 'android' of type org.gradle.api.Project.",
        "> Could not find method variantFilter() for arguments [] on root project 'android' of type org.gradle.api.Project.",
        '> Could not find method unknownMethod() for arguments [] on source set main of type com.android.build.gradle.internal.api.DefaultAndroidSourceSet.',
        "e: file:///path/to/my_app/android/app/build.gradle.kts:15:5: Unresolved reference 'flutterVersionCode'.",
      ];
      for (final example in unrelatedExamples) {
        expect(
          formatTestErrorMessage(example, legacyVariantApiErrorHandler),
          isFalse,
          reason: example,
        );
      }
    });

    testWithoutContext('does not match wrong-module extension lookups when android.newDsl is false', () {
      const wrongExtensionInLibraryUnderLegacyDsl =
          "Extension of type 'AppExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, VersionCatalogsExtension, BasePluginExtension, SourceSetContainer, ReportingExtension, JavaToolchainService, JavaPluginExtension, KotlinAndroidProjectExtension, LibraryExtension, LibraryAndroidComponentsExtension, LintLifecycleExtension, NamedDomainObjectContainer<BaseVariantOutput>]";
      expect(
        formatTestErrorMessage(wrongExtensionInLibraryUnderLegacyDsl, legacyVariantApiErrorHandler),
        isFalse,
      );

      // When android.newDsl=false in :app, AppPlugin registers both ApplicationExtension and BaseAppModuleExtension.
      const wrongExtensionInAppUnderLegacyDsl =
          "Extension of type 'LibraryExtension' does not exist. Currently registered extension types: [ExtraPropertiesExtension, FlutterExtension, ApplicationExtension, BaseAppModuleExtension, ApplicationAndroidComponentsExtension, LintLifecycleExtension]";
      expect(
        formatTestErrorMessage(wrongExtensionInAppUnderLegacyDsl, legacyVariantApiErrorHandler),
        isFalse,
      );
    });

    testWithoutContext('does not match unrelated or legacy-DSL cast exceptions', () {
      const unrelatedClassCastExamples = <String>[
        'java.lang.ClassCastException: class java.lang.String cannot be cast to class java.lang.Integer',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.LibraryExtension$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.AppExtension',
        r'Caused by: java.lang.ClassCastException: class com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to class com.android.build.gradle.BaseExtensionSubclass',
        r"> Cannot cast object 'extension 'android'' with class 'com.android.build.gradle.LibraryExtension$AgpDecorated' to class 'com.android.build.gradle.AppExtension'",
      ];
      for (final example in unrelatedClassCastExamples) {
        expect(
          formatTestErrorMessage(example, legacyVariantApiErrorHandler),
          isFalse,
          reason: example,
        );
      }
    });

    testWithoutContext('suppresses Flutter Fix box for ambiguous .gradle.kts or sourceSets errors when gradle.properties already sets android.newDsl=false', () async {
      fileSystem.currentDirectory
          .childDirectory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.currentDirectory
          .childDirectory('android')
          .childFile('gradle.properties')
          .writeAsStringSync('# Comment line\nandroid.newDsl = false\n');
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      final GradleBuildStatus ktsStatus = await legacyVariantApiErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: "e: file:///path/to/my_app/android/app/build.gradle.kts:5:5: Unresolved reference 'libraryVariants'.",
        project: project,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by legacyVariantApiErrorHandler.
      );
      expect(ktsStatus, equals(GradleBuildStatus.exit));
      expect(testLogger.statusText, isEmpty);

      final GradleBuildStatus sourceSetStatus = await legacyVariantApiErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: r'> Could not find method all() for arguments [closure] on source set library variants of type com.android.build.gradle.internal.api.DefaultAndroidSourceSet.',
        project: project,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by legacyVariantApiErrorHandler.
      );
      expect(sourceSetStatus, equals(GradleBuildStatus.exit));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('prints box with external override note when runtime ExtensionImpl error occurs despite android.newDsl=false in gradle.properties', () async {
      fileSystem.currentDirectory
          .childDirectory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.currentDirectory
          .childDirectory('android')
          .childFile('gradle.properties')
          .writeAsStringSync('android.newDsl=false\n');
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      await legacyVariantApiErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: r"> Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
        project: project,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by legacyVariantApiErrorHandler.
      );

      expect(
        unwrapBoxText(testLogger.statusText),
        contains(
          'android/gradle.properties already sets android.newDsl=false; check '
          '~/.gradle/gradle.properties and -Pandroid.newDsl command-line flags for an override.',
        ),
      );
    });

    testWithoutContext('echoes only the matching line when multi-line ProcessException text is passed and resolves module .android/gradle.properties', () async {
      fileSystem.currentDirectory
          .childFile('pubspec.yaml')
          .writeAsStringSync('name: my_module\nflutter:\n  module:\n    androidX: true\n');
      final FlutterProject moduleProject = FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      );
      const multiLineException = r'''
ProcessException: Failed to run Gradle:
FAILURE: Build failed with an exception.
* What went wrong:
> Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.
* Try:
> Run with --stacktrace option to get the stack trace.''';

      await legacyVariantApiErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: multiLineException,
        project: moduleProject,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by legacyVariantApiErrorHandler.
      );

      expect(
        unwrapBoxText(testLogger.statusText),
        contains(
          r"> Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
        ),
      );
      expect(testLogger.statusText, isNot(contains('ProcessException:')));
      expect(testLogger.statusText, isNot(contains('Run with --stacktrace')));
      expect(
        testLogger.statusText,
        contains('To build now, set android.newDsl=false in .android/gradle.properties.'),
      );
    });

    testWithoutContext('prints matched error line, android.newDsl=false workaround, and variant API migration link', () async {
      const matchedLine =
          r"   > Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.   ";
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
      final GradleBuildStatus status = await legacyVariantApiErrorHandler.handler(
        gradleUtils: FakeGradleUtils(),
        line: matchedLine,
        project: project,
        toolContext: toolContext,
        usesAndroidX: true, // Unused by legacyVariantApiErrorHandler.
      );

      expect(legacyVariantApiErrorHandler.eventLabel, equals('legacy-variant-api-error'));
      expect(status, equals(GradleBuildStatus.exit));
      expect(testLogger.statusText, contains('┌─ Flutter Fix'));
      final String unwrappedBox = unwrapBoxText(testLogger.statusText);
      expect(
        unwrappedBox,
        contains(
          'A Gradle build script or Gradle plugin, in the app or in a Flutter plugin, uses an '
          'Android Gradle Plugin API unavailable when android.newDsl is enabled.',
        ),
      );
      expect(
        unwrappedBox,
        contains(
          r"> Could not get unknown property 'applicationVariants' for object of type com.android.build.gradle.internal.dsl.ApplicationExtensionImpl$AgpDecorated.",
        ),
      );
      expect(
        unwrappedBox,
        contains(
          'Gradle identifies the build script or project under "* Where:" or '
          '"* What went wrong:" above.',
        ),
      );
      expect(
        testLogger.statusText,
        contains('To build now, set android.newDsl=false in android/gradle.properties.'),
      );
      expect(
        testLogger.statusText,
        contains('Android Gradle Plugin 10.0 removes the android.newDsl=false option.'),
      );
      expect(testLogger.statusText, contains(kOptOutOfNewDslDocsUrl));
      expect(
        unwrappedBox,
        contains(
          'If a Flutter plugin or third-party Gradle plugin uses the removed API, upgrade the '
          'plugin or file an issue with the plugin author asking for android.newDsl support.',
        ),
      );
      expect(
        unwrappedBox,
        contains(
          'If the build script is in the app, migrate the build script to the '
          'com.android.build.api.dsl interfaces and the variant API '
          '(androidComponents.onVariants or androidComponents.beforeVariants).',
        ),
      );
      expect(testLogger.statusText, contains(kAgpVariantApiDocsUrl));
    });
  });
}

String unwrapBoxText(String rawStatusText) {
  return rawStatusText
      .split('\n')
      .map(
        (String line) => line.replaceAll(RegExp(r'^\s*[┌┐└┘─│]+.*?(?=\S)|^\s*│\s*|\s*│\s*$'), ''),
      )
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool formatTestErrorMessage(String errorMessage, GradleHandledError error) {
  return errorMessage.split('\n').any((String line) => error.test(line));
}

Platform fakePlatform(String name) {
  return FakePlatform(environment: <String, String>{'HOME': '/'}, operatingSystem: name);
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
  String color(String message, TerminalColor color) => message;

  @override
  String get warningMark => '[!]';

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

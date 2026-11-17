// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Process, ProcessResult, SystemEncoding;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../../../.agents/skills/shepherd-prs/scripts/src/auth_provider.dart';
import '../../../.agents/skills/shepherd-prs/scripts/src/cli_runner.dart';
import '../../../.agents/skills/shepherd-prs/scripts/src/cocoon_client.dart';
import '../../../.agents/skills/shepherd-prs/scripts/src/models.dart';

const String _sampleSha = 'f8800a6a89df2086a05801d8739f066877664a3c';
const int _samplePr = 196572;
const int _sampleCheckRunId = 133828994601;
const String _fakeFirebaseWebApiKey = 'fake-public-firebase-web-key';
const String _fakeFirebaseOptionsDart =
    '''
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$_fakeFirebaseWebApiKey',
    projectId: 'flutter-dashboard',
  );
}
''';

String _buildFakeFirebaseJwt({
  String aud = DashboardConstants.firebaseProjectId,
  String email = 'contributor@google.com',
  String iss = DashboardConstants.firebaseExpectedIssuer,
  String provider = DashboardConstants.googleProviderId,
}) {
  String encodePart(Map<String, Object?> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');

  final String header = encodePart(<String, Object?>{'alg': 'RS256', 'typ': 'JWT'});
  final String payload = encodePart(<String, Object?>{
    'iss': iss,
    'aud': aud,
    'email': email,
    'firebase': <String, Object?>{'sign_in_provider': provider},
  });
  return '$header.$payload.signature';
}

final class _RecordedProcessCall {
  const _RecordedProcessCall(this.command);

  final List<String> command;
}

final class _FakeProcessManager implements ProcessManager {
  _FakeProcessManager({this._onRun, Set<String>? runnableExecutables})
    : _runnableExecutables = runnableExecutables ?? <String>{'chmod'};

  final Set<String> _runnableExecutables;
  final ProcessResult Function(List<String> command)? _onRun;
  final calls = <_RecordedProcessCall>[];

  @override
  bool canRun(Object? executable, {String? workingDirectory}) =>
      executable is String && _runnableExecutables.contains(executable);

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stderrEncoding = const SystemEncoding(),
    Encoding? stdoutEncoding = const SystemEncoding(),
    String? workingDirectory,
  }) async => runSync(
    command,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stderrEncoding: stderrEncoding,
    stdoutEncoding: stdoutEncoding,
    workingDirectory: workingDirectory,
  );

  @override
  ProcessResult runSync(
    List<Object> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stderrEncoding = const SystemEncoding(),
    Encoding? stdoutEncoding = const SystemEncoding(),
    String? workingDirectory,
  }) {
    final args = <String>[for (final Object part in command) '$part'];
    calls.add(_RecordedProcessCall(args));
    if (_onRun != null) {
      return _onRun(args);
    }
    return ProcessResult(0, 0, '', '');
  }

  @override
  bool killPid(int pid, [Object? signal]) => false;

  @override
  Future<Process> start(
    List<Object> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    Object? mode,
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw StateError('ProcessManager.start is not used by dashboard_presubmit.');
  }
}

void main() {
  group('PresubmitGuardReport & JobDisposition', () {
    test('classifies Succeeded, Neutral suppressed flakes, Pending, and Infra Failure', () {
      final report = PresubmitGuardReport.fromJson(const <String, Object?>{
        'pr_num': _samplePr,
        'check_run_id': _sampleCheckRunId,
        'author': 'bkonyi',
        'guard_status': 'Failed',
        'stages': <Object?>[
          <String, Object?>{
            'name': 'fusion',
            'created_at': 1794891419217,
            'jobs': <String, Object?>{
              'Linux analyze': 'Succeeded',
              'Linux customer_testing': 'Neutral',
              'Linux web_canvaskit_tests_3': 'Infra Failure',
              'Mac framework_tests_misc': 'Failed',
              'Windows build_tests_1_9': 'In Progress',
              'Linux skipped_target': 'Skipped',
            },
          },
        ],
      });

      expect(report.prNumber, _samplePr);
      expect(report.checkRunId, _sampleCheckRunId);
      expect(report.guardStatus, 'Failed');
      expect(
        report.succeededJobs.map((PresubmitJobEntry j) => j.name),
        containsAll(<String>['Linux analyze', 'Linux skipped_target']),
      );
      expect(report.suppressedJobs.map((PresubmitJobEntry j) => j.name), <String>[
        'Linux customer_testing',
      ]);
      expect(report.pendingJobs.map((PresubmitJobEntry j) => j.name), <String>[
        'Windows build_tests_1_9',
      ]);
      expect(report.failedJobs.map((PresubmitJobEntry j) => j.name), <String>[
        'Linux web_canvaskit_tests_3',
        'Mac framework_tests_misc',
      ]);
      expect(report.findJob('Linux customer_testing')?.disposition, JobDisposition.suppressedFlake);
    });

    test('parses PresubmitJobAttempt with string or integer build_id', () {
      final attemptFromString = PresubmitJobAttempt.fromJson(const <String, Object?>{
        'attempt_number': 1,
        'job_name': 'Linux web_canvaskit_tests_3',
        'status': 'Infra Failure',
        'build_id': '8664913649940258337',
        'summary': 'Task timed out.',
      });
      final attemptFromInt = PresubmitJobAttempt.fromJson(const <String, Object?>{
        'attempt_number': 2,
        'job_name': 'Linux web_canvaskit_tests_3',
        'status': 'New',
        'build_id': 12345,
      });

      expect(attemptFromString.buildId, '8664913649940258337');
      expect(attemptFromString.summary, 'Task timed out.');
      expect(attemptFromInt.buildId, '12345');
      expect(attemptFromInt.attemptNumber, 2);
      expect(
        () => JobDisposition.fromStatus('Completely Unknown Status'),
        throwsA(isA<DashboardException>()),
      );
    });
  });

  group('CocoonClient .ci.yaml staleness verification', () {
    test(
      'detects non-bringup builders removed on base branch while allowing PR bringup targets',
      () {
        const headYaml = '''
targets:
  - name: Linux analyze
  - name: Linux old_removed_builder
  - name: Linux new_pr_bringup_builder
    bringup: true
''';
        const baseYaml = '''
targets:
  - name: Linux analyze
  - name: Linux newly_added_on_master
''';

        final List<String> removed = CocoonClient.findRemovedNonBringupBuilders(
          baseCiYaml: baseYaml,
          headCiYaml: headYaml,
        );
        expect(removed, <String>['Linux old_removed_builder']);
      },
    );

    test(
      'flags unsafe when master removed a builder after push-time ci.yaml validation passed',
      () async {
        final processManager = _FakeProcessManager(runnableExecutables: const <String>{});
        final mockHttp = MockClient((http.Request request) async {
          final url = request.url.toString();
          if (url.contains('/check-runs?check_name=ci.yaml%20validation')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'check_runs': <Object?>[
                  <String, Object?>{'id': 99, 'status': 'completed', 'conclusion': 'success'},
                ],
              }),
              200,
            );
          }
          if (url.contains('/contents/.ci.yaml?ref=$_sampleSha')) {
            return http.Response(
              'targets:\n  - name: Linux analyze\n  - name: Mac_arm64 legacy_builder\n',
              200,
            );
          }
          if (url.contains('/contents/.ci.yaml?ref=master')) {
            return http.Response('targets:\n  - name: Linux analyze\n', 200);
          }
          if (url.contains('/contents/engine/src/flutter/.ci.yaml')) {
            return http.Response('targets:\n  - name: Linux host_engine\n', 200);
          }
          return http.Response('Not found: $url', 404);
        });

        final client = CocoonClient(httpClient: mockHttp, processManager: processManager);
        final CiYamlSafetyReport safety = await client.verifyCiYamlSafety(
          baseRef: 'master',
          headSha: _sampleSha,
          owner: 'flutter',
          repo: 'flutter',
        );

        expect(safety.isSafe, isFalse);
        expect(safety.removedBuilders, <String>['Mac_arm64 legacy_builder (.ci.yaml)']);
        expect(safety.failureReason, contains('permanently orphan the attempt'));
      },
    );

    test('fails closed when root .ci.yaml fetch returns HTTP 403 rate limit', () async {
      final processManager = _FakeProcessManager(runnableExecutables: const <String>{});
      final mockHttp = MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url.contains('/check-runs?check_name=ci.yaml%20validation')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'check_runs': <Object?>[
                <String, Object?>{'id': 99, 'status': 'completed', 'conclusion': 'success'},
              ],
            }),
            200,
          );
        }
        return http.Response('API rate limit exceeded', 403);
      });

      final client = CocoonClient(httpClient: mockHttp, processManager: processManager);
      final CiYamlSafetyReport safety = await client.verifyCiYamlSafety(
        baseRef: 'master',
        headSha: _sampleSha,
        owner: 'flutter',
        repo: 'flutter',
      );

      expect(safety.isSafe, isFalse);
      expect(safety.failureReason, contains('HTTP 403'));
    });
  });

  group('DashboardAuthProvider', () {
    test('exchanges Google OAuth token, writes 0600 credentials on POSIX, and refreshes when expired', () async {
      final fs = MemoryFileSystem.test();
      final processManager = _FakeProcessManager(
        runnableExecutables: <String>{'chmod', 'gcloud'},
        onRun: (List<String> cmd) {
          if (cmd.length >= 3 && cmd[0] == 'gcloud' && cmd[1] == 'auth' && cmd[2] == 'list') {
            // Simulate Cloudtop where machine service account is ACTIVE and @google.com is inactive.
            return ProcessResult(
              0,
              0,
              jsonEncode(<Object?>[
                <String, Object?>{
                  'account':
                      'insecure-cloudtop-shared-user@cloudtop-prod-us-east.iam.gserviceaccount.com',
                  'status': 'ACTIVE',
                },
                <String, Object?>{'account': 'bkonyi@google.com', 'status': ''},
              ]),
              '',
            );
          }
          if (cmd.length >= 4 &&
              cmd[0] == 'gcloud' &&
              cmd[2] == 'print-access-token' &&
              cmd[3] == '--account=bkonyi@google.com') {
            return ProcessResult(0, 0, 'fake-google-oauth-token\n', '');
          }
          return ProcessResult(0, 0, '', '');
        },
      );

      var currentNow = DateTime.utc(2026, 11, 17, 17);
      final String initialJwt = _buildFakeFirebaseJwt(email: 'bkonyi@google.com');
      final String refreshedJwt = _buildFakeFirebaseJwt(email: 'bkonyi@google.com');
      var refreshCalls = 0;

      final mockHttp = MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url == DashboardConstants.cocoonFirebaseOptionsUrl) {
          return http.Response(_fakeFirebaseOptionsDart, 200);
        }
        if (url == DashboardConstants.firebaseSignInWithIdpUrl(_fakeFirebaseWebApiKey)) {
          final Object? body = jsonDecode(request.body);
          expect(
            body,
            containsPair('postBody', 'access_token=fake-google-oauth-token&providerId=google.com'),
          );
          return http.Response(
            jsonEncode(<String, Object?>{
              'idToken': initialJwt,
              'refreshToken': 'firebase-refresh-1',
              'expiresIn': '3600',
              'email': 'bkonyi@google.com',
            }),
            200,
          );
        }
        if (url == DashboardConstants.firebaseSecureTokenUrl(_fakeFirebaseWebApiKey)) {
          refreshCalls++;
          expect(request.body, 'grant_type=refresh_token&refresh_token=firebase-refresh-1');
          return http.Response(
            jsonEncode(<String, Object?>{
              'id_token': refreshedJwt,
              'refresh_token': 'firebase-refresh-2',
              'expires_in': '3600',
            }),
            200,
          );
        }
        return http.Response('Unexpected URL: $url', 500);
      });

      final provider = DashboardAuthProvider(
        clock: () => currentNow,
        fileSystem: fs,
        hostEnvironment: const HostEnvironment(
          environment: <String, String>{'HOME': '/home/bkonyi'},
          isWindows: false,
        ),
        httpClient: mockHttp,
        processManager: processManager,
      );

      final StoredDashboardCredentials creds = await provider.login();
      expect(creds.email, 'bkonyi@google.com');
      expect(creds.idToken, initialJwt);

      const expectedPath = '/home/bkonyi/.config/flutter_dashboard/credentials.json';
      expect(fs.file(expectedPath).existsSync(), isTrue);
      expect(
        processManager.calls.any(
          (_RecordedProcessCall c) =>
              c.command.length == 3 &&
              c.command[0] == 'chmod' &&
              c.command[1] == '600' &&
              c.command[2] == expectedPath,
        ),
        isTrue,
      );

      // Within expiry window: reuses cached token with zero refresh calls.
      currentNow = currentNow.add(const Duration(minutes: 10));
      expect(await provider.resolveIdToken(), initialJwt);
      expect(refreshCalls, 0);

      // Past expiry window: refreshes headlessly via securetoken API.
      currentNow = currentNow.add(const Duration(hours: 2));
      expect(await provider.resolveIdToken(), refreshedJwt);
      expect(refreshCalls, 1);
      expect(provider.readStoredCredentials()?.refreshToken, 'firebase-refresh-2');
    });

    test('rejects classic GitHub PATs and Cloudtop service-account-only gcloud sessions', () async {
      final fs = MemoryFileSystem.test();
      final processManager = _FakeProcessManager(
        runnableExecutables: <String>{'gcloud'},
        onRun: (List<String> cmd) => ProcessResult(
          0,
          0,
          jsonEncode(<Object?>[
            <String, Object?>{
              'account':
                  'insecure-cloudtop-shared-user@cloudtop-prod-us-east.iam.gserviceaccount.com',
              'status': 'ACTIVE',
            },
          ]),
          '',
        ),
      );
      final mockHttp = MockClient((_) async => http.Response('{}', 200));

      final provider = DashboardAuthProvider(
        fileSystem: fs,
        hostEnvironment: const HostEnvironment(
          environment: <String, String>{'HOME': '/home/bkonyi'},
          isWindows: true,
        ),
        httpClient: mockHttp,
        processManager: processManager,
      );

      await expectLater(
        provider.loginWithAccessToken(
          'ghp'
          '_exampleClassicToken123',
        ),
        throwsA(
          isA<DashboardAuthException>().having(
            (DashboardAuthException e) => e.message,
            'message',
            contains('gh auth token'),
          ),
        ),
      );

      await expectLater(
        provider.login(),
        throwsA(
          isA<DashboardAuthException>().having(
            (DashboardAuthException e) => e.message,
            'message',
            contains('service account'),
          ),
        ),
      );
    });

    test('fails closed on POSIX without chmod, wraps corrupt JSON, and supports GitHub Firebase refresh tokens', () async {
      final fs = MemoryFileSystem.test();
      final String githubJwt = _buildFakeFirebaseJwt(
        email: 'hacker@example.org',
        provider: 'github.com',
      );
      final mockHttp = MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url == DashboardConstants.cocoonFirebaseOptionsUrl) {
          return http.Response(_fakeFirebaseOptionsDart, 200);
        }
        if (url == DashboardConstants.firebaseSecureTokenUrl(_fakeFirebaseWebApiKey)) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'id_token': githubJwt,
              'refresh_token': 'gh-firebase-refresh',
              'expires_in': '3600',
            }),
            200,
          );
        }
        return http.Response('Unexpected', 500);
      });

      // Missing chmod on POSIX fails closed before writing credentials.json.
      final noChmodProvider = DashboardAuthProvider(
        fileSystem: fs,
        hostEnvironment: const HostEnvironment(
          environment: <String, String>{'HOME': '/home/hacker'},
          isWindows: false,
        ),
        httpClient: mockHttp,
        processManager: _FakeProcessManager(runnableExecutables: const <String>{}),
      );
      await expectLater(
        noChmodProvider.loginWithRefreshToken('gh-firebase-refresh'),
        throwsA(isA<DashboardException>()),
      );
      expect(
        fs.file('/home/hacker/.config/flutter_dashboard/credentials.json').existsSync(),
        isFalse,
      );

      // Corrupt JSON throws DashboardAuthException instead of raw FormatException.
      const credsPath = '/home/hacker/.config/flutter_dashboard/credentials.json';
      fs.file(credsPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('{not-valid-json');
      final validProvider = DashboardAuthProvider(
        fileSystem: fs,
        hostEnvironment: const HostEnvironment(
          environment: <String, String>{'HOME': '/home/hacker'},
          isWindows: false,
        ),
        httpClient: mockHttp,
        processManager: _FakeProcessManager(runnableExecutables: const <String>{'chmod'}),
      );
      expect(validProvider.readStoredCredentials, throwsA(isA<DashboardAuthException>()));

      // Non-@google.com GitHub OAuth Firebase refresh token succeeds and sets 0700 + 0600.
      final StoredDashboardCredentials stored = await validProvider.loginWithRefreshToken(
        'gh-firebase-refresh',
      );
      expect(stored.email, 'hacker@example.org');
      expect(await validProvider.resolveIdToken(), githubJwt);
    });
  });

  group('DashboardCliRunner commands', () {
    Future<(int exitCode, String stdoutText, String stderrText)> runCli(
      List<String> args, {
      required http.Client httpClient,
      DateTime Function()? clock,
      FileSystem? fileSystem,
      Map<String, String>? env,
      ProcessManager? processManager,
    }) async {
      final outBuffer = StringBuffer();
      final errBuffer = StringBuffer();
      final runner = DashboardCliRunner(
        clock: clock,
        errSink: errBuffer,
        fileSystem: fileSystem ?? MemoryFileSystem.test(),
        hostEnvironment: HostEnvironment(
          environment: env ?? const <String, String>{'HOME': '/home/bkonyi'},
          isWindows: false,
        ),
        httpClient: httpClient,
        outSink: outBuffer,
        processManager:
            processManager ?? _FakeProcessManager(runnableExecutables: const <String>{'chmod'}),
      );
      final int code = await runner.run(args);
      return (code, outBuffer.toString(), errBuffer.toString());
    }

    MockClient buildStandardMockHttp({
      bool ciYamlValid = true,
      Map<String, String>? guardJobs,
      void Function(http.Request request)? onRerunPost,
      int rerunStatusCode = 200,
    }) {
      final Map<String, String> jobs =
          guardJobs ??
          const <String, String>{
            'Linux analyze': 'Succeeded',
            'Linux customer_testing': 'Neutral',
            'Linux web_canvaskit_tests_3': 'Infra Failure',
          };

      return MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url.endsWith('/repos/flutter/flutter/pulls/$_samplePr')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'number': _samplePr,
              'state': 'open',
              'title': 'Sample PR',
              'head': <String, Object?>{'sha': _sampleSha},
              'base': <String, Object?>{'ref': 'master'},
            }),
            200,
          );
        }
        if (url.contains('/check-runs?check_name=ci.yaml%20validation')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'check_runs': <Object?>[
                <String, Object?>{
                  'id': 10,
                  'status': 'completed',
                  'conclusion': ciYamlValid ? 'success' : 'failure',
                  'output': <String, Object?>{
                    'text': ciYamlValid ? 'Valid' : 'FormatException: builder removed',
                  },
                },
              ],
            }),
            200,
          );
        }
        if (url.contains('/contents/.ci.yaml') ||
            url.contains('/contents/engine/src/flutter/.ci.yaml')) {
          return http.Response('targets:\n  - name: Linux analyze\n', 200);
        }
        if (url.contains(DashboardConstants.presubmitGuardPath)) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'pr_num': _samplePr,
              'check_run_id': _sampleCheckRunId,
              'author': 'bkonyi',
              'guard_status': 'Failed',
              'stages': <Object?>[
                <String, Object?>{'name': 'fusion', 'jobs': jobs},
              ],
            }),
            200,
          );
        }
        if (url.endsWith(DashboardConstants.rerunAllFailedJobsPath) ||
            url.endsWith(DashboardConstants.rerunFailedJobPath)) {
          onRerunPost?.call(request);
          return http.Response('{}', rerunStatusCode);
        }
        return http.Response('Unhandled request: $url', 404);
      });
    }

    test('rerun --all-failed prints flutter-dashboard fallback URL (never Buildbucket) when unauthenticated', () async {
      var rerunCalled = false;
      final MockClient mockHttp = buildStandardMockHttp(onRerunPost: (_) => rerunCalled = true);

      final (int code, String out, String err) = await runCli(<String>[
        'rerun',
        '--pr',
        '$_samplePr',
        '--all-failed',
      ], httpClient: mockHttp);

      expect(code, ExitCodes.authRequired);
      expect(rerunCalled, isFalse);
      expect(out, isEmpty);
      expect(
        err,
        contains('https://flutter-dashboard.appspot.com/#/presubmit?repo=flutter&sha=$_sampleSha'),
      );
      expect(err, isNot(contains('cr-buildbucket.appspot.com/build')));
    });

    test('rerun refuses before calling Cocoon when ci.yaml validation failed', () async {
      var rerunCalled = false;
      final MockClient mockHttp = buildStandardMockHttp(
        ciYamlValid: false,
        onRerunPost: (_) => rerunCalled = true,
      );

      final (int code, String _, String err) = await runCli(<String>[
        'rerun',
        '--pr',
        '$_samplePr',
        '--all-failed',
        '--id-token',
        _buildFakeFirebaseJwt(),
      ], httpClient: mockHttp);

      expect(code, ExitCodes.staleCiYaml);
      expect(rerunCalled, isFalse);
      expect(err, contains('orphan the new attempt in Firestore'));
    });

    test(
      'rerun refuses to retrigger Neutral suppressed flakes and posts valid single builder rerun',
      () async {
        final recordedRequests = <http.Request>[];
        final MockClient mockHttp = buildStandardMockHttp(onRerunPost: recordedRequests.add);
        final String jwt = _buildFakeFirebaseJwt();

        final (int neutralCode, String _, String neutralErr) = await runCli(<String>[
          'rerun',
          '--pr',
          '$_samplePr',
          '--builder',
          'Linux customer_testing',
          '--id-token',
          jwt,
        ], httpClient: mockHttp);

        expect(neutralCode, ExitCodes.error);
        expect(neutralErr, contains('suppressed flake'));
        expect(recordedRequests, isEmpty);

        final (int okCode, String okOut, String okErr) = await runCli(<String>[
          'rerun',
          '--pr',
          '$_samplePr',
          '--builder',
          'Linux web_canvaskit_tests_3',
          '--id-token',
          jwt,
        ], httpClient: mockHttp);

        expect(okCode, ExitCodes.success);
        expect(okErr, isEmpty);
        expect(okOut, contains('Retriggered 1 failed job(s)'));
        expect(recordedRequests, hasLength(1));
        expect(recordedRequests.single.url.path, DashboardConstants.rerunFailedJobPath);
        expect(recordedRequests.single.headers[DashboardConstants.idTokenHeader], jwt);
        expect(jsonDecode(recordedRequests.single.body), <String, Object?>{
          'owner': 'flutter',
          'repo': 'flutter',
          'pr': _samplePr,
          'builder': 'Linux web_canvaskit_tests_3',
        });
      },
    );

    test(
      'rerun --all-failed exits 0 without POST when only Neutral suppressed flakes exist',
      () async {
        var rerunCalled = false;
        final MockClient mockHttp = buildStandardMockHttp(
          guardJobs: const <String, String>{
            'Linux analyze': 'Succeeded',
            'Linux customer_testing': 'Neutral',
          },
          onRerunPost: (_) => rerunCalled = true,
        );

        final (int code, String out, String _) = await runCli(<String>[
          'rerun',
          '--pr',
          '$_samplePr',
          '--all-failed',
          '--id-token',
          _buildFakeFirebaseJwt(),
        ], httpClient: mockHttp);

        expect(code, ExitCodes.success);
        expect(rerunCalled, isFalse);
        expect(out, contains('No failed presubmit jobs to rerun'));
        expect(out, contains('1 Neutral suppressed flake(s) ignored'));
      },
    );

    test(
      'status --details --json flags stale orphaned New attempts while ignoring fresh reruns',
      () async {
        final fixedNow = DateTime.utc(2026, 11, 17, 18);
        final int tenMinutesAgoMs = fixedNow
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch;
        final int tenSecondsAgoMs = fixedNow
            .subtract(const Duration(seconds: 10))
            .millisecondsSinceEpoch;

        final mockHttp = MockClient((http.Request request) async {
          final url = request.url.toString();
          if (url.endsWith('/repos/flutter/flutter/pulls/$_samplePr')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'number': _samplePr,
                'state': 'open',
                'title': 'Sample PR',
                'head': <String, Object?>{'sha': _sampleSha},
                'base': <String, Object?>{'ref': 'master'},
              }),
              200,
            );
          }
          if (url.contains('/check-runs?check_name=ci.yaml%20validation')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'check_runs': <Object?>[
                  <String, Object?>{'id': 10, 'status': 'completed', 'conclusion': 'success'},
                ],
              }),
              200,
            );
          }
          if (url.contains('/contents/.ci.yaml') ||
              url.contains('/contents/engine/src/flutter/.ci.yaml')) {
            return http.Response('targets:\n  - name: Linux analyze\n', 200);
          }
          if (url.contains(DashboardConstants.presubmitGuardPath)) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'pr_num': _samplePr,
                'check_run_id': _sampleCheckRunId,
                'guard_status': 'In Progress',
                'stages': <Object?>[
                  <String, Object?>{
                    'name': 'fusion',
                    'jobs': <String, Object?>{
                      'Linux tool_integration_tests_1_7': 'New',
                      'Linux freshly_retriggered_shard': 'New',
                      'Linux customer_testing': 'Neutral',
                    },
                  },
                ],
              }),
              200,
            );
          }
          if (url.contains(DashboardConstants.presubmitJobPath)) {
            final bool isFresh = url.contains('freshly_retriggered_shard');
            return http.Response(
              jsonEncode(<Object?>[
                <String, Object?>{
                  'attempt_number': 1,
                  'job_name': isFresh
                      ? 'Linux freshly_retriggered_shard'
                      : 'Linux tool_integration_tests_1_7',
                  'status': 'Failed',
                  'build_id': '800001',
                },
                <String, Object?>{
                  'attempt_number': 2,
                  'job_name': isFresh
                      ? 'Linux freshly_retriggered_shard'
                      : 'Linux tool_integration_tests_1_7',
                  'creation_time': isFresh ? tenSecondsAgoMs : tenMinutesAgoMs,
                  'status': 'New',
                },
              ]),
              200,
            );
          }
          return http.Response('Unhandled: $url', 404);
        });

        final (int code, String out, String err) = await runCli(
          <String>['status', '--pr', '$_samplePr', '--details', '--json'],
          clock: () => fixedNow,
          httpClient: mockHttp,
        );

        expect(code, ExitCodes.success);
        expect(err, isEmpty);
        final decoded = jsonDecode(out) as Map<String, Object?>;
        expect(decoded['suspected_orphaned_rerun_builders'], <Object?>[
          'Linux tool_integration_tests_1_7',
        ]);
      },
    );

    test('rerun refreshes cached credentials once and retries when Cocoon returns 401', () async {
      final fs = MemoryFileSystem.test();
      final String staleJwt = _buildFakeFirebaseJwt(email: 'bkonyi@google.com');
      final String freshJwt = _buildFakeFirebaseJwt(email: 'bkonyi@google.com');
      const credsPath = '/home/bkonyi/.config/flutter_dashboard/credentials.json';
      fs.file(credsPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'refresh_token': 'refresh-1',
            'id_token': staleJwt,
            'expires_at_epoch_ms': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
            'email': 'bkonyi@google.com',
          }),
        );

      final seenTokens = <String>[];
      final mockHttp = MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url.endsWith('/repos/flutter/flutter/pulls/$_samplePr')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'number': _samplePr,
              'state': 'open',
              'title': 'Sample PR',
              'head': <String, Object?>{'sha': _sampleSha},
              'base': <String, Object?>{'ref': 'master'},
            }),
            200,
          );
        }
        if (url.contains('/check-runs?check_name=ci.yaml%20validation')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'check_runs': <Object?>[
                <String, Object?>{'id': 10, 'status': 'completed', 'conclusion': 'success'},
              ],
            }),
            200,
          );
        }
        if (url.contains('/contents/.ci.yaml') ||
            url.contains('/contents/engine/src/flutter/.ci.yaml')) {
          return http.Response('targets:\n  - name: Linux analyze\n', 200);
        }
        if (url.contains(DashboardConstants.presubmitGuardPath)) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'pr_num': _samplePr,
              'check_run_id': _sampleCheckRunId,
              'guard_status': 'Failed',
              'stages': <Object?>[
                <String, Object?>{
                  'name': 'fusion',
                  'jobs': <String, Object?>{'Linux web_canvaskit_tests_3': 'Failed'},
                },
              ],
            }),
            200,
          );
        }
        if (url == DashboardConstants.cocoonFirebaseOptionsUrl) {
          return http.Response(_fakeFirebaseOptionsDart, 200);
        }
        if (url == DashboardConstants.firebaseSecureTokenUrl(_fakeFirebaseWebApiKey)) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'id_token': freshJwt,
              'refresh_token': 'refresh-2',
              'expires_in': '3600',
            }),
            200,
          );
        }
        if (url.endsWith(DashboardConstants.rerunAllFailedJobsPath)) {
          final String token = request.headers[DashboardConstants.idTokenHeader] ?? '';
          seenTokens.add(token);
          return seenTokens.length == 1
              ? http.Response('Expired token', 401)
              : http.Response('{}', 200);
        }
        return http.Response('Unhandled: $url', 404);
      });

      final (int code, String out, String err) = await runCli(
        <String>['rerun', '--pr', '$_samplePr', '--all-failed'],
        fileSystem: fs,
        httpClient: mockHttp,
      );

      expect(code, ExitCodes.success);
      expect(err, isEmpty);
      expect(out, contains('Retriggered 1 failed job(s)'));
      expect(seenTokens, <String>[staleJwt, freshJwt]);
    });

    test('login --access-token, --check, and --logout manage stored credentials', () async {
      final fs = MemoryFileSystem.test();
      final String jwt = _buildFakeFirebaseJwt(email: 'bkonyi@google.com');
      final mockHttp = MockClient((http.Request request) async {
        final url = request.url.toString();
        if (url == DashboardConstants.cocoonFirebaseOptionsUrl) {
          return http.Response(_fakeFirebaseOptionsDart, 200);
        }
        if (url == DashboardConstants.firebaseSignInWithIdpUrl(_fakeFirebaseWebApiKey)) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'idToken': jwt,
              'refreshToken': 'refresh-xyz',
              'expiresIn': '3600',
              'email': 'bkonyi@google.com',
            }),
            200,
          );
        }
        return http.Response('Unhandled', 404);
      });

      final (int loginCode, String loginOut, String _) = await runCli(
        <String>['login', '--access-token', 'fake-test-token'],
        fileSystem: fs,
        httpClient: mockHttp,
      );
      expect(loginCode, ExitCodes.success);
      expect(loginOut, contains('bkonyi@google.com'));

      final (int checkCode, String checkOut, String _) = await runCli(
        <String>['login', '--check', '--json'],
        fileSystem: fs,
        httpClient: mockHttp,
      );
      expect(checkCode, ExitCodes.success);
      expect(jsonDecode(checkOut), containsPair('status', 'authenticated'));

      final (int logoutCode, String logoutOut, String _) = await runCli(
        <String>['login', '--logout'],
        fileSystem: fs,
        httpClient: mockHttp,
      );
      expect(logoutCode, ExitCodes.success);
      expect(logoutOut, contains('Removed cached flutter-dashboard credentials'));
    });
  });
}

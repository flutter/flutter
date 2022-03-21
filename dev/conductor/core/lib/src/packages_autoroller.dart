import 'dart:convert';
import 'dart:io';

import 'globals.dart';

// https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
// created personal access token with scopes: "repo", "read:org".

// git push https://<GITHUB_ACCESS_TOKEN>@github.com/<GITHUB_USERNAME>/<REPOSITORY_NAME>.git HEAD:$REMOTE_BRANCH_NAME

class PackageAutoroller {
  PackageAutoroller({
    required this.githubClient,
    required this.token,
  }) {
    if (token.trim().isEmpty) {
      throw Exception('empty token!');
    }
    if (githubClient.trim().isEmpty) {
      throw Exception('Must provide path to GitHub client!');
    }
  }

  /// Path to GitHub CLI client.
  final String githubClient;

  /// GitHub API access token.
  final String token;

  static const String hostname = 'github.com';

  Future<void> roll() async {
    await authLogout();
    await authLogin();
    await createPr(workingDirectory: workingDirectory);
    await authLogout();
  }

  Future<void> authLogout() {
    return cli(
      <String>['auth', 'logout', '--hostname', hostname],
      allowFailure: true,
    );
  }

  Future<void> authLogin() {
    return cli(
      <String>[
        'auth',
        'login',
        '--hostname',
        hostname,
        '--git-protocol',
        'https',
        '--with-token',
      ],
      stdin: token,
    );
  }

  /// Create a pull request on GitHub.
  ///
  /// When the current branch isn't fully pushed to a git remote, a prompt will ask where
  /// to push the branch and offer an option to fork the base repository. Use `--head` to
  /// explicitly skip any forking or pushing behavior.
  ///
  /// A prompt will also ask for the title and the body of the pull request. Use `--title`
  /// and `--body` to skip this, or use `--fill` to autofill these values from git commits.
  ///
  /// Link an issue to the pull request by referencing the issue in the body of the pull
  /// request. If the body text mentions `Fixes #123` or `Closes #123`, the referenced issue
  /// will automatically get closed when the pull request gets merged.
  ///
  /// By default, users with write access to the base repository can push new commits to the
  /// head branch of the pull request. Disable this with `--no-maintainer-edit`.
  ///
  ///
  /// USAGE
  ///   gh pr create [flags]
  ///
  /// FLAGS
  ///   -a, --assignee login       Assign people by their login. Use "@me" to self-assign.
  ///   -B, --base branch          The branch into which you want your code merged
  ///   -b, --body string          Body for the pull request
  ///   -F, --body-file file       Read body text from file
  ///   -d, --draft                Mark pull request as a draft
  ///   -f, --fill                 Do not prompt for title/body and just use commit info
  ///   -H, --head branch          The branch that contains commits for your pull request (default: current branch)
  ///   -l, --label name           Add labels by name
  ///   -m, --milestone name       Add the pull request to a milestone by name
  ///       --no-maintainer-edit   Disable maintainer's ability to modify pull request
  ///   -p, --project name         Add the pull request to projects by name
  ///       --recover string       Recover input from a failed run of create
  ///   -r, --reviewer handle      Request reviews from people or teams by their handle
  ///   -t, --title string         Title for the pull request
  ///   -w, --web                  Open the web browser to create a pull request
  ///
  /// INHERITED FLAGS
  ///       --help                     Show help for command
  ///   -R, --repo [HOST/]OWNER/REPO   Select another repository using the [HOST/]OWNER/REPO format
  ///
  /// EXAMPLES
  ///   $ gh pr create --title "The bug is fixed" --body "Everything works again"
  ///   $ gh pr create --reviewer monalisa,hubot  --reviewer myorg/team-name
  ///   $ gh pr create --project "Roadmap"
  ///   $ gh pr create --base develop --head monalisa:feature
  Future<void> createPr({required String workingDirectory}) async {
    const String title = 'A PR Title';
    const String body = 'A PR Body';
    const String headBranch = 'developmoar';

    await cli(
      <String>[
        'pr',
        'create',
        '--title',
        title,
        '--body',
        body,
        '--head',
        headBranch,
      ],
      workingDirectory: workingDirectory,
    );
  }

  Future<void> help([List<String>? args]) {
    return cli(<String>[
      'help',
      ...?args,
    ]);
  }

  Future<void> cli(
    List<String> args, {
    bool allowFailure = false,
    String? stdin,
    String? workingDirectory,
  }) async {
    final Process process = await Process.start(
      githubClient,
      args,
      workingDirectory: workingDirectory,
      environment: <String, String>{},
    );
    final List<String> stderrStrings = <String>[];
    final List<String> stdoutStrings = <String>[];
    unawaited(process.stdout.transform(utf8.decoder).forEach((String line) {
      print('[STDOUT] $line');
      stdoutStrings.add(line);
    }));
    unawaited(process.stderr.transform(utf8.decoder).forEach((String line) {
      print('[STDERR] $line');
      stderrStrings.add(line);
    }));
    if (stdin != null) {
      process.stdin.write(stdin);
      await process.stdin.flush();
      //await process.stdin.close();
    }
    final int exitCode = await process.exitCode;
    final String stderr = stderrStrings.join();
    final String stdout = stdoutStrings.join();
    if (!allowFailure && exitCode != 0) {
      print('Command $githubClient ${args.join(' ')} failed with code $exitCode');
      print(stderr);
      print(stdout);
      print(StackTrace.current);
      exit(1);
    }
    print(stdout);
  }

  //String get binPath {
  //  return 'gh';
  //  final List<String> segments = Platform.script.pathSegments;
  //  final Iterable<String> parentSegments = segments.take(segments.length - 1);
  //  return <String>[
  //    '', // add empty string so the joined string has a leading separator
  //    ...parentSegments,
  //    'bin',
  //    'gh',
  //  ].join(Platform.pathSeparator);
  //}
}

String get workingDirectory {
  final String workingDirectory = Platform.environment['WORKING_DIR']!.trim();
  if (!Directory(workingDirectory).existsSync()) {
    print('Whoops! $workingDirectory does not exist!');
    exit(1);
  }
  return workingDirectory;
}

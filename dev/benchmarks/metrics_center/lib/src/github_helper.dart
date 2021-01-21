// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// Singleton class to query some Github info with an in-memory cache.
class GithubHelper {
  /// Return the singleton helper.
  factory GithubHelper() {
    return _singleton;
  }

  GithubHelper._internal();

  /// The result is cached in memory so querying the same thing again in the
  /// same process is fast.
  ///
  /// Our unit test requires that calling this method 1000 times for the same
  /// `githubRepo` and `sha` should be done in 1 second.
  Future<DateTime> getCommitDateTime(String githubRepo, String sha) async {
    final String key = '$githubRepo/commit/$sha';
    if (_commitDateTimeCache[key] == null) {
      final RepositoryCommit commit = await _github.repositories
          .getCommit(RepositorySlug.full(githubRepo), sha);
      _commitDateTimeCache[key] = commit.commit.committer.date;
    }
    return _commitDateTimeCache[key];
  }

  static final GithubHelper _singleton = GithubHelper._internal();

  final GitHub _github = GitHub(auth: findAuthenticationFromEnvironment());
  final Map<String, DateTime> _commitDateTimeCache = <String, DateTime>{};
}

import 'dart:io';

import 'package:meta/meta.dart';

import './repositories.dart';

/// Wrapper class for all tool-managed git repositories.
class Checkout {
  Checkout({
    @required this.repos,
    @required this.processManager,
  }) : assert(repos != null, processManager != null) {
    syncAll();
    final String entryPointBin = Platform.script.path;
    print('Checkout root = ${checkoutRoot}');
  }

  Map<String, Repository> repos;
  final ProcessManager processManager;
  Directory checkoutRoot;

  // Ensure all repos are cloned and fetched.
  void syncAll() {
    repos.forEach((String name, Repository repo) async {
      print('About to sync ${repo.name}...');
      repo.ensureCloned();
      repo.fetch();
    });
  }
}

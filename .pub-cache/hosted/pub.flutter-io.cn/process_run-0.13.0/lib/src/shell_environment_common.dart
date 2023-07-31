import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/platform/platform.dart';
import 'package:process_run/src/shell_utils_common.dart';
//import 'package:process_run/shell.dart';
//import 'package:process_run/src/common/import.dart';
//import 'package:process_run/src/shell_utils.dart';
export 'package:process_run/shell.dart' show ShellEnvironment;

/// Shell environment ordered paths helper. Changes the PATH variable
class ShellEnvironmentPaths with ListMixin<String> {
  final ShellEnvironmentCore _environment;

  ShellEnvironmentPaths._(this._environment);

  List<String> get _paths {
    var pathVar = _environment[envPathKey];
    // Handle empty to black
    if (pathVar?.isNotEmpty ?? false) {
      return pathVar!.split(envPathSeparator);
    } else {
      return <String>[];
    }
  }

  set _paths(List<String> paths) {
    if (paths.isEmpty) {
      _environment.remove(envPathKey);
    } else {
      // remove duplicates
      paths = LinkedHashSet<String>.from(paths).toList();
      _environment[envPathKey] = paths.join(envPathSeparator);
    }
  }

  /// Prepend a path (i.e. higher in the hierarchy to handle a [which] resolution.
  void prepend(String path) => insert(0, path);

  @override
  int get length => _paths.length;

  @override
  String operator [](int index) {
    return _paths[index];
  }

  @override
  void operator []=(int index, String? value) {
    _paths = _paths..[index] = value!;
  }

  @override
  void add(String element) {
    // Needed for nnbd
    _paths = [..._paths, element];
  }

  @override
  set length(int newLength) {
    _paths = _paths..length = newLength;
  }

  @override
  void insert(int index, String element) {
    _paths = _paths..insert(index, element);
  }

  /// Merge an environment.
  ///
  /// the other object, paths are prepended.
  void merge(ShellEnvironmentPaths paths) {
    insertAll(0, paths);
  }

  @override
  int get hashCode => const ListEquality<Object?>().hash(this);

  @override
  bool operator ==(Object other) {
    if (other is ShellEnvironmentPaths) {
      return const ListEquality<Object>().equals(this, other);
    }
    return false;
  }

  @override
  String toString() => 'Path($length)';

  /// Overriden to handle concurrent modification and avoid duplicates.
  @override
  void addAll(Iterable<String> paths) {
    _paths = _paths..addAll(paths);
  }

  /// Overriden to handle concurrent modification and avoid duplicates.
  @override
  void insertAll(int index, Iterable<String> paths) {
    _paths = _paths..insertAll(index, paths);
  }
}

/// Shell environment aliases for executable
class ShellEnvironmentAliases with MapMixin<String, String> {
  final Map<String, String> _map;

  ShellEnvironmentAliases._([Map<String, String>? map])
      : _map = map ?? <String, String>{};

  /// the other object takes precedence, vars are added
  void merge(ShellEnvironmentAliases other) {
    addAll(other);
  }

  @override
  String? operator [](Object? key) => _map[key as String];

  @override
  void operator []=(String key, String value) => _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<String> get keys => _map.keys;

  @override
  String? remove(Object? key) => _map.remove(key);

  // Key hash is sufficient here
  @override
  int get hashCode => const ListEquality<Object?>().hash(keys.toList());

  @override
  bool operator ==(Object other) {
    if (other is ShellEnvironmentVars) {
      return const MapEquality<Object?, Object?>().equals(this, other);
    }
    return false;
  }

  @override
  String toString() => 'Aliases($length)';
}

/// Shell environment variables helper. Does not affect the PATH variable
class ShellEnvironmentVars with MapMixin<String, String> {
  final ShellEnvironmentCore _environment;

  ShellEnvironmentVars._(this._environment);

  /// Currently only the PATH key is ignored.
  bool _ignoreKey(Object? key) => key == envPathKey;

  @override
  String? operator [](Object? key) {
    if (_ignoreKey(key)) {
      return null;
    }
    return _environment[key as String];
  }

  @override
  void operator []=(String key, String value) {
    if (!_ignoreKey(key)) {
      _environment[key] = value;
    }
  }

  @override
  void clear() {
    removeWhere((key, value) => !_ignoreKey(key));
  }

  @override
  Iterable<String> get keys =>
      _environment.keys.where((key) => !_ignoreKey(key));

  @override
  String? remove(Object? key) {
    if (!_ignoreKey(key)) {
      return _environment.remove(key);
    }
    return null;
  }

  /// the other object takes precedence, vars are added
  void merge(ShellEnvironmentVars other) {
    addAll(other);
  }

  // Key hash is sufficient here
  @override
  int get hashCode => const ListEquality<Object?>().hash(keys.toList());

  @override
  bool operator ==(Object other) {
    if (other is ShellEnvironmentVars) {
      return const MapEquality<Object?, Object?>().equals(this, other);
    }
    return false;
  }

  @override
  String toString() => 'Vars($length)';
}

/// Shell modifiable helpers. should not be modified after being set.
abstract class ShellEnvironmentBase
    with MapMixin<String, String>
    implements ShellEnvironmentCore {
  /// The resulting _env
  final _env = <String, String>{};

  /// The vars but the PATH variable
  ShellEnvironmentVars? _vars;

  /// The vars but the PATH variable
  @override
  ShellEnvironmentVars get vars => _vars ??= ShellEnvironmentVars._(this);

  /// The PATH variable as a convenient list.
  ShellEnvironmentPaths? _paths;

  /// The PATH variable as a convenient list.
  @override
  ShellEnvironmentPaths get paths => _paths ??= ShellEnvironmentPaths._(this);

  /// The aliases.
  ShellEnvironmentAliases? _aliases;

  /// The aliases as convenient map.
  @override
  ShellEnvironmentAliases get aliases =>
      _aliases ??= ShellEnvironmentAliases._();

  /// Create an empty shell environment.
  ///
  /// Mainly used for testing as it is not easy to which environment variable
  /// are required.
  ShellEnvironmentBase.empty();

  /// Create a new shell environment from the current shellEnvironment.
  ///
  /// Defaults create a full parent environment.
  ///
  /// It is recommended that you apply the environment to a shell. But it can
  /// also be set globally (be aware of the potential effect on other part of
  /// your application) to [shellEnvironment]
  ShellEnvironmentBase.fromEnvironment({Map<String, String>? environment}) {
    environment ??= shellContext.shellEnvironment;

    // Copy vars/path
    _env.addAll(environment);
    // Copy alias
    if (environment is ShellEnvironment) {
      aliases.addAll(environment.aliases);
    }
  }

  /// From json.
  ///
  /// Mainly used for testing as it is not easy to which environment variable
  /// are required.
  ShellEnvironmentBase.fromJson(Map? map) {
    try {
      if (map != null) {
        var rawVars = map['vars'];
        if (rawVars is Map) {
          vars.addAll(rawVars.cast<String, String>());
        }
        var rawPaths = map['paths'];
        if (rawPaths is Iterable) {
          paths.addAll(rawPaths.cast<String>());
        }
        var rawAliases = map['aliases'];
        if (rawAliases is Map) {
          aliases.addAll(rawAliases.cast<String, String>());
        }
      }
    } catch (_) {
      // Silent crash
    }
  }

  @override
  String? operator [](Object? key) => _env[key as String];

  @override
  void operator []=(String key, String value) => _env[key] = value;

  @override
  void clear() {
    _env.clear();
  }

  @override
  Iterable<String> get keys => _env.keys;

  @override
  String? remove(Object? key) {
    return _env.remove(key);
  }

  /// Merge an environment.
  ///
  /// the other object takes precedence, vars are added and paths prepended
  @override
  void merge(ShellEnvironment other) {
    vars.merge(other.vars);
    paths.merge(other.paths);
    aliases.merge(other.aliases);
  }

  /// `paths` and `vars` key
  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'paths': paths, 'vars': vars, 'aliases': aliases};
  }

  @override
  int get hashCode => const ListEquality<Object?>().hash(paths);

  @override
  bool operator ==(Object other) {
    if (other is ShellEnvironment) {
      if (other.vars != vars) {
        return false;
      }
      if (other.paths != paths) {
        return false;
      }
      if (other.aliases != aliases) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => 'ShellEnvironment($paths, $vars, $aliases)';
}

/// The global environment
ShellEnvironment get shellEnvironment => shellContext.shellEnvironment;

/// Shell modifiable helpers. should not be modified after being set.
abstract class ShellEnvironmentCore with MapMixin<String, String> {
  /// The vars but the PATH variable
  ShellEnvironmentVars get vars;

  /// The PATH variable as a convenient list.
  ShellEnvironmentPaths get paths;

  /// The aliases as convenient map.
  ShellEnvironmentAliases get aliases;

  /// Merge an environment.
  ///
  /// the other object takes precedence, vars are added and paths prepended
  void merge(ShellEnvironment other);

  /// `paths` and `vars` key
  Map<String, dynamic> toJson();

  /*
  /// Create a new shell environment from the current shellEnvironment.
  ///
  /// Defaults create a full parent environment.
  ///
  /// It is recommended that you apply the environment to a shell. But it can
  /// also be set globally (be aware of the potential effect on other part of
  /// your application) to [shellEnvironment]
  factory ShellEnvironment({Map<String, String>? environment}) {
    return shellContext.newShellEnvironment(environment: environment);
  }
   */
}

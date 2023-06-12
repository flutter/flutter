import 'package:sqflite_common/src/utils.dart';
import 'package:sqflite_common/src/utils.dart' as impl;

/// helper to get the first int value in a query
/// Useful for COUNT(*) queries
int? firstIntValue(List<Map<String, Object?>> list) {
  if (list.isNotEmpty) {
    final firstRow = list.first;
    if (firstRow.isNotEmpty) {
      return parseInt(firstRow.values.first);
    }
  }
  return null;
}

/// Utility to encode a blob to allow blob query using
/// 'hex(blob_field) = ?', Sqlite.hex([1,2,3])
String hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (var part in bytes) {
    if (part & 0xff != part) {
      throw FormatException('$part is not a byte integer');
    }
    buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return buffer.toString().toUpperCase();
}

/// Deprecated since 1.1.7+.
///
/// Used internally.
@Deprecated('Used internally')
void Function()? get lockWarningCallback => impl.lockWarningCallback;

/// Deprecated since 1.1.7+.
@Deprecated('Used internally')
set lockWarningCallback(void Function()? callback) =>
    impl.lockWarningCallback = callback;

/// Deprecated since 1.1.7+.
@Deprecated('Used internally')
Duration? get lockWarningDuration => impl.lockWarningDuration;

/// Deprecated since 1.1.7+.
@Deprecated('Used internally')
set lockWarningDuration(Duration? duration) =>
    impl.lockWarningDuration = duration;

/// Change database lock behavior mechanism.
///
/// Default behavior is to print a message if a command hangs for more than
/// 10 seconds. Set en empty callback (not null) to prevent it from being
/// displayed.
void setLockWarningInfo({Duration? duration, void Function()? callback}) {
  impl.lockWarningDuration = duration ?? impl.lockWarningDuration;
  impl.lockWarningCallback = callback ?? impl.lockWarningCallback;
}

/// count column.
const sqlCountColumn = 'COUNT(*)';

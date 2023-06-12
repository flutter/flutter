import 'package:sqflite_example/src/common_import.dart';

/// Item states.
enum ItemState {
  /// test not run yet.
  none,

  /// test is running.
  running,

  /// test succeeded.
  success,

  /// test fails.
  failure
}

/// Menu item.
class Item {
  /// Menu item.
  Item(this.name);

  /// Menu item state.
  ItemState state = ItemState.running;

  /// Menu item name/
  String name;
}

/// Menu item implementation.
class SqfMenuItem extends Item {
  /// Menu item implementation.
  SqfMenuItem(String name, this.body, {this.summary}) : super(name) {
    state = ItemState.none;
  }

  /// Summary.
  String? summary;

  /// Run the item.
  Future run() {
    state = ItemState.running;
    return Future<void>.delayed(const Duration()).then((_) async {
      try {
        await body();
        state = ItemState.success;
      } catch (e) {
        state = ItemState.failure;
        rethrow;
      }
    });
  }

  /// Menu item body.
  final FutureOr Function() body;
}

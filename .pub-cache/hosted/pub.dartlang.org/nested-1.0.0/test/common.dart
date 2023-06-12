import 'package:flutter_test/flutter_test.dart';

Matcher matchesInOrder(List<Matcher> match) {
  return _MatchesInOrder(match);
}

class _SubMatcherResult {
  final bool matches;
  final Map<dynamic, dynamic> matchState;

  _SubMatcherResult(this.matches, this.matchState);
}

class _MatchesInOrder extends Matcher {
  const _MatchesInOrder(this.itemMatchers);

  final List<Matcher> itemMatchers;

  @override
  bool matches(dynamic expectation, Map<dynamic, dynamic> matchState) {
    var count = 0;

    List<Object> items;
    if (expectation is Finder) {
      items =
          expectation.evaluate().map((e) => e.widget).toList(growable: false);
    } else if (expectation is Iterable<Object>) {
      items = expectation.toList();
    } else {
      throw StateError('Expectation of unknown kind $expectation');
    }

    matchState['items'] = items;

    for (final item in items) {
      if (count >= itemMatchers.length) {
        return false;
      }

      final subMatcherState = <dynamic, dynamic>{};
      final matches = itemMatchers[count].matches(item, subMatcherState);
      matchState[count] = _SubMatcherResult(matches, subMatcherState);
      if (!matches) {
        return false;
      }

      count++;
    }
    return count == itemMatchers.length;
  }

  @override
  Description describe(Description description) {
    description.add('exactly ${itemMatchers.length} objects where:');
    var index = 0;
    for (final matcher in itemMatchers) {
      description.add('\n - item ${index + 1} is ');
      matcher.describe(description);
      index++;
    }
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    assert(item is Finder || item is Iterable<Object>);

    List<Object> items;
    if (item is Finder) {
      items = item.evaluate().toList(growable: false);
    } else if (item is Iterable<Object>) {
      items = item.toList();
    } else {
      throw StateError('Item of unexpected tyoe $item');
    }

    if (items.length != itemMatchers.length) {
      return mismatchDescription.add(
          'means ${items.length} were found but ${itemMatchers.length} were expected');
    }

    for (var i = 0; i < itemMatchers.length; i++) {
      final matcher = itemMatchers[i];

      final subMatcherResult = matchState[i] as _SubMatcherResult;
      if (!subMatcherResult.matches) {
        return matcher.describeMismatch(
          items[i],
          mismatchDescription..add('fails on item ${i + 1} which'),
          subMatcherResult.matchState,
          verbose,
        );
      }
    }

    return mismatchDescription;
  }
}

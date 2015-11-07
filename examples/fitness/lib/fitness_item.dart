// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

typedef void FitnessItemHandler(FitnessItem item);

// TODO(eseidel): This should be a constant on a SingleLineTile class
// https://www.google.com/design/spec/components/lists.html#lists-specs
const double kFitnessItemHeight = 48.0;

abstract class FitnessItem {
  FitnessItem.fromJson(Map json) : when = DateTime.parse(json['when']);

  FitnessItem({ this.when }) {
    assert(when != null);
  }
  final DateTime when;

  Map toJson() => { 'when' : when.toIso8601String() };

  // TODO(jackson): Internationalize
  String get displayDate => DateUtils.toDateString(when);

  FitnessItemRow toRow({ FitnessItemHandler onDismissed });
}

abstract class FitnessItemRow extends StatelessComponent {

  FitnessItemRow({ FitnessItem item, this.onDismissed })
   : this.item = item,
     super(key: new ValueKey<DateTime>(item.when)) {
    assert(onDismissed != null);
  }

  final FitnessItem item;
  final FitnessItemHandler onDismissed;

  Widget buildContent(BuildContext context);

  Widget build(BuildContext context) {
    return new Dismissable(
      onDismissed: () => onDismissed(item),
      child: new Container(
        height: kFitnessItemHeight,
        // TODO(eseidel): Padding top should be 16px for a single-line tile:
        // https://www.google.com/design/spec/components/lists.html#lists-specs
        padding: const EdgeDims.all(10.0),
        // TODO(eseidel): This line should be drawn by the list as it should
        // stay put even when the tile is dismissed!
        decoration: new BoxDecoration(
          border: new Border(
            bottom: new BorderSide(color: Theme.of(context).dividerColor)
          )
        ),
        child: buildContent(context)
      )
    );
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

final Set<String> interestingLabels = <String>{
  'BUILD',
  'LAYOUT',
  'UPDATING COMPOSITING BITS',
  'PAINT',
  'COMPOSITING',
  'FINALIZE TREE',
  '$Placeholder',
  '$CustomPaint',
  '$RenderCustomPaint',
};

Future<List<TimelineEvent>> fetchInterestingEvents() async {
  return (await fetchTimelineEvents()).where((TimelineEvent event) {
    return interestingLabels.contains(event.json!['name'])
        && event.json!['ph'] == 'B'; // "Begin" mark of events, vs E which is for the "End" mark of events.
  }).toList();
}

String eventToName(TimelineEvent event) => event.json!['name'] as String;

class TestRoot extends StatefulWidget {
  const TestRoot({ Key? key }) : super(key: key);

  static late final TestRootState state;

  @override
  State<TestRoot> createState() => TestRootState();
}

class TestRootState extends State<TestRoot> {
  @override
  void initState() {
    super.initState();
    TestRoot.state = this;
  }

  Widget _widget = const Placeholder();

  void updateWidget(Widget newWidget) {
    setState(() {
      _widget = newWidget;
    });
  }

  void rebuild() {
    setState(() {
      // no change, just force a rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}

Future<void> runFrame(VoidCallback callback) {
  final Future<void> result = SchedulerBinding.instance!.endOfFrame; // schedules a frame
  callback();
  return result;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initTimelineTests();
  test('Timeline', () async {
    // We don't have expectations around the first frame because there's a race around
    // the warm-up frame that we don't want to get involved in here.
    await runFrame(() { runApp(const TestRoot()); });
    await SchedulerBinding.instance!.endOfFrame;
    await fetchInterestingEvents();

    // The next few cases build the exact same tree so should have no effect.

    debugProfileBuildsEnabled = true;
    await runFrame(() { TestRoot.state.rebuild(); });
    expect(
      (await fetchInterestingEvents()).map<String>(eventToName),
      <String>['BUILD', 'LAYOUT', 'UPDATING COMPOSITING BITS', 'PAINT', 'COMPOSITING', 'FINALIZE TREE'],
    );
    debugProfileBuildsEnabled = false;

    debugProfileLayoutsEnabled = true;
    await runFrame(() { TestRoot.state.rebuild(); });
    expect(
      (await fetchInterestingEvents()).map<String>(eventToName),
      <String>['BUILD', 'LAYOUT', 'UPDATING COMPOSITING BITS', 'PAINT', 'COMPOSITING', 'FINALIZE TREE'],
    );
    debugProfileLayoutsEnabled = false;

    debugProfilePaintsEnabled = true;
    await runFrame(() { TestRoot.state.rebuild(); });
    expect(
      (await fetchInterestingEvents()).map<String>(eventToName),
      <String>['BUILD', 'LAYOUT', 'UPDATING COMPOSITING BITS', 'PAINT', 'COMPOSITING', 'FINALIZE TREE'],
    );
    debugProfilePaintsEnabled = false;


    // Now we replace the widgets each time to cause a rebuild.

    List<TimelineEvent> events;
    Map<String, String> args;

    debugProfileBuildsEnabled = true;
    await runFrame(() { TestRoot.state.updateWidget(Placeholder(key: UniqueKey(), color: const Color(0xFFFFFFFF))); });
    events = await fetchInterestingEvents();
    expect(
      events.map<String>(eventToName),
      <String>['BUILD', 'Placeholder', 'CustomPaint', 'LAYOUT', 'UPDATING COMPOSITING BITS', 'PAINT', 'COMPOSITING', 'FINALIZE TREE'],
    );
    args = (events.where((TimelineEvent event) => event.json!['name'] == '$Placeholder').single.json!['args'] as Map<String, Object?>).cast<String, String>();
    expect(args['color'], 'Color(0xffffffff)');
    debugProfileBuildsEnabled = false;

    debugProfileLayoutsEnabled = true;
    await runFrame(() { TestRoot.state.updateWidget(Placeholder(key: UniqueKey())); });
    events = await fetchInterestingEvents();
    expect(
      events.map<String>(eventToName),
      <String>['BUILD', 'LAYOUT', 'RenderCustomPaint', 'UPDATING COMPOSITING BITS', 'PAINT', 'COMPOSITING', 'FINALIZE TREE'],
    );
    args = (events.where((TimelineEvent event) => event.json!['name'] == '$RenderCustomPaint').single.json!['args'] as Map<String, Object?>).cast<String, String>();
    expect(args['creator'], startsWith('CustomPaint'));
    expect(args['creator'], contains('Placeholder'));
    expect(args['foregroundPainter'], startsWith('_PlaceholderPainter#'));
    debugProfileLayoutsEnabled = false;

    debugProfilePaintsEnabled = true;
    await runFrame(() { TestRoot.state.updateWidget(Placeholder(key: UniqueKey())); });
    events = await fetchInterestingEvents();
    expect(
      events.map<String>(eventToName),
      <String>['BUILD', 'LAYOUT', 'UPDATING COMPOSITING BITS', 'PAINT', 'RenderCustomPaint', 'COMPOSITING', 'FINALIZE TREE'],
    );
    args = (events.where((TimelineEvent event) => event.json!['name'] == '$RenderCustomPaint').single.json!['args'] as Map<String, Object?>).cast<String, String>();
    expect(args['creator'], startsWith('CustomPaint'));
    expect(args['creator'], contains('Placeholder'));
    expect(args['foregroundPainter'], startsWith('_PlaceholderPainter#'));
    debugProfilePaintsEnabled = false;

  }, skip: isBrowser); // [intended] uses dart:isolate and io.
}

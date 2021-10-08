// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

/// Display the current conductor state
class ConductorStatus extends StatefulWidget {
  const ConductorStatus({
    Key? key,
    this.releaseState,
    required this.stateFilePath,
  }) : super(key: key);

  final pb.ConductorState? releaseState;
  final String stateFilePath;

  @override
  ConductorStatusState createState() => ConductorStatusState();
}

class ConductorStatusState extends State<ConductorStatus> {
  /// Returns the conductor state in a Map<K, V> format for the desktop app to consume.
  Map<String, Object> presentStateDesktop(pb.ConductorState state) {
    final List<Map<String, Object>> engineCherrypicks = <Map<String, Object>>[];
    for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
      engineCherrypicks
          .add(<String, Object>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
    }

    final List<Map<String, Object>> frameworkCherrypicks = <Map<String, Object>>[];
    for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
      frameworkCherrypicks
          .add(<String, Object>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
    }

    return <String, Object>{
      'Conductor Version': state.conductorVersion,
      'Release Channel': state.releaseChannel,
      'Release Version': state.releaseVersion,
      'Release Started at': DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt()).toString(),
      'Release Updated at': DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt()).toString(),
      'Engine Candidate Branch': state.engine.candidateBranch,
      'Engine Starting Git HEAD': state.engine.startingGitHead,
      'Engine Current Git HEAD': state.engine.currentGitHead,
      'Engine Path to Checkout': state.engine.checkoutPath,
      'Engine Post LUCI Dashboard': luciConsoleLink(state.releaseChannel, 'engine'),
      'Engine Cherrypicks': engineCherrypicks,
      'Dart SDK Revision': state.engine.dartRevision,
      'Framework Candidate Branch': state.framework.candidateBranch,
      'Framework Starting Git HEAD': state.framework.startingGitHead,
      'Framework Current Git HEAD': state.framework.currentGitHead,
      'Framework Path to Checkout': state.framework.checkoutPath,
      'Framework Post LUCI Dashboard': luciConsoleLink(state.releaseChannel, 'flutter'),
      'Framework Cherrypicks': frameworkCherrypicks,
      'Current Phase': state.currentPhase,
    };
  }

  @override
  Widget build(BuildContext context) {
    late final Map<String, Object> currentStatus;
    if (widget.releaseState != null) {
      currentStatus = presentStateDesktop(widget.releaseState!);
    }

    final List<String> statusLookup = <String>[
      'Conductor Version',
      'Release Channel',
      'Release Version',
      'Release Started at',
      'Release Updated at',
      'Dart SDK Revision',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.releaseState == null) ...<Widget>[
          SelectableText('No persistent state file found at ${widget.stateFilePath}')
        ] else ...<Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: FixedColumnWidth(200.0),
                  1: FixedColumnWidth(400.0),
                },
                children: <TableRow>[
                  for (String status in statusLookup)
                    TableRow(
                      children: <Widget>[
                        Text('$status:'),
                        SelectableText(currentStatus[status]! as String),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20.0),
              Wrap(
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      CherrypickTable(engineOrFramework: 'engine', currentStatus: currentStatus),
                    ],
                  ),
                  const SizedBox(width: 20.0),
                  Column(
                    children: <Widget>[
                      CherrypickTable(engineOrFramework: 'framework', currentStatus: currentStatus),
                    ],
                  ),
                ],
              )
            ],
          )
        ],
      ],
    );
  }
}

class StatusTooltip extends StatefulWidget {
  const StatusTooltip({
    Key? key,
    this.engineOrFramework,
  }) : super(key: key);

  final String? engineOrFramework;

  @override
  State<StatusTooltip> createState() => _StatusTooltipState();
}

/// Displays explanations for each status type as a tooltip
class _StatusTooltipState extends State<StatusTooltip> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text('Status'),
        const SizedBox(width: 10.0),
        Tooltip(
          padding: const EdgeInsets.all(10.0),
          message: '''
PENDING: The cherrypick has not yet been applied.
PENDING_WITH_CONFLICT: The cherrypick has not been applied and will require manual resolution.
COMPLETED: The cherrypick has been successfully applied to the local checkout.
ABANDONED: The cherrypick will NOT be applied in this release.''',
          child: Icon(
            Icons.info,
            size: 16.0,
            key: Key('${widget.engineOrFramework}ConductorStatusTooltip'),
          ),
        ),
      ],
    );
  }
}

/// Shows the engine and framework cherrypicks' SHA in two separate tables with their corresponding status.
class CherrypickTable extends StatefulWidget {
  const CherrypickTable({
    Key? key,
    required this.engineOrFramework,
    required this.currentStatus,
  }) : super(key: key);

  final String engineOrFramework;
  final Map<String, Object> currentStatus;

  @override
  CherrypickTableState createState() => CherrypickTableState();
}

class CherrypickTableState extends State<CherrypickTable> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object>> cherrypicks = widget.engineOrFramework == 'engine'
        ? widget.currentStatus['Engine Cherrypicks']! as List<Map<String, Object>>
        : widget.currentStatus['Framework Cherrypicks']! as List<Map<String, Object>>;

    return DataTable(
      dataRowHeight: 30.0,
      headingRowHeight: 30.0,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      columns: <DataColumn>[
        DataColumn(label: Text('${widget.engineOrFramework == 'engine' ? 'Engine' : 'Framework'} Cherrypicks')),
        DataColumn(label: StatusTooltip(engineOrFramework: widget.engineOrFramework)),
      ],
      rows: cherrypicks.map((Map<String, Object> cherrypick) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              SelectableText(cherrypick['trunkRevision']! as String),
            ),
            DataCell(
              SelectableText(cherrypick['state']! as String),
            ),
          ],
        );
      }).toList(),
    );
  }
}

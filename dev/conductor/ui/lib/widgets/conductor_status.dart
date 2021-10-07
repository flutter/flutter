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
  @override
  Widget build(BuildContext context) {
    late final Map<String, Object> currentStatus;
    if (widget.releaseState != null) {
      currentStatus = presentStateDesktop(widget.releaseState!);
    }

    final List<String> statusHeaderTitles = <String>[
      'Conductor version:',
      'Release channel:',
      'Release version:',
      'Release started at:',
      'Release updated at:',
      'Dart SDK evision:',
    ];
    final List<String> statusHeaderDataNames = <String>[
      'conductorVersion',
      'releaseChannel',
      'releaseVersion',
      'startedAt',
      'updatedAt',
      'dartRevision',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.releaseState != null) ...<Widget>[
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
                  for (int i = 0; i < statusHeaderTitles.length; i++)
                    TableRow(
                      children: <Widget>[
                        Text(statusHeaderTitles[i]),
                        SelectableText(currentStatus[statusHeaderDataNames[i]]! as String),
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
        ] else ...<Widget>[
          SelectableText('No persistent state file found at ${widget.stateFilePath}'),
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
            size: 20.0,
            key: widget.engineOrFramework == 'engine' ? const Key('conductorStatusTooltip1') : null,
          ),
        ),
      ],
    );
  }
}

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
        ? widget.currentStatus['engineCherrypicks']! as List<Map<String, Object>>
        : widget.currentStatus['frameworkCherrypicks']! as List<Map<String, Object>>;

    return DataTable(
      dataRowHeight: 30.0,
      headingRowHeight: 30.0,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      columns: <DataColumn>[
        DataColumn(label: Text('${widget.engineOrFramework == 'engine' ? 'Engine' : 'Framework'} Cherrypicks')),
        DataColumn(
          label: StatusTooltip(engineOrFramework: widget.engineOrFramework),
        ),
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

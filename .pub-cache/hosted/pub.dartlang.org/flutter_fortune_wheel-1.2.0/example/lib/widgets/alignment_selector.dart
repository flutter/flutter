import 'package:flutter/material.dart';

typedef AlignmentCallback = void Function(Alignment?);

class AlignmentSelector extends StatelessWidget {
  final Alignment selected;
  final AlignmentCallback onChanged;

  const AlignmentSelector({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignments = <Alignment, String>{
      Alignment.topCenter: 'top center',
      Alignment.centerRight: 'center right',
      Alignment.bottomCenter: 'bottom center',
      Alignment.centerLeft: 'center left',
      Alignment.center: 'center',
    };

    return DropdownButtonFormField<Alignment>(
      decoration: InputDecoration(
        labelText: 'Indicator Alignment',
      ),
      value: selected,
      items: [
        for (final entry in alignments.entries)
          DropdownMenuItem(
            child: Text(entry.value),
            value: entry.key,
          )
      ],
      onChanged: onChanged,
    );
  }
}

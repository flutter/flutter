import 'package:flutter/material.dart';

typedef void OnChanged(List<FilterChipData> data);

class MultipleFilterChipPicker extends StatefulWidget {
  final List<FilterChipData>? filterChips; // List of filter chips
  final OnChanged? onChanged; // Callback when filter chips are changed
  final bool? isEnabled; // Whether the filter chips are enabled
  final bool? isSelected; // Whether the filter chips are selected
  final Widget? avatar; // Avatar widget for filter chips
  final TextStyle? labelStyle; // Style for the filter chip labels
  final double? pressElevation; // Elevation when filter chip is pressed
  final Color? disabledColor; // Color for disabled filter chips
  final Color? selectedColor; // Color for selected filter chips
  final String? tooltip; // Tooltip for filter chips
  final ShapeBorder? avatarBorder; // Border shape for filter chip avatars
  final BorderSide? side; // Border side for filter chips
  final Clip? clipBehavior; // Clip behavior for filter chips
  final FocusNode? focusNode; // Focus node for filter chips
  final bool? autofocus; // Whether the filter chips should autofocus
  final Color? backgroundColor; // Background color for filter chips
  final EdgeInsetsGeometry? labelPadding; // Padding for filter chip labels
  final VisualDensity? visualDensity; // Visual density for filter chips
  final Color? surfaceTintColor; // Surface tint color for filter chips
  final IconThemeData? iconTheme; // Icon theme for filter chips
  final Color? selectedShadowColor; // Shadow color for selected filter chips
  final bool?
      showCheckmark; // Whether to show a checkmark for selected filter chips
  final Color?
      checkmarkColor; // Color for the checkmark on selected filter chips
  final EdgeInsetsGeometry? padding; // Padding for filter chips
  final OutlinedBorder? shape; // Shape for filter chips
  final bool?
      isSelectedShadowColor; // Whether to use shadow color for selected filter chips
  final double? filterChipSpacing; //Spacing between each filter chip
  MultipleFilterChipPicker({
    Key? key,
    required this.filterChips,
    required this.onChanged,
    this.avatar,
    this.autofocus,
      this.avatarBorder,
    this.backgroundColor,
    this.checkmarkColor,
    this.clipBehavior,
    this.disabledColor,
    this.focusNode,
    this.iconTheme,
    this.isEnabled,
    this.isSelected,
    this.isSelectedShadowColor,
    this.labelPadding,
    this.labelStyle,
    this.padding,
    this.pressElevation,
    this.selectedColor,
    this.selectedShadowColor,
    this.shape,
    this.showCheckmark,
    this.side,
    this.surfaceTintColor,
    this.tooltip,
    this.visualDensity,
    this.filterChipSpacing,
  }) : super(key: key);

  @override
  _MultipleFilterChipPickerState createState() =>
      _MultipleFilterChipPickerState();
}

class _MultipleFilterChipPickerState extends State<MultipleFilterChipPicker> {
  List<FilterChipData> filteredChipData = []; // Selected filter chips

  void _onChipSelected(FilterChipData chipData, bool selected) {
    setState(() {
      chipData.isSelected = selected;
      if (chipData.isSelected) {
        filteredChipData.add(chipData);
      } else {
        filteredChipData.removeWhere((item) => item.id == chipData.id);
      }
    });
    widget.onChanged?.call(filteredChipData);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.filterChipSpacing ?? 8.0,
      children: widget.filterChips?.map((chipData) {
            return FilterChip(
              label: Text(chipData.label), // Label for the filter chip
              selected:
                  chipData.isSelected, // Whether the filter chip is selected
              onSelected: (bool selected) {
                _onChipSelected(chipData, selected);
              },
              key: widget.key,
              avatar: widget.avatar, // Avatar widget for the filter chip
              labelStyle: widget.labelStyle, // Style for the filter chip label
              labelPadding: widget.labelPadding ??
                  EdgeInsets.all(0.0), // Padding for the filter chip label
              pressElevation: widget
                  .pressElevation, // Elevation when filter chip is pressed
              disabledColor:
                  widget.disabledColor, // Color for disabled filter chips
              selectedColor:
                  widget.selectedColor, // Color for selected filter chips
              tooltip: widget.tooltip, // Tooltip for filter chips
              side: widget.side, // Border side for filter chips
              shape: widget.shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ), // Shape for filter chips
              focusNode: widget.focusNode, // Focus node for filter chips
              backgroundColor:
                  widget.backgroundColor, // Background color for filter chips
              padding: widget.padding ??
                  EdgeInsets.all(8.0), // Padding for filter chips
              visualDensity:
                  widget.visualDensity, // Visual density for filter chips
              surfaceTintColor: widget
                  .surfaceTintColor, // Surface tint color for filter chips
              iconTheme: widget.iconTheme, // Icon theme for filter chips
              selectedShadowColor: widget
                  .selectedShadowColor, // Shadow color for selected filter chips
              showCheckmark: widget
                  .showCheckmark, // Whether to show a checkmark for selected filter chips
              checkmarkColor: widget
                  .checkmarkColor, // Color for the checkmark on selected filter chips
              avatarBorder: widget.avatarBorder ??
                  CircleBorder(), // Border shape for filter chip avatars
            );
          }).toList() ??
          [], // Convert filter chip data to filter chip widgets
    );
  }
}

class FilterChipData {
  final String label; // Label for the filter chip
  bool isSelected; // Whether the filter chip is selected
  static int _idCounter = 0;
  int id = 0;

  FilterChipData(this.label, this.isSelected)
      : id = getNextId(); // Assign a unique ID to each filter chip data

  static int getNextId() {
    _idCounter++; // Increment the ID counter
    return _idCounter;
  }
}

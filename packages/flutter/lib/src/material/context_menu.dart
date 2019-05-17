import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/editable_text.dart';
import 'debug.dart';
import 'material_localizations.dart';
import 'popup_menu.dart';
import 'theme.dart';

/// TODO
RelativeRect getLocalPosition({
  @required Offset globalPosition,
  @required BuildContext context
}) {
  return RelativeRect.fromSize(globalPosition & Size.zero, MediaQuery.of(context).size);
}

/// TODO
class _MaterialTextContextMenuControls extends TextContextMenuControls {

  @override
  ModalRoute<dynamic> buildRoute({
    @required BuildContext context,
    @required Offset globalPosition,
    @required EditableTextState editableText,
  }) {
    assert(debugCheckHasMaterialLocalizations(context));

    final TextSelection selection = editableText.textEditingValue.selection;
    final TextPosition textPosition = editableText.renderEditable.getPositionForPoint(globalPosition);
    final bool withinSelection = selection.start <= textPosition.offset
      && selection.end > textPosition.offset;

    final List<PopupMenuEntry<dynamic>> items = <PopupMenuEntry<dynamic>>[
      PopupMenuItem<dynamic>(
        child: Text('Selection $withinSelection'),
      ),
    ];

    String label;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        label = MaterialLocalizations.of(context)?.popupMenuLabel;
    }

    const double elevation = 8.0;
    return createPopupMenuRoute<dynamic>(
      position: getLocalPosition(globalPosition: globalPosition, context: context),
      items: items,
      elevation: elevation,
      semanticLabel: label,
      theme: Theme.of(context, shadowThemeOnly: true),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
  }
}

/// TODO
final _MaterialTextContextMenuControls materialTextContextMenuControls
  = _MaterialTextContextMenuControls();
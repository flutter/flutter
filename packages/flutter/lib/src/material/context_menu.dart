import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/context_menu.dart';
import '../widgets/editable_text.dart';
import 'debug.dart';
import 'material_localizations.dart';
import 'popup_menu.dart';
import 'theme.dart';

/// TODO
class _MaterialTextContextMenuControls extends TextContextMenuControls {

  List<PopupMenuEntry<ContextMenuAction>> _buildItems({
    @required EditableTextState editableText,
  }) {
    final TextSelectionControls controls = editableText.widget.selectionControls;
    return <PopupMenuEntry<ContextMenuAction>>[
      PopupMenuItem<ContextMenuAction>(
        child: const Text('Cut'),
        enabled: controls.canCut(editableText),
        value: (_) async => controls.handleCut(editableText),
      ),
      PopupMenuItem<ContextMenuAction>(
        child: const Text('Copy'),
        enabled: controls.canCopy(editableText),
        value: (_) async => controls.handleCopy(editableText),
      ),
      PopupMenuItem<ContextMenuAction>(
        child: const Text('Paste'),
        enabled: controls.canPaste(editableText),
        value: (_) async => controls.handlePaste(editableText),
      ),
      PopupMenuItem<ContextMenuAction>(
        child: const Text('Select all'),
        enabled: controls.canSelectAll(editableText),
        value: (_) async => controls.handleSelectAll(editableText),
      ),
    ];
  }

  @override
  ModalRoute<ContextMenuAction> buildRoute({
    @required BuildContext context,
    @required Offset globalPosition,
    @required EditableTextState editableText,
  }) {
    assert(debugCheckHasMaterialLocalizations(context));

    String label;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        label = MaterialLocalizations.of(context)?.popupMenuLabel;
    }

    const double elevation = 8.0;
    return createPopupMenuRoute<ContextMenuAction>(
      position: getLocalPosition(globalPosition: globalPosition, context: context),
      items: _buildItems(editableText: editableText),
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
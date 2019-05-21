import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/context_menu.dart';
import 'debug.dart';
import 'material_localizations.dart';
import 'popup_menu.dart';
import 'theme.dart';

/// TODO
class _MaterialRenderContextMenu extends RenderContextMenu {
  List<PopupMenuEntry<ContextMenuEntry>> _parseEntries(ContextMenuContent content) {
    final List<PopupMenuEntry<ContextMenuEntry>> renderEntries =
      <PopupMenuEntry<ContextMenuEntry>>[];
    for (ContextMenuEntry contentEntry in content.entries) {
      if (contentEntry is ContextMenuItem) {
        renderEntries.add(PopupMenuItem<ContextMenuEntry>(
          child: Text(contentEntry.text),
          enabled: contentEntry.enabled,
          value: contentEntry,
        ));
      } else if (contentEntry is ContextMenuDivider) {
        renderEntries.add(const PopupMenuDivider());
      } else {
        print('Unrecognized entry $contentEntry');
      }
    }
    return renderEntries;
  }

  @override
  Future<Action> showMenu({
    @required ContextMenuContent content,
    @required Offset globalPosition,
    @required BuildContext context,
  }) async {
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
    final ModalRoute<ContextMenuEntry> route = createPopupMenuRoute<ContextMenuEntry>(
      position: RelativeRect.fromSize(globalPosition & Size.zero, MediaQuery.of(context).size),
      items: _parseEntries(content),
      elevation: elevation,
      semanticLabel: label,
      theme: Theme.of(context, shadowThemeOnly: true),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );

    final ContextMenuEntry result = await Navigator.push<ContextMenuEntry>(
      context,
      route,
    );
    return result?.value;
  }
}

/// TODO
final _MaterialRenderContextMenu materialRenderContextMenu = _MaterialRenderContextMenu();

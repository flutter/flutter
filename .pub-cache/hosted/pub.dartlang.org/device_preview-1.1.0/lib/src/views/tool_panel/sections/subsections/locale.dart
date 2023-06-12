import 'package:device_preview/device_preview.dart';
import 'package:device_preview/src/state/store.dart';
import 'package:device_preview/src/views/tool_panel/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// A page for picking a simulated locale.
class LocalePicker extends StatefulWidget {
  /// Create a new page for picking a simulated locale.
  const LocalePicker({
    Key? key,
  }) : super(key: key);

  @override
  _LocalePickerState createState() => _LocalePickerState();
}

class _LocalePickerState extends State<LocalePicker> {
  String filter = '';
  @override
  Widget build(BuildContext context) {
    final locales = context.select(
      (DevicePreviewStore store) => store.locales,
    );
    final selectedLocale = context.select(
      (DevicePreviewStore store) => store.data.locale,
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Locale'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Column(
          children: [
            ToolbarSearchField(
              hintText: 'Search by locale name or code',
              text: filter,
              onTextChanged: (value) => setState(() => filter = value),
            ),
            Expanded(
              child: ListView(
                children: locales.where(
                  (locale) {
                    final filter = this.filter.trim().toLowerCase();
                    return filter.isEmpty ||
                        locale.name.toLowerCase().contains(filter) ||
                        locale.code.toLowerCase().contains(filter);
                  },
                ).map(
                  (locale) {
                    final isSelected = locale.code == selectedLocale;
                    return ListTile(
                      onTap: !isSelected
                          ? () {
                              final store = context.read<DevicePreviewStore>();
                              store.data =
                                  store.data.copyWith(locale: locale.code);
                              Navigator.pop(context);
                            }
                          : null,
                      title: Text(
                        locale.name,
                      ),
                      subtitle: Text(
                        locale.code,
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

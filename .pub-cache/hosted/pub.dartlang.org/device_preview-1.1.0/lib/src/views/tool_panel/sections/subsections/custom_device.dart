part of 'device_model.dart';

Future<dynamic> _openDeviceSizeAdjustDialog({
  required BuildContext context,
  required double initialValue,
  double min = 128,
  double max = 2688,
  String? title,
}) {
  var formKey = GlobalKey<FormState>();
  return showDialog(
    context: context,
    builder: (context) {
      var navigator = Navigator.of(context);
      var textEditingController =
          TextEditingController(text: initialValue.toString());
      textEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textEditingController.text.length,
      );

      return AlertDialog(
        title: Text(title ?? 'Input Value'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            onSaved: (String? value) => navigator.pop(double.tryParse(value!)),
            keyboardType: TextInputType.number,
            validator: (value) {
              var parsedDouble = 0.0;
              try {
                parsedDouble = double.tryParse(value!)!;
              } catch (e) {
                return 'Please input only numbers';
              }
              bool inBetweenMinMax = parsedDouble >= min && parsedDouble <= max;
              if (!inBetweenMinMax) {
                return 'Invalid range. ($min ~ $max)';
              }
              return null;
            },
            controller: textEditingController,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: navigator.pop,
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
              }
            },
          ),
        ],
      );
    },
  );
}

/// Create a set of tiles to fine tune a custom device.
List<Widget> buildCustomDeviceTiles(BuildContext context) {
  final customDevice = context.select(
    (DevicePreviewStore store) => store.data.customDevice,
  );
  return [
    ToolPanelSection(
      title: 'Screen',
      children: [
        if (customDevice != null) ...[
          ListTile(
            title: const Text('Width'),
            trailing: GestureDetector(
              onTap: () {
                _openDeviceSizeAdjustDialog(
                  context: context,
                  initialValue: customDevice.screenSize.width,
                  title: 'Change Width',
                ).then((value) {
                  if (value == null) return;
                  final store = context.read<DevicePreviewStore>();
                  store.updateCustomDevice(
                    customDevice.copyWith(
                      screenSize: Size(value, customDevice.screenSize.height),
                    ),
                  );
                });
              },
              child: Text(customDevice.screenSize.width.toString()),
            ),
            subtitle: Slider(
              value: customDevice.screenSize.width,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    screenSize: Size(v, customDevice.screenSize.height),
                  ),
                );
              },
              min: 128,
              max: 2688,
              divisions: 20,
            ),
          ),
          ListTile(
            title: const Text('Height'),
            trailing: GestureDetector(
              child: Text(customDevice.screenSize.height.toString()),
              onTap: () {
                _openDeviceSizeAdjustDialog(
                  context: context,
                  initialValue: customDevice.screenSize.height,
                  title: 'Change Height',
                ).then((value) {
                  if (value == null) return;
                  final store = context.read<DevicePreviewStore>();
                  store.updateCustomDevice(
                    customDevice.copyWith(
                      screenSize: Size(customDevice.screenSize.width, value),
                    ),
                  );
                });
              },
            ),
            subtitle: Slider(
              value: customDevice.screenSize.height,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    screenSize: Size(customDevice.screenSize.width, v),
                  ),
                );
              },
              min: 128,
              max: 2688,
              divisions: 20,
            ),
          ),
          ListTile(
            title: const Text('Pixel ratio'),
            trailing: Text(customDevice.pixelRatio.toString()),
            subtitle: Slider(
              value: customDevice.pixelRatio,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    pixelRatio: v,
                  ),
                );
              },
              min: 1,
              max: 4,
              divisions: 3,
            ),
          ),
        ],
      ],
    ),
    ToolPanelSection(
      title: 'Safe areas',
      children: [
        if (customDevice != null) ...[
          ListTile(
            title: const Text('Left'),
            trailing: Text(customDevice.safeAreas.left.toString()),
            subtitle: Slider(
              value: customDevice.safeAreas.left,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    safeAreas: customDevice.safeAreas.copyWith(left: v),
                  ),
                );
              },
              min: 0,
              max: 128,
              divisions: 8,
            ),
          ),
          ListTile(
            title: const Text('Top'),
            trailing: Text(customDevice.safeAreas.top.toString()),
            subtitle: Slider(
              value: customDevice.safeAreas.top,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    safeAreas: customDevice.safeAreas.copyWith(top: v),
                  ),
                );
              },
              min: 0,
              max: 128,
              divisions: 8,
            ),
          ),
          ListTile(
            title: const Text('Right'),
            trailing: Text(customDevice.safeAreas.right.toString()),
            subtitle: Slider(
              value: customDevice.safeAreas.right,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    safeAreas: customDevice.safeAreas.copyWith(right: v),
                  ),
                );
              },
              min: 0,
              max: 128,
              divisions: 8,
            ),
          ),
          ListTile(
            title: const Text('Bottom'),
            trailing: Text(customDevice.safeAreas.bottom.toString()),
            subtitle: Slider(
              value: customDevice.safeAreas.bottom,
              onChanged: (v) {
                final store = context.read<DevicePreviewStore>();
                store.updateCustomDevice(
                  customDevice.copyWith(
                    safeAreas: customDevice.safeAreas.copyWith(bottom: v),
                  ),
                );
              },
              min: 0,
              max: 128,
              divisions: 8,
            ),
          ),
        ],
      ],
    ),
    ToolPanelSection(
      title: 'System',
      children: [
        ..._allPlatforms.map(
          (p) => ListTile(
            leading: TargetPlatformIcon(platform: p),
            title: Text(
              describeEnum(p),
            ),
            onTap: () {
              final store = context.read<DevicePreviewStore>();
              if (customDevice != null) {
                store.updateCustomDevice(
                  customDevice.copyWith(
                    platform: p,
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
    ToolPanelSection(
      title: 'Form factor',
      children: [
        ..._allDeviceTypes.map(
          (type) => ListTile(
            leading: DeviceTypeIcon(
              type: type,
            ),
            title: Text(
              describeEnum(type),
            ),
            onTap: () {
              final store = context.read<DevicePreviewStore>();
              if (customDevice != null) {
                store.updateCustomDevice(
                  customDevice.copyWith(
                    type: type,
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
  ];
}

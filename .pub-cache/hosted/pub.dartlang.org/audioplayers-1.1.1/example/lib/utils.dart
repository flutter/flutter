import 'package:audioplayers_example/components/dlg.dart';
import 'package:flutter/material.dart';

extension StateExt<T extends StatefulWidget> on State<T> {
  void toast(String message, {Key? textKey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, key: textKey),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void simpleDialog(String message, [String action = 'Ok']) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDlg(message: message, action: action);
      },
    );
  }

  void dialog(List<Widget> children) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dlg(children: children);
      },
    );
  }
}

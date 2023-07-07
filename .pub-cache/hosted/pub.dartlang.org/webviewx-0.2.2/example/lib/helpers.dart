import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

/// This dialog will basically show up right on top of the webview.
///
/// AlertDialog is a widget, so it needs to be wrapped in `WebViewAware`, in order
/// to be able to interact (on web) with it.
///
/// Read the `Readme.md` for more info.
void showAlertDialog(String content, BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => WebViewAware(
      child: AlertDialog(
        content: Text(content),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

void showSnackBar(String content, BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(content),
        duration: const Duration(seconds: 1),
      ),
    );
}

Widget createButton({
  VoidCallback? onTap,
  required String text,
}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    ),
    child: Text(text),
  );
}

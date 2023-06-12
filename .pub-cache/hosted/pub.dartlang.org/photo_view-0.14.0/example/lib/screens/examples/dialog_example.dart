import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view_example/screens/common/app_bar.dart';

class DialogExample extends StatefulWidget {
  @override
  _DialogExampleState createState() => _DialogExampleState();
}

class _DialogExampleState extends State<DialogExample> {
  void openDialog(BuildContext context) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              child: PhotoView(
                tightMode: true,
                imageProvider: const AssetImage("assets/large-image.jpg"),
                heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
              ),
            ),
          );
        },
      );

  void openBottomSheet(BuildContext context) => showBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        shape: const ContinuousRectangleBorder(),
        builder: (BuildContext context) {
          return PhotoViewGestureDetectorScope(
            axis: Axis.vertical,
            child: PhotoView(
              backgroundDecoration: BoxDecoration(
                color: Colors.black.withAlpha(240),
              ),
              imageProvider: const AssetImage("assets/large-image.jpg"),
              heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
            ),
          );
        },
      );

  void openBottomSheetModal(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const ContinuousRectangleBorder(),
        builder: (BuildContext context) {
          return SafeArea(
            child: Container(
              height: 250,
              child: PhotoViewGestureDetectorScope(
                axis: Axis.vertical,
                child: PhotoView(
                  tightMode: true,
                  imageProvider: const AssetImage("assets/large-image.jpg"),
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return ExampleAppBarLayout(
      title: "Dialogs integration",
      showGoBack: true,
      child: Builder(
        builder: (context) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(color: Colors.red),
            ),
            ElevatedButton(
              child: const Text("Dialog"),
              onPressed: () => openDialog(context),
            ),
            const Divider(),
            ElevatedButton(
              child: const Text("Bottom sheet"),
              onPressed: () => openBottomSheet(context),
            ),
            const Divider(),
            ElevatedButton(
              child: const Text("Bottom sheet tight mode"),
              onPressed: () => openBottomSheetModal(context),
            ),
          ],
        ),
      ),
    );
  }
}

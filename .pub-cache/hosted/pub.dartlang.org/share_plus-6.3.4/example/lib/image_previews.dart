import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Widget for displaying a preview of images
class ImagePreviews extends StatelessWidget {
  /// The image paths of the displayed images
  final List<String> imagePaths;

  /// Callback when an image should be removed
  final Function(int)? onDelete;

  /// Creates a widget for preview of images. [imagePaths] can not be empty
  /// and all contained paths need to be non empty.
  const ImagePreviews(this.imagePaths, {Key? key, this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageWidgets = <Widget>[];
    for (var i = 0; i < imagePaths.length; i++) {
      imageWidgets.add(_ImagePreview(
        imagePaths[i],
        onDelete: onDelete != null ? () => onDelete!(i) : null,
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: imageWidgets),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onDelete;

  const _ImagePreview(this.imagePath, {Key? key, this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 200,
            ),
            child: kIsWeb ? Image.network(imagePath) : Image.file(imageFile),
          ),
          Positioned(
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: onDelete,
                  child: const Icon(Icons.delete)),
            ),
          ),
        ],
      ),
    );
  }
}

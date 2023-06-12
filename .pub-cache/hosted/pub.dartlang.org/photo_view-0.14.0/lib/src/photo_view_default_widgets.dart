import 'package:flutter/material.dart';

class PhotoViewDefaultError extends StatelessWidget {
  const PhotoViewDefaultError({Key? key, required this.decoration})
      : super(key: key);

  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: 40.0,
        ),
      ),
    );
  }
}

class PhotoViewDefaultLoading extends StatelessWidget {
  const PhotoViewDefaultLoading({Key? key, this.event}) : super(key: key);

  final ImageChunkEvent? event;

  @override
  Widget build(BuildContext context) {
    final expectedBytes = event?.expectedTotalBytes;
    final loadedBytes = event?.cumulativeBytesLoaded;
    final value = loadedBytes != null && expectedBytes != null
        ? loadedBytes / expectedBytes
        : null;

    return Center(
      child: Container(
        width: 20.0,
        height: 20.0,
        child: CircularProgressIndicator(value: value),
      ),
    );
  }
}

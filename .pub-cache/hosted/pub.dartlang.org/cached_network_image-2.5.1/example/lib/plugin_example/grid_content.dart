import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Demonstrates a [GridView] containing [CachedNetworkImage]
class GridContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 250,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) => CachedNetworkImage(
        imageUrl: 'https://loremflickr.com/100/100/music?lock=$index',
        placeholder: _loader,
        errorWidget: _error,
      ),
    );
  }

  Widget _loader(BuildContext context, String url) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _error(BuildContext context, String url, dynamic error) {
    print(error);
    return const Center(child: Icon(Icons.error));
  }
}

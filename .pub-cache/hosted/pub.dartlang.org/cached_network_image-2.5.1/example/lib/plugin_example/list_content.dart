import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Demonstrates a [ListView] containing [CachedNetworkImage]
class ListContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => Card(
        child: Column(
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: 'https://loremflickr.com/320/240/music?lock=$index',
              placeholder: (BuildContext context, String url) => Container(
                width: 320,
                height: 240,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
      itemCount: 250,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_image/network.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String imageUrl = 'https://picsum.photos/250?image=9';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image with Retry Example',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Image with Retry'),
        ),
        body: Center(
          child: NetworkImageWithRetryWidget(
            imageUrl: imageUrl,
          ),
        ),
      ),
    );
  }
}

class NetworkImageWithRetryWidget extends StatelessWidget {
  final String imageUrl;

  const NetworkImageWithRetryWidget({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: NetworkImageWithRetry(
        imageUrl,
        fetchStrategy: (uri, failure) async {
          // Customize the fetch strategy here
          // You can use the defaultFetchStrategy provided by NetworkImageWithRetry
          // or implement your own logic for retrying and handling failures.
          // This example uses the default fetch strategy.

          // Use defaultFetchStrategy to fetch the URL with retry mechanism
          return NetworkImageWithRetry.defaultFetchStrategy(uri, failure);
        },
      ),
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return Text('Failed to load image');
      },
    );
  }
}

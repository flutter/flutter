import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view_example/screens/common/app_bar.dart';

class HeroExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExampleAppBarLayout(
      title: "Hero",
      showGoBack: true,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HeroPhotoViewRouteWrapper(
                  imageProvider: NetworkImage(
                    "https://source.unsplash.com/4900x3600/?camera,paper",
                  ),
                ),
              ),
            );
          },
          child: Container(
            child: Hero(
              tag: "someTag",
              child: Image.network(
                "https://source.unsplash.com/4900x3600/?camera,paper",
                width: 350.0,
                loadingBuilder: (_, child, chunk) =>
                    chunk != null ? const Text("loading") : child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroPhotoViewRouteWrapper extends StatelessWidget {
  const HeroPhotoViewRouteWrapper({
    required this.imageProvider,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
  });

  final ImageProvider imageProvider;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height,
      ),
      child: PhotoView(
        imageProvider: imageProvider,
        backgroundDecoration: backgroundDecoration,
        minScale: minScale,
        maxScale: maxScale,
        heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view_example/screens/common/app_bar.dart';
import 'package:photo_view_example/screens/common/common_example_wrapper.dart';
import 'package:photo_view_example/screens/common/example_button.dart';

class CommonUseCasesExamples extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExampleAppBarLayout(
      title: "Common use cases",
      showGoBack: true,
      child: ListView(
        children: <Widget>[
          ExampleButtonNode(
            title: "Large Image",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Large Image (filter quality: medium)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Small Image (custom background)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/small-image.jpg"),
                    backgroundDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Colors.white, Colors.grey],
                        stops: [0.1, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Small Image (custom alignment)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/small-image.jpg"),
                    backgroundDecoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    basePosition: Alignment(0.5, 0.0),
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Animated GIF",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/neat.gif"),
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Limited scale",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 1.1,
                    initialScale: PhotoViewComputedScale.covered * 1.1,
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "Custom Initial scale",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                    initialScale: PhotoViewComputedScale.contained * 0.7,
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "One tap to dismiss",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OneTapWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                  ),
                ),
              );
            },
          ),
          ExampleButtonNode(
            title: "No gesture ",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonExampleRouteWrapper(
                    imageProvider: const AssetImage("assets/large-image.jpg"),
                    disableGestures: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class OneTapWrapper extends StatelessWidget {
  const OneTapWrapper({
    required this.imageProvider,
  });

  final ImageProvider imageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: GestureDetector(
          onTapDown: (_) {
            Navigator.pop(context);
          },
          child: PhotoView(
            imageProvider: imageProvider,
          ),
        ),
      ),
    );
  }
}

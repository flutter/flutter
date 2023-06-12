import 'package:example/helpers/mock_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Set Demo',
      theme: ThemeData(),
      home: OctoImagePage(
        sets: <OctoSet>[
          OctoSet.blurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
          OctoSet.circleAvatar(
            backgroundColor: Colors.red,
            text: const Text(
              "M",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          OctoSet.circularIndicatorAndIcon(),
          OctoSet.circularIndicatorAndIcon(showProgress: true),
        ],
      ),
    );
  }
}

class OctoImagePage extends StatelessWidget {
  final List<OctoSet> sets;

  const OctoImagePage({Key? key, required this.sets}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Demo'),
      ),
      body: ListView(children: sets.map((element) => _row(element)).toList()),
    );
  }

  Widget _row(OctoSet octoSet) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: 269 / 173,
            child: OctoImage.fromSet(
              image: MockImageProvider(useCase: TestUseCase.loadAndFail),
              octoSet: octoSet,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 269 / 173,
            child: OctoImage.fromSet(
              image: MockImageProvider(useCase: TestUseCase.loadAndSuccess),
              octoSet: octoSet,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

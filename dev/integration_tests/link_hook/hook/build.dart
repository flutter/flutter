import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

const packageName = 'link_hook';

void main(List<String> args) async {
  await build(args, (config, output) async {
    final packageName = config.packageName;
    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: 'some_asset_name_that_is_not_used',
      sources: [
        'src/$packageName.c',
      ],
      dartBuildFiles: ['hook/build.dart'],
    );
    final outputCatcher = BuildOutput();
    await cbuilder.run(
      buildConfig: config,
      buildOutput: outputCatcher,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message)),
    );
    output.addDependencies(outputCatcher.dependencies);
    // Send the asset to hook/link.dart.
    output.addAsset(
      outputCatcher.assets.single,
      linkInPackage: 'link_hook',
    );
  });
}

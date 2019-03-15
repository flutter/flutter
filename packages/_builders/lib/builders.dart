import 'package:build/build.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_web_compilers/build_web_compilers.dart';

/// Dev compiler builder.
Builder devCompilerBuilder(BuilderOptions builderOptions) {
  final String platformSdk = builderOptions.config['platformSdk'];
  final String sdkKernelPath = builderOptions.config['sdkKernelPath'];
  return DevCompilerBuilder(
    platformSdk: platformSdk,
    sdkKernelPath: sdkKernelPath,
  );
}

/// Web entrypoint builder.
Builder webEntrypointBuilder(BuilderOptions options) =>
    WebEntrypointBuilder.fromOptions(options);

/// Extractor for dart archive files.
PostProcessBuilder dart2JsArchiveExtractor(BuilderOptions options) =>
    Dart2JsArchiveExtractor.fromOptions(options);

/// Cleanup for temporary dart files.
PostProcessBuilder dartSourceCleanup(BuilderOptions options) {
  return (options.config['enabled']?? false)
      ? const FileDeletingBuilder(<String>['.dart', '.js.map'])
      : const FileDeletingBuilder(<String>['.dart', '.js.map'], isEnabled: false);
}

/// Kernel summary extension.
const String ddcKernelExtension = '.ddc.dill';

/// Kernel summary builder.
Builder ddcKernelBuilder(BuilderOptions builderOptions) {
  final String platformSdk = builderOptions.config['platformSdk'];
  final String sdkKernelPath = builderOptions.config['sdkKernelPath'];
  return KernelBuilder(
    summaryOnly: true,
    platformSdk: platformSdk,
    sdkKernelPath: sdkKernelPath,
    outputExtension: ddcKernelExtension,
    platform: DartPlatform.dartdevc,
  );
}
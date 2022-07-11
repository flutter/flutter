import 'template.dart';

class BottomAppBarTemplate extends TokenTemplate {
  const BottomAppBarTemplate(super.blockName, super.fileName, super.tokens);


  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends BottomAppBarTheme {
  const _TokenDefaultsM3(this.context)
    : super(
      elevation: ${elevation('md.comp.bottom-app-bar.container')},
      height: ${tokens['md.comp.bottom-app-bar.container.height']},
    );

  final BuildContext context;

  @override
  Color? get color => ${componentColor('md.comp.bottom-app-bar.container')};

  @override
  Color? get surfaceTintColor => ${componentColor('md.comp.bottom-app-bar.container.surface-tint-layer')};

  @override
  NotchedShape? get shape => const AutomaticNotchedShape(${shape('md.comp.bottom-app-bar.container')});
}
  ''';
}


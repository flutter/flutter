// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class InputDecoratorTemplate extends TokenTemplate {
  const InputDecoratorTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _${blockName}DefaultsM3 extends InputDecorationTheme {
  const _${blockName}DefaultsM3(this.context)
    : super();

  final BuildContext context;

  @override
  Color? get fillColor => ${componentColor("md.comp.filled-text-field.container")};

  @override
  Color? get disabledFillColor => ${componentColor("md.comp.filled-text-field.disabled.container")};

  @override
  BorderSide? get activeIndicatorBorder => MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.error)) {
        if (states.contains(MaterialState.hovered)) {
          return ${border('md.comp.filled-text-field.error.hover.active-indicator')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${border('md.comp.filled-text-field.error.focus.active-indicator')};
        }
        return ${border('md.comp.filled-text-field.error.active-indicator')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${border('md.comp.filled-text-field.hover.active-indicator')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${border('md.comp.filled-text-field.focus.active-indicator')};
      }
      if (states.contains(MaterialState.disabled)) {
        return ${border('md.comp.filled-text-field.disabled.active-indicator')};
      }
      return ${border('md.comp.filled-text-field.active-indicator')};
    });

  @override
  BorderSide? get outLineBorder => MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.error)) {
        if (states.contains(MaterialState.hovered)) {
          return ${border('md.comp.outlined-text-field.error.hover.outline')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${border('md.comp.outlined-text-field.error.focus.outline')};
        }
        return ${border('md.comp.outlined-text-field.error.outline')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${border('md.comp.outlined-text-field.hover.outline')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${border('md.comp.outlined-text-field.focus.outline')};
      }
      if (states.contains(MaterialState.disabled)) {
        return ${border('md.comp.outlined-text-field.disabled.outline')};
      }
      return ${border('md.comp.outlined-text-field.outline')};
    });

  @override
  Color? get iconColor => ${componentColor("md.comp.filled-text-field.leading-icon")};
  
  @override
  Color? get prefixIconColor => MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if(states.contains(MaterialState.error)) {
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.filled-text-field.error.hover.leading-icon')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.filled-text-field.error.focus.leading-icon')};
      }
      return ${componentColor('md.comp.filled-text-field.error.leading-icon')};
    }
    if (states.contains(MaterialState.hovered)) {
      return ${componentColor('md.comp.filled-text-field.hover.leading-icon')};
    }
    if (states.contains(MaterialState.focused)) {
      return ${componentColor('md.comp.filled-text-field.focus.leading-icon')};
    }
    if (states.contains(MaterialState.disabled)) {
      return ${componentColor('md.comp.filled-text-field.disabled.leading-icon')};
    }
    return ${componentColor('md.comp.filled-text-field.leading-icon')};
  });
  
  @override
  Color? get suffixIconColor => MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if(states.contains(MaterialState.error)) {
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.filled-text-field.error.hover.trailing-icon')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.filled-text-field.error.focus.trailing-icon')};
      }
      return ${componentColor('md.comp.filled-text-field.error.trailing-icon')};
    }
    if (states.contains(MaterialState.hovered)) {
      return ${componentColor('md.comp.filled-text-field.hover.trailing-icon')};
    }
    if (states.contains(MaterialState.focused)) {
      return ${componentColor('md.comp.filled-text-field.focus.trailing-icon')};
    }
    if (states.contains(MaterialState.disabled)) {
      return ${componentColor('md.comp.filled-text-field.disabled.trailing-icon')};
    }
    return ${componentColor('md.comp.filled-text-field.trailing-icon')};
  });

  @override
  TextStyle? get labelStyle => MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
    final TextStyle textStyle= ${textStyle("md.comp.filled-text-field.label-text")} ?? const TextStyle();
    if(states.contains(MaterialState.error)) {
      if (states.contains(MaterialState.hovered)) {
        return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.hover.label-text')});
      }
      if (states.contains(MaterialState.focused)) {
        return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.focus.label-text')});
      }
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.label-text')});
    }
    if (states.contains(MaterialState.hovered)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.hover.label-text')});
    }
    if (states.contains(MaterialState.focused)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.focus.label-text')});
    }
    if (states.contains(MaterialState.disabled)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.disabled.label-text')});
    }
    return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.label-text')});
  });

  @override
  TextStyle? get helperStyle => MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
    final TextStyle textStyle= ${textStyle("md.comp.filled-text-field.supporting-text")} ?? const TextStyle();
    if(states.contains(MaterialState.error)) {
      if (states.contains(MaterialState.hovered)) {
        return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.hover.supporting-text')});
      }
      if (states.contains(MaterialState.focused)) {
        return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.focus.supporting-text')});
      }
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.error.supporting-text')});
    }
    if (states.contains(MaterialState.hovered)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.hover.supporting-text')});
    }
    if (states.contains(MaterialState.focused)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.focus.supporting-text')});
    }
    if (states.contains(MaterialState.disabled)) {
      return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.disabled.supporting-text')});
    }
    return textStyle.copyWith(color:${componentColor('md.comp.filled-text-field.supporting-text')});
  });
}
''';
}

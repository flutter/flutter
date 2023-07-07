// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.formal_parameter_kind;

enum FormalParameterKind {
  requiredPositional,
  requiredNamed,
  optionalNamed,
  optionalPositional,
}

extension FormalParameterKindExtension on FormalParameterKind {
  bool get isRequiredPositional {
    return FormalParameterKind.requiredPositional == this;
  }

  bool get isOptionalNamed {
    return FormalParameterKind.optionalNamed == this;
  }

  bool get isOptionalPositional {
    return FormalParameterKind.optionalPositional == this;
  }

  bool get isRequiredNamed {
    return FormalParameterKind.requiredNamed == this;
  }

  bool get isRequired => isRequiredPositional || isRequiredNamed;

  bool get isOptional => isOptionalPositional || isOptionalNamed;

  bool get isPositional => isRequiredPositional || isOptionalPositional;

  bool get isNamed => isRequiredNamed || isOptionalNamed;
}

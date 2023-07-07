import '../core/parser.dart';
import 'internal/reference.dart';
import 'internal/undefined.dart';
import 'resolve.dart';

/// Creates a [Parser] from a [function] reference, possibly with the given
/// arguments [arg1], [arg2], [arg3], ...
///
/// This method doesn't work well in strong mode as it perform type checks at
/// runtime only. Depending on the argument count of your function consider
/// using one of the strongly typed alternatives [ref0], [ref1], [ref2], ...
/// instead.
@Deprecated('Use [ref0], [ref1], [ref2], ... instead.')
Parser<T> ref<T>(
  Function function, [
  dynamic arg1 = undefined,
  dynamic arg2 = undefined,
  dynamic arg3 = undefined,
  dynamic arg4 = undefined,
  dynamic arg5 = undefined,
  dynamic arg6 = undefined,
  dynamic arg7 = undefined,
  dynamic arg8 = undefined,
  dynamic arg9 = undefined,
]) {
  final arguments = [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      .takeWhile((each) => each != undefined)
      .toList(growable: false);
  return ReferenceParser<T>(function, arguments);
}

/// Creates a [Parser] from a [function] without arguments.
///
/// Reference parsers behave like normal parsers during construction, but can
/// recursively reference each other. Once the parser is assembled resolve all
/// references by passing the root of your parser to [resolve].
///
/// If you function takes arguments, consider one of the typed alternatives
/// [ref1], [ref2], [ref3], ... instead.
Parser<T> ref0<T>(Parser<T> Function() function) =>
    ReferenceParser<T>(function, const []);

/// Reference to a production [function] parametrized with 1 argument.
///
/// See [ref0] for a detailed description.
Parser<T> ref1<T, A1>(
  Parser<T> Function(A1) function,
  A1 arg1,
) =>
    ReferenceParser<T>(function, [arg1]);

/// Reference to a production [function] parametrized with 2 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref2<T, A1, A2>(
  Parser<T> Function(A1, A2) function,
  A1 arg1,
  A2 arg2,
) =>
    ReferenceParser<T>(function, [arg1, arg2]);

/// Reference to a production [function] parametrized with 3 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref3<T, A1, A2, A3>(
  Parser<T> Function(A1, A2, A3) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
) =>
    ReferenceParser<T>(function, [arg1, arg2, arg3]);

/// Reference to a production [function] parametrized with 4 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref4<T, A1, A2, A3, A4>(
  Parser<T> Function(A1, A2, A3, A4) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
) =>
    ReferenceParser<T>(function, [arg1, arg2, arg3, arg4]);

/// Reference to a production [function] parametrized with 5 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref5<T, A1, A2, A3, A4, A5>(
  Parser<T> Function(A1, A2, A3, A4, A5) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
  A5 arg5,
) =>
    ReferenceParser<T>(function, [arg1, arg2, arg3, arg4, arg5]);

/// Reference to a production [function] parametrized with 6 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref6<T, A1, A2, A3, A4, A5, A6>(
  Parser<T> Function(A1, A2, A3, A4, A5, A6) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
  A5 arg5,
  A6 arg6,
) =>
    ReferenceParser<T>(function, [arg1, arg2, arg3, arg4, arg5, arg6]);

/// Reference to a production [function] parametrized with 7 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref7<T, A1, A2, A3, A4, A5, A6, A7>(
  Parser<T> Function(A1, A2, A3, A4, A5, A6, A7) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
  A5 arg5,
  A6 arg6,
  A7 arg7,
) =>
    ReferenceParser<T>(function, [arg1, arg2, arg3, arg4, arg5, arg6, arg7]);

/// Reference to a production [function] parametrized with 8 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref8<T, A1, A2, A3, A4, A5, A6, A7, A8>(
  Parser<T> Function(A1, A2, A3, A4, A5, A6, A7, A8) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
  A5 arg5,
  A6 arg6,
  A7 arg7,
  A8 arg8,
) =>
    ReferenceParser<T>(
        function, [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8]);

/// Reference to a production [function] parametrized with 9 arguments.
///
/// See [ref0] for a detailed description.
Parser<T> ref9<T, A1, A2, A3, A4, A5, A6, A7, A8, A9>(
  Parser<T> Function(A1, A2, A3, A4, A5, A6, A7, A8, A9) function,
  A1 arg1,
  A2 arg2,
  A3 arg3,
  A4 arg4,
  A5 arg5,
  A6 arg6,
  A7 arg7,
  A8 arg8,
  A9 arg9,
) =>
    ReferenceParser<T>(
        function, [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]);

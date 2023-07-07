import '../../context/failure.dart';

/// Function definition that joins parse [Failure] instances.
typedef FailureJoiner<T> = Failure<T> Function(
    Failure<T> first, Failure<T> second);

/// Reports the first parse failure observed.
Failure<T> selectFirst<T>(Failure<T> first, Failure<T> second) => first;

/// Reports the last parse failure observed (default).
Failure<T> selectLast<T>(Failure<T> first, Failure<T> second) => second;

/// Reports the parser failure farthest down in the input string, preferring
/// later failures over earlier ones.
Failure<T> selectFarthest<T>(Failure<T> first, Failure<T> second) =>
    first.position <= second.position ? second : first;

/// Reports the parser failure farthest down in the input string, joining
/// error messages at the same position.
Failure<T> selectFarthestJoined<T>(Failure<T> first, Failure<T> second) =>
    first.position > second.position
        ? first
        : first.position < second.position
            ? second
            : first.failure<T>('${first.message} OR ${second.message}');

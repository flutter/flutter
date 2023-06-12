part of 'indicators.dart';

@immutable
class FortuneIndicator {
  final Alignment alignment;
  final Widget child;

  const FortuneIndicator({
    this.alignment = Alignment.center,
    required this.child,
  });

  @override
  int get hashCode => hash2(alignment, child);

  @override
  bool operator ==(Object other) {
    return other is FortuneIndicator &&
        alignment == other.alignment &&
        child == other.child;
  }
}

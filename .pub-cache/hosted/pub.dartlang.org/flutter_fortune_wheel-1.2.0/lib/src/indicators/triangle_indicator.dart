part of 'indicators.dart';

class TriangleIndicator extends StatelessWidget {
  final Color? color;

  const TriangleIndicator({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Transform.rotate(
      angle: _math.pi,
      child: SizedBox(
        width: 36,
        height: 36,
        child: _Triangle(
          color: color ?? theme.accentColor,
          elevation: 2,
        ),
      ),
    );
  }
}

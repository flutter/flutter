part of 'indicators.dart';

class _Rectangle extends StatelessWidget {
  final double width;
  final double height;
  final double borderWidth;
  final Color borderColor;
  final Color color;

  const _Rectangle({
    Key? key,
    required this.width,
    required this.height,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.color = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
    );
  }
}

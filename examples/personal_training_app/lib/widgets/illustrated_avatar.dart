import 'dart:math' as math;

import 'package:flutter/material.dart';

class AvatarCatalog {
  static const String tokenPrefix = 'illustrated-avatar:';
  static int get avatarCount => _presets.length;

  static String tokenForIndex(int index) => '$tokenPrefix$index';

  static bool isIllustratedAvatarToken(String? value) {
    return value != null && value.startsWith(tokenPrefix);
  }

  static int indexFromToken(String token) {
    final raw = token.replaceFirst(tokenPrefix, '');
    final parsed = int.tryParse(raw) ?? 0;
    return parsed.clamp(0, avatarCount - 1);
  }

  static String tokenForSeed(String seed) {
    final normalized = seed.trim().isEmpty ? 'default' : seed.trim();
    final hash = normalized.runes.fold<int>(0, (sum, rune) => sum + rune);
    return tokenForIndex(hash % avatarCount);
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? imageValue;
  final String seed;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.seed,
    this.imageValue,
    this.size = 48,
  });

  bool _isDataImageUrl(String value) {
    return value.startsWith('data:image');
  }

  @override
  Widget build(BuildContext context) {
    final resolvedValue = (imageValue == null || imageValue!.trim().isEmpty)
        ? AvatarCatalog.tokenForSeed(seed)
        : imageValue!.trim();

    if (_isDataImageUrl(resolvedValue)) {
      return Image.memory(
        UriData.parse(resolvedValue).contentAsBytes(),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }

    final avatarToken = AvatarCatalog.isIllustratedAvatarToken(resolvedValue)
        ? resolvedValue
        : AvatarCatalog.tokenForSeed(resolvedValue);
    return IllustratedAvatar(token: avatarToken, size: size);
  }
}

class IllustratedAvatar extends StatelessWidget {
  final String token;
  final double size;

  const IllustratedAvatar({super.key, required this.token, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final index = AvatarCatalog.indexFromToken(token);
    return CustomPaint(
      size: Size.square(size),
      painter: _IllustratedAvatarPainter(_presets[index]),
    );
  }
}

enum _HairShape {
  swoop,
  bun,
  fade,
  waves,
  quiff,
  longStraight,
  topKnot,
  ponytail,
  fluffy,
  curls,
  bob,
  sidePart,
  buzz,
}

class _AvatarPreset {
  final Color background;
  final Color shirt;
  final Color shirtAccent;
  final Color skin;
  final Color hair;
  final Color lips;
  final _HairShape hairShape;
  final bool glasses;
  final bool beard;

  const _AvatarPreset({
    required this.background,
    required this.shirt,
    required this.shirtAccent,
    required this.skin,
    required this.hair,
    required this.lips,
    required this.hairShape,
    this.glasses = false,
    this.beard = false,
  });
}

const List<_AvatarPreset> _presets = [
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFF39A9D4),
    shirtAccent: Color(0xFF2388B2),
    skin: Color(0xFFFFC5A3),
    hair: Color(0xFF7A4300),
    lips: Color(0xFFD6837D),
    hairShape: _HairShape.swoop,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFF08C69),
    shirtAccent: Color(0xFFE36D48),
    skin: Color(0xFFF7BE98),
    hair: Color(0xFF0F7AA6),
    lips: Color(0xFFB95E8B),
    hairShape: _HairShape.bun,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFC4E0EA),
    shirtAccent: Color(0xFF8ABCCB),
    skin: Color(0xFF9E563C),
    hair: Color(0xFF7C3C28),
    lips: Color(0xFFB76456),
    hairShape: _HairShape.fade,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFDDE5F7),
    shirtAccent: Color(0xFFBAC7E2),
    skin: Color(0xFFA95641),
    hair: Color(0xFF6D2E1E),
    lips: Color(0xFFC77367),
    hairShape: _HairShape.waves,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFF0C82B0),
    shirtAccent: Color(0xFFEF6A4E),
    skin: Color(0xFFF6C59D),
    hair: Color(0xFFB56A00),
    lips: Color(0xFFB56A00),
    hairShape: _HairShape.quiff,
    beard: true,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFE6A79A),
    shirtAccent: Color(0xFFC38A7D),
    skin: Color(0xFFF8C3B0),
    hair: Color(0xFF8E4B7B),
    lips: Color(0xFFAF6895),
    hairShape: _HairShape.longStraight,
    glasses: true,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFD86249),
    shirtAccent: Color(0xFF60C7AE),
    skin: Color(0xFFF4BA96),
    hair: Color(0xFF7D5C92),
    lips: Color(0xFFD27F73),
    hairShape: _HairShape.topKnot,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFFEF3E75),
    shirtAccent: Color(0xFFF3B033),
    skin: Color(0xFFF6C6B1),
    hair: Color(0xFF623302),
    lips: Color(0xFFCF8679),
    hairShape: _HairShape.ponytail,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFF59C9C2),
    shirtAccent: Color(0xFFE4F2F2),
    skin: Color(0xFFF0B285),
    hair: Color(0xFF5A6D86),
    lips: Color(0xFFC97A62),
    hairShape: _HairShape.fluffy,
  ),
  _AvatarPreset(
    background: Color(0xFFF4ECE6),
    shirt: Color(0xFF6B9AC4),
    shirtAccent: Color(0xFF3F6F96),
    skin: Color(0xFFD7A07B),
    hair: Color(0xFF3E2B23),
    lips: Color(0xFFBD7569),
    hairShape: _HairShape.sidePart,
  ),
  _AvatarPreset(
    background: Color(0xFFF3EBE4),
    shirt: Color(0xFF7ED0C8),
    shirtAccent: Color(0xFF4FB2A8),
    skin: Color(0xFFF3C7A9),
    hair: Color(0xFF4A2D1B),
    lips: Color(0xFFD58476),
    hairShape: _HairShape.bob,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E7E0),
    shirt: Color(0xFF4A90A4),
    shirtAccent: Color(0xFFD9EFF2),
    skin: Color(0xFF8F583F),
    hair: Color(0xFF25374A),
    lips: Color(0xFFB76A5F),
    hairShape: _HairShape.curls,
  ),
  _AvatarPreset(
    background: Color(0xFFF0E8E2),
    shirt: Color(0xFFEE8F5A),
    shirtAccent: Color(0xFFCB5E3E),
    skin: Color(0xFFF0B38C),
    hair: Color(0xFF8B4F10),
    lips: Color(0xFFD97B62),
    hairShape: _HairShape.sidePart,
    beard: true,
  ),
  _AvatarPreset(
    background: Color(0xFFF2EAE5),
    shirt: Color(0xFFB8C7E8),
    shirtAccent: Color(0xFF7C94CB),
    skin: Color(0xFFE7B89A),
    hair: Color(0xFFB05E49),
    lips: Color(0xFFC6727D),
    hairShape: _HairShape.bob,
    glasses: true,
  ),
  _AvatarPreset(
    background: Color(0xFFF0E9E3),
    shirt: Color(0xFF1E88A8),
    shirtAccent: Color(0xFFEF6B4A),
    skin: Color(0xFFBD7A57),
    hair: Color(0xFF1D1A1C),
    lips: Color(0xFFA96055),
    hairShape: _HairShape.buzz,
  ),
  _AvatarPreset(
    background: Color(0xFFF2ECE6),
    shirt: Color(0xFFED5D88),
    shirtAccent: Color(0xFFF2B647),
    skin: Color(0xFFF7CDB3),
    hair: Color(0xFF6E3A20),
    lips: Color(0xFFC56E73),
    hairShape: _HairShape.ponytail,
    glasses: true,
  ),
  _AvatarPreset(
    background: Color(0xFFF3EAE3),
    shirt: Color(0xFF59B3C5),
    shirtAccent: Color(0xFFCBE8EE),
    skin: Color(0xFFEDB284),
    hair: Color(0xFF58667A),
    lips: Color(0xFFC87660),
    hairShape: _HairShape.fluffy,
  ),
  _AvatarPreset(
    background: Color(0xFFF1E8E3),
    shirt: Color(0xFF5F98CE),
    shirtAccent: Color(0xFF2F5E8F),
    skin: Color(0xFF7F4B34),
    hair: Color(0xFF513529),
    lips: Color(0xFFAA6254),
    hairShape: _HairShape.curls,
  ),
];

class _IllustratedAvatarPainter extends CustomPainter {
  final _AvatarPreset preset;

  const _IllustratedAvatarPainter(this.preset);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);
    final radius = math.min(width, height) / 2;
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(clipPath);

    final backgroundPaint = Paint()..color = preset.background;
    canvas.drawCircle(center, radius, backgroundPaint);

    _drawShirt(canvas, size);
    _drawNeck(canvas, size);
    _drawHead(canvas, size);
    _drawHair(canvas, size);
    _drawFace(canvas, size);

    canvas.restore();
  }

  void _drawShirt(Canvas canvas, Size size) {
    final shirtPaint = Paint()..color = preset.shirt;
    final accentPaint = Paint()..color = preset.shirtAccent;
    final shirtRect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.68,
      size.width * 0.76,
      size.height * 0.34,
    );
    canvas.drawOval(shirtRect, shirtPaint);

    final neckline = Path()
      ..moveTo(size.width * 0.38, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.79,
        size.width * 0.62,
        size.height * 0.69,
      )
      ..lineTo(size.width * 0.54, size.height * 0.84)
      ..lineTo(size.width * 0.46, size.height * 0.84)
      ..close();
    canvas.drawPath(neckline, accentPaint);
  }

  void _drawNeck(Canvas canvas, Size size) {
    final neckPaint = Paint()..color = preset.skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.43,
          size.height * 0.52,
          size.width * 0.14,
          size.height * 0.16,
        ),
        const Radius.circular(18),
      ),
      neckPaint,
    );
  }

  void _drawHead(Canvas canvas, Size size) {
    final headPaint = Paint()..color = preset.skin;
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.43),
      width: size.width * 0.34,
      height: size.height * 0.40,
    );
    canvas.drawOval(headRect, headPaint);
    final earPaint = Paint()..color = _shade(preset.skin, -0.04);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.33, size.height * 0.44),
        width: size.width * 0.04,
        height: size.height * 0.08,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.67, size.height * 0.44),
        width: size.width * 0.04,
        height: size.height * 0.08,
      ),
      earPaint,
    );
  }

  void _drawHair(Canvas canvas, Size size) {
    final hairPaint = Paint()..color = preset.hair;
    switch (preset.hairShape) {
      case _HairShape.swoop:
        final path = Path()
          ..moveTo(size.width * 0.33, size.height * 0.29)
          ..quadraticBezierTo(
            size.width * 0.43,
            size.height * 0.16,
            size.width * 0.63,
            size.height * 0.22,
          )
          ..quadraticBezierTo(
            size.width * 0.70,
            size.height * 0.28,
            size.width * 0.65,
            size.height * 0.38,
          )
          ..lineTo(size.width * 0.58, size.height * 0.31)
          ..quadraticBezierTo(
            size.width * 0.48,
            size.height * 0.26,
            size.width * 0.39,
            size.height * 0.33,
          )
          ..close();
        canvas.drawPath(path, hairPaint);
        break;
      case _HairShape.bun:
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.31,
            size.height * 0.22,
            size.width * 0.38,
            size.height * 0.20,
          ),
          hairPaint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.34, size.height * 0.27),
          size.width * 0.07,
          hairPaint,
        );
        final backPath = Path()
          ..moveTo(size.width * 0.30, size.height * 0.32)
          ..quadraticBezierTo(
            size.width * 0.20,
            size.height * 0.45,
            size.width * 0.28,
            size.height * 0.62,
          )
          ..lineTo(size.width * 0.38, size.height * 0.56)
          ..quadraticBezierTo(
            size.width * 0.33,
            size.height * 0.44,
            size.width * 0.39,
            size.height * 0.34,
          )
          ..close();
        canvas.drawPath(backPath, hairPaint);
        break;
      case _HairShape.fade:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.36,
              size.height * 0.22,
              size.width * 0.28,
              size.height * 0.16,
            ),
            const Radius.circular(20),
          ),
          hairPaint,
        );
        break;
      case _HairShape.waves:
        final wavesPath = Path()
          ..moveTo(size.width * 0.28, size.height * 0.24)
          ..quadraticBezierTo(
            size.width * 0.18,
            size.height * 0.40,
            size.width * 0.30,
            size.height * 0.62,
          )
          ..quadraticBezierTo(
            size.width * 0.42,
            size.height * 0.70,
            size.width * 0.44,
            size.height * 0.50,
          )
          ..quadraticBezierTo(
            size.width * 0.36,
            size.height * 0.42,
            size.width * 0.42,
            size.height * 0.28,
          )
          ..close();
        final wavesPath2 = Path()
          ..moveTo(size.width * 0.52, size.height * 0.22)
          ..quadraticBezierTo(
            size.width * 0.76,
            size.height * 0.24,
            size.width * 0.67,
            size.height * 0.55,
          )
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.72,
            size.width * 0.48,
            size.height * 0.54,
          )
          ..quadraticBezierTo(
            size.width * 0.60,
            size.height * 0.40,
            size.width * 0.52,
            size.height * 0.22,
          )
          ..close();
        canvas.drawPath(wavesPath, hairPaint);
        canvas.drawPath(wavesPath2, hairPaint);
        break;
      case _HairShape.quiff:
        final path = Path()
          ..moveTo(size.width * 0.31, size.height * 0.28)
          ..quadraticBezierTo(
            size.width * 0.48,
            size.height * 0.12,
            size.width * 0.67,
            size.height * 0.23,
          )
          ..lineTo(size.width * 0.60, size.height * 0.41)
          ..quadraticBezierTo(
            size.width * 0.49,
            size.height * 0.30,
            size.width * 0.39,
            size.height * 0.36,
          )
          ..close();
        canvas.drawPath(path, hairPaint);
        break;
      case _HairShape.longStraight:
        final sideHair = Path()
          ..moveTo(size.width * 0.28, size.height * 0.22)
          ..quadraticBezierTo(
            size.width * 0.20,
            size.height * 0.44,
            size.width * 0.28,
            size.height * 0.78,
          )
          ..lineTo(size.width * 0.40, size.height * 0.78)
          ..lineTo(size.width * 0.38, size.height * 0.26)
          ..close();
        final sideHair2 = Path()
          ..moveTo(size.width * 0.72, size.height * 0.22)
          ..quadraticBezierTo(
            size.width * 0.80,
            size.height * 0.44,
            size.width * 0.72,
            size.height * 0.78,
          )
          ..lineTo(size.width * 0.60, size.height * 0.78)
          ..lineTo(size.width * 0.62, size.height * 0.26)
          ..close();
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.30,
            size.height * 0.20,
            size.width * 0.40,
            size.height * 0.18,
          ),
          hairPaint,
        );
        canvas.drawPath(sideHair, hairPaint);
        canvas.drawPath(sideHair2, hairPaint);
        break;
      case _HairShape.topKnot:
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.30,
            size.height * 0.22,
            size.width * 0.40,
            size.height * 0.16,
          ),
          hairPaint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.53, size.height * 0.17),
          size.width * 0.07,
          hairPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.49,
            size.height * 0.20,
            size.width * 0.04,
            size.height * 0.08,
          ),
          hairPaint,
        );
        break;
      case _HairShape.ponytail:
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.30,
            size.height * 0.21,
            size.width * 0.40,
            size.height * 0.17,
          ),
          hairPaint,
        );
        final tail = Path()
          ..moveTo(size.width * 0.60, size.height * 0.30)
          ..quadraticBezierTo(
            size.width * 0.72,
            size.height * 0.42,
            size.width * 0.58,
            size.height * 0.68,
          )
          ..lineTo(size.width * 0.50, size.height * 0.64)
          ..quadraticBezierTo(
            size.width * 0.60,
            size.height * 0.46,
            size.width * 0.53,
            size.height * 0.32,
          )
          ..close();
        canvas.drawPath(tail, hairPaint);
        break;
      case _HairShape.fluffy:
        for (final center in [0.34, 0.45, 0.56, 0.66]) {
          canvas.drawCircle(
            Offset(size.width * center, size.height * 0.27),
            size.width * 0.07,
            hairPaint,
          );
        }
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.30,
            size.height * 0.25,
            size.width * 0.40,
            size.height * 0.16,
          ),
          hairPaint,
        );
        break;
      case _HairShape.curls:
        for (final bubble in [
          const Offset(0.35, 0.27),
          const Offset(0.44, 0.23),
          const Offset(0.54, 0.23),
          const Offset(0.63, 0.28),
          const Offset(0.30, 0.34),
          const Offset(0.67, 0.34),
        ]) {
          canvas.drawCircle(
            Offset(size.width * bubble.dx, size.height * bubble.dy),
            size.width * 0.06,
            hairPaint,
          );
        }
        break;
      case _HairShape.bob:
        canvas.drawOval(
          Rect.fromLTWH(
            size.width * 0.29,
            size.height * 0.21,
            size.width * 0.42,
            size.height * 0.18,
          ),
          hairPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.26,
              size.height * 0.29,
              size.width * 0.12,
              size.height * 0.34,
            ),
            const Radius.circular(20),
          ),
          hairPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.62,
              size.height * 0.29,
              size.width * 0.12,
              size.height * 0.34,
            ),
            const Radius.circular(20),
          ),
          hairPaint,
        );
        break;
      case _HairShape.sidePart:
        final partPath = Path()
          ..moveTo(size.width * 0.30, size.height * 0.30)
          ..quadraticBezierTo(
            size.width * 0.38,
            size.height * 0.18,
            size.width * 0.58,
            size.height * 0.23,
          )
          ..quadraticBezierTo(
            size.width * 0.68,
            size.height * 0.26,
            size.width * 0.70,
            size.height * 0.38,
          )
          ..lineTo(size.width * 0.60, size.height * 0.37)
          ..quadraticBezierTo(
            size.width * 0.50,
            size.height * 0.29,
            size.width * 0.39,
            size.height * 0.35,
          )
          ..close();
        canvas.drawPath(partPath, hairPaint);
        break;
      case _HairShape.buzz:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.35,
              size.height * 0.24,
              size.width * 0.30,
              size.height * 0.12,
            ),
            const Radius.circular(18),
          ),
          hairPaint,
        );
        break;
    }
  }

  void _drawFace(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white;
    final eyeColor = Paint()..color = const Color(0xFF55351F);
    final blushPaint = Paint()..color = preset.lips.withValues(alpha: 0.18);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.43, size.height * 0.44),
        width: size.width * 0.06,
        height: size.height * 0.03,
      ),
      whitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.44),
        width: size.width * 0.06,
        height: size.height * 0.03,
      ),
      whitePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.445),
      size.width * 0.010,
      eyeColor,
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.445),
      size.width * 0.010,
      eyeColor,
    );

    final browPaint = Paint()
      ..color = _shade(preset.hair, -0.1)
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.40),
      Offset(size.width * 0.46, size.height * 0.39),
      browPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.39),
      Offset(size.width * 0.60, size.height * 0.40),
      browPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.37, size.height * 0.51),
        width: size.width * 0.06,
        height: size.height * 0.03,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.63, size.height * 0.51),
        width: size.width * 0.06,
        height: size.height * 0.03,
      ),
      blushPaint,
    );

    final nosePaint = Paint()
      ..color = _shade(preset.skin, -0.10)
      ..strokeWidth = size.width * 0.010
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nosePath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.49,
        size.height * 0.51,
        size.width * 0.52,
        size.height * 0.54,
      );
    canvas.drawPath(nosePath, nosePaint);

    final mouthPaint = Paint()
      ..color = preset.lips
      ..strokeWidth = size.width * 0.016
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mouthPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.64,
        size.width * 0.60,
        size.height * 0.56,
      );
    canvas.drawPath(mouthPath, mouthPaint);

    final teethPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.45,
          size.height * 0.57,
          size.width * 0.10,
          size.height * 0.030,
        ),
        const Radius.circular(4),
      ),
      teethPaint,
    );

    if (preset.glasses) {
      final glassesPaint = Paint()
        ..color = const Color(0xFF6B4E67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.43, size.height * 0.445),
          width: size.width * 0.10,
          height: size.height * 0.07,
        ),
        glassesPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.57, size.height * 0.445),
          width: size.width * 0.10,
          height: size.height * 0.07,
        ),
        glassesPaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.48, size.height * 0.445),
        Offset(size.width * 0.52, size.height * 0.445),
        glassesPaint,
      );
    }

    if (preset.beard) {
      final beardPaint = Paint()..color = _shade(preset.hair, -0.02);
      final beardPath = Path()
        ..moveTo(size.width * 0.36, size.height * 0.55)
        ..quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.72,
          size.width * 0.64,
          size.height * 0.55,
        )
        ..quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.68,
          size.width * 0.36,
          size.height * 0.55,
        )
        ..close();
      canvas.drawPath(beardPath, beardPaint);
    }
  }

  Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final nextLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(nextLightness).toColor();
  }

  @override
  bool shouldRepaint(covariant _IllustratedAvatarPainter oldDelegate) {
    return oldDelegate.preset != preset;
  }
}

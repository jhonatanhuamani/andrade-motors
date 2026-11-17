import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';

/// Imágenes locales con ilustraciones vectoriales como respaldo.
class ProductoPreview extends StatelessWidget {
  const ProductoPreview({
    super.key,
    required this.producto,
    this.height = 170,
    this.large = false,
  });
  final Producto producto;
  final double height;
  final bool large;
  Widget _ilustracion() => CustomPaint(
    painter: _ProductPainter(producto.categoria, producto.nombre),
    child: const SizedBox.expand(),
  );
  Widget _local() => producto.imagenAsset?.trim().isNotEmpty == true
      ? Image.asset(
          producto.imagenAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, error, trace) => _ilustracion(),
        )
      : _ilustracion();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.15, -.2),
          radius: .95,
          colors: [Color(0xFF393C41), Color(0xFF202329), Color(0xFF171A1E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: large
                  ? const EdgeInsets.all(24)
                  : const EdgeInsets.fromLTRB(16, 42, 16, 18),
              child: producto.imagenUrl?.trim().isNotEmpty == true
                  ? Image.network(
                      producto.imagenUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, error, trace) => _local(),
                    )
                  : _local(),
            ),
          ),
          if (large)
            Positioned(
              left: 12,
              bottom: 10,
              child: Text(
                'PREMIUM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .2),
                  fontSize: large ? 10 : 7,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ProductPainter extends CustomPainter {
  _ProductPainter(this.categoria, this.nombre);
  final String categoria, nombre;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final scale = math.min(size.width / 200, size.height / 180);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 - 3);
    canvas.scale(scale);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..strokeWidth = 1;
    for (double x = -200; x <= 200; x += 24) {
      canvas.drawLine(Offset(x, -200), Offset(x, 200), grid);
      canvas.drawLine(Offset(-200, x), Offset(200, x), grid);
    }
    canvas.drawOval(
      const Rect.fromLTWH(-65, 51, 130, 16),
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF777D85), Color(0xFF292D34), Color(0xFF111318)],
      ).createShader(const Rect.fromLTWH(-70, -60, 140, 120));
    final line = Paint()
      ..color = const Color(0xFF9B9EA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (categoria == 'Aceites') {
      canvas.rotate(-.13);
      final bottle = Path()
        ..moveTo(-31, -37)
        ..lineTo(-21, -50)
        ..lineTo(17, -50)
        ..lineTo(23, -37)
        ..lineTo(36, -24)
        ..lineTo(36, 52)
        ..quadraticBezierTo(0, 64, -36, 52)
        ..lineTo(-36, -24)
        ..close();
      canvas.drawPath(bottle, metal);
      canvas.drawPath(bottle, line);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, -63, 42, 17),
          const Radius.circular(3),
        ),
        Paint()..color = AppTheme.oro,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-28, -14, 56, 52),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFB8995B),
      );
      _text(canvas, '7100', const Offset(-22, -9), 23, const Color(0xFF181A1D));
      _text(
        canvas,
        '4T • 10W-40',
        const Offset(-23, 18),
        8,
        const Color(0xFF181A1D),
      );
      _text(canvas, '1L', const Offset(-6, 39), 9, AppTheme.oro);
    } else if (categoria == 'Llantas') {
      canvas.rotate(-.3);
      canvas.drawOval(
        const Rect.fromLTWH(-45, -65, 90, 125),
        Paint()..color = const Color(0xFF0B0D10),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-43, -63, 86, 121),
        Paint()
          ..color = const Color(0xFF3E434B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
      canvas.drawOval(const Rect.fromLTWH(-28, -48, 56, 91), metal);
      canvas.drawOval(
        const Rect.fromLTWH(-20, -37, 40, 69),
        Paint()..color = const Color(0xFF13161B),
      );
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12;
        canvas.drawLine(
          Offset(math.cos(angle) * 37, math.sin(angle) * 57),
          Offset(math.cos(angle + .09) * 44, math.sin(angle + .09) * 62),
          Paint()
            ..color = const Color(0xFF666A71)
            ..strokeWidth = 2,
        );
      }
      canvas.drawArc(
        const Rect.fromLTWH(-38, -58, 76, 111),
        -2.8,
        1.4,
        false,
        Paint()
          ..color = AppTheme.oro
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (nombre.contains('Casco')) {
      canvas.rotate(-.12);
      final helmet = Path()
        ..moveTo(-67, 18)
        ..cubicTo(-75, -72, 37, -91, 65, -21)
        ..lineTo(72, 22)
        ..lineTo(41, 49)
        ..lineTo(-37, 49)
        ..close();
      canvas.drawPath(helmet, metal);
      canvas.drawPath(helmet, line);
      final visor = Path()
        ..moveTo(-54, -12)
        ..quadraticBezierTo(6, -28, 59, -12)
        ..lineTo(63, 10)
        ..quadraticBezierTo(8, 22, -45, 9)
        ..close();
      canvas.drawPath(
        visor,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF111D26), Color(0xFF697A87), Color(0xFF17242D)],
          ).createShader(const Rect.fromLTWH(-54, -20, 117, 40)),
      );
      canvas.drawPath(
        visor,
        Paint()
          ..color = AppTheme.oro.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        const Offset(-23, 32),
        const Offset(21, 32),
        Paint()
          ..color = AppTheme.oro
          ..strokeWidth = 3,
      );
      _text(canvas, 'AM', const Offset(-15, -49), 13, AppTheme.oro);
    } else if (nombre.contains('Guantes')) {
      canvas.rotate(.18);
      final glove = Path()
        ..moveTo(-29, 53)
        ..lineTo(-37, 9)
        ..lineTo(-55, -13)
        ..quadraticBezierTo(-61, -28, -48, -29)
        ..lineTo(-27, -10)
        ..lineTo(-30, -50)
        ..quadraticBezierTo(-26, -66, -16, -53)
        ..lineTo(-10, -17)
        ..lineTo(-10, -61)
        ..quadraticBezierTo(-2, -75, 6, -59)
        ..lineTo(9, -17)
        ..lineTo(15, -55)
        ..quadraticBezierTo(26, -65, 29, -50)
        ..lineTo(26, -10)
        ..lineTo(36, -40)
        ..quadraticBezierTo(49, -47, 47, -30)
        ..lineTo(40, 24)
        ..lineTo(29, 53)
        ..close();
      canvas.drawPath(glove, metal);
      canvas.drawPath(glove, line);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-24, -10, 52, 23),
          const Radius.circular(9),
        ),
        Paint()..color = const Color(0xFF11151A),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(-15 + i * 16, -3),
          Offset(-12 + i * 16, 7),
          Paint()
            ..color = AppTheme.oro
            ..strokeWidth = 3,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-30, 37, 60, 17),
          const Radius.circular(4),
        ),
        Paint()..color = AppTheme.oro,
      );
      _text(canvas, 'AM / PRO', const Offset(-20, 40), 8, AppTheme.fondo);
    } else if (nombre.contains('Escape')) {
      canvas.rotate(-.4);
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-66, -25, 116, 50),
        const Radius.circular(15),
      );
      canvas.drawRRect(body, metal);
      canvas.drawRRect(body, line);
      canvas.drawOval(
        const Rect.fromLTWH(35, -24, 28, 48),
        Paint()..color = const Color(0xFF090C10),
      );
      canvas.drawOval(const Rect.fromLTWH(39, -18, 19, 36), line);
      canvas.drawRect(
        const Rect.fromLTWH(-48, -15, 52, 28),
        Paint()..color = AppTheme.oro,
      );
      _text(canvas, 'AK', const Offset(-39, -11), 19, AppTheme.fondo);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-88, -13, 26, 26),
          const Radius.circular(5),
        ),
        metal,
      );
    } else if (nombre.contains('Cadena')) {
      canvas.rotate(-.35);
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8;
        canvas.save();
        canvas.translate(math.cos(a) * 59, math.sin(a) * 37);
        canvas.rotate(a + math.pi / 2);
        final link = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -8, 24, 16),
          const Radius.circular(6),
        );
        canvas.drawRRect(link, metal);
        canvas.drawRRect(
          link,
          Paint()
            ..color = AppTheme.oro
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawCircle(const Offset(-6, 0), 2.5, line);
        canvas.drawCircle(const Offset(6, 0), 2.5, line);
        canvas.restore();
      }
    } else {
      canvas.rotate(-.22);
      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-49, -44, 98, 91),
        const Radius.circular(22),
      );
      canvas.drawRRect(rect, metal);
      canvas.drawRRect(rect, line);
      canvas.drawCircle(
        Offset.zero,
        28,
        Paint()..color = const Color(0xFF12151A),
      );
      canvas.drawCircle(
        Offset.zero,
        25,
        Paint()
          ..color = AppTheme.oro.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawCircle(
          Offset(math.cos(a) * 37, math.sin(a) * 34),
          3,
          Paint()..color = AppTheme.oro,
        );
      }
      _text(canvas, 'AM', const Offset(-13, -10), 16, AppTheme.oro);
    }
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ProductPainter oldDelegate) =>
      oldDelegate.categoria != categoria || oldDelegate.nombre != nombre;
}

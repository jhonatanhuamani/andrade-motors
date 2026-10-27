import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'premium_components.dart';

/// Fotografía local con la ilustración original como respaldo.
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key, required this.onTap, this.imagen});
  final VoidCallback onTap;
  final ImageProvider? imagen;

  Widget _buildImage() {
    Widget frameBuilder(
      BuildContext context,
      Widget child,
      int? frame,
      bool wasSynchronouslyLoaded,
    ) => frame == null && !wasSynchronouslyLoaded
        ? const CustomPaint(painter: MotoShowcasePainter())
        : child;

    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) => const CustomPaint(painter: MotoShowcasePainter());

    if (imagen != null) {
      return Image(
        image: imagen!,
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
      );
    }
    return Image.asset(
      'assets/images/banner/moto_principal.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomRight,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppTheme.linea),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF323027), Color(0xFF171B20), Color(0xFF101216)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('SELECCIÓN PREMIUM'),
              const SizedBox(height: 18),
              const Text(
                'EQUIPA TU',
                style: TextStyle(
                  fontSize: 35,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const Text(
                'PASIÓN.',
                style: TextStyle(
                  fontSize: 48,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  color: AppTheme.oro,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Repuestos y accesorios seleccionados\npara llevar tu moto al siguiente nivel.',
                style: TextStyle(
                  color: Color(0xFFBCBDBB),
                  height: 1.6,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: constraints.maxWidth < 300 ? 145 : 185,
            child: _buildImage(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTap,
                  label: const Text('Explorar catálogo'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                '01 / 03',
                style: TextStyle(
                  color: AppTheme.secundario,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Silueta editorial vectorial: reserva el espacio de una futura foto de moto.
class MotoShowcasePainter extends CustomPainter {
  const MotoShowcasePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 9);
    final scale = (size.width / 350).clamp(.5, 1.45);
    canvas.scale(scale);
    canvas.drawOval(
      const Rect.fromLTWH(-155, 45, 310, 22),
      Paint()
        ..color = Colors.black.withValues(alpha: .7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      const Offset(35, -25),
      92,
      Paint()..color = AppTheme.oro.withValues(alpha: .035),
    );
    canvas.drawCircle(
      const Offset(35, -25),
      78,
      Paint()
        ..color = AppTheme.oro.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final x in [-107.0, 109.0]) {
      canvas.drawCircle(
        Offset(x, 22),
        39,
        Paint()..color = const Color(0xFF080A0D),
      );
      canvas.drawCircle(
        Offset(x, 22),
        32,
        Paint()
          ..color = const Color(0xFF565C65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        Offset(x, 22),
        23,
        Paint()
          ..color = const Color(0xFF252B33)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.translate(x, 22);
        canvas.rotate(i * 1.2566);
        canvas.drawLine(
          Offset.zero,
          const Offset(0, 29),
          Paint()
            ..color = const Color(0xFF8A8E94)
            ..strokeWidth = 2,
        );
        canvas.restore();
      }
    }
    final frame = Paint()
      ..color = const Color(0xFF72777F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(-107, 22)
        ..lineTo(-39, -20)
        ..lineTo(27, 23)
        ..lineTo(-107, 22)
        ..moveTo(109, 22)
        ..lineTo(71, -51),
      frame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-38, -18, 65, 51),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF363D47),
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(-28, -7 + i * 8),
        Offset(16, -7 + i * 8),
        Paint()
          ..color = const Color(0xFF81858A)
          ..strokeWidth = 2,
      );
    }
    final body = Path()
      ..moveTo(-116, -31)
      ..lineTo(-63, -31)
      ..quadraticBezierTo(-40, -64, -5, -54)
      ..lineTo(43, -43)
      ..lineTo(67, -65)
      ..lineTo(87, -47)
      ..lineTo(61, -16)
      ..lineTo(27, -8)
      ..lineTo(-9, -23)
      ..lineTo(-60, -17)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8CA87), Color(0xFFAF8950), Color(0xFF4B402E)],
        ).createShader(const Rect.fromLTWH(-116, -65, 203, 57)),
    );
    canvas.drawLine(
      const Offset(-111, -35),
      const Offset(-62, -35),
      Paint()
        ..color = const Color(0xFF080B0F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(const Offset(62, -59), const Offset(56, -76), frame);
    canvas.drawLine(const Offset(56, -76), const Offset(37, -79), frame);
    canvas.drawLine(
      const Offset(-57, 31),
      const Offset(-98, 3),
      Paint()
        ..color = const Color(0xFF959AA1)
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(77, -39),
      const Offset(88, -39),
      Paint()
        ..color = const Color(0xFFFFEBC5)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MotoShowcasePainter oldDelegate) => false;
}

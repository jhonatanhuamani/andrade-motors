import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

class PresentacionScreen extends StatefulWidget {
  const PresentacionScreen({super.key, required this.child});

  final Widget child;

  @override
  State<PresentacionScreen> createState() => _PresentacionScreenState();
}

class _PresentacionScreenState extends State<PresentacionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _opacity;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1750),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() => _visible = false);
          }
        });
    _opacity = _animation.drive(
      CurveTween(curve: const Interval(0, .35, curve: Curves.easeOut)),
    );
    _animation.forward();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeFocus(
        excluding: _visible,
        child: Offstage(offstage: _visible, child: widget.child),
      ),
      if (_visible)
        Material(
          color: Colors.black,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: FadeTransition(
                    opacity: MediaQuery.disableAnimationsOf(context)
                        ? const AlwaysStoppedAnimation(1)
                        : _opacity,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AndradeLogo(size: 128),
                        SizedBox(height: 24),
                        Text(
                          'ANDRADE MOTORS',
                          style: TextStyle(
                            color: AppTheme.texto,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'PASIÓN EN MOVIMIENTO',
                          style: TextStyle(
                            color: AppTheme.oro,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

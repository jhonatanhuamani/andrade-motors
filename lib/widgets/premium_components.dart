import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AndradeBrand extends StatelessWidget {
  const AndradeBrand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: AppTheme.gradienteOro,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.two_wheeler_rounded,
          color: Color(0xFF231C12),
          size: 27,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ANDRADE MOTORS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'PASIÓN EN MOVIMIENTO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.oro,
                fontSize: 6.5,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class PremiumPanel extends StatelessWidget {
  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gold = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: gold ? AppTheme.oro.withValues(alpha: .35) : AppTheme.linea,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gold
            ? [const Color(0xFF302A20), const Color(0xFF191B1E)]
            : [const Color(0xFF1D2127), AppTheme.superficie],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppTheme.oro});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 9,
      letterSpacing: 2.2,
      fontWeight: FontWeight.w800,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String? subtitle, action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppTheme.secundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.text, {
    super.key,
    this.color = AppTheme.verde,
    this.icon,
  });
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: .17)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon ?? Icons.circle, size: icon == null ? 5 : 12, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 44, this.gold = true});
  final IconData icon;
  final double size;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: gold ? AppTheme.oro.withValues(alpha: .1) : AppTheme.elevado,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: gold ? AppTheme.oro.withValues(alpha: .18) : AppTheme.linea,
      ),
    ),
    child: Icon(
      icon,
      color: gold ? AppTheme.oro : AppTheme.secundario,
      size: size * .48,
    ),
  );
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });
  final String kicker, title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(kicker),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secundario, height: 1.6),
        ),
      ],
    ),
  );
}

class ResponsiveProductGrid extends StatelessWidget {
  const ResponsiveProductGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 850
          ? 4
          : constraints.maxWidth >= 620
          ? 3
          : 2;
      return Wrap(
        spacing: 12,
        runSpacing: 16,
        children: children
            .map(
              (child) => SizedBox(
                width: (constraints.maxWidth - (count - 1) * 12) / count,
                child: child,
              ),
            )
            .toList(),
      );
    },
  );
}

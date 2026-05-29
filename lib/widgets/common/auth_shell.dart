import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shared auth layout: hero header + rounded white content panel.
class AuthShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBackButton;
  final String? imagePath;
  final IconData? heroIcon;
  final LinearGradient? heroGradient;

  const AuthShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBackButton = true,
    this.imagePath,
    this.heroIcon,
    this.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _HeroHeader(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            imagePath: imagePath,
            heroIcon: heroIcon,
            gradient: heroGradient ?? AppColors.primaryGradient,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final String? imagePath;
  final IconData? heroIcon;
  final LinearGradient gradient;

  const _HeroHeader({
    required this.title,
    this.subtitle,
    required this.showBackButton,
    this.imagePath,
    this.heroIcon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.28,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: gradient),
              ),
            )
          else
            Container(decoration: BoxDecoration(gradient: gradient)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
              top: topPadding + 8,
              left: 16,
              child: _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Row(
              children: [
                if (heroIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(heroIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

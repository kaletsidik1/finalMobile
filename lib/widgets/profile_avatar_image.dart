import 'package:flutter/material.dart';

/// Shows network URL or local asset path for profile images.
class ProfileAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final Color borderColor;
  final double borderWidth;

  const ProfileAvatarImage({
    super.key,
    required this.imageUrl,
    required this.size,
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackIconColor,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  bool get _isAsset => imageUrl.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: ClipOval(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (_isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (_isAsset) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.12),
      child: Icon(
        fallbackIcon,
        color: fallbackIconColor ?? Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

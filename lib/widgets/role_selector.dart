import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final Function(UserRole) onRoleSelected;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoleCard(
          role: UserRole.farmer,
          selectedRole: selectedRole,
          onTap: onRoleSelected,
          icon: Icons.agriculture_rounded,
          label: 'Farmer',
          description: 'Sell crops, get AI recommendations',
          gradient: AppColors.primaryGradient,
        ),
        const SizedBox(height: 14),
        _RoleCard(
          role: UserRole.trader,
          selectedRole: selectedRole,
          onTap: onRoleSelected,
          icon: Icons.storefront_rounded,
          label: 'Trader',
          description: 'Buy from farmers, manage orders',
          gradient: AppColors.traderGradient,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final Function(UserRole) onTap;
  final IconData icon;
  final String label;
  final String description;
  final LinearGradient gradient;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () => onTap(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.primary : Colors.black)
                  .withValues(alpha: isSelected ? 0.18 : 0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

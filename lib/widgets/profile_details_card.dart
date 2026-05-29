import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';

class ProfileDetailsCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileDetailsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <_ProfileRow>[
      _ProfileRow(Icons.email_outlined, 'Email', profile.email),
      if (profile.phone != null && profile.phone!.isNotEmpty)
        _ProfileRow(Icons.phone_outlined, 'Phone', profile.phone!),
      if (profile.region != null && profile.region!.isNotEmpty)
        _ProfileRow(Icons.map_outlined, 'Region', profile.region!),
      if (profile.woreda != null && profile.woreda!.isNotEmpty)
        _ProfileRow(Icons.location_city_outlined, 'Woreda', profile.woreda!),
      if (profile.isFarmer && profile.farmLocation != null && profile.farmLocation!.isNotEmpty)
        _ProfileRow(Icons.agriculture_outlined, 'Farm Location', profile.farmLocation!),
      if (profile.isFarmer && profile.farmSize != null)
        _ProfileRow(Icons.square_foot_outlined, 'Farm Size', '${profile.farmSize} ha'),
      if (profile.isTrader && profile.tinNumber != null && profile.tinNumber!.isNotEmpty)
        _ProfileRow(Icons.numbers_outlined, 'TIN', profile.tinNumber!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(row.icon, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                          ),
                          Text(
                            row.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileRow {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow(this.icon, this.label, this.value);
}

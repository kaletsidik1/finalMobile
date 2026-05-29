import 'package:flutter/material.dart';

import '../models/product_model.dart';

class FarmerInfoPopup extends StatelessWidget {
  final Product product;

  const FarmerInfoPopup({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final farmer = product.farmer;
    final farmerName = farmer?.name ?? 'Unknown farmer';
    final phone = (farmer?.phone?.trim().isNotEmpty ?? false)
        ? farmer!.phone!
        : 'Not provided';
    final locationParts = <String>[
      if ((farmer?.region?.trim().isNotEmpty ?? false)) farmer!.region!.trim(),
      if ((farmer?.woreda?.trim().isNotEmpty ?? false)) farmer!.woreda!.trim(),
    ];
    final location =
        locationParts.isEmpty ? 'Not provided' : locationParts.join(', ');

    return AlertDialog(
      title: const Text('Farmer Information'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name', farmerName),
              const SizedBox(height: 8),
              _infoRow('Location', location),
              const SizedBox(height: 8),
              _infoRow('Phone', phone),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

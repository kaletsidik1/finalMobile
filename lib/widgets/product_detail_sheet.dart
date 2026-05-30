import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

void showProductDetailSheet(BuildContext context, Product product) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ProductDetailContent(product: product),
          );
        },
      );
    },
  );
}

class ProductDetailContent extends StatelessWidget {
  final Product product;

  const ProductDetailContent({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final farmer = product.farmer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ETB ${product.price.toStringAsFixed(2)} / ${product.unit}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.traderAccent,
                    ),
                  ),
                  if (product.isOrganic) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Organic',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Product details',
          children: [
            _DetailRow(label: 'Category', value: product.category.isEmpty ? '—' : product.category),
            _DetailRow(label: 'Stock', value: '${product.stock} ${product.unit}'),
            _DetailRow(label: 'Location', value: product.location.isEmpty ? '—' : product.location),
            _DetailRow(
              label: 'Availability',
              value: product.isAvailable && product.stock > 0 ? 'Available' : 'Unavailable',
            ),
            if (product.harvestDate.isNotEmpty)
              _DetailRow(label: 'Harvest date', value: product.harvestDate),
            if (product.expiryDate != null && product.expiryDate!.isNotEmpty)
              _DetailRow(label: 'Expiry date', value: product.expiryDate!),
          ],
        ),
        if (product.description != null && product.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Description',
            children: [
              Text(
                product.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Farmer',
          children: [
            _DetailRow(label: 'Name', value: farmer?.name ?? 'Not provided'),
            _DetailRow(
              label: 'Region',
              value: farmer?.region?.trim().isNotEmpty == true
                  ? farmer!.region!
                  : 'Not provided',
            ),
            _DetailRow(
              label: 'Woreda',
              value: farmer?.woreda?.trim().isNotEmpty == true
                  ? farmer!.woreda!
                  : 'Not provided',
            ),
            _DetailRow(
              label: 'Phone',
              value: farmer?.phone?.trim().isNotEmpty == true
                  ? farmer!.phone!
                  : 'Not provided',
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import '../models/product_model.dart';
import '../widgets/farmer/farmer_dashboard_header.dart';

class FarmerNotificationService {
  FarmerNotificationService._();

  static List<FarmerInboxMessage> fromProducts(
    List<Product> products, {
    Set<String> readIds = const {},
  }) {
    final messages = <FarmerInboxMessage>[];

    if (products.isEmpty) {
      messages.add(
        FarmerInboxMessage(
          id: 'no_products',
          title: 'Start selling on AgriMarket',
          body:
              'You have no marketplace listings yet. Open the Market tab and tap + to add your first product.',
          timeAgo: 'Now',
          isRead: readIds.contains('no_products'),
        ),
      );
      return messages;
    }

    for (final product in products) {
      if (!product.isAvailable || product.stock <= 0) {
        final id = 'inactive_${product.id}';
        messages.add(
          FarmerInboxMessage(
            id: id,
            title: 'Listing inactive: ${product.name}',
            body: product.stock <= 0
                ? 'Stock is depleted. Restock or remove this listing from Market.'
                : 'This product is marked unavailable on the marketplace.',
            timeAgo: 'Recently',
            isRead: readIds.contains(id),
          ),
        );
      } else if (product.stock < 5) {
        final id = 'low_${product.id}';
        messages.add(
          FarmerInboxMessage(
            id: id,
            title: 'Low stock: ${product.name}',
            body:
                'Only ${product.stock} ${product.unit} left at ETB ${product.price.toStringAsFixed(0)} per ${product.unit}.',
            timeAgo: 'Today',
            isRead: readIds.contains(id),
          ),
        );
      }
    }

    final active = products.where((p) => p.isAvailable && p.stock > 0).length;
    if (active > 0) {
      const id = 'active_summary';
      messages.add(
        FarmerInboxMessage(
          id: id,
          title: '$active active listing${active == 1 ? '' : 's'}',
          body:
              'Your marketplace has ${products.length} total product${products.length == 1 ? '' : 's'}. Tap Market to manage them.',
          timeAgo: 'Just now',
          isRead: readIds.contains(id),
        ),
      );
    }

    messages.sort((a, b) {
      if (a.isRead == b.isRead) return 0;
      return a.isRead ? 1 : -1;
    });

    return messages.take(12).toList();
  }
}

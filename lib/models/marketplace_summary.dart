import 'product_model.dart';

class MarketplaceSummary {
  final double inventoryValueEtb;
  final int soldOrInactiveCount;
  final int activeListings;
  final int lowStockCount;

  const MarketplaceSummary({
    this.inventoryValueEtb = 0,
    this.soldOrInactiveCount = 0,
    this.activeListings = 0,
    this.lowStockCount = 0,
  });

  static MarketplaceSummary fromProducts(List<Product> products) {
    var inventory = 0.0;
    var active = 0;
    var soldOrInactive = 0;
    var lowStock = 0;

    for (final p in products) {
      final isActive = p.isAvailable && p.stock > 0;
      if (isActive) {
        active++;
        inventory += p.price * p.stock;
        if (p.stock < 5) lowStock++;
      } else {
        soldOrInactive++;
      }
    }

    return MarketplaceSummary(
      inventoryValueEtb: inventory,
      soldOrInactiveCount: soldOrInactive,
      activeListings: active,
      lowStockCount: lowStock,
    );
  }

  String get formattedInventoryValue {
    if (inventoryValueEtb >= 1000) {
      return 'ETB ${inventoryValueEtb.toStringAsFixed(0)}';
    }
    return 'ETB ${inventoryValueEtb.toStringAsFixed(2)}';
  }
}

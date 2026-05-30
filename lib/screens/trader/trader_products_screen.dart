import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/product_detail_sheet.dart';

class TraderProductsScreen extends StatefulWidget {
  const TraderProductsScreen({super.key});

  @override
  State<TraderProductsScreen> createState() => _TraderProductsScreenState();
}

class _TraderProductsScreenState extends State<TraderProductsScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  String? _selectedCategory;
  bool? _availableOnly = true;

  static const _categories = [
    'VEGETABLES',
    'FRUITS',
    'GRAINS',
    'DAIRY',
    'MEAT',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return products;

    return products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _apiService.fetchProducts(
      category: _selectedCategory,
      available: _availableOnly,
      limit: 50,
    );

    if (!mounted) return;

    if (result.unauthorized) {
      await logoutAndRedirect(context);
      return;
    }

    setState(() {
      isLoading = false;
      if (result.success) {
        products = result.products;
        errorMessage = null;
      } else {
        errorMessage = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer Market',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse produce listed by farmers',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search crops, regions...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ..._categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    fetchProducts();
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Available'),
                selected: _availableOnly == true,
                onSelected: (selected) {
                  setState(() => _availableOnly = selected ? true : null);
                  fetchProducts();
                },
                selectedColor: AppColors.traderAccent.withValues(alpha: 0.15),
                checkmarkColor: AppColors.traderAccent,
              ),
            ],
          ),
        ),
        Expanded(child: _buildProductList()),
      ],
    );
  }

  Widget _buildProductList() {
    if (isLoading && products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.traderAccent),
      );
    }

    if (errorMessage != null && products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.traderAccent,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filteredProducts;

    if (items.isEmpty) {
      return Center(
        child: Text(
          isLoading ? 'Loading products...' : 'No farmer products found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchProducts,
      color: AppColors.traderAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TraderProductRow(
              product: items[index],
              onTap: () => showProductDetailSheet(context, items[index]),
            ),
          );
        },
      ),
    );
  }
}

class TraderProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const TraderProductRow({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                    if (product.farmer?.name != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Farmer: ${product.farmer!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ETB ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.traderAccent,
                    ),
                  ),
                  Text(
                    '/${product.unit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                  if (product.isOrganic)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Organic',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

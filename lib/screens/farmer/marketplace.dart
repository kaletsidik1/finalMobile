import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/add_product.dart';
import '../../utils/logout_helper.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _apiService = ApiService();
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  static const int _pageLimit = 10;

  String? _selectedCategory;
  bool? _availableOnly;

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
  }

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (loadMore && (isLoadingMore || currentPage >= totalPages)) return;

    setState(() {
      if (loadMore) {
        isLoadingMore = true;
      } else {
        isLoading = true;
      }
      errorMessage = null;
    });

    try {
      final response = await _apiService.getMyProducts(
        category: _selectedCategory,
        available: _availableOnly,
        page: currentPage,
        limit: _pageLimit,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final newProducts = (response.data['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            products.addAll(newProducts);
          } else {
            products = newProducts;
          }
          totalPages = response.data['pagination']?['pages'] ?? 1;
          currentPage = response.data['pagination']?['page'] ?? 1;
          isLoading = isLoadingMore = false;
        });
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load products');
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = isLoadingMore = false);
    }
  }

  Future<void> addProduct(Product product) async {
    setState(() => isLoading = true);
    try {
      final response = await _apiService.createProduct(product.toCreateJson());

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        currentPage = 1;
        await fetchProducts();
        if (mounted) Navigator.pop(context);
        _showSnackBar('Product added successfully', AppColors.primary);
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add product');
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id.isEmpty) {
      _showSnackBar('Invalid product id', AppColors.error);
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await _apiService.updateProduct(
        product.id,
        product.toUpdateJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        await fetchProducts();
        if (mounted) Navigator.pop(context);
        _showSnackBar('Product updated successfully', AppColors.primary);
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update product');
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openEditDialog(Product product) {
    showDialog(
      context: context,
      builder: (_) => AddProductDialog(
        product: product,
        onSubmit: updateProduct,
      ),
    );
  }

  Future<void> deleteProduct(String id) async {
    if (id.isEmpty) {
      _showSnackBar('Invalid product id', AppColors.error);
      return;
    }

    try {
      final response = await _apiService.deleteProduct(id);

      if ((response.statusCode == 200 || response.statusCode == 204) &&
          (response.data == null ||
              response.data is! Map ||
              response.data['success'] != false)) {
        await fetchProducts();
        _showSnackBar('Product deleted', AppColors.primary);
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else {
        final message = response.data is Map
            ? response.data['message'] ?? 'Failed to delete product'
            : 'Failed to delete product';
        throw Exception(message);
      }
    } catch (e) {
      _showSnackBar('Error deleting: $e', AppColors.error);
    }
  }

  Future<void> _handleUnauthorized() async {
    if (mounted) await logoutAndRedirect(context);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to remove this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Marketplace',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                              ),
                        ),
                        Text(
                          'Manage your product listings',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      currentPage = 1;
                      fetchProducts();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 4),
                  FloatingActionButton.small(
                    heroTag: 'add_product',
                    backgroundColor: AppColors.primary,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddProductDialog(onSubmit: addProduct),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
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
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All categories')),
                        ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                        currentPage = 1;
                        fetchProducts();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Available'),
                    selected: _availableOnly == true,
                    onSelected: (selected) {
                      setState(() {
                        _availableOnly = selected ? true : null;
                      });
                      currentPage = 1;
                      fetchProducts();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  currentPage = 1;
                  await fetchProducts();
                },
                color: AppColors.primary,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading your products...'),
          ],
        ),
      );
    }

    if (errorMessage != null && products.isEmpty) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load products',
        subtitle: errorMessage!,
        actionLabel: 'Retry',
        onAction: () {
          currentPage = 1;
          fetchProducts();
        },
      );
    }

    if (products.isEmpty) {
      return _EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        subtitle: 'Tap + to list your first product on the marketplace',
        actionLabel: 'Add Product',
        onAction: () => showDialog(
          context: context,
          builder: (_) => AddProductDialog(onSubmit: addProduct),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: products.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return ProductCard(
          product: products[index],
          onEdit: () => _openEditDialog(products[index]),
          onDelete: () => _confirmDelete(products[index].id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(icon, size: 72, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

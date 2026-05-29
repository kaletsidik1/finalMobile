import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/profile_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/profile_details_card.dart';
import '../../widgets/welcome_card.dart';
import 'trader_products_screen.dart';
class TraderDashboard extends StatefulWidget {
  const TraderDashboard({super.key});

  @override
  State<TraderDashboard> createState() => _TraderDashboardState();
}

class _TraderDashboardState extends State<TraderDashboard> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  List<Product> _previewProducts = [];
  bool _isLoadingPreview = true;

  static const _defaultImage = 'assets/images/welcome.jpg';

  static const _navItems = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppNavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Browse',
    ),
    AppNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Orders',
    ),
    AppNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPreviewProducts();
  }

  Future<void> _loadPreviewProducts() async {
    try {
      final response = await _apiService.getProducts(
        available: true,
        page: 1,
        limit: 3,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            _previewProducts =
                list.map((json) => Product.fromJson(json)).toList();
            _isLoadingPreview = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _apiService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const SafeArea(child: TraderProductsScreen()),
          _buildPlaceholderTab(
            icon: Icons.receipt_long_rounded,
            title: 'Your Orders',
            subtitle: 'Track purchases and deliveries from farmers',
          ),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
        selectedColor: AppColors.traderAccent,
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trader Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                        ),
                  ),
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WelcomeCard(
                    farmerName: _profile?.name ?? 'Trader',
                    farmName: _profile?.displaySubtitle.isNotEmpty == true
                        ? _profile!.displaySubtitle
                        : 'Your business',
                    profileImageUrl: _profile?.avatarUrl ?? _defaultImage,
                    gradient: AppColors.traderGradient,
                    onViewProfile: () => setState(() => _selectedIndex = 3),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Active Orders',
                          value: '3',
                          icon: Icons.local_shipping_outlined,
                          color: AppColors.traderAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Saved Farmers',
                          value: '12',
                          icon: Icons.people_outline,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fresh Listings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover produce from verified farmers',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingPreview)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: AppColors.traderAccent,
                        ),
                      ),
                    )
                  else if (_previewProducts.isEmpty)
                    Text(
                      'No listings available right now',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ..._previewProducts.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TraderProductRow(product: p),
                      ),
                    ),
                  const SizedBox(height: 8),                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Browse All Products'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.traderAccent,
                        side: const BorderSide(color: AppColors.traderAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_isLoadingProfile) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.traderAccent),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.traderAccent.withValues(alpha: 0.1),
              backgroundImage: _profile?.avatarUrl != null
                  ? NetworkImage(_profile!.avatarUrl!)
                  : null,
              child: _profile?.avatarUrl == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: AppColors.traderAccent,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _profile?.name ?? 'Trader',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            if (_profile?.displaySubtitle.isNotEmpty == true)
              Text(
                _profile!.displaySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            if (_profile != null) ProfileDetailsCard(profile: _profile!),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => logoutAndRedirect(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.traderAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppColors.traderAccent),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

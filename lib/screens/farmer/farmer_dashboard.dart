import 'package:flutter/material.dart';
import '../../models/crop_model.dart';
import '../../models/marketplace_summary.dart';
import '../../models/product_model.dart';
import '../../models/profile_model.dart';
import '../../services/api_service.dart';
import '../../services/farmer_notification_service.dart';
import '../../services/token_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/farmer/farmer_dashboard_header.dart';
import '../../widgets/farmer/farmer_dashboard_sections.dart';
import '../../widgets/farmer/farmer_weather_card.dart';
import 'farmer_chat_screen.dart';
import 'farmer_profile.dart';
import 'farms_screen.dart';
import 'marketplace.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  final GlobalKey<MarketplaceScreenState> _marketplaceKey = GlobalKey();

  UserProfile? _profile;
  bool _isLoadingProfile = true;
  bool _isLoadingMarketplace = true;
  List<Product> _products = [];
  MarketplaceSummary _marketplaceSummary = const MarketplaceSummary();
  List<FarmerInboxMessage> _notifications = [];

  static const _defaultImage = 'assets/images/welcome.png';
  static const _listingImages = [
    'assets/images/Crop1.jpg',
    'assets/images/Crop2.jpg',
    'assets/images/Crop3.jpg',
    'assets/images/Crop4.jpg',
    'assets/images/Crop5.jpg',
    'assets/images/Crop6.jpg',
  ];

  static const _navItems = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppNavItem(
      icon: Icons.agriculture_outlined,
      activeIcon: Icons.agriculture_rounded,
      label: 'Farms',
    ),
    AppNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
    ),
    AppNavItem(
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      label: 'Market',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMarketplaceData();
  }

  Future<void> _loadProfile() async {
    final profile = await _apiService.getProfile();
    final storedName = await TokenStorage.getUserName();
    final storedFarm = await TokenStorage.getFarmSubtitle();

    if (mounted) {
      setState(() {
        final resolvedName = (profile?.name.isNotEmpty == true)
            ? profile!.name
            : (storedName?.isNotEmpty == true ? storedName! : 'Farmer');

        if (profile != null) {
          _profile = UserProfile(
            id: profile.id,
            name: resolvedName,
            email: profile.email,
            role: profile.role,
            phone: profile.phone,
            region: profile.region,
            woreda: profile.woreda,
            farmLocation: profile.farmLocation ?? storedFarm,
            farmSize: profile.farmSize,
            tinNumber: profile.tinNumber,
            avatarUrl: profile.avatarUrl,
          );
        } else if (storedName != null && storedName.isNotEmpty) {
          _profile = UserProfile(
            name: storedName,
            email: '',
            role: 'farmer',
            farmLocation: storedFarm,
          );
        }
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadMarketplaceData() async {
    setState(() => _isLoadingMarketplace = true);

    final result = await _apiService.fetchMyProducts(limit: 50);

    if (!mounted) return;

    if (result.unauthorized) {
      await logoutAndRedirect(context);
      return;
    }

    final products = result.success ? result.products : <Product>[];
    final readIds = await TokenStorage.getReadNotificationIds();

    setState(() {
      _products = products;
      _marketplaceSummary = MarketplaceSummary.fromProducts(products);
      _notifications = FarmerNotificationService.fromProducts(
        products,
        readIds: readIds,
      );
      _isLoadingMarketplace = false;
    });
  }

  Future<void> _markNotificationRead(String id) async {
    await TokenStorage.markNotificationRead(id);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((m) => m.id == id ? m.copyWith(isRead: true) : m)
          .toList();
    });
  }

  Future<void> _openEditProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const FarmerProfileScreen()),
    );
    await _loadProfile();
    await _loadMarketplaceData();
  }

  String get _farmerName => _profile?.name ?? 'Farmer';

  String get _firstName {
    final parts = _farmerName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Farmer';
  }

  String get _cropRegion => _profile?.region?.trim() ?? 'Oromia';

  String get _profileImageUrl {
    final url = _profile?.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return _defaultImage;
  }

  List<ActiveListingItem> get _activeListings {
    final active = _products.where((p) => p.isAvailable && p.stock > 0).toList();
    return active.take(4).toList().asMap().entries.map((entry) {
      final p = entry.value;
      final image = _listingImages[entry.key % _listingImages.length];
      return ActiveListingItem(
        name: p.name,
        priceLine: 'ETB ${p.price.toStringAsFixed(0)}/${p.unit}',
        statusLine: '${p.stock} ${p.unit}',
        imageAsset: image,
        statusHighlight: p.stock < 5,
      );
    }).toList();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _loadMarketplaceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(),
          const FarmsScreen(),
          FarmerChatScreen(
            defaultRegion: _cropRegion,
            onNavigateToFarms: () => setState(() => _selectedIndex = 1),
          ),
          MarketplaceScreen(key: _marketplaceKey),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }

  Widget _buildHomeScreen() {
    if (_isLoadingProfile) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final featuredCrop = topProfitableCrops.firstWhere(
      (c) => c.isRecommended,
      orElse: () => topProfitableCrops.first,
    );

    return ColoredBox(
      color: AppColors.surface,
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          await _loadMarketplaceData();
          await _marketplaceKey.currentState?.fetchProducts();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FarmerDashboardHeader(
                farmerName: _farmerName,
                profileImageUrl: _profileImageUrl,
                messages: _notifications,
                onNotificationRead: _markNotificationRead,
                onEditProfile: _openEditProfile,
                onLogout: () => logoutAndRedirect(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FarmerWeatherCard(greetingName: _firstName),
                    const SizedBox(height: 16),
                    const FarmerVerificationBanner(),
                    const SizedBox(height: 12),
                    _ManageFarmsCard(onTap: () => _onNavTap(1)),
                    const SizedBox(height: 12),
                    MarketplaceAnalyticsCard(
                      summary: _marketplaceSummary,
                      isLoading: _isLoadingMarketplace,
                    ),
                    const CommodityTickerCard(),
                    AiCropRecommendationsCard(
                      region: _cropRegion,
                      featuredCrop: featuredCrop,
                    ),
                    ActiveListingsSection(
                      listings: _activeListings,
                      onViewAll: () {
                        setState(() => _selectedIndex = 3);
                        _marketplaceKey.currentState?.fetchProducts();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageFarmsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ManageFarmsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.9),
              const Color(0xFF3A7D3A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Your Farms',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register, edit or view your farm lands',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

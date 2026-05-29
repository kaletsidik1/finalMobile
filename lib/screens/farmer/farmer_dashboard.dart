import 'package:flutter/material.dart';
import '../../models/crop_model.dart';
import '../../models/profile_model.dart';
import '../../services/api_service.dart';
import '../../services/token_storage.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_helper.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/farmer/farmer_dashboard_header.dart';
import '../../widgets/farmer/farmer_dashboard_sections.dart';
import '../../widgets/farmer/farmer_weather_card.dart';
import 'farmer_chat_screen.dart';
import 'marketplace.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  UserProfile? _profile;
  bool _isLoadingProfile = true;

  static const _defaultImage = 'assets/images/welcome.jpg';

  static const _navItems = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
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

  static const _activeListings = [
    ActiveListingItem(
      name: 'Premium Teff',
      priceLine: 'ETB 6200/qtl',
      statusLine: '15 qtl',
      imageAsset: 'assets/images/Crop1.jpg',
    ),
    ActiveListingItem(
      name: 'White Maize',
      priceLine: 'ETB 2950/qtl',
      statusLine: '20 qtl',
      imageAsset: 'assets/images/Crop2.jpg',
    ),
    ActiveListingItem(
      name: 'Sorghum',
      priceLine: 'ETB 3200/qtl',
      statusLine: '10 qtl',
      imageAsset: 'assets/images/Crop3.jpg',
      statusHighlight: true,
    ),
    ActiveListingItem(
      name: 'Wheat',
      priceLine: 'ETB 3500/qtl',
      statusLine: 'Offer Received',
      imageAsset: 'assets/images/Crop4.jpg',
      statusHighlight: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  String get _farmerName => _profile?.name ?? 'Farmer';

  String get _firstName {
    final parts = _farmerName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Farmer';
  }

  String get _cropRegion => _profile?.region?.trim() ?? 'Oromia';

  List<Widget> get _screens => [
        _buildHomeScreen(),
        FarmerChatScreen(defaultRegion: _cropRegion),
        _selectedIndex == 2
            ? const MarketplaceScreen()
            : const SizedBox.shrink(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FarmerDashboardHeader(
              farmerName: _farmerName,
              profileImageUrl: _profile?.avatarUrl ?? _defaultImage,
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
                  const SizedBox(height: 16),
                  const MarketplaceAnalyticsCard(),
                  const CommodityTickerCard(),
                  AiCropRecommendationsCard(
                    region: _cropRegion,
                    featuredCrop: featuredCrop,
                  ),
                  ActiveListingsSection(
                    listings: _activeListings,
                    onViewAll: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/profile_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/profile_details_card.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TabController _tabController;

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _api.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    final result = await _api.updateProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSavingProfile = false);

    if (result.success) {
      setState(() => _profile = result.profile ?? _profile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Profile updated'),
          backgroundColor: AppColors.primary,
        ),
      );
      if (result.profile != null) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    final result = await _api.updatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSavingPassword = false);

    if (result.success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Password updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to update password'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Account'),
            Tab(text: 'Password'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _profile == null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAccountTab(),
                    _buildPasswordTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Could not load your profile',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Try Again',
              onPressed: _loadProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    final profile = _profile!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person_rounded, size: 44, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              profile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ),
          if (profile.displaySubtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.displaySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.role.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ProfileDetailsCard(profile: profile),
          const SizedBox(height: 24),
          Text(
            'Edit details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Form(
            key: _profileFormKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Full name',
                  hint: 'Your name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'Phone number',
                  hint: 'e.g. 0912345678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Save changes',
                  isLoading: _isSavingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '••••••••',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            letterSpacing: 2,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Update your password to keep your account secure.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Current password',
                hint: 'Enter current password',
                controller: _currentPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'New password',
                hint: 'At least 6 characters',
                controller: _newPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Confirm new password',
                hint: 'Re-enter new password',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Update password',
                isLoading: _isSavingPassword,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

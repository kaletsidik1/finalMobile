import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/auth_shell.dart';
import '../widgets/common/section_title.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/location_picker.dart';

class TraderSignupScreen extends StatefulWidget {
  const TraderSignupScreen({super.key});

  @override
  State<TraderSignupScreen> createState() => _TraderSignupScreenState();
}

class _TraderSignupScreenState extends State<TraderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tinNumberController = TextEditingController();

  String? _selectedRegion;
  String? _selectedWoreda;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_selectedRegion == null || _selectedRegion!.isEmpty) {
      setState(() => _errorMessage = 'Please select your region');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService().register({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': 'TRADER',
      'phone': _phoneController.text.trim(),
      'region': _selectedRegion,
      'woreda': _selectedWoreda,
    });

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted! Your account is pending admin approval.',
          ),
          backgroundColor: AppColors.traderAccent,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = result.message ?? 'Registration failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Trader Registration',
      subtitle: 'Connect with farmers across Ethiopia',
      heroGradient: AppColors.traderGradient,
      heroIcon: Icons.storefront_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SectionTitle(
                title: 'Business Information',
                subtitle: 'Your company or trading details',
                icon: Icons.business_outlined,
              ),
              CustomTextField(
                label: 'Full Name / Business Name',
                hint: 'Enter your name or business name',
                controller: _nameController,
                prefixIcon: Icons.business_outlined,
              ),
              CustomTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              CustomTextField(
                label: 'TIN Number',
                hint: 'Tax Identification Number',
                controller: _tinNumberController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_outlined,
              ),
              const SectionTitle(
                title: 'Business Location',
                icon: Icons.location_on_outlined,
              ),
              LocationPicker(
                selectedRegion: _selectedRegion,
                selectedWoreda: _selectedWoreda,
                onRegionChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                    _selectedWoreda = null;
                  });
                },
                onWoredaChanged: (value) {
                  setState(() => _selectedWoreda = value);
                },
              ),
              const SectionTitle(
                title: 'Account Security',
                icon: Icons.shield_outlined,
              ),
              CustomTextField(
                label: 'Password',
                hint: 'Create a password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.traderAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.traderAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.traderAccent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approval Required',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.traderAccent.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your account will be verified by admin before you can log in.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: 'Register as Trader',
                backgroundColor: AppColors.traderAccent,
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.traderAccent,
                        fontWeight: FontWeight.w600,
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tinNumberController.dispose();
    super.dispose();
  }
}

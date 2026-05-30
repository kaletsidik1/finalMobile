import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../services/token_storage.dart';
import '../theme/app_theme.dart';
import '../utils/ethiopian_phone.dart';
import '../utils/password_strength.dart';
import '../widgets/common/auth_shell.dart';
import '../widgets/common/section_title.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/location_picker.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/ethiopian_phone_field.dart';
import 'farmer/farmer_dashboard.dart';

class FarmerSignupScreen extends StatefulWidget {
  const FarmerSignupScreen({super.key});

  @override
  State<FarmerSignupScreen> createState() => _FarmerSignupScreenState();
}

class _FarmerSignupScreenState extends State<FarmerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRegion;
  String? _selectedWoreda;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _isLoading = false;
  String? _errorMessage;

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordStrength = PasswordStrengthEvaluator.evaluate(value);
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!PasswordStrengthEvaluator.isStrongEnough(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create a strong password with letters, numbers, and symbols (8+ characters).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
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
      'role': 'FARMER',
      'phone': EthiopianPhone.toInternational(_phoneController.text.trim()),
      'region': _selectedRegion,
      'woreda': _selectedWoreda,
    });

    if (!mounted) return;

    if (result.success && result.raw != null) {
      await AuthSession.saveFromLoginResponse(result.raw!);
      await TokenStorage.saveRole('farmer');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to AgriMarket!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FarmerDashboard()),
        (route) => false,
      );
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
      title: 'Farmer Registration',
      subtitle: 'Tell us about yourself and your farm',
      imagePath: 'assets/images/welcome.png',
      heroIcon: Icons.agriculture_rounded,
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
                const SizedBox(height: 12),
              ],
              const SectionTitle(
                title: 'Personal Information',
                subtitle: 'Your account details',
                icon: Icons.person_outline,
              ),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              EthiopianPhoneField(controller: _phoneController),
              CustomTextField(
                label: 'Password',
                hint: 'Min. 8 chars with letters, numbers & symbols',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                onChanged: _onPasswordChanged,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Password is required';
                  }
                  if (!PasswordStrengthEvaluator.isStrongEnough(v)) {
                    return 'Use a strong password (letters, numbers, symbols, 8+ chars)';
                  }
                  return null;
                },
              ),
              PasswordStrengthIndicator(strength: _passwordStrength),
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SectionTitle(
                title: 'Your Location',
                subtitle: 'Region and woreda',
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
              const SizedBox(height: 8),
              CustomButton(
                text: 'Register as Farmer',
                isLoading: _isLoading,
                onPressed: _register,
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
    super.dispose();
  }
}

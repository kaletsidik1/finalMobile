import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/common/auth_shell.dart';
import '../widgets/common/section_title.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_button.dart';
import '../widgets/location_picker.dart';

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
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _cropsController = TextEditingController();

  String? _selectedRegion;
  String? _selectedWoreda;
  String? _selectedExperience;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _experienceLevels = [
    'Beginner (0-2 years)',
    'Intermediate (3-5 years)',
    'Advanced (6-10 years)',
    'Expert (10+ years)',
  ];

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
      'role': 'FARMER',
      'phone': _phoneController.text.trim(),
      'region': _selectedRegion,
      'woreda': _selectedWoreda,
      'farmSize': _farmSizeController.text.trim().isNotEmpty
          ? '${_farmSizeController.text.trim()} hectares'
          : null,
      'crops': _cropsController.text.trim(),
      'experience': _selectedExperience,
    });

    if (!mounted) return;

    if (result.success && result.raw != null) {
      await AuthSession.saveFromLoginResponse(result.raw!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: AppColors.primary,
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
                const SizedBox(height: 16),
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
              const SectionTitle(
                title: 'Farm Information',
                subtitle: 'Help us personalize recommendations',
                icon: Icons.grass_rounded,
              ),
              CustomTextField(
                label: 'Farm Location',
                hint: 'Specific area or village',
                controller: _farmLocationController,
                prefixIcon: Icons.map_outlined,
              ),
              CustomTextField(
                label: 'Farm Size (hectares)',
                hint: 'e.g. 5.5',
                controller: _farmSizeController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.square_foot_outlined,
              ),
              CustomTextField(
                label: 'Crops You Plant',
                hint: 'e.g. Teff, Wheat, Maize',
                controller: _cropsController,
                prefixIcon: Icons.eco_outlined,
              ),
              CustomDropdown<String>(
                label: 'Farming Experience',
                value: _selectedExperience,
                items: _experienceLevels,
                itemLabel: (item) => item,
                onChanged: (value) {
                  setState(() => _selectedExperience = value);
                },
                hint: 'Select your experience level',
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
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _cropsController.dispose();
    super.dispose();
  }
}

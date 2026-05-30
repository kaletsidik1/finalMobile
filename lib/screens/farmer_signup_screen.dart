import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../services/location_service.dart';
import '../services/token_storage.dart';
import '../theme/app_theme.dart';
import '../utils/ethiopian_phone.dart';
import '../utils/password_strength.dart';
import '../widgets/common/auth_shell.dart';
import '../widgets/common/section_title.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
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
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _cropsController = TextEditingController();

  String? _selectedRegion;
  String? _selectedWoreda;
  String? _selectedExperience;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  String? _locationMessage;

  final List<String> _experienceLevels = [
    'Beginner (0-2 years)',
    'Intermediate (3-5 years)',
    'Advanced (6-10 years)',
    'Expert (10+ years)',
  ];

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationMessage = 'Getting your current location…';
    });

    final result = await LocationService.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      _isFetchingLocation = false;
      if (result.hasCoordinates) {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationMessage =
            'Location captured (${result.latitude!.toStringAsFixed(4)}, ${result.longitude!.toStringAsFixed(4)})';
      } else {
        _latitude = null;
        _longitude = null;
        _locationMessage = result.error ?? 'Could not get location';
      }
    });
  }

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

    if (_latitude == null || _longitude == null) {
      await _captureLocation();
      if (_latitude == null || _longitude == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _locationMessage ?? 'Please allow location access to register.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
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
      'latitude': _latitude,
      'longitude': _longitude,
      if (_farmLocationController.text.trim().isNotEmpty)
        'farmLocation': _farmLocationController.text.trim(),
      if (_farmSizeController.text.trim().isNotEmpty)
        'farmSize': '${_farmSizeController.text.trim()} hectares',
      if (_cropsController.text.trim().isNotEmpty)
        'crops': _cropsController.text.trim(),
      if (_selectedExperience != null) 'experience': _selectedExperience,
    });

    if (!mounted) return;

    if (result.success && result.raw != null) {
      await AuthSession.saveFromLoginResponse(result.raw!);
      await TokenStorage.saveRole('farmer');
      await TokenStorage.saveFarmerLocation(
        lat: _latitude!,
        lng: _longitude!,
      );

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
    final locationOk = _latitude != null && _longitude != null;

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
              _LocationStatusCard(
                message: _locationMessage,
                isLoading: _isFetchingLocation,
                isSuccess: locationOk,
                onRetry: _captureLocation,
              ),
              const SizedBox(height: 8),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _LocationStatusCard extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onRetry;

  const _LocationStatusCard({
    required this.message,
    required this.isLoading,
    required this.isSuccess,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess
        ? AppColors.primary
        : isLoading
            ? AppColors.textSecondary
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLoading
                ? Icons.gps_not_fixed
                : isSuccess
                    ? Icons.gps_fixed
                    : Icons.location_off_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'Location status unknown',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          if (!isLoading)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

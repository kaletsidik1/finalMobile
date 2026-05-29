import 'package:flutter/material.dart';
import 'package:agrimatketapp/config/api_config.dart';
import 'package:agrimatketapp/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:agrimatketapp/services/auth_session.dart';
import 'package:agrimatketapp/screens/farmer/farmer_dashboard.dart';
import 'package:agrimatketapp/screens/trader/trader_dashboard.dart';
import 'package:agrimatketapp/screens/auth/signup_screen.dart';
import 'package:agrimatketapp/theme/app_theme.dart';
import 'package:agrimatketapp/widgets/common/auth_shell.dart';
import 'package:agrimatketapp/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome Back',
      subtitle: 'Sign in to your AgriMarket account',
      showBackButton: false,
      imagePath: 'assets/images/welcome.png',
      heroIcon: Icons.agriculture_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!, onDismiss: () {
                  setState(() => _errorMessage = null);
                }),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot password feature coming soon'),
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Login',
                isLoading: _isLoading,
                onPressed: () => _handleLogin(context),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => _navigateToSignUp(context),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 15,
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

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await _apiService.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          await AuthSession.saveFromLoginResponse(responseData);

          Map<String, dynamic>? user;
          final directUser = responseData['user'];
          if (directUser is Map<String, dynamic>) {
            user = directUser;
          } else {
            final nested = responseData['data'];
            if (nested is Map<String, dynamic>) {
              final nestedUser = nested['user'];
              if (nestedUser is Map<String, dynamic>) {
                user = nestedUser;
              } else {
                // Some APIs return the user object directly in `data`.
                user = nested;
              }
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user?['name'] ?? 'User'}!'),
              backgroundColor: AppColors.primary,
            ),
          );

          if (mounted) {
            final roleRaw =
                (user?['role'] ?? responseData['role'] ?? '').toString();
            final role = roleRaw.toLowerCase().trim();
            final isTrader = role == 'trader' || role.contains('trader');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => isTrader
                    ? const TraderDashboard()
                    : const FarmerDashboard(),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Login failed';
            _isLoading = false;
          });
        }
      } else {
        String message = 'Invalid email or password';
        try {
          final responseData = response.data;
          if (responseData is Map<String, dynamic> &&
              responseData['message'] is String) {
            message = responseData['message'];
          }
        } catch (_) {}

        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      String message = 'Connection error. Please check your internet connection.';
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'];
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection error. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}

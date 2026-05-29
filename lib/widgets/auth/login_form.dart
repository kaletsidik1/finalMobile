// lib/widgets/auth/login_form.dart
import 'package:flutter/material.dart';
import '../custom_text_field.dart';
class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            // Email Field with border
            CustomTextField(
              label: '',
              hint: 'Enter your email',
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: _validateEmail,
            ),
            Column(
              children: [
                // Password input field
                CustomTextField(
                  label: '',
                  hint: 'Enter your password',
                  controller: widget.passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: _validatePassword,
                ),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     GestureDetector(
                          onTap: _showForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: const Color(0xFF2A5A2A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                   ],
                 ),
              ],
            ),
            
            const SizedBox(height: 24),
                  // Login Button
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }


  Widget _buildLoginButton() {
    return SizedBox(
      width: 320,
      height: 55,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A5A2A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 2,
        ),
        child: widget.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _showForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent to your email!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
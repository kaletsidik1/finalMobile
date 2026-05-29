import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/auth_shell.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/role_selector.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  UserRole _selectedRole = UserRole.farmer;

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Join AgriMarket',
      subtitle: 'Choose your role to get started',
      imagePath: 'assets/images/welcome.png',
      heroIcon: Icons.eco_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How will you use AgriMarket?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Select the account type that fits you best.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: RoleSelector(
                selectedRole: _selectedRole,
                onRoleSelected: (role) => setState(() => _selectedRole = role),
              ),
            ),
            CustomButton(
              text: 'Continue',
              onPressed: () {
                if (_selectedRole == UserRole.farmer) {
                  Navigator.pushNamed(context, '/farmer-signup');
                } else {
                  Navigator.pushNamed(context, '/trader-signup');
                }
              },
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
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/ethiopian_phone.dart';

class EthiopianPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const EthiopianPhoneField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            maxLength: EthiopianPhone.localLength,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _EthiopianPhoneInputFormatter(),
            ],
            validator: validator ?? EthiopianPhone.validateLocal,
            decoration: const InputDecoration(
              hintText: '912345678',
              counterText: '',
              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
              prefixText: '+251 ',
              prefixStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ensures first digit is 9 when user starts typing.
class _EthiopianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > EthiopianPhone.localLength) {
      text = text.substring(0, EthiopianPhone.localLength);
    }
    if (text.isNotEmpty && !text.startsWith('9')) {
      text = '9${text.replaceFirst(RegExp(r'^9*'), '')}';
      if (text.length > EthiopianPhone.localLength) {
        text = text.substring(0, EthiopianPhone.localLength);
      }
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

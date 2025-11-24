// TODO Implement this library.
// lib/screens/login/widgets/phone_step.dart

import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';

import '../../../keys.dart';

class PhoneStep extends StatelessWidget {
  final String greeting;
  final String selectedDialCode;
  final String selectedCountryCode;
  final TextEditingController phoneController;
  final VoidCallback onGetCode;
  final VoidCallback onSelectCountry; // сейчас не используется, но пусть будет

  const PhoneStep({
    super.key,
    required this.greeting,
    required this.selectedDialCode,
    required this.selectedCountryCode,
    required this.phoneController,
    required this.onGetCode,
    required this.onSelectCountry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("phone"),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          pleaseEnterPhoneNumber.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 28),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            phoneNumber.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                // 👉 как просили — ничего не меняю здесь
                inputFormatters: selectedDialCode == "+7"
                    ? [MaskedInputFormatter("+# (###) ### ####")]
                    : [],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: selectedDialCode == "+7"
                      ? "+7 (777) 123 4567"
                      : "Phone number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // кнопка выбора страны
            GestureDetector(
              onTap: onSelectCountry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCountryCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: onGetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Text(
              getCode.tr(),
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Text(
          weWillSendYouAVerificationCodeBySMS.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // Диалог выбора страны — статический helper, вызываем из LoginScreen
  static Future<void> showCountryDialog({
    required BuildContext context,
    required ValueChanged<CountryCode> onChanged,
    required String initialCountryCode,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 430,
            child: CountryCodePicker(
              onChanged: onChanged,
              initialSelection: initialCountryCode.toUpperCase(),
              showFlag: true,
              showOnlyCountryWhenClosed: false,
              showCountryOnly: false,
              searchDecoration: InputDecoration(
                hintText: 'Search'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

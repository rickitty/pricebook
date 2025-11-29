// TODO Implement this library.
// lib/screens/login/widgets/otp_step.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../keys.dart';

class OtpStep extends StatelessWidget {
  final String phoneText;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onConfirm;
  final VoidCallback onResend;
  final VoidCallback onChangePhone;

  const OtpStep({
    super.key,
    required this.phoneText,
    required this.otpControllers,
    required this.focusNodes,
    required this.onConfirm,
    required this.onResend,
    required this.onChangePhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("otp"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          phoneNumberVerification.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          "${weSentAVerificationCodeTo.tr()} $phoneText",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),

        Text(
          enter6DigitCode.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 58,
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: focusNodes[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.white70,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 121, 126, 255),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(
                          context,
                        ).requestFocus(focusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(
                          context,
                        ).requestFocus(focusNodes[index - 1]);
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Text(
              confirm.tr(),
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              children: [
                TextSpan(text: didNotReceiveTheCode.tr()),
                TextSpan(
                  text: sendAgain.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onResend,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: onChangePhone,
          child: Text(
            changePhoneNumber.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

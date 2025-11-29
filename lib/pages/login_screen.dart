// lib/screens/login/login_screen.dart
// Version rewritten to remove Firebase and use company API
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/config.dart';
import 'package:price_book/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import './home_page.dart';
import 'widgets/phone_step.dart';
import 'widgets/otp_step.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedDialCode = "+7";
  String selectedCountryCode = "kz";

  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool isCodeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightBlue, lightBlue.withOpacity(0.85)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color.fromARGB(99, 255, 255, 255),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                            color: const Color.fromARGB(
                              255,
                              107,
                              123,
                              177,
                            ).withOpacity(0.25),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Price Book',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            secureLogin.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final fade = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              );
                              final slide = Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: fade,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: isCodeSent
                                ? OtpStep(
                                    key: const ValueKey("otp_step"),
                                    phoneText: _phoneController.text,
                                    otpControllers: _otpControllers,
                                    focusNodes: _focusNodes,
                                    onConfirm: _signInWithCode,
                                    onResend: _verifyPhone,
                                    onChangePhone: _resetToPhoneStep,
                                  )
                                : PhoneStep(
                                    key: const ValueKey("phone_step"),
                                    greeting: getGreeting(),
                                    selectedDialCode: selectedDialCode,
                                    selectedCountryCode: selectedCountryCode,
                                    phoneController: _phoneController,
                                    onGetCode: _verifyPhone,
                                    onSelectCountry: _showCountryPicker,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetToPhoneStep() {
    setState(() {
      isCodeSent = false;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
  }

  Future<void> _verifyPhone() async {
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (raw.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(phoneNumber.tr())));
      return;
    }

    if (raw.length != 11) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Введите корректный номер")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(sendCode),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userName": raw}),
      );

      if (response.statusCode == 200) {
        setState(() => isCodeSent = true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.body)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signInWithCode() async {
    final smsCode = _otpControllers.map((c) => c.text).join();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (smsCode.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(enter6DigitCode.tr())));
      return;
    }

    if (rawPhone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Номер телефона должен быть 11 цифр")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": rawPhone, "code": smsCode}),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.body)));
        return;
      }

      final data = jsonDecode(response.body);
      print("Login response data: $data");
      print(
        "Token: ${data["token"]}, Refresh: ${data["refreshToken"]}, Role: ${data["role"]}",
      );
      print("Mounted: $mounted");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", data["token"]);
      await prefs.setString("refreshToken", data["refreshToken"]);
      await prefs.setString("role", data["role"]);
      await prefs.setString("phone", _phoneController.text.replaceAll(RegExp(r'\D'), ''));
      
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(roleFromLogin: data["role"]),
        ),
      );
    } catch (e, st) {
      print("Login exception: $e\n$st");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка при логине: $e")));
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return goodMorning.tr();
    if (hour >= 12 && hour < 18) return goodAfternoon.tr();
    if (hour >= 18 && hour < 23) return goodEvening.tr();
    return goodNight.tr();
  }

  void _showCountryPicker() {
    PhoneStep.showCountryDialog(
      context: context,
      initialCountryCode: selectedCountryCode,
      onChanged: (code) {
        setState(() {
          selectedDialCode = code.dialCode ?? "+7";
          selectedCountryCode = (code.code ?? "KZ").toLowerCase();
        });
      },
    );
  }
}

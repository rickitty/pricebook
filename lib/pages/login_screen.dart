// lib/screens/login/login_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../../keys.dart';
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
  String? _verificationId;

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
            colors: [
              lightBlue,
              // ignore: deprecated_member_use
              lightBlue.withOpacity(0.85),
            ],
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
                        // ignore: deprecated_member_use
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
                            // ignore: deprecated_member_use
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
                          Text(
                            'Price Book',
                            style: const TextStyle(
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
                              final fadeAnimation = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              );
                              final slideAnimation = Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: SlideTransition(
                                  position: slideAnimation,
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
    final raw = _phoneController.text.trim();

    if (raw.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(phoneNumber.tr())));
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: raw,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _afterLogin();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('PHONE AUTH ERROR: code=${e.code}, message=${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.code}\n${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signInWithCode() async {
    if (_verificationId == null) return;

    final smsCode = _otpControllers.map((c) => c.text).join();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(enter6DigitCode.tr())));
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _afterLogin();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _afterLogin() async {
    final user = FirebaseAuth.instance.currentUser!;
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(ensureUser),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Server error: ${response.body}")));
      return;
    }

    final data = jsonDecode(response.body);
    final role = data["role"] ?? "worker";

    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        "phone": user.phoneNumber,
        "role": role,
        "createdAt": DateTime.now(),
      });
    } else {
      await userRef.update({"role": role});
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
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

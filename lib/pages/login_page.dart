// // ignore_for_file: use_build_context_synchronously

// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
// import 'package:price_book/config.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:easy_localization/easy_localization.dart';
// import '../keys.dart';
// import 'home_page.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';


// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   String selectedDialCode = "+7";
//   String selectedCountryCode = "kz";
//   final _phoneController = TextEditingController();
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );
//   final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

//   bool isCodeSent = false;
//   String? _verificationId;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     for (final c in _otpControllers) {
//       c.dispose();
//     }
//     for (final f in _focusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightBlue,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               child: isCodeSent ? _buildOtpInput() : _buildPhoneInput(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPhoneInput() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           getGreeting(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 26,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 8),

//         Text(
//           pleaseEnterPhoneNumber.tr(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(fontSize: 16, color: Colors.white70),
//         ),
//         const SizedBox(height: 32),

//         Text(
//           phoneNumber.tr(),
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 8),

//         Row(
//           children: [
//             Expanded(
//               child: Expanded(
//                 child: TextField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   inputFormatters: selectedDialCode == "+7"
//                       ? [MaskedInputFormatter("+# (###) ### ####")]
//                       : [],
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.white,
//                     hintText: selectedDialCode == "+7"
//                         ? "+7 (777) 123 4567"
//                         : "Phone number",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(18),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             GestureDetector(
//               onTap: () => _showCountryPicker(),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 14,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Text(
//                   selectedCountryCode.toUpperCase(),
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 28),

//         SizedBox(
//           width: 150,
//           height: 40,
//           child: ElevatedButton(
//             onPressed: _verifyPhone,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//             ),
//             child: Text(
//               getCode.tr(),
//               style: const TextStyle(color: Colors.black, fontSize: 18),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           weWillSendYouAVerificationCodeBySMS.tr(),
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.white70, fontSize: 13),
//         ),
//       ],
//     );
//   }

//   Widget _buildOtpInput() {
//     return Column(
//       key: const ValueKey("otp"),
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Text(
//           phoneNumberVerification.tr(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 8),

//         Text(
//           "${weSentAVerificationCodeTo.tr()} ${_phoneController.text}",
//           textAlign: TextAlign.center,
//           style: const TextStyle(color: Colors.white70, fontSize: 14),
//         ),
//         const SizedBox(height: 28),

//         Text(
//           enter6DigitCode.tr(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(color: Colors.white, fontSize: 16),
//         ),
//         const SizedBox(height: 16),

//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(6, (index) {
//             return Container(
//               width: 50,
//               height: 60,
//               margin: const EdgeInsets.symmetric(horizontal: 5),
//               child: TextField(
//                 controller: _otpControllers[index],
//                 focusNode: _focusNodes[index],
//                 maxLength: 1,
//                 textAlign: TextAlign.center,
//                 keyboardType: TextInputType.number,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 decoration: InputDecoration(
//                   counterText: "",
//                   filled: true,
//                   fillColor: Colors.white,
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: Colors.red, width: 2),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: Colors.red, width: 3),
//                   ),
//                 ),
//                 onChanged: (value) {
//                   if (value.isNotEmpty && index < 5) {
//                     FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
//                   } else if (value.isEmpty && index > 0) {
//                     FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
//                   }
//                 },
//               ),
//             );
//           }),
//         ),

//         const SizedBox(height: 28),

//         ElevatedButton(
//           onPressed: _signInWithCode,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(18),
//             ),
//           ),
//           child: Text(
//             confirm.tr(),
//             style: const TextStyle(color: Colors.black, fontSize: 18),
//           ),
//         ),

//         const SizedBox(height: 16),

//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             RichText(
//               text: TextSpan(
//                 style: const TextStyle(color: Colors.white70, fontSize: 14),
//                 children: [
//                   TextSpan(text: "${didNotReceiveTheCode.tr()}?"),
//                   TextSpan(
//                     text: sendAgain.tr(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       decoration: TextDecoration.underline,
//                     ),
//                     recognizer: TapGestureRecognizer()
//                       ..onTap = () => _verifyPhone(),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         GestureDetector(
//           onTap: () {
//             setState(() {
//               isCodeSent = false;
//               for (final c in _otpControllers) {
//                 c.clear();
//               }
//             });
//           },
//           child: Text(
//             changePhoneNumber.tr(),
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//               decoration: TextDecoration.underline,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _verifyPhone() async {
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: _phoneController.text.trim(),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await FirebaseAuth.instance.signInWithCredential(credential);
//         _afterLogin();
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         print('PHONE AUTH ERROR: code=${e.code}, message=${e.message}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.code}\n${e.message}')),
//         );
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           isCodeSent = true;
//         });
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }

//   void _signInWithCode() async {
//     if (_verificationId == null) return;

//     final smsCode = _otpControllers.map((c) => c.text).join();
//     if (smsCode.length != 6) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(enter6DigitCode.tr())));
//       return;
//     }

//     final credential = PhoneAuthProvider.credential(
//       verificationId: _verificationId!,
//       smsCode: smsCode,
//     );

//     try {
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       _afterLogin();
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _afterLogin() async {
//   final user = FirebaseAuth.instance.currentUser!;
//   final idToken = await user.getIdToken();

//   final response = await http.post(
//     Uri.parse(ensureUser),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $idToken',
//     },
//     body: jsonEncode({}),
//   );

//   if (response.statusCode != 200) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Server error: ${response.body}")),
//     );
//     return;
//   }

//   final data = jsonDecode(response.body);
//   final role = data["role"] ?? "worker";

//   final userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

//   final snapshot = await userRef.get();

//   if (!snapshot.exists) {
//     await userRef.set({
//       "phone": user.phoneNumber,
//       "role": role,
//       "createdAt": DateTime.now(),
//     });
//   } else {
//     await userRef.update({
//       "role": role,
//     });
//   }

//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString("role", role);

//   if (!mounted) return;

//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(builder: (_) => HomePage()),
//   );
// }


//   String getGreeting() {
//     final hour = DateTime.now().hour;

//     if (hour >= 5 && hour < 12) return goodMorning.tr();
//     if (hour >= 12 && hour < 18) return goodAfternoon.tr();
//     if (hour >= 18 && hour < 23) return goodEvening.tr();
//     return goodNight.tr();
//   }

//   void _showCountryPicker() {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black54,
//       builder: (_) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: SizedBox(
//             height: 50,
//             width: 80,
//             child: CountryCodePicker(
//               onChanged: (code) {
//                 setState(() {
//                   selectedDialCode = code.dialCode ?? "+7";
//                   selectedCountryCode = (code.code ?? "KZ").toLowerCase();
//                 });
//                 Navigator.pop(context);
//               },
//               initialSelection: selectedCountryCode.toUpperCase(),
//               showFlag: true,
//               showOnlyCountryWhenClosed: false,
//               showCountryOnly: false,
//               searchDecoration: InputDecoration(
//                 hintText: 'Search'.tr(),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

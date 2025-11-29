import 'package:flutter/material.dart';
import 'package:price_book/pages/admin_page.dart';
import 'package:price_book/pages/login_screen.dart';
import 'package:price_book/pages/worker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String? roleFromLogin;
  const HomePage({super.key, this.roleFromLogin});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    role = widget.roleFromLogin?.trim() ?? prefs.getString("role")?.trim();

    if (role != null) await prefs.setString("role", role!);

    print("Loaded role: $role");

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (role == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    if (role!.toLowerCase() == "admin") return const AdminPage();
    return const WorkerPage();
  }
}

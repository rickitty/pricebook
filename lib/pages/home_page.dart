import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_page.dart';
import 'admin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString("role");

    if (cachedRole != null) {
      setState(() {
        role = cachedRole;
        isLoading = false;
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    String roleFromDb = "worker";
    if (snap.exists &&
        snap.data() != null &&
        snap.data()!.containsKey("role")) {
      roleFromDb = snap["role"];
    }

    await prefs.setString("role", roleFromDb);

    setState(() {
      role = roleFromDb;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (role == "admin") return AdminPage();
    return WorkerPage();
  }
}

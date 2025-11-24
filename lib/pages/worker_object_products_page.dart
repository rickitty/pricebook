import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'worker_product_task_page.dart';

class WorkerObjectProductsPage extends StatefulWidget {
  final String taskId;
  final String objectId;
  final String objectName;

  const WorkerObjectProductsPage({
    super.key,
    required this.taskId,
    required this.objectId,
    required this.objectName,
  });

  @override
  State<WorkerObjectProductsPage> createState() =>
      _WorkerObjectProductsPageState();
}

class _WorkerObjectProductsPageState extends State<WorkerObjectProductsPage> {
  bool loading = false;
  List products = [];

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      final pos = await _getPosition();
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(true) ?? "";

      final uri = Uri.parse(
          '$baseUrl/tasks/${widget.taskId}/objects/${widget.objectId}/products?lat=${pos.latitude}&lng=${pos.longitude}');

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          products = (data['products'] ?? []) as List;
          loading = false;
        });
      } else if (res.statusCode == 403) {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Геолокация не совпадает с объектом. distance=${data["distance"]}'),
          ),
        );
        setState(() => loading = false);
      } else {
        debugPrint('loadProducts error: ${res.statusCode} ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки продуктов')),
        );
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('loadProducts exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка геолокации или сети')),
      );
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    String getLocalized(dynamic data) {
      if (data == null || data is! Map) return "";
      return data[locale] ?? data["en"] ?? data.values.first.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.objectName),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index] as Map<String, dynamic>;
                final name = getLocalized(p['name']);
                final status = (p['status'] ?? 'pending') as String;
                final price = p['price'];
                final photoUrl = p['photoUrl'];

                IconData icon;
                Color color;
                if (status == 'added') {
                  icon = Icons.check_circle;
                  color = Colors.green;
                } else {
                  icon = Icons.radio_button_unchecked;
                  color = Colors.grey;
                }

                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                    status == 'added'
                        ? 'Цена: $price'
                        : 'Не заполнено',
                  ),
                  leading: Icon(icon, color: color),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final productId =
                        (p['productId'] ?? p['_id']).toString();

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerProductTaskPage(
                          taskId: widget.taskId,
                          objectId: widget.objectId,
                          productId: productId,
                          productName: name,
                          existingPhotoUrl: photoUrl?.toString(),
                          existingPrice: price?.toString(),
                        ),
                      ),
                    );

                    if (result == true) {
                     
                      _loadProducts();
                    }
                  },
                );
              },
            ),
    );
  }
}

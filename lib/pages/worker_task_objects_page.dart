import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'worker_object_products_page.dart';

class WorkerTaskObjectsPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const WorkerTaskObjectsPage({super.key, required this.task});

  @override
  State<WorkerTaskObjectsPage> createState() => _WorkerTaskObjectsPageState();
}

class _WorkerTaskObjectsPageState extends State<WorkerTaskObjectsPage> {
  late List objects;
  late String taskId;

  String _getLocalized(dynamic data, String locale) {
    if (data == null || data is! Map) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  @override
  void initState() {
    super.initState();
    objects = (widget.task['objects'] ?? []) as List;
    taskId = widget.task['_id']?.toString() ?? '';
  }

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

  Future<void> _showNearestObjectDialog() async {
    try {
      final pos = await _getPosition();
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(true) ?? "";

      final uri = Uri.parse(
        '$baseUrl/tasks/$taskId/nearest-object'
        '?lat=${pos.latitude}&lng=${pos.longitude}',
      );

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final locale = context.locale.languageCode;

        String getLoc(dynamic d) {
          if (d == null || d is! Map) return '';
          return d[locale] ?? d['en'] ?? d.values.first.toString();
        }

        final name = getLoc(data['name']);
        final address = getLoc(data['address']);
        final distance = (data['distance'] as num?)?.toDouble();

        final lines = <String>[];
        if (name.isNotEmpty) lines.add('Название: $name');
        if (address.isNotEmpty) lines.add('Адрес: $address');
        if (distance != null) {
          lines.add('Расстояние: ${distance.toStringAsFixed(0)} м');
        }

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ближайший объект'),
            content: Text(lines.join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        debugPrint(
            'nearest-object error: ${res.statusCode} ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка определения ближайшего объекта'),
          ),
        );
      }
    } catch (e) {
      debugPrint('nearest-object exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка геолокации или сети'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Объекты задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Показать ближайший объект',
            onPressed: _showNearestObjectDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: objects.length,
        itemBuilder: (context, index) {
          final obj = objects[index] as Map<String, dynamic>;
          final name = _getLocalized(obj['name'], locale);
          final address = _getLocalized(obj['address'], locale);

          final objectId = (obj['objectId'] ?? obj['_id']).toString();

          return ListTile(
            title: Text(name),
            subtitle: Text(address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerObjectProductsPage(
                    taskId: taskId,
                    objectId: objectId,
                    objectName: name,
                  ),
                ),
              );

              if (result == true && mounted) {
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}

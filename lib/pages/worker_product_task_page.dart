import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config.dart';

class WorkerProductTaskPage extends StatefulWidget {
  final String taskId;
  final String objectId;
  final String productId;
  final String productName;
  final String? existingPhotoUrl;
  final String? existingPrice;

  const WorkerProductTaskPage({
    super.key,
    required this.taskId,
    required this.objectId,
    required this.productId,
    required this.productName,
    this.existingPhotoUrl,
    this.existingPrice,
  });

  @override
  State<WorkerProductTaskPage> createState() => _WorkerProductTaskPageState();
}

class _WorkerProductTaskPageState extends State<WorkerProductTaskPage> {
  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  XFile? _capturedFile;
  final _priceController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPrice != null) {
      _priceController.text = widget.existingPrice!;
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initCameraFuture = _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('initCamera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _priceController.dispose();
    super.dispose();
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

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Камера ещё не готова')));
      return;
    }

    try {
      await _initCameraFuture;
      final file = await _cameraController!.takePicture();
      setState(() {
        _capturedFile = file;
      });
    } catch (e) {
      debugPrint('takePhoto error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка при съёмке')));
    }
  }

  Future<void> _save() async {
    if (_capturedFile == null && widget.existingPhotoUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сначала сделайте фото')));
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите цену')));
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await _getPosition();
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(true) ?? "";

      final uri = Uri.parse(
        '$baseUrl/tasks/${widget.taskId}/objects/${widget.objectId}/products/${widget.productId}',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['price'] = _priceController.text.trim();
      request.fields['lat'] = pos.latitude.toString();
      request.fields['lng'] = pos.longitude.toString();
      request.fields['debugIgnoreGeo'] = '1';

      if (_capturedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _capturedFile!.path),
        );
      }

      final response = await request.send();

      if (!mounted) return;

      setState(() => _saving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Сохранено')));
        Navigator.pop(context, true);
      } else if (response.statusCode == 403) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Геолокация не совпадает с объектом. distance=${data["distance"]}',
            ),
          ),
        );
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('save product error: ${response.statusCode} $body');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка при сохранении')));
      }
    } catch (e) {
      debugPrint('save product exception: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка геолокации или сети')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cameraArea;
    if (_cameraController == null || _initCameraFuture == null) {
      cameraArea = const Center(child: CircularProgressIndicator());
    } else {
      cameraArea = FutureBuilder<void>(
        future: _initCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    Widget photoPreview;
    if (_capturedFile != null) {
      if (kIsWeb) {
        photoPreview = Image.network(
          _capturedFile!.path,
          height: 120,
          fit: BoxFit.cover,
        );
      } else {
        photoPreview = Image.file(
          File(_capturedFile!.path),
          height: 120,
          fit: BoxFit.cover,
        );
      }
    } else if (widget.existingPhotoUrl != null) {
      const fileBaseUrl = 'http://localhost:3000';
      photoPreview = Image.network(
        '$fileBaseUrl${widget.existingPhotoUrl}',
        height: 120,
        fit: BoxFit.cover,
      );
    } else {
      photoPreview = const Text('Фото ещё нет');
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.productName)),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Center(child: cameraArea),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Сделать фото'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  photoPreview,
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ввести цену',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

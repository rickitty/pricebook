import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:price_book/keys.dart';

import '../config.dart';

class WorkerProductTaskPage extends StatefulWidget {
  final String taskId;
  final String objectId;
  final String productId;
  final String productName;
  final String? productCategory;
  final String? existingPhotoUrl;
  final String? existingPrice;

  const WorkerProductTaskPage({
    super.key,
    required this.taskId,
    required this.objectId,
    required this.productId,
    required this.productName,
    this.productCategory,
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

  bool get _isAlreadyFilled =>
      (widget.existingPhotoUrl != null &&
          widget.existingPhotoUrl!.isNotEmpty) &&
      (widget.existingPrice != null && widget.existingPrice!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.existingPrice != null) {
      _priceController.text = widget.existingPrice!;
    }
    _requestPermissions();
    _initCamera();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.storage.request();
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
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 10),
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cameraIsNotReadyYet.tr())));
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
      ).showSnackBar(SnackBar(content: Text(errorWhileFilming.tr())));
    }
  }

  Future<void> _save() async {
    if (_capturedFile == null && widget.existingPhotoUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(takeAPictureFirst.tr())));
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(enterPrice.tr())));
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await _getPosition();
      final uri = Uri.parse(
        '$baseUrl/tasks/${widget.taskId}/objects/${widget.objectId}/products/${widget.productId}',
      );

      final request = http.MultipartRequest('POST', uri);

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
        ).showSnackBar(SnackBar(content: Text(saved.tr())));
        Navigator.pop(context, true);
      } else if (response.statusCode == 403) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);

        final distance = (data['distance'] as num?)?.toDouble();

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(geolocationIsNotMatching.tr()),
              content: Text(
                distance != null
                    ? '${youAreTooFarFromTheObject.tr()}.\n'
                          '${currentDistance.tr()}: ${distance.toStringAsFixed(0)} м.'
                    : '${youAreTooFarFromTheObject.tr()}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(confirm.tr()),
                ),
              ],
            );
          },
        );
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('save product error: ${response.statusCode} $body');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorWhileSavingTheProduct.tr())),
        );
      }
    } catch (e) {
      debugPrint('save product exception: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // КАМЕРА
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

    // ПРЕВЬЮ ФОТО
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
    } else if (widget.existingPhotoUrl != null &&
        widget.existingPhotoUrl!.isNotEmpty) {
      const fileBaseUrl = 'http://10.199.117.155:3000';
      photoPreview = Image.network(
        '$fileBaseUrl${widget.existingPhotoUrl}',
        height: 120,
        fit: BoxFit.cover,
      );
    } else {
      photoPreview = Text(noPhotoYet.tr());
    }

    // КАРТОЧКА ТОВАРА (НАЗВАНИЕ + КАТЕГОРИЯ + СТАТУС)
    Widget productHeader = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName.isEmpty ? noName.tr() : widget.productName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (widget.productCategory != null &&
              widget.productCategory!.isNotEmpty)
            Text(
              widget.productCategory!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isAlreadyFilled
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAlreadyFilled
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: _isAlreadyFilled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAlreadyFilled ? filled.tr() : notFilled.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _isAlreadyFilled ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.existingPrice != null &&
                  widget.existingPrice!.isNotEmpty)
                Text(
                  '${currentPrice.tr()}: ${widget.existingPrice}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productName.isEmpty ? productK.tr() : widget.productName,
        ),
      ),
      body: Column(
        children: [
          productHeader,
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
                          label: Text(takeAPicture.tr()),
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
                    decoration: InputDecoration(
                      labelText: enterPrice.tr(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(confirm.tr()),
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

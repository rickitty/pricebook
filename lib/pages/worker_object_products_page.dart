import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/keys.dart';
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
  double? lastDistance;
  String? selectedCategory;

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

  Color _categoryColor(String localizedCategory) {
    final lower = localizedCategory.toLowerCase();

    if (lower.contains('dairy') ||
        lower.contains('молоч') ||
        lower.contains('сүт'))
      return Colors.blue;
    if (lower.contains('vegetables') ||
        lower.contains('овощ') ||
        lower.contains('көкөніс'))
      return Colors.green;
    if (lower.contains('fruit') ||
        lower.contains('фрукт') ||
        lower.contains('жеміс'))
      return Colors.red;
    if (lower.contains('drink') ||
        lower.contains('напит') ||
        lower.contains('сусын'))
      return Colors.purple;
    if (lower.contains('bake') ||
        lower.contains('хлеб') ||
        lower.contains('нан'))
      return Colors.brown;
    if (lower.contains('cereal') ||
        lower.contains('круп') ||
        lower.contains('дән'))
      return Colors.orange;
    if (lower.contains('animal') ||
        lower.contains('животно') ||
        lower.contains('ауылшаруашылық'))
      return const Color.fromARGB(255, 201, 75, 117);

    return Colors.grey;
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      final pos = await _getPosition();

      final uri = Uri.parse(
        '$baseUrl/tasks/${widget.taskId}/objects/${widget.objectId}/products'
        '?lat=${pos.latitude}&lng=${pos.longitude}',
      );

      final res = await http.get(
        uri,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawProducts = (data['products'] ?? []) as List;

        rawProducts.sort((a, b) {
          final aDone = (a['status'] ?? 'pending') == 'added';
          final bDone = (b['status'] ?? 'pending') == 'added';
          if (aDone == bDone) return 0;
          return aDone ? 1 : -1;
        });

        final distance = (data['distance'] as num?)?.toDouble();

        setState(() {
          products = rawProducts;
          lastDistance = distance;
          loading = false;
        });

        if (distance != null) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(distanceToObject.tr()),
                content: Text(
                  yourDistanceFromObjectIs.tr() +
                      ': ' +
                      distance.toStringAsFixed(0) +
                      m.tr(),
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
        }
      } else if (res.statusCode == 403) {
        final data = jsonDecode(res.body);
        final distance = (data['distance'] as num?)?.toDouble();

        setState(() => loading = false);

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(geolocationIsNotMatching.tr()),
              content: Text(
                distance != null
                    ? '${youAreTooFarFromTheObject.tr()}\n'
                          '${currentDistance.tr()}: ${distance.toStringAsFixed(0)} м.'
                    : youAreTooFarFromTheObject.tr(),
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
        debugPrint('loadProducts error: ${res.statusCode} ${res.body}');
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loadProductsError.tr())));
      }
    } catch (e) {
      debugPrint('loadProducts exception: $e');
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
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

    final categorySet = <String>{};
    for (final p in products) {
      final cat = getLocalized((p as Map<String, dynamic>)['category']);
      if (cat.isNotEmpty) {
        categorySet.add(cat);
      }
    }
    final categories = categorySet.toList()..sort();

    final visibleProducts = selectedCategory == null
        ? products
        : products.where((raw) {
            final p = raw as Map<String, dynamic>;
            final cat = getLocalized(p['category']);
            return cat == selectedCategory;
          }).toList();

    Widget buildCategoryFilter() {
      if (categories.isEmpty || products.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: [
            const SizedBox(width: 4),
            ChoiceChip(
              label: Text(all.tr()),
              selected: selectedCategory == null,
              onSelected: (_) {
                setState(() {
                  selectedCategory = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ...categories.map((cat) {
              final color = _categoryColor(cat);
              final selected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : color,
                      fontSize: 12,
                    ),
                  ),
                  selected: selected,
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.12),
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      );
    }

    Widget buildBody() {
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (visibleProducts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${theProductsHaveNotLoadedYet.tr()}.\n'
              '${checkYourGeo.tr()}.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: visibleProducts.length,
        itemBuilder: (context, index) {
          final p = visibleProducts[index] as Map<String, dynamic>;
          final name = getLocalized(p['name']);
          final category = getLocalized(p['category']);
          final status = (p['status'] ?? 'pending') as String;
          final price = p['price'];
          final photoUrl = p['photoUrl'];
          final imageUrl = p['imageUrl'];

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
            leading: imageUrl != null
                ? SizedBox(
                    height: 50,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : Icon(icon, color: color),
            title: Text(
              name.isEmpty ? noName.tr() : name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(category).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _categoryColor(category),
                        ),
                      ),
                    ),
                  ),
                Text(
                  status == 'added' ? '${price.tr()}: $price' : notFilled.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final productId = (p['productId'] ?? p['_id']).toString();

              final name = getLocalized(p['name']);
              final category = getLocalized(p['category']);

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProductTaskPage(
                    taskId: widget.taskId,
                    objectId: widget.objectId,
                    productId: productId,
                    productName: name.isEmpty ? productK.tr() : name,
                    productCategory: category,
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.objectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: showDistanceToObject.tr(),
            onPressed: loading ? null : _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          buildCategoryFilter(),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:price_book/keys.dart';
import '../config.dart';

class TaskCreatePage extends StatefulWidget {
  const TaskCreatePage({super.key});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  List workers = [];
  List objects = [];
  List products = [];

  String? selectedWorker;
  List selectedObjects = [];
  List selectedProducts = [];
  DateTime? selectedDate;
  String searchObjects = "";
  String searchProducts = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadWorkers();
      loadProducts();
    });
  }

  Future<void> loadWorkers() async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.get(
      Uri.parse(workersUrl),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      setState(() => workers = jsonDecode(res.body));
    }
  }

  Future<void> loadObjectsForWorker(String workerId) async {
    final locale = context.locale.languageCode;
    print("Loading objects for workerId=$workerId on language $locale");

    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.get(
      Uri.parse("$baseUrl/object/objects-of/$workerId?lang=$locale"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        objects = jsonDecode(res.body);
        selectedObjects = [];
      });
    }
  }

  Future<void> loadProducts() async {
    final locale = context.locale.languageCode;
    print("Loading products on language: $locale");

    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.get(
      Uri.parse("$baseUrl/products?lang=$locale"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() => products = jsonDecode(res.body));
    }
  }

  Future<void> createTask() async {
    if (selectedWorker == null ||
        selectedObjects.isEmpty ||
        selectedProducts.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fillAllTheFields.tr())));
      return;
    }

    final List<Map<String, dynamic>> formattedObjects = selectedObjects.map((
      objectId,
    ) {
      return {
        "objectId": objectId,
        "products": selectedProducts
            .map((prodId) => {"productId": prodId})
            .toList(),
      };
    }).toList();

    final token = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.post(
      Uri.parse("$baseUrl/tasks/create-task"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "workerId": selectedWorker,
        "date":
            "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
        "objects": formattedObjects,
      }),
    );

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(taskIsMade.tr())));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredObjects = objects.where((o) {
      final name = (o["name"] ?? "").toString().toLowerCase();
      final category = (o["type"] ?? "").toString().toLowerCase();
      final query = searchObjects.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    final filteredProducts = products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      final category = (p["category"] ?? "").toString().toLowerCase();
      final query = searchProducts.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(worker.tr()),
          DropdownSearch<Map<String, dynamic>>(
            items: (String filter, LoadProps? lp) async {
              final filtered = workers
                  .where((w) => (w["phone"] ?? "").contains(filter))
                  .map((e) => e as Map<String, dynamic>)
                  .toList();
              return filtered;
            },
            selectedItem: selectedWorker != null
                ? workers.firstWhere(
                    (w) => w["_id"] == selectedWorker,
                    orElse: () => null,
                  )
                : null,
            compareFn: (item, selected) => item["_id"] == selected["_id"],
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(labelText: workerSearch.tr()),
              ),
              itemBuilder: (context, item, isSelected, searchText) {
                final name = (item["name"] ?? "Name").toString();
                final phone = (item["phone"] ?? "???").toString();
                return ListTile(title: Text("$phone — $name"));
              },
            ),
            onChanged: (v) {
              setState(() {
                selectedWorker = v?["_id"];
                if (v != null) loadObjectsForWorker(v["_id"]);
              });
            },
            dropdownBuilder: (context, selectedItem) {
              if (selectedItem == null) return Text(selectAWorker.tr());
              final name = (selectedItem["name"] ?? "Имя").toString();
              final phone = (selectedItem["phone"] ?? "???").toString();
              return Text("$phone — $name");
            },
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 20),
          Text(objectsK.tr()),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: searchObjectsBy.tr(),
            ),
            onChanged: (v) => setState(() => searchObjects = v),
          ),
          const SizedBox(height: 8),
          Container(
            height: filteredObjects.length > 5 ? 250 : null,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: filteredObjects.map((o) {
                  return CheckboxListTile(
                    value: selectedObjects.contains(o["_id"]),
                    title: Text(o["name"] ?? "Без имени"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o["address"] ?? ""),
                        Text(o["type"] ?? ""),
                      ],
                    ),
                    onChanged: (v) {
                      setState(() {
                        if (v == true)
                          selectedObjects.add(o["_id"]);
                        else
                          selectedObjects.remove(o["_id"]);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(productsK.tr()),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: productsSearch.tr(),
            ),
            onChanged: (v) => setState(() => searchProducts = v),
          ),
          const SizedBox(height: 8),
          Container(
            height: filteredProducts.length > 5 ? 250 : null,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: filteredProducts.map((p) {
                  final imageUrl = p["imageUrl"]?.toString();
                  final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade200,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.inventory_2_outlined, size: 28),
                      ),

                      title: Text(
                        p["name"] ?? "No name",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text(
                        p["category"] ?? "",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      trailing: Checkbox(
                        value: selectedProducts.contains(p["_id"]),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedProducts.add(p["_id"]);
                            } else {
                              selectedProducts.remove(p["_id"]);
                            }
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final today = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(today.year, today.month, today.day),
                lastDate: DateTime(2030),
                initialDate: DateTime.now(),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            child: Text(
              selectedDate == null
                  ? chooseDate.tr()
                  : selectedDate!.toString().split(" ").first,
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(onPressed: createTask, child: Text(createATask.tr())),
        ],
      ),
    );
  }
}

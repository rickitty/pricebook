import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
    print("Загружаем объекты для workerId=$workerId на языке $locale");

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
    print("Загружаем продукты на языке $locale");

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
      ).showSnackBar(const SnackBar(content: Text("Заполните все поля")));
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
        "date": selectedDate!.toIso8601String(),
        "objects": formattedObjects,
      }),
    );

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Задача создана")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: ${res.body}")));
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
          const Text("Работник"),
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
                decoration: InputDecoration(labelText: "Поиск работника"),
              ),
              itemBuilder: (context, item, isSelected, searchText) {
                final name = (item["name"] ?? "Имя").toString();
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
              if (selectedItem == null) return const Text("Выбор работника");
              final name = (selectedItem["name"] ?? "Имя").toString();
              final phone = (selectedItem["phone"] ?? "???").toString();
              return Text("$phone — $name");
            },
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Объекты"),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Поиск объектов (по имени и категории)",
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
          const Text("Продукты"),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Поиск продуктов (по имени и категории)",
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
                  return CheckboxListTile(
                    value: selectedProducts.contains(p["_id"]),
                    title: Text(p["name"] ?? "Без имени"),
                    subtitle: Text(p["category"] ?? ""),
                    onChanged: (v) {
                      setState(() {
                        if (v == true)
                          selectedProducts.add(p["_id"]);
                        else
                          selectedProducts.remove(p["_id"]);
                      });
                    },
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
                  ? "Выбрать дату"
                  : selectedDate!.toString().split(" ").first,
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: createTask,
            child: const Text("Создать задачу"),
          ),
        ],
      ),
    );
  }
}

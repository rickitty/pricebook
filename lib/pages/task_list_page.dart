import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List tasks = [];
  bool loading = false;
  String phone = "";

  // ---- Функция для выбора нужного языка ----
  String getLocalized(dynamic data, String locale) {
    if (data == null || data is! Map) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  // ---- Загрузка всех задач ----
  Future<void> loadAllTasks() async {
    setState(() => loading = true);

    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.get(
      Uri.parse("$baseUrl/tasks/all"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // ---- Загрузка задач по телефону ----
  Future<void> loadByPhone() async {
    if (phone.isEmpty) return;

    setState(() => loading = true);

    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final res = await http.get(
      Uri.parse("$baseUrl/tasks/by-phone/$phone"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        tasks = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Поле поиска по телефону
          TextField(
            decoration: const InputDecoration(
              labelText: "Поиск по номеру",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => phone = v,
          ),
          const SizedBox(height: 10),

          // Кнопки фильтрации
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: loadByPhone,
                  child: const Text("Фильтр по телефону"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: loadAllTasks,
                  child: const Text("Все задачи"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Индикатор загрузки
          if (loading) const CircularProgressIndicator(),

          // ---- Список задач ----
          Expanded(
            child: ListView(
              children: tasks.map((t) {
                // Сначала собираем уникальные продукты для текущей задачи
                final allProducts = <String>{};
                for (var obj in (t["objects"] ?? [])) {
                  for (var p in (obj["products"] ?? [])) {
                    allProducts.add(getLocalized(p["name"], locale));
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Работник: ${t["worker"]?["name"]?[locale] ?? t["worker"]?["name"]?["en"] ?? "Без имени"} (${t["worker"]?["phone"] ?? "??"})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Дата: ${t["date"].toString().split("T").first}"),
                        const SizedBox(height: 12),
                        const Text(
                          "Объекты:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...((t["objects"] ?? []) as List).map<Widget>((obj) {
                          final name = getLocalized(obj["name"], locale);
                          final address = getLocalized(obj["address"], locale);
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text("- $name, $address"),
                          );
                        }),
                        const SizedBox(height: 12),
                        const Text(
                          "Продукты:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Рендерим уникальные продукты
                        ...allProducts.map(
                          (productName) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text("- $productName"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

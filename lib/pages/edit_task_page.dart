
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'package:price_book/keys.dart';

class EditTaskPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  bool saving = false;
  bool loading = false;

  DateTime? selectedDate;
  String? selectedWorkerId;
  List workers = [];
  List objects = [];
  Set<String> selectedObjectIds = {};

  final Map<String, dynamic> existingObjectsById = {};

  @override
  void initState() {
    super.initState();

    try {
      final dateStr = widget.task["date"]?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        selectedDate = DateTime.parse(dateStr);
      }
    } catch (_) {
      selectedDate = DateTime.now();
    }

    final task = widget.task;

    selectedWorkerId =
        (task["workerId"]?.toString()) ?? (task["worker"]?["_id"]?.toString());

    for (var o in (task["objects"] ?? [])) {
      final objId = o["objectId"]?.toString();
      if (objId != null) {
        selectedObjectIds.add(objId);
        existingObjectsById[objId] = o;
      }
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final resWorkers = await http.get(Uri.parse("$baseUrl/users/workers"));
      final resObjects = await http.get(Uri.parse("$baseUrl/object/objects"));

      if (resWorkers.statusCode == 200) {
        workers = jsonDecode(resWorkers.body);
      }
      if (resObjects.statusCode == 200) {
        objects = jsonDecode(resObjects.body);
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickDate() async {
    final initial = selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату')));
      return;
    }
    if (selectedWorkerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите работника')));
      return;
    }
    if (selectedObjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один объект')),
      );
      return;
    }

    final taskId =
        widget.task["_id"]?.toString() ?? widget.task["id"]?.toString();

    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден ID задачи')),
      );
      return;
    }

    final List<Map<String, dynamic>> objectsPayload = [];

    for (var obj in objects) {
      final objId = obj["_id"]?.toString();
      if (objId == null) continue;

      if (selectedObjectIds.contains(objId)) {
        final existing = existingObjectsById[objId];
        final products = existing?["products"] ?? [];

        objectsPayload.add({"objectId": objId, "products": products});
      }
    }

    setState(() => saving = true);

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/tasks/update-task/$taskId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "date": selectedDate!.toIso8601String(),
          "workerId": selectedWorkerId,
          "objects": objectsPayload,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача обновлена')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('Редактирование задачи')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Дата не выбрана'
                              : 'Дата: ${selectedDate!.toLocal().toString().split(" ").first}',
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: Text(chooseDate.tr()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedWorkerId,
                    decoration: InputDecoration(
                      labelText: worker.tr(),
                      border: OutlineInputBorder(),
                    ),
                    items: workers.map<DropdownMenuItem<String>>((w) {
                      final id = w["_id"]?.toString();
                      final nameMap = w["name"];
                      String name = '';
                      if (nameMap is Map) {
                        name =
                            nameMap[locale] ??
                            nameMap["en"] ??
                            nameMap.values.first.toString();
                      } else {
                        name = nameMap?.toString() ?? 'Без имени';
                      }

                      return DropdownMenuItem(value: id, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedWorkerId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          objectsK.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...objects.map((obj) {
                          final objId = obj["_id"]?.toString();
                          if (objId == null) return const SizedBox.shrink();

                          String name = '';
                          String address = '';

                          if (obj["name"] is Map) {
                            name =
                                obj["name"][locale] ??
                                obj["name"]["en"] ??
                                obj["name"].values.first.toString();
                          } else {
                            name = obj["name"]?.toString() ?? '';
                          }

                          if (obj["address"] is Map) {
                            address =
                                obj["address"][locale] ??
                                obj["address"]["en"] ??
                                obj["address"].values.first.toString();
                          } else {
                            address = obj["address"]?.toString() ?? '';
                          }

                          final selected = selectedObjectIds.contains(objId);

                          return CheckboxListTile(
                            value: selected,
                            title: Text(name),
                            subtitle: address.isNotEmpty ? Text(address) : null,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedObjectIds.add(objId);
                                } else {
                                  selectedObjectIds.remove(objId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(save.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

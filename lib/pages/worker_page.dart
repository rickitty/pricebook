import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:price_book/keys.dart';
import '../config.dart';
import 'worker_task_objects_page.dart';
import 'package:price_book/drawer.dart';
import 'package:http/http.dart' as http;

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});

  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List tasks = [];
  bool loading = false;
  String phone = "";

  DateTime selectedDate = DateTime.now();
  bool filterActive = false;

  String getLocalized(dynamic data, String locale) {
    if (data == null || data is! Map) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _startOfWeek(DateTime d) {
    final weekday = d.weekday;
    return d.subtract(Duration(days: weekday - 1));
  }

  Future<void> loadByPhone(String phone) async {
    if (phone.isEmpty) return;

    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/tasks/by-phone/$phone"));
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          tasks = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tasksLoadingError.tr())));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tasksLoadingError.tr())));
    }
  }

  Future<void> _initPhoneAndLoadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPhone = prefs.getString("phone") ?? "";
    setState(() => phone = cachedPhone);

    await loadByPhone(cachedPhone);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPhoneAndLoadTasks();
    });
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Location denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _startTask(String taskId) async {
    try {
      final pos = await _getPosition();

      final res = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
      );

      if (res.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(couldNotStartTheTask.tr())));
      } else {
        await loadByPhone(phone);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final pos = await _getPosition();

      final res = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(taskComplete.tr())));
        await loadByPhone(phone);
      } else if (res.statusCode == 400) {
        final data = jsonDecode(res.body);
        final missing = (data['missing'] ?? []) as List<dynamic>;
        final locale = context.locale.languageCode;

        final names = missing
            .map((m) {
              final n = m['name'];
              if (n is Map)
                return n[locale] ?? n['ru'] ?? n['en'] ?? n.values.first;
              return n?.toString() ?? '???';
            })
            .join(', ');

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(notAllProductsAreFilled.tr()),
            content: Text('${youForgot.tr()}: $names'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(taskCompleteError.tr())));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
    }
  }

  void _openTask(Map<String, dynamic> task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerTaskObjectsPage(task: task)),
    );

    if (result == true) await loadByPhone(phone);
  }

  Widget _buildDateFilter() {
    final weekStart = _startOfWeek(selectedDate);
    const weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now();
    final todayStr = DateFormat('dd.MM.yyyy').format(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${todayK.tr()}: $todayStr',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = weekStart.add(Duration(days: index));
              final isSelected = _isSameDate(day, selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (filterActive && isSelected) {
                      filterActive = false;
                    } else {
                      selectedDate = day;
                      filterActive = true;
                    }
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdaysShort[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final filteredTasks = filterActive
        ? tasks.where((t) {
            final raw = t['date'];
            if (raw == null) return false;
            try {
              final dt = DateTime.parse(raw.toString()).toLocal();
              return _isSameDate(dt, selectedDate);
            } catch (_) {
              return false;
            }
          }).toList()
        : tasks;

    return Scaffold(
      appBar: AppBar(title: Text(tasksK.tr())),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildDateFilter(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Text(
                              tasksNotFound.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView(
                            children: filteredTasks.map((t) {
                              final allProducts = <String>{};
                              for (var obj in (t["objects"] ?? [])) {
                                for (var p in (obj["products"] ?? [])) {
                                  allProducts.add(
                                    getLocalized(p["name"], locale),
                                  );
                                }
                              }

                              final status =
                                  (t['status'] ?? 'pending') as String;
                              String buttonText;
                              Color buttonColor;
                              VoidCallback? onPressed;
                              final taskId = t['_id']?.toString() ?? '';

                              if (status == 'pending') {
                                buttonText = start.tr();
                                buttonColor = Colors.blue;
                                onPressed = () async {
                                  await _startTask(taskId);
                                  _openTask(t);
                                };
                              } else if (status == 'in_progress') {
                                buttonText = continueK.tr();
                                buttonColor = Colors.orange;
                                onPressed = () => _openTask(t);
                              } else {
                                buttonText = complete.tr();
                                buttonColor = Colors.green;
                                onPressed = null;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: InkWell(
                                  onTap: () => _openTask(t),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${worker.tr()}: ${t["worker"]?["name"]?[locale] ?? t["worker"]?["name"]?["en"] ?? "Без имени"} (${t["worker"]?["phone"] ?? "??"})",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${date.tr()}: ${t["date"].toString().split("T").first}",
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          objectsK.tr(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...((t["objects"] ?? []) as List)
                                            .map<Widget>((obj) {
                                              final name = getLocalized(
                                                obj["name"],
                                                locale,
                                              );
                                              final address = getLocalized(
                                                obj["address"],
                                                locale,
                                              );
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8,
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  "- $name, $address",
                                                ),
                                              );
                                            }),
                                        const SizedBox(height: 12),
                                        Text(
                                          "${productsK.tr()}:",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...allProducts.map(
                                          (productName) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              top: 2,
                                            ),
                                            child: Text("- $productName"),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: onPressed,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: buttonColor,
                                            ),
                                            child: Text(buttonText),
                                          ),
                                        ),
                                        if (status == 'in_progress') ...[
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _completeTask(taskId),
                                              child: Text(completeTheTask.tr()),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

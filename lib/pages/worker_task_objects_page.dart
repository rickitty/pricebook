import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'worker_object_products_page.dart';

class WorkerTaskObjectsPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const WorkerTaskObjectsPage({super.key, required this.task});

  @override
  State<WorkerTaskObjectsPage> createState() => _WorkerTaskObjectsPageState();
}

class _WorkerTaskObjectsPageState extends State<WorkerTaskObjectsPage> {
  late List objects;

  String _getLocalized(dynamic data, String locale) {
    if (data == null || data is! Map) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  @override
  void initState() {
    super.initState();
    objects = (widget.task['objects'] ?? []) as List;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final taskId = widget.task['_id']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Объекты задачи'),
      ),
      body: ListView.builder(
        itemCount: objects.length,
        itemBuilder: (context, index) {
          final obj = objects[index] as Map<String, dynamic>;
          final name = _getLocalized(obj['name'], locale);
          final address = _getLocalized(obj['address'], locale);

          return ListTile(
            title: Text(name),
            subtitle: Text(address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final objectId =
                  (obj['objectId'] ?? obj['_id']).toString(); // на всякий случай

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
                // можно придумать перезагрузку задач/объектов, если нужно
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }
}

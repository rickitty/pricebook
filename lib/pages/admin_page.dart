import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/drawer.dart';
import 'task_create_page.dart';
import 'task_list_page.dart';
import '../keys.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text(adminPanel.tr()),
        bottom: TabBar(
          controller: controller,
          tabs: const [
            Tab(text: "Задачи"),
            Tab(text: "Создать задачу"),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: const [
          TaskListPage(),
          TaskCreatePage(),
        ],
      ),
    );
  }
}

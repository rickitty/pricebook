import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/keys.dart';
import 'dart:convert';
import '../config.dart';

class AdminAssignPage extends StatefulWidget {
  const AdminAssignPage({super.key});

  @override
  State<AdminAssignPage> createState() => _AdminAssignPageState();
}

class _AdminAssignPageState extends State<AdminAssignPage> {
  List workers = [];
  List objects = [];
  List selected = [];

  String? selectedWorker;
  String search = "";

  @override
  void initState() {
    super.initState();
    loadWorkers();
    loadObjects();
  }

  Future<void> loadWorkers() async {
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.get(
      Uri.parse(workersUrl),
      headers: {"Authorization": "Bearer $idToken"},
    );

    if (res.statusCode == 200) {
      setState(() {
        workers = jsonDecode(res.body);
      });
    }
  }

  Future<void> loadObjects() async {
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.get(
      Uri.parse(objectsUrl),
      headers: {"Authorization": "Bearer $idToken"},
    );

    if (res.statusCode == 200) {
      setState(() {
        objects = jsonDecode(res.body);
      });
    }
  }

  Future<void> save() async {
    if (selectedWorker == null) return;

    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.post(
      Uri.parse(assignObjectsUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({"userId": selectedWorker, "objectIds": selected}),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredObjects = objects
        .where(
          (o) =>
              o["name"].toString().toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(assigningObjects.tr())),
      body: Column(
        children: [
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
                final name = (item["name"] ?? "Имя").toString();
                final phone = (item["phone"] ?? "???").toString();
                return ListTile(title: Text("$phone — $name"));
              },
            ),
            dropdownBuilder: (context, selectedItem) {
              if (selectedItem == null) return Text(selectAWorker.tr());
              final name = (selectedItem["name"] ?? "Имя").toString();
              final phone = (selectedItem["phone"] ?? "???").toString();
              return Text("$phone — $name");
            },
            onChanged: (v) {
              setState(() {
                selectedWorker = v?["_id"];
                if (v != null) {
                  selected =
                      (v["objects"] as List?)
                          ?.map<String>((o) => o["_id"])
                          .toList() ??
                      [];
                } else {
                  selected = [];
                }
              });
            },
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: objectsSearch.tr(),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

          Expanded(
            child: ListView(
              children: filteredObjects.map((obj) {
                final id = obj["_id"];
                final checked = selected.contains(id);

                final lang = context.locale.languageCode;

                final name = obj["name"]?[lang] ?? noName.tr();
                final address = obj["address"]?[lang] ?? noAddress.tr();
                final category = obj["type"]?[lang] ?? "";

                return CheckboxListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(address), Text(category)],
                  ),
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selected.add(id);
                      } else {
                        selected.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          ElevatedButton(onPressed: save, child: Text(confirm.tr())),
        ],
      ),
    );
  }
}

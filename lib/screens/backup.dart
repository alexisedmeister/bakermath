import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

// ✅ Importa 'dart:html' solo en Web
import 'dart:html' as html if (dart.library.io) 'dart:io';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  BackupScreenState createState() => BackupScreenState();
}

class BackupScreenState extends State<BackupScreen> {
  late Box ingredientsBox;
  late Box recipesBox;

  @override
  void initState() {
    super.initState();
    _openHiveBoxes();
  }

  Future<void> _openHiveBoxes() async {
    ingredientsBox = await Hive.openBox('ingredients');
    recipesBox = await Hive.openBox('recipes');
  }

  // ✅ Exportar datos a JSON
  Future<void> _exportData() async {
    final Map<String, dynamic> data = {
      'ingredients': ingredientsBox.values.toList(),
      'recipes': recipesBox.values.toList(),
    };

    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      _exportWeb(jsonString);
    } else {
      await _exportMobile(jsonString);
    }
  }

  // ✅ Exportar en Web usando `dart:html`
  void _exportWeb(String jsonString) {
    final blob = html.Blob([utf8.encode(jsonString)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "bakermath_backup.json")
      ..click();

    // ✅ Liberar URL después de 1s
    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  // ✅ Exportar en Android/iOS/Desktop
  Future<void> _exportMobile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bakermath_backup.json');
    await file.writeAsString(jsonString);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved: ${file.path}')),
    );
  }

  // ✅ Importar datos desde JSON
  Future<void> _importData() async {
    if (kIsWeb) {
      _importWeb();
    } else {
      await _importMobile();
    }
  }

  // ✅ Importar en Web usando `dart:html`
  void _importWeb() {
    final uploadInput = html.FileUploadInputElement()..accept = ".json";
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoadEnd.listen((event) async {
        if (!mounted) return;

        final jsonData = jsonDecode(reader.result as String);
        await _restoreData(jsonData);
      });
    });
  }

  // ✅ Importar en Android/iOS/Desktop
  Future<void> _importMobile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty || result.files.single.path == null) return;

    File file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString);

    await _restoreData(jsonData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import successful!')),
    );
  }

  // ✅ Restaurar datos en Hive
  Future<void> _restoreData(Map<String, dynamic> jsonData) async {
    await ingredientsBox.clear();
    await recipesBox.clear();

    for (var ingredient in jsonData['ingredients']) {
      await ingredientsBox.add(ingredient);
    }
    for (var recipe in jsonData['recipes']) {
      await recipesBox.add(recipe);
    }

    setState(() {}); // Refrescar UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data restored successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _exportData,
              child: const Text('Export Data to JSON'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _importData,
              child: const Text('Import Data from JSON'),
            ),
          ],
        ),
      ),
    );
  }
}
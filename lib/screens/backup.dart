import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:html' as html;

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  BackupScreenState createState() => BackupScreenState();
}

class BackupScreenState extends State<BackupScreen> {
  final Box ingredientsBox = Hive.box('ingredients');
  final Box recipesBox = Hive.box('recipes');

  String currentAppVersion = '';
  final String minSupportedImportVersion = '2.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      currentAppVersion = info.version;
    });
  }

  Future<void> _exportData() async {
    if (currentAppVersion.isEmpty) return;

    final Map<String, dynamic> data = {
      'appVersion': currentAppVersion,
      'ingredients': ingredientsBox.toMap(),
      'recipes': recipesBox.toMap(),
    };
    final jsonString = jsonEncode(data);

    if (kIsWeb) {
      _exportWeb(jsonString);
    } else {
      await _exportMobile(jsonString);
    }
  }

  void _exportWeb(String jsonString) {
    final blob = html.Blob([utf8.encode(jsonString)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "bakermath_backup.json")
      ..style.display = "none";

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  Future<void> _exportMobile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bakermath_backup.json');
    await file.writeAsString(jsonString);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved: ${file.path}')),
    );
  }

  Future<void> _importData() async {
    if (kIsWeb) {
      _importWeb();
    } else {
      await _importMobile();
    }
  }

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
        final confirmed = await _confirmRestore();
        if (confirmed) await _restoreData(jsonData);
      });
    });
  }

  Future<void> _importMobile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty || result.files.single.path == null) return;

    File file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString);

    final confirmed = await _confirmRestore();
    if (confirmed) {
      await _restoreData(jsonData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import successful!')),
      );
    }
  }

  Future<bool> _confirmRestore() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Import"),
            content: const Text(
              "All current data will be deleted and replaced with the imported backup. Do you want to continue?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Continue"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _restoreData(Map<String, dynamic> jsonData) async {
    final backupVersion = jsonData['appVersion'];
    if (backupVersion == null || !_isCompatibleVersion(backupVersion)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incompatible backup version.")),
        );
      }
      return;
    }

    await ingredientsBox.clear();
    await recipesBox.clear();

    if (jsonData['ingredients'] is Map) {
      final ingredientsMap = Map<String, dynamic>.from(jsonData['ingredients']);
      for (var entry in ingredientsMap.entries) {
        await ingredientsBox.put(entry.key, entry.value);
      }
    }

    if (jsonData['recipes'] is Map) {
      for (var key in jsonData['recipes'].keys) {
        final recipe = jsonData['recipes'][key];
        if (recipe is Map<String, dynamic>) {
          await recipesBox.put(key, recipe);
        } else {
          await recipesBox.put(key, Map<String, dynamic>.from(recipe));
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data restored successfully!")),
      );
    }
  }

  bool _isCompatibleVersion(String version) {
    List<int> toParts(String v) => v.split('.').map(int.parse).toList();
    final current = toParts(version);
    final min = toParts(minSupportedImportVersion);

    for (int i = 0; i < min.length; i++) {
      if (current.length <= i) return false;
      if (current[i] < min[i]) return false;
      if (current[i] > min[i]) return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Center(
        child: currentAppVersion.isEmpty
            ? const CircularProgressIndicator()
            : Column(
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
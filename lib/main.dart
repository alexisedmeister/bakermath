import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screens/ingredients.dart';
import 'screens/recipes.dart';
import 'screens/calculator.dart';
import 'screens/backup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);
  }

  await Hive.openBox('ingredients');
  await Hive.openBox('recipes');

  runApp(const BakermathApp());
}

class BakermathApp extends StatelessWidget {
  const BakermathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bakermath',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Bakermath', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '© alexisedmeister',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'v$_version',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakermath - Home')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ValueListenableBuilder(
            valueListenable: Hive.box('ingredients').listenable(),
            builder: (context, Box box, _) {
              return ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text('Ingredients (${box.length})'),
                subtitle: const Text('Manage your ingredients'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IngredientsScreen()),
                  );
                },
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: Hive.box('recipes').listenable(),
            builder: (context, Box box, _) {
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: Text('Recipes (${box.length})'),
                subtitle: const Text('Manage your recipes'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecipesScreen()),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Calculator'),
            subtitle: const Text('Calculate ingredient proportions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalculatorScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Import or export your data'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version and credits'),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }
}
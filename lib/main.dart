import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/ingredients.dart';
import 'screens/recipes.dart';
import 'screens/calculator.dart';
import 'screens/backup.dart'; // ✅ Importar BackupScreen

void main() async {
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
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int ingredientCount = 0;
  int recipeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final ingredientsBox = Hive.box('ingredients');
    final recipesBox = Hive.box('recipes');
    setState(() {
      ingredientCount = ingredientsBox.length;
      recipeCount = recipesBox.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakermath - Home')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text('Ingredients ($ingredientCount)'),
            subtitle: const Text('Manage your ingredients'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IngredientsScreen()),
              );
              _loadCounts();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: Text('Recipes ($recipeCount)'),
            subtitle: const Text('Manage your recipes'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipesScreen()),
              );
              _loadCounts();
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
          const Divider(), // ✅ Separador visual
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
        ],
      ),
    );
  }
}
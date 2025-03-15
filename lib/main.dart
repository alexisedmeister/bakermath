import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/ingredients.dart';
import 'screens/recipes.dart';
import 'screens/calculator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // ✅ Inicialización para Web
    await Hive.initFlutter();
  } else {
    // ✅ Inicialización para Android/iOS
    final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(directory.path);
  }

  // ✅ Abrir las cajas de Hive correctamente con await
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakermath - Home'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Ingredients'),
            subtitle: const Text('Manage your ingredients'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IngredientsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Recipes'),
            subtitle: const Text('Manage your recipes'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipesScreen()),
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
        ],
      ),
    );
  }
}
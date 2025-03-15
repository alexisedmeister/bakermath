import 'package:flutter/material.dart';
import 'ingredients.dart';
import 'recipes.dart';
import 'calculator.dart';

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
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'recipesadd.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  RecipesScreenState createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  late Box recipesBox;
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    recipesBox = await Hive.openBox('recipes');
    setState(() {
      _recipes = recipesBox.values.map((recipe) {
        return {
          'name': recipe['name']?.toString() ?? '',
          'description': recipe['description']?.toString() ?? '',
          'ingredients': List<Map<String, dynamic>>.from(recipe['ingredients'] ?? []),
        };
      }).toList();
    });
  }

  Future<void> _deleteRecipe(int index) async {
    await recipesBox.deleteAt(index);
    _loadRecipes();
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Recipe'),
          content: const Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteRecipe(index);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
      ),
      body: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return ListTile(
            title: Text(recipe['name']),
            subtitle: Text(recipe['description']),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipesAddScreen(
                    recipe: recipe,
                    recipeIndex: index,
                  ),
                ),
              );
              _loadRecipes(); // Recargar recetas tras editar
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipesAddScreen(),
            ),
          );
          _loadRecipes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

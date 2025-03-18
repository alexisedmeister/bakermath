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
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    recipesBox = await Hive.openBox('recipes');
    _loadRecipes();

    // ✅ Escucha cambios en la base de datos y actualiza automáticamente
    recipesBox.watch().listen((_) => _loadRecipes());
  }

  void _loadRecipes() {
    final recipes = recipesBox.values.cast<Map>().toList();
    setState(() {
      _recipes = recipes
          .map((recipe) => {
                'name': recipe['name']?.toString() ?? '',
                'description': recipe['description']?.toString() ?? '',
                'ingredients': List<Map<String, dynamic>>.from(recipe['ingredients'] ?? []),
              })
          .toList();

      // ✅ Ordena recetas A-Z solo si hay cambios
      _recipes.sort((a, b) => a['name'].toLowerCase().compareTo(b['name'].toLowerCase()));
    });
  }

  Future<void> _deleteRecipe(int index) async {
    await recipesBox.deleteAt(index);
    // 🔹 No es necesario llamar a `_loadRecipes()`, porque `watch()` ya escucha los cambios
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
        title: Text('Recipes (${_recipes.length})'),
      ),
      body: _recipes.isEmpty
          ? const Center(child: Text('No recipes available.'))
          : ListView.builder(
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
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Delete') {
                        _showDeleteConfirmationDialog(index);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'Delete',
                        child: Text('Delete'),
                      ),
                    ],
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
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
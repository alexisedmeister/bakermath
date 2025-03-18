import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  IngredientsScreenState createState() => IngredientsScreenState();
}

class IngredientsScreenState extends State<IngredientsScreen> {
  late Box ingredientsBox;
  late Box recipesBox;
  List<dynamic> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    ingredientsBox = await Hive.openBox('ingredients');
    recipesBox = await Hive.openBox('recipes');
    setState(() {
      _ingredients = ingredientsBox.values.toList();
      _ingredients.sort((a, b) => a.toString().toLowerCase().compareTo(b.toString().toLowerCase()));
    });
  }

  bool _isIngredientUsed(String ingredientName) {
    for (var recipe in recipesBox.values) {
      if (recipe['ingredients'] != null) {
        for (var ingredient in recipe['ingredients']) {
          if (ingredient['ingredient'] == ingredientName) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _addIngredient(String name) async {
    await ingredientsBox.add(name);
    _loadIngredients();
  }

  Future<void> _editIngredient(int index, String newName) async {
    await ingredientsBox.putAt(index, newName);
    _loadIngredients();
  }

  Future<void> _deleteIngredient(int index) async {
    String ingredientName = _ingredients[index];
    if (_isIngredientUsed(ingredientName)) {
      _showCannotDeleteDialog(ingredientName);
    } else {
      await ingredientsBox.deleteAt(index);
      _loadIngredients();
    }
  }

  void _showCannotDeleteDialog(String ingredientName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text('The ingredient "$ingredientName" is being used in a recipe and cannot be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showEditIngredientDialog(int index, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Ingredient'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Ingredient name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _editIngredient(index, controller.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Ingredient'),
          content: const Text('Are you sure you want to delete this ingredient?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteIngredient(index);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddIngredientDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Ingredient'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Ingredient name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _addIngredient(controller.text);
                      controller.clear();
                      setStateDialog(() {});
                    }
                  },
                  child: const Text('Add Another'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingredients (${_ingredients.length})'),
      ),
      body: ListView.builder(
        itemCount: _ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = _ingredients[index];
          return ListTile(
            title: Text(ingredient),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Edit') {
                  _showEditIngredientDialog(index, ingredient);
                } else if (value == 'Delete') {
                  _showDeleteConfirmationDialog(index);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'Edit',
                  child: Text('Edit'),
                ),
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
        onPressed: _showAddIngredientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  IngredientsScreenState createState() => IngredientsScreenState();
}

class IngredientsScreenState extends State<IngredientsScreen> {
  late final Box ingredientsBox = Hive.box('ingredients');
  late final Box recipesBox = Hive.box('recipes');

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  bool _isIngredientUsed(String ingredientKey) {
    for (var recipe in recipesBox.values) {
      if (recipe['ingredients'] != null) {
        for (var ingredient in recipe['ingredients']) {
          if (ingredient['ingredient'] == ingredientKey) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _addIngredient(String name) async {
    final String ingredientKey = Uuid().v4();
    await ingredientsBox.put(ingredientKey, name);
  }

  Future<void> _editIngredient(dynamic key, String newName) async {
    await ingredientsBox.put(key, newName);
  }

  Future<void> _deleteIngredient(dynamic key) async {
    if (_isIngredientUsed(key)) {
      _showCannotDeleteDialog(ingredientsBox.get(key));
    } else {
      await ingredientsBox.delete(key);
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

  void _showEditIngredientDialog(dynamic key, String currentName) {
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
                  _editIngredient(key, controller.text);
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

  void _showDeleteConfirmationDialog(dynamic key) {
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
                _deleteIngredient(key);
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
        title: ValueListenableBuilder(
          valueListenable: Hive.box('ingredients').listenable(),
          builder: (context, Box box, _) {
            return Text('Ingredients (${box.keys.length})');
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search ingredients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('ingredients').listenable(),
              builder: (context, Box box, _) {
                final ingredients = box.toMap();
                final filtered = ingredients.entries.where((entry) {
                  final name = entry.value.toString().toLowerCase();
                  return name.contains(_searchTerm);
                }).toList()
                  ..sort((a, b) => a.value.toString().compareTo(b.value.toString()));

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final key = filtered[index].key;
                    final ingredient = filtered[index].value;
                    return ListTile(
                      title: Text(ingredient),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Edit') {
                            _showEditIngredientDialog(key, ingredient);
                          } else if (value == 'Delete') {
                            _showDeleteConfirmationDialog(key);
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
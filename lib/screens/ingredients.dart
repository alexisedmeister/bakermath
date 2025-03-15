import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  IngredientsScreenState createState() => IngredientsScreenState();
}

class IngredientsScreenState extends State<IngredientsScreen> {
  late Box ingredientsBox;
  List<dynamic> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    ingredientsBox = await Hive.openBox('ingredients');
    setState(() {
      _ingredients = ingredientsBox.values.toList();
    });
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
    await ingredientsBox.deleteAt(index);
    _loadIngredients();
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
                _deleteIngredient(index);
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
      appBar: AppBar(title: const Text('Ingredients')),
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
        onPressed: () => _showAddIngredientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddIngredientDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
}
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class RecipesAddScreen extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  final dynamic recipeKey;

  const RecipesAddScreen({super.key, this.recipe, this.recipeKey});

  @override
  RecipesAddScreenState createState() => RecipesAddScreenState();
}

class RecipesAddScreenState extends State<RecipesAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _selectedIngredients = [];

  late Box ingredientsBox;
  late Box recipesBox;

  @override
  void initState() {
    super.initState();
    ingredientsBox = Hive.box('ingredients');
    recipesBox = Hive.box('recipes');

    if (widget.recipe != null) {
      _nameController.text = widget.recipe!['name'];
      _descriptionController.text = widget.recipe!['description'];
      _selectedIngredients.addAll(List<Map<String, dynamic>>.from(widget.recipe!['ingredients']));
    }
  }

  Future<void> _showAddIngredientDialog({Map<String, dynamic>? existingIngredient}) async {
    String? selectedIngredient = existingIngredient?['ingredient'];
    final TextEditingController quantityController = TextEditingController();

    if (existingIngredient != null) {
      quantityController.text = existingIngredient['quantity'].toStringAsFixed(2);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(existingIngredient != null ? 'Edit Ingredient' : 'Add Ingredient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existingIngredient == null)
                    DropdownButtonFormField<String>(
                      value: selectedIngredient,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedIngredient = value;
                        });
                      },
                      items: ingredientsBox.keys.map<DropdownMenuItem<String>>((key) {
                        final String ingredientName = ingredientsBox.get(key);
                        return DropdownMenuItem<String>(
                          value: key.toString(),
                          child: Text(ingredientName),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if ((selectedIngredient != null || existingIngredient != null) &&
                        quantityController.text.isNotEmpty &&
                        double.tryParse(quantityController.text) != null) {
                      final ingredientKey = selectedIngredient ?? existingIngredient!['ingredient'];
                      final quantity = double.parse(quantityController.text);
                      setState(() {
                        if (existingIngredient != null) {
                          existingIngredient['quantity'] = quantity;
                        } else {
                          _selectedIngredients.add({'ingredient': ingredientKey, 'quantity': quantity});
                        }
                      });

                      // Mantener el cuadro de diálogo abierto limpiando los valores en lugar de cerrarlo
                      setStateDialog(() {
                        selectedIngredient = null;
                        quantityController.clear();
                      });
                    }
                  },
                  child: Text(existingIngredient != null ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteIngredient(Map<String, dynamic> ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
  }

  Future<void> _saveRecipe() async {
    final newRecipe = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'ingredients': _selectedIngredients,
    };

    final String recipeKey = widget.recipeKey ?? const Uuid().v4();
    await recipesBox.put(recipeKey, newRecipe);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddIngredientDialog(),
              child: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _selectedIngredients[index];
                  final ingredientName = ingredientsBox.get(ingredient['ingredient']);
                  final quantity = ingredient['quantity'];
                  return ListTile(
                    title: Text('$ingredientName - ${quantity.toStringAsFixed(2)} kg'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Edit') {
                          _showAddIngredientDialog(existingIngredient: ingredient);
                        } else if (value == 'Delete') {
                          _deleteIngredient(ingredient);
                        }
                      },
                      itemBuilder: (context) => [
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
            ),
            Center(
              child: TextButton(
                onPressed: _saveRecipe,
                child: const Text('Save Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
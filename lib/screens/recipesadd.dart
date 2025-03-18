import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecipesAddScreen extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  final int? recipeIndex;

  const RecipesAddScreen({super.key, this.recipe, this.recipeIndex});

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
      _selectedIngredients.addAll(widget.recipe!['ingredients']);
    }
  }

  Future<void> _showAddIngredientDialog({int? index}) async {
    String? selectedIngredient;
    final TextEditingController quantityController = TextEditingController();

    if (index != null) {
      selectedIngredient = _selectedIngredients[index]['ingredient'];
      quantityController.text = _selectedIngredients[index]['quantity'].toString();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(index != null ? 'Edit Ingredient' : 'Add Ingredient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == null)
                    DropdownButtonFormField<String>(
                      value: selectedIngredient,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedIngredient = value;
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Select Ingredient'),
                        ),
                        ...ingredientsBox.values.map<DropdownMenuItem<String>>((ingredient) {
                          final name = ingredient is Map<String, dynamic> ? ingredient['name'] as String : ingredient.toString();
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }),
                      ],
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
                  onPressed: () => Navigator.of(context).pop(), // Cierra solo con "Cancel"
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if ((selectedIngredient != null || index != null) &&
                        quantityController.text.isNotEmpty &&
                        double.tryParse(quantityController.text) != null) {
                      final ingredientData = {
                        'ingredient': selectedIngredient ?? _selectedIngredients[index!]['ingredient'],
                        'quantity': double.parse(quantityController.text),
                      };
                      setState(() {
                        if (index == null) {
                          _selectedIngredients.add(ingredientData);
                        } else {
                          _selectedIngredients[index] = ingredientData;
                        }
                      });

                      // ✅ Mantener el diálogo abierto y limpiar los campos
                      setStateDialog(() {
                        selectedIngredient = null; // Resetear selección
                        quantityController.clear(); // Limpiar cantidad
                      });
                    }
                  },
                  child: Text(index != null ? 'Update' : 'Add Another'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteIngredient(int index) {
    setState(() {
      _selectedIngredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    final newRecipe = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'ingredients': _selectedIngredients,
    };

    if (widget.recipeIndex != null) {
      await recipesBox.putAt(widget.recipeIndex!, newRecipe);
    } else {
      await recipesBox.add(newRecipe);
    }

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
                  return ListTile(
                    title: Text('${ingredient['ingredient']} - ${ingredient['quantity']} kg'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Edit') {
                          _showAddIngredientDialog(index: index);
                        } else if (value == 'Delete') {
                          _deleteIngredient(index);
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
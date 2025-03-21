import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  CalculatorScreenState createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> {
  late Box recipesBox;
  late Box ingredientsBox;
  String? _selectedRecipe;
  String? _selectedIngredient;
  double _inputWeight = 0.0;
  Map<String, double> _calculatedIngredients = {};

  @override
  void initState() {
    super.initState();
    recipesBox = Hive.box('recipes');
    if (Hive.isBoxOpen('ingredients')) {
      ingredientsBox = Hive.box('ingredients');
    }
  }

  void _calculateProportions(Map<String, Map<String, double>> recipeData) {
    if (_selectedRecipe == null || _selectedIngredient == null || _inputWeight <= 0.0) {
      return;
    }

    final recipe = recipeData[_selectedRecipe!];
    if (recipe == null) return;

    setState(() {
      if (_selectedIngredient == 'Total') {
        final totalWeight = recipe.values.reduce((a, b) => a + b);
        _calculatedIngredients = recipe.map(
          (name, amount) => MapEntry(name, (amount / totalWeight) * _inputWeight),
        );
      } else {
        final baseWeight = recipe[_selectedIngredient!] ?? 1.0;
        _calculatedIngredients = recipe.map(
          (name, amount) => MapEntry(name, (amount / baseWeight) * _inputWeight),
        );
      }
    });
  }

  String _getIngredientName(String uuid) {
    return ingredientsBox.isOpen
        ? ingredientsBox.get(uuid, defaultValue: 'Unknown Ingredient')
        : 'Unknown Ingredient';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: recipesBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return const Center(child: Text('No recipes available.'));
            }

            final recipeData = {
              for (var key in box.keys)
                (box.get(key)['name'] as String): {
                  for (var item in (box.get(key)['ingredients'] as List))
                    _getIngredientName(item['ingredient'] as String):
                        item['quantity'] as double
                }
            };

            final recipeNames = recipeData.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search and Select a Recipe:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return recipeNames;
                    return recipeNames.where((name) =>
                        name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedRecipe = selection;
                      _selectedIngredient = null;
                      _calculatedIngredients.clear();
                    });
                  },
                  initialValue: TextEditingValue(text: _selectedRecipe ?? ''),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: const InputDecoration(
                        labelText: 'Recipe name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedRecipe != null) ...[
                  const Text(
                    'Select an Ingredient or Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _selectedIngredient,
                    isExpanded: true,
                    hint: const Text('Choose an option'),
                    items: ['Total', ...?recipeData[_selectedRecipe!]?.keys]
                        .map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIngredient = value;
                        _calculatedIngredients.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter Weight (kg):',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _inputWeight = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _calculateProportions(recipeData),
                    child: const Text('Calculate'),
                  ),
                  const SizedBox(height: 16),
                  if (_calculatedIngredients.isNotEmpty)
                    const Text(
                      'Calculated Ingredients:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  Expanded(
                    child: ListView(
                      children: (_calculatedIngredients.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value))) // Ordena de mayor a menor
                          .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${entry.value.toStringAsFixed(2)} kg',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
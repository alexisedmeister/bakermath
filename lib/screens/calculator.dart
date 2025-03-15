import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  CalculatorScreenState createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> {
  late Box recipesBox;
  List<String> _recipes = [];
  Map<String, Map<String, double>> _recipeData = {};

  String? _selectedRecipe;
  String? _selectedIngredient;
  double _inputWeight = 0.0;
  Map<String, double> _calculatedIngredients = {};

  @override
  void initState() {
    super.initState();
    recipesBox = Hive.box('recipes');
    _loadRecipes();
  }

  void _loadRecipes() {
    final recipes = recipesBox.values.toList();
    setState(() {
      _recipes = recipes.map((r) => r['name'] as String).toList();
      _recipeData = {
        for (var recipe in recipes)
          recipe['name']: { for (var item in recipe['ingredients']) item['ingredient'] as String : item['quantity'] as double }
      };
    });
  }

  void _calculateProportions() {
    if (_selectedRecipe == null || (_selectedIngredient == null && _inputWeight == 0.0)) {
      return;
    }

    final recipe = _recipeData[_selectedRecipe!];

    if (_selectedIngredient == 'Total') {
      final totalWeight = recipe!.values.reduce((a, b) => a + b);
      setState(() {
        _calculatedIngredients = recipe.map(
          (ingredient, amount) => MapEntry(ingredient, (amount / totalWeight) * _inputWeight),
        );
      });
    } else {
      final baseWeight = recipe![_selectedIngredient!]!;
      setState(() {
        _calculatedIngredients = recipe.map(
          (ingredient, amount) => MapEntry(ingredient, (amount / baseWeight) * _inputWeight),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Recipe:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedRecipe,
              isExpanded: true,
              hint: const Text('Choose a recipe'),
              items: _recipes.map((recipe) {
                return DropdownMenuItem(
                  value: recipe,
                  child: Text(recipe),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecipe = value;
                  _selectedIngredient = null;
                  _calculatedIngredients.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select an Ingredient or Total:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedRecipe != null)
              DropdownButton<String>(
                value: _selectedIngredient,
                isExpanded: true,
                hint: const Text('Choose an option'),
                items: ['Total', ...?_recipeData[_selectedRecipe!]?.keys].map((option) {
                  return DropdownMenuItem(
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
            const Text(
              'Enter Weight (kg):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter weight in kilograms',
              ),
              onChanged: (value) {
                setState(() {
                  _inputWeight = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateProportions,
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
                children: _calculatedIngredients.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    subtitle: Text('${entry.value.toStringAsFixed(2)} kg'),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
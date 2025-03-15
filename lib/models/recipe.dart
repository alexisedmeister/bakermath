import '../models/ingredient.dart';
class Recipe {
  final String name;
  final String description;
  final Map<Ingredient, double> ingredients; // Ingrediente y cantidad

  Recipe({
    required this.name,
    required this.description,
    required this.ingredients,
  });
}
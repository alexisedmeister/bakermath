import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'recipesadd.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  RecipesScreenState createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  late final Box recipesBox = Hive.box('recipes');

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  Future<void> _deleteRecipe(dynamic key) async {
    await recipesBox.delete(key);
    setState(() {});
  }

  void _showDeleteConfirmationDialog(dynamic key) {
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
                _deleteRecipe(key);
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
        title: ValueListenableBuilder(
          valueListenable: recipesBox.listenable(),
          builder: (context, Box box, _) {
            return Text('Recipes (${box.keys.length})');
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
                labelText: 'Search recipes',
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
              valueListenable: recipesBox.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('No recipes available.'));
                }

                final recipeMap = box.toMap();
                final filteredKeys = recipeMap.keys.where((key) {
                  final name = recipeMap[key]['name'].toString().toLowerCase();
                  return name.contains(_searchTerm);
                }).toList()
                  ..sort((a, b) => recipeMap[a]['name']
                      .toLowerCase()
                      .compareTo(recipeMap[b]['name'].toLowerCase()));

                return ListView.builder(
                  itemCount: filteredKeys.length,
                  itemBuilder: (context, index) {
                    final key = filteredKeys[index];
                    final recipe = recipeMap[key];

                    return ListTile(
                      title: Text(recipe['name']),
                      subtitle: Text(recipe['description']),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipesAddScreen(
                              recipe: recipe,
                              recipeKey: key,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Delete') {
                            _showDeleteConfirmationDialog(key);
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipesAddScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
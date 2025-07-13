import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
    _loadedItems.then((items) {
      setState(() {
        _groceryItems.clear();
        _groceryItems.addAll(items);
      });
    });
  }

  Future<List<GroceryItem>> _loadItems() async {
    final firebaseUrl = dotenv.env['FIREBASE_URL'];
    final url = Uri.parse('$firebaseUrl/shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch Grocery Items, Please try again.');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem()));

    if (newItem == null) return;

    final loadedItems = await _loadItems();

    setState(() {
      _groceryItems.clear();
      _groceryItems.addAll(loadedItems);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final firebaseUrl = dotenv.env['FIREBASE_URL'];
    final url = Uri.parse('$firebaseUrl/shopping-list/${item.id}.json');

    // final url = Uri.https(
    //   'flutter-shopping-list-68fb2-default-rtdb.asia-southeast1.firebasedatabase.app',
    //   'shopping-list/${item.id}.json',
    // );

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      // Optional: แสดงข้อความเมื่อลบไม่สําเร็จ
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Product List',
          
        ),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _groceryItems.isEmpty
          ? const Center(child: Text('No items added yet.'))
          : ListView.builder(
              itemCount: _groceryItems.length,
              itemBuilder: (ctx, index) {
                final item = _groceryItems[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  onDismissed: (direction) {
                    _removeItem(item);
                  },
                  child: ListTile(
                    title: Text(item.name),
                    leading: Container(
                      width: 24,
                      height: 24,
                      color: item.category.color,
                    ),
                    trailing: Text(item.quantity.toString()),
                  ),
                );
              },
            ),
    );
  }
}

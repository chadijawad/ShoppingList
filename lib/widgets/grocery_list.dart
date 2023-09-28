import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceyList extends StatefulWidget {
  const GroceyList({super.key});

  @override
  State<GroceyList> createState() => _GroceyListState();
}

class _GroceyListState extends State<GroceyList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadItem();
  } //i want to get the data once i load or reload this widget thanks for initState()

  void _loadItem() async {
    final url = Uri.https(
      'flutter-prep-7be18-default-rtdb.firebaseio.com',
      'shopping_list.json',
    );
    try{
      final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data.Please try again';
      });
    }
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> lisData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in lisData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });

    }catch(error){
      setState(() {
        _error = 'An error occured!Please try again';
      });
    }
    
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      'flutter-prep-7be18-default-rtdb.firebaseio.com',
      'shopping_list/${item.id}.json',
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: ((context) => const NewItem()),
      ),
    );
    if (newItem == null) {
      return;
    }
  }

  //   if (newItem == null) {
  //     return;
  //   }
  //   setState(() {
  //     _groceryItems.add(newItem);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('Please add some items'),
    );
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(
            _groceryItems[index].id,
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('your Groceries'),
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
        ),
        body: content);
  }
}

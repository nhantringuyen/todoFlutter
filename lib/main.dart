// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async{
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('people');
  // Hive.registerAdapter(ContactAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(      
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Todo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _statusController = TextEditingController();
  bool isChecked = false;
  // final Rxn<int> selected = Rxn<int>();
  List<Map<String, dynamic>> _items = [];
  final _peopleBox = Hive.box('people');
  @override
  void  initState(){
    super.initState();
    _refreshItems();
  }
  void _refreshItems(){
    final data = _peopleBox.keys.map((key){
      final item = _peopleBox.get(key);
      return {"key" : key, "name": item["name"], "status": item["status"]};
    }).toList();

    setState(() {
      _items = data.reversed.toList();

    });
  }
  Future<void> _createItem(Map<String, dynamic> newItem) async{
    await _peopleBox.add(newItem);
    // print("amount data is ${_peopleBox.length}");
    _refreshItems();
    // print(_items.length);
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async{
    await _peopleBox.put(itemKey,item);
    _refreshItems();
  }

  Future<void> _deleteItem(int itemKey) async{
    await _peopleBox.delete(itemKey);
    _refreshItems();
    //Display a snack bar
    ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text("An item has been deleted")) 
    );
  }

  void _showForm(BuildContext ctx, int ? itemKey) async {
    if(itemKey != null) {
      final existingItem = _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      // _statusController.text = existingItem['status'];
       isChecked = existingItem['status'] ?? false;
    }    
    showModalBottomSheet(context: ctx, elevation: 5, isScrollControlled: true, 
    builder: (_) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            const SizedBox(
              height: 10,
            ),
            // TextField(
            //   controller: _statusController,
            //   keyboardType: TextInputType.number,
            //   decoration: const InputDecoration(hintText: 'Status')
            // ),
            // const SizedBox(
            //   height: 20
            // ),
            CheckboxListTile(
              title: const Text('Status'),
              value: isChecked,
              onChanged: (value) {
                setState(() {
                  isChecked = !isChecked;
                });
              },
            ),
            const SizedBox(height: 20),
              ElevatedButton(
              onPressed: () async{
                if(itemKey != null) {
                  _updateItem(
                    itemKey,{
                  "name": _nameController.text.trim(),
                  "status" : isChecked 
                });    
                }else{
                _createItem({
                  "name": _nameController.text,
                  "status" : isChecked
                });    
              }
              _nameController.text = '';
              // _statusController.text = '';
              Navigator.of(context).pop();
            },
            child: Text(itemKey == null ? 'Create Person' : 'Update Person'),
            ),   
            const SizedBox(
              height: 20
            ),        
          ],
        ),
      );    
      }
    )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
             // ignore: void_checks
             child: ListNote(items: _items, showForm : (context, index) => _showForm(context, index), deleteItem : (index) => _deleteItem(index!))
             
            )                
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        tooltip: 'Add person',
        child: const Icon(Icons.add),
      ), 
    );
  }
  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
  
  
}
class ListPerson{
  final int ? id;
  final String ? name;
  final bool  ? status;

  ListPerson({
    this.id,
    this.name,
    this.status
  });  
   // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }
  // Implement toString to make it easier to see information about
  @override
  String toString() {
    return 'ListPerson{id: $id, name: $name, status: $status}';
  }
}

class ListNote extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(BuildContext, int?) showForm;
  final void Function(int?) deleteItem;
  const ListNote({
    Key? key,
    required this.items,
    required this.showForm,
    required this.deleteItem
  }) : super(key: key);
  @override
  State<ListNote> createState() => _ListNoteState();
}
class _ListNoteState extends State<ListNote> {
  // final void Function(BuildContext, int?) showForm;
  // _ListNoteState(this.showForm); 
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
        return ListView.builder(itemCount: widget.items.length,itemBuilder: (_,index){
          final currentItem = widget.items[index]; 
          return Card(
            color: Colors.orange.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(currentItem['name']),
              subtitle: Text( currentItem['status'] ? 'true' : 'false'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => 
                      // ignore: avoid_print
                      // print("current item ${currentItem['key']}");
                      widget.showForm(context, currentItem['key'])
                    ,
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => widget.deleteItem(currentItem['key']),
                    icon: const Icon(Icons.delete),
                  )
                ],
              )
              ),
          );          
        });      
  }
}
  

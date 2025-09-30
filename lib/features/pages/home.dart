import 'package:dot_music/core/db/crud.dart';
import 'package:dot_music/core/db/db.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dh = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _showForm = false;

  Future<void> _createPlaylist() async {
    if (_formKey.currentState!.validate()) {
      final ps = PlaylistService();
      await ps.createPlaylist(_nameController.text);
      
      setState(() {
        _showForm = false;
        _nameController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( 
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (!_showForm)
              ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                child: Text("Создать плейлист"),
              ),

            if (_showForm) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Название плейлиста',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите название';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _createPlaylist,
                                child: Text('Создать'),
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showForm = false;
                                  _nameController.clear();
                                });
                              },
                              child: Text('Отмена'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: () => context.push("/list"),
              child: Text('Вызвать функцию'),
            ),

            ElevatedButton(
              onPressed: () => context.push("/listpl"), 
              child: Text("data")
            ),

            ElevatedButton(
              onPressed: () async => await dh.getAllTables(), 
              child: Text("TTTTTTT")
            )
          ],
        ),
      ),
    );
  }
}
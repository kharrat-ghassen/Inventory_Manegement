import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // To use SHA-256
import 'inventory_page.dart';

class AuthentificationPage extends StatefulWidget {
  @override
  const AuthentificationPage({super.key}); // Use the super parameter

  @override
  AuthentificationPageState createState() => AuthentificationPageState();
}

class AuthentificationPageState extends State<AuthentificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<String> getApplicationDocumentsDirectoryPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('Application documents directory: ${directory.path}');
      return directory.path;
    } catch (e) {
      debugPrint('Error getting application documents directory: $e');
      throw Exception('Failed to get application documents directory: $e');
    }
  }

  Future<void> authenticateUser() async {
    try {
      final path = await getApplicationDocumentsDirectoryPath();
      final file = File("$path/Inventery_Management/Authentification.csv");

      if (await file.exists()) {
        final csvData = await file.readAsString();
        final rows = const CsvToListConverter().convert(csvData);

        // Transform the ID to an integer
        int id = int.parse(_idController.text);

        if (id >= 0 && id < rows.length) {
          List<dynamic> idRow = rows[id + 1];
          String hash = idRow[4].toString();
          String name = idRow[1].toString(); // Second element for user name

          // Generate SHA-256 hash of the provided password
          String password = _passwordController.text;
          var bytes = utf8.encode(password);
          String passwordHash = sha256.convert(bytes).toString();
          debugPrint(passwordHash);
          debugPrint('hash is');
          debugPrint(hash);
          // Compare hashes
          if (hash == passwordHash) {
            debugPrint('Right password');
            String fileName = '${id}_$name';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Right password')),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryPage(fileName: fileName),
                ),
              );
            }
          } else {
            debugPrint('False password');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('False password')),
              );
              Navigator.pop(context);
            }
          }
        } else {
          debugPrint('Invalid ID');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid ID')),
            );
          }
        }
      } else {
        debugPrint('Authentification.csv file does not exist');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No authentication data found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error authenticating user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authentification'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(labelText: 'ID'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your ID';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Authenticating...')),
                      );
                      authenticateUser();
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

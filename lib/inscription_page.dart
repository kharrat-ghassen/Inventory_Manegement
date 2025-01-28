import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // To use SHA-256
import 'package:path/path.dart' as p;

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key}); // Use the super parameter

  @override
  InscriptionPageState createState() => InscriptionPageState();
}

class InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

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

  Future<void> checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.storage.status;

    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isDenied || status == PermissionStatus.permanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied. Unable to save data.')),
        );
      }
      return;
    }

    await readAndUpdateCsvFile();
  }

  Future<int> generateID() async {
    try {
      // It start here
      final path = await getApplicationDocumentsDirectoryPath();
      // Ensure the parent directory exists
      String invdirPath = p.join(path, "Inventery_Management");
      final invDir = Directory(invdirPath);
      if (await invDir.exists()) {
        debugPrint('User directory exists, opening it...');
      } else {
        debugPrint('User directory does not exist, creating it...');
        await invDir.create(recursive: true);
      }
      // end here
      //final path = await getApplicationDocumentsDirectoryPath();
      final file = File("$path/Inventery_Management/Authentification.csv");

      if (await file.exists()) {
        final csvData = await file.readAsString();
        final rows = const CsvToListConverter().convert(csvData);
        return rows.length - 1; // Number of rows - 1
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Error generating ID: $e');
      return 0;
    }
  }

  Future<void> readAndUpdateCsvFile() async {
    try {
      final path = await getApplicationDocumentsDirectoryPath();
      final file = File("$path/Inventery_Management/Authentification.csv");

      List<List<dynamic>> rows;

      // Check if the file exists
      if (await file.exists()) {
        // Read the existing CSV file
        final csvData = await file.readAsString();
        rows = const CsvToListConverter().convert(csvData);
        debugPrint('CSV file read successfully');
      } else {
        // Create the CSV file with the header if it doesn't exist
        rows = [
          ['Pays', 'Ville', 'Nom', 'ID', 'Hash']
        ];
        debugPrint('CSV file created with header');
      }
      // Automatically generate ID based on the number of rows
      int newId = rows.length - 1;
      _idController.text = newId.toString();
      // generating the hash
      String password = _passwordController.text;
      var bytes = utf8.encode(password);
      String hash = sha256.convert(bytes).toString();
      // Add new inscription data to the list
      rows.add([
        _countryController.text,
        _cityController.text,
        _nameController.text,
        _idController.text,
        hash,
      ]);

      // Convert rows to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save the updated CSV to the file
      await file.writeAsString(csv).then((_) async {
        debugPrint('File written successfully');

        // Read back the content to verify
        String fileContent = await file.readAsString();
        debugPrint('File content after write: $fileContent');
      }).catchError((error) {
        debugPrint('Error writing file: $error');
      });

      // Ensure the parent directory exists
      // final userfolder = Directory('$dirPath\\$foldername');
      String dirPath = p.join(path, "Inventery_Management/Users_dir");
      final userDir = Directory(dirPath);

      if (await userDir.exists()) {
        debugPrint('User directory exists, opening it...');
      } else {
        debugPrint('User directory does not exist, creating it...');
        await userDir.create(recursive: true);
      }
      // It start here
      String foldername = '${newId}_${_nameController.text}';
      final userfolder = Directory('$dirPath\\$foldername');
      if (await userfolder.exists()) {
        debugPrint('User folder exists, opening it...');
      } else {
        debugPrint('User folder does not exist, creating it...');
        await userfolder.create(recursive: true);
      }
      // it end here

      // Create the user-specific CSV file
      String userFileName = '${newId}_${_nameController.text}.csv';
      String userFilePath =
          p.join(userfolder.path, userFileName); //some modification here
      final userFile = File(userFilePath);

      // Generate the header for the user-specific CSV
      List<List<dynamic>> userRows = [
        ['ID', 'Product', 'Quantity(kg)', 'Provider', 'worker', 'Time']
      ];
      // Convert user rows to CSV
      String userCsv = const ListToCsvConverter().convert(userRows);

      // Write header to the user-specific CSV file
      await userFile.writeAsString(userCsv).then((_) async {
        debugPrint('User file written successfully');
        // Read back the content to verify
        String userFileContent = await userFile.readAsString();
        debugPrint('User file content after write: $userFileContent');
      }).catchError((error) {
        debugPrint('Error writing user file: $error');
      });

      if (!mounted) return; // Check if the widget is still mounted

      // Notify the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription data saved successfully!')),
        );

        // Navigate back to HomeScreen
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error reading and updating CSV file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read and update CSV file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(labelText: 'Country'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your country';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your name';
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
              SizedBox(height: 10),
              FutureBuilder<int>(
                future: generateID(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    _idController.text = snapshot.data.toString();
                    return TextFormField(
                      controller: _idController,
                      decoration: InputDecoration(labelText: 'ID'),
                      readOnly: true,
                    );
                  }
                },
              ),
              /*
              SizedBox(height: 10),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(labelText: 'ID'),
                readOnly: true,
                /*validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your ID';
                  }
                  return null;
                },*/
              ),*/
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      checkAndRequestPermissions();
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
    _countryController.dispose();
    _cityController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _idController.dispose();
    super.dispose();
  }
}

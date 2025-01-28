import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // for TextInputFormatter class
import 'package:decimal/decimal.dart';
import 'package:crypto/crypto.dart'; // Import for hashing
import 'dart:convert';

//import 'package:intl/intl.dart';
class InventoryPage extends StatefulWidget {
  final String fileName;

  const InventoryPage({required this.fileName, super.key});

  @override
  InventoryPageState createState() => InventoryPageState();
}

// Block class to represent a single block in the blockchain

class Block {
  final int index;
  final String previousHash;
  final String data; // Use dynamic to allow for different data structures
  final DateTime timestamp;
  final String hash;

  Block({
    required this.index,
    required this.previousHash,
    required this.data,
    required this.timestamp,
    required this.hash,
  });

  // Create a block
  static Block createBlock(int index, String previousHash, String data) {
    final timestamp = DateTime.now();
    final hash = _calculateHash(index, previousHash, data, timestamp);
    return Block(
        index: index,
        previousHash: previousHash,
        data: data,
        timestamp: timestamp,
        hash: hash);
  }

  // Calculate the SHA-256 hash
  static String _calculateHash(
      int index, String previousHash, String data, DateTime timestamp) {
    final key = utf8.encode(
        "$index$previousHash$data${timestamp.toIso8601String()}"); // Convert input to bytes
    final digest = sha256.convert(key); // Calculate SHA-256 digest
    return digest.toString(); // Return hash as hex string
  }

  // Override the toString method
  @override
  String toString() {
    //if (data == 'Genesis Block') {
    //return 'Block $index: $hash | Data: $data, Timestamp: 2025-01-27 19:44:33.503837';
    //} else {
    return 'Block $index: $hash | Data: $data, Timestamp: $timestamp';
    // {jsonDecode(data).join(', ')
    //}
  }

  // Method to create a Block from a string
  static Block fromString(String string) {
    // Split the string into parts
    final parts = string.split('|');
    if (parts.length != 2) {
      throw FormatException('Invalid block format: $string');
    }

    // Extracting the index and hash from the first part
    final headerPart = parts[0].trim();
    final headerParts = headerPart.split(':');
    if (headerParts.length != 2) {
      throw FormatException('Invalid header format: $headerPart');
    }

    final index = int.parse(headerParts[0].split(' ')[1]); // Extracting index
    final hash = headerParts[1].trim(); // Extracting hash

    // Extracting data from the second part
    final dataPart = parts[1].trim();
    if (!dataPart.startsWith('Data: ')) {
      throw FormatException('Invalid data part format: $dataPart');
    }

    final dataString = dataPart.substring(6); // Remove 'Data: ' prefix
    final dataComponents = dataString.split(', ').map((e) => e.trim()).toList();

    // Extracting the last component which is expected to be the timestamp
    final timestampString = dataComponents.removeLast();

    // Safely parse the timestamp
    final timestamp = _parseTimestamp(timestampString);
    //
    debugPrint("dataComponents=$dataComponents");
    String dataComponentsstr = dataComponents.join(', ');
    debugPrint("dataComponentsstr=$dataComponentsstr");
    // Create and return the new Block object
    return Block(
      index: index,
      previousHash: hash,
      data: dataComponentsstr,
      timestamp: timestamp,
      hash: hash,
    );
  }

  // Helper method to parse the timestamp
  static DateTime _parseTimestamp(String timestampString) {
    try {
      // Remove the "Timestamp: " prefix if present
      if (timestampString.startsWith('Timestamp: ')) {
        timestampString = timestampString.replaceFirst('Timestamp: ', '');
      }

      // Parse the cleaned timestamp string
      final regex =
          RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{6})$');
      final match = regex.firstMatch(timestampString);

      if (match == null) {
        throw FormatException('Invalid timestamp format: $timestampString');
      }

      // Extract components from the match
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      final microsecond = int.parse(match.group(7)!);

      // Create the DateTime object
      return DateTime(year, month, day, hour, minute, second, 0, microsecond);
    } catch (e) {
      throw FormatException(
          'Failed to parse timestamp: $timestampString. Error: $e');
    }
  }
}

// Blockchain class to manage the chain of blocks
class Blockchain {
  List<Block> chain = [];

  Blockchain() {
    chain.add(
        Block.createBlock(0, '0', 'Genesis Block')); // Create the genesis block
  }

  // Add a new block with the given data
  void addBlock(List<String> data) {
    final previousBlock = chain.last;
    final newBlock = Block.createBlock(
        previousBlock.index + 1, previousBlock.hash, data.join(', '));
    chain.add(newBlock);
  }

  // Add a method to convert the blockchain to a string representation
  List<String> toStringList() {
    return chain.map((block) => block.toString()).toList();
  }
}

class InventoryPageState extends State<InventoryPage> {
  List<List<dynamic>> _csvData = [];
  var blockchain = Blockchain(); // Initialize the blockchain
  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = "${directory.path}\\Inventery_Management\\Users_dir";

      final filePath = "$dirPath\\${widget.fileName}\\${widget.fileName}.csv";
      final file = File(filePath);

      /*final blockchaintxtFilePath =
          "$dirPath\\${widget.fileName}\\Blockchain_${widget.fileName}.txt";
      final blockchaintxtFile = File(blockchaintxtFilePath);*/

      _loadTxtFile();

      if (await file.exists()) {
        final csvData = await file.readAsString();
        final rows =
            const CsvToListConverter(fieldDelimiter: ',').convert(csvData);
        setState(() {
          _csvData = rows;
        });
      }
    } catch (e) {
      debugPrint('Error loading CSV: $e');
    }
  }

  Future<void> _addRow(List<dynamic> row) async {
    setState(() {
      _csvData.add(row);
    });
    await _saveCSV();
    await _updateTxtFile(row.map((item) => item.toString()).toList());
  }

  Future<void> _updateRow(
      int rowIndex, String newWorkerName, Decimal newQuantity) async {
    setState(() {
      _csvData[rowIndex + 1][2] = newQuantity; // Update quantity
      _csvData[rowIndex + 1][4] = newWorkerName; // Update worker name
      _csvData[rowIndex + 1][5] = DateTime.now();
    });
    await _saveCSV();
    await _updateTxtFile(
        _csvData[rowIndex + 1].map((item) => item.toString()).toList());
  }

  Future<void> _loadTxtFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = "${directory.path}\\Inventery_Management\\Users_dir";

      final blockchaintxtFilePath =
          "$dirPath\\${widget.fileName}\\Blockchain_${widget.fileName}.txt";
      final blockchaintxtFile = File(blockchaintxtFilePath);

      // Check if the Blockchain.txt file exists, if not create it
      if (await blockchaintxtFile.exists()) {
        // Load the existing blockchain from the file
        _loadBlockchainFromFile(blockchaintxtFile);
      }

      // Save the blockchain to the blockchain text file
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Error updating the txt file: $e'),
        );
        // Display the SnackBar on the screen
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _saveBlockchainToFile(File blockchaintxtFile) async {
    try {
      // Write each block to the file, each on a new line
      await blockchaintxtFile.writeAsString(
          blockchain.chain.map((block) => block.toString()).join('\n'));
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Error saving the blockchain: $e'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        debugPrint('Error saving the blockchain: $e');
      }
    }
  }

  Future<void> _loadBlockchainFromFile(File blockchaintxtFile) async {
    try {
      // Read the contents of the file
      final contents = await blockchaintxtFile.readAsString();

      // Split the contents into lines
      final lines = contents.split('\n');

      // Assuming you have a method to reconstruct a block from its string representation
      List<Block> loadedBlocks = lines.map((line) {
        // You should implement a way to parse 'line' back into a Block object
        return Block.fromString(
            line); // Assuming you have a `fromString` factory method or similar
      }).toList();

      // Now we can create a new Blockchain instance and set its chain
      blockchain.chain =
          loadedBlocks; // Assuming you can directly set the chain

      // Optionally show a success message
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Blockchain loaded successfully!'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      // Show error message if necessary
      if (mounted) {
        final snackBar = SnackBar(
          content: Text('Error loading the blockchain: $e'),
        );
        debugPrint('Error loading the blockchain: $e');
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _updateTxtFile(List<String> updatedRow) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = "${directory.path}\\Inventery_Management\\Users_dir";

      final txtFilePath =
          "$dirPath\\${widget.fileName}\\${widget.fileName}.txt";
      final txtFile = File(txtFilePath);

      final blockchaintxtFilePath =
          "$dirPath\\${widget.fileName}\\Blockchain_${widget.fileName}.txt";
      final blockchaintxtFile = File(blockchaintxtFilePath);

      // Check if the .txt file exists, if not create it
      if (!await txtFile.exists()) {
        await txtFile.create();
      }
      // Check if the Blockchain.txt file exists, if not create it
      if (!await blockchaintxtFile.exists()) {
        await blockchaintxtFile.create();
      }

      // Open the .txt file in append mode
      await txtFile.writeAsString('${updatedRow.join('|')}\n',
          mode: FileMode.append);
      // Add the updated row to the blockchain
      blockchain.addBlock(updatedRow);
      // Save the blockchain to the blockchain text file
      /*await blockchaintxtFile.writeAsString(
          'Block ${blockchain.chain.last.index}: ${blockchain.chain.last.hash} | Data: ${updatedRow.join(', ')}\n',
          mode: FileMode.append);*/
      _saveBlockchainToFile(blockchaintxtFile);
    } catch (e) {
      final snackBar = SnackBar(
        content: Text('Error updating the txt file: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _saveCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = "${directory.path}\\Inventery_Management\\Users_dir";
      final filePath = "$dirPath\\${widget.fileName}\\${widget.fileName}.csv";
      final file = File(filePath);
      final csvContent = const ListToCsvConverter().convert(_csvData);
      await file.writeAsString(csvContent);
    } catch (e) {
      final snackBar = SnackBar(
        content: Text('Error updating the file: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _showAddRowDialog() async {
    final TextEditingController productController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController providerController = TextEditingController();
    final TextEditingController workerController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Row"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Remove the ID TextField, we will generate it programmatically
              TextField(
                decoration: InputDecoration(labelText: 'ID', enabled: false),
                controller:
                    TextEditingController(text: (_csvData.length).toString()),
              ),
              TextField(
                controller: productController,
                decoration: InputDecoration(labelText: 'Product'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(labelText: 'Quantity(kg)'),
              ),
              TextField(
                controller: providerController,
                decoration: InputDecoration(labelText: 'Provider'),
              ),
              TextField(
                controller: workerController,
                decoration: InputDecoration(labelText: 'Worker Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (!mounted) return; // Check if the widget is still mounted

                // Automatically generate the ID based on the current data length
                int id = _csvData.length; // Use the length of _csvData for ID

                // Prepare a new row with the calculated ID
                List<dynamic> newRow = [
                  id.toString(),
                  productController.text,
                  quantityController.text,
                  providerController.text,
                  workerController.text,
                  DateTime.now().toString(),
                ];
                _addRow(newRow);
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateRowDialog(int rowIndex) async {
    final TextEditingController workerController =
        TextEditingController(text: _csvData[rowIndex + 1][4].toString());
    final TextEditingController quantityController =
        TextEditingController(text: _csvData[rowIndex + 1][2].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Row"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  controller: workerController,
                  decoration: InputDecoration(labelText: 'Worker Name')),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(labelText: 'Quantity(kg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (!mounted) return; // Check if the widget is still mounted
                Decimal oldQuantity =
                    Decimal.parse(_csvData[rowIndex + 1][2].toString());
                Decimal newQuantity = Decimal.parse(quantityController.text);
                Decimal zero = Decimal.fromInt(0);
                if (newQuantity <= oldQuantity && newQuantity != zero) {
                  Decimal quantity = oldQuantity - newQuantity;
                  _updateRow(rowIndex, workerController.text, quantity);
                  Navigator.of(context).pop();
                } else {
                  final snackBar = SnackBar(
                    content: Text(
                        'New quantity must be less than or equal the old quantity and different from 0.'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _visualizeBlockchain() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Blockchain Visualization'),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(blockchain.chain.length, (index) {
                final block = blockchain.chain[index];
                return ListTile(
                  title: Text('Block ${block.index}'),
                  subtitle: Text(
                      'Hash: ${block.hash}\nData: ${block.data.toString()}\nPrevious Hash: ${block.previousHash}\nTimestamp: ${block.timestamp}'),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
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
        title: Text('Inventory'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: _visualizeBlockchain, // Button to visualize blockchain
          ),
        ],
      ),
      body: Center(
        child: _csvData.isNotEmpty
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false, // Disable selection checkboxes
                  columns: List.generate(
                    _csvData[0].length,
                    (index) => DataColumn(
                      label: Text(_csvData[0][index]
                          .toString()), // Use index directly for header
                    ),
                  ),
                  rows: List.generate(
                    _csvData.length -
                        1, // Start from 1 if the first row is a header
                    (rowIndex) {
                      final row = _csvData[rowIndex + 1]; // Skip header
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            _showUpdateRowDialog(
                                rowIndex); // Handle row selection
                          }
                        },
                        cells: List.generate(
                          row.length, // Use entire row length
                          (colIndex) => DataCell(
                            Text(row[colIndex].toString()), // Display cell data
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            : Center(
                child: Text("No CSV content available."),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRowDialog, // Show dialog to add a new row
        child: Icon(Icons.add),
      ),
    );
  }
}

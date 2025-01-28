import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'inscription_page.dart';
import 'authentification_page.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key}); // Use the super parameter
  final Logger logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management App'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Inventory.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AuthentificationPage()),
                  );
                },
                child: Text('Authentification'),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InscriptionPage()),
                  );
                },
                child: Text('Inscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

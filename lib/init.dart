// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gymdo/mpage.dart';
import 'sql.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  InitPageState createState() => InitPageState();
}

class InitPageState extends State<InitPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController nameController = TextEditingController();

  query(String query) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.customQuery(query);
  }

  verifyLog() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery('select Init from user');
    //print(queryResult);
    if (queryResult[0]['Init'] == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MPage(),
        ),
      );
    }
  }

  @override
  void initState() {
    verifyLog();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Adjust the height of the AppBar
        child: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'New User',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Make the text bold
              fontSize: 24.0, // Adjust the font size
              color: Colors.white,
            ),
          ),
          centerTitle: true, // Align the title in the center horizontally
          titleSpacing: 0.0, // Adjust the spacing around the title
        ),
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Insert your Name'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    cursorColor: Colors.black, // Set the cursor color to black
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Label moves to top when focused
                      labelStyle: TextStyle(color: Colors.black), // Label color
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Change the border color when focused
                        ),
                      ),
                      // Error border when focused
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black, // Change error border color when focused
                        ),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.black), // Icon color
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      query("insert into User values (0, '${nameController.text}', 1);");
                      verifyLog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymdo/mpage.dart';

import 'sql.dart';

class InitPage extends StatefulWidget {
  @override
  _InitPageState createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController _NameController = TextEditingController();

  Query(String query) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery(query);
    print(query);
  }

  // ignore: non_constant_identifier_names
  VerifyLog() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> queryResult =
        await dbHelper.customQuery('select init from user');
    print(queryResult);
    if (queryResult[0]['init'] == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MPage(),
        ),
      );
    }
  }

  @override
  void initState() {
    VerifyLog();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0), // Adjust the height of the AppBar
        child: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Novo Utilizador',
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
                  Text('Insere o teu Nome'),
                  SizedBox(height: 20),
                  TextField(
                    controller: _NameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors
                              .black, // Change the border color when focused
                        ),
                      ),
                      // Specify constant color for the label when focused
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Query("insert into user values (0, '" +
                          _NameController.text +
                          "', 1);");
                      VerifyLog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(200, 50),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'sql.dart';

class MPage extends StatefulWidget {
  @override
  _MPageState createState() => _MPageState();
}

class _MPageState extends State<MPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<String> names = [];
  String data = '', dia = '', obj = 'Cardio';
  List<bool> Completed = [];
  List<bool> Expanded = [];
  double expandedHeight = 50;

  ChangeValue(bool value, int index) {
    Completed[index] = value;
    setState(() {});
  }

  ChangeExpanded(bool value, int index) {
    Expanded[index] = value;
    if (value) {
      setState(() {
        print('expanded');
        expandedHeight += 50; // Adjust this value as needed
      });
    } else {
      setState(() {
        // Decrease the height of the SizedBox by the same amount
        expandedHeight -= 50; // Adjust this value as needed
      });
    }
  }

  Query(String query) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery(query);
    print(queryResult);
    for (int i = 0; i < queryResult.length; i++) {
      names.add(queryResult[i]['name']);
      DateTime now = DateTime.now();
      data = DateFormat('d', 'pt_BR').format(now).toString();
      dia = DateFormat('EEEE', 'pt_BR').format(now).toString();
      String formattedDate =
          DateFormat('kk:mm:ss \n EEEE d MMMM', 'pt_BR').format(now);
      print(formattedDate);

      print(Completed[0]);

      setState(() {});
    }
  }

  @override
  void initState() {
    Completed.add(false);
    Expanded.add(false);
    Query("select name from user");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _textFieldController = TextEditingController();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Text(
            names.isNotEmpty ? 'Olá ${names[0]}' : 'Olá',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          titleSpacing: 10.0,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 178,
              width: MediaQuery.of(context).size.width - 10,
              child: Card(
                color: Color.fromARGB(255, 233, 233, 233),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Card(
                              color: Colors.white,
                              elevation: 3,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height / 7,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50.0,
                                      ),
                                    ),
                                    Text(dia),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 25,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Card(
                              elevation: 3,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height / 14,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Objetivo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24.0,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height / 14,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      obj,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                      ),
                                    )
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: MediaQuery.of(context).size.width - 10,
              height: MediaQuery.of(context).size.height / 2,
              child: Container(
                // Set a fixed height or use constraints to avoid overflow errors
                child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: expandedHeight,
                        child: Column(
                          children: [
                            Card(
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 5,
                                      ),
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.black,
                                        child: Text(
                                          (index + 1).toString(),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 25,
                                      ),
                                      Text(
                                        'Seated Row',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.8,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Checkbox(
                                            value: Completed.isEmpty
                                                ? false
                                                : Completed[0],
                                            onChanged: (value) {
                                              ChangeValue(value!, index);
                                            }),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Checkbox(
                                            value: Expanded.isEmpty
                                                ? false
                                                : Expanded[0],
                                            onChanged: (value) {
                                              ChangeExpanded(value!, index);
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: expandedHeight - 50,
                              child: Row(
                                children: [Text(data)],
                              ),
                            )
                          ],
                        ));
                  },
                ),
              ),
            )
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _textFieldController,
                  decoration: InputDecoration(
                    hintText: 'Enter Name',
                  ),
                ),
              ),
              SizedBox(width: 10),
              FloatingActionButton(
                onPressed: () async {
                  String name = _textFieldController.text;
                  print(name);
                  if (name.isNotEmpty) {
                    Query(name);
                  }
                },
                child: Icon(Icons.add),
              ),
            ],
          ),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sql.dart';

class CPage extends StatefulWidget {
  @override
  _CPageState createState() => _CPageState();
}

class _CPageState extends State<CPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String data = '', dia = '';
  DateTime now = DateTime.now();

  List<String> weekDays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];

  Future<void> query(String query) async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery(query);
    print(queryResult);
  }

  @override
  void initState() {
    super.initState();
    data = DateFormat('d', 'pt_BR').format(now).toString();
    dia = _getWeekDay(); // Get the localized weekday name
  }

  String _getWeekDay() {
    String formattedWeekDay = DateFormat('EEEE', 'pt_BR').format(now);
    formattedWeekDay =
        formattedWeekDay[0].toUpperCase() + formattedWeekDay.substring(1);
    if (weekDays.contains(formattedWeekDay)) {
      return formattedWeekDay;
    } else {
      return weekDays[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(70.0), // Adjust the height of the AppBar
        child: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the back button color to white
          ),
          title: const Text(
            'Alterar Plano',
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
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 5,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: dia,
                  decoration: const InputDecoration(
                    border: InputBorder.none, // Remove the border
                    contentPadding: EdgeInsets.zero, // Remove padding
                  ),
                  items: weekDays.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Center(child: Text(day)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        dia = newValue;
                        query(
                            "select * from Exer e, Dias d where e.coddia=d.iddia and d.name='$dia'");
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          // Add any additional content here
          Expanded(
            child: Center(
              child: Text(
                'Content goes here',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CPage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CPage(),
  ));
}

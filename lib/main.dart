import 'package:flutter/material.dart';
import 'package:gymdo/init.dart';
import 'package:intl/date_symbol_data_local.dart';

const Color primaryColor = Color.fromARGB(255, 0, 0, 0); // Example primary color
const Color secondaryColor = Color.fromARGB(255, 255, 255, 255); // Example secondary color
//const Color accentColor1 = Color.fromARGB(255, 0, 0, 0);
const Color accentColor1 = Color.fromARGB(255, 48, 48, 48);
const Color accentColor2 = Colors.red; // Example accent color 2

void main() {
  initializeDateFormatting('pt_BR', null);
  runApp(MainPage());
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InitPage(),
    );
  }
}

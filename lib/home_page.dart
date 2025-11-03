import 'package:flutter/material.dart';
//import 'package:racunalni_sah/champions.dart';
//import 'package:racunalni_sah/chessopenings.dart';
//import 'package:racunalni_sah/choice.dart';
//import 'package:racunalni_sah/tactics.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.brown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.greenAccent,
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80.0)),
                minimumSize: const Size(240, 160),
              ),
              onPressed: () {
          /*      Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return const Choice();
                    },
                  ),
                );*/
              },
              child: const Text(
                'Play',
                style: TextStyle(
                    fontSize: 40,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
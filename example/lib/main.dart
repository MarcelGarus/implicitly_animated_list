import 'dart:math';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var numbers = <int>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Implicitly animated list')),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('Generate numbers'),
          icon: Icon(Icons.directions_walk),
          onPressed: () => setState(() {
            numbers = List.generate(10, (_) => Random().nextInt(10));
            print(numbers);
          }),
        ),
        body: ImplicitlyAnimatedList(
          itemData: numbers,
          itemBuilder: (_, number) => ListTile(title: Text('$number')),
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _numbers = [1, 2, 3, 4, 5, 6];
  var _initialAnimation = false;
  var _resetKey = ValueKey(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Implicitly animated list'),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.settings),
              itemBuilder: (context) {
                return [
                  CheckedPopupMenuItem(
                    value: "toggleAnimation",
                    checked: _initialAnimation,
                    padding: EdgeInsets.zero,
                    child: Text("InitialAnimation?"),
                  ),
                  PopupMenuItem(
                    value: "performReset",
                    child: Text("Reset View"),
                  ),
                ];
              },
              onSelected: (value) {
                if (value == "toggleAnimation") {
                  setState(() {
                    _initialAnimation = !_initialAnimation;
                  });
                } else if (value == "performReset") {
                  setState(() {
                    _resetKey = ValueKey(_resetKey.value + 1);
                    _numbers = [1, 2, 3, 4, 5, 6];
                  });
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('Generate numbers'),
          icon: Icon(Icons.directions_walk),
          onPressed: () => setState(() {
            _numbers = List.generate(10, (_) => Random().nextInt(10));
            print(_numbers);
          }),
        ),
        body: ImplicitlyAnimatedList(
          key: _resetKey,
          initialAnimation: _initialAnimation,
          itemData: _numbers,
          itemBuilder: (_, number) => ListTile(title: Text('$number')),
        ),
      ),
    );
  }
}

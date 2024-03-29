import 'dart:math';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

void main() => runApp(MyApp());

class MyItem {
  final int value;
  final int version;

  const MyItem({this.value, this.version});

  @override
  bool operator ==(dynamic other) {
    return other is MyItem &&
        this.value == other.value &&
        this.version == other.version;
  }

  @override
  int get hashCode => value + version;

  @override
  String toString() => '$value (version: $version)';
}

List<MyItem> updateItems(List<MyItem> old) {
  return List.generate(
    10,
    (i) => MyItem(
      value: Random().nextInt(3),
      version: i < old.length ? old[i].version + 1 : 0,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _items = updateItems([]);
  var _initialAnimation = true;
  var _customEquality = true;
  var _resetKey = ValueKey(0);

  bool _myCustomEquality(MyItem a, MyItem b) => a.value == b.value;

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
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: "toggleAnimation",
                  checked: _initialAnimation,
                  padding: EdgeInsets.zero,
                  child: Text("Use initial animation?"),
                ),
                CheckedPopupMenuItem(
                  value: "toggleEquality",
                  checked: _customEquality,
                  padding: EdgeInsets.zero,
                  child: Text("Use custom equality?"),
                ),
                PopupMenuItem(
                  value: "performReset",
                  child: Text("Reset View"),
                ),
              ],
              onSelected: (value) {
                if (value == "toggleAnimation") {
                  setState(() => _initialAnimation = !_initialAnimation);
                } else if (value == "toggleEquality") {
                  setState(() => _customEquality = !_customEquality);
                } else if (value == "performReset") {
                  setState(() {
                    _resetKey = ValueKey(_resetKey.value + 1);
                    _items = updateItems([]);
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
            _items = updateItems(_items);
            print(_items);
          }),
        ),
        body: ImplicitlyAnimatedList<MyItem>(
          key: _resetKey,
          initialAnimation: _initialAnimation,
          itemData: _items,
          itemBuilder: (_, item) => ListTile(title: Text('$item')),
          itemEquality: _customEquality ? _myCustomEquality : null,
        ),
      ),
    );
  }
}

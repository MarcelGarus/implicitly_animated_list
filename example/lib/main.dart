import 'dart:math';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

void main() => runApp(MyApp());

class MyData {
  final int value;
  final int version;

  const MyData({
    this.value,
    this.version,
  })  : assert(value != null),
        assert(version != null);

  @override
  int get hashCode => value + version;

  @override
  bool operator ==(dynamic other) {
    if (other is MyData) {
      return this.value == other.value && this.version == other.version;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    return '$value (version: $version)';
  }
}

List<MyData> updateDatas(List<MyData> old) {
  return List.generate(
    10,
    (idx) => MyData(
      value: Random().nextInt(3),
      version: idx < old.length ? old[idx].version + 1 : 0,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _datas = updateDatas([]);
  var _initialAnimation = true;
  var _customEquality = true;
  var _resetKey = ValueKey(0);

  bool _myCustomEquality(MyData a, MyData b) {
    return a.value == b.value;
  }

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
                ];
              },
              onSelected: (value) {
                if (value == "toggleAnimation") {
                  setState(() {
                    _initialAnimation = !_initialAnimation;
                  });
                } else if (value == "toggleEquality") {
                  setState(() {
                    _customEquality = !_customEquality;
                  });
                } else if (value == "performReset") {
                  setState(() {
                    _resetKey = ValueKey(_resetKey.value + 1);
                    _datas = updateDatas([]);
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
            _datas = updateDatas(_datas);
            print(_datas);
          }),
        ),
        body: ImplicitlyAnimatedList<MyData>(
          key: _resetKey,
          initialAnimation: _initialAnimation,
          itemData: _datas,
          itemBuilder: (_, data) => ListTile(title: Text('$data')),
          itemEquality: _customEquality ? _myCustomEquality : null,
        ),
      ),
    );
  }
}

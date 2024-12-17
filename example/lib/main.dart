import 'dart:math';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

void main() => runApp(MyApp());

class MyItem {
  const MyItem({required this.value, required this.version});

  final int value;
  final int version;

  @override
  bool operator ==(Object other) {
    return other is MyItem &&
        this.value == other.value &&
        this.version == other.version;
  }

  @override
  int get hashCode => Object.hash(value, version);

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
          actions: [_buildSettingsButton()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('Generate numbers'),
          icon: Icon(Icons.directions_walk),
          onPressed: () => setState(() {
            _items = updateItems(_items);
            print(_items);
          }),
        ),
        body: Row(
          children: [
            _listWithTitle(
              title: 'ImplicitlyAnimatedList',
              child: ImplicitlyAnimatedList(
                key: _resetKey,
                initialAnimation: _initialAnimation,
                insertDuration: Duration(milliseconds: 500),
                deleteDuration: Duration(milliseconds: 500),
                itemData: _items,
                itemBuilder: (context, item) => ListTile(title: Text('$item')),
                itemEquality: _customEquality ? _myCustomEquality : null,
              ),
            ),
            VerticalDivider(),
            _listWithTitle(
              title: 'SliverImplicitlyAnimatedList',
              child: CustomScrollView(
                slivers: [
                  SliverImplicitlyAnimatedList(
                    key: _resetKey,
                    initialAnimation: _initialAnimation,
                    insertDuration: Duration(milliseconds: 500),
                    deleteDuration: Duration(milliseconds: 500),
                    itemData: _items,
                    itemBuilder: (context, item) =>
                        ListTile(title: Text('$item')),
                    itemEquality: _customEquality ? _myCustomEquality : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return PopupMenuButton(
      icon: Icon(Icons.settings),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: _SettingAction.toggleAnimation,
          checked: _initialAnimation,
          child: Text("Use initial animation?"),
        ),
        CheckedPopupMenuItem(
          value: _SettingAction.toggleEquality,
          checked: _customEquality,
          child: Text("Use custom equality?"),
        ),
        PopupMenuItem(
          value: _SettingAction.performReset,
          child: Text("Reset View"),
        ),
      ],
      onSelected: (value) => setState(() {
        switch (value) {
          case _SettingAction.toggleAnimation:
            _initialAnimation = !_initialAnimation;
          case _SettingAction.toggleEquality:
            _customEquality = !_customEquality;
          case _SettingAction.performReset:
            _resetKey = ValueKey(_resetKey.value + 1);
            _items = updateItems([]);
        }
      }),
    );
  }

  Widget _listWithTitle({required String title, required Widget child}) {
    return Expanded(
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center),
          Expanded(child: child),
        ],
      ),
    );
  }
}

enum _SettingAction { toggleAnimation, toggleEquality, performReset }

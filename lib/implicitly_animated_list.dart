import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:list_diff/list_diff.dart';

typedef AnimatedChildBuilder = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

Animation<double> _driveDefaultAnimation(Animation<double> parent) {
  return CurvedAnimation(
    parent: parent,
    curve: Curves.easeInOutQuad,
  ).drive(Tween<double>(begin: 0, end: 1));
}

Widget _defaultAnimation(
    BuildContext context, Widget child, Animation<double> animation) {
  return SizeTransition(
    sizeFactor: _driveDefaultAnimation(animation),
    child: FadeTransition(
      opacity: _driveDefaultAnimation(animation),
      child: child,
    ),
  );
}

class ImplicitlyAnimatedList<ItemData> extends StatefulWidget {
  const ImplicitlyAnimatedList({
    Key? key,
    required this.itemData,
    required this.itemBuilder,
    this.insertAnimation = _defaultAnimation,
    this.deleteAnimation = _defaultAnimation,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  }) : super(key: key);

  final List<ItemData> itemData;
  final Widget Function(BuildContext context, ItemData data) itemBuilder;
  final AnimatedChildBuilder insertAnimation;
  final AnimatedChildBuilder deleteAnimation;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  @override
  _ImplicitlyAnimatedListState<ItemData> createState() =>
      _ImplicitlyAnimatedListState<ItemData>();
}

class _ImplicitlyAnimatedListState<ItemData>
    extends State<ImplicitlyAnimatedList<ItemData>> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<ItemData> _dataForBuild = List.empty(growable: true);

  var sizeTween = Tween<double>(begin: 0, end: 1);

  @override
  void initState() {
    super.initState();

    _updateData(widget.itemData, _dataForBuild);
  }

  @override
  void didUpdateWidget(ImplicitlyAnimatedList<ItemData> oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool hasNewItems = widget.itemData.any((e) => !_dataForBuild.contains(e));
    bool hasRemovedItems =
        _dataForBuild.any((e) => !widget.itemData.contains(e));
    if (hasNewItems || hasRemovedItems) {
      _updateData(widget.itemData, _dataForBuild);
    }
  }

  Future<void> _updateData(List<ItemData> from, List<ItemData> to) async {
    final operations = await diff(to, from);
    setState(() {
      for (final op in operations) {
        op.applyTo(to);

        if (op.isInsertion) {
          _listKey.currentState!.insertItem(op.index);
        } else if (op.isDeletion) {
          _listKey.currentState!.removeItem(op.index, (context, animation) {
            return widget.deleteAnimation(
              context,
              widget.itemBuilder(context, op.item),
              animation,
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      controller: widget.controller,
      initialItemCount: _dataForBuild.length,
      padding: widget.padding,
      physics: widget.physics,
      primary: widget.primary,
      reverse: widget.reverse,
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      itemBuilder: (context, index, animation) {
        return widget.insertAnimation(
          context,
          widget.itemBuilder(context, _dataForBuild[index]),
          animation,
        );
      },
    );
  }
}

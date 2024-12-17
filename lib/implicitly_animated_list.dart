import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:list_diff/list_diff.dart';

typedef AnimatedChildBuilder = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

// The default insert/remove animation duration of [AnimatedList].
const _defaultDuration = Duration(milliseconds: 300);

Animation<double> _driveDefaultAnimation(Animation<double> parent) {
  return CurvedAnimation(
    parent: parent,
    curve: Curves.easeInOutQuad,
  ).drive(Tween<double>(begin: 0, end: 1));
}

Widget _defaultAnimation(
  BuildContext context,
  Widget child,
  Animation<double> animation,
) {
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
    super.key,
    required this.itemData,
    required this.itemBuilder,
    this.itemEquality,
    this.insertDuration = _defaultDuration,
    this.insertAnimation = _defaultAnimation,
    this.deleteDuration = _defaultDuration,
    this.deleteAnimation = _defaultAnimation,
    this.scrollDirection = Axis.vertical,
    this.initialAnimation = true,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });

  final List<ItemData> itemData;
  final bool Function(ItemData a, ItemData b)? itemEquality;
  final Widget Function(BuildContext context, ItemData data) itemBuilder;
  final Duration insertDuration;
  final AnimatedChildBuilder insertAnimation;
  final Duration deleteDuration;
  final AnimatedChildBuilder deleteAnimation;
  final bool initialAnimation;
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
  final _dataForBuild = List<ItemData>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    if (widget.initialAnimation) {
      Future.microtask(() {
        _updateData(widget.itemData, _dataForBuild);
      });
    } else {
      _dataForBuild.addAll(widget.itemData);
    }
  }

  @override
  void didUpdateWidget(ImplicitlyAnimatedList<ItemData> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(widget.itemData, _dataForBuild)) {
      _updateData(widget.itemData, _dataForBuild);
    }
  }

  void _updateData(List<ItemData> to, List<ItemData> from) {
    final listState = _listKey.currentState;
    final equalityCustom = widget.itemEquality;

    setState(() {
      final operations = diffSync(from, to);
      final operationsCustom = equalityCustom != null
          ? diffSync(from, to, areEqual: equalityCustom)
          : operations;

      // First apply all animations to the list but without touching the model.
      if (listState != null) {
        for (final op in operationsCustom) {
          if (op.isInsertion) {
            listState.insertItem(
              op.index,
              duration: widget.insertDuration,
            );
          } else if (op.isDeletion) {
            listState.removeItem(
              op.index,
              (context, animation) => widget.deleteAnimation(
                context,
                widget.itemBuilder(context, op.item),
                animation,
              ),
              duration: widget.deleteDuration,
            );
          }
        }
      }

      // Then update the model according to the intrinsic item-data equality to
      // make sure that:
      // - the next diff will operate on the correct base,
      // - rendering of the remove-item animation will use the last known item-data, and
      // - we always use refreshed item-datas when building.
      for (final op in operations) {
        op.applyTo(from);
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

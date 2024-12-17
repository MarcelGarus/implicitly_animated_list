import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:list_diff/list_diff.dart';

typedef AnimatedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
  Animation<double> animation,
);

/// The default insert/remove animation duration of [AnimatedList].
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

abstract class _BaseWidget<W extends _BaseWidget<W, T>, T>
    extends StatefulWidget {
  const _BaseWidget({
    super.key,
    required this.itemData,
    required this.itemBuilder,
    this.itemEquality,
    this.insertDuration = _defaultDuration,
    this.insertAnimation = _defaultAnimation,
    this.deleteDuration = _defaultDuration,
    this.deleteAnimation = _defaultAnimation,
    this.initialAnimation = true,
  });

  final List<T> itemData;
  final bool Function(T a, T b)? itemEquality;
  final Widget Function(BuildContext context, T data) itemBuilder;
  final Duration insertDuration;
  final AnimatedChildBuilder insertAnimation;
  final Duration deleteDuration;
  final AnimatedChildBuilder deleteAnimation;
  final bool initialAnimation;
}

abstract class _BaseState<W extends _BaseWidget<W, T>, T> extends State<W> {
  final _dataForBuild = List<T>.empty(growable: true);

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
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(widget.itemData, _dataForBuild)) {
      _updateData(widget.itemData, _dataForBuild);
    }
  }

  void _updateData(List<T> to, List<T> from) {
    final equalityCustom = widget.itemEquality;

    setState(() {
      final operations = diffSync(from, to);
      final operationsCustom = equalityCustom != null
          ? diffSync(from, to, areEqual: equalityCustom)
          : operations;

      // First apply all animations to the list but without touching the model.
      for (final op in operationsCustom) {
        if (op.isInsertion) {
          _insertItem(
            op.index,
            duration: widget.insertDuration,
          );
        } else if (op.isDeletion) {
          _removeItem(
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

  void _insertItem(int index, {Duration duration});
  void _removeItem(int index, AnimatedRemovedItemBuilder builder,
      {Duration duration});
}

class ImplicitlyAnimatedList<ItemData>
    extends _BaseWidget<ImplicitlyAnimatedList<ItemData>, ItemData> {
  const ImplicitlyAnimatedList({
    super.key,
    required super.itemData,
    required super.itemBuilder,
    super.itemEquality,
    super.insertDuration = _defaultDuration,
    super.insertAnimation = _defaultAnimation,
    super.deleteDuration = _defaultDuration,
    super.deleteAnimation = _defaultAnimation,
    super.initialAnimation = true,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });

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
    extends _BaseState<ImplicitlyAnimatedList<ItemData>, ItemData> {
  final _listKey = GlobalKey<AnimatedListState>();

  void _insertItem(int index, {Duration duration = _defaultDuration}) =>
      _listKey.currentState?.insertItem(index, duration: duration);
  void _removeItem(
    int index,
    AnimatedRemovedItemBuilder builder, {
    Duration duration = _defaultDuration,
  }) =>
      _listKey.currentState?.removeItem(index, builder, duration: duration);

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
      itemBuilder: (context, index, animation) => widget.insertAnimation(
        context,
        widget.itemBuilder(context, _dataForBuild[index]),
        animation,
      ),
    );
  }
}

class SliverImplicitlyAnimatedList<ItemData>
    extends _BaseWidget<SliverImplicitlyAnimatedList<ItemData>, ItemData> {
  const SliverImplicitlyAnimatedList({
    super.key,
    required super.itemData,
    required super.itemBuilder,
    super.itemEquality,
    super.insertDuration = _defaultDuration,
    super.insertAnimation = _defaultAnimation,
    super.deleteDuration = _defaultDuration,
    super.deleteAnimation = _defaultAnimation,
    super.initialAnimation = true,
  });

  @override
  _SliverImplicitlyAnimatedListState<ItemData> createState() =>
      _SliverImplicitlyAnimatedListState<ItemData>();
}

class _SliverImplicitlyAnimatedListState<ItemData>
    extends _BaseState<SliverImplicitlyAnimatedList<ItemData>, ItemData> {
  final _listKey = GlobalKey<SliverAnimatedListState>();

  void _insertItem(int index, {Duration duration = _defaultDuration}) =>
      _listKey.currentState?.insertItem(index, duration: duration);
  void _removeItem(
    int index,
    AnimatedRemovedItemBuilder builder, {
    Duration duration = _defaultDuration,
  }) =>
      _listKey.currentState?.removeItem(index, builder, duration: duration);

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _dataForBuild.length,
      itemBuilder: (context, index, animation) => widget.insertAnimation(
        context,
        widget.itemBuilder(context, _dataForBuild[index]),
        animation,
      ),
    );
  }
}

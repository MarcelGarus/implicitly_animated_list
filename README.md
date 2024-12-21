Often, your lists represent some kind of data.

You can just pass the original list data to the `ImplicitlyAnimatedList` as
well as an `itemBuilder` for building a widget from one data point, and it'll
animate whenever the data changes:

```dart
ImplicitlyAnimatedList(
  // When you change items of this list and hot reload, the list animates.
  itemData: [1, 2, 3, 4],
  itemBuilder: (_, number) => ListTile(title: Text('$number')),
),
```

It works with all classes and works well with `StreamBuilder`:

```dart
class User {
  const User({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  // The ImplicitlyAnimatedList uses the == operator to compare items.
  bool operator ==(Object other) => other is User
    && firstName == other.firstName
    && lastName == other.lastName;
}

...

StreamBuilder<List<User>>(
  stream: someSource.usersStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return ...;
    }
    return ImplicitlyAnimatedList(
      itemData: snapshot.data,
      itemBuilder: (context, user) {
        return ListTile(title: Text('${user.firstName} ${user.lastName}'));
      }
    );
  }
)
```

Here's an example that generates random numbers and animates from one state to the next (notice it's only 10 fps because of being a GIF):

![example showcase](showcase.gif)

In addition to `ImplicitlyAnimatedList`, there's also `SliverImplicitlyAnimatedList` for use in a `CustomScrollView`:

```dart
CustomScrollView(
  slivers: [
    SliverImplicitlyAnimatedList(
      itemData: myListOfItems,
      itemBuilder: (context, item) => ListTile(title: Text('$item')),
    ),
    // ...
  ],
),
```

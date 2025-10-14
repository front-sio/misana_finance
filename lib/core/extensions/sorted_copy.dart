extension SortedCopyExtension<T> on Iterable<T> {
  List<T> sorted([int Function(T a, T b)? compare]) {
    final list = List<T>.of(this); // make a mutable copy
    if (compare != null) {
      list.sort(compare);
    } else {
      // If T is Comparable, this works; otherwise provide a comparator.
      list.sort();
    }
    return list;
  }
}
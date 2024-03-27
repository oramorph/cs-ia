class BoardStack<type> {
  List<type> elements = [];

  void push(type element) {
    elements.add(element);
  }

  type pop() {
    if (elements.isNotEmpty) {
      return elements.removeLast();
    } else {
      throw StateError('Cannot pop from an empty stack');
    }
  }

  type get top {
    if (elements.isNotEmpty) {
      return elements.last;
    } else {
      throw StateError('Stack is empty');
    }
  }

  int get length => elements.length;

  bool get isEmpty => elements.isEmpty;

  bool get isNotEmpty => elements.isNotEmpty;
}
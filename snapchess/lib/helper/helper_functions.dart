bool isWhite(int index) {
  int x = index ~/ 8; // Row number
  int y = index % 8; // Column number
  bool isWhite = (x + y) % 2 == 0; // Alternating Colors
  return isWhite;
}

bool isInBoard(int row, int col) {
  return row >= 0 && row <= 7 && col >= 0 && col <= 7;
}
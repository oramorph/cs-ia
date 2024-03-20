import 'package:snapchess/components/piece.dart';

bool isWhite(int index) {
  int x = index ~/ 8; // Row number
  int y = index % 8; // Column number
  bool isWhite = (x + y) % 2 == 0; // Alternating Colors
  return isWhite;
}

bool isInBoard(int row, int col) {
  return row >= 0 && row <= 7 && col >= 0 && col <= 7;
}

ChessPiece charToPiece(String char) {
  bool isWhite = (char != char.toLowerCase());
  ChessPieceType type;
  switch(char.toLowerCase()) {
    case 'p':
      type = ChessPieceType.pawn;
    case 'r':
      type = ChessPieceType.rook;
    case 'n':
      type = ChessPieceType.knight;
    case 'b':
      type = ChessPieceType.bishop;
    case 'q':
      type = ChessPieceType.queen;
    default: // Use default to avoid compilation error
      type = ChessPieceType.king;
  }
  return ChessPiece(type: type, isWhite: isWhite);
}
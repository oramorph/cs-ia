import 'dart:core';
enum ChessPieceType{pawn, rook, knight, bishop, queen, king}

class ChessPiece {
  final ChessPieceType type;
  final bool isWhite;
  late final String imagePath;

  ChessPiece({
    required this.type,
    required this.isWhite,
  }){
    imagePath = getImagePath(type, isWhite);
  }

  String getImagePath(type, isWhite){
    final strippedType = type.toString().replaceFirst('ChessPieceType.', ''); // Strip the prefix
    return 'lib/images/${isWhite ? 'white' : 'black'}_$strippedType.png';
  }
}
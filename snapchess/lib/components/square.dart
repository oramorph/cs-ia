import 'package:flutter/material.dart';
import 'package:snapchess/components/piece.dart';
import 'package:snapchess/values/colors.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece; // Can be null for empty square
  final bool isSelected;
  final bool isValidMove;
  final bool isCapturable;
  final void Function() onTap;

  const Square({
    super.key, 
    required this.isWhite,
    required this.piece,
    required this.isSelected,
    required this.onTap,
    required this.isValidMove,
    required this.isCapturable,
  });

  @override
  Widget build(BuildContext context) {
    Color? squareColor;

    // if selected, square is green
    if (isSelected && piece != null){
      squareColor = Colors.green;
    }
    // otherwise, it's white or black
    else {
      squareColor = isWhite ? lightTile : darkTile;
    }
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
            Container(
              color: squareColor
            ),
          if (!isValidMove) 
            Container(
              child: piece != null ? Image.asset(piece!.imagePath) : null,
            ),
          if (isValidMove && !isCapturable)
            Positioned.fill(
              child: Container(
                color: Colors.green[300],
                margin: EdgeInsets.all(8),
                child: piece != null ? Image.asset(piece!.imagePath) : null,
              ),
            ),
          if (isValidMove && isCapturable)
            Positioned.fill(
              child: Container(
                color: Colors.red[300],
                margin: EdgeInsets.all(8),
                child: piece != null ? Image.asset(piece!.imagePath) : null,
              ),
            ),
        ],
      ),
    );
  }
}
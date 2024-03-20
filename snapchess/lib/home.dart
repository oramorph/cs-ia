import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:snapchess/components/piece.dart';
import 'package:snapchess/components/square.dart';
import 'package:snapchess/helper/helper_functions.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Upload Function
  File? selectedImage;
  String? fen = "";
  bool loading = false;

  uploadImage() async{
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {loading = true;}); 
    selectedImage = File(pickedImage!.path);
    final request = http.MultipartRequest("POST", Uri.parse('https://68a2-139-226-186-28.ngrok-free.app/upload'));

    final headers = {"Content-type": "multipart/form-data"};

    request.files.add(
      http.MultipartFile('image', selectedImage!.readAsBytes().asStream(),selectedImage!.lengthSync(), filename: selectedImage!.path.split("/").last)
    );

    request.headers.addAll(headers);
    final response = await request.send();
    http.Response res = await http.Response.fromStream(response);
    final resJson = jsonDecode(res.body);
    fen = resJson['message'];
    setFEN(fen!);
    setState((){loading = false;});
  }

  // 2D Array Representing Chessboard
  late List<List<ChessPiece?>> board;

  // Selected Piece
  ChessPiece ? selectedPiece; 
  int selectedRow = -1;
  int selectedCol = -1;

  // Whose turn
  bool isWhiteTurn = true;

  // Tracking King Position
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;
  bool checkMateStatus = false;
  
  // 2D Array Representing Valid Moves for Current Piece
  List<List<int>> validMoves = [];

  @override
  void initState(){
    super.initState();
    _initializeBoard();
  }

  // Initialize Board
  void _initializeBoard(){
    List<List<ChessPiece?>> newBoard = List.generate(8, (index) => List.generate(8, (index) => null));

    // Pawns
    for (int i = 0; i < 8; i ++){
      newBoard[1][i] = ChessPiece(type: ChessPieceType.pawn, isWhite: false);
    }
    for (int i = 0; i < 8; i ++){
      newBoard[6][i] = ChessPiece(type: ChessPieceType.pawn, isWhite: true);
    }
    // Rooks
    for(int i = 0; i < 8; i += 7){
      for(int j = 0; j < 8; j += 7){
        newBoard[i][j] = ChessPiece(type: ChessPieceType.rook, isWhite: i == 0 ? false : true);
      }
    }
    // Knights
    for(int i = 0; i < 8; i += 7){
      for(int j = 1; j < 8; j += 5){
        newBoard[i][j] = ChessPiece(type: ChessPieceType.knight, isWhite: i == 0 ? false : true);
      }
    }
    // Bishops
    for(int i = 0; i < 8; i += 7){
      for(int j = 2; j < 8; j += 3){
        newBoard[i][j] = ChessPiece(type: ChessPieceType.bishop, isWhite: i == 0 ? false : true);
      }
    }
    // Queens
    for(int i = 0; i < 8; i += 7){
      newBoard[i][3] = ChessPiece(type: ChessPieceType.queen, isWhite: i == 0 ? false : true);
    }
    // Kings
    for(int i = 0; i < 8; i += 7){
      newBoard[i][4] = ChessPiece(type: ChessPieceType.king, isWhite: i == 0 ? false : true);
    }

    board = newBoard;
  }

  // User selects piece
  void pieceSelected(int row, int col) {
    setState((){
      // No piece selected
      if (selectedPiece == null && board[row][col] != null && board[row][col]!.isWhite == isWhiteTurn) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      }
      // Piece selected
      else if (board[row][col] != null && board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;        
      }

      // Piece selected and tap on valid square
      else if (selectedPiece != null && validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      validMoves = calculateRealValidMoves(selectedRow, selectedCol, selectedPiece);
    });


  }

  // Calculate Raw Valid Moves
  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    // When Selecting Empty Tile
    if(piece == null){
      return candidateMoves;
    }

    // When Selecting a Piece
    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // One move forward
        if (isInBoard(row + direction, col) && board[row + direction][col] == null){
          candidateMoves.add([row + direction, col]);
        }
        // Two moves forward on first move
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)){
          if (isInBoard(row + 2 * direction, col) && board[row + 2 * direction][col] == null && board[row + direction][col] == null){
            candidateMoves.add([row + 2 * direction, col]);
          }
        }
        // Taking diagonally
        if ((isInBoard(row + direction, col - 1) && board[row + direction][col - 1] != null && board[row + direction][col - 1]!.isWhite != board[row][col]!.isWhite)){
          candidateMoves.add([row + direction, col - 1]);
        }
        if ((isInBoard(row + direction, col + 1) && board[row + direction][col + 1] != null && board[row + direction][col + 1]!.isWhite != board[row][col]!.isWhite)){
          candidateMoves.add([row + direction, col + 1]);
        }
        break;
      case ChessPieceType.rook:
        // Horizontal and Vertical
        var directions = [[-1, 0],[0, -1],[0, 1],[1, 0]];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (isInBoard(newRow, newCol) && board[newRow][newCol] == null){
              candidateMoves.add([newRow, newCol]);
              i++;
            }
            else if (isInBoard(newRow, newCol) && (board[newRow][newCol]!.isWhite != piece.isWhite)) {
              candidateMoves.add([newRow, newCol]);
              break;
            }
            else{
              break;
            }
          }
        }
        break;
      case ChessPieceType.knight:
        // L-Shapes
        var knightMoves = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]];
        for(var move in knightMoves){
          var newRow = row + move[0];
          var newCol = col + move[1];
          if(isInBoard(newRow, newCol) && (board[newRow][newCol] == null || board[newRow][newCol]!.isWhite != piece.isWhite)){
            candidateMoves.add([newRow, newCol]);
            
          }
        }
        break;
      case ChessPieceType.bishop:
        // Horizontal and Vertical
        var directions = [[-1, -1],[-1, 1],[1, -1],[1, 1]];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (isInBoard(newRow, newCol) && board[newRow][newCol] == null){
              candidateMoves.add([newRow, newCol]);
              i++;
            }
            else if (isInBoard(newRow, newCol) && (board[newRow][newCol]!.isWhite != piece.isWhite)) {
              candidateMoves.add([newRow, newCol]);
              break;
            }
            else{
              break;
            }
          }
        }
        break;
      case ChessPieceType.queen:
        // All Directions
        var directions = [[-1, -1],[-1, 0],[-1, 1],[0, -1],[0, 1],[1, -1],[1, 0],[1, 1]];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (isInBoard(newRow, newCol) && board[newRow][newCol] == null){
              candidateMoves.add([newRow, newCol]);
              i++;
            }
            else if (isInBoard(newRow, newCol) && (board[newRow][newCol]!.isWhite != piece.isWhite)) {
              candidateMoves.add([newRow, newCol]);
              break;
            }
            else{
              break;
            }
          }
        }
        break;
      case ChessPieceType.king:
        // L-Shapes
        var kingMoves = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]];
        for(var move in kingMoves){
          var newRow = row + move[0];
          var newCol = col + move[1];
          if(isInBoard(newRow, newCol) && (board[newRow][newCol] == null || board[newRow][newCol]!.isWhite != piece.isWhite)){
            candidateMoves.add([newRow, newCol]);
            
          }
        }
        break;
    }
    return candidateMoves;
  }

  // Calculate Real Valid Moves
  List<List<int>> calculateRealValidMoves(int row, int col, ChessPiece? piece){
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRawValidMoves(row, col, piece);

    // If empty square selected
    if(piece == null){
      return realValidMoves;
    }

    // Filter out ones resulting in check
    for (var move in candidateMoves) {
      int endRow = move[0];
      int endCol = move[1];

      // Simulate future move to see if safe
      if(simulatedMoveIsSafe(piece, row, col, endRow, endCol)) {
        realValidMoves.add(move);
      }
    }

    return realValidMoves;
  }
  
  // Simulate Future Move
  bool simulatedMoveIsSafe(ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    // Save current state
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    // If piece is king, save current position and update to new one
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      if(piece.isWhite){
        originalKingPosition = whiteKingPosition;
        whiteKingPosition = [endRow, endCol];
      }
      else{
        originalKingPosition = blackKingPosition;
        blackKingPosition = [endRow, endCol];
      }
    }

    // Simulate
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // Check
    bool kingInCheck = isKingInCheck(piece.isWhite);

    // Restore to original state
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    // If the piece was the king, restore its original position
    if (piece.type == ChessPieceType.king) {
      piece.isWhite ? whiteKingPosition = originalKingPosition! : blackKingPosition = originalKingPosition!;
    }

    return !kingInCheck;
  }
  
  // Move Piece
  void movePiece(int newRow, int newCol) {
    // Check if piece being moved is a king
    if (selectedPiece != null && selectedPiece!.type == ChessPieceType.king){
      selectedPiece!.isWhite ? whiteKingPosition = [newRow, newCol] : blackKingPosition = [newRow, newCol];
    }

    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    checkStatus = isKingInCheck(!isWhiteTurn);
    checkMateStatus = isCheckmate(!isWhiteTurn);
    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    if (isCheckmate(!isWhiteTurn)) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text("CHECK MATE"),
          actions: [
            TextButton(onPressed: resetGame, child: const Text("Play Again")),
          ],
        )
      );
    }

    isWhiteTurn = !isWhiteTurn;
  }

  // Is King in Check
  bool isKingInCheck(bool isWhiteKing) {
    
    List<int> kingPosition = isWhiteKing ? whiteKingPosition : blackKingPosition;

    for (int i = 0; i < 8; i ++){
      for (int j = 0; j < 8; j++){
        if (board[i][j] != null && board[i][j]!.isWhite != isWhiteKing) {
          List<List<int>> pieceValidMoves = calculateRawValidMoves(i, j, board[i][j]);
          if (pieceValidMoves.any((move) => move[0] == kingPosition[0] && move[1] == kingPosition[1])){
            return true;
          }
        }
      }
    }
    return false;
  } 

  // Is it Checkmate
  bool isCheckmate(bool isWhiteKing){
    for (int i = 0; i < 8; i ++) {
      for (int j = 0; j < 8; j ++) {
        if (board[i][j] != null && board[i][j]!.isWhite == isWhiteKing) {
          List<List<int>> validMoves = calculateRealValidMoves(i, j, board[i][j]);
          if(validMoves.isNotEmpty) return false;
        }
      }
    }
    return true;
  }
  // Set board to FEN

  void setFEN(String fen) {
    int row = 0;
    int col = 0;
    for(int i = 0; i < fen.length; i ++) {
      String char = fen[i];
      if (char == '/') {
        row++;
        col = 0;
      }
      else if(RegExp(r'\d').hasMatch(char)) { // Finding empty tiles
        for (int j = 0; j < int.parse(char); j++) {
          board[row][col] = null;
          col++;
        }
      }
      else {
        board[row][col] = charToPiece(char);
        col++;
      }
    }

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });
  }
  // Extract FEN from board

  // Reset Game
  void resetGame() {
    Navigator.pop(context);
    _initializeBoard();
    checkStatus = false;
    checkMateStatus = false;
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height * 0.85; // Height of available area
    var w = MediaQuery.of(context).size.width; // Width of available area
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'SnapChess', 
          style: GoogleFonts.roboto(),
        )
      ),
      body: Container(
        height: h,
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 100, 
              width: 100, 
              padding: EdgeInsets.all(20), 
              child: Image.asset('lib/images/logo.png', color:Colors.teal)
            ),
            Text(
              'SnapChess', 
              style: GoogleFonts.roboto(
                fontSize: 20, 
                fontWeight: FontWeight.bold)
            ),
            SizedBox(height:10), 
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: GridView.builder(
                  itemCount: 8 * 8,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: 
                    const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemBuilder: (context, index) {

                    // Obtain row and column
                    int row = index ~/ 8;
                    int col = index % 8;

                    // Check if selected
                    bool isSelected = selectedRow == row && selectedCol == col;

                    // Check if valid move
                    bool isValidMove = false;
                    for(var position in validMoves){
                      if(position[0] == row && position[1] == col){
                        isValidMove = true;
                      }
                    }
                    // Check if capturable
                    bool isCapturable = false;
                    if(isInBoard(selectedRow, selectedCol)){ // Piece has been selected
                      // Square needs to have an opponent piece that is also a valid move
                      if(isValidMove && board[row][col] != null && board[selectedRow][selectedCol]!.isWhite != board[row][col]!.isWhite){ 
                        isCapturable = true;
                      }
                    }

                    return Square(
                      isSelected: isSelected,
                      isWhite: isWhite(index),
                      piece: board[row][col],
                      isValidMove: isValidMove,
                      isCapturable: isCapturable,
                      onTap: () => pieceSelected(row, col)
                    );
                  },
                ),
              ),
            ), // Chessboard
            Text(checkMateStatus ? "CHECKMATE!" : checkStatus ? "CHECK!" : ""),
            loading ? Container(
            width: MediaQuery.of(context).size.width * 0.8, // Setting progress bar width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Rounded edges
            ),
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[300], // Progress bar background color
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal), // Progress bar color
            ),
            ) 
            : SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 70,
              child: Padding(
                padding: EdgeInsets.all(0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: uploadImage,
                  child: Text(
                    'Upload from Gallery',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          ])
          
      ),
    );
  }
}

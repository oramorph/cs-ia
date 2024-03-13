import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height; // Height of available area
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
        // color: Colors.red,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 150, 
              width: 150, 
              padding: EdgeInsets.all(10), 
              //color: Colors.green,
              child: Image.asset('assets/logo.png', color:Colors.teal)
            ),
            Container(
              child: Text(
                'SnapChess', 
                style: GoogleFonts.roboto(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold)
              )
            ),
            SizedBox(height:10),
            Container(
              width:double.infinity,
              height:70,
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.teal,
                ),
                child: Text(
                  'Camera',
                  style: GoogleFonts.roboto(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold)), 
                onPressed: (){},
              )
            ),
            Container(
              width:double.infinity,
              height:70,
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.teal,
                ),
                child: Text(
                  'Gallery',
                  style: GoogleFonts.roboto(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold)), 
                onPressed: (){},
              )
            )
          ])
      ),
    );
  }
}

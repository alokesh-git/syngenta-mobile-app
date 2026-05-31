import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Text(
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color:Colors.green[600]),
        title,
      ),
    );
  }
}

class LeafAppIcon extends StatelessWidget {
  const LeafAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(color: Colors.green[600], Icons.spa),
      ),
    );
  }
}

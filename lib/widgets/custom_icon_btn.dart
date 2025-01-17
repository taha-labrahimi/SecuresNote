import 'package:flutter/material.dart';

class CustomIconBtn extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final Widget icon;

  const CustomIconBtn({
    Key? key,
    required this.color,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? textColor;

  const AppLogo({
    Key? key,
    this.size = 120,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF3AAFA9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'SN',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'StudyNotion',
          style: TextStyle(
            fontSize: size * 0.25,
            fontWeight: FontWeight.bold,
            color: textColor ?? const Color(0xFF3AAFA9),
          ),
        ),
      ],
    );
  }
} 
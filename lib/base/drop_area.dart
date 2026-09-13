import 'package:flutter/material.dart';

class DropArea extends StatefulWidget {
  const DropArea({super.key});

  @override
  State<DropArea> createState() => _DropAreaState();
}

class _DropAreaState extends State<DropArea> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _hovered ? Colors.grey.shade300 : Colors.grey.shade200;

    return Container(
      padding: EdgeInsets.fromLTRB(0, 75, 0, 75),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * 0.95,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade500,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            'Drop visual components here...',
            textAlign: .center,
            style: TextStyle(
              fontSize: 25,
              color: Colors.grey.shade800,

            ),
          ),
        ),
      ),
    );
  }
}

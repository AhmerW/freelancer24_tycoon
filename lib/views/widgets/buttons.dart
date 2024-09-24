import 'package:flutter/material.dart';

class GoBackButton extends StatelessWidget {
  final Function() callback;
  const GoBackButton(this.callback, {super.key});

  @override
  Widget build(BuildContext context) {
    // rectangle square shape style
    return SizedBox(
      child: ElevatedButton(
        onPressed: callback,
        child: const Text("Go back"),
      ),
    );
  }
}

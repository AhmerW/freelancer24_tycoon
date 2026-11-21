import 'package:flutter/material.dart';

/// Placeholder for marketing campaigns (planned for a later phase).
class MarketingView extends StatelessWidget {
  const MarketingView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String label) => Tooltip(
          message: '$label: coming soon',
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: null,
            child: Icon(icon),
          ),
        );

    return Column(
      children: [
        const Text('Marketing (coming soon)'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            button(Icons.phone_outlined, 'Cold calls'),
            button(Icons.radio_outlined, 'Radio ads'),
            button(Icons.email_outlined, 'Email campaign'),
          ],
        ),
      ],
    );
  }
}

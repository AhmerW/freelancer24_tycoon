import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key});

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Marketing (0 active campaigns)",
          style: GoogleFonts.robotoCondensed(
            fontSize: 14,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () {},
                child: const Icon(
                  Icons.phone_outlined,
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () {},
                child: const Icon(
                  Icons.radio_outlined,
                )),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () {},
                child: const Icon(
                  Icons.email_outlined,
                ))
          ],
        )
      ],
    );
  }
}

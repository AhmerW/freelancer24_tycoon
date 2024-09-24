import 'package:flutter/material.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
      children: [
        Column(
          children: [
            const Text(
              "...Freelancing day 1 of 30",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: const Text("30 cases closed"),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: const Text("5 total employees across 3 cities"),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      child: const Text("View more stats"),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ),
          ],
        )
      ],
    ));
  }
}

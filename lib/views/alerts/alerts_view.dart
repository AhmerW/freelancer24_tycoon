import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  void close(Alert alert) => setState(() {
        BlocProvider.of<AlertBloc>(context).add(RemoveAlertEvent(alert));
      });

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: AnimatedContainer(
        duration: 200.ms,
        height: 90.h,
        width: 250,
        child: BlocBuilder<AlertBloc, AlertState>(
          builder: (context, state) {
            if (state is LoadedAlertState) {
              return ListView.builder(
                itemCount: state.alerts.length,
                itemBuilder: (context, index) {
                  Alert alert = state.alerts[index];
                  return Container(
                      height: 100,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]),
                      child: Container(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  alert.title,
                                  style: GoogleFonts.robotoCondensed(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => close(alert),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                            alert.widget != null
                                ? alert.widget!
                                : Text(alert.message)
                          ],
                        ),
                      ));
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

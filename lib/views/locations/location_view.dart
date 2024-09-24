import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/contracts/contract_bloc.dart';
import 'package:freelancer24_tycoon/blocs/locations/location_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/contracts_view.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/offers_view.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employees_view.dart';
import 'package:freelancer24_tycoon/views/locations/marketing_view.dart';
import 'package:freelancer24_tycoon/views/widgets/fade_indexed_stack.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class LocationView extends StatefulWidget {
  final Location location;
  final Function() onClose;
  const LocationView(this.location, this.onClose, {super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  int index = 10;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      alignment: Alignment.center,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.all(20),
      width: 95.w,
      height: 95.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // repeat image in background

          Positioned.fill(
            child: Image.asset(
              width: 70,
              height: 70,
              "assets/icons/locations/${widget.location.icon}",
              color: Colors.grey.withOpacity(0.1),
              repeat: ImageRepeat.repeat,
            ),
          ),

          Column(
            children: [
              Container(
                child: AnimatedTextKit(
                    repeatForever: false,
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TyperAnimatedText(
                        "${widget.location.city}, ${widget.location.country}",
                        speed: const Duration(milliseconds: 50),
                        textStyle: GoogleFonts.robotoCondensed(
                          fontSize: 20.sp,
                        ),
                      ),
                    ]),
              ),
              SizedBox(
                height: 20,
                child: Text(
                  "Freelance Portal V.1.0",
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 15.sp,
                    // add underline
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: widget.location.locked
                    ? LockedLocationView(widget.location,
                        onClose: widget.onClose)
                    : Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          index == 10
                              ? const MarketingView()
                              : const SizedBox.shrink(),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(top: 15),
                              child: index != 10
                                  ? BlocBuilder<ContractBloc, ContractState>(
                                      builder: (context, state) {
                                        List<Contract> contracts =
                                            BlocProvider.of<ContractBloc>(
                                          context,
                                        ).getContractsGenIfEmpty(
                                          widget.location,
                                        );

                                        return FadeIndexedStack(
                                          index: index,
                                          children: [
                                            OffersView(
                                              widget.location,
                                              contracts
                                                  .where((c) => !c.accepted)
                                                  .toList(),
                                              onReject: () => setState(() {
                                                index = index;
                                              }),
                                              callback: () => setState(() {
                                                index = 10;
                                              }),
                                              callbackContracts: () => {
                                                setState(() {
                                                  index = 1;
                                                })
                                              },
                                            ),
                                            ContractsView(
                                                contracts
                                                    .where((c) => c.accepted)
                                                    .toList(),
                                                widget.location,
                                                callback: () => setState(() {
                                                      index = 10;
                                                    })),
                                            EmployeesView(
                                              widget.location,
                                              callback: () => setState(() {
                                                index = 10;
                                              }),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : Wrap(
                                      children: [
                                        LocationOptionButton(
                                          callback: () => setState(() {
                                            index = 0;
                                          }),
                                          text: "Show available offers",
                                          icon: Icons.work_outline,
                                        ),
                                        LocationOptionButton(
                                          callback: () => setState(() {
                                            index = 1;
                                          }),
                                          text: "Show ongoing contracts",
                                          icon: Icons.description_outlined,
                                        ),
                                        LocationOptionButton(
                                          callback: () => setState(() {
                                            index = 2;
                                          }),
                                          text: "Manage employees ",
                                          icon: Icons.badge_outlined,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          Container(
            alignment: Alignment.topRight,
            child: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close_rounded,
                )),
          ),
        ],
      ),
    );
  }
}

class LocationOptionButton extends StatelessWidget {
  final Function() callback;
  final IconData icon;
  final String text;
  const LocationOptionButton({
    super.key,
    required this.callback,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: UniqueKey(),
      padding: const EdgeInsets.all(20),
      height: 15.h,
      width: 90.w,
      child: ElevatedButton(
          onPressed: callback,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40.w,
                child: Text(
                  text,
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 18.sp,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Icon(icon)
            ],
          )),
    );
  }
}

class LockedLocationView extends StatefulWidget {
  final Location location;
  final Function() onClose;
  const LockedLocationView(this.location, {super.key, required this.onClose});

  @override
  State<LockedLocationView> createState() => _LockedLocationViewState();
}

class _LockedLocationViewState extends State<LockedLocationView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              widget.location.message,
              style: GoogleFonts.robotoCondensed(
                fontSize: 17.sp,
              ),
            ),
          ),
        ),
        Column(
          children: [
            const Icon(
              Icons.lock,
              size: 40,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    BlocProvider.of<LocationBloc>(context)
                        .add(UnlockLocationEvent(widget.location));
                  });
                },
                child: Text(
                    "Unlock for ${r'$'}${formatMoney(widget.location.price.toDouble())}"))
          ],
        )
      ],
    );
  }
}

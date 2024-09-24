import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/locations/location_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/views/locations/location_view.dart';
import 'package:freelancer24_tycoon/views/locations/stats_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class LocationsView extends StatefulWidget {
  const LocationsView({super.key});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  Location? clickedLocation;
  bool updatedInitial = false;

  final _imageKey = GlobalKey();
  Size imageSize = Size.zero;

  void _updateImageSize(_) {
    final size = _imageKey.currentContext?.size;
    if (size == null) return;
    if (imageSize != size) {
      imageSize = size;
      // When the window is resized using keyboard shortcuts (e.g. Rectangle.app),
      // The widget won't rebuild AFTER this callback. Therefore, the new
      // image size is not used to update the bounding box drawing.
      // So we call setState
      setState(() {});
    } else {
      if (!updatedInitial) {
        updatedInitial = true;
        Future.delayed(const Duration(milliseconds: 250), () {
          setState(() {});
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset(
      "assets/images/worldmap.png",
      fit: BoxFit.fill,
      key: _imageKey,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black.withOpacity(0.8)
          : Colors.black,
    );
    MediaQuery.of(context);

    WidgetsBinding.instance.addPostFrameCallback(_updateImageSize);
    return SafeArea(
      child: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          if (state is LoadedLocationState) {
            List<Location> locs =
                BlocProvider.of<LocationBloc>(context).getAllLocations();
            return Stack(
              children: [
                Column(
                  children: [image, const StatsView()],
                ),
                for (Location loc in locs)
                  Positioned(
                    left: imageSize.width * loc.widthMultiplier,
                    top: imageSize.height * loc.heightMultiplier,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          clickedLocation = loc;
                        });
                      },
                      child: Container(
                        width: 45,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: loc.locked
                              ? Colors.black.withOpacity(0.5)
                              : Colors.green.withOpacity(0.8),
                        ),
                        child: Text(
                          loc.abbreviation,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sansita(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: 400.ms,
                  child: clickedLocation != null
                      ? LocationView(
                          key: UniqueKey(),
                          clickedLocation!,
                          () => setState(() {
                                clickedLocation = null;
                              }))
                      : const SizedBox.shrink(),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class LocationButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Function() onPressed;
  const LocationButton(this.text, this.icon, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      height: 100,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          children: [Text(text), const Spacer(), Icon(icon)],
        ),
      ),
    );
  }
}

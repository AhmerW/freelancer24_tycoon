import 'package:flutter_bloc/flutter_bloc.dart';

class AppObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print("bloc: $bloc - event: $event");
  }
}

import 'package:vibration/vibration.dart';

void vibratePhone() async {
  if (await Vibration.hasVibrator() ?? false) {
    Vibration.vibrate(duration: 500); // Vibrate for 500 milliseconds
  }
}

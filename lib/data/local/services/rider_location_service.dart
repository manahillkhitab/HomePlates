import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class RiderLocation {
  final double lat;
  final double lng;
  final double rotation;

  RiderLocation(this.lat, this.lng, this.rotation);
}

class RiderLocationService {
  static final RiderLocationService _instance = RiderLocationService._internal();
  factory RiderLocationService() => _instance;
  RiderLocationService._internal();

  final Map<String, StreamController<RiderLocation>> _controllers = {};

  // Starting point (Chef - e.g. Lahore center)
  // Ending point (Customer - random offset)
  Stream<RiderLocation> getRiderLocation(String orderId) {
    if (_controllers.containsKey(orderId)) {
      return _controllers[orderId]!.stream;
    }

    final controller = StreamController<RiderLocation>.broadcast();
    _controllers[orderId] = controller;
    
    _startSimulation(orderId, controller);
    
    return controller.stream;
  }

  void _startSimulation(String orderId, StreamController<RiderLocation> controller) {
    const startLat = 31.5204;
    const startLng = 74.3587;
    
    // Generate a random destination within ~2km
    final destLat = startLat + (Random().nextDouble() - 0.5) * 0.04;
    final destLng = startLng + (Random().nextDouble() - 0.5) * 0.04;

    int steps = 60; // 60 seconds of movement
    int currentStep = 0;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      if (currentStep >= steps) {
        timer.cancel();
        return;
      }

      double progress = currentStep / steps;
      double currentLat = startLat + (destLat - startLat) * progress;
      double currentLng = startLng + (destLng - startLng) * progress;
      
      // Calculate rotation (heading)
      double rotation = atan2(destLng - startLng, destLat - startLat) * 180 / pi;

      controller.add(RiderLocation(currentLat, currentLng, rotation));
      currentStep++;
    });
  }

  void stopSimulation(String orderId) {
    _controllers[orderId]?.close();
    _controllers.remove(orderId);
  }
}

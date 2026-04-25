import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/local/services/rider_location_service.dart';
import '../utils/app_theme.dart';

class LiveMapWidget extends StatefulWidget {
  final String orderId;
  const LiveMapWidget({super.key, required this.orderId});

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late Stream<RiderLocation> _locationStream;
  final MapController _mapController = MapController();

  // Fixed Points (Simulated for Demo)
  // Kitchen (Lahore Center-ish)
  static const LatLng _kitchenLocation = LatLng(31.5204, 74.3587);
  // Home (Simulated destination 2km away)
  static const LatLng _homeLocation = LatLng(31.5204 + 0.015, 74.3587 - 0.005);

  @override
  void initState() {
    super.initState();
    _locationStream = RiderLocationService().getRiderLocation(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _kitchenLocation,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),

                // Static Markers (Kitchen & Home)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _kitchenLocation,
                      width: 80,
                      height: 80,
                      child: const _MapLabel(
                        icon: Icons.storefront_rounded,
                        label: 'KITCHEN',
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    Marker(
                      point: _homeLocation,
                      width: 80,
                      height: 80,
                      child: const _MapLabel(
                        icon: Icons.home_rounded,
                        label: 'YOU',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                // Live Rider Marker
                StreamBuilder<RiderLocation>(
                  stream: _locationStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final loc = snapshot.data!;
                    final latLng = LatLng(loc.lat, loc.lng);

                    // Auto-center map on rider initially or periodically could be added here
                    // But for now purely passive tracking to avoid jarring movements while user pans

                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 60,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.warmCharcoal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(top: 2),
                                child: const Text(
                                  'RIDER',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            // Overlay gradient for better integration
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MapLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

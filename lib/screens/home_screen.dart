import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../data/local/sample_model.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Home',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2933), // Warm Charcoal
                ),
              ),
              TextSpan(
                text: 'Plates',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF4B740), // Muted Saffron
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _controller.clearAllSamples();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared!')),
                );
              }
            },
            tooltip: 'Clear all data',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<SampleModel>>(
        valueListenable: _controller.samplesNotifier,
        builder: (context, samples, child) {
          if (samples.isEmpty) {
            // Empty state
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: AppTheme.mutedSaffron.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data yet',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add sample data',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Display list of samples
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: samples.length,
            itemBuilder: (context, index) {
              final sample = samples[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.mutedSaffron,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    sample.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(sample.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.lightText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(sample.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.lightText,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            sample.isSynced
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            size: 14,
                            color: sample.isSynced
                                ? Colors.green
                                : AppTheme.lightText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sample.isSynced ? 'Synced' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: sample.isSynced
                                  ? Colors.green
                                  : AppTheme.lightText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _controller.deleteSample(sample.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _controller.addSample();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sample data added!')),
            );
          }
        },
        backgroundColor: AppTheme.mutedSaffron,
        icon: const Icon(Icons.add),
        label: const Text('Add Sample Data'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

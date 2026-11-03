import 'package:flutter/material.dart';

import '../weather.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Weather? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await fetchKigaliWeather();
      setState(() {
        weather = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      child = Row(
        children: [
          const Icon(Icons.wifi_off),
          const SizedBox(width: 12),
          Expanded(child: Text(error!)),
          FilledButton(onPressed: retry, child: const Text('Retry')),
        ],
      );
    } else {
      final w = weather!;
      child = Row(
        children: [
          const Icon(Icons.cloud),
          const SizedBox(width: 12),
          Text('Kigali today: ${w.temperature.round()}°C, ${describe(w.code)}'),
        ],
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
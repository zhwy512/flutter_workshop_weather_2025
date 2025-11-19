import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favourite_provider.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final WeatherService _service = WeatherService();
  final Map<String, Weather?> _weatherCache = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadAllWeather();
  }

  void _loadAllWeather() {
    final provider = Provider.of<FavouriteProvider>(context, listen: false);
    for (var city in provider.cities) {
      _loadWeather(city);
    }
  }

  void _loadWeather(String city) {
    if (_weatherCache.containsKey(city)) return;

    setState(() {
      _loadingStates[city] = true;
    });

    _service
        .getWeather(city)
        .then((weather) {
          if (mounted) {
            setState(() {
              _weatherCache[city] = weather;
              _loadingStates[city] = false;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _loadingStates[city] = false;
            });
          }
        });
  }

  Color _getWeatherColor(double temp) {
    if (temp < 0) return Colors.indigo;
    if (temp < 10) return Colors.blue;
    if (temp < 20) return Colors.cyan;
    if (temp < 30) return Colors.orange;
    return Colors.deepOrange;
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain')) return Icons.beach_access;
    if (desc.contains('cloud')) return Icons.cloud;
    if (desc.contains('clear')) return Icons.wb_sunny;
    if (desc.contains('snow')) return Icons.ac_unit;
    if (desc.contains('thunder')) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouriteProvider>(
      builder: (context, provider, child) {
        final cities = provider.cities;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Favourite Cities',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (cities.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Favourites?'),
                        content: const Text(
                          'This will remove all cities from your favourites.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              for (var city in [...cities]) {
                                provider.toggle(city);
                              }
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All favourites cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Clear All',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Clear all favourites',
                ),
            ],
          ),
          body: cities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No favourites yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add cities to see them here',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _weatherCache.clear();
                    _loadAllWeather();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final weather = _weatherCache[city];
                      final isLoading = _loadingStates[city] ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(city),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          onDismissed: (direction) {
                            provider.toggle(city);
                            _weatherCache.remove(city);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$city removed from favourites'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    provider.toggle(city);
                                    _loadWeather(city);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                Navigator.pop(context);
                                // Optionally navigate back with city data
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Weather icon
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: weather != null
                                            ? _getWeatherColor(
                                                weather.temp,
                                              ).withOpacity(0.2)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: isLoading
                                          ? const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : weather != null
                                          ? Icon(
                                              _getWeatherIcon(
                                                weather.description,
                                              ),
                                              size: 32,
                                              color: _getWeatherColor(
                                                weather.temp,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.location_city,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    const SizedBox(width: 16),

                                    // City name and weather info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            city,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (weather != null)
                                            Text(
                                              weather.description[0]
                                                      .toUpperCase() +
                                                  weather.description.substring(
                                                    1,
                                                  ),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            )
                                          else if (!isLoading)
                                            Text(
                                              'Tap to refresh',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Temperature
                                    if (weather != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getWeatherColor(
                                            weather.temp,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${weather.temp.toStringAsFixed(1)}°C',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getWeatherColor(
                                              weather.temp,
                                            ),
                                          ),
                                        ),
                                      ),

                                    const SizedBox(width: 8),

                                    // Delete button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Remove Favourite?',
                                            ),
                                            content: Text(
                                              'Remove $city from favourites?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  provider.toggle(city);
                                                  _weatherCache.remove(city);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '$city removed from favourites',
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'Remove',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Remove from favourites',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

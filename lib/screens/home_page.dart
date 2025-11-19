import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import '../providers/favourite_provider.dart';
import '../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  Weather? _weather;
  bool _loading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final WeatherService _service = WeatherService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchWeather() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    _service
        .getWeather(_controller.text.trim())
        .then((weather) {
          setState(() {
            _weather = weather;
            _loading = false;
          });
          _animationController.forward(from: 0);
        })
        .catchError((e) {
          setState(() {
            _error = e.toString();
            _loading = false;
            _weather = null;
          });
        });
  }

  Color _getWeatherColor() {
    if (_weather == null) return Colors.blue;

    final temp = _weather!.temp;
    if (temp < 0) return Colors.indigo;
    if (temp < 10) return Colors.blue;
    if (temp < 20) return Colors.cyan;
    if (temp < 30) return Colors.orange;
    return Colors.deepOrange;
  }

  IconData _getWeatherIcon() {
    if (_weather == null) return Icons.wb_sunny;

    final description = _weather!.description.toLowerCase();
    if (description.contains('rain')) return Icons.beach_access;
    if (description.contains('cloud')) return Icons.cloud;
    if (description.contains('clear')) return Icons.wb_sunny;
    if (description.contains('snow')) return Icons.ac_unit;
    if (description.contains('thunder')) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    final favouriteProvider = Provider.of<FavouriteProvider>(context);
    final isFavourite =
        _weather != null && favouriteProvider.cities.contains(_weather!.city);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.pushNamed(context, '/favourites'),
            tooltip: 'Favourites',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getWeatherColor().withOpacity(0.7),
              _getWeatherColor().withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Search Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Search city',
                          hintText: 'e.g., London, Tokyo, New York',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.location_city),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _fetchWeather,
                            tooltip: 'Search',
                          ),
                        ),
                        onSubmitted: (_) => _fetchWeather(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Quick access to favourites
                  if (favouriteProvider.cities.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Access',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favouriteProvider.cities.length,
                        itemBuilder: (context, index) {
                          final city = favouriteProvider.cities[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: const Icon(Icons.location_on, size: 16),
                              label: Text(city),
                              onPressed: () {
                                _controller.text = city;
                                _fetchWeather();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // Loading indicator
                  if (_loading)
                    Column(
                      children: [
                        const SizedBox(height: 50),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getWeatherColor(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Fetching weather data...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),

                  // Error message
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Weather information
                  if (_weather != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Main weather card
                          Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                children: [
                                  // City name
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, size: 28),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _weather!.city,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Weather icon
                                  Hero(
                                    tag: 'weather_icon',
                                    child: Icon(
                                      _getWeatherIcon(),
                                      size: 100,
                                      color: _getWeatherColor(),
                                    ),
                                  ),

                                  // API Weather icon overlay
                                  Image.network(
                                    'https://openweathermap.org/img/wn/${_weather!.icon}@4x.png',
                                    height: 120,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(),
                                  ),

                                  // Temperature
                                  Text(
                                    '${_weather!.temp.toStringAsFixed(1)}°C',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getWeatherColor(),
                                        ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Description
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getWeatherColor().withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _weather!.description[0].toUpperCase() +
                                          _weather!.description.substring(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Favourite button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: Icon(
                                        isFavourite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      label: Text(
                                        isFavourite
                                            ? 'Remove from Favourites'
                                            : 'Add to Favourites',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFavourite
                                            ? Colors.red
                                            : _getWeatherColor(),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 5,
                                      ),
                                      onPressed: () {
                                        favouriteProvider.toggle(
                                          _weather!.city,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFavourite
                                                  ? '${_weather!.city} removed from favourites'
                                                  : '${_weather!.city} added to favourites',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Initial state
                  if (!_loading && _weather == null && _error == null)
                    Column(
                      children: [
                        const SizedBox(height: 50),
                        Icon(
                          Icons.cloud_outlined,
                          size: 100,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Search for a city to see weather',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

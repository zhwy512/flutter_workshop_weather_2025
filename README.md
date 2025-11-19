# flutter_workshop_weather_2025

## 1. **Khởi tạo MultiProvider + ThemeSwitcher**

`lib\main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/favourite_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_page.dart';
import 'screens/favourite_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Weather Favourite',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const HomePage(),
          routes: {'/favourites': (context) => const FavouritePage()},
        );
      },
    );
  }
}
```

## 2. **Tạo model và service gọi API**

`lib\models\weather.dart`:

```dart
class Weather {
  final String city;
  final double temp;
  final String description;
  final String icon;

  Weather({
    required this.city,
    required this.temp,
    required this.description,
    required this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['name'] ?? "Unknown",
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? "",
      icon: json['weather'][0]['icon'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "city": city,
      "temp": temp,
      "description": description,
      "icon": icon,
    };
  }
}
```

`lib\services\weather_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String apiKey = "2126c39435e61509ca1ef213f1a66088";
  static const String baseUrl =
      "https://api.openweathermap.org/data/2.5/weather";

  Future<Weather> getWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=vi'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Weather.fromJson(json);
    } else {
      throw Exception('City not found');
    }
  }
}
```

## 3. **Tạo Provider để quản lý danh sách favourite và theme**

`lib\providers\theme_provider.dart`:

```dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
```

`lib\providers\favourite_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteProvider extends ChangeNotifier {
  List<String> _cities = [];

  List<String> get cities => _cities;

  FavouriteProvider() {
    _load();
  }

  void toggle(String city) {
    if (_cities.contains(city)) {
      _cities.remove(city);
    } else {
      _cities.add(city);
    }
    _save();
    notifyListeners();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _cities = prefs.getStringList('favourites') ?? [];
    notifyListeners();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favourites', _cities);
  }
}
```

## 4. **Xây dựng các màn hình**

`lib\screens\home_page.dart`:

```dart
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
```

`lib\screens\favourite_page.dart`:

```dart
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

```

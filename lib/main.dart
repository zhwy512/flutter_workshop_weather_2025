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
          debugShowCheckedModeBanner: false,
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

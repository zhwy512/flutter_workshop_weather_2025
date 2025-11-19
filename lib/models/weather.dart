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

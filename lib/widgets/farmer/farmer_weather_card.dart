import 'package:flutter/material.dart';

String _formatCurrentDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

List<String> _forecastDayLabels(DateTime today) {
  const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return [
    'Today',
    shortDays[today.add(const Duration(days: 1)).weekday - 1],
    shortDays[today.add(const Duration(days: 2)).weekday - 1],
  ];
}

class FarmerWeatherCard extends StatelessWidget {
  final String greetingName;
  final String seasonalAlert;

  const FarmerWeatherCard({
    super.key,
    required this.greetingName,
    this.seasonalAlert =
        'Seasonal Alert: Meher sowing window: 10 days remaining.',
  });

  @override
  Widget build(BuildContext context) {
    final dayLabels = _forecastDayLabels(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88E5), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $greetingName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrentDate(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ForecastDay(
                  label: dayLabels[0],
                  temp: '24°C',
                  detail: 'Sunny',
                  icon: Icons.wb_sunny_rounded,
                ),
              ),
              Expanded(
                child: _ForecastDay(
                  label: dayLabels[1],
                  temp: '25°C',
                  detail: 'Rain 20%',
                  icon: Icons.grain_rounded,
                ),
              ),
              Expanded(
                child: _ForecastDay(
                  label: dayLabels[2],
                  temp: '23°C',
                  detail: 'Sunny',
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              seasonalAlert,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDay extends StatelessWidget {
  final String label;
  final String temp;
  final String detail;
  final IconData icon;

  const _ForecastDay({
    required this.label,
    required this.temp,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 4),
        Text(
          temp,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        Text(
          detail,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

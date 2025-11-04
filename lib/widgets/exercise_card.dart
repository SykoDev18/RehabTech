
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExerciseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final Color iconColor;

  const ExerciseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.50),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor,
                radius: 20,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                   Row(
                    children: [
                      SvgPicture.asset(
                        'assets/clock.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(Color(0xFF4B5563), BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        duration,
                        style: const TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

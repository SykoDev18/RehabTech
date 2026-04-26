import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Static slide content shown on the onboarding flow. Lives in code (not
/// Firestore) — adding/editing slides requires an app release.
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
}

const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    title: 'Bienvenido a RehabTech',
    subtitle:
        'Una plataforma diseñada para acompañarte en tu rehabilitación, '
        'con seguimiento, ejercicios guiados y recordatorios personalizados.',
    icon: LucideIcons.heartPulse,
    accentColor: Color(0xFF2563EB),
  ),
  OnboardingSlide(
    title: 'Tu terapeuta, siempre contigo',
    subtitle:
        'Mantén una conexión cercana con tu terapeuta, recibe rutinas '
        'personalizadas y comparte tu progreso desde la app.',
    icon: LucideIcons.userCheck,
    accentColor: Color(0xFF10B981),
  ),
  OnboardingSlide(
    title: 'Nora, tu asistente de IA',
    subtitle:
        'Nora te orienta durante tus ejercicios, responde tus dudas y te '
        'motiva a alcanzar tus metas, paso a paso.',
    icon: LucideIcons.sparkles,
    accentColor: Color(0xFF8B5CF6),
  ),
];

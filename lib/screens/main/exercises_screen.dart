import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myapp/widgets/exercise_card.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ejercicios',
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF111827),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: SvgPicture.asset('assets/user.svg'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.40),
            hintText: 'Buscar ejercicio...',
            hintStyle: const TextStyle(color: Color(0xFF4B5563)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF4B5563)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              Chip(label: Text('Rodilla')),
              SizedBox(width: 8),
              Chip(label: Text('Hombro')),
              SizedBox(width: 8),
              Chip(label: Text('Fuerza')),
               SizedBox(width: 8),
              Chip(label: Text('Cardio')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Column(
          children: [
            ExerciseCard(
              title: 'Flexión de Rodilla',
              description: 'Fortalece los cuádriceps.',
              duration: '30 min',
              iconPath: 'assets/activity.svg',
              imagePath: 'assets/exercices/Flexión de Rodilla.jpg',
              iconColor: Colors.blue,
            ),
            SizedBox(height: 16),
            ExerciseCard(
              title: 'Extensión de Cadera',
              description: 'Ideal para glúteos y femorales.',
              duration: '15 min',
              iconPath: 'assets/zap.svg',
              imagePath: 'assets/exercices/Extensión de Cadera.jpg',
              iconColor: Colors.purple,
            ),
            SizedBox(height: 16),
            ExerciseCard(
              title: 'Sentadilla Asistida',
              description: 'Perfecta para principiantes.',
              duration: '20 min',
              iconPath: 'assets/dumbbell.svg',
              imagePath: 'assets/exercices/Sentadilla Asistida.jpg',
              iconColor: Colors.green,
            ),
            SizedBox(height: 16),
            ExerciseCard(
              title: 'Estiramiento de Cuádriceps',
              description: 'Mejora la flexibilidad.',
              duration: '10 min',
              iconPath: 'assets/heart.svg',
              imagePath: 'assets/exercices/Estiramiento de Cuádriceps.jpg',
              iconColor: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}

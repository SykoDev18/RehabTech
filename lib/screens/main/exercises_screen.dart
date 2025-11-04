
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myapp/widgets/exercise_card.dart';

class ExercisesScreen extends StatefulWidget {
  final VoidCallback onProfileTapped;

  const ExercisesScreen({super.key, required this.onProfileTapped});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Rodilla';

  final List<Map<String, dynamic>> _allExercises = [
    {
      'title': 'Flexión de Rodilla',
      'subtitle': 'Fortalece los cuádriceps.',
      'duration': '30 min',
      'iconColor': const Color(0xFF2563EB),
      'category': 'Rodilla',
    },
    {
      'title': 'Extensión de Cadera',
      'subtitle': 'Fortalece los glúteos.',
      'duration': '15 min',
      'iconColor': const Color(0xFF9333EA),
      'category': 'Cadera',
    },
    {
      'title': 'Sentadilla Asistida',
      'subtitle': 'Fortalece las piernas.',
      'duration': '20 min',
      'iconColor': const Color(0xFF16A34A),
      'category': 'Fuerza',
    },
    {
      'title': 'Estiramiento de Cuádriceps',
      'subtitle': 'Mejora la flexibilidad.',
      'duration': '10 min',
      'iconColor': const Color(0xFFEA580C),
      'category': 'Flexibilidad',
    },
  ];

  List<Map<String, dynamic>> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _filterExercises();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterExercises();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterExercises();
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final titleMatches = exercise['title']!.toLowerCase().contains(query);
        final categoryMatches = _selectedFilter == 'Todos' || exercise['category'] == _selectedFilter;
        return titleMatches && categoryMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = ['Rodilla', 'Hombro', 'Fuerza', 'Cardio'];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
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
                GestureDetector(
                  onTap: widget.onProfileTapped,
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_outline,
                      color: Color(0xFF111827),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          sliver: SliverToBoxAdapter(
            child: TextFormField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.50),
                hintText: 'Buscar ejercicio...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SvgPicture.asset(
                    'assets/search.svg',
                    colorFilter: const ColorFilter.mode(Color(0xFF6B7280), BlendMode.srcIn),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onFilterChanged(filter);
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.5),
                    selectedColor: const Color(0xFFE0E7FF), // indigo-100
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF3730A3) : const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide.none,
                    ),
                    pressElevation: 0,
                  ),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = _filteredExercises[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ExerciseCard(
                    title: exercise['title']!,
                    subtitle: exercise['subtitle']!,
                    duration: exercise['duration']!,
                    iconColor: exercise['iconColor']!,
                  ),
                );
              },
              childCount: _filteredExercises.length,
            ),
          ),
        ),
      ],
    );
  }
}

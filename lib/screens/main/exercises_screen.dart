import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehabtech/models/exercise.dart';
import 'package:rehabtech/widgets/exercise_card.dart';
import 'package:rehabtech/screens/main/exercise_detail_screen.dart';

class ExercisesScreen extends StatefulWidget {
  final VoidCallback onProfileTapped;

  const ExercisesScreen({super.key, required this.onProfileTapped});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  List<Exercise> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _filteredExercises = allExercises;
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
      _filteredExercises = allExercises.where((exercise) {
        final titleMatches = exercise.title.toLowerCase().contains(query);
        final descriptionMatches = exercise.description.toLowerCase().contains(query);
        final musclesMatches = exercise.targetMuscles.toLowerCase().contains(query);
        final textMatches = titleMatches || descriptionMatches || musclesMatches;
        
        final categoryMatches = _selectedFilter == 'Todos' || 
            exercise.categories.contains(_selectedFilter);
        
        return textMatches && categoryMatches;
      }).toList();
    });
  }

  void _openExerciseDetail(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Explorar Ejercicios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onProfileTapped,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.user,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Barra de búsqueda
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextFormField(
                  controller: _searchController,
                  style: const TextStyle(color: Color(0xFF111827), fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.60),
                    hintText: 'Búsqueda por nombre, parte del cuerpo',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Icon(
                        LucideIcons.search,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x, color: const Color(0xFF9CA3AF), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterExercises();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Filtros horizontales
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: exerciseCategories.length,
              itemBuilder: (context, index) {
                final filter = exerciseCategories[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _onFilterChanged(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
                              )
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Contador de resultados
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${_filteredExercises.length} ejercicio${_filteredExercises.length != 1 ? 's' : ''} encontrado${_filteredExercises.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Lista de ejercicios
        _filteredExercises.isEmpty
            ? SliverPadding(
                padding: const EdgeInsets.all(48),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 64,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron ejercicios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Intenta con otros términos de búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = _filteredExercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          title: exercise.title,
                          duration: exercise.duration,
                          icon: exercise.icon,
                          iconColor: exercise.iconColor,
                          iconBgColor: exercise.iconBgColor,
                          onTap: () => _openExerciseDetail(exercise),
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

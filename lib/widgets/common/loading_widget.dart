import 'package:flutter/material.dart';

/// Widget de carga reutilizable
class AppLoadingWidget extends StatelessWidget {
  final String? message;
  final Color color;
  final double size;

  const AppLoadingWidget({
    super.key,
    this.message,
    this.color = const Color(0xFF6366F1),
    this.size = 40,
  });

  /// Loading para pantalla completa
  factory AppLoadingWidget.fullScreen({String? message}) {
    return AppLoadingWidget(
      message: message ?? 'Cargando...',
      size: 48,
    );
  }

  /// Loading compacto para botones o inline
  factory AppLoadingWidget.compact({Color? color}) {
    return AppLoadingWidget(
      size: 20,
      color: color ?? Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 30 ? 4 : 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer/Skeleton para loading de contenido
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  /// Shimmer circular (para avatares)
  factory ShimmerLoading.circle({required double size}) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Shimmer para texto
  factory ShimmerLoading.text({double width = 100, double height = 14}) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }

  /// Shimmer para tarjetas
  factory ShimmerLoading.card({double height = 120}) {
    return ShimmerLoading(
      width: double.infinity,
      height: height,
      borderRadius: 12,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lista de shimmer para loading de listas
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => ShimmerLoading.card(height: itemHeight),
    );
  }
}

/// Overlay de carga para bloquear interacción
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: AppLoadingWidget.fullScreen(message: message),
          ),
      ],
    );
  }
}

/// Coarse confidence bucket for the most recent pose detection.
/// Drives "Detección: Alta/Media/Baja/Perdida" pill in the overlay.
enum PoseDetectionQuality {
  /// Avg confidence > 0.8.
  excellent,

  /// Avg confidence 0.6-0.8.
  good,

  /// Avg confidence < 0.6.
  poor,

  /// No pose detected for > 2 seconds.
  lost,
}

extension PoseDetectionQualityX on PoseDetectionQuality {
  String get label {
    switch (this) {
      case PoseDetectionQuality.excellent:
        return 'Detección: Alta';
      case PoseDetectionQuality.good:
        return 'Detección: Media';
      case PoseDetectionQuality.poor:
        return 'Detección: Baja';
      case PoseDetectionQuality.lost:
        return 'Detección: Perdida';
    }
  }

  static PoseDetectionQuality fromConfidence(
    double avgConfidence, {
    bool lost = false,
  }) {
    if (lost) return PoseDetectionQuality.lost;
    if (avgConfidence > 0.8) return PoseDetectionQuality.excellent;
    if (avgConfidence >= 0.6) return PoseDetectionQuality.good;
    return PoseDetectionQuality.poor;
  }
}

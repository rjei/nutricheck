import 'package:flutter/material.dart';

import '../data/models/risk_level.dart';

/// Gaya visual indikator risiko (hijau / kuning / merah).
///
/// Dipisah dari model agar `RiskLevel` tetap Dart murni (aman untuk
/// serialisasi & dipakai ulang di backend/Cloud Functions jika perlu).
extension RiskLevelStyle on RiskLevel {
  Color get color => switch (this) {
        RiskLevel.aman => const Color(0xFF0F5132),
        RiskLevel.waspada => const Color(0xFFD97706),
        RiskLevel.bahaya => const Color(0xFFB91C1C),
      };

  Color get backgroundColor => switch (this) {
        RiskLevel.aman => const Color(0xFFD1E7DD),
        RiskLevel.waspada => const Color(0xFFFEF3C7),
        RiskLevel.bahaya => const Color(0xFFFEE2E2),
      };

  IconData get icon => switch (this) {
        RiskLevel.aman => Icons.check_circle_rounded,
        RiskLevel.waspada => Icons.warning_amber_rounded,
        RiskLevel.bahaya => Icons.dangerous_rounded,
      };
}

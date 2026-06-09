// lib/core/constants/app_constants.dart
class AppConstants {
  // Supabase - GANTI dengan credentials Anda
  static const String supabaseUrl = 'https://ytefujwkonkiabezqkix.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0ZWZ1andrb25raWFiZXpxa2l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5NzE4NjAsImV4cCI6MjA5NjU0Nzg2MH0.EnUR4qQMj_dW69fdYr9dcRdWs9LOnv12PjILrz1swRw';

  // Storage
  static const String bucketFoto = 'ekspedisi-foto';

  // App Info
  static const String appName = 'Buku Ekspedisi';
  static const String appVersion = '1.0.0';

  // Status
  static const Map<String, StatusInfo> statusMap = {
    'menunggu': StatusInfo(
      label: 'Menunggu Diambil',
      color: 0xFFFF9800,
      icon: '⏳',
    ),
    'diambil_security': StatusInfo(
      label: 'Diambil Security',
      color: 0xFF2196F3,
      icon: '🛡️',
    ),
    'dalam_pengiriman': StatusInfo(
      label: 'Dalam Pengiriman',
      color: 0xFF9C27B0,
      icon: '🚶',
    ),
    'diterima': StatusInfo(
      label: 'Sudah Diterima',
      color: 0xFF4CAF50,
      icon: '✅',
    ),
    'dikembalikan': StatusInfo(
      label: 'Dikembalikan',
      color: 0xFFF44336,
      icon: '↩️',
    ),
  };

  // Satuan barang
  static const List<String> satuanList = [
    'pcs', 'buah', 'lembar', 'bundel', 'pak', 'box', 'kg', 'gram', 'liter', 'set', 'unit',
  ];
}

class StatusInfo {
  final String label;
  final int color;
  final String icon;
  const StatusInfo({required this.label, required this.color, required this.icon});
}

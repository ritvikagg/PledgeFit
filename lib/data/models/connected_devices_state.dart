/// Persisted health / step-sync preferences for the device.
class ConnectedDevicesState {
  /// User completed a successful connect + at least one intended sync.
  final bool stepSyncConnected;

  /// Last time we finished reading steps from Apple Health / Health Connect.
  final DateTime? lastSyncedAt;

  /// Last known authorization outcome. On iOS, READ may remain indeterminate.
  final bool? permissionsGranted;

  /// Last failed sync outcome name ([StepSyncOutcome.name]); cleared on success.
  /// Does not clear [lastSyncedAt] — last good sync time is preserved for UI.
  final String? lastSyncErrorCode;

  const ConnectedDevicesState({
    required this.stepSyncConnected,
    this.lastSyncedAt,
    this.permissionsGranted,
    this.lastSyncErrorCode,
  });

  static const none = ConnectedDevicesState(stepSyncConnected: false);

  ConnectedDevicesState copyWith({
    bool? stepSyncConnected,
    DateTime? lastSyncedAt,
    bool? permissionsGranted,
    String? lastSyncErrorCode,
    bool clearLastSyncedAt = false,
    bool clearLastSyncError = false,
  }) {
    return ConnectedDevicesState(
      stepSyncConnected: stepSyncConnected ?? this.stepSyncConnected,
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      lastSyncErrorCode: clearLastSyncError
          ? null
          : (lastSyncErrorCode ?? this.lastSyncErrorCode),
    );
  }

  Map<String, dynamic> toJson() => {
        'stepSyncConnected': stepSyncConnected,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'permissionsGranted': permissionsGranted,
        'lastSyncErrorCode': lastSyncErrorCode,
      };

  static ConnectedDevicesState fromJson(Map<String, dynamic> json) {
    if (json.containsKey('stepSyncConnected')) {
      return ConnectedDevicesState(
        stepSyncConnected: json['stepSyncConnected'] as bool? ?? false,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.tryParse(json['lastSyncedAt'] as String)
            : null,
        permissionsGranted: json['permissionsGranted'] as bool?,
        lastSyncErrorCode: json['lastSyncErrorCode'] as String?,
      );
    }
    // Legacy mock keys — do not auto-connect; require real Health setup.
    return ConnectedDevicesState.none;
  }
}

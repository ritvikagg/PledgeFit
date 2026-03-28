/// Mock connected step sources — wire to [HealthStepSyncService] implementations later.
class ConnectedDevicesState {
  final bool appleHealth;
  final bool googleFit;
  final bool fitbit;

  const ConnectedDevicesState({
    required this.appleHealth,
    required this.googleFit,
    required this.fitbit,
  });

  static const ConnectedDevicesState none = ConnectedDevicesState(
    appleHealth: false,
    googleFit: false,
    fitbit: false,
  );

  ConnectedDevicesState copyWith({
    bool? appleHealth,
    bool? googleFit,
    bool? fitbit,
  }) {
    return ConnectedDevicesState(
      appleHealth: appleHealth ?? this.appleHealth,
      googleFit: googleFit ?? this.googleFit,
      fitbit: fitbit ?? this.fitbit,
    );
  }

  Map<String, dynamic> toJson() => {
        'appleHealth': appleHealth,
        'googleFit': googleFit,
        'fitbit': fitbit,
      };

  static ConnectedDevicesState fromJson(Map<String, dynamic> json) {
    return ConnectedDevicesState(
      appleHealth: json['appleHealth'] as bool? ?? false,
      googleFit: json['googleFit'] as bool? ?? false,
      fitbit: json['fitbit'] as bool? ?? false,
    );
  }
}

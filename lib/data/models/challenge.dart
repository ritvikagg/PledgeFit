import '../../core/date_utils.dart';
import '../../core/money.dart';
import '../../core/id_generator.dart';
import 'daily_entry.dart';

enum ChallengeStatus {
  active,
  success,
  failed,
}

class Challenge {
  final String id;
  final DateTime createdAt;
  final DateTime startDate; // date-only
  final DateTime endDate; // date-only
  final int durationDays;
  final int dailyStepGoal;
  final int totalStepGoal;
  final Money depositPerDay;
  final Money totalDeposit;
  final ChallengeStatus status;
  final int totalStepsAccumulated;
  final int totalPenaltyAmountCents;
  final int refundableRemainingAmountCents;
  final int returnedAmountCents;
  final int platformKeptAmountCents;
  final List<DailyEntry> dailyEntries;

  const Challenge({
    required this.id,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.dailyStepGoal,
    required this.totalStepGoal,
    required this.depositPerDay,
    required this.totalDeposit,
    required this.status,
    required this.totalStepsAccumulated,
    required this.totalPenaltyAmountCents,
    required this.refundableRemainingAmountCents,
    required this.returnedAmountCents,
    required this.platformKeptAmountCents,
    required this.dailyEntries,
  });

  Money get totalPenaltyAmount => Money(totalPenaltyAmountCents);
  Money get refundableRemainingAmount => Money(refundableRemainingAmountCents);
  Money get returnedAmount => Money(returnedAmountCents);
  Money get platformKeptAmount => Money(platformKeptAmountCents);

  Challenge copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    int? dailyStepGoal,
    int? totalStepGoal,
    Money? depositPerDay,
    Money? totalDeposit,
    ChallengeStatus? status,
    int? totalStepsAccumulated,
    int? totalPenaltyAmountCents,
    int? refundableRemainingAmountCents,
    int? returnedAmountCents,
    int? platformKeptAmountCents,
    List<DailyEntry>? dailyEntries,
  }) {
    return Challenge(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      totalStepGoal: totalStepGoal ?? this.totalStepGoal,
      depositPerDay: depositPerDay ?? this.depositPerDay,
      totalDeposit: totalDeposit ?? this.totalDeposit,
      status: status ?? this.status,
      totalStepsAccumulated:
          totalStepsAccumulated ?? this.totalStepsAccumulated,
      totalPenaltyAmountCents:
          totalPenaltyAmountCents ?? this.totalPenaltyAmountCents,
      refundableRemainingAmountCents:
          refundableRemainingAmountCents ?? this.refundableRemainingAmountCents,
      returnedAmountCents: returnedAmountCents ?? this.returnedAmountCents,
      platformKeptAmountCents:
          platformKeptAmountCents ?? this.platformKeptAmountCents,
      dailyEntries: dailyEntries ?? this.dailyEntries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'durationDays': durationDays,
        'dailyStepGoal': dailyStepGoal,
        'totalStepGoal': totalStepGoal,
        'depositPerDay': depositPerDay.toJson(),
        'totalDeposit': totalDeposit.toJson(),
        'status': status.name,
        'totalStepsAccumulated': totalStepsAccumulated,
        'totalPenaltyAmountCents': totalPenaltyAmountCents,
        'refundableRemainingAmountCents': refundableRemainingAmountCents,
        'returnedAmountCents': returnedAmountCents,
        'platformKeptAmountCents': platformKeptAmountCents,
        'dailyEntries': dailyEntries.map((e) => e.toJson()).toList(),
      };

  static Challenge fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate:
          MvpDateUtils.dateOnly(DateTime.parse(json['startDate'] as String)),
      endDate: MvpDateUtils.dateOnly(DateTime.parse(json['endDate'] as String)),
      durationDays: json['durationDays'] as int,
      dailyStepGoal: json['dailyStepGoal'] as int,
      totalStepGoal: json['totalStepGoal'] as int,
      depositPerDay: Money.fromJson(
        json['depositPerDay'] as Map<String, dynamic>,
      ),
      totalDeposit: Money.fromJson(
        json['totalDeposit'] as Map<String, dynamic>,
      ),
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      totalStepsAccumulated: json['totalStepsAccumulated'] as int,
      totalPenaltyAmountCents: json['totalPenaltyAmountCents'] as int,
      refundableRemainingAmountCents:
          json['refundableRemainingAmountCents'] as int,
      returnedAmountCents: json['returnedAmountCents'] as int,
      platformKeptAmountCents: json['platformKeptAmountCents'] as int,
      dailyEntries: (json['dailyEntries'] as List<dynamic>)
          .map((e) => DailyEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Challenge buildNew({
    required DateTime now,
    required int durationDays,
    required int depositPerDayDollars,
    required int dailyStepGoal,
    required int totalStepGoal,
  }) {
    final startDate = MvpDateUtils.dateOnly(now);
    final endDate = MvpDateUtils.dateOnly(
      MvpDateUtils.addDays(startDate, durationDays - 1),
    );
    final id = generateId(prefix: 'challenge');
    final depositPerDay = Money(depositPerDayDollars * 100);
    final totalDeposit = Money(durationDays * depositPerDayDollars * 100);
    final dailyEntries = <DailyEntry>[];
    for (var i = 0; i < durationDays; i++) {
      final date = MvpDateUtils.addDays(startDate, i);
      final isToday = MvpDateUtils.isSameDate(date, startDate);
      dailyEntries.add(
        DailyEntry(
          date: date,
          steps: 0,
          hitDailyGoal: false,
          depositAllocatedForDayDollars: depositPerDayDollars,
          dailyPenaltyAmountCents: 0,
          editable: isToday,
          evaluationState: DailyEntryEvaluationState.pending,
          stepsEntered: false,
        ),
      );
    }

    return Challenge(
      id: id,
      createdAt: now,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      dailyStepGoal: dailyStepGoal,
      totalStepGoal: totalStepGoal,
      depositPerDay: depositPerDay,
      totalDeposit: totalDeposit,
      status: ChallengeStatus.active,
      totalStepsAccumulated: 0,
      totalPenaltyAmountCents: 0,
      refundableRemainingAmountCents: totalDeposit.cents,
      returnedAmountCents: 0,
      platformKeptAmountCents: 0,
      dailyEntries: dailyEntries,
    );
  }
}


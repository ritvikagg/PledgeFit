import '../../core/money.dart';
import '../../core/date_utils.dart';

enum DailyEntryEvaluationState {
  pending, // Not yet evaluated (future days, or today's steps not synced yet).
  evaluated, // We have enough info to compute daily hit + penalty.
}

class DailyEntry {
  final DateTime date; // date-only
  final int steps;
  final bool hitDailyGoal;
  /// Step goal that applied when this day was evaluated (supports mid-challenge increases).
  final int stepGoalForDay;
  final int depositAllocatedForDayDollars;
  final int dailyPenaltyAmountCents;
  final bool editable;
  final DailyEntryEvaluationState evaluationState;
  final bool stepsEntered; // Used to decide when today's entry becomes evaluable.

  const DailyEntry({
    required this.date,
    required this.steps,
    required this.hitDailyGoal,
    required this.stepGoalForDay,
    required this.depositAllocatedForDayDollars,
    required this.dailyPenaltyAmountCents,
    required this.editable,
    required this.evaluationState,
    required this.stepsEntered,
  });

  Money get depositAllocatedForDay => Money(depositAllocatedForDayDollars * 100);
  Money get dailyPenaltyAmount => Money(dailyPenaltyAmountCents);

  DailyEntry copyWith({
    DateTime? date,
    int? steps,
    bool? hitDailyGoal,
    int? stepGoalForDay,
    int? depositAllocatedForDayDollars,
    int? dailyPenaltyAmountCents,
    bool? editable,
    DailyEntryEvaluationState? evaluationState,
    bool? stepsEntered,
  }) {
    return DailyEntry(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      hitDailyGoal: hitDailyGoal ?? this.hitDailyGoal,
      stepGoalForDay: stepGoalForDay ?? this.stepGoalForDay,
      depositAllocatedForDayDollars:
          depositAllocatedForDayDollars ?? this.depositAllocatedForDayDollars,
      dailyPenaltyAmountCents:
          dailyPenaltyAmountCents ?? this.dailyPenaltyAmountCents,
      editable: editable ?? this.editable,
      evaluationState: evaluationState ?? this.evaluationState,
      stepsEntered: stepsEntered ?? this.stepsEntered,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'hitDailyGoal': hitDailyGoal,
        'stepGoalForDay': stepGoalForDay,
        'depositAllocatedForDayDollars': depositAllocatedForDayDollars,
        'dailyPenaltyAmountCents': dailyPenaltyAmountCents,
        'editable': editable,
        'evaluationState': evaluationState.name,
        'stepsEntered': stepsEntered,
      };

  static DailyEntry fromJson(Map<String, dynamic> json) {
    return DailyEntry(
      date: MvpDateUtils.dateOnly(DateTime.parse(json['date'] as String)),
      steps: json['steps'] as int,
      hitDailyGoal: json['hitDailyGoal'] as bool,
      stepGoalForDay: json['stepGoalForDay'] as int? ?? 8000,
      depositAllocatedForDayDollars:
          json['depositAllocatedForDayDollars'] as int,
      dailyPenaltyAmountCents: json['dailyPenaltyAmountCents'] as int,
      editable: json['editable'] as bool,
      evaluationState: DailyEntryEvaluationState.values.firstWhere(
        (e) => e.name == json['evaluationState'],
      ),
      stepsEntered: json['stepsEntered'] as bool,
    );
  }
}


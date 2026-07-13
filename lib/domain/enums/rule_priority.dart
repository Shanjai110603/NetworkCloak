/// Priority hierarchy for rule evaluation.
/// Lower integer = higher priority (Priority 1 wins over Priority 7).
enum RulePriority {
  emergencyLockdown(1),
  temporary(2),
  session(3),
  manualApp(4),
  profile(5),
  global(6),
  defaultBehavior(7);

  const RulePriority(this.value);
  final int value;
}

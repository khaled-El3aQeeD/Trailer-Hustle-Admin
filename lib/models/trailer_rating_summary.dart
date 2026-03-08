class TrailerRatingSummary {
  final int trailerId;
  final int count;
  final double average;

  const TrailerRatingSummary({required this.trailerId, required this.count, required this.average});

  TrailerRatingSummary copyWith({int? trailerId, int? count, double? average}) =>
      TrailerRatingSummary(trailerId: trailerId ?? this.trailerId, count: count ?? this.count, average: average ?? this.average);

  static TrailerRatingSummary empty(int trailerId) => TrailerRatingSummary(trailerId: trailerId, count: 0, average: 0);
}

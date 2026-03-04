class ShiftCalculator {
  static double calculateTotalPay({
    required DateTime startTime,
    required DateTime endTime,
    required int breakTimeMinutes,
    required bool isHoliday,
    required double hourlyWage,
  }) {
    // 1. Total Duration
    Duration totalDuration = endTime.difference(startTime);
    int totalMinutes = totalDuration.inMinutes;

    // 2. Net Work Hours
    int netMinutes = totalMinutes - breakTimeMinutes;
    if (netMinutes < 0) netMinutes = 0;
    double netHours = netMinutes / 60.0;

    // 3. Base Pay
    double basePayRate = isHoliday ? hourlyWage * 1.5 : hourlyWage;
    double basePay = netHours * basePayRate;

    // 4. Night Shift Allowance (22:00 ~ 06:00) - 0.5x extra
    // We only add the 0.5x part here. The 1.0x is covered in Base Pay.
    // (Note: If Base Pay was 1.5x due to Holiday, Night Allowance is usually 0.5x of original base,
    // making it 2.0x total. Korean law: Holiday(1.5) + Night(0.5) = 2.0. Correct.)
    
    double nightHours = _calculateNightOverlapHours(startTime, endTime);
    
    // Safety check: Night hours cannot exceed Net Work Hours? 
    // Usually break time is deducted. If we don't know when break was,
    // strict implementation might be tricky.
    // The prompt says: "Net Work Hours: (Total Duration - BreakTimeMinutes)."
    // "Night Shift Allowance: Check overlapping hours with 22:00 ~ 06:00. Apply 0.5x extra pay for THESE hours."
    // It doesn't explicitly say to deduct break from Night Hours.
    // However, if Net Hours < Night Hours (e.g. 8h night shift, 8h break), pay should be 0.
    // Let's cap night hours to netHours just in case.
    if (nightHours > netHours) {
      nightHours = netHours; 
    }

    double nightAllowance = nightHours * hourlyWage * 0.5;

    return basePay + nightAllowance;
  }

  static double _calculateNightOverlapHours(DateTime start, DateTime end) {
    double totalOverlapMinutes = 0.0;

    // We consider night windows relative to the start date.
    // Shift is usually < 24h.
    // Potential windows:
    // 1. Night of the start day (Starts at 22:00 on start.day)
    // 2. Night of the previous day (Starts at 22:00 on start.day - 1)
    //    (Relevant if start is e.g., 01:00)
    
    // Construct Window 1: Start Date 22:00 -> Next Day 06:00
    DateTime startDayNightStart = DateTime(start.year, start.month, start.day, 22, 0);
    DateTime startDayNightEnd = startDayNightStart.add(const Duration(hours: 8)); // 06:00 next day

    // Construct Window 2: Prev Date 22:00 -> Start Date 06:00
    DateTime prevDayNightStart = startDayNightStart.subtract(const Duration(days: 1));
    DateTime prevDayNightEnd = prevDayNightStart.add(const Duration(hours: 8));

    // Construct Window 3: Next Date 22:00 -> Next Next Day 06:00
    // (In case shift is very long)
    DateTime nextDayNightStart = startDayNightStart.add(const Duration(days: 1));
    DateTime nextDayNightEnd = nextDayNightStart.add(const Duration(hours: 8));

    totalOverlapMinutes += _getOverlapMinutes(start, end, startDayNightStart, startDayNightEnd);
    totalOverlapMinutes += _getOverlapMinutes(start, end, prevDayNightStart, prevDayNightEnd);
    totalOverlapMinutes += _getOverlapMinutes(start, end, nextDayNightStart, nextDayNightEnd);

    return totalOverlapMinutes / 60.0;
  }

  static double _getOverlapMinutes(DateTime rangeStart, DateTime rangeEnd, DateTime windowStart, DateTime windowEnd) {
    // Overlap: Max(Start, WindowStart) to Min(End, WindowEnd)
    DateTime overlapStart = rangeStart.isAfter(windowStart) ? rangeStart : windowStart;
    DateTime overlapEnd = rangeEnd.isBefore(windowEnd) ? rangeEnd : windowEnd;

    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes.toDouble();
    }
    return 0.0;
  }
}

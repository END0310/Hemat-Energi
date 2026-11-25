import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';

/// Bottom sheet pemilih rentang tanggal berbasis gulir (scroll wheel)
/// dengan urutan Hari - Bulan - Tahun (tanpa ketik manual).
class ScrollDateRangePicker {
  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    int minYear = 2020,
    int? maxYear,
  }) {
    final now = DateTime.now();
    final effectiveMaxYear = maxYear ?? now.year + 1;
    final defaultRange = initialRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );

    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScrollDateRangeSheet(
        initialRange: defaultRange,
        minYear: minYear,
        maxYear: effectiveMaxYear,
      ),
    );
  }
}

class _ScrollDateRangeSheet extends StatefulWidget {
  final DateTimeRange initialRange;
  final int minYear;
  final int maxYear;

  const _ScrollDateRangeSheet({
    required this.initialRange,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_ScrollDateRangeSheet> createState() => _ScrollDateRangeSheetState();
}

class _ScrollDateRangeSheetState extends State<_ScrollDateRangeSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _editingStart = true;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  DateTime get _activeDate => _editingStart ? _startDate : _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialRange.start.year,
      widget.initialRange.start.month,
      widget.initialRange.start.day,
    );
    _endDate = DateTime(
      widget.initialRange.end.year,
      widget.initialRange.end.month,
      widget.initialRange.end.day,
    );
    _initControllersFor(_activeDate);
  }

  void _initControllersFor(DateTime d) {
    final clampedYear = d.year.clamp(widget.minYear, widget.maxYear);
    _dayController = FixedExtentScrollController(initialItem: d.day - 1);
    _monthController = FixedExtentScrollController(initialItem: d.month - 1);
    _yearController = FixedExtentScrollController(initialItem: clampedYear - widget.minYear);
  }

  void _jumpControllersTo(DateTime d) {
    final clampedYear = d.year.clamp(widget.minYear, widget.maxYear);
    if (_yearController.hasClients) {
      _yearController.jumpToItem(clampedYear - widget.minYear);
    }
    if (_monthController.hasClients) {
      _monthController.jumpToItem(d.month - 1);
    }
    if (_dayController.hasClients) {
      _dayController.jumpToItem(d.day - 1);
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateActiveDate({int? day, int? month, int? year}) {
    final cur = _activeDate;
    final newYear = year ?? cur.year;
    final newMonth = month ?? cur.month;
    final maxDay = _daysInMonth(newYear, newMonth);
    final newDay = (day ?? cur.day).clamp(1, maxDay);
    final updated = DateTime(newYear, newMonth, newDay);

    setState(() {
      if (_editingStart) {
        _startDate = updated;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = updated;
        if (_startDate.isAfter(_endDate)) {
          _startDate = _endDate;
        }
      }
    });

    if (day == null && cur.day > maxDay && _dayController.hasClients) {
      _dayController.jumpToItem(maxDay - 1);
    }
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
    });
    _jumpControllersTo(_activeDate);
  }

  void _switchTab(bool editStart) {
    if (_editingStart == editStart) return;
    setState(() {
      _editingStart = editStart;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpControllersTo(_activeDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDays = _daysInMonth(_activeDate.year, _activeDate.month);
    final yearCount = widget.maxYear - widget.minYear + 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Pilih Rentang Tanggal',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Geser roda Hari – Bulan – Tahun di bawah (tanpa perlu mengetik).',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Pintasan Cepat (Preset)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    label: '7 Hari Terakhir',
                    onTap: () => _applyPreset(today.subtract(const Duration(days: 6)), today),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    label: 'Bulan Ini',
                    onTap: () => _applyPreset(DateTime(today.year, today.month, 1), today),
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    label: '30 Hari Terakhir',
                    onTap: () => _applyPreset(today.subtract(const Duration(days: 29)), today),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Dari Tanggal vs Sampai Tanggal (format Hari Bulan Tahun)
            Row(
              children: [
                Expanded(
                  child: _buildDateTab(
                    label: 'Dari Tanggal',
                    date: _startDate,
                    isSelected: _editingStart,
                    onTap: () => _switchTab(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTab(
                    label: 'Sampai Tanggal',
                    date: _endDate,
                    isSelected: !_editingStart,
                    onTap: () => _switchTab(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Label Kolom: Hari | Bulan | Tahun
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Hari',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Text(
                      'Bulan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Tahun',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Roda Scroll 3 Kolom: Hari - Bulan - Tahun
            Container(
              height: 165,
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  // Kolom 1: Hari (01..31)
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: _dayController,
                      itemExtent: 36,
                      onSelectedItemChanged: (index) {
                        _updateActiveDate(day: index + 1);
                      },
                      children: List.generate(maxDays, (i) {
                        final dayNum = (i + 1).toString().padLeft(2, '0');
                        return Center(
                          child: Text(
                            dayNum,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Kolom 2: Bulan (Januari..Desember)
                  Expanded(
                    flex: 4,
                    child: CupertinoPicker(
                      scrollController: _monthController,
                      itemExtent: 36,
                      onSelectedItemChanged: (index) {
                        _updateActiveDate(month: index + 1);
                      },
                      children: ScrollDateRangePicker._namaBulan.map((nama) {
                        return Center(
                          child: Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Kolom 3: Tahun
                  Expanded(
                    flex: 3,
                    child: CupertinoPicker(
                      scrollController: _yearController,
                      itemExtent: 36,
                      onSelectedItemChanged: (index) {
                        _updateActiveDate(year: widget.minYear + index);
                      },
                      children: List.generate(yearCount, (i) {
                        final yr = widget.minYear + i;
                        return Center(
                          child: Text(
                            '$yr',
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Terapkan
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    DateTimeRange(start: _startDate, end: _endDate),
                  );
                },
                child: const Text('Terapkan Rentang Tanggal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({required String label, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: AppConstants.primaryDarkGreen,
        ),
      ),
      backgroundColor: AppConstants.primaryLightGreen,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onPressed: onTap,
    );
  }

  Widget _buildDateTab({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryLightGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryGreen : AppConstants.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: isSelected ? AppConstants.primaryDarkGreen : AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              AppFormatters.formatDateShort(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: isSelected ? AppConstants.primaryDarkGreen : AppConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

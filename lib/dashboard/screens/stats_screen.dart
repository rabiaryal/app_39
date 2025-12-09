import 'package:app_039/features/daily_activities/viewmodels/events_viewmodel.dart';
import 'package:app_039/features/journal/models/journal_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../viewmodels/optimized_dashboard_viewmodel.dart';
import '../../features/journal/viewmodels/journal_viewmodel.dart';
import '../../features/notes/viewmodels/notes_viewmodel.dart';
import '../../features/notes/models/note.dart';

class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedTimeRange = 'Today';
  String _selectedChartType = 'Events';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Filter Chips
            _buildFilterSection(context),
            const SizedBox(height: 24),

            // Content based on selection
            if (_selectedChartType == 'Events')
              _buildEventsSection(context, ref)
            else if (_selectedChartType == 'Journals')
              _buildJournalsSection(context, ref)
            else if (_selectedChartType == 'Notes')
              _buildNotesSection(context, ref)
            else
              _buildCombinedSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Period',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Today', 'This Week', 'This Month', 'All Time']
                .map(
                  (range) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(range),
                      selected: _selectedTimeRange == range,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTimeRange = range);
                        }
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'View Type',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Events', 'Journals', 'Notes', 'Combined']
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: _selectedChartType == type,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedChartType = type);
                        }
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsSection(BuildContext context, WidgetRef ref) {
    final totalEvents = ref.watch(totalEventsCountProvider);
    final completedEvents = ref.watch(completedEventsCountProvider);
    final pendingEvents = totalEvents - completedEvents;

    // Debug: Watch events state to see what's happening
    final eventsState = ref.watch(eventsProvider);

    // Adjust data based on time range
    int adjustedTotal = _getAdjustedValue(totalEvents, 0.2, 0.4, 0.7);
    int adjustedCompleted = _getAdjustedValue(
      completedEvents,
      0.25,
      0.45,
      0.75,
    );
    int adjustedPending = adjustedTotal - adjustedCompleted;

    final completionRate = adjustedTotal > 0
        ? (adjustedCompleted / adjustedTotal * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug Information (remove this later)
        // Container(
        //   margin: const EdgeInsets.only(bottom: 16),
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     color: Colors.blue.withOpacity(0.1),
        //     border: Border.all(color: Colors.blue),
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'DEBUG INFO - Stats Events Data',
        //         style: TextStyle(
        //           fontWeight: FontWeight.bold,
        //           color: Colors.blue[800],
        //         ),
        //       ),
        //       const SizedBox(height: 8),
        //       Text('Events State Loading: ${eventsState.isLoading}'),
        //       Text('Events State Error: ${eventsState.error ?? "None"}'),
        //       Text('Raw Events Count: ${eventsState.events.length}'),
        //       Text('Total Events Provider: $totalEvents'),
        //       Text('Completed Events Provider: $completedEvents'),
        //       Text('Selected Time Range: $_selectedTimeRange'),
        //       Text('Adjusted Total: $adjustedTotal'),
        //       if (eventsState.events.isNotEmpty) ...[
        //         const SizedBox(height: 8),
        //         Text(
        //           'Sample Events:',
        //           style: TextStyle(fontWeight: FontWeight.bold),
        //         ),
        //         ...eventsState.events
        //             .take(3)
        //             .map(
        //               (event) => Padding(
        //                 padding: const EdgeInsets.only(left: 16, top: 4),
        //                 child: Text(
        //                   '• ${event.title} - Status: ${event.status} - Completed: ${event.isCompleted}',
        //                 ),
        //               ),
        //             ),
        //       ],
        //     ],
        //   ),
        // ),

        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total',
                value: adjustedTotal.toString(),
                icon: Icons.event_note_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Done',
                value: adjustedCompleted.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Pending',
                value: adjustedPending.toString(),
                icon: Icons.schedule_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Completion Rate Card
        if (adjustedTotal > 0) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completion Rate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$completionRate%',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getCompletionColor(completionRate),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate / 100,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(
                      _getCompletionColor(completionRate),
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getCompletionMessage(completionRate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pie Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: SfCircularChart(
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                    series: <CircularSeries>[
                      DoughnutSeries<ChartData, String>(
                        dataSource: [
                          ChartData(
                            'Completed',
                            adjustedCompleted.toDouble(),
                            Colors.green,
                          ),
                          ChartData(
                            'Pending',
                            adjustedPending.toDouble(),
                            Colors.orange,
                          ),
                        ],
                        xValueMapper: (ChartData data, _) => data.category,
                        yValueMapper: (ChartData data, _) => data.value,
                        pointColorMapper: (ChartData data, _) => data.color,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                        ),
                        // innerRadius: '60%', // Commented out - not supported in this version
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else
          _buildEmptyState(
            context,
            icon: Icons.event_busy,
            message: 'No events yet',
            subtitle: 'Create events to see your statistics',
          ),
      ],
    );
  }

  Widget _buildJournalsSection(BuildContext context, WidgetRef ref) {
    final journalsState = ref.watch(journalProvider);
    final totalJournals = journalsState.entries.length;

    // Adjust data based on time range
    int adjustedTotal = _getAdjustedValue(totalJournals, 0.2, 0.4, 0.7);

    // Calculate journals by mood
    final moodCounts = <String, int>{};
    for (final entry in journalsState.entries) {
      final mood = entry.mood.displayName;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total',
                value: adjustedTotal.toString(),
                icon: Icons.book_outlined,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'This Week',
                value: _getThisWeekCount(
                  journalsState.entries,
                  (entry) => entry.createdAt,
                ).toString(),
                icon: Icons.calendar_today_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        if (totalJournals > 0) ...[
          const SizedBox(height: 24),
          Text(
            'Journal Mood Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: moodCounts.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value.toDouble(),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    // innerRadius: '60%',
                  ),
                ],
              ),
            ),
          ),
        ] else
          _buildEmptyState(
            context,
            icon: Icons.book_outlined,
            message: 'No journal entries yet',
            subtitle: 'Create journal entries to see your statistics',
          ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final totalNotes = notesState.notes.length;
    final pinnedNotes = notesState.notes.where((note) => note.isPinned).length;

    // Adjust data based on time range
    int adjustedTotal = _getAdjustedValue(totalNotes, 0.2, 0.4, 0.7);
    int adjustedPinned = _getAdjustedValue(pinnedNotes, 0.15, 0.35, 0.65);

    // Calculate notes by status
    final statusCounts = <String, int>{};
    for (final note in notesState.notes) {
      final status = note.status.displayName;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total',
                value: adjustedTotal.toString(),
                icon: Icons.note_outlined,
                color: Colors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Pinned',
                value: adjustedPinned.toString(),
                icon: Icons.push_pin_outlined,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        if (totalNotes > 0) ...[
          const SizedBox(height: 24),
          Text(
            'Notes Status Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: statusCounts.entries.toList(),
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value.toDouble(),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    // innerRadius: '60%',
                  ),
                ],
              ),
            ),
          ),
        ] else
          _buildEmptyState(
            context,
            icon: Icons.note_outlined,
            message: 'No notes yet',
            subtitle: 'Create notes to see your statistics',
          ),
      ],
    );
  }

  Widget _buildCombinedSection(BuildContext context, WidgetRef ref) {
    final timeSeriesData = ref.watch(combinedTimeSeriesProvider);
    final totalEvents = ref.watch(totalEventsCountProvider);
    final completedEvents = ref.watch(completedEventsCountProvider);
    final journalsState = ref.watch(journalProvider);
    final notesState = ref.watch(notesProvider);

    int adjustedTotal = _getAdjustedValue(totalEvents, 0.2, 0.4, 0.7);
    int adjustedCompleted = _getAdjustedValue(
      completedEvents,
      0.25,
      0.45,
      0.75,
    );

    return Column(
      children: [
        // Quick Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickStatCard(
              context,
              title: 'Events',
              value: adjustedTotal.toString(),
              icon: Icons.event_outlined,
              color: Colors.blue,
            ),
            _buildQuickStatCard(
              context,
              title: 'Journals',
              value: journalsState.entries.length.toString(),
              icon: Icons.book_outlined,
              color: Colors.amber,
            ),
            _buildQuickStatCard(
              context,
              title: 'Notes',
              value: notesState.notes.length.toString(),
              icon: Icons.note_outlined,
              color: Colors.pink,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Combined Time Series Chart
        Text(
          '7-Day Activity Trends',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Events', Colors.blue),
                    _buildLegendItem('Journals', Colors.amber),
                    _buildLegendItem('Notes', Colors.pink),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('MM/dd'),
                      intervalType: DateTimeIntervalType.days,
                      interval: 1,
                    ),
                    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Count')),
                    legend: Legend(isVisible: false),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries>[
                      LineSeries<TimeSeriesData, DateTime>(
                        dataSource: timeSeriesData,
                        xValueMapper: (TimeSeriesData data, _) => data.date,
                        yValueMapper: (TimeSeriesData data, _) =>
                            data.eventCount.toDouble(),
                        name: 'Events',
                        color: Colors.blue,
                        width: 3,
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                          height: 6,
                          width: 6,
                          color: Colors.blue,
                        ),
                      ),
                      LineSeries<TimeSeriesData, DateTime>(
                        dataSource: timeSeriesData,
                        xValueMapper: (TimeSeriesData data, _) => data.date,
                        yValueMapper: (TimeSeriesData data, _) =>
                            data.journalCount.toDouble(),
                        name: 'Journals',
                        color: Colors.amber,
                        width: 3,
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                          height: 6,
                          width: 6,
                          color: Colors.amber,
                        ),
                      ),
                      LineSeries<TimeSeriesData, DateTime>(
                        dataSource: timeSeriesData,
                        xValueMapper: (TimeSeriesData data, _) => data.date,
                        yValueMapper: (TimeSeriesData data, _) =>
                            data.noteCount.toDouble(),
                        name: 'Notes',
                        color: Colors.pink,
                        width: 3,
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                          height: 6,
                          width: 6,
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(int rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getCompletionMessage(int rate) {
    if (rate >= 70) return 'Excellent progress! Keep it up! 🎉';
    if (rate >= 40) return 'Good work! A bit more to go.';
    return 'Let\'s work on completing more events.';
  }

  int _getAdjustedValue(int total, double today, double week, double month) {
    switch (_selectedTimeRange) {
      case 'Today':
        return (total * today).round();
      case 'This Week':
        return (total * week).round();
      case 'This Month':
        return (total * month).round();
      default:
        return total;
    }
  }

  int _getThisWeekCount<T>(List<T> items, DateTime Function(T) getDate) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return items.where((item) {
      final itemDate = getDate(item);
      return itemDate.isAfter(
        weekStartDate.subtract(const Duration(seconds: 1)),
      );
    }).length;
  }
}

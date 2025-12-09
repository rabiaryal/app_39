import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../viewmodels/optimized_dashboard_viewmodel.dart';
import '../../core/widgets/router.dart';
import '../../core/utils.dart';
import '../../core/services/home_widget_service.dart';
import '../../features/daily_activities/viewmodels/events_viewmodel.dart';

import '../../features/notes/viewmodels/notes_viewmodel.dart';


class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}

class OptimizedDashboardScreen extends ConsumerStatefulWidget {
  const OptimizedDashboardScreen({super.key});

  @override
  ConsumerState<OptimizedDashboardScreen> createState() =>
      _OptimizedDashboardScreenState();
}

class _OptimizedDashboardScreenState
    extends ConsumerState<OptimizedDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRefreshing) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        ref.read(eventsProvider.notifier).loadEvents(),
        ref.read(notesProvider.notifier).loadNotes(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final dashboardSummary = ref.watch(optimizedDashboardSummaryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Debug: Watch events state to see what's happening
    final eventsState = ref.watch(eventsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // // Debug Information Section (remove this later)
            // SliverToBoxAdapter(
            //   child: Container(
            //     margin: const EdgeInsets.all(16),
            //     padding: const EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: Colors.yellow.withOpacity(0.1),
            //       border: Border.all(color: Colors.orange),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'DEBUG INFO - Events Data',
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.orange[800],
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         Text('Events State Loading: ${eventsState.isLoading}'),
            //         Text('Events State Error: ${eventsState.error ?? "None"}'),
            //         Text('Total Events Count: ${eventsState.events.length}'),
            //         Text(
            //           'Dashboard Summary - Total Events: ${dashboardSummary.totalEvents}',
            //         ),
            //         Text(
            //           'Dashboard Summary - Today Events: ${dashboardSummary.todayEvents}',
            //         ),
            //         if (eventsState.events.isNotEmpty) ...[
            //           const SizedBox(height: 8),
            //           Text(
            //             'Sample Events:',
            //             style: TextStyle(fontWeight: FontWeight.bold),
            //           ),
            //           ...eventsState.events
            //               .take(3)
            //               .map(
            //                 (event) => Padding(
            //                   padding: const EdgeInsets.only(left: 16, top: 4),
            //                   child: Text(
            //                     '• ${event.title} - ${event.date.toString().split(' ')[0]}',
            //                   ),
            //                 ),
            //               ),
            //         ],
            //       ],
            //     ),
            //   ),
            // ),

            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                    _buildSettingsButton(context),
                  ],
                ),
              ),
            ),

            // Today's Overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            icon: Icons.event_outlined,
                            label: 'Events',
                            value: '${dashboardSummary.todayEvents}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context),
                  ],
                ),
              ),
            ),

            // Insights Charts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '7-Day Insights',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          GestureDetector(
                            onTap: () => AppNavigation.goToStats(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'View Stats',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        children: [
                          _buildEventsChart(context, ref),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Activity List
            Consumer(
              builder: (context, ref, child) {
                final recentActivities = ref.watch(recentActivitiesProvider);

                if (recentActivities.isEmpty) {
                  return SliverToBoxAdapter(
                    // child: _buildEmptyActivities(context),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActivityCard(
                          context,
                          recentActivities[index],
                        ),
                      );
                    }, childCount: recentActivities.length),
                  ),
                );
              },
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigation.goToSettings(context),
      child: Container(
        padding: const EdgeInsets.all(8),

        child: Icon(
          Icons.person_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
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
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      // _QuickAction(
      //   label: 'View Stats',
      //   icon: Icons.bar_chart_rounded,
      //   color: Colors.teal,
      //   onTap: () => AppNavigation.goToStats(context),
      // ),
      _QuickAction(
        label: 'Add Event',
        icon: Icons.event_available,
        color: Colors.blue,
        onTap: () => AppNavigation.goToAddEvent(context),
      ),
      _QuickAction(
        label: 'Add Journal',
        icon: Icons.add_circle_outline,
        color: Colors.green,
        onTap: () => AppNavigation.goToAddJournal(context),
      ),
      _QuickAction(
        label: 'Home Widget',
        icon: Icons.widgets_outlined,
        color: Colors.orange,
        onTap: () => _setupHomeWidget(context),
      ),
      _QuickAction(
        label: 'Add Note',
        icon: Icons.note_add_outlined,
        color: Colors.purple,
        onTap: () => AppNavigation.goToAddNote(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(context, action);
      },
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: action.color,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsChart(BuildContext context, WidgetRef ref) {
    final timeSeriesData = ref.watch(combinedTimeSeriesProvider);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Trends',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend\n          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n            children: [\n              _buildLegendItem('Events', Colors.blue),\n              _buildLegendItem('Journals', Colors.amber),\n              _buildLegendItem('Notes', Colors.pink),\n            ],\n          ),\n          const SizedBox(height: 8),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('MM/dd'),
                intervalType: DateTimeIntervalType.days,
                interval: 1,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  dashArray: [5, 5],
                ),
                axisLine: const AxisLine(width: 0),
              ),
              series: <CartesianSeries>[
                LineSeries<TimeSeriesData, DateTime>(
                  dataSource: timeSeriesData,
                  xValueMapper: (TimeSeriesData data, _) => data.date,
                  yValueMapper: (TimeSeriesData data, _) =>
                      data.eventCount.toDouble(),
                  color: Colors.blue,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    color: Colors.blue,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),
                LineSeries<TimeSeriesData, DateTime>(
                  dataSource: timeSeriesData,
                  xValueMapper: (TimeSeriesData data, _) => data.date,
                  yValueMapper: (TimeSeriesData data, _) =>
                      data.journalCount.toDouble(),
                  color: Colors.amber,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    color: Colors.amber,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),
                LineSeries<TimeSeriesData, DateTime>(
                  dataSource: timeSeriesData,
                  xValueMapper: (TimeSeriesData data, _) => data.date,
                  yValueMapper: (TimeSeriesData data, _) =>
                      data.noteCount.toDouble(),
                  color: Colors.pink,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    color: Colors.pink,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
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

  Widget _buildActivityCard(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final type = activity['type'] as String? ?? 'unknown';
    final title = activity['title'] as String? ?? 'Untitled';
    final description = activity['description'] as String? ?? '';
    final status = activity['status'] as String? ?? 'unknown';
    final label = activity['label'] as String? ?? 'Item';
    final id = activity['id'] as String? ?? '';
    final executionTime =
        activity['executionTime'] as DateTime? ?? DateTime.now();

    final activityColor = _getActivityColor(type);
    final statusColor = _getStatusColor(status);

    return InkWell(
      onTap: () => _navigateToActivity(context, type, id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with status indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getActivityIcon(type),
                    color: activityColor,
                    size: 20,
                  ),
                ),
                if (type != 'note')
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: activityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: activityColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatActivityDate(executionTime),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (type != 'note') ...[
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  /// Navigate to the appropriate screen based on activity type
  void _navigateToActivity(BuildContext context, String type, String id) {
    try {
      switch (type) {
        case 'event':
          if (id.isNotEmpty) {
            AppNavigation.goToEditEvent(context, id);
          } else {
            AppNavigation.goToEvents(context);
          }
          break;
        case 'note':
          if (id.isNotEmpty) {
            AppNavigation.goToEditNote(context, id);
          } else {
            AppNavigation.goToNotes(context);
          }
          break;
        case 'journal':
          if (id.isNotEmpty) {
            AppNavigation.goToEditJournalEntry(context, id);
          } else {
            AppNavigation.goToJournal(context);
          }
          break;
        default:
          // For unknown types, do nothing or show a message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot navigate to $type'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening $type: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  Widget _buildEmptyActivities(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent activities will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event_outlined;
      case 'transaction':
        return Icons.attach_money;
      case 'note':
        return Icons.note_outlined;
      case 'journal':
        return Icons.book_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'transaction':
        return Colors.green;
      case 'note':
        return Colors.purple;
      case 'journal':
        return Colors.orange;
      case 'appointment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
      case 'confirmed':
        return Colors.green;
      case 'ongoing':
      case 'active':
        return Colors.blue;
      case 'upcoming':
      case 'pending':
      case 'not_started':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Handle home widget setup
  Future<void> _setupHomeWidget(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Setting up widget...'),
            ],
          ),
        ),
      );

      // Initialize and update widget
      await HomeWidgetService.initialize();
      await HomeWidgetService.updateOngoingEventsWidget();
      final available = await HomeWidgetService.isWidgetAvailable();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (!available) {
        // Show info dialog if widgets aren't supported
        _showWidgetInfoDialog(context, false);
        return;
      }

      // Request to add widget
      final success = await HomeWidgetService.requestAddWidget();

      if (context.mounted) {
        _showWidgetInfoDialog(context, success);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup widget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show widget setup info dialog
  void _showWidgetInfoDialog(BuildContext context, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.info_outline,
              color: success ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(success ? 'Widget Ready!' : 'Widget Setup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              success
                  ? 'Your home widget has been updated with ongoing events data!'
                  : 'To add the ongoing events widget to your home screen:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (!success) ...[
              const Text('1. Long press on your home screen'),
              const Text('2. Tap \"Widgets\"'),
              const Text('3. Find \"Daily Tracker\" app'),
              const Text('4. Add the \"Ongoing Events\" widget'),
              const SizedBox(height: 12),
            ],
            Text(
              'The widget shows your ongoing and upcoming events in real-time!',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          if (success)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await HomeWidgetService.updateOngoingEventsWidget();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Widget updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Update Now'),
            ),
        ],
      ),
    );
  }

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

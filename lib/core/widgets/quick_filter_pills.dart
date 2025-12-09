import 'package:flutter/material.dart';
import '../../../core/design_system.dart';
import '../../../core/widgets/app_text_style.dart';

/// Quick Filter Pills for filtering tasks/events/etc
/// Horizontally scrollable chips with active states
class QuickFilterPills extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<FilterOption> filters;

  const QuickFilterPills({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: AppDesignSystem.spacingSm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacingBase),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.value == selectedFilter;

          return Padding(
            padding: EdgeInsets.only(right: AppDesignSystem.spacingSm),
            child: _buildFilterChip(context, filter, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    FilterOption filter,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: AppDesignSystem.animationFast,
      child: InkWell(
        onTap: () => onFilterChanged(filter.value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingBase,
            vertical: AppDesignSystem.spacingSm,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? AppDesignSystem.gradientPrimary : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppDesignSystem.gray300,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppDesignSystem.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.icon != null) ...[
                Icon(
                  filter.icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppDesignSystem.gray700,
                ),
                SizedBox(width: AppDesignSystem.spacingXs),
              ],
              Text(
                filter.label,
                style: AppTextStyles.of(context).body2.copyWith(
                  color: isSelected ? Colors.white : AppDesignSystem.gray700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (filter.count != null) ...[
                SizedBox(width: AppDesignSystem.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : AppDesignSystem.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filter.count}',
                    style: AppTextStyles.of(context).caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppDesignSystem.gray700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FilterOption {
  final String value;
  final String label;
  final IconData? icon;
  final int? count;

  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });
}

/// Predefined filter sets for different pages

class TaskFilters {
  static List<FilterOption> get defaults => [
    const FilterOption(value: 'all', label: 'All', icon: Icons.list_rounded),
    const FilterOption(
      value: 'today',
      label: 'Today',
      icon: Icons.today_rounded,
    ),
    const FilterOption(
      value: 'week',
      label: 'This Week',
      icon: Icons.date_range_rounded,
    ),
    const FilterOption(
      value: 'high',
      label: 'High Priority',
      icon: Icons.flag_rounded,
    ),
    const FilterOption(
      value: 'completed',
      label: 'Completed',
      icon: Icons.check_circle_rounded,
    ),
  ];
}

class EventFilters {
  static List<FilterOption> get defaults => [
    const FilterOption(value: 'all', label: 'All', icon: Icons.event_rounded),
    const FilterOption(
      value: 'today',
      label: 'Today',
      icon: Icons.today_rounded,
    ),
    const FilterOption(
      value: 'upcoming',
      label: 'Upcoming',
      icon: Icons.upcoming_rounded,
    ),
    const FilterOption(value: 'work', label: 'Work', icon: Icons.work_rounded),
    const FilterOption(
      value: 'personal',
      label: 'Personal',
      icon: Icons.person_rounded,
    ),
  ];
}

class NoteFilters {
  static List<FilterOption> get defaults => [
    const FilterOption(value: 'all', label: 'All', icon: Icons.note_rounded),
    const FilterOption(
      value: 'active',
      label: 'Active',
      icon: Icons.edit_rounded,
    ),
    const FilterOption(
      value: 'pinned',
      label: 'Pinned',
      icon: Icons.push_pin_rounded,
    ),
    const FilterOption(
      value: 'archived',
      label: 'Archived',
      icon: Icons.archive_rounded,
    ),
  ];
}

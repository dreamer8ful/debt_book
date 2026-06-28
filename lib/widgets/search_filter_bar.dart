import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final hasActiveFilter = provider.filterStatus != 'All';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: hasActiveFilter
                    ? const Color(0xFF0D6B8A).withValues(alpha: 0.28)
                    : const Color(0xFFE1E8EF),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6B8A).withValues(
                    alpha: hasActiveFilter ? 0.08 : 0.0,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildFilterChip('All', 'All'),
                    _buildFilterChip('Unpaid', 'Unpaid'),
                    _buildFilterChip('Paid', 'Paid'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.filterStatus == value;
        final chipColor = value == 'All'
            ? Colors.blue.shade100
            : value == 'Unpaid'
            ? Colors.orange.shade100
            : Colors.green.shade100;
        final labelColor = value == 'All'
            ? Colors.blue.shade700
            : value == 'Unpaid'
            ? Colors.orange.shade700
            : Colors.green.shade700;

        return AnimatedScale(
          scale: isSelected ? 1.0 : 0.97,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Semantics(
            button: true,
            selected: isSelected,
            label: 'Filter: $label',
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (selected) {
                if (selected) {
                  provider.setFilterStatus(value);
                }
              },
              side: BorderSide(color: isSelected ? labelColor.withValues(alpha: 0.25) : const Color(0xFFD9E1E8)),
              backgroundColor: Colors.white,
              selectedColor: chipColor,
              checkmarkColor: labelColor,
              labelStyle: TextStyle(
                color: isSelected ? labelColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}

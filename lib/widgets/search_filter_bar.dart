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
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              _buildFilterChip('Active', 'Active'),
              const SizedBox(width: 8),
              _buildFilterChip('Settled', 'Settled'),
              const SizedBox(width: 8),
              _buildFilterChip('All', 'All'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.filterStatus == value;
        final labelColor = value == 'All'
            ? const Color(0xFF0D6B8A)
            : value == 'Active'
            ? Colors.orange.shade800
            : Colors.green.shade800;

        return Expanded(
          child: InkWell(
            onTap: () => provider.setFilterStatus(value),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? labelColor : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? labelColor : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: labelColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.blueGrey.shade600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

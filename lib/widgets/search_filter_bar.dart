import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<DebtProvider>(
        context,
        listen: false,
      ).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: Colors.grey.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Search & Filter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', 'All'),
                      _buildFilterChip('Unpaid', 'Unpaid'),
                      _buildFilterChip('Paid', 'Paid'),
                    ],
                  ),
                ],
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

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              provider.setFilterStatus(value);
            }
          },
          backgroundColor: Colors.white,
          selectedColor: chipColor,
          checkmarkColor: labelColor,
          labelStyle: TextStyle(
            color: isSelected ? labelColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        );
      },
    );
  }
}

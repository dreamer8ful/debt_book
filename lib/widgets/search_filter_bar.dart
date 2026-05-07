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
      Provider.of<DebtProvider>(context, listen: false).setSearchQuery(_searchController.text);
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Search field
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips
              Row(
                children: [
                  _buildFilterChip('All', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unpaid', 'Unpaid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paid', 'Paid'),
                ],
              ),
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
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              provider.setFilterStatus(value);
            }
          },
          backgroundColor: Colors.grey.shade200,
          selectedColor: value == 'All' 
              ? Colors.blue.shade100
              : value == 'Unpaid' 
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
          checkmarkColor: value == 'All'
              ? Colors.blue.shade700
              : value == 'Unpaid'
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
          labelStyle: TextStyle(
            color: isSelected
                ? value == 'All'
                    ? Colors.blue.shade700
                    : value == 'Unpaid'
                        ? Colors.orange.shade700
                        : Colors.green.shade700
                : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      },
    );
  }
}
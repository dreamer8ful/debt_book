import 'package:flutter/material.dart';

class FilterButtons extends StatefulWidget {
  final Function(String) onFilterChanged; // 👈 HII LAZIMA IWE HAPA
  
  const FilterButtons({super.key, required this.onFilterChanged}); // 👈 NA HII

  @override
  State<FilterButtons> createState() => _FilterButtonsState();
}

class _FilterButtonsState extends State<FilterButtons> {
  String selectedFilter = 'Active';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          _buildChip(Icons.visibility_outlined, 'Timeline'),
          const SizedBox(width: 8),
          _buildChip(Icons.filter_list, 'Active'),
          const SizedBox(width: 8),
          _buildChip(Icons.sort, 'Default'),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    bool isSelected = selectedFilter == label;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected? Colors.white : Colors.grey.shade700),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedFilter = label);
        widget.onFilterChanged(label); // 👈 HII INATUMIA CALLBACK
      },
      selectedColor: Colors.blue.shade600,
      labelStyle: TextStyle(color: isSelected? Colors.white : Colors.black87),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected? Colors.blue.shade600 : Colors.grey.shade300),
      ),
      backgroundColor: Colors.white,
    );
  }
}
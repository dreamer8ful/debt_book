import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class OverviewCard extends StatelessWidget {
  final bool isLend;
  const OverviewCard({super.key, required this.isLend});

  String formatCurrency(double amount) {
    return '${NumberFormat('#,##0', 'en_US').format(amount)} TSh';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    // CHAGUA LIST SAHI
    final filteredList = isLend
      ? provider.filteredLendList
        : provider.filteredBorrowList;

    // CALCULATE TOTALS ZA FILTERED LIST
    double totalAmount = 0;
    double paidAmount = 0;

    for (var debt in filteredList) {
      totalAmount += debt.amount;
      paidAmount += debt.paidAmount; // 👈 BADILISHA HAPA: Tumia paidAmount badala ya status
      // 👇 BADILISHA HAPA: Tumia status badala ya isPaid
      //paidAmount += debt.amount;
      //}
    }

    double remainingAmount = totalAmount - paidAmount;
    double progress = totalAmount > 0? paidAmount / totalAmount : 0;

    final isFiltering = provider.searchQuery.isNotEmpty || provider.filterStatus!= 'All';
    final cardColor = isLend? Colors.red.shade50 : Colors.green.shade50;
    final textColor = isLend? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFiltering? textColor.withValues(alpha: 0.5) : Colors.transparent,
          width: isFiltering? 2 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLend? 'Total Lend' : 'Total Borrow',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isFiltering)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(totalAmount),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn('Paid', paidAmount, textColor),
              _buildAmountColumn('Remaining', remainingAmount, Colors.grey[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
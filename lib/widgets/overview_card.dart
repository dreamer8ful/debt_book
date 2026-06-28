import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class OverviewCard extends StatelessWidget {
  final bool isLend;
  final VoidCallback? onTap;
  const OverviewCard({super.key, required this.isLend, this.onTap});

  String formatCurrency(double amount) {
    return '${NumberFormat('#,##0', 'en_US').format(amount)} TSh';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    final filteredList = isLend
        ? provider.filteredLendList
        : provider.filteredBorrowList;

    double totalAmount = 0;
    double paidAmount = 0;

    for (var debt in filteredList) {
      totalAmount += debt.amount;
      paidAmount += debt.paidAmount;
    }

    double remainingAmount = totalAmount - paidAmount;

    final isFiltering =
        provider.searchQuery.isNotEmpty || provider.filterStatus != 'All';
    final cardColor = isLend ? Colors.red.shade50 : Colors.green.shade50;
    final textColor = isLend ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFiltering
              ? textColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: isFiltering ? 2 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Touch to view full report',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFiltering)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: 14,
                                  color: textColor,
                                ),
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
                        if (onTap != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey[500]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 16),
          _buildAmountRow(
            label: isLend ? 'Total lend amount' : 'Total borrow amount',
            amount: totalAmount,
            color: Colors.red,
          ),
          const SizedBox(height: 14),
          _buildAmountRow(
            label: isLend ? 'Collected' : 'Paid',
            amount: paidAmount,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Divider(color: Colors.grey[400], thickness: 1, height: 1),
            ),
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            label: 'Remaining',
            amount: remainingAmount,
            color: Colors.amber.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
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

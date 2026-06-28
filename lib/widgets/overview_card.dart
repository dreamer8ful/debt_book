import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/debt_provider.dart';

class OverviewCard extends StatelessWidget {
  final bool isLend;
  final VoidCallback? onTap;
  const OverviewCard({super.key, required this.isLend, this.onTap});

  String formatCurrency(BuildContext context, double amount) {
    return context.read<AppSettingsProvider>().formatCurrency(amount);
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
    final textColor = isLend ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isFiltering
              ? textColor.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: isFiltering ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFiltering)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Filtered',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.blueGrey.shade400),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAmountBlock(
                  context,
                  label: isLend ? 'Total Lend' : 'Total Borrow',
                  amount: totalAmount,
                  color: Colors.red.shade600,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildAmountBlock(
                  context,
                  label: isLend ? 'Collected' : 'Paid',
                  amount: paidAmount,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining Balance',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatCurrency(context, remainingAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBlock(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blueGrey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatCurrency(context, amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

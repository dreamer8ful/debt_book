import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../widgets/debt_person_card.dart';
import '../widgets/overview_card.dart';
import '../widgets/search_filter_bar.dart';

class TransactionReportScreen extends StatefulWidget {
  final int initialIndex;

  const TransactionReportScreen({super.key, this.initialIndex = 0});

  @override
  State<TransactionReportScreen> createState() =>
      _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLendTab = _tabController.index == 0;
    final appBarColor = isLendTab ? Colors.red.shade600 : Colors.green.shade600;

    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction Report'),
            backgroundColor: appBarColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'LEND'),
                Tab(text: 'BORROW'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTab(context, provider, true),
              _buildTab(context, provider, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, DebtProvider provider, bool isLend) {
    final list = isLend
        ? provider.filteredLendList
        : provider.filteredBorrowList;

    return Column(
      children: [
        const SearchFilterBar(),
        OverviewCard(isLend: isLend),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      provider.searchQuery.isNotEmpty ||
                              provider.filterStatus != 'All'
                          ? 'No results found'
                          : (isLend
                                ? 'No lend transactions yet'
                                : 'No borrow transactions yet'),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final debt = list[index];
                    return DebtPersonCard(
                      debt: debt,
                      onDelete: () => provider.deleteDebt(debt.id!),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

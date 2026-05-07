// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/app_drawer.dart';
import '../providers/debt_provider.dart';
import '../widgets/overview_card.dart';
import '../widgets/debt_person_card.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid build issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).loadAllData();
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatCurrency(double amount) {
    return '${NumberFormat('#,##0', 'en_US').format(amount)} TSh';
  }

  @override
  Widget build(BuildContext context) {
    bool isLendTab = _tabController.index == 0;
    Color appBarColor = isLendTab ? Colors.red.shade600 : Colors.green.shade600;

    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: const AppDrawer(),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
            title: const Row(
              children: [
                Icon(Icons.book, color: Colors.amber),
                SizedBox(width: 8),
                Text('Debt Book', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Focus on search field in SearchFilterBar
                  // You can add a FocusNode to programmatically focus
                },
              ),
              const SizedBox(width: 16),
            ],
            backgroundColor: appBarColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(child: Text('LEND\n${formatCurrency(debtProvider.totalLent)}', textAlign: TextAlign.center)),
                Tab(child: Text('BORROW\n${formatCurrency(debtProvider.totalBorrow)}', textAlign: TextAlign.center)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(debtProvider, true),
              _buildTabContent(debtProvider, false),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(type: isLendTab ? 'lend' : 'borrow'),
                ),
              ).then((_) {
                // Refresh data when returning from add screen
                debtProvider.loadAllData();
              });
            },
            backgroundColor: appBarColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(DebtProvider provider, bool isLend) {
    final list = isLend ? provider.filteredLendList : provider.filteredBorrowList;
    final tabKey = isLend ? 'lend' : 'borrow';

    return Column(
      children: [
        const SearchFilterBar(),
        OverviewCard(isLend: isLend),
        Expanded(
          child: list.isEmpty
              ? Center(
                  key: ValueKey('empty_${tabKey}_${provider.searchQuery}_${provider.filterStatus}'),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty || provider.filterStatus != 'All'
                              ? 'No results found'
                              : 'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (provider.filterStatus != 'All')
                          TextButton.icon(
                            onPressed: () {
                              provider.setFilterStatus('All');
                              provider.setSearchQuery('');
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: ValueKey('list_${tabKey}_${provider.searchQuery}_${provider.filterStatus}'),
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final debt = list[index];
                    return DebtPersonCard(
                      key: ValueKey(debt.id),
                      debt: debt,
                      onDelete: () async {
                        // Show confirmation before delete
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Transaction?'),
                            content: Text('Are you sure you want to delete ${debt.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await provider.deleteDebt(debt.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${debt.name} deleted'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
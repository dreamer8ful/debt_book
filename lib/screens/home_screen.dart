// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/app_drawer.dart';
import '../providers/debt_provider.dart';
import '../widgets/overview_card.dart';
import '../widgets/debt_person_card.dart';
import '../widgets/debt_search_delegate.dart';
import 'add_transaction_screen.dart';
import 'transaction_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid build issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).loadAllData();
    });
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: Duration.zero,
    );
    _tabController.addListener(() {
      if (mounted) {
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
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  void _openSearch(DebtProvider debtProvider) {
    showSearch(
      context: context,
      delegate: DebtSearchDelegate(debtProvider),
    );
  }

  void _openAddTransaction(bool isLendTab, DebtProvider debtProvider) {
    Navigator.push(
      context,
      _buildPageRoute(
        AddTransactionScreen(type: isLendTab ? 'lend' : 'borrow'),
      ),
    ).then((_) {
      debtProvider.loadAllData();
    });
  }

  void _showFeedback(String message, {Color? backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  PageRouteBuilder<void> _buildPageRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLendTab = _tabController.index == 0;
    Color appBarColor = isLendTab ? const Color(0xFFB23A48) : const Color(0xFF2E9E5B);

    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
        final shortcuts = <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              () => _openSearch(debtProvider),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              () => _openAddTransaction(isLendTab, debtProvider),
        };

        return CallbackShortcuts(
          bindings: shortcuts,
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Scaffold(
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
                Icon(Icons.menu_book_rounded, color: Color(0xFFFFD166)),
                SizedBox(width: 8),
                Text(
                  'Debt Book',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search transactions',
                onPressed: () {
                  _openSearch(debtProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
            backgroundColor: appBarColor,
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appBarColor,
                    isLendTab ? const Color(0xFF922A36) : const Color(0xFF267F49),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.16),
              ),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  child: Text(
                    'LEND\n${formatCurrency(debtProvider.totalLent)}',
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    'BORROW\n${formatCurrency(debtProvider.totalBorrow)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
              body: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF3F7FA), Color(0xFFEAF2F8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(debtProvider, true),
                    _buildTabContent(debtProvider, false),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  _openAddTransaction(isLendTab, debtProvider);
                },
                tooltip: 'Add a new transaction',
                backgroundColor: appBarColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Transaction'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(DebtProvider provider, bool isLend) {
    final list = isLend
        ? provider.filteredLendList
        : provider.filteredBorrowList;
    final tabKey = isLend ? 'lend' : 'borrow';

    return Column(
      children: [
        OverviewCard(
          isLend: isLend,
          onTap: () {
            Navigator.push(
              context,
              _buildPageRoute(
                TransactionReportScreen(initialIndex: isLend ? 0 : 1),
              ),
            );
          },
        ),
        const SearchFilterBar(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
            child: list.isEmpty
                ? Center(
                    key: ValueKey(
                      'empty_${tabKey}_${provider.searchQuery}_${provider.filterStatus}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.searchQuery.isNotEmpty ||
                                    provider.filterStatus != 'All'
                                ? 'No transactions match your filters'
                                : 'No transactions yet. Add your first one.',
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
                              label: const Text('Reset Filters'),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    key: ValueKey(
                      'list_${tabKey}_${provider.searchQuery}_${provider.filterStatus}',
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                              contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              title: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.red.shade700.withValues(alpha: 0.12),
                                    child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Delete Transaction',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to delete ${debt.name}? This action cannot be undone.',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await provider.deleteDebt(debt.id!);
                            if (mounted) {
                              _showFeedback(
                                '${debt.name} deleted',
                                backgroundColor: Colors.red,
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

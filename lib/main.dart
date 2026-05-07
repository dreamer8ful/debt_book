import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/debt_provider.dart';
import 'widgets/overview_card.dart';
import 'widgets/debt_person_card.dart';
import 'screens/add_transaction_screen.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/app_drawer.dart'; // 👈 ADD THIS IMPORT

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebtBookApp());
}

class DebtBookApp extends StatelessWidget {
  const DebtBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DebtProvider()..loadAllData(),
      child: MaterialApp(
        title: 'Debt Book',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.red,
        ),
        home: const HomeScreen(),
        // Add named routes for better navigation
        routes: {
          '/home': (context) => const HomeScreen(),
          '/export': (context) => const ExportScreen(), // Add when created
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // 👈 ADD THIS

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
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
          key: _scaffoldKey, // 👈 ADD THIS
          drawer: const AppDrawer(), // 👈 ADD DRAWER HERE
          appBar: AppBar(
            // FIXED: Menu button with onPressed
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
            title: const Row(
              children: [
                Icon(Icons.book, color: Colors.amber),
                SizedBox(width: 8),
                Text('Debt Book'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: DebtSearchDelegate(debtProvider),
                  );
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
              // LEND TAB
              Column(
                children: [
                  SearchFilterBar(), // 👈 Pass callback if needed
                  OverviewCard(isLend: true),
                  Expanded(
                    child: debtProvider.filteredLendList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              debtProvider.searchQuery.isNotEmpty || debtProvider.filterStatus != 'All'
                                ? 'No results found'
                                : 'No lend transactions yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: debtProvider.filteredLendList.length,
                          itemBuilder: (context, index) {
                            final debt = debtProvider.filteredLendList[index];
                            return DebtPersonCard(
                              debt: debt,
                              onDelete: () => debtProvider.deleteDebt(debt.id!),
                            );
                          },
                        ),
                  ),
                ],
              ),
              // BORROW TAB
              Column(
                children: [
                  SearchFilterBar(),
                  OverviewCard(isLend: false),
                  Expanded(
                    child: debtProvider.filteredBorrowList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              debtProvider.searchQuery.isNotEmpty || debtProvider.filterStatus != 'All'
                                ? 'No results found'
                                : 'No borrow transactions yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: debtProvider.filteredBorrowList.length,
                          itemBuilder: (context, index) {
                            final debt = debtProvider.filteredBorrowList[index];
                            return DebtPersonCard(
                              debt: debt,
                              onDelete: () => debtProvider.deleteDebt(debt.id!),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(type: isLendTab ? 'lend' : 'borrow'),
                ),
              );
            },
            backgroundColor: appBarColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

// Add this if ExportScreen doesn't exist yet
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.green.shade600,
      ),
      body: const Center(
        child: Text('Export Screen - Coming Soon'),
      ),
    );
  }
}

class DebtSearchDelegate extends SearchDelegate {
  final DebtProvider debtProvider;

  DebtSearchDelegate(this.debtProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = debtProvider.allDebts.where((debt) => debt.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final debt = results[index];
        return DebtPersonCard(
          debt: debt,
          onDelete: () => debtProvider.deleteDebt(debt.id!),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
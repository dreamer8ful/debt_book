import 'package:flutter/material.dart';
import 'package:debt_book/models/debt_model1.dart';
import 'package:debt_book/services/database_helper.dart';

class DebtProvider with ChangeNotifier {
  List<DebtModel> _lendList = [];
  List<DebtModel> _borrowList = [];
  
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Paid, Unpaid
  String _sortBy = 'Date';
  
  double _remainingLend = 0;
  double _remainingBorrow = 0;
  double _collectedLend = 0;
  double _collectedBorrow = 0;
  double _totalLend = 0;
  double _totalBorrow = 0;

  // GETTERS
  List<DebtModel> get lendList => _lendList;
  List<DebtModel> get borrowList => _borrowList;
  List<DebtModel> get allDebts => [..._lendList, ..._borrowList];
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;
  
  double get totalLent => _totalLend;
  double get totalBorrow => _totalBorrow;
  double get remainingLend => _remainingLend;
  double get remainingBorrow => _remainingBorrow;
  double get collectedLend => _collectedLend;
  double get collectedBorrow => _collectedBorrow;

  // FILTERED LISTS - FIXED: Calculate remainingAmount inside filter
  List<DebtModel> get filteredLendList {
    return _applyFilters(_lendList);
  }
  
  List<DebtModel> get filteredBorrowList {
    return _applyFilters(_borrowList);
  }

  // FUNCTION YA KUFILTER + SORT - FIXED VERSION
  List<DebtModel> _applyFilters(List<DebtModel> list) {
    // 1. FILTER by search and status
    var filtered = list.where((debt) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty || 
          debt.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Calculate remaining amount
      final remainingAmount = debt.amount - debt.paidAmount;
      
      // Filter by status
      bool matchesStatus = true;
      if (_filterStatus == 'Paid') {
        matchesStatus = remainingAmount <= 0;
      } else if (_filterStatus == 'Unpaid') {
        matchesStatus = remainingAmount > 0;
      }
      
      return matchesSearch && matchesStatus;
    }).toList();

    // 2. SORT
    if (_sortBy == 'Amount') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'Name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else {
      // Date - newest first (assuming date format DD-MM-YYYY)
      filtered.sort((a, b) => _parseDate(b.dateBorrowed).compareTo(_parseDate(a.dateBorrowed)));
    }
    
    return filtered;
  }

  // Helper function to parse date string for sorting
  DateTime _parseDate(String dateStr) {
    try {
      // Format: DD-MM-YYYY
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // If parsing fails, return current date
      //print('Error parsing date: $dateStr');
    }
    return DateTime(2000, 1, 1); // Default for sorting
  }

  // FUNCTIONS ZA KUBADILISHA FILTER
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }
  
  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _lendList = await DatabaseHelper.instance.getDebtsByType('lend');
    _borrowList = await DatabaseHelper.instance.getDebtsByType('borrow');
    
    // Calculate totals using remainingAmount
    _totalLend = _lendList.fold(0, (sum, debt) => sum + debt.amount);
    _totalBorrow = _borrowList.fold(0, (sum, debt) => sum + debt.amount);
    
    // Calculate remaining amounts (amount - paidAmount)
    _remainingLend = _lendList.fold(0, (sum, debt) => sum + (debt.amount - debt.paidAmount));
    _remainingBorrow = _borrowList.fold(0, (sum, debt) => sum + (debt.amount - debt.paidAmount));
    
    // Calculate collected amounts
    _collectedLend = _lendList.fold(0, (sum, debt) => sum + debt.paidAmount);
    _collectedBorrow = _borrowList.fold(0, (sum, debt) => sum + debt.paidAmount);
    
    notifyListeners();
  }

  Future<void> addDebt(DebtModel debt) async {
    await DatabaseHelper.instance.insertDebt(debt);
    await loadAllData();
  }

  Future<void> deleteDebt(int id) async {
    await DatabaseHelper.instance.deleteDebt(id);
    await loadAllData();
  }
  
  Future<void> addPayment(int id, double payAmount) async {
    await DatabaseHelper.instance.updatePaidAmount(id, payAmount);
    await loadAllData();
  }
  
  Future<void> addMoreDebt(int id, double moreAmount) async {
    await DatabaseHelper.instance.addMoreDebt(id, moreAmount);
    await loadAllData();
  }
  
  Future<void> updateDebt(DebtModel debt) async {
    await DatabaseHelper.instance.updateDebt(debt);
    await loadAllData();
  }
}
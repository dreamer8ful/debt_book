import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _currencyCodeKey = 'currencyCode';
  static const String _currencySymbolKey = 'currencySymbol';
  static const String _dateFormatKey = 'dateFormatPattern';
  static const String _passwordHashKey = 'passwordHash';
  static const String _lockEnabledKey = 'lockEnabled';

  SharedPreferences? _prefs;
  String _currencyCode = 'TZS';
  String _currencySymbol = 'TSh ';
  String _dateFormatPattern = 'dd-MM-yyyy';
  String _passwordHash = '';
  bool _lockEnabled = false;
  bool _isLocked = false;
  bool _initialized = false;

  bool get initialized => _initialized;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get dateFormatPattern => _dateFormatPattern;
  bool get lockEnabled => _lockEnabled;
  bool get hasPassword => _passwordHash.isNotEmpty;
  bool get isLocked => _lockEnabled && _isLocked;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currencyCode = _prefs!.getString(_currencyCodeKey) ?? _currencyCode;
    _currencySymbol = _prefs!.getString(_currencySymbolKey) ?? _currencySymbol;
    _dateFormatPattern = _prefs!.getString(_dateFormatKey) ?? _dateFormatPattern;
    _passwordHash = _prefs!.getString(_passwordHashKey) ?? '';
    _lockEnabled = _prefs!.getBool(_lockEnabledKey) ?? false;
    _isLocked = _lockEnabled && _passwordHash.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setCurrency({
    required String code,
    required String symbol,
  }) async {
    _currencyCode = code;
    _currencySymbol = symbol;
    await _prefs?.setString(_currencyCodeKey, code);
    await _prefs?.setString(_currencySymbolKey, symbol);
    notifyListeners();
  }

  Future<void> setDateFormat(String pattern) async {
    _dateFormatPattern = pattern;
    await _prefs?.setString(_dateFormatKey, pattern);
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    _passwordHash = _hashPassword(password);
    _lockEnabled = true;
    _isLocked = true;
    await _prefs?.setString(_passwordHashKey, _passwordHash);
    await _prefs?.setBool(_lockEnabledKey, true);
    notifyListeners();
  }

  Future<void> clearPassword() async {
    _passwordHash = '';
    _lockEnabled = false;
    _isLocked = false;
    await _prefs?.remove(_passwordHashKey);
    await _prefs?.setBool(_lockEnabledKey, false);
    notifyListeners();
  }

  void lockApp() {
    if (!_lockEnabled || _passwordHash.isEmpty) {
      return;
    }
    _isLocked = true;
    notifyListeners();
  }

  bool unlockWithPassword(String password) {
    if (!_lockEnabled || _passwordHash.isEmpty) {
      return true;
    }

    final matches = _hashPassword(password) == _passwordHash;
    if (matches) {
      _isLocked = false;
      notifyListeners();
    }
    return matches;
  }

  String formatCurrency(double amount) {
    return '$_currencySymbol${NumberFormat('#,##0', 'en_US').format(amount)}';
  }

  String formatDate(DateTime date) {
    return DateFormat(_dateFormatPattern).format(date);
  }

  String formatStoredDate(String dateText) {
    try {
      final parsed = DateFormat('dd-MM-yyyy').parseStrict(dateText);
      return formatDate(parsed);
    } catch (_) {
      return dateText;
    }
  }

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
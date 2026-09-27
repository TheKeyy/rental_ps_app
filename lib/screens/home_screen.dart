import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/db_helper.dart';
import '../models/expense_model.dart';
import '../models/rental_model.dart';
import '../models/snack_model.dart';
import '../services/alert_service.dart';
import '../services/rental_time.dart';
import '../services/settings_service.dart';
import '../services/tariff.dart';
import 'add_expense_screen.dart';
import 'add_rental_screen.dart';
import 'add_snack_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'snack_inventory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedDate;
  List<Rental> _rentalList = [];
  List<Expense> _expenseList = [];
  List<SnackOrder> _snackOrderList = [];
  Timer? _timer;
  String _timerSignature = '';
  final Set<String> _playedAlarms = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadAllData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _checkTimersForAlert();
      final sig = _buildTimerSignature();
      if (sig != _timerSignature) {
        _timerSignature = sig;
        setState(() {});
      }
    });
  }

  @override
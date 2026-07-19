import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';
import '../models/tenant_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/print_service.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Quick add name
  final _priceController = TextEditingController(); // Total price
  final _amountPaidController = TextEditingController(); // Partial payment
  String? _selectedCustomerId;

  String _selectedDuration = '1 Hour';
  String _selectedPaymentMethod = 'Cash';
  bool _isFullDay = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  StateSetter? _modalSetState;
  bool _autoPrint = true;
  bool _useAutoName = false;
  int _autoCustomerCount = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPrefs();
    });
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isAr = ref.read(isArabicProvider);
    _updateState(() {
      _autoPrint = prefs.getBool('posAutoPrint') ?? true;
      _useAutoName = prefs.getBool('posUseAutoName') ?? false;
      _autoCustomerCount = prefs.getInt('posAutoCustomerCount') ?? 1;
      _priceController.text = '10.00';
      if (_useAutoName && _selectedCustomerId == null) {
        _nameController.text = isAr ? 'العميل : $_autoCustomerCount' : 'Customer : $_autoCustomerCount';
      }
    });
  }

  Future<void> _toggleAutoName(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('posUseAutoName', val);
    if (!mounted) return;
    final isAr = ref.read(isArabicProvider);
    _updateState(() {
      _useAutoName = val;
      if (val && _selectedCustomerId == null) {
        _nameController.text = isAr ? 'العميل : $_autoCustomerCount' : 'Customer : $_autoCustomerCount';
      } else if (!val && _selectedCustomerId == null) {
        _nameController.clear();
      }
    });
  }

  Future<void> _toggleAutoPrint(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('posAutoPrint', val);
    _updateState(() => _autoPrint = val);
  }

  void _updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
      _modalSetState?.call(() {});
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _updateState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    if (_isFullDay) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) _updateState(() => _selectedTime = picked);
  }

  Future<void> _submitTransaction(bool isAr, {BuildContext? dialogContext}) async {
    if (_formKey.currentState!.validate()) {
      _updateState(() => _isLoading = true);
      try {
        int durationHours = 1;
        if (_selectedDuration == '2 Hours') durationHours = 2;
        if (_selectedDuration == '3 Hours') durationHours = 3;

        final bookingStart = _isFullDay
            ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                8,
                0,
              )
            : DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );

        final totalAmount = double.tryParse(_priceController.text) ?? 0.0;
        final amountPaid =
            double.tryParse(_amountPaidController.text) ?? totalAmount;

        String customerName = '';
        if (_selectedCustomerId != null) {
          final customersData = ref.read(customersProvider).asData?.value ?? [];
          final c = customersData.firstWhere(
            (cust) => cust['id'] == _selectedCustomerId,
            orElse: () => null,
          );
          if (c != null) customerName = c['name'];
        } else {
          customerName = _nameController.text.isEmpty
              ? (AppStrings.t('walkInCustomer', isAr))
              : _nameController.text;
          
          if (_useAutoName) {
            final prefs = await SharedPreferences.getInstance();
            _autoCustomerCount++;
            await prefs.setInt('posAutoCustomerCount', _autoCustomerCount);
            if (mounted) {
              _updateState(() {
                _nameController.text = isAr ? 'العميل : $_autoCustomerCount' : 'Customer : $_autoCustomerCount';
              });
            }
          }
        }

        await ref
            .read(bookingsProvider.notifier)
            .addBooking(
              customerName: customerName,
              customerId: _selectedCustomerId,
              startTime: bookingStart,
              durationHours: durationHours,
              isFullDay: _isFullDay,
              totalAmount: totalAmount,
              amountPaid: amountPaid,
              paymentMethod: _selectedPaymentMethod,
            );

        ref.invalidate(customersProvider);

        if (mounted) {
          final isDesktop = MediaQuery.of(context).size.width > 800;
          if (!isDesktop && dialogContext != null) {
            _modalSetState = null;
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          }

          void doPrint() {
            PrintService.printReceipt(
              isAr: isAr,
              title: AppStrings.t('receiptTitlePos', isAr),
              customerName: customerName,
              items: [
                {'name': _isFullDay ? (isAr ? 'حجز يوم كامل' : 'Full Day') : _selectedDuration, 'price': totalAmount}
              ],
              totalAmount: totalAmount,
              amountPaid: amountPaid,
              paymentMethod: _selectedPaymentMethod,
              date: bookingStart,
            );
          }

          if (_autoPrint) {
            doPrint();
          }

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.t('posBookingSuccess', isAr))),
                ],
              ),
              content: Text(AppStrings.t('posBookingSuccess', isAr)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    doPrint();
                  },
                  child: Text(AppStrings.t('printReceipt', isAr)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.t('done', isAr)),
                ),
              ],
            ),
          );

          _amountPaidController.clear();
          _updateState(() {
            _selectedCustomerId = null;
            _selectedDuration = '1 Hour';
            _isFullDay = false;
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
            _selectedPaymentMethod = 'Cash';
            _priceController.text = '10.00';
            if (_useAutoName) {
              _nameController.text = isAr ? 'العميل : $_autoCustomerCount' : 'Customer : $_autoCustomerCount';
            } else {
              _nameController.clear();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceAll('Exception: ', '');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.block,
                    color: Theme.of(context).colorScheme.error,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.t('posBookingFailed', isAr))),
                ],
              ),
              content: Text(errorMsg, style: const TextStyle(fontSize: 15)),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.t('ok', isAr)),
                ),
              ],
            ),
          );
        }
      } finally {
        _updateState(() => _isLoading = false);
      }
    }
  }

  String _formattedDate(bool isAr) {
    final now = DateTime.now();
    final diff = _selectedDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff == 0) return AppStrings.t('posToday', isAr);
    if (diff == 1) return AppStrings.t('posTomorrow', isAr);
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final customersData = ref.watch(customersProvider);
    final isAr = ref.watch(isArabicProvider);
    final isChalet = ref.read(authProvider).tenantType == TenantType.chalet;
    final s = (String key) => AppStrings.t(key, isAr);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (!isDesktop) {
          // Mobile View
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(s('posTitle')),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildScheduleList(
                context,
                bookingsAsync,
                isAr,
                s,
                isMobile: true,
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    insetPadding: const EdgeInsets.all(16),
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter modalSetState) {
                        _modalSetState = modalSetState;
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _buildForm(
                              ctx,
                              customersData,
                              isAr,
                              s,
                              isChalet,
                              isModal: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ).whenComplete(() => _modalSetState = null);
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.add,
                size: 28,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          );
        }

        // Desktop View
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('posTitle'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t('posSubtitle', isAr),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // ── LEFT: Booking Form ──
                      Container(
                        width: 450,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.02),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: SingleChildScrollView(
                          child: _buildForm(
                            context,
                            customersData,
                            isAr,
                            s,
                            isChalet,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // ── RIGHT: Today's Schedule ──
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: 0.02),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Schedule",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildScheduleList(
                                context,
                                bookingsAsync,
                                isAr,
                                s,
                                isMobile: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue customersData,
    bool isAr,
    Function(String) s,
    bool isChalet, {
    bool isModal = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fieldColor = isDark
        ? colors.surfaceContainerHighest
        : Theme.of(context).cardColor;
    final outlineColor = isDark
        ? colors.outline
        : Theme.of(context).dividerColor;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s('posNewBooking'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 8,
                  //     vertical: 4,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: isDark
                  //         ? colors.secondaryContainer
                  //         : colors.surfaceContainerHighest,
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                    // child: Text(
                    //   'Walk-in',
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.bold,
                    //     color: isDark
                    //         ? colors.onSecondaryContainer
                    //         : colors.onSurface,
                    //   ),
                    // ),
                  //),
                  if (isModal) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: s('closeBtn'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Customer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          if (!isChalet)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _selectedCustomerId,
                    decoration: InputDecoration(
                      labelText: s('SelectCustomer'),
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: fieldColor,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(s('newCustomerWalkIn')),
                      ),
                      ...(customersData.asData?.value ?? []).map((c) {
                        final isSubbed = c['hasActiveSubscription'] == true;
                        final subText = isSubbed ? (s('subscribedSuffix')) : '';
                        return DropdownMenuItem<String?>(
                          value: c['id'],
                          child: Text(
                            '${c['name']}$subText',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      _updateState(() {
                        _selectedCustomerId = val;
                        if (val != null) {
                          _nameController.clear();
                        } else if (_useAutoName) {
                          _nameController.text = isAr ? 'العميل : $_autoCustomerCount' : 'Customer : $_autoCustomerCount';
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.person_add, color: colors.primary),
                  onPressed: () =>
                      _showCreateCustomerDialog(context, ref, isAr),
                ),
              ],
            ),

          if (_selectedCustomerId == null) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                isAr ? 'ترقيم العملاء تلقائياً (العميل : 1...)' : 'Auto-number Customers',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              value: _useAutoName,
              activeColor: colors.primary,
              onChanged: _toggleAutoName,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s('posCustomerName'),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: fieldColor,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: outlineColor),
            ),
            color: fieldColor,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: colors.primary),
              title: Text(
                '${s('posDate')} ${_formattedDate(isAr)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(s('posFullDayBlock')),
            value: _isFullDay,
            activeColor: colors.primary,
            onChanged: (val) {
              _updateState(() {
                _isFullDay = val;
                if (val) {
                  _selectedDuration = 'Full Day';
                  _priceController.text = '50.00';
                } else {
                  _selectedDuration = '1 Hour';
                  _priceController.text = '10.00';
                }
              });
            },
          ),
          if (!_isFullDay) ...[
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: outlineColor),
              ),
              color: fieldColor,
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.access_time, color: colors.primary),
                title: Text(
                  '${s('posStartTime')} ${_selectedTime.format(context)}',
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: s('posDuration'),
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: fieldColor,
              ),
              items: [
                '1 Hour',
                '2 Hours',
                '3 Hours',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                _updateState(() {
                  _selectedDuration = val!;
                  if (val == '1 Hour') _priceController.text = '10.00';
                  if (val == '2 Hours') _priceController.text = '18.00';
                  if (val == '3 Hours') _priceController.text = '25.00';
                });
              },
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return isAr ? 'الرجاء إدخال السعر' : 'Please enter price';
              if (double.tryParse(value) == null) return isAr ? 'رقم غير صالح' : 'Invalid number';
              return null;
            },
            decoration: InputDecoration(
              labelText: s('totalPrice'),
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: fieldColor,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountPaidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitTransaction(isAr),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return isAr ? 'الرجاء إدخال المبلغ المدفوع' : 'Please enter amount paid';
              if (double.tryParse(value) == null) return isAr ? 'رقم غير صالح' : 'Invalid number';
              return null;
            },
            decoration: InputDecoration(
              labelText: s('amountPaidNow'),
              prefixIcon: const Icon(Icons.money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: fieldColor,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: isAr ? 'طريقة الدفع' : 'Payment Method',
              prefixIcon: const Icon(Icons.payment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: fieldColor,
            ),
            items: [
              DropdownMenuItem(value: 'Cash', child: Text(isAr ? 'كاش' : 'Cash')),
              DropdownMenuItem(value: 'Transfer', child: Text(isAr ? 'حوالة' : 'Transfer')),
            ],
            onChanged: (val) {
              if (val != null) _updateState(() => _selectedPaymentMethod = val);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(AppStrings.t('autoPrint', isAr)),
            value: _autoPrint,
            activeColor: colors.primary,
            onChanged: _toggleAutoPrint,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    _submitTransaction(isAr, dialogContext: context);
                  },
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(
              _isFullDay ? s('posReserveFullDay') : s('posRecordBooking'),
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(
    BuildContext context,
    AsyncValue bookingsAsync,
    bool isAr,
    Function(String) s, {
    required bool isMobile,
  }) {
    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        
        final filtered = bookings.where((b) {
          if (b['status'] == 1) return false; // Hide Cancelled
          final dt = DateTime.parse(b['startTime']).toLocal();
          // Keep if it's today or in the future
          return dt.isAfter(startOfToday.subtract(const Duration(seconds: 1)));
        }).toList();

        final sorted = [...filtered]
          ..sort(
            (a, b) => DateTime.parse(
              a['startTime'],
            ).compareTo(DateTime.parse(b['startTime'])),
          );
        if (sorted.isEmpty)
          return Center(
            child: Text(
              s('posNoBookings'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );

        return ListView.builder(
          shrinkWrap: !isMobile,
          physics: isMobile ? null : const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final b = sorted[i];
            final dt = DateTime.parse(b['startTime']).toLocal();
            final isFullDay = b['isFullDayBlock'] == true;
            final durationHours = b['durationHours'] ?? 1;

            final DateTime endTime = isFullDay
                ? DateTime(dt.year, dt.month, dt.day, 23, 59)
                : dt.add(
                    Duration(
                      hours: durationHours is double
                          ? durationHours.toInt()
                          : durationHours as int,
                    ),
                  );

            final now = DateTime.now();
            final isCompleted = now.isAfter(endTime);
            final isInProgress = now.isAfter(dt) && now.isBefore(endTime);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant
                                  : (isInProgress
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      if (i != sorted.length - 1)
                        Container(
                          width: 2,
                          height: 60,
                          color: Theme.of(context).dividerColor,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Timeline card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.02),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.15)
                                      : (isInProgress
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary.withValues(alpha: 0.15)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCompleted
                                      ? AppStrings.t('completed', isAr)
                                      : (isInProgress
                                            ? AppStrings.t('inProgress', isAr)
                                            : AppStrings.t('confirmed', isAr)),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCompleted
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : (isInProgress
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.secondary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isCompleted) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.cancel, size: 20, color: Theme.of(context).colorScheme.error),
                                  tooltip: isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    double feePercentage = 0.0;
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => StatefulBuilder(
                                        builder: (ctx, setStateDialog) => AlertDialog(
                                          title: Text(isAr ? 'إلغاء الحجز' : 'Cancel Booking'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(isAr ? 'هل تريد فرض رسوم إلغاء على العميل؟ سيتم خصم هذه النسبة من المبلغ المدفوع كأرباح.' : 'Do you want to apply a cancellation fee? This percentage will be deducted from the paid amount as revenue.'),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                alignment: WrapAlignment.center,
                                                children: [0.0, 10.0, 20.0, 30.0, 50.0].map((fee) {
                                                  final isSelected = feePercentage == fee;
                                                  return ChoiceChip(
                                                    label: Text(fee == 0 ? (isAr ? 'بدون خصم' : 'No Fee') : '${fee.toInt()}%'),
                                                    selected: isSelected,
                                                    onSelected: (selected) {
                                                      if (selected) setStateDialog(() => feePercentage = fee);
                                                    },
                                                    selectedColor: Theme.of(context).colorScheme.errorContainer,
                                                  );
                                                }).toList(),
                                              )
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: Text(AppStrings.t('cancel', isAr)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                                foregroundColor: Theme.of(context).colorScheme.onError,
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: Text(isAr ? 'تأكيد الإلغاء' : 'Confirm Cancel'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    
                                    if (confirm == true) {
                                      try {
                                        await ref.read(bookingsProvider.notifier).cancelBooking(b['id'], feePercentage);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(isAr ? 'تم إلغاء الحجز بنجاح' : 'Booking cancelled successfully')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFullDay
                                ? AppStrings.t('posFullDayBlock', isAr)
                                : AppStrings.t('hourlyBooking', isAr),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b['customerName'] ?? 'Walk-in',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateCustomerDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? selectedDob;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final dobStr = selectedDob != null
              ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}"
              : (AppStrings.t('notSet', isAr));
          return AlertDialog(
            title: Text(AppStrings.t('customerAddNew', isAr)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('customerName', isAr),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('customerPhone', isAr),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  leading: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(AppStrings.t('customerDOB', isAr)),
                  subtitle: Text(
                    dobStr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => selectedDob = date);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.t('cancel', isAr)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;
                        setState(() => isLoading = true);
                        try {
                          await ref
                              .read(customersProvider.notifier)
                              .addCustomer(
                                nameController.text.trim(),
                                phoneController.text.trim(),
                                selectedDob,
                              );
                          ref.invalidate(customersProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.t('save', isAr)),
              ),
            ],
          );
        },
      ),
    );
  }
}

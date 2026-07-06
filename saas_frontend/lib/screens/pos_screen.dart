import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Quick add name
  final _priceController= TextEditingController(); // Total price
  final _amountPaidController = TextEditingController(); // Partial payment
  String? _selectedCustomerId;

  String    _selectedDuration = '1 Hour';
  bool      _isFullDay        = false;
  bool      _isLoading        = false;
  DateTime  _selectedDate     = DateTime.now();
  TimeOfDay _selectedTime     = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    if (_isFullDay) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitTransaction(bool isAr) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        int durationHours = 1;
        if (_selectedDuration == '2 Hours') durationHours = 2;
        if (_selectedDuration == '3 Hours') durationHours = 3;

        final bookingStart = _isFullDay
            ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 8, 0)
            : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
                _selectedTime.hour, _selectedTime.minute);

        final totalAmount = double.tryParse(_priceController.text) ?? 0.0;
        final amountPaid = double.tryParse(_amountPaidController.text) ?? totalAmount;

        String customerName = '';
        if (_selectedCustomerId != null) {
           final customersData = ref.read(customersProvider).asData?.value ?? [];
           final c = customersData.firstWhere((cust) => cust['id'] == _selectedCustomerId, orElse: () => null);
           if (c != null) customerName = c['name'];
        } else {
           customerName = _nameController.text.isEmpty
                  ? (isAr ? 'عميل مباشر' : 'Walk-in Customer')
                  : _nameController.text;
        }

        await ref.read(bookingsProvider.notifier).addBooking(
              customerName: customerName,
              customerId: _selectedCustomerId,
              startTime: bookingStart,
              durationHours: durationHours,
              isFullDay: _isFullDay,
              totalAmount: totalAmount,
              amountPaid: amountPaid,
            );
            
        ref.invalidate(customersProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t('posBookingSuccess', isAr)),
              backgroundColor: Colors.green,
            ),
          );
          _nameController.clear();
          _priceController.clear();
          _amountPaidController.clear();
          setState(() {
            _selectedCustomerId = null;
            _selectedDuration = '1 Hour';
            _isFullDay  = false;
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
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
                  const Icon(Icons.block, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('posBookingFailed', isAr)),
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _formattedDate(bool isAr) {
    final now  = DateTime.now();
    final diff = _selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return AppStrings.t('posToday', isAr);
    if (diff == 1) return AppStrings.t('posTomorrow', isAr);
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop     = MediaQuery.of(context).size.width > 800;
    final bookingsAsync = ref.watch(bookingsProvider);
    final customersData = ref.watch(customersProvider);
    final isAr          = ref.watch(isArabicProvider);
    final s             = (String key) => AppStrings.t(key, isAr);

    return Scaffold(
      appBar: AppBar(title: Text(s('posTitle')), elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: Booking Form ────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, spreadRadius: 2)
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s('posNewBooking'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        // Customer Selection
                        Row(
                          children: [
                            Expanded(
                              child: DropdownMenu<String?>(
                                expandedInsets: EdgeInsets.zero,
                                enableFilter: true,
                                leadingIcon: const Icon(Icons.search),
                                label: Text(isAr ? 'بحث عن عميل' : 'Search Customer'),
                                inputDecorationTheme: const InputDecorationTheme(
                                  border: OutlineInputBorder(),
                                ),
                                dropdownMenuEntries: [
                                  DropdownMenuEntry<String?>(
                                    value: null,
                                    label: isAr ? 'عميل جديد (أدخل اسمه أدناه)' : 'New Customer / Walk-in',
                                  ),
                                  ...(customersData.asData?.value ?? []).map((c) {
                                    final isSubbed = c['hasActiveSubscription'] == true;
                                    final subText = isSubbed ? (isAr ? ' (مشترك)' : ' (Subscribed)') : '';
                                    return DropdownMenuEntry<String?>(
                                      value: c['id'],
                                      label: '${c['name']}$subText',
                                    );
                                  }),
                                ],
                                onSelected: (val) => setState(() => _selectedCustomerId = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_add, color: Colors.blue),
                              tooltip: AppStrings.t('customerAddNew', isAr),
                              onPressed: () {
                                _showCreateCustomerDialog(context, ref, isAr);
                              },
                            ),
                          ],
                        ),
                        if (_selectedCustomerId == null) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: s('posCustomerName'),
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Date Picker
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          leading: const Icon(Icons.calendar_today, color: Colors.blue),
                          title: Text('${s('posDate')} ${_formattedDate(isAr)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(s('posChangeDate')),
                          trailing: const Icon(Icons.edit, size: 18),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 16),

                        // Full Day toggle
                        SwitchListTile(
                          title: Text(s('posFullDayBlock')),
                          subtitle: Text(s('posFullDaySubtitle')),
                          value: _isFullDay,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            setState(() {
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
                        const SizedBox(height: 8),

                        // Time & Duration (hidden if full day)
                        if (!_isFullDay) ...[
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            leading: const Icon(Icons.access_time, color: Colors.blue),
                            title: Text('${s('posStartTime')} ${_selectedTime.format(context)}'),
                            trailing: const Icon(Icons.edit, size: 18),
                            onTap: _pickTime,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDuration,
                            decoration: InputDecoration(
                              labelText: s('posDuration'),
                              prefixIcon: const Icon(Icons.timer),
                              border: const OutlineInputBorder(),
                            ),
                            items: ['1 Hour', '2 Hours', '3 Hours']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDuration = val!;
                                if (val == '1 Hour') _priceController.text = '10.00';
                                if (val == '2 Hours') _priceController.text = '18.00';
                                if (val == '3 Hours') _priceController.text = '25.00';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Price
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: isAr ? 'إجمالي السعر' : 'Total Price',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? s('required') : null,
                        ),
                        const SizedBox(height: 16),

                        // Partial Payment
                        TextFormField(
                          controller: _amountPaidController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: isAr ? 'المبلغ المدفوع الان' : 'Amount Paid Now',
                            prefixIcon: const Icon(Icons.money),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _submitTransaction(isAr),
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.receipt_long),
                          label: Text(
                            _isFullDay ? s('posReserveFullDay') : s('posRecordBooking'),
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── RIGHT: Recent Bookings ────────────────────────────────────────
            if (isDesktop) ...[
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s('posRecentBookings'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Expanded(
                        child: bookingsAsync.when(
                          data: (bookings) {
                            final sorted = [...bookings]..sort((a, b) =>
                                DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
                            if (sorted.isEmpty) {
                              return Center(
                                  child: Text(s('posNoBookings'),
                                      style: const TextStyle(color: Colors.grey)));
                            }
                            return ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (context, i) {
                                final b        = sorted[i];
                                final dt       = DateTime.parse(b['startTime']).toLocal();
                                final isFullDay= b['isFullDayBlock'] == true;
                                return ListTile(
                                  leading: Icon(isFullDay ? Icons.calendar_month : Icons.timer,
                                      color: isFullDay ? Colors.orange : Colors.blue),
                                  title: Text(b['customerName'] ?? 'Walk-in'),
                                  subtitle: Text(
                                      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
                                  trailing: isFullDay
                                      ? Chip(label: Text(s('calFullDay')))
                                      : null,
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCustomerDialog(BuildContext context, WidgetRef ref, bool isAr) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    DateTime? selectedDob;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final dobStr = selectedDob != null ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}" : (isAr ? 'لم يحدد' : 'Not Set');
        return AlertDialog(
          title: Text(AppStrings.t('customerAddNew', isAr)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: AppStrings.t('customerName', isAr), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: AppStrings.t('customerPhone', isAr), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(AppStrings.t('customerDOB', isAr)),
                subtitle: Text(dobStr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t('cancel', isAr))),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setState(() => isLoading = true);
                try {
                  await ref.read(customersProvider.notifier).addCustomer(nameController.text.trim(), phoneController.text.trim(), selectedDob);
                  ref.invalidate(customersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppStrings.t('save', isAr)),
            ),
          ],
        );
      }),
    );
  }
}

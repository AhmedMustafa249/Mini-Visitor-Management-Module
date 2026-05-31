import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/visitor_cubit.dart';
import '../cubit/visitor_state.dart';
import '../data/visitor_repository.dart';
import '../../auth/cubit/auth_cubit.dart';

class AddVisitorScreen extends StatelessWidget {
  const AddVisitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthCubit>().currentUser!.token;
    return BlocProvider(
      create: (_) => VisitorCubit(repository: VisitorRepository(token: token)),
      child: const _AddVisitorForm(),
    );
  }
}

class _AddVisitorForm extends StatefulWidget {
  const _AddVisitorForm();

  @override
  State<_AddVisitorForm> createState() => _AddVisitorFormState();
}

class _AddVisitorFormState extends State<_AddVisitorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  DateTime? _selectedDate;
  bool _dateError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = false;
      });
    }
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    final formatted = DateFormat('EEE, d MMM yyyy').format(date);
    if (diff == 0) return '$formatted (Today)';
    if (diff == 1) return '$formatted (Tomorrow)';
    return formatted;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (_selectedDate == null) {
      setState(() => _dateError = true);
    }
    if (!formValid || _selectedDate == null) return;

    final success = await context.read<VisitorCubit>().addVisitor(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          visitDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Visitor added successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Visitor'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<VisitorCubit, VisitorState>(
        listener: (context, state) {
          if (state is VisitorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_alt_1, size: 56, color: Color(0xFF1565C0)),
                const SizedBox(height: 8),
                Text(
                  'Register a new visitor',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Ahmed Ali',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'e.g. 0551234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(v.trim())) {
                      return 'Enter a valid mobile number (9–15 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Visit Date',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      errorText: _dateError ? 'Visit date is required' : null,
                      suffixIcon: _selectedDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() {
                                _selectedDate = null;
                                _dateError = false;
                              }),
                            )
                          : null,
                    ),
                    child: Text(
                      _selectedDate != null
                          ? _relativeDate(_selectedDate!)
                          : 'Tap to select a date',
                      style: TextStyle(
                        color: _selectedDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<VisitorCubit, VisitorState>(
                  builder: (context, state) {
                    final isAdding = state is VisitorAdding;
                    return FilledButton.icon(
                      onPressed: isAdding ? null : _submit,
                      icon: isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        isAdding ? 'Adding...' : 'Add Visitor',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

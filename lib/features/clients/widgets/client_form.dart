/// Provides the create and edit form for clients.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../l10n/app_localizations.dart';

/// Asynchronous callback invoked after the form has been validated.
typedef ClientSavedCallback = Future<void> Function(Client client);

/// A reusable client create/edit form.
class ClientForm extends ConsumerStatefulWidget {
  /// Creates a form seeded with [initialClient], or defaults for a new client.
  const ClientForm({
    required this.initialClient,
    required this.onSaved,
    required this.onCancel,
    super.key,
  });

  /// Existing client when editing; null when creating.
  final Client? initialClient;

  /// Saves the validated client.
  final ClientSavedCallback onSaved;

  /// Cancels form entry.
  final VoidCallback onCancel;

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late final TextEditingController _dobController;
  late ClientRole _role;
  late Gender _gender;
  DateTime? _dob;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = widget.initialClient;
    _nameController = TextEditingController(text: client?.name ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _notesController = TextEditingController(text: client?.notes ?? '');
    _dob = client?.dob;
    _dobController = TextEditingController(
      text: _dob == null ? '' : DateFormat('yyyy-MM-dd').format(_dob!),
    );
    _role = client?.role ?? ClientRole.holder;
    _gender = client?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _dob ?? DateTime(now.year - 30, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected != null && mounted) {
      setState(() {
        _dob = selected;
        _dobController.text = DateFormat('yyyy-MM-dd').format(selected);
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    final dateOfBirth = _dob;
    if (dateOfBirth == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final client = widget.initialClient;
    final savedClient = client == null
        ? Client(
            role: _role,
            name: _nameController.text.trim(),
            gender: _gender,
            dob: dateOfBirth,
            phone: _optionalValue(_phoneController.text),
            email: _optionalValue(_emailController.text),
            notes: _optionalValue(_notesController.text),
            createdAt: null,
            updatedAt: null,
            archivedAt: null,
          )
        : client.copyWith(
            role: _role,
            name: _nameController.text.trim(),
            gender: _gender,
            dob: dateOfBirth,
            phone: _optionalValue(_phoneController.text),
            email: _optionalValue(_emailController.text),
            notes: _optionalValue(_notesController.text),
          );

    try {
      await widget.onSaved(savedClient);
    } on Exception {
      _showSaveError(l10n);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSaveError(AppLocalizations l10n) {
    if (mounted) {
      setState(() => _error = l10n.client_form_error_save);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.client_form_error_save)));
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          DropdownButtonFormField<ClientRole>(
            initialValue: _role,
            decoration: InputDecoration(labelText: l10n.client_role),
            items: <DropdownMenuItem<ClientRole>>[
              DropdownMenuItem(
                value: ClientRole.holder,
                child: Text(l10n.client_role_holder),
              ),
              DropdownMenuItem(
                value: ClientRole.insured,
                child: Text(l10n.client_role_insured),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (ClientRole? value) {
                    if (value != null) {
                      setState(() => _role = value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.client_name),
            validator: (String? value) => value == null || value.trim().isEmpty
                ? l10n.client_form_error_name_required
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            decoration: InputDecoration(labelText: l10n.client_gender),
            items: <DropdownMenuItem<Gender>>[
              DropdownMenuItem(
                value: Gender.male,
                child: Text(l10n.gender_male),
              ),
              DropdownMenuItem(
                value: Gender.female,
                child: Text(l10n.gender_female),
              ),
              DropdownMenuItem(
                value: Gender.other,
                child: Text(l10n.gender_other),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (Gender? value) {
                    if (value != null) {
                      setState(() => _gender = value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            enabled: !_isSaving,
            onTap: _selectDate,
            decoration: InputDecoration(
              labelText: l10n.client_dob,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            validator: (String? value) =>
                _dob == null ? l10n.client_form_error_dob_required : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            enabled: !_isSaving,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.client_phone),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.client_email),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            enabled: !_isSaving,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.client_notes),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isSaving ? null : widget.onCancel,
                child: Text(l10n.client_form_cancel),
              ),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.client_form_saving),
                        ],
                      )
                    : Text(l10n.client_form_save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

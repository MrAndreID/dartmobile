import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/user.dart';
import '../error_message.dart';
import '../providers/user_providers.dart';

/// Create or edit a user.
///
/// When [user] is null the page is in "create" mode; otherwise it is prefilled
/// for editing. Emails are managed as a dynamic list of text fields.
class UserFormPage extends ConsumerStatefulWidget {
  const UserFormPage({super.key, this.user});

  final User? user;

  bool get isEditing => user != null;

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<TextEditingController> _emailControllers;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    final existingEmails =
        widget.user?.emails.map((e) => e.email).toList() ?? const [];
    _emailControllers = existingEmails.isEmpty
        ? [TextEditingController()]
        : existingEmails.map((e) => TextEditingController(text: e)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEmailField() {
    setState(() => _emailControllers.add(TextEditingController()));
  }

  void _removeEmailField(int index) {
    setState(() {
      _emailControllers.removeAt(index).dispose();
    });
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final emails = _emailControllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    final repository = ref.read(userRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repository.updateUser(
          id: widget.user!.id,
          name: name,
          emails: emails,
        );
      } else {
        await repository.createUser(name: name, emails: emails);
      }

      // Refresh the list so it reflects the change on return.
      await ref.read(userListControllerProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'User updated' : 'User created'),
        ),
      );
      // Pop back to the list; fall back to the named route on deep links.
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.userList);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${messageForError(error)}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit user' : 'New user'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoutes.userList),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emails', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addEmailField,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildEmailFields(),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(widget.isEditing ? 'Save changes' : 'Create user'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailFields() {
    return List.generate(_emailControllers.length, (index) {
      final canRemove = _emailControllers.length > 1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailControllers[index],
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email ${index + 1}'),
                validator: _validateEmail,
              ),
            ),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () => _removeEmailField(index),
              ),
          ],
        ),
      );
    });
  }
}

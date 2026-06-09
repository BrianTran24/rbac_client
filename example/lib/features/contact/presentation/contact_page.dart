import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'contact_cubit.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactCubit, ContactState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<ContactCubit>().add(
                          name: _nameController.text,
                          phone: _phoneController.text,
                        );
                        _nameController.clear();
                        _phoneController.clear();
                      },
                      child: const Text('Add contact'),
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                context.read<ContactCubit>().remove(item.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

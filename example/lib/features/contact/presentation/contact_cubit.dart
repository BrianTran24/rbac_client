import 'package:bloc/bloc.dart';
import 'package:rbac_client/rbac.dart';

import '../domain/contact_item.dart';
import '../domain/contact_repository.dart';

class ContactState {
  const ContactState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ContactItem> items;
  final bool isLoading;
  final String? error;

  ContactState copyWith({
    List<ContactItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ContactState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ContactCubit extends Cubit<ContactState> {
  ContactCubit(this._repository) : super(const ContactState());

  final ContactRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await _repository.fetchContacts();
      emit(state.copyWith(items: items, isLoading: false, clearError: true));
    } on ForbiddenException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    }
  }

  Future<void> add({required String name, required String phone}) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) return;
    try {
      await _repository.addContact(name: name.trim(), phone: phone.trim());
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _repository.deleteContact(id);
      await load();
    } on ForbiddenException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}

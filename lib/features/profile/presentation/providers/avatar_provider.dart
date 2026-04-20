import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/avatar_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AvatarState {
  final bool uploading;
  final bool deleting;
  final double? uploadProgress;
  final Object? error;

  const AvatarState({
    this.uploading = false,
    this.deleting = false,
    this.uploadProgress,
    this.error,
  });

  AvatarState copyWith({
    bool? uploading,
    bool? deleting,
    double? uploadProgress,
    Object? error,
  }) {
    return AvatarState(
      uploading: uploading ?? this.uploading,
      deleting: deleting ?? this.deleting,
      // Explicit null clears the progress field.
      uploadProgress: uploadProgress,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AvatarNotifier extends StateNotifier<AvatarState> {
  final AvatarRepository _repository;
  final AuthNotifier _authNotifier;

  AvatarNotifier({
    required AvatarRepository repository,
    required AuthNotifier authNotifier,
  })  : _repository = repository,
        _authNotifier = authNotifier,
        super(const AvatarState());

  /// Uploads the avatar bytes and updates [authStateProvider] on success.
  ///
  /// Shows optimistic loading and rolls back on error by emitting the error
  /// into state (callers should read it and show a SnackBar).
  Future<bool> upload(Uint8List bytes, String filename) async {
    state = state.copyWith(uploading: true, uploadProgress: 0.0, error: null);
    try {
      final result = await _repository.upload(
        bytes: bytes,
        filename: filename,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(
              uploading: true,
              uploadProgress: sent / total,
            );
          }
        },
      );

      // Propagate the new URLs into the global auth state so every widget
      // that reads user.profileImageUrl / thumbnailUrl updates immediately.
      final currentUser = _authNotifier.state.user;
      if (currentUser != null) {
        _authNotifier.updateUser(
          currentUser.copyWith(
            profileImageUrl: result.url,
            thumbnailUrl: result.thumb,
          ),
        );
      }

      state = const AvatarState();
      return true;
    } on ApiException catch (e) {
      state = AvatarState(error: e);
      return false;
    } catch (e) {
      state = AvatarState(error: e);
      return false;
    }
  }

  /// Deletes the avatar and clears the URL from [authStateProvider].
  Future<bool> delete() async {
    state = state.copyWith(deleting: true, error: null);
    try {
      await _repository.delete();

      final currentUser = _authNotifier.state.user;
      if (currentUser != null) {
        _authNotifier.updateUser(
          currentUser.copyWith(
            // Passing null explicitly via copyWith clears the fields.
            profileImageUrl: null,
            thumbnailUrl: null,
          ),
        );
      }

      state = const AvatarState();
      return true;
    } on ApiException catch (e) {
      state = AvatarState(error: e);
      return false;
    } catch (e) {
      state = AvatarState(error: e);
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final avatarProvider =
    StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  return AvatarNotifier(
    repository: ref.watch(avatarRepositoryProvider),
    authNotifier: ref.watch(authStateProvider.notifier),
  );
});

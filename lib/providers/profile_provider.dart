import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return ProfileModel.fromJson(data);
});

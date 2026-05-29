import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'auth_provider.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('categories')
      .select()
      .eq('is_active', true)
      .order('name');

  return (data as List)
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

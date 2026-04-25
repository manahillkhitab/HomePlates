import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class CategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void update(String value) => state = value;
}

final categoryProvider = NotifierProvider<CategoryNotifier, String>(
  CategoryNotifier.new,
);

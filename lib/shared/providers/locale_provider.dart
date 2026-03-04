import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';

/// Holds the current language code ('en' or 'de').
/// Watching this provider triggers a full UI rebuild when the language changes.
final localeProvider = StateProvider<String>((ref) => S.langCode);

/// Helper to switch language at runtime.
/// Updates [S.current] + persists + updates the provider.
Future<void> switchLocale(WidgetRef ref, String langCode) async {
  await S.setLocale(langCode);
  ref.read(localeProvider.notifier).state = langCode;
}

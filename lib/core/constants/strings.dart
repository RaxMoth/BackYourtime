import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

/// Centralised user-facing strings with locale support.
/// German (de) uses [_De], everything else falls back to English [_En].
///
/// Call [S.init] once at app start (before `runApp`).
/// Access via the top-level [S] instance, e.g. `S.current.appName`.
abstract class S {
  S._();

  static const _kLocaleKey = 'app_locale';

  // ── Singleton access ─────────────────────────────────────────────────────
  static late S current;

  /// Must be called once before `runApp`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLocaleKey);
      if (saved != null) {
        current = saved == 'de' ? _De() : _En();
      } else {
        final lang = Platform.localeName.split('_').first.toLowerCase();
        current = lang == 'de' ? _De() : _En();
      }
    } catch (_) {
      current = _En();
    }
  }

  /// Change locale at runtime and persist the choice.
  static Future<void> setLocale(String langCode) async {
    current = langCode == 'de' ? _De() : _En();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, langCode);
    } catch (_) {
      // best-effort persist
    }
  }

  /// The active language code ('en' or 'de').
  static String get langCode => current is _De ? 'de' : 'en';

  /// Whether the active locale is German.
  static bool get isGerman => current is _De;

  // ── General ──────────────────────────────────────────────────────────────
  String get appName;
  String get cancel;
  String get delete;
  String get create;
  String get untitled;
  String errorGeneric(Object e);

  // ── Dashboard ────────────────────────────────────────────────────────────
  String get profilesSectionTitle;
  String get noProfilesYet;
  String get noProfilesTapPlus;
  String get noAppsWarning;

  // ── Summary Card ─────────────────────────────────────────────────────────
  String get allShieldsActive;
  String someShieldsActive(int active, int total);
  String get noProfiles;
  String get shieldsInactive;
  String get blockingDistractingApps;
  String get createProfileToStart;
  String get noProfilesAreActive;

  // ── Stats Row ────────────────────────────────────────────────────────────
  String get timeSaved;
  String get today;
  String get dailyAvg;
  String get saved;
  String get last7Days;
  String get appBreakdown;
  String moreApps(int count);

  // ── Create Profile Sheet ─────────────────────────────────────────────────
  String get newProfile;
  String get createProfileDescription;
  String get profileNameHint;

  // ── Settings ─────────────────────────────────────────────────────────────
  String get settings;
  String get changePin;
  String get changePinSubtitle;
  String get languageLabel;
  String get languageEnglish;
  String get languageGerman;

  // ── Profile Detail ───────────────────────────────────────────────────────
  String get profileNamePlaceholder;
  String get sectionColor;
  String get sectionIcon;
  String get sectionApps;
  String get sectionUsageStats;
  String get sectionBlockRules;
  String get blockRulesDescription;
  String appsSelected(int count);
  String get selectAppsToBlock;

  // ── Block Rules ──────────────────────────────────────────────────────────
  String get scheduleTitle;
  String get scheduleDescription;
  String get scheduleStart;
  String get scheduleEnd;

  String get usageLimitTitle;
  String get usageLimitDescription;
  String get dailyLimit;
  String get sliderMin;
  String get sliderMax;

  String get taskModeTitle;
  String get taskModeDescription;

  // ── Activate / Deactivate ────────────────────────────────────────────────
  String get activateShield;
  String get deactivateShield;
  String get selectAppsToActivate;
  String get settingsLockedWhileActive;
  String get tasksResetDaily;

  // ── Lock / Unlock indicator ──────────────────────────────────────────────
  String get appsLocked;
  String get appsUnlocked;

  // ── Requirement reasons (used by entity) ─────────────────────────────────
  String get reasonManualMode;
  String get reasonInsideSchedule;
  String reasonTasksRemaining(int remaining);
  String get reasonAllMet;

  // ── Subtitle helpers (used by entity) ────────────────────────────────────
  String get noAppsSelected;
  String subtitleApps(int count);
  String subtitleUsageLimit(int minutes);
  String subtitleTasks(int done, int total);
  String get subtitleManual;
  /// Format "HH:mm" for schedule times in subtitle. German uses " Uhr" suffix.
  String subtitleScheduleRange(String start, String end);

  // ── Delete Profile Dialog ────────────────────────────────────────────────
  String get deleteProfile;
  String deleteProfileConfirm(String name);

  // ── Task List ────────────────────────────────────────────────────────────
  String get tasks;
  String taskProgress(int done, int total);
  String get addTaskHint;
  String get allTasksDoneNote;
  String tasksRemainingNote(int remaining);
  String get emptyTasksHint;

  // ── PIN Setup Dialog ─────────────────────────────────────────────────────
  String get setPinTitle;
  String get setPinDescription;
  String get enterPin;
  String get confirmPin;
  String get savePin;
  String get pinTooShort;
  String get pinsMismatch;

  // ── Timer + PIN Deactivation Dialog ──────────────────────────────────────
  String get coolingDown;
  String get enterPinToDeactivate;
  String get confirmDeactivation;
  String get deactivateAction;
  String get areYouSureDeactivate;
  String get cooldownDescription;
  String get enterTrustedPersonPin;
  String get pinLabel;
  String get enterYourPin;
  String get incorrectPin;

  // ── Day labels ───────────────────────────────────────────────────────────
  List<String> get dayLabels;
}

// ═══════════════════════════════════════════════════════════════════════════
// ── English (default) ──────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _En extends S {
  _En() : super._();

  @override String get appName => 'Unspend';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get create => 'Create';
  @override String get untitled => 'Untitled';
  @override String errorGeneric(Object e) => 'Error: $e';

  @override String get profilesSectionTitle => 'Profiles';
  @override String get noProfilesYet => 'No profiles yet';
  @override String get noProfilesTapPlus => 'Tap + to create your first blocking profile.';
  @override String get noAppsWarning => 'No apps in this group — select apps first';

  @override String get allShieldsActive => 'All Shields Active';
  @override String someShieldsActive(int active, int total) => '$active of $total Active';
  @override String get noProfiles => 'No Profiles';
  @override String get shieldsInactive => 'Shields Inactive';
  @override String get blockingDistractingApps => 'Blocking distracting apps';
  @override String get createProfileToStart => 'Create a profile to get started';
  @override String get noProfilesAreActive => 'No profiles are active';

  @override String get timeSaved => 'Time Saved';
  @override String get today => 'Today';
  @override String get dailyAvg => 'Daily Avg';
  @override String get saved => 'Saved';
  @override String get last7Days => 'Last 7 Days';
  @override String get appBreakdown => 'App Breakdown';
  @override String moreApps(int count) => '+$count more apps';

  @override String get newProfile => 'New Profile';
  @override String get createProfileDescription => 'Create a group of apps with its own blocking rules.';
  @override String get profileNameHint => 'e.g. Social Media, Games…';

  @override String get settings => 'Settings';
  @override String get changePin => 'Change PIN';
  @override String get changePinSubtitle => 'Trusted-person deactivation PIN';
  @override String get languageLabel => 'Language';
  @override String get languageEnglish => 'English';
  @override String get languageGerman => 'German';

  @override String get profileNamePlaceholder => 'Profile Name';
  @override String get sectionColor => 'Color';
  @override String get sectionIcon => 'Icon';
  @override String get sectionApps => 'Apps';
  @override String get sectionUsageStats => 'Usage Stats';
  @override String get sectionBlockRules => 'Block Rules';
  @override String get blockRulesDescription => 'Combine any rules below. With none enabled, use Activate Shield for manual control.';
  @override String appsSelected(int count) => '$count apps selected';
  @override String get selectAppsToBlock => 'Select Apps to Block';

  @override String get scheduleTitle => 'Schedule';
  @override String get scheduleDescription => 'Hard-block during a daily time window';
  @override String get scheduleStart => 'Start';
  @override String get scheduleEnd => 'End';

  @override String get usageLimitTitle => 'Usage Limit';
  @override String get usageLimitDescription => 'Soft-block after a daily screen-time budget';
  @override String get dailyLimit => 'Daily Limit';
  @override String get sliderMin => '5 min';
  @override String get sliderMax => '3 hrs';

  @override String get taskModeTitle => 'Task Mode';
  @override String get taskModeDescription => 'Block until all tasks are completed';

  @override String get activateShield => 'Activate Shield';
  @override String get deactivateShield => 'Deactivate Shield';
  @override String get selectAppsToActivate => 'Select Apps to Activate';
  @override String get settingsLockedWhileActive => 'Settings are locked while the shield is active. Deactivate to make changes.';
  @override String get tasksResetDaily => 'Tasks reset each day.';

  @override String get appsLocked => 'Apps blocked';
  @override String get appsUnlocked => 'Requirements met — apps accessible';

  @override String get reasonManualMode => 'Manual mode — deactivate to unlock';
  @override String get reasonInsideSchedule => 'Inside schedule window';
  @override String reasonTasksRemaining(int r) => '$r task${r == 1 ? '' : 's'} remaining';
  @override String get reasonAllMet => 'All requirements met — apps accessible';

  @override String get noAppsSelected => 'No apps selected';
  @override String subtitleApps(int count) => '$count apps';
  @override String subtitleUsageLimit(int minutes) => '${minutes}min limit';
  @override String subtitleTasks(int done, int total) => '$done/$total tasks';
  @override String get subtitleManual => 'Manual';
  @override String subtitleScheduleRange(String start, String end) => '$start–$end';

  @override String get deleteProfile => 'Delete Profile';
  @override String deleteProfileConfirm(String name) => 'Delete "$name"? This cannot be undone.';

  @override String get tasks => 'Tasks';
  @override String taskProgress(int done, int total) => '$done / $total';
  @override String get addTaskHint => 'Add a task…';
  @override String get allTasksDoneNote => 'All tasks done!';
  @override String tasksRemainingNote(int r) => '$r task${r == 1 ? '' : 's'} remaining to unlock';
  @override String get emptyTasksHint => 'Add tasks that must be completed before apps unlock.';

  @override String get setPinTitle => 'Set Deactivation PIN';
  @override String get setPinDescription => 'Hand your phone to a trusted person.\nThey set a PIN that is required to deactivate any shield.';
  @override String get enterPin => 'Enter PIN';
  @override String get confirmPin => 'Confirm PIN';
  @override String get savePin => 'Save PIN';
  @override String get pinTooShort => 'PIN must be at least 4 characters';
  @override String get pinsMismatch => 'PINs do not match';

  @override String get coolingDown => 'Cooling Down…';
  @override String get enterPinToDeactivate => 'Enter PIN to Deactivate';
  @override String get confirmDeactivation => 'Confirm Deactivation';
  @override String get deactivateAction => 'Deactivate';
  @override String get areYouSureDeactivate => 'Are you sure you want to deactivate?';
  @override String get cooldownDescription => 'Take a moment to reconsider.\nThe shield will be deactivatable after the timer.';
  @override String get enterTrustedPersonPin => 'Enter the PIN set by your trusted person.';
  @override String get pinLabel => 'PIN';
  @override String get enterYourPin => 'Enter your PIN';
  @override String get incorrectPin => 'Incorrect PIN';

  @override List<String> get dayLabels => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Deutsch ────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _De extends S {
  _De() : super._();

  @override String get appName => 'Unspend';
  @override String get cancel => 'Abbrechen';
  @override String get delete => 'Löschen';
  @override String get create => 'Erstellen';
  @override String get untitled => 'Unbenannt';
  @override String errorGeneric(Object e) => 'Fehler: $e';

  @override String get profilesSectionTitle => 'Profile';
  @override String get noProfilesYet => 'Noch keine Profile';
  @override String get noProfilesTapPlus => 'Tippe auf +, um dein erstes Blockier-Profil zu erstellen.';
  @override String get noAppsWarning => 'Keine Apps in dieser Gruppe — wähle zuerst Apps aus';

  @override String get allShieldsActive => 'Alle Schilde aktiv';
  @override String someShieldsActive(int active, int total) => '$active von $total aktiv';
  @override String get noProfiles => 'Keine Profile';
  @override String get shieldsInactive => 'Schilde inaktiv';
  @override String get blockingDistractingApps => 'Ablenkende Apps werden blockiert';
  @override String get createProfileToStart => 'Erstelle ein Profil, um loszulegen';
  @override String get noProfilesAreActive => 'Keine Profile sind aktiv';

  @override String get timeSaved => 'Zeit gespart';
  @override String get today => 'Heute';
  @override String get dailyAvg => 'Tagesschnitt';
  @override String get saved => 'Gespart';
  @override String get last7Days => 'Letzte 7 Tage';
  @override String get appBreakdown => 'App-Aufschlüsselung';
  @override String moreApps(int count) => '+$count weitere Apps';

  @override String get newProfile => 'Neues Profil';
  @override String get createProfileDescription => 'Erstelle eine Gruppe von Apps mit eigenen Blockier-Regeln.';
  @override String get profileNameHint => 'z.\u202FB. Social Media, Spiele…';

  @override String get settings => 'Einstellungen';
  @override String get changePin => 'PIN ändern';
  @override String get changePinSubtitle => 'Vertrauensperson-Deaktivierungs-PIN';
  @override String get languageLabel => 'Sprache';
  @override String get languageEnglish => 'Englisch';
  @override String get languageGerman => 'Deutsch';

  @override String get profileNamePlaceholder => 'Profilname';
  @override String get sectionColor => 'Farbe';
  @override String get sectionIcon => 'Symbol';
  @override String get sectionApps => 'Apps';
  @override String get sectionUsageStats => 'Nutzungsstatistiken';
  @override String get sectionBlockRules => 'Blockier-Regeln';
  @override String get blockRulesDescription => 'Kombiniere beliebige Regeln. Ohne aktive Regeln nutze „Schild aktivieren" für manuelle Kontrolle.';
  @override String appsSelected(int count) => '$count Apps ausgewählt';
  @override String get selectAppsToBlock => 'Apps zum Blockieren auswählen';

  @override String get scheduleTitle => 'Zeitplan';
  @override String get scheduleDescription => 'Hart-Blockierung in einem täglichen Zeitfenster';
  @override String get scheduleStart => 'Beginn';
  @override String get scheduleEnd => 'Ende';

  @override String get usageLimitTitle => 'Nutzungslimit';
  @override String get usageLimitDescription => 'Weich-Blockierung nach täglichem Bildschirmzeit-Budget';
  @override String get dailyLimit => 'Tägliches Limit';
  @override String get sliderMin => '5 Min';
  @override String get sliderMax => '3 Std';

  @override String get taskModeTitle => 'Aufgabenmodus';
  @override String get taskModeDescription => 'Blockieren, bis alle Aufgaben erledigt sind';

  @override String get activateShield => 'Schild aktivieren';
  @override String get deactivateShield => 'Schild deaktivieren';
  @override String get selectAppsToActivate => 'Apps zum Aktivieren auswählen';
  @override String get settingsLockedWhileActive => 'Einstellungen sind gesperrt, solange der Schild aktiv ist. Deaktiviere ihn, um Änderungen vorzunehmen.';
  @override String get tasksResetDaily => 'Aufgaben werden täglich zurückgesetzt.';

  @override String get appsLocked => 'Apps blockiert';
  @override String get appsUnlocked => 'Anforderungen erfüllt — Apps zugänglich';

  @override String get reasonManualMode => 'Manueller Modus — deaktiviere zum Entsperren';
  @override String get reasonInsideSchedule => 'Innerhalb des Zeitfensters';
  @override String reasonTasksRemaining(int r) => '$r Aufgabe${r == 1 ? '' : 'n'} übrig';
  @override String get reasonAllMet => 'Alle Anforderungen erfüllt — Apps zugänglich';

  @override String get noAppsSelected => 'Keine Apps ausgewählt';
  @override String subtitleApps(int count) => '$count Apps';
  @override String subtitleUsageLimit(int minutes) => '${minutes} Min Limit';
  @override String subtitleTasks(int done, int total) => '$done/$total Aufgaben';
  @override String get subtitleManual => 'Manuell';
  @override String subtitleScheduleRange(String start, String end) => '$start–$end Uhr';

  @override String get deleteProfile => 'Profil löschen';
  @override String deleteProfileConfirm(String name) => '„$name" löschen? Das kann nicht rückgängig gemacht werden.';

  @override String get tasks => 'Aufgaben';
  @override String taskProgress(int done, int total) => '$done / $total';
  @override String get addTaskHint => 'Aufgabe hinzufügen…';
  @override String get allTasksDoneNote => 'Alle Aufgaben erledigt!';
  @override String tasksRemainingNote(int r) => 'Noch $r Aufgabe${r == 1 ? '' : 'n'} zum Entsperren';
  @override String get emptyTasksHint => 'Füge Aufgaben hinzu, die erledigt werden müssen, bevor Apps entsperrt werden.';

  @override String get setPinTitle => 'Deaktivierungs-PIN festlegen';
  @override String get setPinDescription => 'Gib dein Handy einer Vertrauensperson.\nSie legt eine PIN fest, die zum Deaktivieren benötigt wird.';
  @override String get enterPin => 'PIN eingeben';
  @override String get confirmPin => 'PIN bestätigen';
  @override String get savePin => 'PIN speichern';
  @override String get pinTooShort => 'PIN muss mindestens 4 Zeichen lang sein';
  @override String get pinsMismatch => 'PINs stimmen nicht überein';

  @override String get coolingDown => 'Abkühlphase…';
  @override String get enterPinToDeactivate => 'PIN zum Deaktivieren eingeben';
  @override String get confirmDeactivation => 'Deaktivierung bestätigen';
  @override String get deactivateAction => 'Deaktivieren';
  @override String get areYouSureDeactivate => 'Bist du sicher, dass du deaktivieren möchtest?';
  @override String get cooldownDescription => 'Nimm dir einen Moment zum Nachdenken.\nDer Schild kann nach dem Timer deaktiviert werden.';
  @override String get enterTrustedPersonPin => 'Gib die PIN deiner Vertrauensperson ein.';
  @override String get pinLabel => 'PIN';
  @override String get enterYourPin => 'PIN eingeben';
  @override String get incorrectPin => 'Falsche PIN';

  @override List<String> get dayLabels => const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
}

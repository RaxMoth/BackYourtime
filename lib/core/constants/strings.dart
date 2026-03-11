import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

/// Centralised user-facing strings with locale support.
/// Supported: English (en), Deutsch (de), Español (es), Français (fr), Hrvatski (hr).
///
/// Call [S.init] once at app start (before `runApp`).
/// Access via the top-level [S] instance, e.g. `S.current.appName`.
abstract class S {
  S._();

  static const _kLocaleKey = 'app_locale';

  /// All supported language codes.
  static const supportedLocales = ['en', 'de', 'es', 'fr', 'hr'];

  // ── Singleton access ─────────────────────────────────────────────────────
  static late S current;

  static S _forCode(String code) => switch (code) {
    'de' => _De(),
    'es' => _Es(),
    'fr' => _Fr(),
    'hr' => _Hr(),
    _ => _En(),
  };

  /// Must be called once before `runApp`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLocaleKey);
      if (saved != null) {
        current = _forCode(saved);
      } else {
        final lang = Platform.localeName.split('_').first.toLowerCase();
        current = _forCode(lang);
      }
    } catch (_) {
      current = _En();
    }
  }

  /// Change locale at runtime and persist the choice.
  static Future<void> setLocale(String langCode) async {
    current = _forCode(langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, langCode);
    } catch (_) {
      // best-effort persist
    }
  }

  /// The active language code.
  static String get langCode {
    if (current is _De) return 'de';
    if (current is _Es) return 'es';
    if (current is _Fr) return 'fr';
    if (current is _Hr) return 'hr';
    return 'en';
  }

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
  String get noTasksWarning;

  // ── Summary Card ─────────────────────────────────────────────────────────
  String get allShieldsActive;
  String someShieldsActive(int active, int total);
  String get noProfiles;
  String get shieldsInactive;
  String get blockingDistractingApps;
  String get createProfileToStart;
  String get noProfilesAreActive;

  // ── Create Profile Sheet ─────────────────────────────────────────────────
  String get newProfile;
  String get createProfileDescription;
  String get profileNameHint;

  // ── Settings ─────────────────────────────────────────────────────────────
  String get settings;
  String get changePin;
  String get changePinSubtitle;
  String get languageLabel;
  String get themeLabel;
  String get themeSystem;
  String get themeLight;
  String get themeDark;

  // ── Profile Detail ───────────────────────────────────────────────────────
  String get profileNamePlaceholder;
  String get sectionColor;
  String get sectionIcon;
  String get sectionApps;
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
  String pinLockedOut(int seconds);

  // ── Privacy Policy ──────────────────────────────────────────────────────
  String get privacyPolicyTitle;
  String get privacyPolicySubtitle;
  String get privacyPolicyBody;

  // ── Delete All Data ─────────────────────────────────────────────────────
  String get deleteAllData;
  String get deleteAllDataSubtitle;
  String get deleteAllDataConfirm;
  String get deleteAllDataWarning;

  // ── Onboarding ──────────────────────────────────────────────────────────
  String get onboardingTitle1;
  String get onboardingBody1;
  String get onboardingTitle2;
  String get onboardingBody2;
  String get onboardingTitle3;
  String get onboardingBody3;
  String get getStarted;
  String get next;
  String get skip;
}

// ═══════════════════════════════════════════════════════════════════════════
// ── English (default) ──────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _En extends S {
  _En() : super._();

  @override
  String get appName => 'Unspend';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get create => 'Create';
  @override
  String get untitled => 'Untitled';
  @override
  String errorGeneric(Object e) => 'Error: $e';

  @override
  String get profilesSectionTitle => 'Profiles';
  @override
  String get noProfilesYet => 'No profiles yet';
  @override
  String get noProfilesTapPlus =>
      'Tap + to create your first blocking profile.';
  @override
  String get noAppsWarning => 'No apps in this group — select apps first';
  @override
  String get noTasksWarning =>
      'Add at least one task before activating task mode';

  @override
  String get allShieldsActive => 'All Shields Active';
  @override
  String someShieldsActive(int active, int total) => '$active of $total Active';
  @override
  String get noProfiles => 'No Profiles';
  @override
  String get shieldsInactive => 'Shields Inactive';
  @override
  String get blockingDistractingApps => 'Blocking distracting apps';
  @override
  String get createProfileToStart => 'Create a profile to get started';
  @override
  String get noProfilesAreActive => 'No profiles are active';

  @override
  String get newProfile => 'New Profile';
  @override
  String get createProfileDescription =>
      'Create a group of apps with its own blocking rules.';
  @override
  String get profileNameHint => 'e.g. Social Media, Games…';

  @override
  String get settings => 'Settings';
  @override
  String get changePin => 'Change PIN';
  @override
  String get changePinSubtitle => 'Trusted-person deactivation PIN';
  @override
  String get languageLabel => 'Language';
  @override
  String get themeLabel => 'Theme';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';

  @override
  String get profileNamePlaceholder => 'Profile Name';
  @override
  String get sectionColor => 'Color';
  @override
  String get sectionIcon => 'Icon';
  @override
  String get sectionApps => 'Apps';
  @override
  String get sectionBlockRules => 'Block Rules';
  @override
  String get blockRulesDescription =>
      'Combine any rules below. With none enabled, use Activate Shield for manual control.';
  @override
  String appsSelected(int count) => '$count apps selected';
  @override
  String get selectAppsToBlock => 'Select Apps to Block';

  @override
  String get scheduleTitle => 'Schedule';
  @override
  String get scheduleDescription => 'Hard-block during a daily time window';
  @override
  String get scheduleStart => 'Start';
  @override
  String get scheduleEnd => 'End';

  @override
  String get usageLimitTitle => 'Usage Limit';
  @override
  String get usageLimitDescription =>
      'Soft-block after a daily screen-time budget';
  @override
  String get dailyLimit => 'Daily Limit';
  @override
  String get sliderMin => '5 min';
  @override
  String get sliderMax => '3 hrs';

  @override
  String get taskModeTitle => 'Task Mode';
  @override
  String get taskModeDescription => 'Block until all tasks are completed';

  @override
  String get activateShield => 'Activate Shield';
  @override
  String get deactivateShield => 'Deactivate Shield';
  @override
  String get selectAppsToActivate => 'Select Apps to Activate';
  @override
  String get settingsLockedWhileActive =>
      'Settings are locked while the shield is active. Deactivate to make changes.';

  @override
  String get reasonManualMode => 'Manual mode — deactivate to unlock';
  @override
  String get reasonInsideSchedule => 'Inside schedule window';
  @override
  String reasonTasksRemaining(int r) => '$r task${r == 1 ? '' : 's'} remaining';
  @override
  String get reasonAllMet => 'All requirements met — apps accessible';

  @override
  String get noAppsSelected => 'No apps selected';
  @override
  String subtitleApps(int count) => '$count apps';
  @override
  String subtitleUsageLimit(int minutes) => '${minutes}min limit';
  @override
  String subtitleTasks(int done, int total) => '$done/$total tasks';
  @override
  String get subtitleManual => 'Manual';
  @override
  String subtitleScheduleRange(String start, String end) => '$start–$end';

  @override
  String get deleteProfile => 'Delete Profile';
  @override
  String deleteProfileConfirm(String name) =>
      'Delete "$name"? This cannot be undone.';

  @override
  String get tasks => 'Tasks';
  @override
  String get addTaskHint => 'Add a task…';
  @override
  String get allTasksDoneNote => 'All tasks done!';
  @override
  String tasksRemainingNote(int r) =>
      '$r task${r == 1 ? '' : 's'} remaining to unlock';
  @override
  String get emptyTasksHint =>
      'Add tasks that must be completed before apps unlock.';

  @override
  String get setPinTitle => 'Set Deactivation PIN';
  @override
  String get setPinDescription =>
      'Hand your phone to a trusted person.\nThey set a PIN that is required to deactivate any shield.';
  @override
  String get enterPin => 'Enter PIN';
  @override
  String get confirmPin => 'Confirm PIN';
  @override
  String get savePin => 'Save PIN';
  @override
  String get pinTooShort => 'PIN must be at least 4 characters';
  @override
  String get pinsMismatch => 'PINs do not match';

  @override
  String get coolingDown => 'Cooling Down…';
  @override
  String get enterPinToDeactivate => 'Enter PIN to Deactivate';
  @override
  String get confirmDeactivation => 'Confirm Deactivation';
  @override
  String get deactivateAction => 'Deactivate';
  @override
  String get areYouSureDeactivate => 'Are you sure you want to deactivate?';
  @override
  String get cooldownDescription =>
      'Take a moment to reconsider.\nThe shield will be deactivatable after the timer.';
  @override
  String get enterTrustedPersonPin =>
      'Enter the PIN set by your trusted person.';
  @override
  String get pinLabel => 'PIN';
  @override
  String get enterYourPin => 'Enter your PIN';
  @override
  String get incorrectPin => 'Incorrect PIN';
  @override
  String pinLockedOut(int seconds) =>
      'Too many attempts. Try again in ${seconds}s';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';
  @override
  String get privacyPolicySubtitle => 'How your data is handled';
  @override
  String get privacyPolicyBody =>
      'Unspend stores all data locally on your device. No personal data is collected, transmitted, or shared with third parties.\n\n'
      'Your blocking profiles, settings, and PIN are saved using on-device storage (SharedPreferences and iOS Keychain). '
      'No analytics, tracking, or telemetry is used.\n\n'
      'The app uses Apple\'s FamilyControls framework to manage app blocking. This data stays on your device and is managed entirely by iOS.\n\n'
      'You can delete all your data at any time from Settings > Delete All Data.';

  @override
  String get deleteAllData => 'Delete All Data';
  @override
  String get deleteAllDataSubtitle => 'Remove all profiles, PIN, and settings';
  @override
  String get deleteAllDataConfirm => 'Delete Everything';
  @override
  String get deleteAllDataWarning =>
      'This will permanently delete all profiles, your PIN, and all settings. Active shields will be removed. This cannot be undone.';

  @override
  String get onboardingTitle1 => 'Take Back Your Time';
  @override
  String get onboardingBody1 =>
      'Unspend helps you block distracting apps at the OS level so you can focus on what matters.';
  @override
  String get onboardingTitle2 => 'Create Blocking Profiles';
  @override
  String get onboardingBody2 =>
      'Set up profiles with combinable rules: time schedules, daily usage limits, and task-based unlocking.';
  @override
  String get onboardingTitle3 => 'Unskippable Protection';
  @override
  String get onboardingBody3 =>
      'Shields are enforced by iOS itself. A PIN and cooldown timer prevent impulsive disabling.';
  @override
  String get getStarted => 'Get Started';
  @override
  String get next => 'Next';
  @override
  String get skip => 'Skip';
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Deutsch ────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _De extends S {
  _De() : super._();

  @override
  String get appName => 'Unspend';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get delete => 'Löschen';
  @override
  String get create => 'Erstellen';
  @override
  String get untitled => 'Unbenannt';
  @override
  String errorGeneric(Object e) => 'Fehler: $e';

  @override
  String get profilesSectionTitle => 'Profile';
  @override
  String get noProfilesYet => 'Noch keine Profile';
  @override
  String get noProfilesTapPlus =>
      'Tippe auf +, um dein erstes Blockier-Profil zu erstellen.';
  @override
  String get noAppsWarning =>
      'Keine Apps in dieser Gruppe — wähle zuerst Apps aus';
  @override
  String get noTasksWarning =>
      'Füge mindestens eine Aufgabe hinzu, bevor du den Aufgabenmodus aktivierst';

  @override
  String get allShieldsActive => 'Alle Schilde aktiv';
  @override
  String someShieldsActive(int active, int total) => '$active von $total aktiv';
  @override
  String get noProfiles => 'Keine Profile';
  @override
  String get shieldsInactive => 'Schilde inaktiv';
  @override
  String get blockingDistractingApps => 'Ablenkende Apps werden blockiert';
  @override
  String get createProfileToStart => 'Erstelle ein Profil, um loszulegen';
  @override
  String get noProfilesAreActive => 'Keine Profile sind aktiv';

  @override
  String get newProfile => 'Neues Profil';
  @override
  String get createProfileDescription =>
      'Erstelle eine Gruppe von Apps mit eigenen Blockier-Regeln.';
  @override
  String get profileNameHint => 'z.\u202FB. Social Media, Spiele…';

  @override
  String get settings => 'Einstellungen';
  @override
  String get changePin => 'PIN ändern';
  @override
  String get changePinSubtitle => 'Vertrauensperson-Deaktivierungs-PIN';
  @override
  String get languageLabel => 'Sprache';
  @override
  String get themeLabel => 'Design';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Hell';
  @override
  String get themeDark => 'Dunkel';

  @override
  String get profileNamePlaceholder => 'Profilname';
  @override
  String get sectionColor => 'Farbe';
  @override
  String get sectionIcon => 'Symbol';
  @override
  String get sectionApps => 'Apps';
  @override
  String get sectionBlockRules => 'Blockier-Regeln';
  @override
  String get blockRulesDescription =>
      'Kombiniere beliebige Regeln. Ohne aktive Regeln nutze „Schild aktivieren" für manuelle Kontrolle.';
  @override
  String appsSelected(int count) => '$count Apps ausgewählt';
  @override
  String get selectAppsToBlock => 'Apps zum Blockieren auswählen';

  @override
  String get scheduleTitle => 'Zeitplan';
  @override
  String get scheduleDescription =>
      'Hart-Blockierung in einem täglichen Zeitfenster';
  @override
  String get scheduleStart => 'Beginn';
  @override
  String get scheduleEnd => 'Ende';

  @override
  String get usageLimitTitle => 'Nutzungslimit';
  @override
  String get usageLimitDescription =>
      'Weich-Blockierung nach täglichem Bildschirmzeit-Budget';
  @override
  String get dailyLimit => 'Tägliches Limit';
  @override
  String get sliderMin => '5 Min';
  @override
  String get sliderMax => '3 Std';

  @override
  String get taskModeTitle => 'Aufgabenmodus';
  @override
  String get taskModeDescription =>
      'Blockieren, bis alle Aufgaben erledigt sind';

  @override
  String get activateShield => 'Schild aktivieren';
  @override
  String get deactivateShield => 'Schild deaktivieren';
  @override
  String get selectAppsToActivate => 'Apps zum Aktivieren auswählen';
  @override
  String get settingsLockedWhileActive =>
      'Einstellungen sind gesperrt, solange der Schild aktiv ist. Deaktiviere ihn, um Änderungen vorzunehmen.';

  @override
  String get reasonManualMode => 'Manueller Modus — deaktiviere zum Entsperren';
  @override
  String get reasonInsideSchedule => 'Innerhalb des Zeitfensters';
  @override
  String reasonTasksRemaining(int r) => '$r Aufgabe${r == 1 ? '' : 'n'} übrig';
  @override
  String get reasonAllMet => 'Alle Anforderungen erfüllt — Apps zugänglich';

  @override
  String get noAppsSelected => 'Keine Apps ausgewählt';
  @override
  String subtitleApps(int count) => '$count Apps';
  @override
  String subtitleUsageLimit(int minutes) => '$minutes Min Limit';
  @override
  String subtitleTasks(int done, int total) => '$done/$total Aufgaben';
  @override
  String get subtitleManual => 'Manuell';
  @override
  String subtitleScheduleRange(String start, String end) => '$start–$end Uhr';

  @override
  String get deleteProfile => 'Profil löschen';
  @override
  String deleteProfileConfirm(String name) =>
      '„$name" löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get tasks => 'Aufgaben';
  @override
  String get addTaskHint => 'Aufgabe hinzufügen…';
  @override
  String get allTasksDoneNote => 'Alle Aufgaben erledigt!';
  @override
  String tasksRemainingNote(int r) =>
      'Noch $r Aufgabe${r == 1 ? '' : 'n'} zum Entsperren';
  @override
  String get emptyTasksHint =>
      'Füge Aufgaben hinzu, die erledigt werden müssen, bevor Apps entsperrt werden.';

  @override
  String get setPinTitle => 'Deaktivierungs-PIN festlegen';
  @override
  String get setPinDescription =>
      'Gib dein Handy einer Vertrauensperson.\nSie legt eine PIN fest, die zum Deaktivieren benötigt wird.';
  @override
  String get enterPin => 'PIN eingeben';
  @override
  String get confirmPin => 'PIN bestätigen';
  @override
  String get savePin => 'PIN speichern';
  @override
  String get pinTooShort => 'PIN muss mindestens 4 Zeichen lang sein';
  @override
  String get pinsMismatch => 'PINs stimmen nicht überein';

  @override
  String get coolingDown => 'Abkühlphase…';
  @override
  String get enterPinToDeactivate => 'PIN zum Deaktivieren eingeben';
  @override
  String get confirmDeactivation => 'Deaktivierung bestätigen';
  @override
  String get deactivateAction => 'Deaktivieren';
  @override
  String get areYouSureDeactivate =>
      'Bist du sicher, dass du deaktivieren möchtest?';
  @override
  String get cooldownDescription =>
      'Nimm dir einen Moment zum Nachdenken.\nDer Schild kann nach dem Timer deaktiviert werden.';
  @override
  String get enterTrustedPersonPin =>
      'Gib die PIN deiner Vertrauensperson ein.';
  @override
  String get pinLabel => 'PIN';
  @override
  String get enterYourPin => 'PIN eingeben';
  @override
  String get incorrectPin => 'Falsche PIN';
  @override
  String pinLockedOut(int seconds) =>
      'Zu viele Versuche. Erneut in ${seconds}s';

  @override
  String get privacyPolicyTitle => 'Datenschutz';
  @override
  String get privacyPolicySubtitle => 'Wie deine Daten behandelt werden';
  @override
  String get privacyPolicyBody =>
      'Unspend speichert alle Daten lokal auf deinem Gerät. Es werden keine personenbezogenen Daten erhoben, übermittelt oder an Dritte weitergegeben.\n\n'
      'Deine Blockierprofile, Einstellungen und deine PIN werden im Gerätespeicher (SharedPreferences und iOS-Schlüsselbund) gesichert. '
      'Es werden keine Analyse-, Tracking- oder Telemetriedienste verwendet.\n\n'
      'Die App nutzt Apples FamilyControls-Framework zur App-Blockierung. Diese Daten verbleiben auf deinem Gerät und werden vollständig von iOS verwaltet.\n\n'
      'Du kannst alle Daten jederzeit unter Einstellungen > Alle Daten löschen entfernen.';

  @override
  String get deleteAllData => 'Alle Daten löschen';
  @override
  String get deleteAllDataSubtitle =>
      'Alle Profile, PIN und Einstellungen entfernen';
  @override
  String get deleteAllDataConfirm => 'Alles löschen';
  @override
  String get deleteAllDataWarning =>
      'Alle Profile, deine PIN und sämtliche Einstellungen werden unwiderruflich gelöscht. Aktive Schilde werden entfernt.';

  @override
  String get onboardingTitle1 => 'Hol dir deine Zeit zurück';
  @override
  String get onboardingBody1 =>
      'Unspend hilft dir, ablenkende Apps auf Systemebene zu blockieren, damit du dich auf das Wesentliche konzentrieren kannst.';
  @override
  String get onboardingTitle2 => 'Erstelle Blockierprofile';
  @override
  String get onboardingBody2 =>
      'Richte Profile mit kombinierbaren Regeln ein: Zeitpläne, tägliche Nutzungslimits und aufgabenbasiertes Entsperren.';
  @override
  String get onboardingTitle3 => 'Unumgehbarer Schutz';
  @override
  String get onboardingBody3 =>
      'Schilde werden von iOS selbst durchgesetzt. Eine PIN und ein Abkühl-Timer verhindern impulsives Deaktivieren.';
  @override
  String get getStarted => 'Los geht\'s';
  @override
  String get next => 'Weiter';
  @override
  String get skip => 'Überspringen';
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Español ────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _Es extends S {
  _Es() : super._();

  @override
  String get appName => 'Unspend';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Eliminar';
  @override
  String get create => 'Crear';
  @override
  String get untitled => 'Sin título';
  @override
  String errorGeneric(Object e) => 'Error: $e';

  @override
  String get profilesSectionTitle => 'Perfiles';
  @override
  String get noProfilesYet => 'Sin perfiles aún';
  @override
  String get noProfilesTapPlus =>
      'Toca + para crear tu primer perfil de bloqueo.';
  @override
  String get noAppsWarning =>
      'No hay apps en este grupo — selecciona apps primero';
  @override
  String get noTasksWarning =>
      'Añade al menos una tarea antes de activar el modo de tareas';

  @override
  String get allShieldsActive => 'Todos los escudos activos';
  @override
  String someShieldsActive(int active, int total) =>
      '$active de $total activos';
  @override
  String get noProfiles => 'Sin perfiles';
  @override
  String get shieldsInactive => 'Escudos inactivos';
  @override
  String get blockingDistractingApps => 'Bloqueando apps de distracción';
  @override
  String get createProfileToStart => 'Crea un perfil para empezar';
  @override
  String get noProfilesAreActive => 'Ningún perfil está activo';

  @override
  String get newProfile => 'Nuevo perfil';
  @override
  String get createProfileDescription =>
      'Crea un grupo de apps con sus propias reglas de bloqueo.';
  @override
  String get profileNameHint => 'ej. Redes sociales, Juegos…';

  @override
  String get settings => 'Ajustes';
  @override
  String get changePin => 'Cambiar PIN';
  @override
  String get changePinSubtitle =>
      'PIN de desactivación de persona de confianza';
  @override
  String get languageLabel => 'Idioma';
  @override
  String get themeLabel => 'Tema';
  @override
  String get themeSystem => 'Sistema';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';

  @override
  String get profileNamePlaceholder => 'Nombre del perfil';
  @override
  String get sectionColor => 'Color';
  @override
  String get sectionIcon => 'Icono';
  @override
  String get sectionApps => 'Apps';
  @override
  String get sectionBlockRules => 'Reglas de bloqueo';
  @override
  String get blockRulesDescription =>
      'Combina reglas. Sin reglas activas, usa Activar escudo para control manual.';
  @override
  String appsSelected(int count) => '$count apps seleccionadas';
  @override
  String get selectAppsToBlock => 'Seleccionar apps a bloquear';

  @override
  String get scheduleTitle => 'Horario';
  @override
  String get scheduleDescription =>
      'Bloqueo fijo durante una franja horaria diaria';
  @override
  String get scheduleStart => 'Inicio';
  @override
  String get scheduleEnd => 'Fin';

  @override
  String get usageLimitTitle => 'Límite de uso';
  @override
  String get usageLimitDescription =>
      'Bloqueo suave tras un presupuesto diario de pantalla';
  @override
  String get dailyLimit => 'Límite diario';
  @override
  String get sliderMin => '5 min';
  @override
  String get sliderMax => '3 hrs';

  @override
  String get taskModeTitle => 'Modo tareas';
  @override
  String get taskModeDescription => 'Bloquear hasta completar todas las tareas';

  @override
  String get activateShield => 'Activar escudo';
  @override
  String get deactivateShield => 'Desactivar escudo';
  @override
  String get selectAppsToActivate => 'Seleccionar apps para activar';
  @override
  String get settingsLockedWhileActive =>
      'Los ajustes están bloqueados mientras el escudo está activo. Desactívalo para hacer cambios.';

  @override
  String get reasonManualMode => 'Modo manual — desactiva para desbloquear';
  @override
  String get reasonInsideSchedule => 'Dentro de la franja horaria';
  @override
  String reasonTasksRemaining(int r) =>
      '$r tarea${r == 1 ? '' : 's'} pendiente${r == 1 ? '' : 's'}';
  @override
  String get reasonAllMet => 'Todos los requisitos cumplidos — apps accesibles';

  @override
  String get noAppsSelected => 'Sin apps seleccionadas';
  @override
  String subtitleApps(int count) => '$count apps';
  @override
  String subtitleUsageLimit(int minutes) => '${minutes}min límite';
  @override
  String subtitleTasks(int done, int total) => '$done/$total tareas';
  @override
  String get subtitleManual => 'Manual';
  @override
  String subtitleScheduleRange(String start, String end) => '$start–$end';

  @override
  String get deleteProfile => 'Eliminar perfil';
  @override
  String deleteProfileConfirm(String name) =>
      '¿Eliminar "$name"? Esto no se puede deshacer.';

  @override
  String get tasks => 'Tareas';
  @override
  String get addTaskHint => 'Añadir una tarea…';
  @override
  String get allTasksDoneNote => '¡Todas las tareas completadas!';
  @override
  String tasksRemainingNote(int r) =>
      '$r tarea${r == 1 ? '' : 's'} pendiente${r == 1 ? '' : 's'} para desbloquear';
  @override
  String get emptyTasksHint =>
      'Añade tareas que deban completarse antes de desbloquear las apps.';

  @override
  String get setPinTitle => 'Establecer PIN de desactivación';
  @override
  String get setPinDescription =>
      'Dale tu teléfono a una persona de confianza.\nElla establece un PIN necesario para desactivar cualquier escudo.';
  @override
  String get enterPin => 'Introducir PIN';
  @override
  String get confirmPin => 'Confirmar PIN';
  @override
  String get savePin => 'Guardar PIN';
  @override
  String get pinTooShort => 'El PIN debe tener al menos 4 caracteres';
  @override
  String get pinsMismatch => 'Los PINs no coinciden';

  @override
  String get coolingDown => 'Enfriándose…';
  @override
  String get enterPinToDeactivate => 'Introducir PIN para desactivar';
  @override
  String get confirmDeactivation => 'Confirmar desactivación';
  @override
  String get deactivateAction => 'Desactivar';
  @override
  String get areYouSureDeactivate => '¿Estás seguro de que quieres desactivar?';
  @override
  String get cooldownDescription =>
      'Tómate un momento para reconsiderar.\nEl escudo se podrá desactivar después del temporizador.';
  @override
  String get enterTrustedPersonPin =>
      'Introduce el PIN establecido por tu persona de confianza.';
  @override
  String get pinLabel => 'PIN';
  @override
  String get enterYourPin => 'Introduce tu PIN';
  @override
  String get incorrectPin => 'PIN incorrecto';
  @override
  String pinLockedOut(int seconds) =>
      'Demasiados intentos. Inténtalo en ${seconds}s';

  @override
  String get privacyPolicyTitle => 'Política de privacidad';
  @override
  String get privacyPolicySubtitle => 'Cómo se manejan tus datos';
  @override
  String get privacyPolicyBody =>
      'Unspend almacena todos los datos localmente en tu dispositivo. No se recopilan, transmiten ni comparten datos personales con terceros.\n\n'
      'Tus perfiles de bloqueo, ajustes y PIN se guardan en el almacenamiento del dispositivo (SharedPreferences y el llavero de iOS). '
      'No se utiliza ningún servicio de análisis, rastreo o telemetría.\n\n'
      'La app usa el framework FamilyControls de Apple para gestionar el bloqueo de apps. Estos datos permanecen en tu dispositivo y son gestionados por iOS.\n\n'
      'Puedes eliminar todos tus datos en cualquier momento desde Ajustes > Eliminar todos los datos.';

  @override
  String get deleteAllData => 'Eliminar todos los datos';
  @override
  String get deleteAllDataSubtitle =>
      'Eliminar todos los perfiles, PIN y ajustes';
  @override
  String get deleteAllDataConfirm => 'Eliminar todo';
  @override
  String get deleteAllDataWarning =>
      'Se eliminarán permanentemente todos los perfiles, tu PIN y todos los ajustes. Los escudos activos serán eliminados. Esta acción no se puede deshacer.';

  @override
  String get onboardingTitle1 => 'Recupera tu tiempo';
  @override
  String get onboardingBody1 =>
      'Unspend te ayuda a bloquear apps distractoras a nivel del sistema para que puedas concentrarte en lo importante.';
  @override
  String get onboardingTitle2 => 'Crea perfiles de bloqueo';
  @override
  String get onboardingBody2 =>
      'Configura perfiles con reglas combinables: horarios, límites de uso diario y desbloqueo basado en tareas.';
  @override
  String get onboardingTitle3 => 'Protección inquebrantable';
  @override
  String get onboardingBody3 =>
      'Los escudos son aplicados por iOS mismo. Un PIN y un temporizador de espera previenen la desactivación impulsiva.';
  @override
  String get getStarted => 'Comenzar';
  @override
  String get next => 'Siguiente';
  @override
  String get skip => 'Omitir';
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Français ───────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _Fr extends S {
  _Fr() : super._();

  @override
  String get appName => 'Unspend';
  @override
  String get cancel => 'Annuler';
  @override
  String get delete => 'Supprimer';
  @override
  String get create => 'Créer';
  @override
  String get untitled => 'Sans titre';
  @override
  String errorGeneric(Object e) => 'Erreur : $e';

  @override
  String get profilesSectionTitle => 'Profils';
  @override
  String get noProfilesYet => 'Aucun profil';
  @override
  String get noProfilesTapPlus =>
      'Appuyez sur + pour créer votre premier profil de blocage.';
  @override
  String get noAppsWarning =>
      'Aucune app dans ce groupe — sélectionnez d\'abord des apps';
  @override
  String get noTasksWarning =>
      'Ajoutez au moins une tâche avant d\'activer le mode tâches';

  @override
  String get allShieldsActive => 'Tous les boucliers actifs';
  @override
  String someShieldsActive(int active, int total) =>
      '$active sur $total actifs';
  @override
  String get noProfiles => 'Aucun profil';
  @override
  String get shieldsInactive => 'Boucliers inactifs';
  @override
  String get blockingDistractingApps => 'Blocage des apps de distraction';
  @override
  String get createProfileToStart => 'Créez un profil pour commencer';
  @override
  String get noProfilesAreActive => 'Aucun profil n\'est actif';

  @override
  String get newProfile => 'Nouveau profil';
  @override
  String get createProfileDescription =>
      'Créez un groupe d\'apps avec ses propres règles de blocage.';
  @override
  String get profileNameHint => 'ex. Réseaux sociaux, Jeux…';

  @override
  String get settings => 'Paramètres';
  @override
  String get changePin => 'Changer le PIN';
  @override
  String get changePinSubtitle =>
      'PIN de désactivation de la personne de confiance';
  @override
  String get languageLabel => 'Langue';
  @override
  String get themeLabel => 'Thème';
  @override
  String get themeSystem => 'Système';
  @override
  String get themeLight => 'Clair';
  @override
  String get themeDark => 'Sombre';

  @override
  String get profileNamePlaceholder => 'Nom du profil';
  @override
  String get sectionColor => 'Couleur';
  @override
  String get sectionIcon => 'Icône';
  @override
  String get sectionApps => 'Apps';
  @override
  String get sectionBlockRules => 'Règles de blocage';
  @override
  String get blockRulesDescription =>
      'Combinez les règles ci-dessous. Sans règle active, utilisez Activer le bouclier pour un contrôle manuel.';
  @override
  String appsSelected(int count) => '$count apps sélectionnées';
  @override
  String get selectAppsToBlock => 'Sélectionner les apps à bloquer';

  @override
  String get scheduleTitle => 'Horaire';
  @override
  String get scheduleDescription =>
      'Blocage strict pendant une plage horaire quotidienne';
  @override
  String get scheduleStart => 'Début';
  @override
  String get scheduleEnd => 'Fin';

  @override
  String get usageLimitTitle => 'Limite d\'utilisation';
  @override
  String get usageLimitDescription =>
      'Blocage souple après un budget quotidien d\'écran';
  @override
  String get dailyLimit => 'Limite quotidienne';
  @override
  String get sliderMin => '5 min';
  @override
  String get sliderMax => '3 h';

  @override
  String get taskModeTitle => 'Mode tâches';
  @override
  String get taskModeDescription =>
      'Bloquer jusqu\'à ce que toutes les tâches soient terminées';

  @override
  String get activateShield => 'Activer le bouclier';
  @override
  String get deactivateShield => 'Désactiver le bouclier';
  @override
  String get selectAppsToActivate => 'Sélectionner les apps à activer';
  @override
  String get settingsLockedWhileActive =>
      'Les paramètres sont verrouillés tant que le bouclier est actif. Désactivez-le pour modifier.';

  @override
  String get reasonManualMode => 'Mode manuel — désactivez pour débloquer';
  @override
  String get reasonInsideSchedule => 'Dans la plage horaire';
  @override
  String reasonTasksRemaining(int r) =>
      '$r tâche${r == 1 ? '' : 's'} restante${r == 1 ? '' : 's'}';
  @override
  String get reasonAllMet =>
      'Toutes les conditions remplies — apps accessibles';

  @override
  String get noAppsSelected => 'Aucune app sélectionnée';
  @override
  String subtitleApps(int count) => '$count apps';
  @override
  String subtitleUsageLimit(int minutes) => '${minutes}min limite';
  @override
  String subtitleTasks(int done, int total) => '$done/$total tâches';
  @override
  String get subtitleManual => 'Manuel';
  @override
  String subtitleScheduleRange(String start, String end) => '$start–$end';

  @override
  String get deleteProfile => 'Supprimer le profil';
  @override
  String deleteProfileConfirm(String name) =>
      'Supprimer « $name » ? Cette action est irréversible.';

  @override
  String get tasks => 'Tâches';
  @override
  String get addTaskHint => 'Ajouter une tâche…';
  @override
  String get allTasksDoneNote => 'Toutes les tâches terminées !';
  @override
  String tasksRemainingNote(int r) =>
      '$r tâche${r == 1 ? '' : 's'} restante${r == 1 ? '' : 's'} pour débloquer';
  @override
  String get emptyTasksHint =>
      'Ajoutez des tâches à accomplir avant de débloquer les apps.';

  @override
  String get setPinTitle => 'Définir le PIN de désactivation';
  @override
  String get setPinDescription =>
      'Donnez votre téléphone à une personne de confiance.\nElle définit un PIN nécessaire pour désactiver tout bouclier.';
  @override
  String get enterPin => 'Entrer le PIN';
  @override
  String get confirmPin => 'Confirmer le PIN';
  @override
  String get savePin => 'Enregistrer le PIN';
  @override
  String get pinTooShort => 'Le PIN doit comporter au moins 4 caractères';
  @override
  String get pinsMismatch => 'Les PINs ne correspondent pas';

  @override
  String get coolingDown => 'Refroidissement…';
  @override
  String get enterPinToDeactivate => 'Entrer le PIN pour désactiver';
  @override
  String get confirmDeactivation => 'Confirmer la désactivation';
  @override
  String get deactivateAction => 'Désactiver';
  @override
  String get areYouSureDeactivate => 'Êtes-vous sûr de vouloir désactiver ?';
  @override
  String get cooldownDescription =>
      'Prenez un moment pour réfléchir.\nLe bouclier sera désactivable après le minuteur.';
  @override
  String get enterTrustedPersonPin =>
      'Entrez le PIN défini par votre personne de confiance.';
  @override
  String get pinLabel => 'PIN';
  @override
  String get enterYourPin => 'Entrez votre PIN';
  @override
  String get incorrectPin => 'PIN incorrect';
  @override
  String pinLockedOut(int seconds) =>
      'Trop de tentatives. Réessayez dans ${seconds}s';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';
  @override
  String get privacyPolicySubtitle => 'Comment vos données sont traitées';
  @override
  String get privacyPolicyBody =>
      'Unspend stocke toutes les données localement sur votre appareil. Aucune donnée personnelle n\'est collectée, transmise ou partagée avec des tiers.\n\n'
      'Vos profils de blocage, paramètres et PIN sont enregistrés dans le stockage de l\'appareil (SharedPreferences et le trousseau iOS). '
      'Aucun service d\'analyse, de suivi ou de télémétrie n\'est utilisé.\n\n'
      'L\'application utilise le framework FamilyControls d\'Apple pour gérer le blocage des apps. Ces données restent sur votre appareil et sont gérées par iOS.\n\n'
      'Vous pouvez supprimer toutes vos données à tout moment depuis Réglages > Supprimer toutes les données.';

  @override
  String get deleteAllData => 'Supprimer toutes les données';
  @override
  String get deleteAllDataSubtitle =>
      'Supprimer tous les profils, le PIN et les réglages';
  @override
  String get deleteAllDataConfirm => 'Tout supprimer';
  @override
  String get deleteAllDataWarning =>
      'Tous les profils, votre PIN et tous les réglages seront définitivement supprimés. Les boucliers actifs seront retirés. Cette action est irréversible.';

  @override
  String get onboardingTitle1 => 'Reprenez votre temps';
  @override
  String get onboardingBody1 =>
      'Unspend vous aide à bloquer les apps distrayantes au niveau du système pour vous concentrer sur l\'essentiel.';
  @override
  String get onboardingTitle2 => 'Créez des profils de blocage';
  @override
  String get onboardingBody2 =>
      'Configurez des profils avec des règles combinables : horaires, limites d\'utilisation quotidienne et déblocage par tâches.';
  @override
  String get onboardingTitle3 => 'Protection incontournable';
  @override
  String get onboardingBody3 =>
      'Les boucliers sont appliqués par iOS lui-même. Un PIN et un minuteur de refroidissement empêchent la désactivation impulsive.';
  @override
  String get getStarted => 'Commencer';
  @override
  String get next => 'Suivant';
  @override
  String get skip => 'Passer';
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Hrvatski (Croatian) ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
class _Hr extends S {
  _Hr() : super._();

  @override
  String get appName => 'Unspend';
  @override
  String get cancel => 'Odustani';
  @override
  String get delete => 'Obriši';
  @override
  String get create => 'Kreiraj';
  @override
  String get untitled => 'Bez naziva';
  @override
  String errorGeneric(Object e) => 'Greška: $e';

  @override
  String get profilesSectionTitle => 'Profili';
  @override
  String get noProfilesYet => 'Nema profila';
  @override
  String get noProfilesTapPlus =>
      'Dodirni + za izradu prvog profila za blokiranje.';
  @override
  String get noAppsWarning =>
      'Nema aplikacija u ovoj grupi — prvo odaberi aplikacije';
  @override
  String get noTasksWarning =>
      'Dodaj barem jedan zadatak prije aktiviranja načina zadataka';

  @override
  String get allShieldsActive => 'Svi štitovi aktivni';
  @override
  String someShieldsActive(int active, int total) =>
      '$active od $total aktivno';
  @override
  String get noProfiles => 'Nema profila';
  @override
  String get shieldsInactive => 'Štitovi neaktivni';
  @override
  String get blockingDistractingApps => 'Blokiranje ometajućih aplikacija';
  @override
  String get createProfileToStart => 'Kreiraj profil za početak';
  @override
  String get noProfilesAreActive => 'Nijedan profil nije aktivan';

  @override
  String get newProfile => 'Novi profil';
  @override
  String get createProfileDescription =>
      'Kreiraj grupu aplikacija s vlastitim pravilima blokiranja.';
  @override
  String get profileNameHint => 'npr. Društvene mreže, Igre…';

  @override
  String get settings => 'Postavke';
  @override
  String get changePin => 'Promijeni PIN';
  @override
  String get changePinSubtitle => 'PIN za deaktivaciju osobe od povjerenja';
  @override
  String get languageLabel => 'Jezik';
  @override
  String get themeLabel => 'Tema';
  @override
  String get themeSystem => 'Sustav';
  @override
  String get themeLight => 'Svijetla';
  @override
  String get themeDark => 'Tamna';

  @override
  String get profileNamePlaceholder => 'Naziv profila';
  @override
  String get sectionColor => 'Boja';
  @override
  String get sectionIcon => 'Ikona';
  @override
  String get sectionApps => 'Aplikacije';
  @override
  String get sectionBlockRules => 'Pravila blokiranja';
  @override
  String get blockRulesDescription =>
      'Kombiniraj pravila. Bez aktivnih pravila koristi Aktiviraj štit za ručnu kontrolu.';
  @override
  String appsSelected(int count) => '$count aplikacija odabrano';
  @override
  String get selectAppsToBlock => 'Odaberi aplikacije za blokiranje';

  @override
  String get scheduleTitle => 'Raspored';
  @override
  String get scheduleDescription =>
      'Čvrsto blokiranje unutar dnevnog vremenskog okvira';
  @override
  String get scheduleStart => 'Početak';
  @override
  String get scheduleEnd => 'Kraj';

  @override
  String get usageLimitTitle => 'Ograničenje korištenja';
  @override
  String get usageLimitDescription =>
      'Meko blokiranje nakon dnevnog budžeta zaslona';
  @override
  String get dailyLimit => 'Dnevno ograničenje';
  @override
  String get sliderMin => '5 min';
  @override
  String get sliderMax => '3 sata';

  @override
  String get taskModeTitle => 'Način zadataka';
  @override
  String get taskModeDescription => 'Blokiraj dok se svi zadaci ne dovrše';

  @override
  String get activateShield => 'Aktiviraj štit';
  @override
  String get deactivateShield => 'Deaktiviraj štit';
  @override
  String get selectAppsToActivate => 'Odaberi aplikacije za aktiviranje';
  @override
  String get settingsLockedWhileActive =>
      'Postavke su zaključane dok je štit aktivan. Deaktiviraj ga za promjene.';

  @override
  String get reasonManualMode => 'Ručni način — deaktiviraj za otključavanje';
  @override
  String get reasonInsideSchedule => 'Unutar vremenskog okvira';
  @override
  String reasonTasksRemaining(int r) => 'Još $r zadat${r == 1 ? 'ak' : 'aka'}';
  @override
  String get reasonAllMet => 'Svi uvjeti ispunjeni — aplikacije dostupne';

  @override
  String get noAppsSelected => 'Nema odabranih aplikacija';
  @override
  String subtitleApps(int count) => '$count aplikacija';
  @override
  String subtitleUsageLimit(int minutes) => '${minutes}min ograničenje';
  @override
  String subtitleTasks(int done, int total) => '$done/$total zadataka';
  @override
  String get subtitleManual => 'Ručno';
  @override
  String subtitleScheduleRange(String start, String end) => '$start–$end';

  @override
  String get deleteProfile => 'Obriši profil';
  @override
  String deleteProfileConfirm(String name) =>
      'Obrisati „$name"? Ovo se ne može poništiti.';

  @override
  String get tasks => 'Zadaci';
  @override
  String get addTaskHint => 'Dodaj zadatak…';
  @override
  String get allTasksDoneNote => 'Svi zadaci dovršeni!';
  @override
  String tasksRemainingNote(int r) =>
      'Još $r zadat${r == 1 ? 'ak' : 'aka'} za otključavanje';
  @override
  String get emptyTasksHint =>
      'Dodaj zadatke koji moraju biti završeni prije otključavanja aplikacija.';

  @override
  String get setPinTitle => 'Postavi PIN za deaktivaciju';
  @override
  String get setPinDescription =>
      'Daj telefon osobi od povjerenja.\nOna postavlja PIN potreban za deaktivaciju bilo kojeg štita.';
  @override
  String get enterPin => 'Unesi PIN';
  @override
  String get confirmPin => 'Potvrdi PIN';
  @override
  String get savePin => 'Spremi PIN';
  @override
  String get pinTooShort => 'PIN mora imati najmanje 4 znaka';
  @override
  String get pinsMismatch => 'PIN-ovi se ne podudaraju';

  @override
  String get coolingDown => 'Hlađenje…';
  @override
  String get enterPinToDeactivate => 'Unesi PIN za deaktivaciju';
  @override
  String get confirmDeactivation => 'Potvrdi deaktivaciju';
  @override
  String get deactivateAction => 'Deaktiviraj';
  @override
  String get areYouSureDeactivate =>
      'Jesi li siguran/na da želiš deaktivirati?';
  @override
  String get cooldownDescription =>
      'Uzmi trenutak za razmišljanje.\nŠtit će se moći deaktivirati nakon timera.';
  @override
  String get enterTrustedPersonPin =>
      'Unesi PIN koji je postavila tvoja osoba od povjerenja.';
  @override
  String get pinLabel => 'PIN';
  @override
  String get enterYourPin => 'Unesi svoj PIN';
  @override
  String get incorrectPin => 'Netočan PIN';
  @override
  String pinLockedOut(int seconds) =>
      'Previše pokušaja. Pokušaj za ${seconds}s';

  @override
  String get privacyPolicyTitle => 'Politika privatnosti';
  @override
  String get privacyPolicySubtitle => 'Kako se rukuje tvojim podacima';
  @override
  String get privacyPolicyBody =>
      'Unspend pohranjuje sve podatke lokalno na tvom uređaju. Nikakvi osobni podaci se ne prikupljaju, prenose ili dijele s trećim stranama.\n\n'
      'Tvoji profili blokiranja, postavke i PIN se pohranjuju pomoću lokalne pohrane (SharedPreferences i iOS Keychain). '
      'Ne koriste se nikakve analitike, praćenje ili telemetrija.\n\n'
      'Aplikacija koristi Appleov FamilyControls okvir za upravljanje blokiranjem aplikacija. Ti podaci ostaju na tvom uređaju i njima upravlja isključivo iOS.\n\n'
      'Možeš obrisati sve podatke u bilo kojem trenutku iz Postavki > Obriši sve podatke.';

  @override
  String get deleteAllData => 'Obriši sve podatke';
  @override
  String get deleteAllDataSubtitle => 'Ukloni sve profile, PIN i postavke';
  @override
  String get deleteAllDataConfirm => 'Obriši sve';
  @override
  String get deleteAllDataWarning =>
      'Ovo će trajno obrisati sve profile, tvoj PIN i sve postavke. Aktivni štitovi će biti uklonjeni. Ovo se ne može poništiti.';

  @override
  String get onboardingTitle1 => 'Preuzmi kontrolu nad vremenom';
  @override
  String get onboardingBody1 =>
      'Unspend ti pomaže blokirati aplikacije koje odvlače pažnju na razini OS-a kako bi se mogao/la fokusirati na ono što je važno.';
  @override
  String get onboardingTitle2 => 'Izradi profile blokiranja';
  @override
  String get onboardingBody2 =>
      'Postavi profile s kombinabilnim pravilima: vremenski rasporedi, dnevna ograničenja korištenja i otključavanje na temelju zadataka.';
  @override
  String get onboardingTitle3 => 'Zaštita koju ne možeš preskočiti';
  @override
  String get onboardingBody3 =>
      'Štitove primjenjuje sam iOS. PIN i tajmer hlađenja sprječavaju impulzivno isključivanje.';
  @override
  String get getStarted => 'Počni';
  @override
  String get next => 'Dalje';
  @override
  String get skip => 'Preskoči';
}

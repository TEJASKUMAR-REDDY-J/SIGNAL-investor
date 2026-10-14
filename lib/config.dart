// Build-time values from .env (flutter run/build --dart-define-from-file=.env).
// The key is compiled into the APK: keep the APK private. A key pasted in
// Settings (secure storage, per profile) takes priority over this default.
const groqKeyFromEnv = String.fromEnvironment('GROQ_API_KEY');
const groqModelDefault = String.fromEnvironment('GROQ_MODEL', defaultValue: 'openai/gpt-oss-120b');

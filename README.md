# Privy
Your privacy. Your control.

Proyecto Flutter/Dart para Android e iOS. Tema negro, azul para acciones, nombre completamente blanco. Sin datos precargados. El backend es Supabase Auth + Postgres, sin servidor propio. Requiere Internet para cargar y guardar; no incluye modo offline.

## Configurar Supabase
1. Crea un proyecto en https://supabase.com.
2. Abre SQL Editor > New query, pega `supabase/setup.sql` y ejecuta Run. No crea usuarios ni credenciales de ejemplo.
3. En Authentication > Providers habilita Email. Mantén confirmación de correo, configura SMTP para producción. Al confirmar el email, vuelve a la app e inicia sesión manualmente.
4. Copia Project URL y la clave publishable (o anon). Nunca uses service_role o secret en el móvil.
5. Copia `config.example.json` a `config.json` y completa ambos valores.

## Ejecutar en Windows / Android
Instala Flutter estable, Android Studio, SDK y Python 3; activa depuración USB. Abre PowerShell en esta carpeta:

```powershell
flutter doctor
python scripts/setup.py
Copy-Item config.example.json config.json
# Edita config.json con tus valores
flutter analyze
flutter test
flutter devices
flutter run --dart-define-from-file=config.json
```

El script genera los proyectos nativos Android/iOS con tu versión de Flutter, añade permisos biométricos y configura el icono. No sobrescribe runners existentes. Ejecuta una sola vez por copia limpia. Para APK: `flutter build apk --dart-define-from-file=config.json`.

## iOS
En macOS con Xcode y CocoaPods: ejecuta `python3 scripts/setup.py` si no has generado los runners. Abre `ios/Runner.xcworkspace` tras instalar pods mediante Flutter. Configura Signing & Capabilities con tu equipo Apple y un bundle ID único. Prueba Face ID/Touch ID en dispositivo. `flutter run --dart-define-from-file=config.json` o `flutter build ios --dart-define-from-file=config.json`. Android requiere API 23 o superior. La versión mínima real de iOS depende de Flutter y los plugins.

## Primer uso
Crea una cuenta real con correo, confirma correo si corresponde, entra, configura una contraseña maestra distinta de la de cuenta (12 caracteres como mínimo). La bóveda aparece vacía. Pulsa + para crear carpeta. Puedes protegerla con una contraseña independiente. Pulsa + dentro de ella para registrar cuentas, sistemas, API, notas, campos personalizados. Mantén pulsada una carpeta para renombrar, proteger/cambiar clave o eliminar. Ajustes activa biometría para la bóveda (no para carpetas). Al salir o tras dos minutos sin pulsaciones se bloquea. Los favoritos están marcados en cada carpeta; no hay vista global. No hay subcarpetas en esta versión.

## Seguridad y límites
- AES-256-GCM con nonce aleatorio y contexto asociado; Argon2id 64 MiB, 3 iteraciones, paralelismo 2. Clave de bóveda aleatoria, envuelta con clave derivada de la contraseña maestra. Supabase recibe solo ciphertext, salt, versión y owner. Carpetas protegidas: segunda capa de cifrado con salt y contraseña propios, títulos/descripciones de carpeta visibles solo tras desbloquear bóveda. La base usa RLS por propietario y actualización por revisión para evitar sobrescritura concurrente. Sin recuperación de claves de bóveda/carpeta; no pierdas las contraseñas. No hay recuperación/exportación de backup integrada.
- La biometría opcional usa biometric_storage (Keystore/Keychain) para guardar la clave de bóveda con autenticación biométrica. No guarda huellas. El acceso biométrico es una alternativa a la contraseña maestra, no un segundo factor obligatorio. Las carpetas requieren su contraseña. Android FLAG_SECURE; iOS no garantiza impedir capturas. Limpieza de portapapeles es de mejor esfuerzo. No garantiza borrado de memoria Dart, protección contra root/jailbreak, malware, rollback del servidor ni dispositivos comprometidos.
- No hay SDK de analítica ni registros de contraseñas. Supabase Auth conserva sesiones de cuenta; la bóveda siempre necesita desbloqueo. RLS protege usuarios, no sustituye el cifrado. El servidor puede ver metadatos de sincronización, tamaño y correo de cuenta.
- Proyecto inicial sin auditoría independiente. NO introducir secretos reales hasta revisar código, ejecutar pruebas de Flutter, verificar RLS con dos cuentas, comprobar bloqueo y biometría en ambos sistemas, y realizar pruebas de pérdida de conexión y conflictos. El entorno de creación no dispone de Flutter ni dispositivos; no se compiló ni se ejecutó la app. Las versiones de dependencias deben resolverse localmente. El nombre comercial no está verificado.

## Archivos
`lib/main.dart` interfaz; `lib/store.dart` sincronización y biometría; `lib/crypto.dart` cifrado; `supabase/setup.sql` base de datos; `scripts/setup.py` generación de plataformas; `test/crypto_test.dart` prueba inicial.

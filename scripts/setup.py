"""Run from the project directory with Flutter installed. Generates native runners only."""
import os, subprocess, pathlib, tempfile, shutil, plistlib, re
root=pathlib.Path(__file__).resolve().parents[1]
flutter=shutil.which('flutter') or shutil.which('flutter.bat')
if not flutter: raise SystemExit('Install Flutter stable and add it to PATH.')
with tempfile.TemporaryDirectory() as td:
    p=pathlib.Path(td)/'privy'
    subprocess.run([flutter,'create','--platforms=android,ios','--org','com.privyapp',str(p)],check=True)
    for platform in ('android','ios'):
        if not (root/platform).exists(): shutil.copytree(p/platform,root/platform)
android=root/'android'
for f in android.rglob('MainActivity.kt'):
    s=f.read_text(); s=s.replace('import io.flutter.embedding.android.FlutterActivity','import io.flutter.embedding.android.FlutterFragmentActivity').replace(': FlutterActivity()',': FlutterFragmentActivity()'); f.write_text(s)
for f in (android/'app').glob('build.gradle*'):
    s=f.read_text();s=re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion','minSdk = 23',s);s=s.replace('minSdkVersion flutter.minSdkVersion','minSdkVersion 23');f.write_text(s)
f=android/'app/src/main/AndroidManifest.xml';s=f.read_text();s=s.replace('android:label="privy"','android:label="Privy"');
if 'android.permission.INTERNET' not in s:s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
if 'android.permission.USE_BIOMETRIC' not in s:s=s.replace('<application','<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <application',1)
if 'android:allowBackup=' not in s:
    s=s.replace('android:label="Privy"','android:label="Privy" android:allowBackup="false"')
f.write_text(s)
# avoid snapshots/screenshots on Android
for f in android.rglob('MainActivity.kt'):
    s=f.read_text();s=s.replace('class MainActivity : FlutterFragmentActivity()', 'class MainActivity : FlutterFragmentActivity()');
    if 'FLAG_SECURE' not in s:
        s=re.sub(r'class MainActivity\s*:\s*FlutterFragmentActivity\(\)\s*\{\s*\}', '''class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
    }
}''',s)
    f.write_text(s)
f=root/'ios/Runner/Info.plist';data=plistlib.loads(f.read_bytes());data['NSFaceIDUsageDescription']='Desbloquear tu bóveda Privy de forma segura.';data['CFBundleDisplayName']='Privy';f.write_bytes(plistlib.dumps(data))
subprocess.run([flutter,'pub','get'],cwd=root,check=True)
dart = pathlib.Path(flutter).parent / ('cache/dart-sdk/bin/dart.exe' if os.name == 'nt' else 'dart')
subprocess.run([str(dart), 'run', 'flutter_launcher_icons'], cwd=root, check=True)
print('Privy preparado. Ejecuta flutter analyze y flutter run con tus credenciales.')

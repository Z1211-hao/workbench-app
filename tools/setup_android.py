"""flutter create 生成 android 壳后调用（GitHub Actions 里执行）：
1) 关闭 R8 全量混淆 —— 环信 SDK 引用了各厂商推送类（OPPO/vivo/小米/魅族），
   未集成这些 SDK 时 R8 会报 Missing class；双人小应用无混淆需求。
2) 给 main Manifest 补 INTERNET / CAMERA 权限 —— Flutter 模板只在 debug manifest 里有，
   release 包不带它就连不上环信服务器（INTERNET）、无法拍照识热量（CAMERA）。
3) 固定 minSdk = 23 —— audioplayers 6.x 的安卓端要求 minSdk >= 23，
   Flutter 模板默认 21/24 可能触发 Manifest merger 失败。
"""
import os
import sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 1) 关闭混淆
patched = False
for rel in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    path = os.path.join(root, rel)
    if not os.path.exists(path):
        continue
    text = open(path, encoding='utf-8').read()
    if 'isMinifyEnabled' in text or 'minifyEnabled' in text:
        patched = True
        break
    # Kotlin DSL（Flutter 3.16+ 默认）
    new = text.replace(
        'release {',
        'release {\n            isMinifyEnabled = false\n            isShrinkResources = false',
        1,
    )
    if new == text:
        # Groovy DSL（旧模板）
        new = text.replace(
            'release {',
            'release {\n            minifyEnabled false\n            shrinkResources false',
            1,
        )
    if new == text:
        sys.exit('未找到 release 构建块：' + rel)
    open(path, 'w', encoding='utf-8').write(new)
    patched = True
    break

if not patched:
    sys.exit('未找到 android/app/build.gradle(.kts)')

# 2) 补 INTERNET / CAMERA 权限
manifest = os.path.join(root, 'android/app/src/main/AndroidManifest.xml')
if os.path.exists(manifest):
    text = open(manifest, encoding='utf-8').read()
    add = ''
    if 'android.permission.INTERNET' not in text:
        add += '<uses-permission android:name="android.permission.INTERNET" />\n    '
    if 'android.permission.CAMERA' not in text:
        add += '<uses-permission android:name="android.permission.CAMERA" />\n    '
    if add:
        text = text.replace(
            '<application',
            add + '<application',
            1,
        )
        open(manifest, 'w', encoding='utf-8').write(text)

# 3) 固定 minSdk = 23（Kotlin DSL 与 Groovy DSL 双兼容）
for rel, repl in (
    ('android/app/build.gradle.kts', 'minSdk = flutter.minSdkVersion'),
    ('android/app/build.gradle', 'minSdkVersion flutter.minSdkVersion'),
):
    path = os.path.join(root, rel)
    if not os.path.exists(path):
        continue
    text = open(path, encoding='utf-8').read()
    if repl in text:
        open(path, 'w', encoding='utf-8').write(text.replace(repl, 'minSdk = 23', 1) if rel.endswith('.kts') else text.replace(repl, 'minSdkVersion 23', 1))
        break

#!/usr/bin/env bash
# 快速设置脚本
# 运行: bash gen.sh

echo "📦 安装依赖..."
flutter pub get

echo "🎨 生成 App 图标..."
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

echo "✅ 完成！现在可以运行 flutter run 了"

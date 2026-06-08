#!/usr/bin/env bash
# 代码生成脚本
# 运行: bash gen.sh

echo "📦 安装依赖..."
flutter pub get

echo "🔨 生成 freezed / json_serializable 代码..."
dart run build_runner build --delete-conflicting-outputs

echo "🎨 生成 App 图标..."
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

echo "✅ 全部完成！"

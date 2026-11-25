#!/usr/bin/env bash
# 必要なコマンドが無ければ、無いものと入れ方を表示して 2 で終わる（SessionEnd と Skill の両方から使う）
missing=
for c in claude jq perl; do command -v "$c" >/dev/null || missing="$missing $c"; done
[ -n "$missing" ] || exit 0
echo "memory-tools: コマンドが見つからないため、セッション終了時に記憶を更新できません:$missing" >&2
case "$missing" in
  *jq* | *perl*) echo "入れ方: macOS は brew install jq perl / Debian・Ubuntu は sudo apt install jq perl / Fedora は sudo dnf install jq perl" >&2 ;;
esac
case "$missing" in *claude*) echo "claude は、PATH から実行できるようにしてください" >&2 ;; esac
exit 2

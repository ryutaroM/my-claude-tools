#!/usr/bin/env bash
# SessionEnd: 終わったセッションを「未整理リスト」に1行追記する。
# SessionEnd は既定で1.5秒しか待たれないので、軽い処理だけにする（jq 不要）。
set -u

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || exit 0

INPUT=$(cat)
field() {
  printf '%s' "$INPUT" \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
    | head -n1
}

SID=$(field session_id)
TP=$(field transcript_path)
CWD=$(field cwd)
PROJECT="${CLAUDE_PROJECT_DIR:-$CWD}"

# 中身のないセッション（開いてすぐ閉じた等）は記録しない
[ -n "$TP" ] && [ -s "$TP" ] || exit 0
# yumemi 自体を実行したセッションは記録しない（自分の整理作業を再整理しないため）
# スキル名はスキル一覧や通知文にも現れるので、実際の呼び出し（Skill ツール / スラッシュコマンド）だけに一致させる
# （短縮形 /yumemi でも起動できるので、プラグイン名の接頭辞は省略可とする）
grep -qE '"skill"[[:space:]]*:[[:space:]]*"([^":]+:)?yumemi"|<command-name>/([^<:]+:)?yumemi</command-name>' "$TP" 2>/dev/null && exit 0

mkdir -p "$DATA"
# 形式: 記録時刻(UTC) <TAB> プロジェクト <TAB> トランスクリプト <TAB> セッションID
printf '%s\t%s\t%s\t%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PROJECT" "$TP" "$SID" >> "$DATA/pending.tsv"
exit 0

#!/usr/bin/env bash
# SessionStart(startup): このプロジェクトの未整理セッションが閾値以上なら、
# その事実を1行だけ出力する（stdout は Claude のコンテキストに入る）。
set -u

cat >/dev/null  # stdin は使わないので読み捨てる

DATA="${CLAUDE_PLUGIN_DATA:-}"
PENDING="$DATA/pending.tsv"
THRESHOLD="${CLAUDE_PLUGIN_OPTION_THRESHOLD:-5}"
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"

[ -n "$DATA" ] && [ -f "$PENDING" ] || exit 0

# 設定は number 型で小数も入りうる。正の整数でなければ既定値に戻す
case "$THRESHOLD" in
  *[!0-9]* | 0*) THRESHOLD=5 ;;
esac

# 同じトランスクリプトは1件と数え、既に削除されたものは数えない
# （awk -v はバックスラッシュを解釈するので、パスは環境変数で渡す）
COUNT=0
while IFS= read -r tp; do
  [ -s "$tp" ] && COUNT=$((COUNT + 1))
done < <(YUMEMI_PROJECT="$PROJECT" awk -F'\t' '$2 == ENVIRON["YUMEMI_PROJECT"] && !seen[$3]++ { print $3 }' "$PENDING")

if [ "$COUNT" -ge "$THRESHOLD" ]; then
  echo "yumemi: このプロジェクトには未整理のセッションが ${COUNT} 件たまっている（閾値 ${THRESHOLD} 件）。/memory-tools:yumemi で記憶を整理できる。"
fi
exit 0

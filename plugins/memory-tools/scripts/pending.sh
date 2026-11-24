#!/usr/bin/env bash
# 未整理セッション（前回の整理より後に更新されたトランスクリプト）を扱う。
#   pending.sh notify               SessionStart hook 用。閾値以上なら1行だけ出力する
#   pending.sh start <session-id>   整理の開始。対象を古い順に出力し、確定前の印を付ける
#   pending.sh finish <session-id>  整理の完了。start の印を確定する
# 印は memory/.yumemi-last の更新時刻。start の時点の時刻を使うので、整理中に追記された分は次回また対象になる。
set -u

LIMIT=20

# yumemi のために開いたセッションか（自分の整理作業を再整理しないため）
# 作業の途中で yumemi が起動されたセッションには拾うべき訂正も含まれるので、
# 最初のユーザー発言が /yumemi のものだけを除く
opened_for_yumemi() {
  grep -m1 '"type":"user"' "$1" 2>/dev/null | grep -qE '<command-name>/([^<:]+:)?yumemi</command-name>'
}

# 未整理のトランスクリプトを古い順に出力する: list <ディレクトリ> <除外するトランスクリプト>
list() {
  local f
  # shellcheck disable=SC2012  # ファイル名は Claude Code が付ける UUID なので ls で並べてよい
  ls -tr "$1"/*.jsonl 2>/dev/null | while IFS= read -r f; do
    [ "$f" != "$2" ] && [ -s "$f" ] || continue
    # bash 3.2 の -nt は秒単位で同じ秒の更新を取りこぼすので、find で比べる
    if [ -f "$1/memory/.yumemi-last" ]; then
      [ -n "$(find "$f" -newer "$1/memory/.yumemi-last")" ] || continue
    fi
    opened_for_yumemi "$f" && continue
    printf '%s\n' "$f"
  done
}

# セッションIDからそのトランスクリプトのパスを求める
find_transcript() {
  local f
  case "$1" in
    '' | *[!A-Za-z0-9-]*) return 1 ;;
  esac
  for f in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/projects/*/"$1.jsonl"; do
    [ -f "$f" ] && printf '%s\n' "$f" && return 0
  done
  return 1
}

case "${1:-}" in
  notify)
    TP=$(sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    [ -n "$TP" ] || exit 0

    THRESHOLD="${CLAUDE_PLUGIN_OPTION_THRESHOLD:-5}"
    # 設定は number 型で小数も入りうる。正の整数でなければ既定値に戻す
    case "$THRESHOLD" in
      *[!0-9]* | 0*) THRESHOLD=5 ;;
    esac

    # セッション開始を遅らせないよう、閾値に達したら数えるのをやめる
    COUNT=$(list "$(dirname "$TP")" "$TP" | head -n "$THRESHOLD" | wc -l)
    if [ "$COUNT" -ge "$THRESHOLD" ]; then
      echo "yumemi: このプロジェクトには未整理のセッションが ${THRESHOLD} 件以上たまっている。/memory-tools:yumemi で記憶を整理できる。"
    fi
    ;;

  start | finish)
    SELF=$(find_transcript "${2:-}") || {
      echo "pending: セッション ${2:-} のトランスクリプトが見つからない" >&2
      exit 1
    }
    DIR=$(dirname "$SELF")
    LAST="$DIR/memory/.yumemi-last"
    NEXT="$DIR/memory/.yumemi-next"

    if [ "$1" = finish ]; then
      [ -f "$NEXT" ] || { echo "pending: 確定する印が無い"; exit 0; }
      mv "$NEXT" "$LAST" || exit 1
      echo "pending: 整理済みとして記録した"
      exit 0
    fi

    rm -f "$NEXT"
    TARGETS=$(list "$DIR" "$SELF")
    echo "トランスクリプトのディレクトリ: $DIR"
    [ -n "$TARGETS" ] || { echo "対象: 0 件"; exit 0; }
    TOTAL=$(printf '%s\n' "$TARGETS" | wc -l | tr -d ' ')
    TARGETS=$(printf '%s\n' "$TARGETS" | head -n "$LIMIT")
    mkdir -p "$DIR/memory" && touch -r "$(printf '%s\n' "$TARGETS" | tail -n 1)" "$NEXT" || exit 1
    echo "対象: $(printf '%s\n' "$TARGETS" | wc -l | tr -d ' ') 件（未整理 ${TOTAL} 件のうち古い順）"
    printf '%s\n' "$TARGETS"
    ;;

  *)
    echo "usage: pending.sh notify | start <session-id> | finish <session-id>" >&2
    exit 2
    ;;
esac
exit 0

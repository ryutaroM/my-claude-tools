#!/usr/bin/env bash
# 整理が済んだセッションを未整理リストから消す（yumemi スキルの後片付け用）。
# 使い方: mark-done.sh <データディレクトリ> <プロジェクト> [処理済みトランスクリプト...]
# 消すのは指定プロジェクトの行のうち、処理済みのものと、トランスクリプトが既に無いものだけ。
set -u

if [ "$#" -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
  echo "usage: mark-done.sh <data-dir> <project> [transcript...]" >&2
  exit 2
fi
PENDING="$1/pending.tsv"
PROJECT="$2"
shift 2

[ -f "$PENDING" ] || { echo "mark-done: 未整理リストは無い"; exit 0; }

is_done() {
  local target="$1" t
  shift
  for t in "$@"; do
    [ "$t" = "$target" ] && return 0
  done
  return 1
}

# 途中で失敗しても元のリストが壊れないよう、同じディレクトリの一時ファイルに書いてから置き換える
TMP=$(mktemp "$PENDING.XXXXXX") || exit 1
trap 'rm -f "$TMP"' EXIT

TAB=$'\t'
DONE=0
GONE=0
KEPT=0
while IFS= read -r line || [ -n "$line" ]; do
  rest="${line#*"$TAB"}"
  project="${rest%%"$TAB"*}"
  rest="${rest#*"$TAB"}"
  tp="${rest%%"$TAB"*}"
  if [ "$project" = "$PROJECT" ]; then
    if is_done "$tp" "$@"; then
      DONE=$((DONE + 1))
      continue
    elif [ ! -s "$tp" ]; then
      GONE=$((GONE + 1))
      continue
    fi
  fi
  printf '%s\n' "$line" >> "$TMP" || exit 1
  KEPT=$((KEPT + 1))
done < "$PENDING"

mv "$TMP" "$PENDING" || exit 1
echo "mark-done: 処理済み ${DONE} 行とトランスクリプトの無い ${GONE} 行を削除、${KEPT} 行を残した"

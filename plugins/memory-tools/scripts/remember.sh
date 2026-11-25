#!/usr/bin/env bash
# SessionEnd: 終わった会話を裏で別の Claude に読ませ、残すべきことを auto memory に反映する。
set -u

# 対話セッションだけを対象にする（裏の claude 自身や claude -p の自動実行では動かない）
[ "${CLAUDE_CODE_ENTRYPOINT:-}" = cli ] && [ -z "${MEMORY_TOOLS_RUNNING:-}" ] || exit 0

TP=$(sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
[ -s "$TP" ] || exit 0

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 0
bash "$ROOT/scripts/check-deps.sh" || exit 2

# 何を残すかの規則は Skill に置く。frontmatter と、手入力のときだけ使う依存確認（! の行）は除く
# （Skill として起動すると、会話の原文が書き換わり、Bash 無しでは依存確認で失敗するので、本文を渡す）
PROMPT=$(sed -e '1,/^---$/d' -e '/^!/d' "$ROOT/skills/yumemi/SKILL.md")
[ -n "$PROMPT" ] || exit 0

# 書き換える前に、全プロジェクトの記憶を写しておく（前回と同じなら取らない。直近20回分を残す）
# shellcheck disable=SC2012  # 扱うのは自分で付けた日時の名前だけ
backup() {
  [ -n "${CLAUDE_PLUGIN_DATA:-}" ] || return 0
  local projects=${TP%/*/*} dir="$CLAUDE_PLUGIN_DATA/backup" new last d n
  new="$dir/$(date +%Y%m%d-%H%M%S)-$$"
  last=$(ls -1 "$dir" 2>/dev/null | sort | tail -n 1)
  for d in "$projects"/*/memory; do
    [ -d "$d" ] || continue
    n=${d%/memory}; n=${n##*/}
    mkdir -p "$new/$n" && cp -Rp "$d/." "$new/$n/" || return 0
  done
  [ -d "$new" ] || return 0
  if [ -n "$last" ] && diff -rq "$dir/$last" "$new" >/dev/null 2>&1; then rm -rf "$new"; return 0; fi
  n=$(ls -1 "$dir" | wc -l)
  [ "$n" -le 20 ] || ls -1 "$dir" | sort | head -n $((n - 20)) | while read -r d; do rm -rf "${dir:?}/$d"; done
}

# SessionEnd は短時間しか待たれないので、切り離して裏で続ける
(
  trap '' HUP
  # ユーザーと Claude の発言だけを取り出す（長い会話は末尾だけ）。@ は、書かれたファイルが読み込まれないよう全角にする
  TALK=$(jq -r 'select((.type == "user" or .type == "assistant") and (.isMeta | not))
    | .type as $who | .message.content
    | if type == "string" then . else map(select(.type == "text").text) | join("\n") end
    | select(length > 0) | "[\($who)] \(.)" | split("@") | join("＠")' "$TP" | tail -c 60000)
  [ -n "$TALK" ] || exit 0
  backup

  # 終わったセッションと同じプロジェクトの auto memory を使わせる
  cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
  # 固まっても残り続けないよう10分で終わらせる（alarm は exec 後も有効。macOS に timeout は無い）
  printf '%s\n' "$TALK" | MEMORY_TOOLS_RUNNING=1 perl -e 'alarm 600; exec @ARGV' claude -p "$PROMPT" \
    --model sonnet --tools "Read,Edit,Write,Glob" --strict-mcp-config \
    --no-session-persistence --max-budget-usd 0.5
) </dev/null >/dev/null 2>&1 &
exit 0

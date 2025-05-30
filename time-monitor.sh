#!/data/data/com.termux/files/usr/bin/bash

FLAGS_FILE="./flags.json"
TAP_COUNT_FILE="./tap-count.txt"

update_flag() {
  jq --arg key "$1" --argjson val "$2" '.[$key] = $val' "$FLAGS_FILE" > flags.tmp && mv flags.tmp "$FLAGS_FILE"
}

LAST_TAP_TIME=$(date +%s)
TAP_TIMEOUT=15
WAIT_WINDOW=0.6
TRIPLE_WINDOW=0.2

while true; do
  FLAGS=$(cat "$FLAGS_FILE")
  MODE=$(jq -r '.mode' <<< "$FLAGS")
  EXECUTED=$(jq -r '.executed' <<< "$FLAGS")
  PREV_COUNT=$(cat "$TAP_COUNT_FILE" 2>/dev/null || echo 0)

  inotifywait -qq -e modify "$TAP_COUNT_FILE" || continue
  CURR_COUNT=$(cat "$TAP_COUNT_FILE")
  TAP_TIME=$(date +%s%3N)

  if [[ "$MODE" == "idle" ]]; then
    sleep "$WAIT_WINDOW"
    if [[ $(cat "$TAP_COUNT_FILE") -gt "$CURR_COUNT" ]]; then
      sleep "$TRIPLE_WINDOW"
      if [[ $(cat "$TAP_COUNT_FILE") -gt "$CURR_COUNT" ]]; then
        update_flag "mode" '"active"'
        update_flag "tap_sequence" '[]'
        update_flag "executed" false
        update_flag "single_tap" 0
        update_flag "double_tap" 0
        update_flag "triple_tap" 0
      else
        update_flag "mode" '"active"'
      fi
    fi
  else
    sleep "$WAIT_WINDOW"
    NEW_COUNT=$(cat "$TAP_COUNT_FILE")
    if [[ "$NEW_COUNT" -gt "$CURR_COUNT" ]]; then
      sleep "$TRIPLE_WINDOW"
      FINAL_COUNT=$(cat "$TAP_COUNT_FILE")
      TAP_TYPE=1
      [[ "$FINAL_COUNT" -gt "$NEW_COUNT" ]] && TAP_TYPE=3 || TAP_TYPE=2

      TAP_SEQ=$(jq '.tap_sequence' "$FLAGS_FILE")
      TAP_SEQ=$(jq --argjson t "$TAP_TYPE" '. + [$t]' <<< "$TAP_SEQ")
      jq --argjson seq "$TAP_SEQ" '.tap_sequence = $seq' "$FLAGS_FILE" > flags.tmp && mv flags.tmp "$FLAGS_FILE"
    fi
  fi

  sleep 0.1
done

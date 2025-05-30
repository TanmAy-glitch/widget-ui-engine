#!/data/data/com.termux/files/usr/bin/bash

FLAGS_FILE="./flags.json"
TEMPLATE_DIR="./Custom-UI/template-states"
TEMPLATE_NAME="home-temp"
TAP_COUNT_FILE="./tap-count.txt"

FLAGS=$(cat "$FLAGS_FILE")
MODE=$(jq -r '.mode' <<< "$FLAGS")
SEQ=$(jq -r '.tap_sequence | map(tostring) | join(",")' <<< "$FLAGS")

tap_to_block() {
  case "$1" in
    1) echo "▢" ;;
    2) echo "▢▢" ;;
    3) echo "▢▢▢" ;;
    *) echo "" ;;
  esac
}

IFS=',' read -r -a taps <<< "$SEQ"
click1=""
click2=""
click3=""

(( ${#taps[@]} > 0 )) && click1=$(tap_to_block "${taps[0]}")
(( ${#taps[@]} > 1 )) && click2=$(tap_to_block "${taps[1]}")
(( ${#taps[@]} > 2 )) && click3=$(tap_to_block "${taps[2]}")

if [[ "$MODE" == "idle" ]]; then
  TEMPLATE_FILE="$TEMPLATE_DIR/${TEMPLATE_NAME}_idle.txt"
else
  TEMPLATE_FILE="$TEMPLATE_DIR/${TEMPLATE_NAME}_live.txt"
fi

# Update tap count file
echo $(( $(cat "$TAP_COUNT_FILE" 2>/dev/null || echo 0) + 1 )) > "$TAP_COUNT_FILE"

# Output template
sed -e "s/{click1}/$click1/g" \
    -e "s/{click2}/$click2/g" \
    -e "s/{click3}/$click3/g" \
    "$TEMPLATE_FILE"

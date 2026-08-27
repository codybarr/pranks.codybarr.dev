#!/bin/sh
# Send a random dad joke notification to your coworker every 5 minutes
set -eu

PLIST="$HOME/Library/LaunchAgents/com.pranks.dadjokes.plist"
JOB="gui/$(id -u)/com.pranks.dadjokes"
SCRIPT="$HOME/dadjokes.sh"

if [ "${1:-}" = "--uninstall" ]; then
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [--uninstall]" >&2
    exit 2
  fi

  launchctl bootout "$JOB" 2>/dev/null || true
  rm -f "$PLIST" "$SCRIPT" /tmp/dadjokes.out /tmp/dadjokes.err
  echo "Dad jokes prank uninstalled."
  exit 0
fi

if [ "$#" -ne 0 ]; then
  echo "Usage: $0 [--uninstall]" >&2
  exit 2
fi

touch "$SCRIPT"
cat > "$SCRIPT" <<'EOF'
#!/bin/bash

JOKE=$(curl -s \
  -H "Accept: application/json" \
  https://icanhazdadjoke.com/ | \
  jq -r '.joke')

osascript -e "display notification \"$JOKE\" with title \"😂 Dad Joke\""
EOF
chmod +x "$SCRIPT"

mkdir -p "$HOME/Library/LaunchAgents"
touch "$PLIST"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.pranks.dadjokes</string>

    <key>ProgramArguments</key>
    <array>
      <string>$SCRIPT</string>
    </array>

    <key>StartInterval</key>
    <integer>300</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/dadjokes.out</string>

    <key>StandardErrorPath</key>
    <string>/tmp/dadjokes.err</string>
  </dict>
</plist>
EOF
plutil -lint "$PLIST"
# Remove a previously loaded copy so this installer can be run again.
launchctl bootout "$JOB" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

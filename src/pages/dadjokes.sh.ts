const script = `#!/bin/sh
# Send a random dad joke notification to your coworker every 5 minutes
set -eu

touch "$HOME/dadjokes.sh"
cat > "$HOME/dadjokes.sh" <<'EOF'
#!/bin/bash

JOKE=$(curl -s \\
  -H "Accept: application/json" \\
  https://icanhazdadjoke.com/ | \\
  jq -r '.joke')

osascript -e "display notification \"$JOKE\" with title \"😂 Dad Joke\""
EOF
chmod +x "$HOME/dadjokes.sh"

touch "$HOME/Library/LaunchAgents/com.pranks.dadjokes.plist"
cat > "$HOME/Library/LaunchAgents/com.pranks.dadjokes.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.pranks.dadjokes</string>

    <key>ProgramArguments</key>
    <array>
      <string>$HOME/dadjokes.sh</string>
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
plutil -lint "$HOME/Library/LaunchAgents/com.pranks.dadjokes.plist"
# Remove a previously loaded copy so this installer can be run again.
launchctl bootout "gui/$(id -u)/com.pranks.dadjokes" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.pranks.dadjokes.plist"
`;

export const GET = () =>
  new Response(script, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Disposition": 'inline; filename="dadjokes.sh"',
    },
  });

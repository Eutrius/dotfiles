#!/usr/bin/env bash
# Start the first available polkit authentication agent

# Possible polkit agent paths, in priority order
polkit=(
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    "/usr/lib/polkit-kde-authentication-agent-1"
    "/usr/lib/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-gnome-authentication-agent-1"
    "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
    "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

for file in "${polkit[@]}"; do
    if [ -e "$file" ]; then
        echo "File $file found, executing command..."
        exec "$file"
    fi
done

echo "None of the specified files were found. Install a Polkit"

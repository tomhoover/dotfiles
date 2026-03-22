# shellcheck shell=sh
# Set window root path. Default is `$session_root`.
# Must be called before `new_window`.
#window_root "~/Projects/xyz"

# Create new window. If no argument is given, window name will be based on
# layout file name.
# new_window "xyz"
new_window

# Split window into panes.
split_h 40
split_v 50

# Run commands.
#run_cmd "top"     # runs in active pane
run_cmd "opencode" 1
run_cmd "source switch-to-main-worktree.sh && clear" 2

# Paste text
#send_keys "top"    # paste into active pane
#send_keys "date" 1 # paste into pane 1

# Set active pane.
select_pane 1

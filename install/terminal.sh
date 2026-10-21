# Ensure computer doesn't go to sleep while installing
keep_awake

# Run terminal installers
for installer in "$OMAKMA_PATH"/install/terminal/*.sh; do source "$installer"; done

# Revert to normal idle settings
let_sleep

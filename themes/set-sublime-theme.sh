SUBLIME_SUPPORT="$HOME/Library/Application Support/Sublime Text"

# Nothing to theme, and nothing to clone into, when Sublime Text's config is not
# there. The package clone used to run regardless, creating a directory tree and
# pulling a repository from the network for an app that is not installed.
if [ ! -d "$SUBLIME_SUPPORT/Packages" ]; then
  return 0 2>/dev/null || exit 0
fi

if [ -n "$SUBLIME_PACKAGE_GITHUB" ]; then
  SUBLIME_PACKAGE_PATH="$SUBLIME_SUPPORT/Packages/$SUBLIME_PACKAGE_NAME"
  [ -d "$SUBLIME_PACKAGE_PATH" ] || git clone "https://github.com/$SUBLIME_PACKAGE_GITHUB.git" "$SUBLIME_PACKAGE_PATH"
fi

edit_config "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings" \
  "s/\"color_scheme\": \".*\"/\"color_scheme\": \"$SUBLIME_COLOR_SCHEME\"/g" \
  "s/\"light_theme\": \".*\"/\"light_theme\": \"$SUBLIME_LIGHT_THEME.sublime-theme\"/g" \
  "s/\"dark_theme\": \".*\"/\"dark_theme\": \"$SUBLIME_DARK_THEME.sublime-theme\"/g"

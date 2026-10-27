SUBLIME_SUPPORT="$HOME/Library/Application Support/Sublime Text"

# Nothing to theme, and nothing to clone into, when Sublime Text's config is not
# there. The package clone used to run regardless, creating a directory tree and
# pulling a repository from the network for an app that is not installed.
if [ ! -d "$SUBLIME_SUPPORT/Packages" ]; then
  return 0 2>/dev/null || exit 0
fi

if [ -n "$SUBLIME_PACKAGE_GITHUB" ]; then
  SUBLIME_PACKAGE_PATH="$SUBLIME_SUPPORT/Packages/$SUBLIME_PACKAGE_NAME"
  clone_if_missing "$SUBLIME_PACKAGE_PATH" "https://github.com/$SUBLIME_PACKAGE_GITHUB.git"

  # The scheme the edit below names lives inside that package, so writing it
  # when the clone did not arrive points Sublime Text at a file that is not
  # there. Leaving the theme as it was is the better of the two, and the only
  # one the user can undo. clone_if_missing reports the download itself; this
  # says what it meant for the theme.
  if [ ! -d "$SUBLIME_PACKAGE_PATH" ]; then
    echo "Sublime Text's theme was left as it was."
    return 0 2>/dev/null || exit 0
  fi
fi

edit_config "$SUBLIME_SUPPORT/Packages/User/Preferences.sublime-settings" \
  "s/\"color_scheme\": \".*\"/\"color_scheme\": \"$SUBLIME_COLOR_SCHEME\"/g" \
  "s/\"light_theme\": \".*\"/\"light_theme\": \"$SUBLIME_LIGHT_THEME.sublime-theme\"/g" \
  "s/\"dark_theme\": \".*\"/\"dark_theme\": \"$SUBLIME_DARK_THEME.sublime-theme\"/g"

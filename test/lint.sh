#!/bin/bash
# Run ShellCheck over everything in this repository that is bash.
#
# `find -name '*.sh'` is not enough on its own, which is how
# defaults/bash/functions -- the file every installer depends on -- went
# unchecked: bin/omakma, the shipped .bashrc and the helpers under
# defaults/bash/ all carry no extension. defaults/bash is globbed rather than
# listed so a new helper there cannot escape the linter just by being new.
#
# Deliberately left out:
#   defaults/bash/inputrc, configs/inputrc  readline config, not shell
#   configs/zshrc                           zsh, which ShellCheck cannot check
#
# CI runs this, and so should you before pushing.

set -u

cd "$(dirname "$0")/.." || exit 1

{
  find . -name '*.sh' -not -path './.git/*'
  find defaults/bash -type f ! -name inputrc
  printf '%s\n' bin/omakma configs/bashrc
} | sort -u | xargs shellcheck

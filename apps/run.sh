#!/bin/bash

export https_proxy=http://proxy.home.local:7890

for f in $(ls [0-9][0-9]*.sh|sort)
do
  echo ">>>>>>>Executing $f"
  if ! "./$f"; then
    echo
    echo ">>>>>>>ERROR: $f failed; stopping here instead of continuing to the next step."
    echo "        Fix the problem above and run ./run.sh again (the scripts are meant to be re-runnable)."
    exit 1
  fi
done

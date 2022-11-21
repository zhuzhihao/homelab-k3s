#!/bin/bash

export https_proxy=http://proxy.home.local:7890

for f in $(ls [0-9][0-9]*.sh|sort)
do
  echo ">>>>>>>Executing $f"
  eval ./$f
done

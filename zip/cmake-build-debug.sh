#!/usr/bin/env bash

find ~/qsc_ws/ | grep cmake-build-debug | cut -d "/" -f 2 | uniq -d >cmake-build-debug.txt
find ~/qsc_ws/ | grep .git | uniq -d >git.txt

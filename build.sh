#!/bin/bash

./build.sh.d/common.sh
check=$(./build.sh.d/check.sh)
echo $check
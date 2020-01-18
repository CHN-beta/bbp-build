#!/bin/bash

rm -f list.txt
touch list.txt

base_url="https://downloads.openwrt.org/releases/"
echo "base_url=$base_url"

# 抓取所有系统版本
versions=$(curl $base_url | grep '<tr><td class="n">' | awk '{split($0,b,'"\"\\\"\""');print b[4]}' | grep -v faillogs | grep -v packages)
versions=${versions//\// }
echo -e "versions:\n$versions"

for version in $versions
do
    targets=$(curl $base_url$version/targets/ | grep '<tr><td class="n">' | awk '{split($0,b,'"\"\\\"\""');print b[4]}')
    targets=${targets//\// }
    echo -e "targets:\n$targets"
    for target in $targets
    do
        subtargets=$(curl $base_url$version/targets/$target/ | grep '<tr><td class="n">' | awk '{split($0,b,'"\"\\\"\""');print b[4]}')
        subtargets=${subtargets//\// }
        echo -e "subtargets:\n$subtargets"
        for subtarget in $subtargets
        do
            sdk=$(curl $base_url$version/targets/$target/$subtarget/ | grep '<tr><td class="n">' | awk '{split($0,b,'"\"\\\"\""');print b[4]}' | grep tar.xz | grep sdk)
            echo "sdk:$sdk"
            echo "$base_url$version/targets/$target/$subtarget/$sdk" >> list.txt
        done
    done
done

#!/bin/bash

cat list.txt | while read line
do
    echo $line
    version=$(echo $line | awk '{print $1}')
    target=$(echo $line | awk '{print $2}')
    subtarget=$(echo $line | awk '{print $3}')
    sdk=$(echo $line | awk '{print $4}')
    url=$(echo $line | awk '{print $5}')
    
    curl -sO --retry 99 $url
    tar -xf $sdk.tar.xz
    cd $sdk
    git clone -q https://github.com/CHN-beta/xmurp-ua.git package/xmurp-ua
    make defconfig

    args="package/xmurp-ua/compile V=sc"

    # 18.06.x 以前的需要加参数
    result=$(echo $version | grep 18.06)
    if [ -z "$result" ]
    then
        arch=$(cat .config | grep CONFIG_ARCH | awk '{split($0,b,'"\"\\\"\""');print b[2]}')
        cross_compile="$(pwd)/staging_dir/$(ls staging_dir | grep toolchain)/bin/$arch-openwrt-linux-"
        args="$args ARCH=$arch CROSS_COMPILE=$cross_compile"
    fi

    # 编译
    echo $args
    make $args > compile.log 2>&1

    # 检查
    if [ ! -f bin/targets/$target/$subtarget*/packages/kmod-* ]
    then
        echo "here may build failed." > compile.log
    else
        mkdir test
        cp bin/targets/$target/$subtarget/packages/kmod-* test/
        cd test
        mv kmod-* test.tar
        tar -xf test.tar
        if [ ! -f data.tar.gz ]
        then
            echo "here may build failed." > compile.log
        else
            tar -xf data.tar.gz
            if [ ! -f lib/modules/*/*.ko ]
            then
                echo "here may build failed." > compile.log
            fi
        fi
        cd ..
    fi

    # 整理，清理
    echo $line >> ../compile.log
    cat compile.log >> ../compile.log
    mkdir -p ../bin/$version/$target/$subtarget
    cp bin/targets/$target/$subtarget/packages/kmod-* ../bin/$version/$target/$subtarget/
    cd ..
    rm -rf $sdk*
    
done
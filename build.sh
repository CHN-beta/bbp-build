#!/bin/bash

cat list.txt | while read line
do
    # 读取参数
    echo "building $line" | tee -a ../status.log
    version=$(echo $line | awk '{print $1}')
    target=$(echo $line | awk '{print $2}')
    subtarget=$(echo $line | awk '{print $3}')
    sdk=$(echo $line | awk '{print $4}')
    url=$(echo $line | awk '{print $5}')
    
    # 准备 SDK 和源代码
    curl -sO --retry 99 $url
    tar -xf $sdk.tar.xz
    cd $sdk
    git clone -q https://github.com/CHN-beta/xmurp-ua.git package/xmurp-ua

    # 准备编译参数
    args="package/xmurp-ua/compile V=sc"
    # 17.01.x 以前的需要加参数
    result=$(echo $version | grep 17.01)
    if [ ! -z "$result" ]
    then
        arch=$(cat .config | grep CONFIG_ARCH | awk '{split($0,b,'"\"\\\"\""');print b[2]}')
        cross_compile="$(pwd)/staging_dir/$(ls staging_dir | grep toolchain)/bin/$arch-openwrt-linux-"
        args="$args ARCH=$arch CROSS_COMPILE=$cross_compile"
    fi

    # 编译
    echo $args | tee -a ../status.log
    make defconfig >> compile.log 2>&1
    make $args >> compile.log 2>&1

    # 检查
    if [ ! -f bin/targets/$target/$subtarget*/packages/kmod-* ]
    then
        echo "here may build failed. ipk not found." | tee -a ../status.log
    else
        mkdir test
        cp bin/targets/$target/$subtarget/packages/kmod-* test/
        cd test
        mv kmod-* test.tar
        tar -xf test.tar
        if [ ! -f data.tar.gz ]
        then
            echo "here may build failed. data.tar.gz not found." | tee -a ../status.log
        else
            tar -xf data.tar.gz
            if [ ! -f lib/modules/*/*.ko ]
            then
                echo "here may build failed. ko not found." | tee -a ../status.log
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

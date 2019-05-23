#!/bin/bash

#sdk folders
VUNGLE_SDKS_DIR=../vungle_sdk_releases

#target sdk folder for build
TARGET_SDK_DIR=VungleSDK

#tmp_dir for builds
BUILD_DIR=/tmp/VungleSDKProxy_build_dir
IPHONE_BUILD_DIR=$BUILD_DIR/Release-iphoneos
SIMULATOR_BUILD_DIR=$BUILD_DIR/Release-iphonesimulator
LIPO_OUTPUT_DIR=$BUILD_DIR/lipo


#deploy dir
DEPOLY_DIR=../Runner/VungleSDKProxy

#code sign identity
CODE_SIGN_IDENTITY="iPhone Developer: Felix Zhang (RAR4PEMA99)"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $IPHONE_BUILD_DIR
mkdir -p $SIMULATOR_BUILD_DIR
mkdir -p $LIPO_OUTPUT_DIR

#build sdk proxy
build_sdk_proxy() {
	product_name="$1"
	echo "build vungle sdk proxy for $product_name"
	#clean
	xcodebuild -sdk iphonesimulator -project VungleSDKProxy.xcodeproj -configuration debug -scheme VungleSDKProxy \
	CONFIGURATION_BUILD_DIR=$SIMULATOR_BUILD_DIR PRODUCT_NAME=$product_name clean

	#build for simulator
	xcodebuild -sdk iphonesimulator -project VungleSDKProxy.xcodeproj -configuration debug -scheme VungleSDKProxy \
	CONFIGURATION_BUILD_DIR=$SIMULATOR_BUILD_DIR PRODUCT_NAME=$product_name build


	#clean
	xcodebuild -sdk iphoneos -project VungleSDKProxy.xcodeproj -configuration release -scheme VungleSDKProxy \
	CONFIGURATION_BUILD_DIR=$IPHONE_BUILD_DIR PRODUCT_NAME=$product_name clean

	#build for ios device
	xcodebuild -sdk iphoneos -project VungleSDKProxy.xcodeproj -configuration release -scheme VungleSDKProxy \
	CONFIGURATION_BUILD_DIR=$IPHONE_BUILD_DIR PRODUCT_NAME=$product_name OTHER_CFLAGS='-fembed-bitcode' BITCODE_GENERATION_MODE='bitcode'\
    build



	#lipo & merge
	target=$product_name
	lipo_output_path=$LIPO_OUTPUT_DIR/$target
    xcrun -sdk iphoneos lipo -create -output $lipo_output_path \
    ${IPHONE_BUILD_DIR}/$target.framework/$target \
    ${SIMULATOR_BUILD_DIR}/$target.framework/$target

    cp ${lipo_output_path} ${IPHONE_BUILD_DIR}/$target.framework/$target

    #code sign
    #codesign --verbose --force --sign "$CODE_SIGN_IDENTITY" --timestamp=none ${IPHONE_BUILD_DIR}/$target.framework

    #copy to deploy folder
    cp -r ${IPHONE_BUILD_DIR}/$target.framework $DEPOLY_DIR/

}


#go to vungle sdks dir, copy each framework to target sdk
for file in ${VUNGLE_SDKS_DIR}/*
do
	sdk_name=$(basename $file)
	#echo $file $sdk_name

	if [[ -d $file && $sdk_name == Vungle* ]]; then
		framework=$file/VungleSDK.framework
		#echo $framework
		if [[ -e $framework && -d $framework ]]; then
			#echo "framework exists!"
			rm -rf $TARGET_SDK_DIR/*
			cp -R $framework $TARGET_SDK_DIR/
			build_sdk_proxy "VungleSDKProxy_$sdk_name"
		fi
	fi
done



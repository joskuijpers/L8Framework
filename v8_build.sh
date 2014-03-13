#!/bin/sh

#
# Copyright (c) 2014 Jos Kuijpers. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

V8_OPTIONS="-Dv8_enable_disassembler=1 -Dv8_use_liveobjectlist=true -Dv8_deprecation_warnings=true"

cd v8

echo "Exporting environment variables..."
export GYP_GENERATORS=xcode
export GYP_DEFINES="clang=1 -Dcomponent=shared_library "${V8_OPTIONS}

echo "Retrieving dependencies..."
#make dependencies || exit $?

echo "Applying patches..."
for patch in ../Patches/*; do
	echo "   $patch..."
	git apply $patch || exit $?
done

echo "Creating Xcode projects..."
build/gyp_v8 -Dtarget_arch=x64 || exit $?

echo "Building V8..."
xcodebuild -project build/all.xcodeproj -configuration Release -j8 || exit $?

echo "Removing patches..."
for patch in ../Patches/*; do
	echo "   $patch..."
	git apply --reverse $patch || exit $?
done

echo "Done."

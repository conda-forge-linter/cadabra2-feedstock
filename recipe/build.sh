#!/bin/bash

REL_SP_DIR=$(python -c "import os;print(os.path.relpath(os.getenv('SP_DIR'), os.getenv('PREFIX')))")
sed -i.bak "s@set(PYTHON_SITE_PATH.*@set(PYTHON_SITE_PATH $REL_SP_DIR)@g" CMakeLists.txt

ln -sf $PREFIX/x86_64-conda-linux-gnu $PREFIX/x86_64-conda_cos6-linux-gnu

mkdir build
cd build

export CXXFLAGS="$CXXFLAGS -UNDEBUG"
export CFLAGS="$CFLAGS -UNDEBUG"

cmake \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_SYSTEM_JSONCPP=ON \
  -DENABLE_MATHEMATICA=OFF \
  -DENABLE_FRONTEND=ON \
  -DENABLE_JUPYTER=ON \
  -DPYTHON_EXECUTABLE=$PYTHON \
  ..

make -j${CPU_COUNT}
make install

mkdir -p $PREFIX/share/cadabra2
ln -s $SP_DIR $PREFIX/share/cadabra2/python

# Following test fails with no module named `module03` found.
TESTS_TO_SKIP="modules"
if [[ "$target_platform" == osx* ]]; then
    # The following test segfaults on OSX
    TESTS_TO_SKIP="${TESTS_TO_SKIP}|implicit"
fi

ctest --output-on-failure -E "${TESTS_TO_SKIP}" -j${CPU_COUNT}

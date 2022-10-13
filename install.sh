#!/bin/bash
#echo "### Setup TI edge AI platform ... ###"
#cd /opt/edge_ai_apps
#./setup_script.sh
#cd /opt/ti_pylon_edgeai

echo "### Installing Pylon ... ###"
rm -rf tmp && mkdir -p tmp/pylon
rm -rf /opt/pylon && mkdir -p /opt/pylon

tar xzf ti_*_aarch64_setup.tar.gz -C tmp
cd tmp 
tar xzf *tar.gz -C /opt/pylon
chmod 755 /opt/pylon
cd ..
rm -rf tmp

# Add support for pylon cameras to "edge_ai_apps" source files
cd /opt/ti_pylon_edgeai

## Install example configuration demo that uses pylon camera
echo "### Installing sample application to app_edge_ai ... ###"
cp pylon_demo.yaml /opt/edge_ai_apps/configs

## Apply some modifications to gst_wrapper.py
patch /opt/edge_ai_apps/apps_python/gst_wrapper.py gst_wrapper.py.patch

# Clone git repository "gst-plugin-pylon" 
echo "### Installing GStreamer Plugin ... ###"
rm -rf /opt/gst-plugin-pylon
cd /opt/
git clone https://github.com/basler/gst-plugin-pylon.git
cd gst-plugin-pylon

# Meson and ninja build system are required to build plugin
python3 -m pip install meson ninja --upgrade

# for pylon in default location
export PYLON_ROOT=/opt/pylon

# Configure project
meson builddir --prefix /usr/

# Build
ninja -C builddir

# Install
sudo ninja -C builddir install

cd /opt/edge_ai_apps/apps_python
echo "### Installation done."
echo "### Connect Basler camera and start app_edge_ai sample application with:"
echo "cd /opt/edge_ai_apps/apps_python"
echo "./app_edgeai.py ../configs/pylon_demo.yaml"
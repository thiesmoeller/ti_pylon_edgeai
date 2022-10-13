**ti_pylon_edgeai**
---
Support for Basler USB and GigE cameras in the TI edge AI environment

- [1. Prerequisites](#1-prerequisites)
  - [1.1. Mandatory](#11-mandatory)
  - [1.2. Recommended](#12-recommended)
- [2. Installation](#2-installation)
  - [2.1. Setup SK-TDA4VM for edge_ai_apps](#21-setup-sk-tda4vm-for-edge_ai_apps)
  - [2.2. Clone repository files to target platform](#22-clone-repository-files-to-target-platform)
  - [2.3. Install Pylon and Gstreamer](#23-install-pylon-and-gstreamer)
    - [2.3.1. Install everything by using provided installer script](#231-install-everything-by-using-provided-installer-script)
    - [2.3.2. Manual installation](#232-manual-installation)
      - [2.3.2.1. Add support for pylon cameras to "edge_ai_apps" source files](#2321-add-support-for-pylon-cameras-to-edge_ai_apps-source-files)
      - [2.3.2.2. Install Basler's Gstreamer plugin for pylon cameras](#2322-install-baslers-gstreamer-plugin-for-pylon-cameras)
- [3. Run TI app_edge_ai Python example application with pylon camera](#3-run-ti-app_edge_ai-python-example-application-with-pylon-camera)
- [4. Use Pylonviewer GUI to configure camera and show raw images (optional)](#4-use-pylonviewer-gui-to-configure-camera-and-show-raw-images-optional)
- [5. Reference documentation](#5-reference-documentation)
- [6. Known bugs and limitations](#6-known-bugs-and-limitations)

# 1. Prerequisites
## 1.1. Mandatory 
* [SK-TDA4VM processor starter kit for Edge AI vision systems](https://www.ti.com/tool/SK-TDA4VM)
* Linux system image: [ti-processor-sdk-linux-sk-tda4vm-etcher-image.zip](https://dr-download.ti.com/software-development/software-development-kit-sdk/MD-4K6R4tqhZI/08.04.00.10/ti-processor-sdk-linux-sk-tda4vm-etcher-image.zip)
* [Basler USB or GigE-Camera](https://www.baslerweb.com/)
* [Balena Etcher](https://www.balena.io/etcher/)
* SSH connection to SK-TDA4VM
* SK-TDA4VM must be connected to the Internet

> Processor SDK Linux for Edge AI (08.04.00) is verified to work

## 1.2. Recommended
* FAN to cool the processor since it gets too hot
* [Visual Studio Code](https://code.visualstudio.com/) with Remote SSH extension

# 2. Installation
## 2.1. Setup SK-TDA4VM for edge_ai_apps
* Use Balena Etcher to create SD card with target Linux [ti-processor-sdk-linux-sk-tda4vm-etcher-image.zip](https://dr-download.ti.com/software-development/software-development-kit-sdk/MD-4K6R4tqhZI/08.04.00.10/ti-processor-sdk-linux-sk-tda4vm-etcher-image.zip)
* Insert SD card to target and boot 
* Connect to target using SSH (hostname: tda4vm-sk, user:root, pwd: root)

```bash
ssh root@tda4vm-sk
cd /opt/edge_ai_apps
./setup_script.sh
```

## 2.2. Clone repository files to target platform
```bash
cd /opt
git clone https://github.com/millertheripper/ti_pylon_edgeai.git
```

## 2.3. Install Pylon and Gstreamer
In order to use a Basler camera with the TI Jacquinto Platform you need to install Pylon first. Pylon is the framework to use Basler cameras. It can be used for developing applications in C/C#/C++ and Python or simply showing camera images using the "Pylonviewer" application. Pylon comes with a wide set of programming examples that demonstrate the API access. However, the TI edge AI demo applications are based on Gstreamer pipelines. In order to access pylon cameras using the GStreamer framework you also need to install Basler's Gstreamer Pylon Plugin to the target system.

>[NOTE:] Due to a compatibility issue with stdlibc++ between TI target Linux and Pylon it is currently not possible to install official Pylon releases from the Basler [website](https://www.baslerweb.com/). You need to use the provided installer "ti_pylon_6.2.0.21487_aarch64_setup.tar" in order to install pylon to the target. You can choose between automated installation or operate the installation steps manually. 

### 2.3.1. Install everything by using provided installer script
```bash
cd /opt/ti_pylon_edgeai
sh install.sh
```
> You can now skip over to [Section 3](#3-run-ti-app_edge_ai-python-example-application-with-pylon-camera):

### 2.3.2. Manual installation
```bash
cd /opt/ti_pylon_edgeai
mkdir -p tmp/pylon
tar xzf ti_*_aarch64_setup.tar.gz -C tmp
cd tmp 
tar xzf *tar.gz -C pylon
cp -r pylon /opt
chmod 755 /opt/pylon
cd ..
rm -r tmp
```

#### 2.3.2.1. Add support for pylon cameras to "edge_ai_apps" source files
```bash
cd /opt/ti_pylon_edgeai

# Install example configuration demo that uses pylon camera
cp pylon_demo.yaml /opt/edge_ai_apps/configs

# Apply some modifications to gst_wrapper.py
patch /opt/edge_ai_apps/apps_python/gst_wrapper.py gst_wrapper.py.patch
```

#### 2.3.2.2. Install Basler's Gstreamer plugin for pylon cameras
The TI edge AI applications are based on Gstreamer pipelines. In order to access pylon cameras using the GStreamer framework you need to install Gstreamer Pylon Plugin to the target system.

> Link to Github including documentation: https://github.com/basler/gst-plugin-pylon

```bash
# Clone git repository "gst-plugin-pylon" 
cd /opt
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

# Finally, test for proper installation:
gst-inspect-1.0 pylonsrc

# Connect a Basler camera and use the following example pipeline to show video on HDMI output
gst-launch-1.0 pylonsrc ! "video/x-raw,width=1280,height=720,format=RGB" ! videoconvert ! kmssink
```

# 3. Run TI app_edge_ai Python example application with pylon camera
```bash
cd /opt/edge_ai_apps/apps_python
./app_edgeai.py ../configs/pylon_demo.yaml
```

> Note 1: Depending on the camera used, you may need to adjust camera parameters (width, height, framerate, pixel format) in pylon_demo.yaml

> Note 2: In case you want to use multiple cameras, you need to provide the serial number of the camera to parameter "sens-id"


# 4. Use Pylonviewer GUI to configure camera and show raw images (optional)
Start shell on the HDMI connected wayland desktop, using a mouse and keyboard
```bash
cd /opt/pylon/bin
./pylonviewer -platform wayland
``` 

# 5. Reference documentation
* [SK-TDA4VM User's Guide](https://www.ti.com/lit/ug/spruj21c/spruj21c.pdf?ts=1665603727984&ref_url=https%253A%252F%252Fwww.ti.com%252Ftool%252FSK-TDA4VM)
* [Documentation Processor SDK Linux for Edge AI](https://software-dl.ti.com/jacinto7/esd/processor-sdk-linux-sk-tda4vm/08_04_00/exports/docs/index.html)
* [Pylon Camera Suite](https://www.baslerweb.com/en/products/basler-pylon-camera-software-suite/)
* [Basler Cameras](https://www.baslerweb.com/en/products/cameras/)

# 6. Known bugs and limitations
* Currently only the Python API of apps_edge_ai is supported 
* Due to a compatibility issue with stdlibc++ between TI target Linux and Pylon it is currently not possible to install official Pylon releases from the Basler [website](https://www.baslerweb.com/)
# ACSim

**ACSim** — *A Novel Acoustic Camera Simulator with Recursive Ray Tracing, Artifact Modeling, and Ground Truthing*  
📄 Published in [IEEE Transactions on Robotics (TRO), 2025](https://ieeexplore.ieee.org/document/10967163)

---

## 🚧 Project Status

This repository is under active development.  
Please refer to the [documentation](https://sollynoay.github.io/ACSim-docs/) for tutorials and setup instructions.

---

## ⚡ Quick Start

1. Open `demo/test.blend` in Blender  
2. Install the add-on `SonarRT.zip`  
3. Press `F12` to render the scene

---

## 🛠️ Development (Built-in Ray-Mesh Intersection)

1. Open `built-in/wakachiku.blend`  
2. Go to the **Scripting** tab  
   - Run `sonarRT_plugin.py` (click ▶️)  
   - Run `sonarRT_UIpanels.py` (click ▶️)

---

## 🚀 Optimized Version

An accelerated version is available in the `optimized` folder.  
Please follow the [documentation](https://sollynoay.github.io/ACSim-docs/) for environment setup and usage.

---

## 📦 Synthetic Dataset

We provide a synthetic dataset used in training and evaluation:

- [Flow](http://gofile.me/7aSbh/XhN1d02kj)  
- [3D Geometry](http://gofile.me/7aSbh/NSMrchSxy)  
- [Segmentation Masks](http://gofile.me/7aSbh/ubne7Rgk9)

---

## 📚 Documentation

Full documentation is available here:  
👉 [ACSim Documentation](https://sollynoay.github.io/ACSim-docs/)

---

## 📝 Citation

If you use **ACSim** in your research, please cite the following paper:

```bibtex
@ARTICLE{acsim, 
  author = {Wang, Yusheng and Ji, Yonghoon and Tsuchiya, Hiroshi and Ota, Jun and Asama, Hajime and Yamashita, Atsushi},
  title = {ACSim: A Novel Acoustic Camera Simulator With Recursive Ray Tracing, Artifact Modeling, and Ground Truthing}, 
  journal = {IEEE Transactions on Robotics}, 
  year = {2025},
  volume = {41},
  pages = {2970--2989},
}

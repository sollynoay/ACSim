# ACSim

**ACSim**: A Novel Acoustic Camera Simulator with Recursive Ray Tracing, Artifact Modeling, and Ground Truthing (TRO 2025).  
📄 [paper](https://ieeexplore.ieee.org/document/10967163)

## 🚧 Notice

This repository is under active development.  
A demo using Blender’s built-in ray-mesh intersection engine is available for early trials.

## ⚡ Quick Start

1. Open `demo/test.blend` in Blender  
2. Install the add-on `SonarRT.zip`  
3. Press `F12` to render

## 🛠️ Development (Built-in Ray-Mesh Intersection)

1. Open `built-in/wakachiku.blend`  
2. In the **Scripting** tab:  
   - Run `sonarRT_plugin.py` (click ▶️)  
   - Run `sonarRT_UIpanels.py` (click ▶️)

## 📦 Dataset

We provide the synthetic dataset used in our training pipeline:  
- [Flow](http://gofile.me/7aSbh/XhN1d02kj)  
- [3D](http://gofile.me/7aSbh/NSMrchSxy)  
- [Mask](http://gofile.me/7aSbh/ubne7Rgk9)

## 📚 Documentation

Documentation is available here:  
👉 [ACSim Docs](https://sollynoay.github.io/ACSim-docs/) 

## 📝 Citation

If you find ACSim helpful in your work, please consider citing us:

```bibtex
@ARTICLE{acsim, 
  author = {Wang, Yusheng and Ji, Yonghoon and Tsuchiya, Hiroshi and Ota, Jun and Asama, Hajime and Yamashita, Atsushi},
  title = {ACSim: A Novel Acoustic Camera Simulator With Recursive Ray Tracing, Artifact Modeling, and Ground Truthing}, 
  journal = {IEEE Transactions on Robotics}, 
  year = {2025},
  volume = {41},
  pages = {2970--2989},
}

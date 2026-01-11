
# AllToolBox

你的下一个小天才 Root 工具箱 —— 不止 Root。

AllToolBox 是一款为小天才Rooter设计的轻量级工具集合。它集成了多种实用的小工具、脚本和本地辅助程序，帮助用户简化设备管理、Root 权限操作、系统调试及构建发布流程。项目强调模块化、实用性和易扩展。

---

## 项目简介

- 仓库地址：https://github.com/AllToolBox-SC/AllToolBox  
- 主要编程语言：Batch、Python、PowerShell、Rust、C++，涵盖了多种脚本和本地编译程序    
- 构建环境建议：Python 3.12 或以下版本，目前**仅支持 Windows** 

---

## 主要功能

- Root 相关辅助脚本和工具，便于权限管理和系统操作  
- 设备维护和系统调优脚本  
- 构建和打包辅助工具（包含批处理、Python 脚本和 Rust 编译组件）  

---

## 目录结构简述

- `.github/`：CI/CD 流水线配置  
- `src/`：主要脚本代码，包括 `start.py` 和 Windows 批处理脚本（如 `src/bats/root.bat`）  
- `build.py`：构建流程的 Python 脚本  
- `ezbuild.bat`：Windows 平台一键构建脚本  
- `requirements.txt`：Python 依赖列表  
- `Cargo.toml`：Rust 组件配置文件

---

## 快速安装与构建指南

1. 克隆项目：
   ```bash
   git clone https://github.com/AllToolBox-SC/AllToolBox.git
   cd AllToolBox
   ```

2. 准备 Python 环境（建议使用 Python 3.12 或以下）：

   ```powershell
   python -m venv .venv
   # Windows
   .venv\Scripts\activate
   ```

3. 构建项目：

   * Windows 平台可直接运行 `ezbuild.bat` 批处理完成构建：

     ```powershell
     # 示例编译正式版
     .\ezbuild.bat -t release --pyinstaller
     ```

---

## 运行示例

* 需要先编译或直接调试：

  #### 1. 生成调试文件
  ```powershell
  .\ezdebug.bat /mode:full
  ```
  生成文件在`source/`中

  #### 2. 查看编译帮助
  ```powershell
  .\ezbuild.bat -h
  ```

---

## 发布说明

项目采用小步快跑式发布，具体版本更新内容可参考仓库 Releases 页面。

---

## 贡献指南

欢迎贡献代码：

1. Fork 仓库
2. 创建分支 `git checkout -b feature/xxx`
3. 添加代码、测试或使用示例
4. 提交 Pull Request 并简要说明修改内容

请确保代码安全且易于维护，尤其是涉及设备 Root 或系统层面的脚本。

---

## 注意事项

* 工具需要管理员权限，请务必在信任其行为后再执行
* 非稳定版建议在虚拟环境或测试环境中进行构建和测试，避免对生产设备产生影响

---

## 作者及许可

请查看项目 LICENSE 文件和 GitHub Contributors 页面获取详细信息。

---

## 反馈与支持

如遇问题或建议，欢迎通过 GitHub Issues 反馈或在讨论区讨论。

QQ群：`907491503`


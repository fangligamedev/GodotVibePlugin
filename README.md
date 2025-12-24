# VibeCoding Plugin for Godot 🤖✨

**VibeCoding** 是一个为 Godot 4.x 引擎打造的智能 AI 编程助手插件。
它不仅仅是一个聊天机器人，更是一个具备**多模态感知**、**自主规划**、**代码编写**、**自我检查**闭环能力的智能体 (Agent)。

**v0.2.0 新特性:**
- 👁️ **视觉能力**: 支持粘贴图片 (Cmd+V)，AI 可识别 UI 截图并协助开发。
- 🔄 **双模式**: 
    - **Chat (问答)**: 纯对话更安全。
    - **Agent (代理)**: 全自动执行任务。
- 🇨🇳 **中文优先**: 默认全中文交互和反馈。
- 📋 **自动报告**: 任务完成后自动生成设计摘要和游戏说明书。

---

## ✨ 核心特性 (Features)

### 1. ⚡️ 智能体能力 (Agentic Capabilities)
不同于普通的 Copilot，VibeCoding 拥有“手”和“眼”：
- **写代码 (save_script)**: 自动创建或修改脚本文件。
- **建目录 (make_dir)**: 自动规划项目文件结构。
- **读代码 (read_file)**: 读取现有的代码进行理解和自我修复。
- **看目录 (list_dir)**: 检查项目结构是否符合预期。

### 2. 🧠 双模式工作流 (Dual Modes)
插件提供了两种工作模式，通过顶部的下拉菜单切换：

#### 🟢 Chat 模式 (问答)
- **用途**: 咨询问题、生成代码片段、让 AI 解释代码。
- **行为**: 只回答，**不**自动修改项目文件。

#### 🔴 Agent 模式 (代理)
- **用途**: 委托开发任务（如 "做一个贪吃蛇"）。
- **行为**: 
    1. **规划**: 生成 `design_doc.md`。
    2. **执行**: 循环执行 `save_script`, `make_dir` 等操作。
    3. **闭环**: 每次操作后自动检查结果，直到任务完成。
    4. **报告**: 最终输出项目摘要和玩法说明。

### 3. 👁️ 多模态支持 (Multimodal)
- **粘贴即用**: 在输入框按下 `Cmd+V` (Mac) 或 `Ctrl+V` (Win) 粘贴截图。
- **场景感知**: 除了文字描述，AI 还能通过图片理解你的 UI 布局或参考图。

---

## 📅 开发日志 (Dev Log)

### v0.2.0: 视觉与代理 (Current)
- [x] **视觉集成**: 实现图片粘贴与预览，对接 Multimodal LLM。
- [x] **模式分离**: 拆分 Chat/Agent 逻辑，提升安全性与可用性。
- [x] **中文本地化**: 系统提示词全面汉化。
- [x] **自动报告**: 增加任务完成后的总结报告生成。

### v0.1.0: 基础架构
- [x] 搭建插件骨架与 UI。
- [x] 实现基础通信模块与 JSON Action 执行器。
- [x] 验证 "规划->执行" 自动化原型。

---

## 🚀 快速开始 (Getting Started)

### 1. 安装
克隆本项目到你的 Godot 项目的 `addons/` 目录下：
```bash
git clone https://github.com/fangligamedev/GodotVibePlugin addons/vibecoding_plugin
```
或者直接下载源码放入 `addons/vibecoding_plugin`。

### 2. 启用
1. 打开 Godot 编辑器。
2. 菜单栏 -> **Project** -> **Project Settings** -> **Plugins**。
3. 勾选 **VibeCoding AI Assistant**。

### 3. 配置
在 `res://addons/vibecoding_plugin/vibecoding_config.json` 中配置你的 API Key：
> 首次运行会自动生成 `vibecoding_config.template.json`，请重命名为 `vibecoding_config.json` 并填入 Key。
```json
{
    "gemini_api_key": "YOUR_API_KEY_OR_OPENROUTER_KEY",
    "model": "google/gemini-2.0-flash-exp:free"
}
```

### 4. 使用
打开编辑器右侧的 **Vibe AI** 面板：
- **模式**: 选择 **Agent**。
- **输入**: "帮我做一个 3D 打砖块游戏，先出计划，然后一步步执行。"

---

## 📄 许可证
MIT License

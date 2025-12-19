# VibeCoding Plugin for Godot 🤖✨

**VibeCoding** 是一个为 Godot 4.x 引擎打造的智能 AI 编程助手插件。
它不仅仅是一个聊天机器人，更是一个具备**自主规划**、**代码编写**、**自我检查**闭环能力的智能体 (Agent)。

它可以帮你：
- 理解当前场景结构和报错信息。
- 自动编写脚本 (`.gd`) 和创建场景结构。
- 通过 "Auto-Pilot" 模式，根据一句话需求（如 "做一个打砖块游戏"）自动拆解任务并连续执行，直到项目完成。

---

## ✨ 核心特性 (Features)

### 1. ⚡️ 智能体能力 (Agentic Capabilities)
不同于普通的 Copilot，VibeCoding 拥有“手”和“眼”：
- **写代码 (save_script)**: 自动创建或修改脚本文件。
- **建目录 (make_dir)**: 自动规划项目文件结构。
- **改设置 (set_setting)**: 修改项目设置（如物理层、窗口大小）。
- **读代码 (read_file)**: 读取现有的代码进行理解和自我修复。
- **看目录 (list_dir)**: 检查项目结构是否符合预期。

### 2. 🧠 自主规划循环 (Autonomous Loop)
引入了 `chain_task` 和 `Auto-Pilot` 机制，实现 **规划 -> 执行 -> 检查 -> 下一步** 的自动化闭环。

- **关键词触发**: 
  只要你的指令中包含 **"自动" (Auto)** 或 **"计划" (Plan)** 等词（例如 "帮我做个游戏，自动执行"），插件就会自动进入 **Auto-Pilot Mode**。

- **自动闭环**: 
  当 Agent 执行完一个动作（比如创建了 `player.gd`），插件会等待 1.5 秒，然后**自动**把执行结果（Success）发回给 Agent，并附加指令：“Action finished. Proceed to next step.”。这意味着你不用再点发送了，它会自己动，直到做完。

- **终交付格式**: 
  系统提示词 (System Prompt) 明确要求 Agent 在所有步骤执行完毕后，必须输出你指定的 **三段式报告**：
  1. 设计文档 (Design Document)
  2. 项目介绍 (Project Introduction)
  3. 游戏说明 (Game Manual)

### 3. 💬 上下文感知 (Context Aware)
- **记忆力**: 拥有完整的对话历史记忆，知道自己上一步做了什么。
- **感知力**: 实时读取 Godot 的 Scene Tree（场景树）状态，理解你当前选中的节点和属性。

---

## 🛠️ 架构设计 (Architecture)

本插件采用模块化设计，主要组件如下：

```mermaid
graph TD
    A[Plugin Entry (plugin.gd)] --> B[LLM Communicator]
    A --> C[Action Executor]
    A --> D[State Manager]
    A --> E[UI Dock]

    B -- 发送状态/历史 --> LLM[Gemini/OpenAI]
    LLM -- 返回 JSON 指令 --> B
    B -- 解析指令 --> A
    A -- 调度执行 --> C
    C -- 操作编辑器API --> Godot[Godot Editor]
    D -- 读取状态 --> Godot
```

- **`plugin.gd`**: 中央控制器，负责生命周期管理和模块协调。
- **`llm_communicator.gd`**: 负责与 LLM (Gemini/OpenRouter) 通信，维护聊天历史 (`chat_history`)，并包含**鲁棒的 JSON 解析器**（支持从混合文本中提取指令）。
- **`action_executor.gd`**: 封装 Godot Editor API，提供安全的文件读写和编辑器操作接口。
- **`state_manager.gd`**: 负责抓取编辑器当前状态（场景树、选中节点）作为 Context 发送给 AI。

---

## 📅 开发日志 (Dev Log)

### 阶段 1: 基础架构搭建 (已完成)
- [x] 搭建插件骨架 (`plugin.cfg`, `plugin.gd`)。
- [x] 实现 UI 面板 (`vibecoding_dock.gd`)，支持流式对话。
- [x] 实现基础通信模块，支持 Google Gemini 和 OpenRouter API。
- [x] 解决 UI 交互 Bug（回车发送、输入框高度）。

### 阶段 2: 赋予动作能力 (已完成)
- [x] 定义 JSON Action Protocol。
- [x] 实现 `ActionExecutor`，支持 `save_script`, `make_dir`, `set_setting`。
- [x] 升级 LLM System Prompt，使其学会使用工具。
- [x] 修复 JSON 解析逻辑，支持从复杂回复中提取动作。

### 阶段 3: 自主智能体 (Current Status)
- [x] **记忆升级**: 实现对话历史 (`chat_history`) 管理。
- [x] **感知升级**: 增加 `read_file` 和 `list_dir` 能力，支持自我检查。
- [x] **自动驾驶**: 实现 `chain_task`，允许 AI 主动请求进入下一步，形成闭环。

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
```json
{
    "gemini_api_key": "YOUR_API_KEY_OR_OPENROUTER_KEY",
    "model": "google/gemini-2.0-flash-exp:free"
}
```

### 4. 使用
打开编辑器右侧的 **Vibe AI** 面板，输入：
> "帮我做一个 3D 打砖块游戏，先出计划，然后一步步执行。"

---

## 📄 许可证
MIT License

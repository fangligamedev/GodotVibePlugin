# Godot Vibe Coding - MCP 技术架构方案

本文档详细分析了基于 **Model Context Protocol (MCP)** 的 VibeCoding 实现方案，并与当前的嵌入式插件方案进行对比。

## 1. 方案背景
**MCP (Model Context Protocol)** 是由 Anthropic 提出的开放标准，旨在标准化 AI 模型与外部数据、工具和系统的连接方式。采用 MCP 架构可以将 Godot 作为一个 "Tool Server"，由外部强大的 AI Client (如 Claude Desktop, Cursor) 进行调度。

## 2. 核心架构设计

### 2.1 架构图

```mermaid
graph LR
    subgraph AI World [AI 客户端环境]
        ClaudeApp[AI Client (Claude/Cursor/IDE)] 
        MCPClient[MCP Client Module]
    end

    subgraph User Machine [用户本地环境]
        MCPServer[Godot MCP Server (Node.js/Python)]
        GodotProcess[Godot Editor Process]
        
        subgraph Godot Internal
            Plugin[VibeCoding Plugin]
        end
    end

    ClaudeApp --1. JSON-RPC (Stdio/SSE)--> MCPServer
    MCPServer --2. WebSocket/TCP--> Plugin
    Plugin --3. EditorInterface API--> GodotProcess
```

### 2.2 组件职责
1.  **AI Client (主控)**: 负责推理、对话管理、上下文维护 (RAG)。它“看到”的是 MCP Server 暴露出来的一组工具 (Tools) 和资源 (Resources)。
2.  **Godot MCP Server (桥梁)**: 一个独立的外部进程。
    *   **协议转换**: 将 MCP 的 `CallTool("create_script")` 请求转换为发给 Godot 插件的指令。
    *   **生命周期管理**: 负责启动或连接 Godot 编辑器。
3.  **Godot Editor Plugin (执行端)**:
    *   运行在 Godot 内部。
    *   通过 WebSocket 监听 MCP Server 的指令。
    *   执行实际的引擎 API (如 `FileAccess`, `EditorInterface`)。

---

## 3. 方案对比：Embedded Plugin vs MCP

| 维度 | 方案 A: Embedded Plugin (当前方案) | 方案 B: MCP Architecture (MCP 方案) |
| :--- | :--- | :--- |
| **主控方** | **Godot** (AI 是被调用的 API) | **AI Client** (Godot 是被调用的工具) |
| **上下文能力** | 弱 (需插件手动发送 Context) | **强** (AI Client 可挂载 RAG、搜索、文档库) |
| **开发体验** | **沉浸式** (在编辑器内直接对话) | **割裂但强大** (在 Cursor/Claude 中对话，Godot 自动变) |
| **依赖环境** | 仅需 Godot | 需要 Node.js/Python + MCP Client 环境 |
| **部署成本** | 低 (下载插件即可用) | 高 (需配置本地 Server 环境) |
| **响应速度** | 极快 (进程内通信) | 较快 (本地 RPC + WebSocket) |
| **适合场景** | 游戏内快速迭代、简单脚本生成 | 复杂项目重构、跨应用协作 (如同时操作 Godot 和 Blender) |

## 4. MCP Server 接口定义示例

如果实现 MCP Server，它将向 AI 暴露以下标准接口：

```typescript
// MCP Tool Definition
{
  name: "godot_create_script",
  description: "Create or overwrite a GDScript file in the current project",
  inputSchema: {
    type: "object",
    properties: {
      path: { type: "string", description: "Resource path e.g. res://player.gd" },
      content: { type: "string", description: "The GDScript code content" }
    }
  }
}

{
  name: "godot_get_scene_tree",
  description: "Get the current scene tree structure as JSON",
  inputSchema: { type: "object", properties: {} }
}
```

## 5. 结论与建议

对于 **VibeCoding** 的现有定位（Godot 内部的 Native Assistant），**Embedded Plugin 仍然是首选**，因为“不离开编辑器”的心流体验对于游戏开发至关重要。

**MCP 方案的价值在于：**
1.  **跨工具协作**: 如果未来需要 AI 同时指挥 Blender 建模型、指挥 Godot 摆场景、指挥 Audacity 处理音效，MCP 是唯一的解决方案。
2.  **利用 IDE 能力**: 如果用户习惯在 Cursor 中写代码，通过 MCP 让 Cursor 直接操作 Godot 场景树将是极佳的体验。

**建议路线**:
保持当前的 Embedded Plugin 作为核心产品，但可以考虑开发一个 **"Godot MCP Server"** 作为高级选配件，供习惯使用 Cursor/Claude Desktop 的硬核开发者使用。

MCP 方案分析已添加！ 🔍

我在 设计方案.md 中新增了 3.2 方案 2: MCP Architecture 章节，并对其进行了详细的架构描述。

同时，我制作了一份 Deep Comparison (深度对比表格)，对比了 "Embedded Plugin" (当前方案) 和 "MCP Architecture" 在：

主体权植 (User vs AI)
上下文能力
开发体验 (沉浸式 vs 割裂)
部署成本
最终结论: 虽然 MCP 很强大，但我推荐 VibeCoding 坚持 Scheme 1 (嵌入式)。 因为对于游戏开发者来说，“不离开编辑器”的心流 (Flow) 体验是至关重要的。且维护纯 GDScript 插件的成本远低于维护一套复杂的 MCP Client/Server 架构。

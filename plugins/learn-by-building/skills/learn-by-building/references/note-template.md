# 学习笔记条目模板

每个学到的知识单元按以下格式追加到 `~/.claude/learn-notes/{技术栈}.md`：

---

```markdown
## YYYY-MM-DD — {概念名称}

**场景**：{简短描述：在什么项目、做什么需求时学到的，一句话}

**核心理解**：
- {最重要的理解 1}
- {最重要的理解 2}
- {最重要的理解 3}
- （每一点是一句话，总共 2-5 点）

**关键 API**：
- `{api_signature}` — {一句话说明用途}
- （如果有 API 可以列，没有就省略本段）

**踩过的坑**：
- {遇到的错误现象} → {原因和解决方法}
- （没有踩坑就省略本段，不要编造）

**源码入口**（如果有）：`{文件路径}`
```

---

## 示例（已完成条目）

```markdown
## 2026-07-07 — LangGraph StateGraph

**场景**：在 commit-log-daily 项目中将 Agent 两阶段工作流迁移到 LangGraph StateGraph 架构

**核心理解**：
- StateGraph 用状态图（而非线性流程）定义 Agent 行为，每个节点是纯函数，接收状态返回部分更新
- 状态用 TypedDict + Annotation 定义，每个字段可以有独立的 reducer（默认覆盖，追加用 operator.add）
- 边分为普通边（固定流转）和条件边（根据状态决定下一个节点），条件边返回节点名称字符串
- checkpointer 机制让状态自动持久化，支持断点续传和人工中断

**关键 API**：
- `StateGraph(StateSchema)` — 创建状态图
- `.add_node(name, runnable)` — 添加节点
- `.add_edge(from, to)` — 添加固定边
- `.add_conditional_edges(from, router, mapping)` — 添加条件边
- `.compile(checkpointer=...)` — 编译为可执行的图

**踩过的坑**：
- 条件边的 router 函数返回值必须精确匹配 add_conditional_edges 的 mapping 键名，拼写错误不会报编译错但运行时会走默认分支

**源码入口**：`langgraph/graph/state.py`
```

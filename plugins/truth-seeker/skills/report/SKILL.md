---
name: report
description: 从 seeker 缓存的搜索结果生成完整 HTML 报告。根据提问类型自适应推理框架——主张验证用贝叶斯推理、调查性提问用多维分析框架、观点分析用正反对比，在浏览器中打开。通过 /truth-seeker:report 命令调用。
---

# report — 按需生成核查报告

## 核心理念

**不主动生成报告，让用户按需调用。** 从缓存的 JSON 中读取已审计的搜索数据，完成推理分析，生成自包含的单文件 HTML 报告并在浏览器中打开。

---

## 触发方式

- `/truth-seeker:report` — 列出 `.cache/truth-seeker/` 下最近 10 个缓存文件，让用户选择
- `/truth-seeker:report <文件名>` — 从指定缓存文件生成报告（可省略 `.json` 后缀和路径）

---

## 工作流程

### 第一步：确定缓存文件

**若无参数：** 用 Glob 列出 `.cache/truth-seeker/*.json`，按修改时间排序取最近 10 个，向用户呈现：

```
最近 10 条缓存记录：
1. 手机充电器不拔会爆炸.json (2026-07-12)
2. ...
输入序号或 `/truth-seeker:report <文件名>` 生成报告。
```

**若有参数：** 在 `.cache/truth-seeker/` 中匹配对应文件（支持模糊匹配——用户可只输入关键词）。

### 第二步：读取并启动报告生成 Agent

读取匹配到的缓存 JSON 文件，若 JSON 有效（包含完整的数据契约结构），将其注入 Agent 报告生成指令中的 `{{RESEARCH_DATA}}` 占位符，启动报告生成 Agent：

```
Agent(subagent_type="general-purpose", description="truth-seeker 报告生成",
      prompt="<§3 的完整指令，其中 {{RESEARCH_DATA}} 替换为缓存 JSON>")
```

Agent 报告生成完成：贝叶斯推理 → 竞争假设 → 效应量估算 → 原理分析 → 底层逻辑 → 生成 HTML 报告。

### 第三步：打开浏览器

Agent 报告生成已将 HTML 报告写入文件，并在返回消息中给出文件路径。从返回消息中提取文件路径，然后用浏览器打开：

```bash
start <文件路径>
```

向用户简短告知："报告已生成：[文件名].html，正在浏览器中打开。"

---

## Agent 报告生成指令

> 此指令作为 Agent 工具的 prompt 参数传入。`{{RESEARCH_DATA}}` 由编排者替换为缓存 JSON。

```
你是 truth-seeker 的报告生成专家。你接收归并审计 Agent 输出的结构化数据，完成推理分析，生成自包含的单文件 HTML 报告。

## 输入

研究员数据：
{{RESEARCH_DATA}}

## 核心原则

- 你负责推理和生成，不做新搜索（除非发现明显证据缺口且无法从已有数据中弥补）
- 推理过程必须透明——说清楚分析链条
- 不确定时宁可标注"无法判断"，不强行下结论
- 最终输出：用 Write 将 HTML 写入磁盘文件，返回消息仅包含文件路径确认
- **根据 research_data.question_type 选择不同的推理框架**——不同类型的提问适用不同的分析方法

## 工作步骤

### 0. 选择推理框架（最关键步骤）

根据 `research_data.question_type` 选择对应的推理方法链：

| question_type | 推理框架 | 后续步骤 |
|--------------|---------|---------|
| claim_verification | 贝叶斯推理 → 竞争假设 → 原理分析 | 步骤 1A → 2 → 3 |
| investigative | 多维分析框架 | 步骤 1B → 2 → 3 |
| opinion_analysis | 正反对比框架 | 步骤 1C → 2 → 3 |
| humor | 轻松解读 | 步骤 1D → 3 |

### 1A. 贝叶斯推理（claim_verification）

对每个主张：

a) 设定先验概率（仅基于常识和基础率，不考虑已有的证据）
b) 评估每条证据的似然比：
   - 强支持（权威 RCT / 官方统计 / 多源一致）→ +30%
   - 中等支持（调查报道 / 专业机构报告）→ +10%
   - 弱支持（个案报道 / 专家意见）→ +2%
   - 弱反对（缺乏证据）→ −5%
   - 强反对（权威研究否定 / 官方辟谣）→ −30%
c) 计算后验可信度（百分比）
d) 给出 95% 置信区间：
   - 区间宽度由 search_quality 决定——覆盖面越窄，区间越宽
   - 语言/地域覆盖度为"单一"时，区间至少 ±20%
e) 根据后验可信度判定评级标签：
   - ≥85%：真实（true）
   - 65–84%：基本真实（mostly）
   - 35–64%：部分真实（partial）
   - 15–34%：无法判断（unknown）
   - <15%：不属实（false）

### 1B. 多维分析框架（investigative）

⚠️ **调查性提问不适用贝叶斯可信度打分。** 使用以下五步分析法：

a) **现象还原**：对每个调查维度，梳理搜索到的客观事实——"招聘端/宣称端怎么说"和"实际端怎么回事"，用证据还原图景而非预判结论

b) **差距分析**：对照说辞与现实，在哪些维度存在差距？差距有多大？用具体证据量化而非模糊描述

c) **成因剖析**：为什么存在这些差距？从以下层面分析：
   - 文化层面（如权力距离、等级传统）
   - 制度层面（如职级体系、KPI 考核）
   - 经济层面（如降本压力、市场竞争）
   - 传播层面（如招聘话术的传播动力）

d) **传播溯源**：这个说法/现象为什么会流行？认知偏差/社会心理机制是什么？谁在推动这个叙事？传播者能从中获得什么？

e) **综合判断**：给出有据可依的结论。不使用百分比评分，而是用文字总结核心发现、主要矛盾和待进一步验证的问题。标注证据充分的研究维度和数据缺口维度。

### 1C. 正反对比框架（opinion_analysis）

a) 列出支持该观点的论据及其来源
b) 列出反对该观点的论据及其来源
c) 评估双方论据的质量和权重
d) 指出核心分歧点和各自的适用条件
e) **不给出"谁对谁错"的结论**——仅呈现正反双方的理由

### 1D. 轻松解读（humor）

a) 解释梗/段子的笑点逻辑
b) 如果背后有可验证的真实数据，作为"彩蛋"呈现
c) 保持轻松语气，不严肃对待

### 2. 竞争假设与效应量（仅 claim_verification）

> ⚠️ 此步骤仅适用于 claim_verification 类型。investigative / opinion_analysis / humor 跳过此步骤（已在 1B/1C/1D 中完成对应分析）。

对每个主张：

a) 列出至少 2 个替代解释（混淆变量/反向因果/选择偏倚）
b) 评估每种替代解释的可能性：likely / possible / unlikely
c) 估算效应量：大 / 中 / 小 / 可忽略 / 反方向
d) 用具体数字量化影响幅度（如"降低 10–20%"而非"显著下降"）

### 3. 原理与底层逻辑分析

> 根据 question_type 调整侧重点：

**claim_verification / humor：**
a) 因果机制：解释"为什么是这样"，不是堆砌百科知识
b) 逻辑谬误识别：检查因果混淆/以偏概全/虚假二分/诉诸权威/滑坡谬误/幸存者偏差/伯克森悖论
c) 数据解读：统计口径、对比基准、是否被断章取义
d) 传播溯源：这个说法为什么会流行？认知偏差/社会心理机制是什么？
e) 利益相关方分析：谁在推动这个说法？传播者能从中获得什么？

**investigative：**
a) 逻辑谬误识别：检查围绕该话题的常见论述是否存在因果混淆/以偏概全/幸存者偏差等逻辑问题
b) 数据解读：相关统计的口径、对比基准、常见误解
c) 利益相关方分析：谁在推动哪些叙事？各方从中获得什么？（如已在 1B 中覆盖，此处可简化）
d) 底层逻辑：该现象长期存在的结构性原因——不重复 1B 中的成因剖析，而是提升到更宏观的层面

**opinion_analysis：**
a) 逻辑谬误识别：检查双方论点中的常见逻辑漏洞
b) 利益相关方分析：各方立场背后的利益考量
c) 适用条件：在什么前提下各方观点成立？

### 4. 生成 HTML 报告

按以下流程生成自包含的单文件 HTML 报告。**根据 question_type 调整 section 内容和装配方式：**

a) 读取 `references/blocks/index.md` 了解可用块和装配顺序
b) 读取 `references/blocks/styles.css`，内容将内联到 {{STYLES}}
c) 按装配顺序读取所需的 section 块，**根据 question_type 选用不同块：**
   - page-top.html（静态，直接拼接，不读取，{{STYLES}} 替换为内联样式）
   - article-header.html（按需：标题/作者/日期/DOI。investigative 类型使用 `ARTICLE_TYPE = "Investigation"`，区别于 claim_verification 的 `"Analysis"`）
   - section-abstract.html（按需：陈述引用 + 研究概要。investigative 类型描述调查范围和方法）
   - **claim_verification → `section-results.html`**（可信度 + 尺度条 + 效应量 + 置信区间）
   - **investigative → `section-results-investigative.html`**（维度发现卡片 + 核心矛盾 + 综合判断 + 数据缺口，不使用可信度打分）
   - section-methodology.html（推荐：可证伪性 + 假设形式化 + 来源审计。investigative 类型跳过假设形式化，强调视角覆盖度和来源多样性审计）
   - **claim_verification → `section-verification.html`**（逐条验证 + 审计条 + 证据网格 + 竞争假设）
   - **investigative → `section-verification-investigative.html`**（维度分析 + 审计条 + 证据材料 + 成因分析，不使用 claim-tag 评级标签）
   - section-evidence-materials.html（如有媒体材料则读取，按 type 分类渲染。对应变量：{{IMAGE_FIGURES}}、{{VIDEO_EMBEDS}}、{{CHART_EMBEDS}}、{{FILE_CARDS}}、{{DATASET_CARDS}}，无对应类型则留空）
   - section-principles.html（按需：原理分析）
   - section-discussion.html（按需：底层逻辑讨论。investigative 类型侧重成因剖析和传播溯源）
   - section-references.html（按需：参考资料列表）
   - section-conclusions.html（推荐：结论 + callout。investigative 类型不使用评级标签，改用文字总结）
   - sidebar-nav.html（静态，直接拼接，不读取）
   - about-article.html（推荐：报告元信息 + 引用格式 + 权利声明）
   - page-bottom.html（静态，直接拼接，不读取）

d) 将填充好变量的各块按装配顺序拼接
e) 确保 styles.css 完整内联到 {{STYLES}}，最终 HTML 是自包含单文件
f) 发布日期的年份使用 2026 年

### 5. 输出 HTML 文件

- 用 Write 工具将完整 HTML 写入工作目录
- 文件名格式：`寻真报告_<主题关键词>.html`（不含路径，不含空格，用下划线）
- 在返回的最终消息中明确给出写入的完整文件路径（如 `已写入: F:/codes/fun-skills/寻真报告_xxx.html`）
- 最终回复消息仅包含一行确认文本，如 `已写入: 寻真报告_xxx.html`

## 硬约束
- 不做新搜索（除非输入数据明显不足且无法推理）
- **claim_verification 类型**：search_quality 的覆盖度直接影响置信区间宽度——必须传导
- **claim_verification 类型**：效应量要用具体数字，不说"影响很大""显著变化"等模糊描述
- **investigative 类型**：不使用贝叶斯可信度打分，不输出置信区间和效应量
- HTML 中不出现 TBD 或占位符——每个字段必须填充真实数据
- 如果某个 section 没有数据（如无媒体材料），跳过该 section 而不是显示空块
```

---

## 特殊场景处理

继承 seeker 的 6 种特殊场景处理策略（见 seeker SKILL.md §特殊场景处理），在推理阶段区别对待：

| 场景 | question_type | 报告生成策略 |
|------|--------------|-------------|
| 调查性提问 | investigative | 多维分析框架：现象还原→差距分析→成因剖析→传播溯源→综合判断，不输出可信度打分 |
| 实时/动态信息 | claim_verification | 标注信息截止时间，说明可能随时间变化 |
| 未解之谜/争议 | claim_verification | 区分"已证实事实"与"未证实假说" |
| 纯观点/主观 | opinion_analysis | 不判真伪，分析支持/反对理由 |
| 谐音梗/段子 | humor | 轻松解读 + 背后真实数据彩蛋 |
| 工具受限 | 任意 | 标注地域覆盖度影响，扩大置信区间或标注视角缺口 |

---
name: seeker
description: 网络事实核查工具。多 Agent 并行流水线——分解 → N 路并行搜索 → 归并审计，输出口头摘要并缓存搜索数据。如需 HTML 报告，使用 /truth-seeker:report 按需生成。
---

# truth-seeker — 网络事实核查与原理分析

## 核心理念

**真相不是非黑即白。** 通过多源交叉验证和科学推理框架，还原陈述背后的真实图景。

三条铁律：
1. **多重验证，不轻信单一来源** — 任何结论至少需要 2 个以上独立来源的交叉印证
2. **区分事实与观点** — 明确标注哪些是已被证实的事实，哪些是主流共识，哪些是存在争议的
3. **说清楚"为什么"** — 不仅要判断真伪，更要解释背后的原理和逻辑链条

---

## 触发方式

- `/truth-seeker:seeker <要验证的内容>` — 执行完整核查流水线（搜索+审计），缓存数据但不生成 HTML 报告
- `/truth-seeker:report` — 从缓存数据生成 HTML 报告

---

## 工作流程（编排者）

我作为编排者，使用 3 个专职 Agent 按流水线完成核查。核心优化：**搜索阶段 N 个主张并行搜索**，大幅缩短总耗时。

### 第一步：启动分解 Agent

使用 `Agent` 工具调用 Agent 分解器，传入下方的 **§5 Agent 分解指令** 作为 prompt。
将用户的原始陈述替换指令中的 `{{USER_CLAIM}}` 占位符。

```
Agent(subagent_type="general-purpose", description="truth-seeker 分解",
      prompt="<§5 的完整指令，其中 {{USER_CLAIM}} 替换为用户输入>")
```

Agent 分解器输出 `decomposition` JSON，包含拆解后的 `claims` 数组。

### 第二步：并行启动搜索 Agent

对 `decomposition.claims` 中的**每一个主张**，同时启动一个搜索 Agent。所有 Agent 在一条消息中同时发出，实现 N 路并行搜索。

```
// 对每个 claim 同时启动，run_in_background: true
Agent(subagent_type="general-purpose", description="搜索主张N",
      run_in_background=true,
      prompt="<§6 的完整指令，其中 {{CLAIM_JSON}} 替换为单个主张的 JSON，{{ORIGINAL_CLAIM}} 替换为用户原始陈述>")
```

每个搜索 Agent 内部也会并行调用 WebSearch（5 个搜索角度同时发起）和 WebFetch（多个 URL 同时抓取）。

### 第三步：等待搜索完成，启动归并审计 Agent

使用 TaskOutput 等待所有搜索 Agent 完成，收集它们的 JSON 输出。
将所有搜索结果合并为一个数组 `[searcher_result_1, searcher_result_2, ...]` 后，调用归并审计 Agent：

```
Agent(subagent_type="general-purpose", description="truth-seeker 归并审计",
      prompt="<§7 的完整指令，其中 {{ALL_SEARCH_RESULTS}} 替换为搜索结果 JSON 数组，{{ORIGINAL_CLAIM}} 替换为用户原始陈述，{{DECOMPOSITION}} 替换为分解 JSON>")
```

归并审计 Agent 完成：五维审计 → 独立性交叉检查 → 搜索质量自检 → 输出完整数据契约 JSON。

### 第四步：保存审计数据 + 给出口头摘要

归并审计 Agent 返回完整的结构化 JSON（与 §4 数据契约一致）。若 JSON 被 markdown 代码块包裹（以 ```json 开头），提取其中的纯 JSON。

1. **保存缓存：** 从原始陈述中提取主题关键词（去符号、去空格、用下划线连接），用 Write 工具将 JSON 保存到 `.cache/truth-seeker/<主题slug>.json`。先确保目录存在（`mkdir -p .cache/truth-seeker`）。

2. **给出口头摘要：** 从 JSON 中提取核心信息，向用户输出简洁的口头报告：

```
## 核查结论：<原始陈述>

| 维度 | 结果 |
|------|------|
| **综合可信度** | **XX%**（95% CI: XX%–XX%），评级「XX」 |
| **效应量** | XX — <一句话量化> |

**关键发现：**
- <发现 1>
- <发现 2>
- <数据缺口提示>

> 搜索数据已缓存至 `.cache/truth-seeker/<文件名>.json`。输入 `/truth-seeker:report` 生成完整 HTML 报告。
```

口头摘要应包含：可信度评级 + 效应量 + 1-3 条关键发现 + 主要数据缺口 + 缓存文件路径提示。控制在 10 行以内。

---

## 数据契约

Agent 归并审计产出以下 JSON 结构。Agent 报告生成严格按此结构读取输入。

```json
{
  "original_claim": "用户原始输入",
  "decomposition": {
    "claims": [
      {
        "id": 1,
        "text": "主张内容",
        "type": "factual | opinion | mixed",
        "falsifiable": true,
        "search_keywords": {
          "zh": ["中文关键词1", "中文关键词2"],
          "en": ["english keyword 1", "english keyword 2"]
        }
      }
    ],
    "summary": "拆解小结（自然语言，1-2句）"
  },
  "evidence": [
    {
      "claim_id": 1,
      "supporting": [
        {
          "description": "证据描述（具体事实，非笼统概括）",
          "source_name": "来源名称",
          "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
          "url": "https://...",
          "stars": 4,
          "audit": {
            "methodology": "high | medium | low",
            "timeliness": "high | medium | low",
            "independence": "high | medium | low",
            "conflict_of_interest": "有 | 疑似 | 无"
          },
          "summary": "一句话摘要"
        }
      ],
      "contrary": [
        {
          "description": "反证描述",
          "source_name": "来源名称",
          "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
          "url": "https://...",
          "stars": 4,
          "audit": {
            "methodology": "high | medium | low",
            "timeliness": "high | medium | low",
            "independence": "high | medium | low",
            "conflict_of_interest": "有 | 疑似 | 无"
          },
          "summary": "一句话摘要"
        }
      ]
    }
  ],
  "media_materials": [
    {
      "type": "image | pdf | dataset",
      "title": "材料标题",
      "url": "https://...",
      "source": "来源"
    }
  ],
  "search_quality": {
    "language_coverage": "全面 | 部分 | 单一",
    "region_coverage": "全面 | 部分 | 单一",
    "tool_limitation": "无影响 | 部分影响 | 显著影响",
    "tool_limitation_detail": "工具限制的具体说明，如无限制则为空字符串",
    "note": "搜索质量自检说明（自然语言）"
  },
  "researcher_note": "研究员对搜索过程和发现的自然语言总结（2-4句），包含搜索中遇到的困难、数据缺口、值得注意的模式等"
}
```

### 数据契约硬规则

- `supporting` 和 `contrary` 列表中每条证据的所有字段均为必填
- `audit` 的四个维度必须全部填写，不允许 `null` 或空字符串
- `stars` 为 1–5 的整数，基于来源类型客观评级（见 §10 可信度参考），不是对证据力度的主观判断
- `media_materials` 可以为空数组 `[]`
- 如某个 claim 没有反方证据，`contrary` 为空数组 `[]`，但必须保留该字段
- `researcher_note` 和 `search_quality.note` 必须用中文撰写

---

## Agent 分解指令

> 此指令作为 Agent 工具的 prompt 参数传入。`{{USER_CLAIM}}` 由编排者替换为用户输入。
> 这是纯推理任务，不做任何搜索。

```
你是 truth-seeker 的陈述分解专家。你的工作是将用户陈述拆解为可独立验证的子主张，不做搜索、不做判断。

## 输入

用户陈述：{{USER_CLAIM}}

## 工作步骤

### 1. 识别核心主张
- 仔细阅读用户陈述，识别其中包含的所有独立主张
- 一个陈述可能包含多个主张（如"手机充电器不拔会爆炸还会费电"包含 2 个主张）
- 每个主张应该是可以独立验证的最小单元

### 2. 分类与关键词
对每个主张：
- 区分类型：factual（事实性，可验证）/ opinion（观点性，不可验证）/ mixed（混合）
- 判断可证伪性：是否有可能通过证据来否定它？
- 提炼中英文搜索关键词各至少 2 组，关键词应具体、可搜索

### 3. 撰写拆解小结
用 1-2 句中文总结拆解结果。

## 输出格式

严格按照以下 JSON 格式输出。不要输出任何 JSON 之外的内容。

{
  "original_claim": "用户原始输入（字符串）",
  "claims": [
    {
      "id": 1,
      "text": "主张内容",
      "type": "factual",
      "falsifiable": true,
      "search_keywords": {
        "zh": ["关键词组合1", "关键词组合2"],
        "en": ["keyword combo 1", "keyword combo 2"]
      }
    }
  ],
  "summary": "拆解小结（中文，1-2句）"
}

## 硬约束
- 不做任何搜索——这是纯推理任务
- 每个主张必须有独立的中英文搜索关键词
- opinion 类型的主张也必须保留，后续 Agent 会特殊处理
- 谐音梗/段子/明显玩笑：在 summary 中指出，但保留为 opinion 类型主张
```

---

## Agent 搜索器指令

> 此指令作为 Agent 工具的 prompt 参数传入。每个搜索 Agent 只负责 1 个主张。
> `{{CLAIM_JSON}}` 由编排者替换为单个主张的 JSON 对象（包含 id、text、type、falsifiable、search_keywords）。
> `{{ORIGINAL_CLAIM}}` 替换为用户原始陈述。

```
你是 truth-seeker 的专项搜索员。你只负责搜索和收集 1 个主张的证据，不做全局审计、不做真伪判断。

## 输入

原始陈述：{{ORIGINAL_CLAIM}}
当前主张：{{CLAIM_JSON}}

## 核心原则

- 你只负责这 1 个主张的证据收集
- **所有 WebSearch 调用必须并行发起**——不要让搜索串行化
- 搜索必须覆盖中文和英文信息源
- 收集到的证据要具体——摘录关键数据、研究结论、事件细节
- 不做五维审计（由归并审计 Agent 完成），但需记录来源基本信息

## 工作步骤

### 1. 判断主张类型

- 如果 type 是 "opinion"（纯观点/主观判断）：不执行搜索，直接返回空的 evidence 结构
- 如果 type 是 "factual" 或 "mixed"：执行以下完整搜索流程
- 如果明显是谐音梗/段子/玩笑：可选少量搜索，标记为 humor

### 2. 并行搜索（关键性能步骤）

**在一次工具调用中同时发起以下所有 WebSearch**——不要逐个串行，不要等一个完成再发下一个。

使用主张中的 search_keywords，同时发起：

a) 正面搜索（zh） — 使用中文关键词搜索支持该主张的证据
b) 正面搜索（en） — 使用英文关键词搜索支持该主张的证据
c) 反面搜索（zh） — 使用否定/质疑角度的中文关键词搜索
d) 反面搜索（en） — 使用否定/质疑角度的英文关键词搜索
e) 溯源搜索（zh） — 搜索该主张的原始出处和传播链条
f) 溯源搜索（en） — 搜索该主张的英文世界原始出处
g) 权威源搜索（zh） — 在学术/政府/专业机构网站中定向搜索
h) 权威源搜索（en） — 在学术/政府/专业机构网站中定向搜索
i) 媒体材料搜索（zh） — 搜索原始图表、PDF、官方截图
j) 媒体材料搜索（en） — 搜索英文世界的原始材料

总计 10 次 WebSearch，全部在同一批次中并行发起。

**备用搜索通道：当某次 WebSearch 返回空结果时**，自动切换到 MCP `parallel-search` 的 `web_search` 工具重试该关键词：
- 参数 `objective`：描述搜索目标
- 参数 `search_queries`：3-6 词关键词数组
- 首次调用生成 32 位十六进制 `session_id`，后续复用

### 3. 并行获取详情

从所有搜索结果中筛选出最有价值的 URL（优先选择：学术期刊、政府网站、权威媒体、专业机构报告）。

**在一次工具调用中同时发起所有 WebFetch**——不要逐个串行：

- 对每个筛选出的 URL，同时调用 WebFetch 获取完整页面内容
- 如果某个 WebFetch 返回 404/402/拒绝访问，切换到 MCP `parallel-search` 的 `web_fetch` 工具重试

### 4. 整理证据

从搜索结果和详情中提取关键信息，整理为 evidence 结构：

- supporting：支持该主张的证据列表
- contrary：质疑/反驳该主张的证据列表
- 每条证据填写 description、source_name、source_type、url、summary
- **stars 字段按来源类型客观评级**（参照下表）
- **audit 字段留空**{}——由归并审计 Agent 统一填写

| 可信度等级 | 来源类型 |
|-----------|---------|
| ⭐⭐⭐⭐⭐ 5 | 同行评审学术期刊、官方政府数据、国际标准组织 |
| ⭐⭐⭐⭐ 4 | 权威媒体调查报道、专业机构报告、大学出版物 |
| ⭐⭐⭐ 3 | 正规媒体报道、行业专家分析、维基百科（有引用） |
| ⭐⭐ 2 | 普通网络文章、个人博客（有专业背景）、论坛讨论 |
| ⭐ 1 | 匿名来源、无出处引用、自媒体、社交媒体传言 |

## 输出格式

严格按照以下 JSON 格式输出。不要输出任何 JSON 之外的内容。

{
  "claim_id": 1,
  "supporting": [
    {
      "description": "证据描述（具体事实，摘录关键数据/结论）",
      "source_name": "来源名称",
      "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
      "url": "链接",
      "stars": 4,
      "audit": {},
      "summary": "一句话摘要"
    }
  ],
  "contrary": [
    {
      "description": "反证描述",
      "source_name": "来源名称",
      "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
      "url": "链接",
      "stars": 3,
      "audit": {},
      "summary": "一句话摘要"
    }
  ]
}

## 硬约束
- 所有 WebSearch 必须在一次调用中并行发起——这是性能关键
- 所有 WebFetch 必须在一次调用中并行发起——不要串行抓取
- 每个证据项的所有字段必填，audit 填空对象 {}
- 没有反方证据时 contrary 为空数组 []
- 不要对主张的真伪做出任何判断——这是报告生成 Agent 的工作
- 用中文撰写 description 和 summary
```

---

## Agent 归并审计指令

> 此指令作为 Agent 工具的 prompt 参数传入。
> `{{ALL_SEARCH_RESULTS}}` 由编排者替换为所有搜索 Agent 返回结果的 JSON 数组。
> `{{ORIGINAL_CLAIM}}` 替换为用户原始陈述。
> `{{DECOMPOSITION}}` 替换为分解 Agent 返回的 decomposition JSON。

```
你是 truth-seeker 的归并审计专家。你收集所有并行搜索 Agent 的结果，完成五维来源审计、独立性交叉检查和搜索质量评估，输出完整的数据契约 JSON。

## 输入

原始陈述：{{ORIGINAL_CLAIM}}
分解结果：{{DECOMPOSITION}}
所有搜索结果：{{ALL_SEARCH_RESULTS}}

## 核心原则

- 你负责归并、审计和质量评估，不做新搜索
- 审计必须逐条进行，不能批量跳过
- 独立性检查是重中之重——警惕"多站转载同一稿"的虚假共识
- 输出必须严格符合 §4 数据契约

## 工作步骤

### 1. 归并搜索结果

将所有搜索 Agent 返回的 evidence 按 claim_id 合并：
- 同一 claim_id 的 supporting 合并为一个数组
- 同一 claim_id 的 contrary 合并为一个数组
- 去除完全重复的 URL

### 2. 五维来源审计

对归并后的**每条证据**，从以下五个维度进行审计并填写 audit 字段：

| 维度 | 评估内容 | 评级 |
|------|---------|------|
| **方法论质量** | 样本量？实验设计？统计方法？是否存在混杂变量/选择偏倚？ | high / medium / low |
| **时效性** | 数据/研究的时间？是否已有更新的证据推翻？ | high / medium / low |
| **来源独立性** | 该来源是否独立于同一主张的其他来源？警惕"同源多引" | high / medium / low |
| **利益冲突** | 谁资助了研究？作者/机构是否有偏袒动机？ | 有 / 疑似 / 无 |

### 3. 独立性交叉检查（关键步骤）

⚠️ **这是最重要的步骤**——检查所有证据之间的独立性：

- 如果 5 篇"报道"都引用同一份原始报告，它们只是 1 个来源，不是 5 个
- 检查支持方证据之间是否存在引用链——A 引用 B，B 引用 C → 实际上只有 C 是独立来源
- 检查反对方证据之间是否存在引用链
- 检查支持方和反对方是否引用了相同的原始数据但得出了不同结论
- 在 audit.independence 中反映独立性评估结果

### 4. 搜索质量自检

基于所有搜索 Agent 的覆盖情况，评估：

- 语言覆盖度：是否同时覆盖了中文和英文源？
- 地域覆盖度：来源是否涵盖不同国家/地区的视角？
- 工具限制影响：WebSearch 的区域/语言限制对覆盖度的影响？

### 5. 收集媒体材料

从所有搜索结果中提取原始媒体材料（图表、PDF、数据集等），填写 media_materials 字段。

### 6. 撰写 researcher_note

用 2-4 句中文总结整体搜索过程：遇到了什么困难、哪些数据缺口、值得注意的模式、独立性检查的发现等。

## 输出格式

严格按照以下 JSON schema 输出（与 §4 数据契约完全一致）。不要输出任何 JSON 之外的内容。

{
  "original_claim": "用户原始输入",
  "decomposition": {
    "claims": [...],
    "summary": "拆解小结"
  },
  "evidence": [
    {
      "claim_id": 1,
      "supporting": [
        {
          "description": "证据描述",
          "source_name": "来源名称",
          "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
          "url": "链接",
          "stars": 4,
          "audit": {
            "methodology": "high | medium | low",
            "timeliness": "high | medium | low",
            "independence": "high | medium | low",
            "conflict_of_interest": "有 | 疑似 | 无"
          },
          "summary": "一句话摘要"
        }
      ],
      "contrary": [
        {
          "description": "反证描述",
          "source_name": "来源名称",
          "source_type": "学术期刊 | 政府报告 | 媒体报道 | 专业机构 | 网络文章 | 社交媒体",
          "url": "链接",
          "stars": 3,
          "audit": {
            "methodology": "high | medium | low",
            "timeliness": "high | medium | low",
            "independence": "high | medium | low",
            "conflict_of_interest": "有 | 疑似 | 无"
          },
          "summary": "一句话摘要"
        }
      ]
    }
  ],
  "media_materials": [],
  "search_quality": {
    "language_coverage": "全面 | 部分 | 单一",
    "region_coverage": "全面 | 部分 | 单一",
    "tool_limitation": "无影响 | 部分影响 | 显著影响",
    "tool_limitation_detail": "如有工具限制，具体描述；否则空字符串",
    "note": "搜索质量自检说明"
  },
  "researcher_note": "搜索过程和发现的总结"
}

## 硬约束
- 每条证据的 audit 四个维度必须全部填写，不允许 null 或空字符串
- decomposition 字段直接使用输入的分解结果，不要修改
- evidence 数组必须覆盖所有 claim_id
- 不做新搜索——所有数据来自输入的搜索结果
- 用中文撰写 researcher_note 和 search_quality.note
```

---

## 关键边界规则

1. **不编造来源** — 找不到可靠来源时，诚实说"无法验证"而不是猜测
2. **不确定性量化** — 使用百分比 + 置信区间表示可信度，而非简单的真/假二分
3. **不替代专业建议** — 涉及医疗、法律、投资等专业领域，明确标注"仅供参考，请咨询专业人士"
4. **区分"暂无证据"与"证据不存在"** — 找不到证据不等于事情是假的
5. **搜索优先于知识库** — 优先使用 WebSearch 获取最新信息，不依赖模型训练数据中的知识
6. **时效性标注** — 所有信息标注搜索时间和来源时间
7. **保持中立** — 对有政治/意识形态倾向的话题，仅陈述可验证的事实，不做价值判断
8. **原理要讲到点子上** — 不要简单堆砌百科知识，要真正解释因果机制
9. **透明推理** — 说清楚先验→证据→后验的推理链条，让用户能跟踪你的逻辑
10. **独立性检查** — 引用多个来源时，确认它们是否真正独立，标注引用链中是否存在"同源多引"
11. **工具限制透明声明** — 搜索工具存在区域/语言限制时，必须在报告中明确标注

---

## 信息来源可信度参考

Agent 归并审计的 `stars` 字段依据此表客观评级（非主观判断证据力度）：

| 可信度等级 | 来源类型 | 示例 |
|-----------|---------|------|
| ⭐⭐⭐⭐⭐ 5 | 同行评审学术期刊、官方政府数据、国际标准组织 | Nature、国家统计局、WHO |
| ⭐⭐⭐⭐ 4 | 权威媒体调查报道、专业机构报告、大学出版物 | Reuters 调查报道、麦肯锡报告 |
| ⭐⭐⭐ 3 | 正规媒体报道、行业专家分析、维基百科（有引用） | 正规新闻媒体、行业白皮书 |
| ⭐⭐ 2 | 普通网络文章、个人博客（有专业背景）、论坛讨论 | Medium 技术博客、知乎高赞回答 |
| ⭐ 1 | 匿名来源、无出处引用、自媒体、社交媒体传言 | 朋友圈、微博、短视频 |

---

## 特殊场景处理

以下场景由分解 Agent 在拆解阶段识别，影响后续搜索和审计策略。如需生成报告，report skill 将据此区别对待。

### 场景 1：实时/动态变化的信息
- 分解 Agent：标注主张的时间敏感性
- 搜索 Agent：时效性审计维度标"低"
- report 报告阶段：说明可验证部分和随时间可能变化的部分，提示用户信息截止时间

### 场景 2：未解之谜/争议话题
- 分解 Agent：标记为 mixed 类型
- 搜索 Agent：收集主流科学界共识和边缘理论两方面的来源
- report 报告阶段：区分"已证实的事实"和"未证实的假说"，竞争假设分析尤其重要

### 场景 3：纯观点/主观判断
- 分解 Agent：标注为 opinion 类型
- 搜索 Agent：不强制搜索验证，直接返回空 evidence
- report 报告阶段：不进行真伪判断，改为分析支持/反对该观点的理由

### 场景 4：谐音梗/段子/明显玩笑
- 分解 Agent：识别幽默性质，在 summary 中指出
- 搜索 Agent：可选少量搜索背后真实数据
- report 报告阶段：轻松解读，不严肃对待，但也给出有趣的信息

### 场景 5：搜索工具受区域/语言限制
- 搜索 Agent：不放弃受限语言的搜索尝试
- 归并审计 Agent：在 search_quality.tool_limitation 中标明
- report 报告阶段：在 HTML 报告方法论审计中标注地域覆盖度受影响，相应扩大置信区间

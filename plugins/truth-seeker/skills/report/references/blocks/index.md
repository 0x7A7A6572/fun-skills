# 报告模板块索引

## 使用方式

生成 HTML 报告时，按以下流程操作：

1. **读本文件** — 了解可用块和装配顺序
2. **按需读取内容块** — 仅读取本次报告需要的 section 块（参考其 HTML 结构）
3. **跳过静态块** — 标记为"静态，无需读取"的块直接拼接，不消耗上下文
4. **按装配顺序拼接** — 用 `{{变量}}` 替换实际数据后拼接输出

---

## 块清单与装配顺序

按报告中出现的顺序排列：

| 序号 | 文件 | 类型 | 说明 |
|------|------|------|------|
| 1 | `page-top.html` | 静态，无需读取 | DOCTYPE → head → 品牌顶栏 → 面包屑 → 布局容器开始 |
| 2 | `article-header.html` | **按需读取** | 文章头部：标题、作者、日期、DOI |
| 3 | `section-abstract.html` | **按需读取** | Abstract：陈述引用 + 研究概要 |
| 4a | `section-results.html` | **推荐读取**（claim_verification） | 核心：综合可信度评级 + 尺度条 + 效应量 + 置信区间 |
| 4b | `section-results-investigative.html` | **推荐读取**（investigative） | 调查发现：各维度核心发现 + 核心矛盾 + 综合判断 + 数据缺口 |
| 5 | `section-methodology.html` | **推荐读取** | 验证方法论：可证伪性检查 + 假设形式化（可选） + 来源审计 |
| 6a | `section-verification.html` | **推荐读取**（claim_verification） | 逐条验证：claim-block × N（审计条 + 证据网格 + 竞争假设） |
| 6b | `section-verification-investigative.html` | **推荐读取**（investigative） | 维度分析：dimension-block × N（审计条 + 证据 + 成因分析） |
| 7 | `section-evidence-materials.html` | 按需读取 | 媒体证据：图表示例、文件下载卡片（无可跳过） |
| 8 | `section-principles.html` | 按需读取 | 原理分析：效率表格 + 驱动力 |
| 9 | `section-discussion.html` | 按需读取 | 底层逻辑：编号列表 + 能力光谱 |
| 10 | `section-references.html` | 按需读取 | 参考资料列表 |
| 11 | `section-conclusions.html` | **推荐读取** | 结论：首字下沉 + callout + 结尾 |
| 12 | `sidebar-nav.html` | 静态，无需读取 | 关闭主内容区 + 右侧导航栏 |
| 13 | `about-article.html` | **推荐读取** | 报告元信息 + 引用格式 + 权利声明 |
| 14 | `page-bottom.html` | 静态，无需读取 | 页脚 + 滚动监听脚本 + 闭合标签 |

> **静态块**（page-top、sidebar-nav、page-bottom）在每次报告中完全相同，AI 不需要读取它们——直接知道要拼接即可。
>
> **推荐读取**的块几乎每份报告都用，应当读取以了解其 HTML 结构和变量。
>
> **按需读取**的块根据报告内容决定是否使用。

---

## 装配模板

```
page-top.html
  + article-header.html
  + section-abstract.html
  + section-results.html
  + section-methodology.html     ← 新增
  + section-verification.html    ← 已升级（含审计条+竞争假设）
  + section-evidence-materials.html  ← 新增（可选）
  + section-principles.html
  + section-discussion.html
  + section-references.html
  + section-conclusions.html
  + sidebar-nav.html
  + about-article.html
  + page-bottom.html
```

---

## 各块变量参考

### page-top.html
```
{{TITLE}}        — 报告标题（显示在浏览器标签页）
{{PUBLISH_DATE}} — 发布日期，如 "12 July 2026"
{{STYLES}}       — 替换为 styles.css 的完整内容，包裹在 <style>/* ... */</style> 中。
                   确保最终 HTML 是自包含的单文件，不依赖外部 CSS。
```

### article-header.html
```
{{ARTICLE_TYPE}}   — 文章类型标签，如 "Analysis"
{{TITLE}}          — 报告主标题
{{SUBTITLE}}       — 副标题（可留空）
{{AUTHORS}}        — 作者名（不含上标数字）
{{AFFILIATION}}    — 隶属机构描述
{{VERIFY_DATE}}    — 核查日期，如 "2026年7月12日"
{{DOI}}            — DOI 标识符，如 "ts:2026/xxxx"
```

### section-results.html
```
{{VERDICT_SCORE}}        — 可信度百分比数字，如 55
{{VERDICT_LABEL}}        — 中文标签，如 "部分真实"
{{VERDICT_LABEL_CLASS}}  — CSS 后缀: true | mostly | partial | unknown | false
{{VERDICT_SCALE_PCT}}    — 尺度条宽度，如 "55%"
{{VERDICT_DESCRIPTION}}  — 详细评级说明（贝叶斯推理过程，支持 <strong>、<br>）
{{VERDICT_SUMMARY}}      — 评级总结段落

{{CI_RANGE}}             — 置信区间范围，如 "40%–70%"
{{CI_LEVEL}}             — 置信水平，如 "95%"

{{EFFECT_SIZE_LABEL}}    — 效应量标签，如 "小" / "中等" / "大"
{{EFFECT_SIZE_PCT}}      — 效应量条宽度（对应效应大小），如 "35%"
{{EFFECT_SIZE_CLASS}}    — CSS后缀: small | medium | large | neg
{{EFFECT_SIZE_DESC}}     — 效应量文字描述
```

**⚠️ 尺度条 is-active 注意事项：**
`scale-labels` 中 5 个 `<span>` 分别对应：虚假、无法判断、部分真实、基本真实、真实。
AI 需要根据评级结果，在对应的 `<span>` 上添加 `class="is-active"`，其他 4 个不加类。

### section-results-investigative.html
```
{{DIMENSION_FINDINGS}}   — 各维度发现卡片列表，每项格式:
  <div class="finding-card">
    <h3 class="finding-dimension">维度名称</h3>
    <p class="finding-text">该维度的核心发现（2-3句，有据可依）</p>
  </div>

{{CORE_TENSION}}         — 核心矛盾总结段落（说辞与现实的差距，可含 <strong>、<br>）
{{OVERALL_JUDGMENT}}     — 综合判断段落（文字结论，不使用百分比评分）
{{DATA_GAPS}}            — 数据缺口说明（哪些维度证据充分，哪些存疑）
```

### section-methodology.html
```
{{FALSIFIABILITY}}       — 可证伪性判断结论（一段话）
{{HYPOTHESIS_BOX}}       — 可选的假设形式化框，如不需要则删除。格式:
  <div class="hypothesis-box">
    <h4>假设形式化</h4>
    <div class="hypothesis-row">
      <div class="hypothesis-item">
        <div class="hypothesis-label h0">H₀（零假设）</div>
        <div class="hypothesis-text">该主张不成立 / 效应量为零</div>
      </div>
      <div class="hypothesis-item">
        <div class="hypothesis-label h1">H₁（备择假设）</div>
        <div class="hypothesis-text">该主张成立</div>
      </div>
    </div>
    <div class="hypothesis-standard">
      <strong>证据标准：</strong>需要____级别证据才能拒绝 H₀
    </div>
  </div>
{{AUDIT_STRIP}}          — 方法论审计标记条，4个 badge:
  <span class="audit-badge audit-badge--LEVEL">维度: 评级</span>
  每个 badge LEVEL: high | medium | low | na
  四个维度：方法论质量、时效性、来源独立性、利益冲突
{{METHODOLOGY_SUMMARY}}  — 方法论总结
```

### section-verification.html
```
每个 claim 所需变量：
{{CLAIM_N_TITLE}}           — 主张标题
{{CLAIM_N_TAG}}             — 评级标签文字
{{CLAIM_N_TAG_CLASS}}       — CSS后缀: claim-tag--true | mostly | partial | unknown | false
{{CLAIM_N_AUDIT}}           — 审计标记条 HTML（4个 audit-badge）
{{CLAIM_N_SUPPORTING}}      — 支持证据列表（多个 <li>）
{{CLAIM_N_CONTRARY}}        — 反方证据列表（多个 <li>）
{{CLAIM_N_ANALYSIS}}        — 分析文字
{{CLAIM_N_ALT_HYPOTHESES}}  — 竞争假设列表，每项格式:
  <div class="alt-hypothesis">
    <span class="alt-h-label">替代解释 N</span>
    <span>解释内容</span>
    <span class="alt-h-plausibility alt-h-plausibility--LEVEL">likely / possible / unlikely</span>
  </div>
  plausibility LEVEL: likely | possible | unlikely
```

证据项格式：
```html
<li>证据描述 <span class="evidence-source">来源名 <span class="evidence-stars">★★★★</span></span></li>
```

审计 badge 示例：
```html
<span class="audit-badge audit-badge--high">方法论质量: 高</span>
<span class="audit-badge audit-badge--medium">时效性: 中等</span>
<span class="audit-badge audit-badge--high">来源独立性: 高</span>
<span class="audit-badge audit-badge--low">利益冲突: 待确认</span>
```

### section-verification-investigative.html
```
每个维度 N 所需变量：
{{DIM_N_TITLE}}          — 维度标题
{{DIM_N_AUDIT}}          — 来源审计标记条 HTML（4个 audit-badge）
{{DIM_N_EVIDENCE}}       — 该维度的证据列表（多个 <li>，不区分正反方，按主题分组）
{{DIM_N_ANALYSIS}}       — 分析文字（<strong>分析：</strong>开头）
{{DIM_N_CAUSES}}         — 成因分析条目，每项格式:
  <div class="cause-item">
    <span class="cause-label">文化 / 制度 / 经济 / 传播</span>
    <span>具体成因分析</span>
  </div>
  cause-label 四个取值：文化、制度、经济、传播
```

证据项格式（与 section-verification.html 相同）：
```html
<li>证据描述 <span class="evidence-source">来源名 <span class="evidence-stars">★★★★</span></span></li>
```

### section-evidence-materials.html
```
按 media_materials 的 type 字段分类渲染，每个变量按需填充，无对应类型则留空：

{{IMAGE_FIGURES}}   — image 类型。用 <figure class="figure-box"> 包裹 <img> 直接显示。
                      格式:
                        <figure class="figure-box">
                          <img src="图片直接URL" alt="描述" loading="lazy">
                          <figcaption><strong>图 N.</strong> 标题。
                            <span class="figure-attr">来源：机构名称</span>
                            <a class="figure-source-link" href="来源URL">查看原始页面</a>
                          </figcaption>
                        </figure>

{{VIDEO_EMBEDS}}    — video 类型。用 <figure class="figure-box"> 包裹 <video> 标签。
                      格式:
                        <figure class="figure-box">
                          <video controls preload="metadata" style="width:100%;display:block;background:#000;">
                            <source src="视频直接URL" type="video/mp4">
                          </video>
                          <figcaption><strong>视频 N.</strong> 标题。
                            <span class="figure-attr">来源：机构名称</span>
                            <a class="figure-source-link" href="来源URL">查看来源</a>
                          </figcaption>
                        </figure>

{{CHART_EMBEDS}}    — chart 类型。交互式图表用 <iframe> 嵌入；静态图片退化同 IMAGE_FIGURES。
                      格式（iframe）:
                        <figure class="figure-box">
                          <iframe src="图表页面URL" loading="lazy"
                                  style="width:100%;height:500px;border:none;display:block;"></iframe>
                          <figcaption><strong>图 N.</strong> 标题。
                            <span class="figure-attr">来源：机构名称</span>
                            <a class="figure-source-link" href="来源URL">查看原始页面</a>
                          </figcaption>
                        </figure>

{{FILE_CARDS}}      — file 类型。下载卡片:
                        <a class="file-card" href="文件URL" target="_blank" rel="noopener">
                          <span class="file-card-icon">📄</span>
                          <div class="file-card-body">
                            <div class="file-card-name">文件名称</div>
                            <div class="file-card-meta">
                              <span>来源名称</span>
                              <span class="file-card-type">PDF</span>
                            </div>
                          </div>
                          <span class="file-card-arrow">→</span>
                        </a>
                      图标: 📄=PDF/文档, 📑=报告, 📝=文稿, 📋=表格文档, 📕=书籍

{{DATASET_CARDS}}   — dataset 类型。数据集下载卡片（格式同 FILE_CARDS）。
                      图标: 📊=数据表格, 📁=数据集, 📈=趋势数据, 💾=原始数据, 🗂️=多文件数据集
```

### section-principles.html
```
{{PRINCIPLES_INTRO}}   — 核心机制概述
{{PRINCIPLES_BODY}}    — 正文（多个 <p>）
{{TABLE_ROWS}}         — <tr><td>时代</td><td>开发方式</td><td>产出</td></tr>
{{TABLE_CAPTION}}      — 表格标题（含 <strong>表 N.</strong>）
{{DRIVERS_HEADING}}    — 驱动力子标题
{{DRIVERS}}            — 驱动力内容
```

### section-discussion.html
```
{{DISCUSSION_INTRO}}   — 引导段落
{{LOGIC_ITEMS}}        — 逻辑条目列表，每项:
                          <li><div><strong>标题 — </strong>内容。</div></li>
{{DISCUSSION_CLOSING}} — 结尾段落（可选）
```

能力光谱（嵌入在某个 `<li>` 内）：
```html
<div class="spectrum-figure">
  <div class="spectrum-bar">
    <div class="spectrum-seg"><span class="spectrum-seg-label">标签</span><span class="spectrum-seg-desc">描述</span></div>
  </div>
  <div class="spectrum-figcaption"><strong>图 1.</strong> 说明。</div>
</div>
```

### section-references.html
```
{{REF_ITEMS}} — 每项格式:
  <li>
    <span class="ref-authors">作者.</span>
    <span class="ref-title"> 标题.</span>
    <span class="ref-source"> 来源, 年份.</span>
    <a class="ref-link" href="URL">URL</a>
    摘要一句话。
  </li>
```

### section-conclusions.html
```
{{CONCLUSION_LEAD}}    — 首段（自动首字下沉）
{{CONCLUSION_BODY}}    — 正文段落
{{CALLOUT_CONTENT}}    — callout 框内容（支持 <strong>, <br>）
{{CONCLUSION_ENDING}}  — 结尾段落
```

### sidebar-nav.html
```
{{NAV_ITEMS}} — 导航链接（动态生成，只包含实际有的 section）:
  <li><a href="#abstract">Abstract</a></li>
  <li><a href="#results">Results</a></li>
  <li><a href="#methodology">Methodology</a></li>
  <li><a href="#verification">Verification</a></li>
  <li><a href="#materials">Evidence Materials</a></li>
  <li><a href="#principles">Principles</a></li>
  <li><a href="#logic">Discussion</a></li>
  <li><a href="#references">References</a></li>
  <li><a href="#conclusion">Conclusions</a></li>
```

### about-article.html
```
{{ABOUT_DATE}}       — 核查日期
{{ABOUT_REPORT_ID}}  — 报告编号
{{ABOUT_DOI}}        — DOI
{{ABOUT_ENGINE}}     — 生成引擎
{{CITE_TEXT}}        — 引用文本（含 <em>）
{{RIGHTS_TEXT}}      — 权利声明
```

### page-bottom.html
```
{{FOOTER_TEXT}} — 页脚文字
```

---

## 样式文件

`styles.css` — 全部 CSS 样式（含新增的假设框、效应量条、置信区间、审计标记、竞争假设、figure-box、file-card、evidence-gallery 等样式）。
AI 通常不需要读取此文件。生成最终 HTML 时，读取后替换 `page-top.html` 中的 `{{STYLES}}` 变量（包裹为 `<style>...</style>` 内联样式）。

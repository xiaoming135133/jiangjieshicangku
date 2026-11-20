# 批量创建任务 Issue（一次性脚本，用完可以删）
#
# 用法（在仓库根目录执行）：
#   pwsh -File scripts/create-issues.ps1            # 预览，什么都不创建
#   pwsh -File scripts/create-issues.ps1 -Apply     # 真的创建
#
# 提示：如果报「禁止运行脚本」，先执行一次
#   Set-ExecutionPolicy -Scope Process Bypass
#
# 前提：装了 GitHub CLI 并登录过一次（gh auth login），且当前目录在这个仓库里。

param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host '没找到 gh。先装 GitHub CLI 并执行 gh auth login，或直接在网页上手动建 Issue。' -ForegroundColor Yellow
    exit 1
}

$labels = @(
    @{ name = 'task';    color = '0E8A16'; desc = '可交付任务' },
    @{ name = 'data';    color = '5319E7'; desc = '数据与评测' },
    @{ name = 'server';  color = '1D76DB'; desc = '云端结构服务' },
    @{ name = 'align';   color = 'B60205'; desc = '增量结构对齐' },
    @{ name = 'app';     color = 'FBCA04'; desc = 'Android 客户端' },
    @{ name = 'search';  color = '006B75'; desc = '三层检索' },
    @{ name = 'web';     color = 'C2E0C6'; desc = '网页整理台' },
    @{ name = 'release'; color = 'D93F0B'; desc = '打包与提交材料' }
)

$issues = @(
    @{
        title  = '[W2] 100 张真实照片入库（分层抽样）'
        label  = 'data'
        goal   = '有了自己的样本，才谈得上测指标。'
        accept = @('印刷课件 30 张 / 纯手写板书 50 张 / 含公式 20 张', '统一命名 2026-11-20-高数-01.jpg，清单写入 datasets/photos.csv', '原始照片放本地 data/photos/，不进 git')
        ref    = 'docs/06-评测集与指标.md 第 1 节'
    }
    @{
        title  = '[W2] 识别服务 baseline 实验并回填指标'
        label  = 'data'
        goal   = '在写代码之前，先知道现成服务在我们自己的照片上能到多少。'
        accept = @('100 张全部跑完，逐条判"可用/需重打"', '汇总填进 docs/06 第 2 节"当前值"', '列出三类主要失败类型')
        ref    = 'docs/06-评测集与指标.md 第 3 节'
    }
    @{
        title  = '[W2] server 骨架：一张图进，LaTeX 出'
        label  = 'server'
        goal   = '把主链路最短的一段先跑通，后面所有事都挂在这上面。'
        accept = @('FastAPI 起得来，POST 一张图返回 JSON', '返回体含 LaTeX 与原图链接', 'README 补一条跑起来的命令')
        ref    = 'docs/02-技术方案.md 2.2'
    }
    @{
        title  = '[W2] 自动裁边与透视校正'
        label  = 'server'
        goal   = '拍歪的照片先扶正，后面分区才准。'
        accept = @('角点检测 + 透视变换可用', '失败时保留原图仅做亮度归一（不抛错）', '10 张倾斜样本前后对比图存 docs/assets/demo/')
        ref    = 'docs/02-技术方案.md 2.3.3'
    }
    @{
        title  = '[W2] 版面分区：文字/公式/图形/表格'
        label  = 'server'
        goal   = '让后续每一步只处理它该处理的部分。'
        accept = @('输出区域框 + 类别 + 阅读顺序', '双栏板书能正确排序', '分区失败时退化为整页 OCR 并打标记')
        ref    = 'docs/02-技术方案.md 2.3.3'
    }
    @{
        title  = '[W3] LaTeX 转 MathML 并建符号索引'
        label  = 'server'
        goal   = '让"搜一个符号"能命中，这是理工科场景的偏方。'
        accept = @('LaTeX → MathML 转换成功率记录', '符号集合可查询（单符号 + 组合）', '失败降级为纯文本检索')
        ref    = 'docs/02-技术方案.md 2.3.5'
    }
    @{
        title  = '[W3] 原图对照界面'
        label  = 'app'
        goal   = '产品诚实度的体现：任何自动结果都能点回原始那一页。'
        accept = @('任意识别结果可跳到原图对应区域', '可疑符号有标黄提示', '断网时原图仍可看')
        ref    = 'docs/01-项目概述.md 1.5 创新点二'
    }
    @{
        title  = '[W4] 候选生成三路并行'
        label  = 'align'
        goal   = '先把"可能挂在哪"的候选找出来，再谈判定。'
        accept = @('语义 / 字面 / 符号 三路各取前 10', '20 张样本每张输出 ≥ 3 个候选', '符号路在 5 个手写公式样例上命中正确节点')
        ref    = 'docs/02-技术方案.md 2.3.1'
    }
    @{
        title  = '[W4] 关系判定：四种关系 + 理由 + 置信度'
        label  = 'align'
        goal   = '系统的核心判断，一次结构化调用完成。'
        accept = @('JSON Schema 约束输出，四选一 + target + reason + confidence', '置信度越界有兜底', '错误样例记录到 datasets/align-failures.csv')
        ref    = 'docs/02-技术方案.md 2.3.1'
    }
    @{
        title  = '[W4] 阈值三档分流'
        label  = 'align'
        goal   = '≥0.80 直接执行；0.55–0.80 执行但标黄；<0.55 只进未归类箱。'
        accept = @('三档行为可在配置里改', '每档都有对应界面标记', '测试用固定知识树 + 固定输入做回归')
        ref    = 'docs/02-技术方案.md 2.3.1'
    }
    @{
        title  = '[W4] 知识树视图与拖拽改挂'
        label  = 'app'
        goal   = '任何自动结果都能被一键否决。'
        accept = @('树形浏览（课程/章/知识点三层）', '拖拽改挂后本地与云端一致', '批量归类、节点合并可用')
        ref    = 'docs/02-技术方案.md 2.2'
    }
    @{
        title  = '[W4] 对齐评测集 200 条标注'
        label  = 'data'
        goal   = '没有它，对齐准确率就只能靠嘴说。'
        accept = @('200 条标完，四类关系各 50', '20% 双人重标，不一致率 < 20%', 'CSV 字段符合 docs/06 第 4.3 节')
        ref    = 'docs/06-评测集与指标.md 第 4 节'
    }
    @{
        title  = '[W5] 未归类箱'
        label  = 'align'
        goal   = '允许系统说"我不知道"，这是整套设计里最关键的退路。'
        accept = @('角标显示条数，不打断任何操作', '上限 30，超出提升提示优先级', '箱内 3–5 条小聚类')
        ref    = 'docs/02-技术方案.md 2.3.2'
    }
    @{
        title  = '[W5] 批量确认交互'
        label  = 'app'
        goal   = '把 N 次打扰压成 1 次。'
        accept = @('一次提问处理 3–5 条', '可"再等等"，且延后不丢内容', '一次点击后树正确更新')
        ref    = 'docs/02-技术方案.md 2.3.2'
    }
    @{
        title  = '[W5] 修订记录落库'
        label  = 'server'
        goal   = '"越用越准"的真实机制，不是宣传语。'
        accept = @('记录 content_id / suggested / chosen / time_to_decide_ms', '按课程聚合可查', '每周批处理脚本能跑出修正率与混淆对')
        ref    = 'docs/02-技术方案.md 2.3.4'
    }
    @{
        title  = '[W5] 修正率首次统计并成图'
        label  = 'data'
        goal   = '证明"用户改得越来越少"这条指标真的成立。'
        accept = @('第一版修正率数字回填 docs/06 第 5 节', '列出主要混淆对', '提示词已按混淆对补 3–5 条少样本示例')
        ref    = 'docs/06-评测集与指标.md 第 5 节'
    }
    @{
        title  = '[W6] 三层检索：语义 / 符号 / 结构'
        label  = 'search'
        goal   = '让"我想不起在哪一页"变成"搜一下就出来"。'
        accept = @('三层各自可单独查询', 'D3 的 50 条查询集命中率可测', '命中结果标注命中原因')
        ref    = 'docs/02-技术方案.md 2.3.5'
    }
    @{
        title  = '[W6] 检索结果统一打分融合'
        label  = 'search'
        goal   = '三层结果不能各说各话，要合成一个排序。'
        accept = @('融合分数可解释（权重可调）', '展示"为什么给你看这个"', '前 5 条命中率 ≥ 80%')
        ref    = 'docs/02-技术方案.md 2.3.5'
    }
    @{
        title  = '[W7] 网页整理台（只读树 + 关系图）'
        label  = 'web'
        goal   = '大屏上看结构，比在手机上拖拽清楚得多。'
        accept = @('知识树只读视图', '关系图可点击跳转', '手机端改动刷新后可见')
        ref    = 'docs/02-技术方案.md 2.1'
    }
    @{
        title  = '[W7] 导出 Markdown / Obsidian 双链'
        label  = 'web'
        goal   = '不做数据孤岛，这是这个品类最便宜的信任建立方式。'
        accept = @('导出文件兼容 Obsidian 双链语法', '节点与边完整导出', '导出失败有明确提示')
        ref    = 'docs/02-技术方案.md 2.3.7'
    }
    @{
        title  = '[W8] 题目五槽位与错题本'
        label  = 'app'
        goal   = '拆开才可重组、可反查薄弱点。'
        accept = @('题干/已知/目标/图形/解法 五槽位', '错题按知识点重组', '卡点可跳回原页（三个月前那页也能找到）')
        ref    = 'docs/01-项目概述.md 1.5 创新点三'
    }
    @{
        title  = '[W8] 5 人试用两周并回收记录'
        label  = 'data'
        goal   = '用真实使用规模换掉"我们觉得"。'
        accept = @('5 名同学各用 ≥ 2 周', '累计 ≥ 500 张真实照片', '回收：修正率曲线、最常放弃的环节、原话引述')
        ref    = 'docs/03-项目计划.md 3.5'
    }
    @{
        title  = '[W9] Beta 打包与 Release'
        label  = 'release'
        goal   = '让评委能真的装上去点一下。'
        accept = @('Releases 里挂 APK + 源码包 + 校验说明', '安装说明三步以内', '打 tag v1.0-submission')
        ref    = 'docs/05-进度与里程碑.md 里程碑 tag'
    }
    @{
        title  = '[W9] 演示视频定稿与匿名自查'
        label  = 'release'
        goal   = '三分钟讲清"先绝望，再倒回去看怎么避免"。'
        accept = @('按 docs/04 附录 A 的倒叙脚本录制', '视频与截图不含校名/姓名/学号', 'docs/07 第 3 节全部打勾')
        ref    = 'docs/04-附录-演示与评分对照.md 附录 A'
    }
)

if ($Apply) {
    Write-Host "开始创建 $($issues.Count) 条 Issue…" -ForegroundColor Cyan
    foreach ($l in $labels) {
        # --force：已存在时更新而不是报错；万一旧版 gh 不认这个参数，也不该中断
        try { gh label create $l.name --color $l.color --description $l.desc --force 2>$null | Out-Null } catch { }
    }
} else {
    Write-Host '预览模式：不会创建任何东西。加 -Apply 才会真的建。' -ForegroundColor Yellow
}

$n = 0
foreach ($i in $issues) {
    $body = "**目标**：$($i.goal)`n`n**验收标准**`n" +
            (($i.accept | ForEach-Object { "- $_" }) -join "`n") +
            "`n`n**关联**：$($i.ref)`n`n> 完成时：PR 合入 main，并把相关进度/指标文档同步更新。"
    $n++
    if ($Apply) {
        try {
            gh issue create --title $i.title --body $body --label 'task' --label $i.label | Out-Null
        } catch {
            # 标签没建成功时，退一步：不带标签也要把 Issue 建出来
            Write-Host "[$n] 标签失败，改为无标签创建 $($i.title)" -ForegroundColor Yellow
            gh issue create --title $i.title --body $body | Out-Null
        }
        Write-Host "[$n] 已创建 $($i.title)"
    } else {
        Write-Host "[$n] 预览 $($i.title)  (label: task,$($i.label))"
    }
}

Write-Host ''
if ($Apply) {
    Write-Host "完成：$n 条。接下来到 Issues 页给它们分配负责人（Assignee），按周排序。" -ForegroundColor Green
} else {
    Write-Host "预览了 $n 条。确认无误后运行：pwsh -File scripts/create-issues.ps1 -Apply" -ForegroundColor Green
}

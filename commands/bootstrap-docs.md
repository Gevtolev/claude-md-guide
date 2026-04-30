---
description: 为当前项目搭建或重构完整的 Claude Code 文档体系（CLAUDE.md / ARCHITECTURE.md / docs/ + 项目级维护 skill）
---

请用 bootstrap-claude-docs skill 为当前工作目录搭建完整的文档体系。

按 skill 定义的三阶段流程执行：
1. Phase 0 检测项目状态并让我确认走哪条路径（greenfield / complete / restructure）
2. Phase 1 扫描与推断，输出假设清单让我审阅
3. Phase 2 生成骨架到 `.claude-docs-staging/`，让我审阅后再 mv 到正式位置
4. Phase 3 深度填充与验证

每个检查点都要停下来等我确认。

# 评论系统 — 技术交接文档

> acme-app 评论系统的技术交接。产品思考见 [docs/insights/comments.md](../insights/comments.md)

## 核心思路

卡片下的评论区支持 @ 提及、Markdown 渲染、软删除。所有评论事件通过 Redis pub/sub 广播给订阅该看板的前端客户端，实现近实时协作。

## 目录结构

```
src/
├── app/api/comments/
│   ├── route.ts              # POST /api/comments — 发表
│   ├── [id]/route.ts         # PATCH/DELETE
│   └── board/[boardId]/route.ts  # GET 按看板查
├── components/comments/
│   ├── CommentList.tsx       # 评论列表 + 订阅 SSE
│   ├── CommentForm.tsx       # 发表表单（含 @ 自动补全）
│   └── MentionPicker.tsx     # @ 提及选择器
└── lib/comments/
    ├── service.ts            # 业务逻辑（创建、更新、查询）
    ├── markdown.ts           # 服务端渲染 + XSS 过滤
    └── mentions.ts           # @ 解析 + 通知派发
```

## 数据流

发表：
```
CommentForm.submit()
  → POST /api/comments
  → auth middleware
  → comments/service.create(): 写 Postgres → 解析 @ → 写 notifications
  → Redis PUBLISH board:<id> { type: 'comment.created', comment }
  → 订阅该看板的前端 SSE 收到 → CommentList 重新拉取
```

## 数据模型

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY,
  card_id UUID REFERENCES cards(id),
  author_id UUID REFERENCES users(id),
  content TEXT NOT NULL,
  mentions UUID[] DEFAULT '{}',
  deleted_at TIMESTAMPTZ,      -- 软删除
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_comments_card ON comments(card_id) WHERE deleted_at IS NULL;
```

## 关键设计决策

1. **软删除**：保留审计痕迹；查询默认带 `WHERE deleted_at IS NULL`
2. **mentions 冗余存 UUID 数组**：避免每次查评论再 join 解析；写入时一次性解析
3. **Markdown 服务端渲染**：避免前端加载 markdown-it 包；同时统一 XSS 规则
4. **pub/sub 事件只带 comment 对象不带 board**：减少频道数，订阅方已知 board 上下文

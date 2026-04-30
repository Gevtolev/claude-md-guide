# ARCHITECTURE.md

acme-app 是一个虚构的 SaaS 看板工具：团队创建看板 → 添加卡片 → 拖拽状态流转 → 评论协作。Next.js 做前后端，PostgreSQL 做主存储，Redis 做实时协作层。

## 目录结构

```
src/
├── app/                # Next.js App Router
│   ├── api/            #   REST 端点（auth, boards, cards, comments）
│   ├── boards/         #   看板页
│   ├── login/          #   登录页
│   └── layout.tsx
├── components/         # React 组件
│   ├── ui/             #   基础组件（Button, Dialog）
│   ├── board/          #   看板相关（Column, Card, DragLayer）
│   └── comments/       #   评论相关
├── lib/                # 业务逻辑
│   ├── db.ts           #   Postgres 连接池 + 查询封装
│   ├── redis.ts        #   Redis 客户端 + pub/sub
│   ├── auth/           #   认证（JWT + bcrypt）
│   └── realtime.ts     #   实时协作编排
├── hooks/              # React Hooks
├── types/              # TypeScript 类型
└── i18n/               # 国际化
```

## 数据流

```
用户拖卡片 → 前端乐观更新 → POST /api/cards/:id/move
           → auth middleware 验 JWT → 更新 Postgres
           → Redis PUBLISH board:<id> 广播给其他订阅者
           → 其他客户端 SSE 订阅接收 → 刷新 UI
```

## 数据库

PostgreSQL，3 张主表：

| 表 | 用途 |
|----|------|
| `users` | 用户（email, password_hash, role） |
| `boards` | 看板（name, owner_id, settings JSON） |
| `cards` | 卡片（board_id, column, position, title, description, metadata） |
| `comments` | 评论（card_id, author_id, content, created_at） |

主要索引：`cards(board_id, column, position)` 支撑拖拽性能。

## 关键模块

- `src/lib/db.ts` — 所有 SQL 查询在这；不允许在 route handler 里裸写 SQL
- `src/lib/realtime.ts` — Redis pub/sub 的唯一入口；订阅管理 + 背压
- `src/lib/auth/` — JWT 签发 / 校验 + 中间件；所有 `/api/**` 默认要 auth

## 技术栈

| 层 | 技术 |
|----|------|
| 前端框架 | Next.js 15 (App Router) + React 19 |
| 样式 | Tailwind CSS |
| 状态 | Zustand（客户端）+ React Query（服务端） |
| 数据库 | PostgreSQL 16 + pg |
| 缓存/实时 | Redis 7 |
| 认证 | JWT (jose) + bcrypt |
| 测试 | Vitest（单元）+ Playwright（E2E） |
| 部署 | Docker + AWS ECS |

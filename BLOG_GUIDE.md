# 博客日常操作速查

结合当前 Hexo + Butterfly 的配置，整理一份写作与维护的基本流程，随时翻阅。

## 1. 写文章

```bash
npx hexo new post "HDMI 2.1 Deep Dive"
```

会生成 `source/_posts/hdmi-2-1-deep-dive.md`。编辑时保持 front‑matter 完整：

```yaml
---
title: HDMI 2.1 Deep Dive
date: 2025-03-01 10:00:00
updated: 2025-03-01 10:00:00
categories:
  - 接口协议
tags:
  - HDMI
  - TMDS
cover: https://...
description: 一句话摘要
---
```

推荐写完后 `npx hexo clean && npx hexo g && npx hexo s` 本地预览。

## 2. 插入图片

1. **全站共享图片**：放到 `source/img/` 下，Markdown 中用 `/img/xxx.png`。
2. **文章资源目录**（可在 `_config.yml` 设置 `post_asset_folder: true`）：
   ```
   source/_posts/my-post.md
   source/_posts/my-post/diagram.png
   ```
   文内引用 `![示意图](./my-post/diagram.png)`。
3. 外链图片直接使用完整 URL。注意控制体积，必要时压缩。

## 3. 更换头像 / 图标

在 `themes/butterfly/_config.yml` 中修改：

```yaml
avatar:
  img: /img/avatar.png
favicon: /img/favicon.svg
logo: /img/logo.svg
```

把对应文件放到 `source/img/`。若使用外链，直接填入 URL。

## 4. 主题配置常见项

- 导航菜单：`themes/butterfly/_config.yml` → `menu`.
- 首页字幕、封面：`subtitle`、`index_img`、`default_top_img`.
- 侧栏卡片：`aside.card_author` / `card_tags` 等。
- 颜色与字体：`theme_color`、`font`.

修改后执行 `npx hexo clean && npx hexo g`，再 `npx hexo s` 检查。

## 5. 本地调试与生成

| 操作 | 命令 |
| --- | --- |
| 清理缓存 / public | `npx hexo clean` |
| 生成静态文件 | `npx hexo generate` |
| 本地预览 | `npx hexo server -o` |

常规流程：写作 → `hexo clean` → `hexo g` → `hexo s` → 确认无误再部署。

## 6. 部署到 GitHub Pages

1. 确保 `_config.yml` 中的 `deploy` 配置正确（例如 `type: git`, `branch: gh-pages`）。
2. 运行：
   ```bash
    npm install hexo-deployer-git --save   # 首次需要
    npx hexo clean && npx hexo g && npx hexo deploy
   ```
3. GitHub → Settings → Pages 选择 `gh-pages` 分支发布，等待 1–2 分钟后访问 `https://djdgctw.github.io/`。

## 7. Git 操作

```bash
git add .
git commit -m "update blog"
git branch -M main      # 首次
git push origin main
```

主仓库存源码，`hexo deploy` 推 `public` 到 `gh-pages`。必要时记得同步两侧。

## 8. 常见问题

- **页面显示 Pug 代码**：缺少 `hexo-renderer-pug`，执行 `npm install hexo-renderer-pug --save`。
- **侧栏报错**：检查 `themes/butterfly/_config.yml` 是否按照数组结构写 `footer.nav`、`aside.stack` 等。
- **图片 404**：确认路径以 `/img/` 开头且图片位于 `source/img/`。
- **部署后仍旧旧版本**：清浏览器缓存，或重新 `hexo clean && hexo g && hexo deploy` 并确认 GitHub Pages 指向正确分支。

随时根据自己的习惯扩充这份指南，保持流程清晰就能高效更新博客。

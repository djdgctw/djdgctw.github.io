# Hexo 博客使用指南

通过 Hexo + Butterfly 主题打造的硬件笔记博客。下面是本地开发、写作以及发布的完整流程，方便后续维护。

## 1. 环境准备

- Node.js 20 LTS（推荐使用 [nvm-windows](https://github.com/coreybutler/nvm-windows) 管理版本）
- NPM 9.9（`corepack enable` 后可用 `npm i -g npm@9.9.0` 固定版本）
- Git（可选，仅在推送到 GitHub Pages 时需要）

```bash
node -v    # 确认 20.x
npm -v     # 确认 9.9.x
```

## 2. 项目初始化 / 依赖安装

```bash
cd C:\Users\86184\hexo-blog
npm install
```

依赖说明：

- `hexo` 主程序及常见 generator / renderer 组件
- `hexo-renderer-pug`：让 Butterfly 的 Pug 模板能被渲染
- `hexo-generator-feed`：输出 `atom.xml`，方便 RSS 订阅

## 3. 常用命令

| 作用 | 命令 |
| --- | --- |
| 清理缓存与静态文件 | `npx hexo clean` |
| 本地预览（默认 <http://localhost:4000>） | `npx hexo server` |
| 生成静态页面到 `public/` | `npx hexo generate` |
| 一次性清理 + 生成 | `npx hexo clean && npx hexo generate` |

> 预览调试时推荐：`npx hexo s -o` 自动打开浏览器。完成修改后运行 `hexo g` 产出最终文件，再部署到 GitHub Pages。

### 脚本快捷方式

项目提供 `tools/blog-tool.ps1`，包含两个常用工作流：

```powershell
# 1) 一键清理 + 生成 + 启动本地服务（当前终端，Ctrl+C 停止）
powershell -ExecutionPolicy Bypass -File tools/blog-tool.ps1 -Action preview

# 2) 一键清理 + 生成 + hexo deploy
#    如有源码改动，会提示输入 git commit 信息并推送 main 分支
powershell -ExecutionPolicy Bypass -File tools/blog-tool.ps1 -Action deploy
```

根据提示操作即可快速预览或发布。

## 4. 写作 / 内容维护

1. **新建文章**  
   ```bash
   npx hexo new post "HDMI 1.4 深入理解"
   ```  
   文章会生成在 `source/_posts/`，使用 Markdown 编写即可。

2. **Front‑matter 建议字段**（示例在 `source/_posts/*.md` 中）  
   ```yaml
   ---
   title: HDMI 1.4 协议总结（一）：综述和编码方式
   date: 2025-02-15 10:00:00
   updated: 2025-02-15 10:00:00
   categories:
     - 接口协议
   tags:
     - HDMI
     - TMDS
   cover: https://...
   description: 一句话摘要
   ---
   ```

3. **页面说明**
   - `source/about/index.md`：个人介绍与 Roadmap，支持 Markdown / HTML 混写。
   - `source/img/`：自定义 LOGO、头像、favicon 等资源，Butterfly 配置已经指向这里的 SVG。

## 5. 主题与配置

- 全局站点配置：`_config.yml`（网站标题、域名、feed、部署设置等）。
- Butterfly 主题配置：`themes/butterfly/_config.yml`（导航、封面、侧边栏、配色、字体、特效等）。
- 典型可调区域：
  - `nav` / `menu`：顶部导航与按钮
  - `cover`、`default_top_img`：首页和文章封面
  - `aside.card_*`：侧栏卡片（作者信息、公告、标签、归档等）
  - `theme_color`、`font`：全局配色与排版

修改配置后执行 `npx hexo clean && npx hexo g && npx hexo s` 检查效果。

## 6. RSS 与部署

- RSS：`atom.xml` 自动生成，可在浏览器访问 `<站点>/atom.xml` 检查。
- 部署到 GitHub Pages：
  1. **初始化仓库（首次）**
     ```bash
     git init
     git remote add origin https://github.com/<your-name>/<your-repo>.git
     ```
  2. **生成静态文件**
     ```bash
     npx hexo clean && npx hexo generate
     ```
  3. **推送源码（main 分支）**
     ```bash
     git add .
     git commit -m "update blog"
     git push origin main
     ```
  4. **发布静态页面**
     - 方案 A：使用 Hexo 自带部署（推荐单独部署分支）
       ```yaml
       # _config.yml
       deploy:
         type: git
         repo: https://github.com/<your-name>/<your-repo>.git
         branch: gh-pages
       ```
       ```bash
       npm install hexo-deployer-git --save
       npx hexo clean && npx hexo g && npx hexo deploy       # 自动将 public/ 推送到 gh-pages
       ```
    
       ```
  5. **GitHub Pages 设置**：在仓库 Settings → Pages 中选择 `gh-pages` 分支 / `docs` 目录（取决于你的部署方式）。

## 7. 常见问题

- **页面显示模板源码**：缺少 `hexo-renderer-pug`，执行 `npm install hexo-renderer-pug --save` 后重建即可。
- **侧栏或 Footer 报错**：Butterfly 需要按照官方结构填写数组/对象，参考 `themes/butterfly/_config.yml` 里的现有示例。
- **图片不显示**：本地图片需放在 `source/` 下（如 `source/img/...`），引用时用绝对路径 `/img/xxx.svg`。

如需进一步扩展（评论系统、统计、搜索等），优先查看 [Butterfly 官方文档](https://butterfly.js.org/) 以确认插件兼容性。祝写博愉快！

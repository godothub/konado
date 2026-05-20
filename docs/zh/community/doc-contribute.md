---
title: 文档贡献
order: 4
---

# 文档贡献指南

## 在线编辑

在线编辑文档，点击在线文档左下角的 `在线编辑此页`，浏览器会跳转到仓库文件所在目录位置，此时点击右上角 `编辑` 按钮，修改后预览查看效果，确认无误后点击 `提交修改` 提交。

提交后会经过审查，通过后合并到主仓库。一般主仓库合并后，在线文档会自动更新，如果没有更新，请手动刷新页面，或者提交后等待几分钟再刷新。

## 本地编辑

文档可以直接向 `master` 分支`提交PR`，不必创建特性分支。

在提交代码之前请确保在本地完成了 Git 的全局配置
```
git config --global user.name 你的Git用户名
git config --global user.email 你的提交邮箱，必须和代码平台账户邮箱一致
```

1. **Fork 项目**：点击右上角 Fork 到自己的仓库  
2. **克隆仓库**：`git clone`  
3. **编辑文档**：在 `docs` 目录下找到需要修改的文件，使用 Markdown 语法进行编辑（参考 [Markdown 语法](https://www.markdownguide.org/basic-syntax)）
4. **提交更改**：`git commit -m "描述你的文档更改"`  
5. **推送分支**：`git push origin master`

提交后，在自己fork的仓库页面、点击`Pull Request`按钮，创建 PR。

## 本地预览Konado文档
Konado 文档基于 [VitePress](https://vitepress.dev/) 构建，为确保文档修改内容符合预期，建议先在本地预览验证后再提交代码。

### 前置准备：安装 Node.js
VitePress 依赖 Node.js 环境运行，需先安装符合版本要求的 Node.js：
1. **版本要求**：推荐安装 Node.js 18.x 及以上版本（LTS 长期支持版最佳，兼容性更优）。
2. **下载安装**：
   - 访问 Node.js 官方下载地址：[https://nodejs.org/](https://nodejs.org/)
   - 根据操作系统（Windows/macOS/Linux）选择对应安装包，按向导完成安装（Windows 建议勾选“Add to PATH”选项）。
3. **验证安装**：
   打开终端（Windows 为命令提示符/PowerShell，macOS/Linux 为终端），执行以下命令验证 Node.js 和 npm（Node.js 自带包管理器）是否安装成功：
   ```shell
   # 查看 Node.js 版本
   node -v
   # 查看 npm 版本
   npm -v
   ```
   若输出清晰的版本号（如 `v20.10.0`、`10.2.3`），说明安装成功。

> 可选优化：若 npm 下载依赖速度较慢，可配置国内镜像提升速度：
> ```shell
> npm config set registry https://registry.npmmirror.com
> ```

### 安装项目依赖
进入 Konado 项目的根目录，执行以下命令安装文档预览所需依赖：
```shell
npm install
```
等待命令执行完成，终端无报错即表示依赖安装成功。

### 启动本地预览服务
依赖安装完成后，执行以下命令启动 VitePress 开发服务：
```shell
npm run docs:dev
```

### 访问预览文档
命令执行成功后，终端会输出类似以下的信息：
```shell
vitepress v1.6.4

➜  Local:   http://localhost:5173/konado/
➜  Network: use --host to expose
➜  press h to show help
```
打开浏览器，访问输出信息中的 `Local` 地址（默认：`http://localhost:5173/konado/`），即可查看本地文档。

### 补充说明
1. 实时刷新：修改文档内容后，无需重启服务，浏览器会自动刷新页面，实时展示修改后的效果；
2. 端口异常：若 `localhost:5173` 端口被占用，VitePress 会自动切换到可用端口（如 5174），请以终端实际输出的地址为准；
3. 局域网访问：如需在局域网内其他设备（如手机、另一台电脑）预览文档，可执行 `npm run docs:dev -- --host` 命令，终端会输出网络可访问的 IP 地址；
4. 停止服务器：在终端中按下 `Ctrl + C` 即可停止本地预览服务。
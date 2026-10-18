# 构建命令

在 GoLand 编辑器中，点击各个 Bash 代码块左侧的 ▶，只执行对应的命令。
GoLand 从当前文件所在的 `script` 目录执行以下命令。

## 日常编译（版本不变）

```bash
bash build.sh
```

## 发布小更新（末位版本号加一，生成 ZIP 和校验文件）

```bash
bash build.sh --release
```

## 发布较大更新（中间版本号加一、末位归零，生成 ZIP 和校验文件）

```bash
bash build.sh --release minor
```

## 打开编译产物目录

```bash
open ../dist
```

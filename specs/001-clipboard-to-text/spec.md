# Feature Specification: 剪贴成文

**Feature Branch**: 当前工作区（未建立新分支）
**Created**: 2026-09-17
**Status**: 原型已实现并安装；文件夹右键验收通过，桌面空白处与完整耗时待确认
**Input**: 将微信、飞书中复制的口播稿和提示词，通过桌面右键自动命名并保存为文本。

## User Scenarios & Testing

### User Story 1 - 一次操作保存原文 (Priority: P1)
用户复制文字后，在桌面空白处右键选择「将剪贴板保存为文本」，立即获得已保存文件。
**Why this priority**: 省去新建、打开、粘贴、另存为。
**Independent Test**: 复制中文、空行、标点与 Emoji，点击菜单并比较全文。
**Acceptance Scenarios**:
1. Given 剪贴板有文字，When 点击菜单，Then 桌面生成 .txt，全文保留，无命名或保存对话框。
2. Given 首次启用完成，When 保存成功，Then 新文件在 Finder 中选中，可直接改名或打开。

### User Story 2 - 自动命名且不覆盖 (Priority: P1)
第一行非空文字命名，处理非法字符与重名。
**Why this priority**: 用户明确选择直接保存。
**Independent Test**: 同一内容保存两次，两文件都存在，原文件未变。
**Acceptance Scenarios**:
1. Given 前几行空白，When 保存，Then 使用第一行非空文字命名。
2. Given 同名文件存在，When 保存，Then 添加「 2」「 3」等序号。
3. Given 首行过长或含路径符号，When 保存，Then 文件名有效可见且正文不变。

### User Story 3 - 失败反馈与首次启用 (Priority: P2)
无文字或无法写入时得到原因；首次有启用引导。
**Why this priority**: 避免误以为保存成功。
**Independent Test**: 空剪贴板和不可写目录下保存，不产生空文件。
**Acceptance Scenarios**:
1. Given 空、纯空白或仅图片，When 保存，Then 提示先复制文字且不创建文件。
2. Given 权限被拒，When 保存，Then 提示检查桌面权限，不覆盖原文件。
3. Given 未启用扩展，When 打开应用，Then 可找到启用入口和使用说明。

### Edge Cases
LF、CRLF、CR 和 Unicode 换行；文件名斜杠、冒号、控制字符和隐藏文件前缀；目录重名、并发保存和写入失败。
正文首尾空白保留，纯空白不保存。

## Requirements

### Functional Requirements
- FR-001: 桌面空白处右键显示「将剪贴板保存为文本」。
- FR-002: 仅主动保存时读文字，以 UTF-8 无 BOM 保存 .txt，正文不变。
- FR-003: 首行非空文字命名，最多 60 个可见字符且不超过 180 字节，过滤非法字符；无有效名字回退「未命名」。
- FR-004: 重名加序号，并发时亦不覆盖。
- FR-005: 保存到系统桌面目录，成功在 Finder 中选中；优先桌面选中，若只能在文件夹窗口选中则如实标注。
- FR-006: 无文字及写入失败有中文提示，不留下空白占位文件。
- FR-007: 首次启用扩展有引导，无联网或账号，不持续监听剪贴板。

### Key Entities
- 剪贴板文字：本次主动复制内容，只保留本次保存的内存副本。
- 文本文件：桌面上的文件名、原始正文、保存路径。

## Success Criteria

### Measurable Outcomes
- SC-001: 首次启用后，仅右键与一次菜单点击即可保存，无保存对话框。
- SC-002: 10 万字以内样例在正常本机桌面 2 秒内出现文件。
- SC-003: 中文、空行、混合换行、Emoji 测试正文全部准确保留。
- SC-004: 连续与并发重名保存无旧文件丢失；失败不残留空文件。

## Assumptions
- 仅复制的纯文字，不读取聊天应用、截图或附件，不合并多条消息。
- 目标用户当前 Apple Silicon Mac；其他版本兼容性独立标注。
- 首次按系统流程启用 Finder 扩展和桌面访问权限。
- 无 AI 和外部服务，暂不提供格式和目录设置。

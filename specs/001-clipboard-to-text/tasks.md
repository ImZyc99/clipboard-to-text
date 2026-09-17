# Tasks: 剪贴成文

## Phase 1: Setup
- [x] T001 在 .specify/ 与 specs/001-clipboard-to-text/ 建立原则、需求和计划。
- [x] T002 建立 Package.swift、.gitignore、scripts/build.sh 与 Resources/ 包配置。

## Phase 2: Foundational
- [x] T003 在 Tests/TextCoreTests/TextFileWriterTests.swift 建立原文、命名、不覆盖、异常与性能验收测试。

## Phase 3: US1 一次操作保存
- [x] T004 [US1] 在 Sources/TextCore/TextFileWriter.swift 实现原文 UTF-8 写入与失败清理（FR-002、SC-002/003）。
- [x] T005 [US1] 在 Sources/FinderExtension/FinderSync.swift 实现桌面菜单与宿主定向命令（FR-001）。
- [x] T006 [US1] 在 Sources/App/ClipboardToTextApp.swift 接收命令、按需读取文字、保存并 Finder 选中（FR-002/005）。

## Phase 4: US2 自动命名
- [x] T007 [US2] 在 Sources/TextCore/TextFileWriter.swift 实现首行命名，最多 60 个 Character / 180 UTF-8 字节，非法字符和空名字回退（FR-003）。
- [x] T008 [US2] 在 Sources/TextCore/TextFileWriter.swift 原子发布并加序号，文件/目录重名和并发均不覆盖（FR-004、SC-004）。

## Phase 5: US3 失败反馈与启用
- [x] T009 [US3] 在 Sources/App/ClipboardToTextApp.swift 加中文错误提示、扩展状态与启用引导（FR-006/007）。
- [x] T010 [US3] 在 scripts/install.sh 实现用户目录安装和标准扩展注册，写 README.md 使用说明。

## Phase 6: 收敛
- [x] T011 运行核心测试、构建与签名校验，记录 specs/001-clipboard-to-text/validation.md。
- [ ] T012 实机验证桌面右键到文件创建、重复命名与失败反馈，更新 specs/001-clipboard-to-text/validation.md（SC-001）。
- [x] T013 按 speckit-converge 对照源码与需求复查，更新 specs/001-clipboard-to-text/tasks.md。

## Dependencies & Execution Order
T001 → T002/T003 → T004 → T005/T006 → T007/T008 → T009/T010 → T011/T012 → T013。
US1 可用固定安全命名独立验证；US2 核心测试不依赖 UI；US3 异常可从应用直接保存入口验证。

## Parallel Opportunities
US1：菜单和宿主在协议确定后可独立实现；US2：采用同一文件顺序执行；US3：安装说明与设置界面可独立处理。
本任务仅委派只读技术研究，实现由主代理完成。

## Implementation Strategy
先完成安全文件保存和原生构建，再验证系统菜单；不把编译成功当成桌面验证通过。

## Phase 7: Convergence
- [ ] T014 实测真正桌面壁纸空白处右键入口与保存；需用户反馈补充自动化工具无法操作桌面的证据；更新 specs/001-clipboard-to-text/validation.md，完成后关闭 T012。依据 FR-001、US1/AC1、SC-001（partial）。
- [ ] T015 测量首次及再次点击右键菜单到文件出现的完整耗时，确认 SC-002；核心写入已通过，但首次剪贴板读取存在系统延迟。更新 specs/001-clipboard-to-text/validation.md（partial）。

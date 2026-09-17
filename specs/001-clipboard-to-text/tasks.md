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

## Phase 8: 真实桌面右键修复
- [ ] T016 在 Sources/FinderExtension/FinderSync.swift 记录不含正文/路径的回调诊断，核对真实桌面入口缺失原因（FR-001）。
- [ ] T017 在 Sources/TextCore/DesktopMenuPolicy.swift 与 Tests/TextCoreTests/TextFileWriterTests.swift 增加桌面菜单判定及回归测试；修正 FinderSync.swift（FR-001）。
- [x] T018 更新 scripts/install.sh，退出并替换本应用扩展，备份不留在 Applications 内，并验证加载新版本（plan: 安装更新）。
- [ ] T019 对照用户截图在真实桌面重测菜单与保存，更新 validation.md，保留未通过项（US1/AC1）。

## Phase 9: US4 菜单栏与图标
- [x] T020 [US4] 在 Sources/App/ClipboardToTextApp.swift 实现常驻菜单栏、动态扩展状态和无自动窗口生命周期（FR-008/009）。
- [x] T021 [US4] 生成 Resources/AppIcon.png，新增 scripts/build-icon.sh 并接入 scripts/build.sh、Resources/App-Info.plist，设置页使用棕色图标，菜单栏用 BrandIcon.swift 透明单色核心元素（FR-010）。
- [ ] T022 [US4] 构建安装后实测冷启动、设置往返、保存、退出，更新 README.md 与 specs/001-clipboard-to-text/validation.md（SC-005）。

T020 与图标生成可独立进行；T021 接入后再 T022。菜单栏交付不替代 T014/T019 的真实桌面验证。

## Phase 10: Convergence
- [ ] T023 在 specs/001-clipboard-to-text/validation.md 补齐 US4/AC3/AC4 与 SC-005 实机证据：关闭设置后的菜单保存、退出后图标消失、再次打开无自动窗口；图标与设置已获用户确认，accessory 应用暂无法由电脑操作工具控制（partial，关联 T022）。

## Phase 11: 应用图标透明度
- [x] T024 [US4] 修正 Resources/AppIcon.png 的内部半透明并记录 Resources/Icon.md，验证 alpha 后重新打包安装，更新 validation.md（FR-010）。

# 数据模型

- DesktopPasteState：enabled（UserDefaults）、accessibilityTrusted、monitorInstalled；不持久化按键或焦点内容。
- DesktopPasteContext：是否 Finder 前台、是否确定桌面祖先、是否窗口/编辑焦点；任何未知结果均放弃。
- PasteboardSnapshot：一次读取的 ClipboardContent（text String 或 image PNG Data）+ 前后 changeCount，仅本次保存持有，变化则不保存。

- TextInput：原始 String；必须至少含一个非空白字符，正文不标准化。
- FileName：首个非空行，首尾空白移除；非法路径符号替换、控制字符删除、前导点移除；最多 60 个 Character / 180 UTF-8 字节；空值回退「未命名」。
- SavedText：URL，扩展名 .txt；名称冲突依次加空格和 2、3…；不保存历史。
- SaveError：emptyText / IO 错误；向用户提供中文提示，不包含正文。
- 状态：闲置 → 用户点击 → 读剪贴板 → 验证 → 写临时文件 → 不覆盖发布 → 闲置（无窗口副作用）；失败清理临时文件并提示。
# 菜单栏状态
AppDelegate 持有 statusItem 与可选 settingsWindow；菜单打开时获取 extensionEnabled。两者仅内存状态，无新增持久化或剪贴板读取。生命周期为启动→菜单栏常驻→显式打开/关闭设置→退出；关闭设置不改变常驻状态。

- ClipboardReadError：empty / files / changed / invalidImage；快捷键对前三者静默，手动操作可解释；不记录内容。
- ImageContent：经过完整性和像素验证的 PNG Data；单张、最多 256 MiB 输入及 100 MiPixel，首帧转换保持显示方向及 alpha。
- SavedImage：桌面 URL，「图片 yyyy-MM-dd HH.mm.ss.png」；同秒重复/并发用序号，不覆盖文件、目录或符号链接。

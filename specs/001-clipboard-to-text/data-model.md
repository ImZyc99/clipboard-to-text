# 数据模型

- TextInput：原始 String；必须至少含一个非空白字符，正文不标准化。
- FileName：首个非空行，首尾空白移除；非法路径符号替换、控制字符删除、前导点移除；最多 60 个 Character / 180 UTF-8 字节；空值回退「未命名」。
- SavedText：URL，扩展名 .txt；名称冲突依次加空格和 2、3…；不保存历史。
- SaveError：emptyText / IO 错误；向用户提供中文提示，不包含正文。
- 状态：闲置 → 用户点击 → 读剪贴板 → 验证 → 写临时文件 → 不覆盖发布 → Finder 选中；失败清理临时文件并提示。
# 菜单栏状态
AppDelegate 持有 statusItem 与可选 settingsWindow；菜单打开时获取 extensionEnabled。两者仅内存状态，无新增持久化或剪贴板读取。生命周期为启动→菜单栏常驻→显式打开/关闭设置→退出；关闭设置不改变常驻状态。

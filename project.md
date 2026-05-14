# 项目主要流程梳理

本项目是一个基于 Python 的游戏自动化工具。整体由 `gui_main.py` 提供图形界面，由 `qiang_huan.py` 和 `zhuxian_main.py` 执行两类自动化任务，底层依赖 `utils.py` 完成截图、OpenCV 模板匹配、点击和通用异常处理。

## 模块职责

| 模块/目录 | 主要职责 |
| --- | --- |
| `gui_main.py` | PyQt5 GUI 入口；读取/保存配置；启动、暂停任务线程；刷新截图预览；输出运行日志 |
| `qiang_huan.py` | “抢环/救援”自动化主流程 |
| `zhuxian_main.py` | “精英主线”自动化主流程 |
| `utils.py` | 资源路径适配、区域截图、模板匹配、通用弹窗处理、技能选择、体力不足判断 |
| `picture/` | 通用按钮、异常弹窗、技能、体力不足等图片模板 |
| `zhuxian_picture/` | 精英主线模式专用图片模板 |
| `config.ini` | GUI 参数持久化，包括运行时间、运行次数、任务耗时、截图识别区域 |

## 总体运行流程

```mermaid
flowchart TD
    A["启动 gui_main.py"] --> B["初始化 PyQt5 界面"]
    B --> C["读取 config.ini"]
    C --> D["用户设置运行参数和识别区域"]
    D --> E{"用户操作"}
    E -- "刷新截图" --> F["utils.jietu_with_save 截取指定区域"]
    F --> G["GUI 预览截图"]
    E -- "抢环" --> H["创建 ScriptThread，mode=ring"]
    E -- "精英" --> I["创建 ScriptThread，mode=elite"]
    E -- "暂停" --> J["设置 qianghuan_STOP 和 zhuxian_STOP 为 True"]
    H --> K["调用 qiang_huan.main"]
    I --> L["调用 zhuxian_main.main"]
    K --> M["任务结束后发送 task_finished"]
    L --> M
    M --> N["GUI 恢复按钮状态"]
```

## GUI 调度流程

`ImageDisplayApp` 负责界面和用户交互。用户点击“抢环”或“精英”后，GUI 会收集运行时间、运行次数、识别区域等参数，创建 `ScriptThread`，并在子线程中调用对应业务模块，避免阻塞界面。

```mermaid
sequenceDiagram
    participant U as 用户
    participant GUI as gui_main.ImageDisplayApp
    participant T as ScriptThread
    participant R as qiang_huan 和 zhuxian_main

    U->>GUI: 点击抢环或精英
    GUI->>GUI: set_running_state(True)
    GUI->>T: 创建线程并传入参数
    T->>R: 调用 main(...)
    R-->>T: 循环结束或收到暂停标记
    T-->>GUI: task_finished 信号
    GUI->>GUI: set_running_state(False)
```

## 抢环流程

`qiang_huan.main(limit_hours, region, limit_cishu)` 使用 `state` 管理流程：

- `state = 0`：未入队，查找并点击聊天按钮。
- `state = 1`：进入聊天后，查找并点击招募按钮。
- `state = 2`：查找所有抢环按钮并连续点击。
- `state = 3`：已入队或已开局，尝试选择技能。

```mermaid
flowchart TD
    A["进入 qiang_huan.main"] --> B["初始化次数、开始时间、state=3"]
    B --> C{"未暂停且未超过时间或次数限制"}
    C -- "否" --> Z["退出抢环流程"]
    C -- "是" --> D["截取识别区域截图"]
    D --> E["utils.utils 处理授权、返回、断网、战斗结束等通用状态"]
    E --> F{"state < 3"}
    F -- "是" --> G["识别是否已入队或已开局"]
    G -- "识别成功" --> H["state=3"]
    F -- "否" --> I["utils.choose_ji_neng 选择技能"]
    I -- "已处理技能" --> C
    G --> J["识别是否无人或未入队"]
    H --> J
    J -- "无人" --> K["state=0"]
    K --> L{"state"}
    J -- "未命中" --> L
    L -- "0" --> M["识别并点击聊天按钮，state=1"]
    L -- "1" --> N["识别并点击招募按钮，state=2"]
    L -- "2" --> O["识别全部抢环按钮并双击"]
    O --> P["判断体力不足"]
    P -- "是" --> Z
    P -- "否" --> Q["每抢 100 次休息 10 秒"]
    L -- "3" --> R["重置抢环计数"]
    M --> C
    N --> C
    Q --> C
    R --> C
```

## 精英主线流程

`zhuxian_main.main(limit_hours, region, limit_cishu, maximum_time_one_round)` 通过 `state` 管理自动开局、局内处理和超时退出：

- `state = 0`：在关卡页面，查找并点击开始按钮。
- `state = 1`：已进入局内，持续处理技能选择、返回按钮和通用异常；如果单局超过 `maximum_time_one_round`，点击暂停。
- `state = 2`：暂停菜单出现后，点击退出按钮并回到 `state = 0`。

```mermaid
flowchart TD
    A["进入 zhuxian_main.main"] --> B["初始化次数、开始时间、state=0"]
    B --> C{"未暂停且未超过时间或次数限制"}
    C -- "否" --> Z["退出精英流程"]
    C -- "是" --> D["截取识别区域截图"]
    D --> E["utils.utils 处理通用弹窗、返回和结算"]
    E --> F{"state < 1"}
    F -- "是" --> G["识别是否已经进入游戏"]
    G -- "成功" --> H["state=1，并记录单局开始时间"]
    F -- "否" --> I["utils.choose_ji_neng 选择技能"]
    I -- "已处理技能" --> C
    H --> J{"state"}
    G --> J
    J -- "0" --> K["识别并点击开始按钮"]
    K --> L["记录单局开始时间，state=1"]
    K --> M["判断体力不足"]
    M -- "是" --> Z
    M -- "否" --> C
    J -- "1" --> N["识别开始按钮是否重新出现"]
    N -- "出现" --> O["state=0"]
    N -- "未出现" --> P{"单局是否超时"}
    P -- "否" --> C
    P -- "是" --> Q["识别并点击暂停按钮"]
    Q --> R["识别退出按钮，state=2"]
    J -- "2" --> S["识别并点击退出按钮"]
    S --> T["state=0"]
    O --> C
    R --> C
    T --> C
```

## 通用工具流程

`utils.py` 是两个业务流程的公共底座：

```mermaid
flowchart TD
    A["业务模块传入截图"] --> B["utils.utils"]
    B --> C["识别拒绝授权并点击"]
    B --> D["识别返回按钮并点击"]
    D --> E["全局 cishu 加 1"]
    B --> F["识别回退按钮并点击"]
    B --> G["识别断网、重连、战斗结束并点击"]
    A --> H["utils.choose_ji_neng"]
    H --> I["优先识别已激活技能"]
    H --> J["遍历技能模板目录并点击匹配技能"]
    A --> K["utils.is_end_state"]
    K --> L["遍历体力不足模板目录"]
    L --> M{"是否匹配"}
    M -- "是" --> N["返回 True，业务流程退出"]
    M -- "否" --> O["返回 False，继续循环"]
```

## 关键退出条件

两个主业务循环都会在以下条件下退出：

1. GUI 点击“暂停”，设置对应全局停止标记。
2. 运行时间超过 `limit_hours`。
3. 完成次数 `utils.cishu` 达到 `limit_cishu`。
4. 识别到体力不足状态。
5. 精英主线单局超时后尝试暂停并退出当前局。

## 数据与资源流向

```mermaid
flowchart LR
    A["config.ini"] --> B["gui_main.py 读取参数"]
    B --> C["ScriptThread 参数字典"]
    C --> D["qiang_huan.py 和 zhuxian_main.py"]
    E["picture 与 zhuxian_picture"] --> F["utils.resource_path"]
    F --> G["OpenCV 模板匹配"]
    G --> H["pyautogui.click 执行点击"]
    D --> I["print 日志"]
    I --> J["GUI 重定向到右侧日志框"]
```

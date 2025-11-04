function love.conf(t)
    t.Identity = 'seve'
    --保存目录的名称（字符串）的名称
    t.appendidentity = false
    --在保存目录（boolean）之前，在源目录中搜索文件
    t.version = '11.3' -- l?ve版本此游戏是为（字符串）制作的
    t.console = false
    --附加控制台（布尔值，仅限窗口）
    t.accelerometerjoystick = true
    --启用iOS加速度计和Android的加速度计，将其暴露为操纵杆（布尔）
    t.externalStorage = true
    -- tum tum ture保存文件（并从保存目录中读取）在Android（boolean）上的外部存储中
    t.gammacorrect = false
    --启用伽马校正渲染，在系统支持时（布尔值）
    t.audio.mic = false
    --请求并在Android（Boolean）中使用麦克风功能
    t.audio.mixwithsystem = true
    --打开爱情时保持背景音乐播放（仅布尔，iOS和Android）
    t.window.title = 'untitled'
    -- 窗口标题（字符串）
    t.window.icon = nil         -- 用作窗口图标的图像的文件路径（字符串）

    t.window.width = 400        -- 窗口宽度（数字）
    t.window.height = 400       -- 窗口高度（数字）
    t.window.borderless = false -- 从窗口中删除所有边框视觉效果（布尔值）
    t.window.resizable = false  -- 让窗口可由用户调整大小（布尔值）
    t.window.minwidth = 100
    -- 窗口可调整大小时的最小窗口宽度（数字）
    t.window.minheight = 100
    -- 窗口可调整大小时的最小窗口高度（数字）
    t.window.fullscreen = false         -- 启用全屏（布尔值）
    t.window.fullscreentype = 'desktop' -- 在“桌面”全屏或“独占”全屏模式之间选择（字符串）
    t.window.vsync = 0                  -- 垂直同步模式（数字）
    t.window.msaa = 0                   -- 用于多重采样抗锯齿的采样数（number）
    t.window.depth = nil                -- 深度缓冲区中每个样本的位数
    t.window.stencil = nil              -- 模板缓冲区中每个样本的位数
    t.window.display = 1                -- 显示窗口的监视器索引（数字）
    t.window.highdpi = false            -- 在 Retina 显示屏上为窗口启用高 dpi 模式（布尔值）
    t.window.usedpiscale = true         -- 当 highdpi 也设置为 true 时启用自动 DPI 缩放（布尔值）
    t.window.x = nil                    -- 窗口在指定显示中的位置的 x 坐标（数字）
    t.window.y = nil                    -- 指定显示中窗口位置的y坐标（数字）
    t.window.resizable = false          --锁定屏幕

    t.modules.audio = true
    --启用音频模块（布尔值）
    t.modules.data = true
    --启用数据模块（boolean）
    t.modules.event = true
    --启用事件模块（布尔值）
    t.modules.font = true
    --启用字体模块（boolean）
    t.modules.graphics = true
    --启用图形模块（boolean）
    t.modules.image = true
    --启用图像模块（布尔值）
    t.modules.joystick = true
    --启用操纵杆模块（布尔值）
    t.modules.keyboard = true
    --启用键盘模块（布尔值）
    t.modules.math = true
    --启用数学模块（布尔值）
    t.modules.mouse = true
    --启用鼠标模块（布尔值）
    t.modules.physics = true
    --启用物理模块（布尔值）
    t.modules.sound = true
    --启用声音模块（布尔值）
    t.modules.system = true
    --启用系统模块（布尔值）
    t.modules.thread = true
    --启用线程模块（boolean）
    t.modules.timer = true
    --启用计时器模块（布尔值），禁用它将导致0 delta time in Love.update
    t.modules.touch = true
    --启用触摸模块（布尔值）
    t.modules.video = true
    --启用视频模块（布尔值）
    t.modules.window = true
    --启用窗口模块（布尔值）
    --

    --[[
if t.getOS()=="Android" then
  t.window.fullscreen = true

    t.window.width = 400 -- 窗口宽度（数字）
    t.window.height = 800 -- 窗口高度（数字）
    t.window.borderless = false -- 从窗口中删除所有边框视觉效果（布尔值）
    t.window.resizable = true -- 让窗口可由用户调整大小（布尔值）
    t.window.minwidth = 400
    -- 窗口可调整大小时的最小窗口宽度（数字）
    t.window.minheight = 300
    elseif t.system.getOS()=="Windows" then
    t.window.width = 400 -- 窗口宽度（数字）
    t.window.height = 300 -- 窗口高度（数字）
    t.window.borderless = false -- 从窗口中删除所有边框视觉效果（布尔值）
    t.window.resizable = true -- 让窗口可由用户调整大小（布尔值）
    t.window.minwidth = 400
    -- 窗口可调整大小时的最小窗口宽度（数字）
    t.window.minheight = 300

    else
    end]]
end

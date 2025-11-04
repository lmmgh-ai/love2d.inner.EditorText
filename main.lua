local utf8 = require("utf8")
utf8.sub = function(str, start_pos, end_pos)
    local len = utf8.len(str)
    if not len then
        error("Invalid UTF-8 string")
    end

    start_pos = start_pos or 1
    end_pos = end_pos or len

    -- 处理负数索引
    if start_pos < 0 then
        start_pos = len + start_pos + 1
    end
    if end_pos < 0 then
        end_pos = len + end_pos + 1
    end

    -- 边界检查
    start_pos = math.max(1, math.min(start_pos, len + 1))
    end_pos = math.max(0, math.min(end_pos, len))

    if start_pos > end_pos then
        return ""
    end

    local start_byte = utf8.offset(str, start_pos)
    local end_byte = utf8.offset(str, end_pos + 1)

    if not start_byte then
        return ""
    end

    if not end_byte then
        return string.sub(str, start_byte)
    else
        return string.sub(str, start_byte, end_byte - 1)
    end
end


--加载字体
local path = "YeZiGongChangTangYingHei-2.ttf"
--local font = love.graphics.newFont(path)
--love.graphics.setFont(font)
---print(font:getWidth(" "))
--print(font:getWidth("a"))
--print(font:getWidth("汉"))
--[[
local font1 = love.graphics.newFont()
print(font1:getWidth(" "))
print(font1:getWidth("a"))
print(font1:getWidth("汉"))
]]
-- 纯文本编辑器类
TextEditor = {}
TextEditor.__index = TextEditor

function TextEditor:new()
    local editor = {
        -- 文本内容（按行存储）
        lines           = { "" },
        -- 光标位置
        cursorX         = 1,
        cursorY         = 1,
        -- 选择范围
        selectStartX    = nil,
        selectStartY    = nil,
        selectEndX      = nil,
        selectEndY      = nil,
        -- 视图相关
        scrollX         = 0,
        scrollY         = 0,
        viewWidth       = 800,
        viewHeight      = 600,
        lineHeight      = 16,
        charWidth       = 8,
        -- 功能开关
        autoWrap        = false, -- 自动换行
        showLineNumbers = true,  -- 显示行号
        autoIndent      = true,  -- 自动缩进
        -- 字体设置
        font            = love.graphics.newFont(path, 14),
        -- 鼠标状态
        mousePressed    = false,
        -- 行号栏宽度
        lineNumberWidth = 40,
        -- 拖拽选择时的定时器
        dragTimer       = 0,
        dragInterval    = 0.1,
        cursorColor     = { 0, 0, 1, 1 }, -- 光标颜色
        cursorBlinkTime = 0,              -- 光标闪烁计时器
    }

    setmetatable(editor, TextEditor)
    editor.lineHeight = editor.font:getHeight()
    editor.charWidth  = editor.font:getWidth("M")

    return editor
end

-- 获取指定行的字符数量（考虑UTF-8）
function TextEditor:getLineCharCount(lineNum)
    if lineNum > #self.lines or lineNum < 1 then
        return 0
    end
    return utf8.len(self.lines[lineNum]) or 0
end

-- 获取指定位置的字符宽度（用于处理中文等多字节字符）
function TextEditor:getCharWidth(char)
    return self.font:getWidth(char)
end

-- 将屏幕坐标转换为文本坐标
--鼠标选中
function TextEditor:screenToTextCoord(screenX, screenY)
    local x, y = screenX, screenY

    -- 考虑滚动偏移
    x = x + self.scrollX
    y = y + self.scrollY

    -- 计算行号
    local lineNum = math.floor(y / self.lineHeight) + 1
    lineNum = math.max(1, math.min(lineNum, #self.lines))
    -- print(1, ":", x)
    -- 如果显示行号，需要减去行号栏宽度
    if self.showLineNumbers then
        x = x - self.lineNumberWidth
    end
    --print(2, ":", x)
    -- 计算列位置
    local line = self.lines[lineNum] or ""
    local charPos = 1
    --print(3, line)
    if line ~= "" then
        local currentX = 0
        local i = 1

        -- 逐字符计算位置，正确处理UTF-8字符
        while i <= #line do
            local byte = string.byte(line, i)
            local charByteCount = 1

            -- 判断UTF-8字符长度
            if byte >= 0xF0 then
                charByteCount = 4
            elseif byte >= 0xE0 then
                charByteCount = 3
            elseif byte >= 0xC0 then
                charByteCount = 2
            end

            local char = string.sub(line, i, i + charByteCount - 1)
            local charWidth = self:getCharWidth(char)
            --  print(char, charWidth)
            -- 如果当前位置已经超过鼠标点击位置，则返回上一个位置

            if currentX - charWidth / 2 > x then --前半
                -- print("31", currentX + charWidth / 2, x)
                --  print(32, i, utf8.offset(line, 1, i))
                --  charPos = utf8.offset(line, 1, i) or (i + charByteCount)
                charPos = charPos - 1
                break
            elseif currentX > x then
                charPos = charPos - 1
            elseif currentX >= x then --前半
            end

            currentX = currentX + charWidth
            charPos = charPos + 1
            i = i + charByteCount
            --print(31, currentX)
            -- 防止无限循环
            if i > #line + 1 then
                break
            end
        end
    end
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(line)
    --print(4, textWidth)
    --print(5, charPos, lineNum)
    return charPos, lineNum
end

-- 获取可视区域内的行范围
function TextEditor:getVisibleLines()
    local startLine = math.floor(self.scrollY / self.lineHeight) + 1
    local endLine = math.floor((self.scrollY + self.viewHeight) / self.lineHeight) + 1
    startLine = math.max(1, startLine)
    endLine = math.min(#self.lines, endLine)
    return startLine, endLine
end

-- 绘制编辑器
function TextEditor:draw()
    love.graphics.setFont(self.font)

    -- 绘制背景
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.viewHeight)

    -- 获取可见行范围
    local startLine, endLine = self:getVisibleLines()

    -- 绘制选中区域
    love.graphics.setColor(0.7, 0.8, 1)
    self:drawSelection(startLine, endLine)

    -- 绘制文本和行号
    love.graphics.setColor(0, 0, 0)

    for i = startLine, endLine do
        local y = (i - 1) * self.lineHeight - self.scrollY

        -- 绘制行号
        if self.showLineNumbers then
            --love.graphics.print(tostring(i), 5, y)
            love.graphics.printf(tostring(i), 5, y, self.lineNumberWidth * 0.6, "right")
        end

        -- 绘制文本
        local textX = self.showLineNumbers and self.lineNumberWidth or 0
        textX = textX - self.scrollX
        love.graphics.print(self.lines[i], textX, y)
    end

    -- 绘制光标
    if self.cursorBlinkTime % 1 < 0.5 then
        self:drawCursor()
    end
end

-- 绘制选中区域
function TextEditor:drawSelection(startLine, endLine)
    if not self:hasSelection() then return end

    local startX, startY, endX, endY = self:getNormalizedSelection()

    for i = startLine, endLine do
        local y = (i - 1) * self.lineHeight - self.scrollY

        if i >= startY and i <= endY then
            local line = self.lines[i]
            local textX = self.showLineNumbers and self.lineNumberWidth or 0
            textX = textX - self.scrollX

            if startY == endY then
                -- 单行选择
                local startPixel = self:getTextPositionInPixels(line, startX)
                local endPixel = self:getTextPositionInPixels(line, endX)
                love.graphics.rectangle("fill", textX + startPixel, y, endPixel - startPixel, self.lineHeight)
            elseif i == startY then
                -- 选择起始行
                local startPixel = self:getTextPositionInPixels(line, startX)
                local linePixelWidth = self:getTextPositionInPixels(line, self:getLineCharCount(i) + 1)
                love.graphics.rectangle("fill", textX + startPixel, y, linePixelWidth - startPixel, self.lineHeight)
            elseif i == endY then
                -- 选择结束行
                local endPixel = self:getTextPositionInPixels(line, endX)
                love.graphics.rectangle("fill", textX, y, endPixel, self.lineHeight)
            else
                -- 中间完整行
                local linePixelWidth = self:getTextPositionInPixels(line, self:getLineCharCount(i) + 1)
                love.graphics.rectangle("fill", textX, y, linePixelWidth, self.lineHeight)
            end
        end
    end
end

-- 获取文本位置对应的像素位置（正确处理UTF-8）
function TextEditor:getTextPositionInPixels(text, charPos)
    if charPos <= 1 then return 0 end

    local pixelPos = 0
    local currentChar = 1
    local i = 1

    while i <= #text and currentChar < charPos do
        local byte = string.byte(text, i)
        local charByteCount = 1

        if byte >= 0xF0 then
            charByteCount = 4
        elseif byte >= 0xE0 then
            charByteCount = 3
        elseif byte >= 0xC0 then
            charByteCount = 2
        end

        local char = string.sub(text, i, i + charByteCount - 1)
        pixelPos = pixelPos + self:getCharWidth(char)
        currentChar = currentChar + 1
        i = i + charByteCount
    end

    return pixelPos
end

-- 绘制光标
function TextEditor:drawCursor()
    -- 只在没有选择时绘制光标
    if self:hasSelection() then return end

    local cursorPixelX = self:getTextPositionInPixels(self.lines[self.cursorY], self.cursorX)
    local cursorScreenX = cursorPixelX
    if self.showLineNumbers then
        cursorScreenX = cursorScreenX + self.lineNumberWidth
    end
    cursorScreenX = cursorScreenX - self.scrollX

    local cursorY = (self.cursorY - 1) * self.lineHeight - self.scrollY

    -- 确保光标在可视区域内才绘制
    if cursorScreenX >= (self.showLineNumbers and self.lineNumberWidth or 0) and
        cursorScreenX <= self.viewWidth and
        cursorY >= 0 and cursorY <= self.viewHeight then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.line(cursorScreenX, cursorY, cursorScreenX, cursorY + self.lineHeight)
    end
end

-- 检查是否有文本选择
function TextEditor:hasSelection()
    return self.selectStartX ~= nil and self.selectEndX ~= nil
end

-- 获取标准化的选择范围（确保start <= end）
function TextEditor:getNormalizedSelection()
    if not self:hasSelection() then return 0, 0, 0, 0 end

    local startX, startY, endX, endY = self.selectStartX, self.selectStartY, self.selectEndX, self.selectEndY

    -- 标准化选择范围
    if startY > endY or (startY == endY and startX > endX) then
        startX, startY, endX, endY = endX, endY, startX, startY
    end

    return startX, startY, endX, endY
end

-- 获取选择的文本
function TextEditor:getSelectedText()
    if not self:hasSelection() then return "" end

    local startX, startY, endX, endY = self:getNormalizedSelection()
    local selectedText = ""

    if startY == endY then
        -- 同一行
        local line = self.lines[startY]
        selectedText = string.sub(line, utf8.offset(line, startX), utf8.offset(line, endX) - 1)
    else
        -- 多行选择
        local firstLine = self.lines[startY]
        selectedText = string.sub(firstLine, utf8.offset(firstLine, startX)) .. "\n"

        for i = startY + 1, endY - 1 do
            selectedText = selectedText .. self.lines[i] .. "\n"
        end

        local lastLine = self.lines[endY]
        selectedText = selectedText .. string.sub(lastLine, 1, utf8.offset(lastLine, endX) - 1)
    end

    return selectedText
end

-- 删除选择的文本
function TextEditor:deleteSelection()
    if not self:hasSelection() then return false end

    local startX, startY, endX, endY = self:getNormalizedSelection()

    if startY == endY then
        -- 同一行删除
        local line         = self.lines[startY]
        local startByte    = utf8.offset(line, startX)
        local endByte      = utf8.offset(line, endX)
        self.lines[startY] = string.sub(line, 1, startByte - 1) .. string.sub(line, endByte)
        self.cursorX       = startX
        self.cursorY       = startY
    else
        -- 跨行删除
        local firstLine = self.lines[startY]
        local lastLine = self.lines[endY]

        -- 合并首尾行
        local startByte = utf8.offset(firstLine, startX)
        local endByte = utf8.offset(lastLine, endX)
        local mergedLine = string.sub(firstLine, 1, startByte - 1) .. string.sub(lastLine, endByte)

        -- 移除中间的行
        for i = endY, startY + 1, -1 do
            table.remove(self.lines, i)
        end

        self.lines[startY] = mergedLine
        self.cursorX       = startX
        self.cursorY       = startY
    end

    -- 清除选择状态
    self:clearSelection()
    return true
end

-- 清除选择状态
function TextEditor:clearSelection()
    self.selectStartX = nil
    self.selectStartY = nil
    self.selectEndX   = nil
    self.selectEndY   = nil
end

-- 插入文本
function TextEditor:insertText(text)
    -- 如果有选择则先删除
    if self:deleteSelection() then
        -- 已经删除了选择的内容
    end

    -- 处理换行符
    local linesToInsert = {}
    for line in string.gmatch(text, "([^\r\n]*)[\r\n]?") do
        if line ~= nil then
            table.insert(linesToInsert, line)
        end
    end

    -- 如果只有一行，简单插入
    --if #linesToInsert == 1 then
    local line               = self.lines[self.cursorY]
    local cursorByte         = utf8.offset(line, self.cursorX) or (#line + 1)
    self.lines[self.cursorY] = string.sub(line, 1, cursorByte - 1) ..
        linesToInsert[1] .. string.sub(line, cursorByte)
    self.cursorX             = self.cursorX + utf8.len(linesToInsert[1] or "")
    --end
    --[[
        end
    else
        -- 多行插入
        local currentLine        = self.lines[self.cursorY]
        local cursorByte         = utf8.offset(currentLine, self.cursorX) or (#currentLine + 1)
        local beforeCursor       = string.sub(currentLine, 1, cursorByte - 1)
        local afterCursor        = string.sub(currentLine, cursorByte)

        -- 更新当前行
        self.lines[self.cursorY] = beforeCursor .. linesToInsert[1]

        -- 插入新行
        for i = 2, #linesToInsert do
            table.insert(self.lines, self.cursorY + i - 1, linesToInsert[i])
        end

        -- 更新最后一行
        local lastInsertedLineIndex       = self.cursorY + #linesToInsert - 1
        self.lines[lastInsertedLineIndex] = self.lines[lastInsertedLineIndex] .. afterCursor

        -- 更新光标位置
        self.cursorY                      = lastInsertedLineIndex
        self.cursorX                      = utf8.len(linesToInsert[#linesToInsert] or "") + 1
    end
]]
    self:scrollToCursor()
end

-- 删除字符
function TextEditor:deleteChar(direction)
    -- 如果有选择则删除选择内容
    if self:hasSelection() then
        self:deleteSelection()
        return
    end

    local line = self.lines[self.cursorY]
    local lineLength = self:getLineCharCount(self.cursorY)

    if direction == "left" then
        -- 向左删除
        if self.cursorX > 1 then
            -- 同行删除
            local prevCharByte       = utf8.offset(line, self.cursorX - 1)
            local currentCharByte    = utf8.offset(line, self.cursorX)
            self.lines[self.cursorY] = string.sub(line, 1, prevCharByte - 1) .. string.sub(line, currentCharByte)
            self.cursorX             = self.cursorX - 1
        elseif self.cursorY > 1 then
            -- 合并到上一行
            local prevLine = self.lines[self.cursorY - 1]
            local prevLineLength = self:getLineCharCount(self.cursorY - 1)
            self.lines[self.cursorY - 1] = prevLine .. line
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
            self.cursorX = prevLineLength + 1
        end
    elseif direction == "right" then
        -- 向右删除
        if self.cursorX <= lineLength then
            -- 同行删除
            local currentCharByte    = utf8.offset(line, self.cursorX)
            local nextCharByte       = utf8.offset(line, self.cursorX + 1)
            self.lines[self.cursorY] = string.sub(line, 1, currentCharByte - 1) .. string.sub(line, nextCharByte)
        elseif self.cursorY < #self.lines then
            -- 合并下一行
            local nextLine           = self.lines[self.cursorY + 1]
            self.lines[self.cursorY] = line .. nextLine
            table.remove(self.lines, self.cursorY + 1)
        end
    end

    self:scrollToCursor()
end

-- 移动光标
function TextEditor:moveCursor(direction, select)
    local oldX, oldY = self.cursorX, self.cursorY

    if select and not self:hasSelection() then
        self.selectStartX = self.cursorX
        self.selectStartY = self.cursorY
    end

    if direction == "left" then
        if self.cursorX > 1 then
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = self:getLineCharCount(self.cursorY) + 1
        end
    elseif direction == "right" then
        local lineLength = self:getLineCharCount(self.cursorY)
        if self.cursorX <= lineLength then
            self.cursorX = self.cursorX + 1
        elseif self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
        end
    elseif direction == "up" then
        if self.cursorY > 1 then
            self.cursorY     = self.cursorY - 1
            local lineLength = self:getLineCharCount(self.cursorY)
            self.cursorX     = math.min(self.cursorX, lineLength + 1)
        end
    elseif direction == "down" then
        if self.cursorY < #self.lines then
            self.cursorY     = self.cursorY + 1
            local lineLength = self:getLineCharCount(self.cursorY)
            self.cursorX     = math.min(self.cursorX, lineLength + 1)
        end
    elseif direction == "home" then
        self.cursorX = 1
    elseif direction == "end" then
        self.cursorX = self:getLineCharCount(self.cursorY) + 1
    end

    if select then
        self.selectEndX = self.cursorX
        self.selectEndY = self.cursorY
    elseif self:hasSelection() then
        self:clearSelection()
    end

    self:scrollToCursor()
end

-- 滚动到光标位置
function TextEditor:scrollToCursor()
    local cursorPixelX = self:getTextPositionInPixels(self.lines[self.cursorY], self.cursorX)
    local cursorScreenX = cursorPixelX
    --print(cursorPixelX)
    if self.showLineNumbers then
        cursorScreenX = cursorScreenX + self.lineNumberWidth
    end

    local cursorY = (self.cursorY - 1) * self.lineHeight

    -- 水平滚动
    if cursorScreenX - self.scrollX < 0 then
        self.scrollX = cursorScreenX
    elseif cursorScreenX - self.scrollX > self.viewWidth - 20 then
        self.scrollX = cursorScreenX - self.viewWidth + 20
    end

    -- 垂直滚动
    if cursorY - self.scrollY < 0 then
        self.scrollY = cursorY
    elseif cursorY - self.scrollY > self.viewHeight - self.lineHeight then
        self.scrollY = cursorY - self.viewHeight + self.lineHeight
    end

    -- 确保滚动不会超出边界
    self.scrollX = math.max(0, self.scrollX)
    self.scrollY = math.max(0, self.scrollY)
end

-- 处理按键输入
function TextEditor:keypressed(key)
    -- 处理组合键
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if ctrl then
        if key == "a" then
            -- 全选
            self:selectAll()
        elseif key == "c" then
            -- 复制
            self:copy()
        elseif key == "v" then
            -- 粘贴
            self:paste()
        elseif key == "x" then
            -- 剪切
            self:cut()
        elseif key == "z" then
            -- 撤销（简化实现）
        elseif key == "y" then
            -- 重做（简化实现）
        end
        return
    end

    if key == "left" then
        self:moveCursor("left", shift)
    elseif key == "right" then
        self:moveCursor("right", shift)
    elseif key == "up" then
        self:moveCursor("up", shift)
    elseif key == "down" then
        self:moveCursor("down", shift)
    elseif key == "home" then
        self:moveCursor("home", shift)
    elseif key == "end" then
        self:moveCursor("end", shift)
    elseif key == "backspace" then
        self:deleteChar("left")
    elseif key == "delete" then
        self:deleteChar("right")
    elseif key == "return" or key == "kpenter" then
        self:insertNewLine()
    elseif key == "tab" then
        self:insertText("    ") -- 插入4个空格作为制表符
    end
end

-- 处理文本输入
function TextEditor:textinput(text)
    self:insertText(text)
end

-- 插入新行（带自动缩进）
function TextEditor:insertNewLine()
    -- 如果有选择则先删除
    if self:deleteSelection() then
        -- 已经删除了选择的内容
    end

    local currentLine = self.lines[self.cursorY]
    local beforeCursor = string.sub(currentLine, 1, utf8.offset(currentLine, self.cursorX) - 1)
    local afterCursor = string.sub(currentLine, utf8.offset(currentLine, self.cursorX))

    -- 设置新行的缩进
    local indent = ""
    if self.autoIndent then
        -- 计算当前行的前导空格数
        local leadingSpaces = string.match(beforeCursor, "^%s*")
        indent = leadingSpaces or ""

        -- 如果光标前有{符号，增加缩进
        if string.find(beforeCursor, "{%s*$") then
            indent = indent .. "    "
        end
    end

    -- 更新当前行
    self.lines[self.cursorY] = beforeCursor

    -- 插入新行
    table.insert(self.lines, self.cursorY + 1, indent .. afterCursor)

    -- 更新光标位置
    self.cursorY = self.cursorY + 1
    self.cursorX = utf8.len(indent) + 1

    self:clearSelection()
    self:scrollToCursor()
end

-- 全选
function TextEditor:selectAll()
    self.selectStartX = 1
    self.selectStartY = 1
    self.selectEndX   = self:getLineCharCount(#self.lines) + 1
    self.selectEndY   = #self.lines
    -- 将光标移到末尾
    self.cursorX      = self.selectEndX
    self.cursorY      = self.selectEndY
end

-- 复制
function TextEditor:copy()
    local selectedText = self:getSelectedText()
    if selectedText ~= "" then
        love.system.setClipboardText(selectedText)
    end
end

-- 剪切
function TextEditor:cut()
    local selectedText = self:getSelectedText()
    if selectedText ~= "" then
        love.system.setClipboardText(selectedText)
        self:deleteSelection()
    end
end

-- 粘贴
function TextEditor:paste()
    local clipboardText = love.system.getClipboardText()
    if clipboardText then
        self:insertText(clipboardText)
    end
end

-- 处理鼠标按下
function TextEditor:mousepressed(x, y, button)
    if button == 1 then -- 左键
        self.mousePressed  = true
        local textX, textY = self:screenToTextCoord(x, y)
        -- print(textX, textY)
        self.cursorX       = textX
        self.cursorY       = textY

        -- 处理Shift键的连续选择
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            if not self:hasSelection() then
                self.selectStartX = self.cursorX
                self.selectStartY = self.cursorY
            end
            self.selectEndX = self.cursorX
            self.selectEndY = self.cursorY
        else
            self.selectStartX = self.cursorX
            self.selectStartY = self.cursorY
            self.selectEndX   = self.cursorX
            self.selectEndY   = self.cursorY
        end
        --计算鼠标位置
        self:scrollToCursor()
    end
end

-- 处理鼠标释放
function TextEditor:mousereleased(x, y, button)
    if button == 1 then
        self.mousePressed = false
        -- 如果起始和结束位置相同，则清除选择
        if self.selectStartX == self.selectEndX and self.selectStartY == self.selectEndY then
            self:clearSelection()
        end
    end
end

-- 处理鼠标移动
function TextEditor:mousemoved(x, y, dx, dy)
    if self.mousePressed then
        local textX, textY = self:screenToTextCoord(x, y)
        self.cursorX       = textX
        self.cursorY       = textY
        self.selectEndX    = self.cursorX
        self.selectEndY    = self.cursorY
        self:scrollToCursor()
    end
end

-- 处理滚轮
function TextEditor:wheelmoved(x, y)
    self.scrollY = math.max(0, self.scrollY - y * 20)
end

-- 切换自动换行
function TextEditor:toggleAutoWrap()
    self.autoWrap = not self.autoWrap
end

-- 切换行号显示
function TextEditor:toggleLineNumbers()
    self.showLineNumbers = not self.showLineNumbers
end

-- 获取完整文本
function TextEditor:getText()
    return table.concat(self.lines, "\n")
end

-- 设置文本
function TextEditor:setText(text)
    self.lines = {}
    if text == "" then
        self.lines = { "" }
    else
        for line in string.gmatch(text, "([^\r\n]*)[\r\n]?") do
            table.insert(self.lines, line or "")
        end
    end
    self.cursorX = 1
    self.cursorY = 1
    self:clearSelection()
    self.scrollX = 0
    self.scrollY = 0
end

--循环
function TextEditor:update(dt)
    -- body
    self.cursorBlinkTime = self.cursorBlinkTime + dt --更新光标闪烁计时器
    self.dragTimer = self.dragTimer + dt             --拖拽时间
end

-- 主程序初始化
function love.load()
    love.window.setTitle(" 纯文本编辑器")
    --love.window.setMode(800, 600)

    -- 创建编辑器实例
    editor = TextEditor:new()

    -- 示例文本
    local sampleText = [[这是一个支持中文的文本编辑器示例。
它具有以下功能：
1. 支持中文字符显示和输入
2. 鼠标点击定位和拖拽选择
3. 增删改文本操作
4. 自动缩进功能
5. 可切换的自动换行
6. 可切换的行号显示
7. 正确处理UTF-8字符

你可以尝试：
- 输入中英文混合文本
- 使用鼠标选择文本
- 使用Ctrl+C/V/X进行复制粘贴剪切
- 使用方向键、Home、End键导航
- 按Tab键插入缩进
- 按F1切换自动换行
- 按F2切换行号显示

Because I didn't find a good textEditor on the internet when I was creating a gui library, I wrote one myself, which has the following functions. This is an example of a text editor supporting Chinese. It has the following functions:

1. Support Chinese character display and input.
2. Click the mouse to locate and drag to select.
3. Add, delete and modify text operations
4. Automatic indentation function
5. Switched word wrap
6. Switched line number display
7. Handle UTF-8 characters correctly

You can try: -Enter mixed Chinese and English text. -Use the mouse to select text. -use Ctrl+C/V/X to copy, paste and cut. -use the arrow keys, Home and End keys to navigate. -press Tab to insert indentation. -Press F1 to toggle word wrap. -Press F2 to switch the line number display
]]

    editor:setText(sampleText)
end

-- 绘制函数
function love.draw()
    editor:draw()

    -- 绘制状态信息
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(string.format(" 行:%d/%d 列:%d 自动换行:%s 行号:%s",
            editor.cursorY, #editor.lines, editor.cursorX,
            editor.autoWrap and "开" or "关",
            editor.showLineNumbers and "开" or "关"),
        10, editor.viewHeight - 30)
end

-- 更新函数
function love.update(dt)
    --editor.dragTimer = editor.dragTimer + dt
    editor:update(dt)
end

-- 键盘事件
function love.keypressed(key)
    if key == "f1" then
        editor:toggleAutoWrap()
    elseif key == "f2" then
        editor:toggleLineNumbers()
    else
        editor:keypressed(key)
    end
end

-- 文本输入事件
function love.textinput(text)
    editor:textinput(text)
end

-- 鼠标事件
function love.mousepressed(x, y, button)
    love.keyboard.setTextInput(true)
    editor:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    editor:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    editor:mousemoved(x, y, dx, dy)
end

-- 滚轮事件
function love.wheelmoved(x, y)
    editor:wheelmoved(x, y)
end

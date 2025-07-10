-- 清洁的共享脚注过滤器（避免重复编号）
local footnote_contents = {}  -- 存储脚注内容，键为内容，值为编号
local footnote_order = {}     -- 存储脚注出现的顺序
local footnote_counter = 0    -- 脚注计数器

function Pandoc(doc)
  local blocks = {}
  
  -- 第一遍：处理所有块，收集和去重脚注
  for i, block in ipairs(doc.blocks) do
    if block.t == "Para" or block.t == "Plain" then
      local new_inlines = {}
      for j, inline in ipairs(block.content) do
        if inline.t == "Note" then
          local content = pandoc.utils.stringify(inline.content)
          
          -- 检查是否已存在相同内容的脚注
          local footnote_id = footnote_contents[content]
          
          if not footnote_id then
            -- 新脚注，分配新编号
            footnote_counter = footnote_counter + 1
            footnote_id = footnote_counter
            footnote_contents[content] = footnote_id
            table.insert(footnote_order, {id = footnote_id, content = content})
          end
          
          -- 替换为上标编号
          table.insert(new_inlines, pandoc.Superscript({pandoc.Str(tostring(footnote_id))}))
        else
          table.insert(new_inlines, inline)
        end
      end
      
      if #new_inlines > 0 then
        block.content = new_inlines
      end
    end
    table.insert(blocks, block)
  end
  
  -- 添加去重后的脚注列表到文档末尾
  if #footnote_order > 0 then
    -- 添加分隔线
    table.insert(blocks, pandoc.HorizontalRule())
    
    -- 添加脚注标题
    table.insert(blocks, pandoc.Para({pandoc.Strong({pandoc.Str("脚注：")})}))
    
    -- 添加脚注列表（不包含手动编号，让有序列表自动编号）
    local footnote_items = {}
    for i, footnote in ipairs(footnote_order) do
      table.insert(footnote_items, {pandoc.Para({
        pandoc.Str(footnote.content)  -- 只包含内容，不包含编号
      })})
    end
    table.insert(blocks, pandoc.OrderedList(footnote_items))
  end
  
  return pandoc.Pandoc(blocks, doc.meta)
end


-- micromode -----------------------------------------------------------------

-- micromode.lua introduces Sciboo-style 'micro-modes' to SciTE.
-- For instance, if your C file begins like this:
-- // build@ gcc fred.c alice.o -o fred
-- then that will set the property command.build.* to 'gcc fred.c alice.o -o fred'.
--
-- General format is '<operation>@ <command> <args>'
-- build,compile and go are valid operations; otherwise, the name is assumed to
-- be a global Lua function that will handle this build operation
-- If the args end with a single '*', it will be replaced with $(FileNameExt)
-- (As an extension, if the command is a GNU-style compiler, then '- o $(FileName)'
-- is appended as well, so that 'build@ gcc *' will work as expected.)
-- If the command is a valid global Lua function, it will be used instead. So:
--  --go@ dofile *
-- will mean that a Lua script is to be run using SciTE Lua.

local compile_tool = {gcc=1,['g++']=2,gfortran=1,g95=1}

local propset = {}

function get_line(pane,lineno)
    if not pane then pane = editor end
    if not lineno then
        local line_pos = pane.CurrentPos
        lineno = pane:LineFromPosition(line_pos)-1
    end
    -- strip linefeeds (Windows is a special case as usual!)
    local endl = 2
    if pane.EOLMode == 0 then endl = 3 end
    local line = pane:GetLine(lineno)
    if not line then return nil end
    return string.sub(line,1,-endl)
end

local function check_micro_mode(f)
	if #propset > 0 then -- very important to keep clearing these guys out!
		for i,k in ipairs(propset) do
			props[k] = nil
		end
		propset = {}
	end
	local line = get_line(editor,0)
	if not line then return end
	local _,_,p,val = line:find('([a-z]+)@%s+(.+)')
	if _ then
        local custom_build, lua_function
        if p ~= 'build' and p ~= 'compile' and p ~= 'go' then
            custom_build = p
            p = 'build'
        end
		local prop = 'command.'..p..'.*'
		if val:sub(1,1) == '$' then -- might have been a property expansion!
			val = val:sub(3,-2)
			val = props[val]
		end
		if val == "" then return end
		local cmd = val:match('^(%S+)')
		if val:find('%*$') then
			val = val:sub(1,-2) .. '$(FileNameExt)'
            if compile_tool[cmd] then
                val = val .. ' -o $(FileName)'
            end
		end
		lua_function = cmd and _G[cmd]
        if not custom_build and not lua_function then
            props[prop] = val
        else
			local subsys
			-- a Lua function; use the 3 subsystem to evaluate it!
			if custom_build then
				props[prop] = custom_build..' '..val
				subsys = 'command.build.subsystem.*'
			else
				props[prop] = val
				subsys = 'command.go.subsystem.*'
			end
            props[subsys] = '3'
            table.insert(propset,subsys)
        end
        table.insert(propset,prop)
	end
end

local function buffer_switch(f)
	if not string.find(f, '[\\/]$') then
		check_micro_mode(f)
	end
end
function OnOpen(f)
	buffer_switch(f)
end
function OnSwitchFile(f)
	buffer_switch(f)
end
function OnSave()
	check_micro_mode()
end

function getWordAtCursor()
	local pos = editor.CurrentPos
	local start_pos = editor:WordStartPosition(pos, true)
	local end_pos = editor:WordEndPosition(pos, true)
	local word = editor:textrange(start_pos, end_pos)
	return word
end

function setFindText()
	--local word = getWordAtCursor() or ''
	--props['find.what'] = word
	--scite.SendEditor(SCI_SEARCHANCHOR)
	--scite.SendEditor(SCI_SETTARGETSTART, 0)
	--scite.SendEditor(SCI_SETTARGETEND, editor.Length)
	--scite.SendEditor(SCI_SEARCHINTARGET, word:len(), word)
	--scite.MenuCommand(IDM_FIND)
	--scite.MenuCommand(IDM_FINDNEXT)
end

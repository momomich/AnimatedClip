script_name = "倾斜遮罩动画效果"
script_description = "Animate the rotated rectangle vector clip."
script_author = "Momomich"
script_version = "1.0"
script_modified = "15th April 2022"

include("karaskel.lua")

local frame_dur = aegisub.video_size() and (aegisub.ms_from_frame(101)-aegisub.ms_from_frame(1)) / 100 or 41.71

function frames(starts, ends)
	local cur_start_time = starts
	local function next_frame()
		if cur_start_time >= ends then
			return nil
		end
		local return_start_time = cur_start_time
		local return_end_time = return_start_time + frame_dur <= ends and return_start_time + frame_dur or ends
		cur_start_time = return_end_time
		return return_start_time, return_end_time
	end
	return next_frame
end

function frame_generator(subs, sel, rotate)
	function clip_pos(leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y, step_x, step_y)
		leftbottom_x = leftbottom_x - step_x
		leftbottom_y = leftbottom_y + step_y
		rightbottom_x = rightbottom_x - step_x
		rightbottom_y = rightbottom_y + step_y
		return leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y
	end
	local meta, styles = karaskel.collect_head(subs)
	local add = 0
	for _, i in ipairs(sel) do
		local line = subs[i+add]
		karaskel.preproc_line(subs, meta, styles, line)
		local pos_s, _, pos_x, pos_y = string.find(line.text, "{[^}]*\\pos%(([^,%)]*),([^,%)]*)%).*}")
		local frame_count = math.ceil(line.duration / frame_dur)
		local step_x = line.height * math.sin(math.rad(rotate)) / (frame_count - 1)
		local step_y = line.height * math.cos(math.rad(rotate)) / (frame_count - 1)
		local lefttop_x = pos_x - line.width * 0.5 * math.cos(math.rad(rotate)) + line.height * math.sin(math.rad(rotate))
		local lefttop_y = pos_y - line.width * 0.5 * math.sin(math.rad(rotate)) - line.height * math.cos(math.rad(rotate))
		local righttop_x = pos_x + line.width * 0.5 * math.cos(math.rad(rotate)) + line.height * math.sin(math.rad(rotate))
		local righttop_y = pos_y + line.width * 0.5 * math.sin(math.rad(rotate)) - line.height * math.cos(math.rad(rotate))
		local leftbottom_x = lefttop_x
		local leftbottom_y = lefttop_y
		local rightbottom_x = righttop_x
		local rightbottom_y = righttop_y

		for s, e in frames(line.start_time, line.end_time) do
			local nline = table.copy(line)
			nline.start_time = s
			nline.end_time = e
			nline.text = (string.format("{\\frz%d\\clip(1 m %.3f %.3f l %.3f %.3f %.3f %.3f %.3f %.3f)}",
			-rotate, lefttop_x, lefttop_y, righttop_x, righttop_y, rightbottom_x, rightbottom_y, leftbottom_x, leftbottom_y)..nline.text)
			leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y = clip_pos(leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y, step_x, step_y)
			subs.insert(i+add, nline)
			add = add + 1
		end
		subs.delete(i+add)
		add = add - 1
	end
end

local config = {
	{
		class = "label",
		x = 0, y = 0, width = 5, height = 1,
		label = "本脚本用于制作旋转文本的卷帘门特效\n要求使用屏幕中下对齐方式，无字体类特效标签，无换行符\n"
	},
	{
		class = "label",
		x = 0, y = 1, width = 3, height = 1,
		label = "顺时针旋转角度:"
	},
	{
		class = "intedit", name = "rotate",
		x = 3, y = 1, width = 2, height = 1,
		value = 1
	},
	{
		class = "label",
		x = 0, y = 2, width = 5, height = 1,
		label = ""
	}
}

function GUI(subs, sel)
	aegisub.progress.title(script_name)
	aegisub.progress.set(0)
	local button, conf = aegisub.dialog.display(config,{"Go!", "Cancel"})
	if button == "Go!" then
		frame_generator(subs, sel, conf.rotate)
		aegisub.set_undo_point("\""..script_name.."\"")
	end
end

function test_null_frames(subs, sel)
	for i, si in ipairs(sel) do
		local sub = subs[si]
		if (math.ceil((sub.end_time - sub.start_time) / frame_dur) < 1) then
			return false
		end
	end
	return true
end

aegisub.register_macro(script_name, script_description, GUI, test_null_frames)

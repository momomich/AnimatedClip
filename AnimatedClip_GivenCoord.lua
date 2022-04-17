script_name = "自定义方形卷帘门特效"
script_description = "Animate the custom rectangle vector clip."
script_author = "Momomich"
script_version = "1.0"
script_modified = "17th April 2022"

include("karaskel.lua")

--frame duration
local frame_dur = aegisub.video_size() and (aegisub.ms_from_frame(101)-aegisub.ms_from_frame(1)) / 100 or 41.71

--frame by frame
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

--animate clip by frame
function frame_generator(subs, sel, lt_x, lt_y, rt_x, rt_y, rb_x, rb_y, lb_x, lb_y, dur)
	function clip_pos(leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y, step_lx, step_ly, step_rx, step_ry)
		--step_x and step_y calculated below
		leftbottom_x = leftbottom_x + step_lx
		leftbottom_y = leftbottom_y + step_ly
		rightbottom_x = rightbottom_x + step_rx
		rightbottom_y = rightbottom_y + step_ry
		return leftbottom_x, leftbottom_y, rightbottom_x, rightbottom_y
	end
	local meta, styles = karaskel.collect_head(subs)
	local add = 0
	--for each original line to be animated
	for _, i in ipairs(sel) do
		local line = subs[i+add]
		karaskel.preproc_line(subs, meta, styles, line)
		-- local pos_s, _, pos_x, pos_y = string.find(line.text, "{[^}]*\\pos%(([^,%)]*),([^,%)]*)%).*}")
		local frame_count = math.ceil(dur / frame_dur)
		local step_lx = (lb_x - lt_x) / (frame_count - 1)
		local step_ly = (lb_y - lt_y) / (frame_count - 1)
		local step_rx = (rb_x - rt_x) / (frame_count - 1)
		local step_ry = (rb_y - rt_y) / (frame_count - 1)
		--initialization
		local cur_lb_x = lt_x
		local cur_lb_y = lt_y
		local cur_rb_x = rt_x
		local cur_rb_y = rt_y
		--insert animated clipping line to subs by frame
		local nline = table.copy(line)
		for s, e in frames(line.start_time, line.start_time + dur) do
			nline.start_time = s
			nline.end_time = e
			nline.text = (string.format("{\\clip(1 m %d %d l %d %d %.3f %.3f %.3f %.3f)}",
			lt_x, lt_y, rt_x, rt_y, cur_rb_x, cur_rb_y, cur_lb_x, cur_lb_y)..line.text)
			cur_lb_x, cur_lb_y, cur_rb_x, cur_rb_y = clip_pos(cur_lb_x, cur_lb_y, cur_rb_x, cur_rb_y, step_lx, step_ly, step_rx, step_ry)
			subs.insert(i+add, nline)
			add = add + 1
		end
		--insert the non-animated part of line
		nline.start_time = line.start_time + dur
		nline.end_time = line.end_time
		nline.text = (string.format("{\\clip(1 m %.3f %.3f l %.3f %.3f %.3f %.3f %.3f %.3f)}",
		lt_x, lt_y, rt_x, rt_y, rb_x, rb_y, lb_x, lb_y)..line.text)
		subs.insert(i+add, nline)
		subs.delete(i+add+1)
	end
end

local config = {
	{
		class = "label",
		x = 0, y = 0, width = 4, height = 1,
		label = "本脚本用于制作自定义方形卷帘门特效\n请填写方形区域顶点坐标（整数）\n"
	},
	{
		class = "label",
		x = 2, y = 1, width = 1, height = 1,
		label = "横坐标:"
	},
	{
		class = "label",
		x = 3, y = 1, width = 1, height = 1,
		label = "纵坐标:"
	},
	{
		class = "label",
		x = 0, y = 2, width = 2, height = 1,
		label = "左上:"
	},
	{
		class = "label",
		x = 0, y = 3, width = 2, height = 1,
		label = "右上:"
	},
	{
		class = "label",
		x = 0, y = 4, width = 2, height = 1,
		label = "左下:"
	},
	{
		class = "label",
		x = 0, y = 5, width = 2, height = 1,
		label = "右下:"
	},
	{
		class = "intedit", name = "lt_x",
		x = 2, y = 2, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "rt_x",
		x = 2, y = 3, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "lb_x",
		x = 2, y = 4, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "rb_x",
		x = 2, y = 5, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "lt_y",
		x = 3, y = 2, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "rt_y",
		x = 3, y = 3, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "lb_y",
		x = 3, y = 4, width = 1, height = 1,
		value = 0
	},
	{
		class = "intedit", name = "rb_y",
		x = 3, y = 5, width = 1, height = 1,
		value = 0
	},
	{
		class = "label",
		x = 0, y = 6, width = 3, height = 1,
		label = "变化持续时间（整数ms）:"
	},
	{
		class = "intedit", name = "dur",
		x = 3, y = 6, width = 1, height = 1,
		value = 1000, min = 0
	},
	{
		class = "label",
		x = 0, y = 7, width = 4, height = 1,
		label = ""
	}
}

function GUI(subs, sel)
	aegisub.progress.title(script_name)
	aegisub.progress.set(0)
	local button, conf = aegisub.dialog.display(config,{"Go!", "Cancel"})
	if button == "Go!" then
		frame_generator(subs, sel, conf.lt_x, conf.lt_y, conf.rt_x, conf.rt_y, conf.rb_x, conf.rb_y, conf.lb_x, conf.lb_y, conf.dur)
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

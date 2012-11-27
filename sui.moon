export sui

import graphics, mouse from love

tau = 2 * math.pi
quarter_tau = 0.25 * tau

copy = (obj) ->
	{k, v for k, v in pairs obj}

bang = (obj) ->
	if type(obj) == 'function'
		obj!
	else
		obj

sequence = (...) ->
	fs = {...}
	(...) ->
		for i, f in ipairs(fs)
			f ...

forward = (table) -> ->
	i = 0
	->
		i += 1
		table[i]

backward = (table) -> ->
	i = #table
	->
		i, j = i - 1, i
		table[j]

sui = {}

connect_handler = (child, parent) ->
	if type(child) == 'function'
		sequence(child, parent)
	else
		parent

connect_focus = (child, parent) ->
	if type(child) == 'function'
		(f, i) -> return child(parent(f, i))
	else
		parent

rotate_focus = (f_iter, b_iter) ->
	(f, i) ->
		iter = if type(i) == 'boolean' and i then b_iter else f_iter
		for wid in iter()
			focus = wid.focus
			if type(focus) == 'function'
				f, i = focus f, i
		return f, i

sui.vbox = (padding, widgets) ->
	obj = {}
	obj.children = widgets
	obj.size = (x, y, ...) ->
		p = bang(padding)
		ox, oy = 0, 0
		for i, wid in ipairs widgets
			w, h = wid.size()
			ox = math.max ox, w
			oy += h + p
		return ox, oy - p
	func = (name) -> (x, y, ...) ->
		p = bang(padding)
		oy = 0
		for i, wid in ipairs widgets
			f = wid[name]
			if type(f) == 'function'
				f x, y + oy, ...
			w, h = wid.size()
			oy += h + p
	obj.draw = func 'draw'
	obj.mousepressed = func 'mousepressed'
	obj.mousereleased = func 'mousereleased'
	obj.update = (...) ->
		for i, wid in ipairs widgets
			f = wid.update
			if type(f) == 'function' then f(...)
	obj.focus = rotate_focus forward(widgets), backward(widgets)
	obj.focus(true)
	return obj

sui.hbox = (padding, widgets) ->
	obj = {}
	obj.children = widgets
	obj.size = (x, y, ...) ->
		p = bang(padding)
		ox, oy = 0, 0
		for i, wid in ipairs widgets
			w, h = wid.size()
			ox += w + p
			oy = math.max oy, h
		return ox - p, oy
	func = (name) -> (x, y, ...) ->
		p = bang(padding)
		ox = 0
		for i, wid in ipairs widgets
			f = wid[name]
			if type(f) == 'function'
				f x + ox, y, ...
			w, h = wid.size()
			ox += w + p
	obj.draw = func 'draw'
	obj.mousepressed = func 'mousepressed'
	obj.mousereleased = func 'mousereleased'
	obj.update = (...) ->
		for i, wid in ipairs widgets
			f = wid.update
			if type(f) == 'function' then f(...)
	obj.focus = rotate_focus forward(widgets), backward(widgets)
	obj.focus(true)
	return obj

sui.option = (key, widgets) ->
	obj = {}
	obj.children = widgets
	obj.size = ->
		wid = widgets[bang(key)]
		if wid ~= nil
			return wid.size()
		else
			return 0, 0
	func = (name) -> (...) ->
		wid = widgets[bang(key)]
		if wid ~= nil
			v = wid[name]
			if type(v) == 'function'
				v(...)
			else
				v
	obj.draw = func 'draw'
	obj.mousepressed = func 'mousepressed'
	obj.mousereleased = func 'mousereleased'
	obj.update = func 'update'
	return obj

eventhandler = (name, handler, widget) ->
	obj = copy(widget)
	obj[name] = connect_handler obj[name], handler
	return obj

handle_on_area = (size, handler) ->
	(x, y, button) ->
		w, h = size()
		if 0 <= x and x < w and 0 <= y and y < h
			handler(x, y, button)

mouse_coordinate_transform = (handler) -> (wx, wy, mx, my, button) ->
	x, y = mx - wx, my - wy
	handler(x, y, button)

sui.mousepressed = (handler, widget) ->
	eventhandler 'mousepressed', mouse_coordinate_transform(handle_on_area(widget.size, handler)), widget

sui.mousereleased = (handler, widget) ->
	eventhandler 'mousereleased', mouse_coordinate_transform(handle_on_area(widget.size, handler)), widget

sui.global_mousepressed = (handler, widget) ->
	eventhandler 'mousepressed', mouse_coordinate_transform(handler), widget

sui.global_mousereleased = (handler, widget) ->
	eventhandler 'mousereleased', mouse_coordinate_transform(handler), widget

sui.update = (handler, widget) ->
	eventhandler 'update', handler, widget

sui.clicked = (handler, widget) ->
	mousedown = nil
	sui.mousepressed (x, y, button) -> mousedown = button,
		sui.global_mousereleased (x, y, button) -> mousedown = nil,
			sui.mousereleased (x, y, button) -> if mousedown == button then handler(x, y, button),
				widget

sui.focusroot = (widget) ->
	obj = copy(widget)
	focus = obj.focus
	obj.focus = (f, i) ->
		f, i = focus(f, i)
		if f then focus(true, i)
	return obj

sui.focus = (handler, widget) ->
	obj = copy(widget)
	focus = obj.focus
	focused = false
	func = (f, i) ->
		x = f or focused
		y = focused
		switch type(i)
			when 'nil'
				focused = f
				x = false
			when 'table'
				focused = f and (i == obj)
			when 'boolean'
				if f
					focused = true
					x, i = false, nil
				else
					focused = false
			when 'number'
				i = math.floor(i)
				if i == 0
					focused = x
					x = false
				else
					focused = false
					if x
						if i > 0 then i -= 1 else i += 1
		if focused != y
			handler(focused)
		return x, i
	obj.focus = connect_focus focus, func
	obj.focus(true)
	return obj

sui.focusbc = (color, handler, widget) ->
	focused = false
	sui.bc (-> if focused then bang(color)),
		sui.focus connect_handler(handler, (f) -> focused = f),
			widget

sui.float = (dx, dy, widget) ->
	obj = copy(widget)
	obj.size = -> return 0, 0
	func = (f) ->
		if type(f) == 'function'
			(x, y, ...) -> f(x + bang(dx), y + bang(dy), ...)
		else
			f
	obj.draw = func obj.draw
	obj.mousepressed = func obj.mousepressed
	obj.mousereleased = func obj.mousereleased
	return obj

sui.margin = (marginx, marginy, widget) ->
	obj = copy(widget)
	size = obj.size
	obj.size = ->
		mx, my = bang(marginx), bang(marginy)
		w, h = size()
		return w + 2 * mx, h + 2 * my
	func = (f) ->
		if type(f) == 'function'
			(x, y, ...) -> f(x + bang(marginx), y + bang(marginy), ...)
		else
			f
	
	obj.draw = func obj.draw
	obj.mousepressed = func obj.mousepressed
	obj.mousereleased = func obj.mousereleased
	return obj

sui.font = (font, widget) ->
	obj = copy(widget)
	draw = obj.draw
	obj.draw = (x, y) ->
		f = bang(font)
		if f == nil
			return draw x, y
		prev = graphics.getFont()
		graphics.setFont f
		draw x, y
		graphics.setFont prev
	return obj

sui.fc = (color, widget) ->
	obj = copy(widget)
	draw = obj.draw
	obj.draw = (x, y) ->
		c = bang(color)
		if c == nil
			return draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		draw x, y
		graphics.setColor r, g, b, a
	return obj

sui.bc = (color, widget) ->
	obj = copy(widget)
	draw = obj.draw
	size = obj.size
	obj.draw = (x, y) ->
		c = bang(color)
		if c == nil
			return draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		w, h = size()
		graphics.rectangle 'fill', x, y, w, h
		graphics.setColor r, g, b, a
		draw x, y
	return obj

sui.frame = (width, height, draw) ->
	obj = {}
	obj.size = -> return bang(width), bang(height)
	obj.draw = draw
	return obj

sui.label = (width, height, caption) ->
	sui.frame width, height, (x, y) -> graphics.print bang(caption), x, y

sui.hbar = (width, height, value) ->
	sui.frame width, height, (x, y) -> graphics.rectangle 'fill', x, y, bang(width) * bang(value), bang(height)

sui.pie = (diameter, value) ->
	obj = {}
	obj.draw = (x, y) ->
		d = bang(diameter)
		r = d / 2
		graphics.arc 'fill', x + r, y + r, r, -quarter_tau, tau * bang(value) - quarter_tau
	obj.size = ->
		d = bang(diameter)
		return d, d
	return obj

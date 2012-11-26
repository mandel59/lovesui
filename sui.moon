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

sui = {}

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
	func = (f) -> (x, y, ...) ->
		p = bang(padding)
		oy = 0
		for i, wid in ipairs widgets
			f wid, x, y + oy, ...
			w, h = wid.size()
			oy += h + p
	obj.draw = func (wid, x, y) -> wid.draw x, y
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
	obj.mousepressed = ms 'mousepressed'
	obj.mousereleased = ms 'mousereleased'
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
		return ox, oy - p
	func = (f) -> (x, y, ...) ->
		p = bang(padding)
		ox = 0
		for i, wid in ipairs widgets
			f wid, x + ox, y, ...
			w, h = wid.size()
			ox += w + p
	obj.draw = func (wid, x, y) -> wid.draw x, y
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
	obj.mousepressed = ms 'mousepressed'
	obj.mousereleased = ms 'mousereleased'
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
	func = (name) -> (x, y, ...) ->
		wid = widgets[bang(key)]
		if wid ~= nil
			v = wid[name]
			if type(v) == 'function'
				v(x, y, ...)
			else
				v
	obj.draw = func 'draw'
	obj.mousepressed = func 'mousepressed'
	obj.mousereleased = func 'mousereleased'
	return obj

sui.margin = (marginx, marginy, widget) ->
	children = {widget}
	draw = (x, y) ->
		mx, my = bang(marginx), bang(marginy)
		w, h = children[1].draw x + mx, y + my
	size = ->
		mx, my = bang(marginx), bang(marginy)
		w, h = children[1].size()
		return w + 2 * mx, h + 2 * my
	ms = (name) -> (x, y, ...) ->
		mx, my = bang(marginx), bang(marginy)
		f = children[1][name]
		if type(f) == 'function'
			f(x + mx, y + my, ...)
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: children}

handle_on_area = (obj, handler) -> (wx, wy, mx, my, button) ->
	x, y = mx - wx, my - wy
	w, h = obj.size()
	if 0 <= x and x < w and 0 <= y and y < h
		handler(x, y, button)

handle_global = (obj, handler) -> (wx, wy, mx, my, button) ->
	x, y = mx - wx, my - wy
	handler(x, y, button)

connect_handler = (child, parent) ->
	if type(child) == 'function'
		sequence(child, parent)
	else
		parent

sui.mousepressed = (handler, widget) ->
	obj = copy(widget)
	obj.mousepressed = connect_handler obj.mousepressed, handle_on_area obj, handler
	return obj

sui.mousereleased = (handler, widget) ->
	obj = copy(widget)
	obj.mousereleased = connect_handler obj.mousereleased, handle_on_area obj, handler
	return obj

sui.global_mousepressed = (handler, widget) ->
	obj = copy(widget)
	obj.mousepressed = connect_handler obj.mousepressed, handle_global obj, handler
	return obj

sui.global_mousereleased = (handler, widget) ->
	obj = copy(widget)
	obj.mousereleased = connect_handler obj.mousereleased, handle_global obj, handler
	return obj

sui.clicked = (handler, widget) ->
	mousedown = nil
	sui.mousepressed (x, y, button) -> mousedown = button,
		sui.global_mousereleased (x, y, button) -> mousedown = nil,
			sui.mousereleased (x, y, button) -> if mousedown == button then handler(x, y, button),
				widget

sui.font = (font, widget) ->
	obj = copy(widget)
	draw = widget.draw
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
	obj.draw = (x, y) ->
		c = bang(color)
		if c == nil
			return widget.draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		widget.draw x, y
		graphics.setColor r, g, b, a
	return obj

sui.bc = (color, widget) ->
	obj = copy(widget)
	obj.draw = (x, y) ->
		c = bang(color)
		if c == nil
			return widget.draw x, y
		r, g, b, a = graphics.getColor()
		graphics.setColor c
		w, h = widget.size()
		graphics.rectangle 'fill', x, y, w, h
		graphics.setColor r, g, b, a
		widget.draw x, y
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

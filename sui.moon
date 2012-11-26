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
		for i = 1, #fs
			fs[i] ...

sui = {}

sui.vbox = (padding, widgets) ->
	func = (f) -> (x, y, ...) ->
		p = bang(padding)
		ox, oy = 0, 0
		for i = 1, #widgets
			w, h = f widgets[i], x, y + oy, ...
			ox = math.max ox, w
			oy += h + p
		return ox, oy - p
	draw = func (wid, x, y) -> wid.draw x, y
	size = func (wid, x, y) -> wid.size()
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
		else
			wid.size()
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: widgets}

sui.hbox = (padding, widgets) ->
	func = (f) -> (x, y, ...) ->
		p = bang(padding)
		ox, oy = 0, 0
		for i = 1, #widgets
			w, h = f widgets[i], x + ox, y, ...
			ox += w + p
			oy = math.max oy, h
		return ox - p, oy
	draw = func (wid, x, y) -> wid.draw x, y
	size = func (wid, x, y) -> wid.size()
	ms = (name) -> func (wid, x, y, ...) ->
		f = wid[name]
		if type(f) == 'function'
			f(x, y, ...)
		else
			wid.size()
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: widgets}

sui.margin = (marginx, marginy, widget) ->
	children = {widget}
	draw = (x, y) ->
		mx, my = bang(marginx), bang(marginy)
		w, h = children[1].draw x + mx, y + marginy
		return w + 2 * mx, h + 2 * my
	size = ->
		mx, my = bang(marginx), bang(marginy)
		w, h = children[1].size()
		return w + 2 * mx, h + 2 * my
	ms = (name) -> (x, y, ...) ->
		mx, my = bang(marginx), bang(marginy)
		f = children[1][name]
		w, h = if type(f) == 'function'
			f(x + mx, y + my, ...)
		else
			children[1].size()
		return w + marginx + marginx, h + marginy + marginy
	return {draw: draw, size: size,
		mousepressed: ms 'mousepressed',
		mousereleased: ms 'mousereleased',
		children: children}

build_mousehandler = (obj, handler) -> (wx, wy, mx, my, button) ->
	x, y = mx - wx, my - wy
	w, h = obj.size()
	if 0 <= x and x < w and 0 <= y and y < h
		handler(x, y, button)
	return w, h

sui.mousepressed = (handler, widget) ->
	obj = copy(widget)
	mousepressed = obj.mousepressed
	obj.mousepressed = build_mousehandler(obj, handler)
	return obj

sui.mousereleased = (handler, widget) ->
	obj = copy(widget)
	obj.mousereleased = build_mousehandler(obj, handler)
	return obj

sui.clicked = (handler, widget) ->
	mousedown = nil
	sui.mousepressed (x, y, button) ->
			mousedown = button,
		sui.mousereleased (x, y, button) ->
				if mousedown == button then handler(x, y, button)
				mousedown = nil,
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
		obj.size!
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
		obj.size!
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

sui.label = (width, height, caption) ->
	obj = {}
	obj.draw = (x, y) ->
		graphics.print bang(caption), x, y
		obj.size!
	obj.size = -> return bang(width), bang(height)
	return obj

sui.hbar = (width, height, value) ->
	obj = {}
	obj.draw = (x, y) ->
		graphics.rectangle 'fill', x, y, bang(width) * bang(value), bang(height)
		obj.size!
	obj.size = -> return bang(width), bang(height)
	return obj

sui.pie = (diameter, value) ->
	obj = {}
	obj.draw = (x, y) ->
		d = bang(diameter)
		r = d / 2
		graphics.arc 'fill', x + r, y + r, r, -quarter_tau, tau * bang(value) - quarter_tau
		obj.size!
	obj.size = ->
		d = bang(diameter)
		return d, d
	return obj

Container = require('./drawing.coffee').Container
Circle    = require('./drawing.coffee').Circle
Line      = require('./drawing.coffee').Line

new class Field
  constructor: ->
    document.getElementsByTagName('button')[0].addEventListener "click", () => @resetWins()

    @count = 7

    if not localStorage.getItem('wins')?  then localStorage.setItem('wins', 0)
    if not localStorage.getItem('count')? then localStorage.setItem('count', @count)

    @updateWinsView()

    @setBackground()
    @start()

  resetWins: ->
    localStorage.removeItem('wins')
    localStorage.setItem('wins', 0)
    @updateWinsView()

  updateWinsView: ->
    document.getElementsByClassName('Wins')[0].innerText = localStorage.getItem('wins')

  setBackground: ->
    stage.canvas.style.background = '#eee'

  howMuch: (win) ->
    @count = localStorage.getItem('count')

    if win then t = 'Поздравляем! ' else t = ''
    @count = parseInt(prompt("#{t}Сколько линий?", @count))

    while not _.isNumber(@count) or _.isNaN(@count)
      @count = parseInt(prompt('Нужно только число. Сколько линий?', @count))

    while @count < 4
      @count = parseInt(prompt('Не, так не интересно, давай больше. Сколько линий?', 4))

    localStorage.setItem('count', @count)

  restart: (recreate, win) ->
    @removeAll()
    @start recreate, win

  start: (recreate, win) ->
    if not recreate
      @howMuch win
      @proportion = @getProportion()
      @win = false

    @createCirclesBlock()
    @createLinesBlock()

    @drawCircles()
    @drawLines()

    @setListeners()

    @reverseLayers()

    @checkIntersection true

    @circlesBlock.visible = true
    @linesBlock.visible = true

  setListeners: ->
    for val in @circles
      val.on 'pressmove', () =>
        @drawLines()
        @checkIntersection()

      val.on 'pressup', () =>
        @checkIntersection false, true

  createCirclesBlock: ->
    @circlesBlock = new Container('circles')
    @circlesBlock.visible = false

  createLinesBlock: ->
    @linesBlock = new Container('lines')
    @linesBlock.visible = false

  getProportion: ->
    maxRadius = 25
    minRadius = 13
    rp = (maxRadius - minRadius) / 70
    if @count >= 70 then @radius = minRadius
    else if @count <= 10 then @radius = maxRadius
    else @radius = maxRadius - ((@count - minRadius) * rp)

    maxStrokeWidth = 5
    minStrokeWidth = 2
    lp = (maxStrokeWidth - minStrokeWidth) / 70
    if @count >= 70 then @strokeWidth = minStrokeWidth
    else if @count <= 10 then @strokeWidth = maxStrokeWidth
    else @strokeWidth = maxStrokeWidth - ((@count - minStrokeWidth) * lp)

  drawCircles: ->
    @circles = []

    for i in [0 ... @count]
      circle = new Circle _.random(@radius, stage.canvas.width - @radius * 2), _.random(@radius, stage.canvas.height - @radius * 2), @radius, '#00bfff', @circlesBlock, i
      @circles.push circle

  drawLines: ->
    @clearContainer @linesBlock
    @lines = []

    for val, key in @circles
      next = key + 1
      if not @circles[next]?
        line = new Line val, @circles[0], @strokeWidth, '#bfff00', @linesBlock
        val.line = line
      else
        line = new Line val, @circles[next], @strokeWidth, '#bfff00', @linesBlock
        val.line = line

      @lines.push line

  checkIntersection: (isFirst, finish) ->
    res = []
    for q in [0 ... @circles.length]
      w = q + 1
      if not @circles[w]? then w = 0
      if @circles[w]?
        for e in [w + 1 ... @circles.length]
          r = e + 1
          if @circles[r]?
            if w == 0 and r == @circles.length - 1 then continue

            p1 = {x: @circles[q].x / 100, y: (stage.canvas.height - @circles[q].y) / 100 }
            p2 = {x: @circles[w].x / 100, y: (stage.canvas.height - @circles[w].y) / 100 }
            p3 = {x: @circles[e].x / 100, y: (stage.canvas.height - @circles[e].y) / 100 }
            p4 = {x: @circles[r].x / 100, y: (stage.canvas.height - @circles[r].y) / 100 }

            x = ((p1.x*p2.y-p2.x*p1.y)*(p4.x-p3.x)-(p3.x*p4.y-p4.x*p3.y)*(p2.x-p1.x))/((p1.y-p2.y)*(p4.x-p3.x)-(p3.y-p4.y)*(p2.x-p1.x))
            y = ((p3.y-p4.y)*x-(p3.x*p4.y-p4.x*p3.y))/(p4.x-p3.x)

            check =
              ((p1.x<=x)and(p2.x>=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x<=x)and(p2.x>=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y<=y)and(p2.y>=y)and(p3.y>=y)and(p4.y<=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x<=x)and(p4.x>=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y<=y)and(p4.y>=y)) or
              ((p1.x>=x)and(p2.x<=x)and(p3.x>=x)and(p4.x<=x)) or
              ((p1.y>=y)and(p2.y<=y)and(p3.y>=y)and(p4.y<=y))

            if check
              @circles[q].line.graphics._stroke.style = '#ff0040'
              @circles[e].line.graphics._stroke.style = '#ff0040'


            if finish or isFirst then res.push check

    if isFirst
      if res.every( (val) -> !val)
        @restart isFirst, finish

    if finish
      if res.every( (val) -> !val)
        return if @win
        @win = true
        localStorage.setItem('wins', Number(localStorage.getItem('wins')) + 1)
        @updateWinsView()
        @restart false, true

  reverseLayers :             -> stage.children.reverse() # TODO
  clearContainer: (container) -> container.removeAllChildren()
  removeAll     :             -> stage.removeAllChildren()

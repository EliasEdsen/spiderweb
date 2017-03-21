class Container
  constructor: (name = '', x = 0, y = 0, parent = stage) ->
    @container = new createjs.Container()

    @container.set
      name: name
      x: x
      y: y

    parent.addChild @container

    return @container

###############
###############

class Draw
  constructor: ->
    @draw = new createjs.Shape()

  setListenersForMoveable: ->
    @draw.on 'mouseover', () =>
      command = @draw.graphics.command
      createjs.Tween.get command, {override: true}
        .to({radius: command.radius + 5}, 500, createjs.Ease.elasticOut)

      document.body.style.cursor = 'pointer'

    @draw.on 'mouseout', () =>
      command = @draw.graphics.command
      createjs.Tween.get command, {override: true}
        .to({radius: command.radius - 5}, 500, createjs.Ease.elasticOut)

      document.body.style.cursor = 'default'

    @draw.on 'pressup', () =>
      @localX = @localY = null

    @draw.on 'pressmove', (evt) =>
      @localX ?= evt.localX
      @localY ?= evt.localY

      @draw.x = evt.stageX - @localX
      @draw.y = evt.stageY - @localY

      if @draw.x < @draw.graphics.command.radius then @draw.x = @draw.graphics.command.radius
      if @draw.y < @draw.graphics.command.radius then @draw.y = @draw.graphics.command.radius

      if @draw.x > stage.canvas.width - @draw.graphics.command.radius then @draw.x = stage.canvas.width - @draw.graphics.command.radius
      if @draw.y > stage.canvas.height - @draw.graphics.command.radius then @draw.y = stage.canvas.height - @draw.graphics.command.radius

  addChild: (parent = stage) -> parent.addChild @draw

###############
###############

class Line extends Draw
  constructor: (from, to, width, color, parent) ->
    super

    @draw.graphics.setStrokeStyle(width).beginStroke(color).moveTo(from.x, from.y).lineTo(to.x, to.y)
    @addChild parent

    return @draw

###############
###############

class Circle extends Draw
  constructor: (x, y, radius, color, parent) ->
    super

    @draw.graphics.setStrokeStyle(3).beginStroke('#eee').beginFill(color).drawCircle(0, 0, radius);
    @draw.set
      x: x + radius
      y: y + radius

    @setListenersForMoveable()

    @addChild parent

    return @draw


module.exports.Container = Container
module.exports.Circle    = Circle
module.exports.Line      = Line

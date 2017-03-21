require '../styles/index.styl'

global._     = require "underscore"
global.stage = new createjs.Stage "canvas"

stage.enableMouseOver()
createjs.Ticker.setFPS(60)
createjs.Ticker.addEventListener "tick", stage

require './field.coffee'

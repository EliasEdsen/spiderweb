require '../styles/index.styl'

global._     = require "underscore"
global.stage = new createjs.Stage "canvas"

require './app.coffee'

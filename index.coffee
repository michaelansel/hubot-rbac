Path = require('path')

module.exports = (robot) ->
  path = Path.resolve __dirname, 'src'

  robot.loadFile path, 'rbac.coffee'
  robot.parseHelp Path.join(path, 'rbac.coffee')

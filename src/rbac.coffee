# Description
#   RBAC authorization framework for hubot
#
# Configuration:
#   HUBOT_RBAC_DEFAULT_POLICY - [allow|deny] - Behavior when there is no defined policy for a given listener
#
# Commands:
#
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Michael Ansel <mansel@box.com>

module.exports = (robot) ->
  require('hubot-rbac/src/core')(robot)

  robot.addListenerMiddleware (robot, listener, response, next, done) ->
    operation = listener.options.id
    permissions = robot.rbac.allOperations[operation] or []

    response.reply "Permissions allowing Operation (#{operation}): #{permissions}"
    response.reply "Checking permissions for #{response.message.user.id}"

    allowed = false
    if permissions.length > 0
      permissions.forEach (permission) ->
        allowed = allowed or robot.rbac.userHasPermission(response.message.user.id, permission)
    else
      defaultPolicy = robot.rbac.allowUnknown
      defaultPolicyWord = if defaultPolicy then 'allow' else 'deny'
      response.reply "No Permissions for Operation (#{operation}); using default policy (#{defaultPolicyWord})"
      allowed = defaultPolicy
    response.reply "Access allowed? " + JSON.stringify allowed

    # If allowed, continue; otherwise, bail
    if allowed
      next(done)
    else
      done()

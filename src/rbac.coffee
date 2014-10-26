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
#   Installs basic middleware for enforcing authorization policy. Expects
#   that robot.rbac.isUserAuthorized is overridden. Depends on core.coffee.
#
# Author:
#   Michael Ansel <mansel@box.com>

async = require 'async'

module.exports = (robot) ->
  RBAC = require('./core')(robot)

  robot.addListenerMiddleware (robot, listener, response, next, done) ->
    operation = listener.options.id
    permissions = RBAC.getPermissionsForOperation(operation)

    response.reply "Permissions allowing Operation (#{operation}): #{permissions}"
    response.reply "Checking permissions for #{response.message.user.id}"

    if permissions.length == 0
      defaultPolicy = RBAC.allowUnknown
      defaultPolicyWord = if defaultPolicy then 'allow' else 'deny'
      response.reply "No Permissions for Operation (#{operation}); using default policy (#{defaultPolicyWord})"
      finish defaultPolicy, response, next, done
    else
      # Check for any authorized permissions
      async.some(permissions,
       (permission, cb) ->
         RBAC.isUserAuthorized(
           # TODO Probably want the full user object here
           response.message.user.id, permission, response, cb
         )
       (allowed) ->
         finish allowed, response, next, done
      )

  finish = (allowed, response, next, done) ->
    response.reply "Access allowed? " + JSON.stringify allowed

    # If allowed, continue; otherwise, bail
    if allowed
      next(done)
    else
      done()

async = require 'async'
minimatch = require 'minimatch'

module.exports = (robot) ->
  RBAC = require('./core')(robot)

  SimpleACL = {}

  # Map of User to allowed Permissions
  userPermissions = {}

  SimpleACL.addUserPermissions = (users) ->
    Object.keys(users).forEach (user) ->
      if not userPermissions.hasOwnProperty(user)
        userPermissions[user] = []
      # Add new permissions to the list of permissions for this user
      userPermissions[user] = userPermissions[user].concat(users[user])

  userHasPermission = (user, permission, response, cb) ->
    user = user.id
    if user in Object.keys(userPermissions)
      # User just needs a single permission
      async.some(
        userPermissions[user],
        (permPattern, cb) -> cb minimatch(permission, permPattern)
        (result) -> cb result
      )
    else
      response.reply 'User does not have any permissions'
      cb false

  RBAC.addPermissionCheck (user, permissions, response, cb) ->
    done = (permissions) ->
      if permissions.length == 0
        response.reply "User does not have any of the required permissions"
      cb permissions
    async.filter(
      permissions
      (permission, cb) -> userHasPermission user, permission, response, cb
      done
    )

  return SimpleACL

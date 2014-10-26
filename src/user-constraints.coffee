async = require 'async'

module.exports = (robot) ->
  RBAC = require('./core')(robot)

  UserConstraints = {}

  # Map of permissions to an array of constraint names
  permissionConstraints = {}

  # Map of constraint names to handler functions
  constraintCheckers = {}

  # TODO documentation
  UserConstraints.addPermissionConstraints = (permissions) ->
    Object.keys(permissions).forEach (permission) ->
      if not permissionConstraints.hasOwnProperty(permission)
        permissionConstraints[permission] = []
      # Add new constraints to the list of constraints for this permission
      permissionConstraints[permission] = permissionConstraints[permission].concat(permissions[permission])

  # TODO documentation
  UserConstraints.addChecker = (name, checker) ->
    constraintCheckers[name] = checker

  testConstraint = (user, constraintName) ->
    if constraintName in Object.keys(constraintCheckers)
      constraintCheckers[constraintName](user)
    else
      robot.logger.error "Unknown constraint required! (#{constraintName})"
      false

  userMeetsConstraints = (user, permission, response, cb) ->
    if permission in Object.keys(permissionConstraints)
      # Make sure every constraint passes
      async.every(
        permissionConstraints[permission]
        (constraint, cb) -> cb testConstraint(user, constraint)
        cb
      )
    else
      # no constraints to check
      response.reply "No constraints on permission (#{permission})"
      cb true

  RBAC.addPermissionCheck userMeetsConstraints

  return UserConstraints

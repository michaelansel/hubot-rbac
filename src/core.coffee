# Description
#   Core RBAC functionality usable by all scripts
#
# Configuration:
#   HUBOT_RBAC_DEFAULT_POLICY - [allow|deny] - Behavior when there is no defined policy for a given listener
#
# Commands:
#
#
# Notes:
#   Primarily provides robot.rbac.addPermissions so scripts can define their
#   own Permission to Operation mapping. Does NOT set up any commands or
#   install middleware.
#
# Author:
#   Michael Ansel <mansel@box.com>


module.exports = (robot) ->
  # Only initialize once
  return if robot.rbac?

  robot.rbac = {}

  robot.rbac.addPermissions = (baseNamespace, permissions) ->
    Object.keys(permissions).forEach (k) ->
      permissionName = baseNamespace + '.' + k
      operations = permissions[k].map (operation) ->
        baseNamespace + '.' + operation
      addPermission(permissionName, operations)

  # map of permissions to an array of operations
  robot.rbac.allPermissions = {}
  # map of operations to an array of permissions
  robot.rbac.allOperations = {}

  # replaces existing operation list for the permission
  addPermission = (permission, operations) ->
    # not sure if this forward mapping is ever even needed, might only need the reverse mapping
    robot.rbac.allPermissions[permission] = operations
    operations.forEach (operation) ->
      addPermissionToOperation(permission, operation)

  # adds permission to list of permissions allowing a certain operation
  addPermissionToOperation = (permission, operation) ->
    if !robot.rbac.allOperations.hasOwnProperty operation
      robot.rbac.allOperations[operation] = []
    robot.rbac.allOperations[operation].push permission

  # Default; should be overridden
  robot.rbac.userHasPermission = (user, permission) ->
    defaultPolicy = robot.rbac.allowUnknown
    defaultPolicyWord = if defaultPolicy then 'allow' else 'deny'
    console.log("No auth policy defined! Falling back to default state for all commands (#{defaultPolicyWord}).")
    return defaultPolicy

  # Default to the more secure option
  defaultPolicy = process.env.HUBOT_RBAC_DEFAULT_POLICY or 'deny'
  robot.rbac.allowUnknown = (defaultPolicy == 'allow')

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

  # baseNamespace - optional namespace for all permissions and operations
  # permissions - Object mapping Permissions to arrays of Operations
  robot.rbac.addPermissions = (baseNamespace, permissions) ->
    if not permissions?
      permissions = baseNamespace
      baseNamespace = undefined

    if not (permissions is Object(permissions))
      throw new Error("Need an object of Permission to Operation mappings")

    if baseNamespace?
      prefix = baseNamespace + '.'
    else
      prefix = ''

    # Prefix permission name and all operation names
    # Then, add to the global permission set
    Object.keys(permissions).forEach (permission) ->
      fullPermissionName = prefix + permission
      operations = permissions[permission].map (operation) ->
        prefix + operation
      addPermission(fullPermissionName, operations)

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

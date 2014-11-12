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

async = require 'async'
minimatch = require 'minimatch'

module.exports = (robot) ->
  # Only initialize once
  return robot.rbac if robot.rbac?

  robot.rbac = RBAC = {}

  # map of operations to an array of permissions
  allOperations = {}

  # array of permission check functions
  permissionChecks = []

  # TODO documentation
  # baseNamespace - optional namespace for all permissions and operations
  # permissions - Object mapping Permissions to arrays of OperationPatterns
  # OperationPattern is a glob pattern that matches one or more Operations
  RBAC.addPermissions = (baseNamespace, permissions) ->
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
      permissions[permission].forEach (operation) ->
        addPermissionToOperation(fullPermissionName, prefix + operation)

  # adds permission to list of permissions allowing a certain operation
  addPermissionToOperation = (permission, operation) ->
    if !allOperations.hasOwnProperty operation
      allOperations[operation] = []
    allOperations[operation].push permission

  # TODO documentation
  # expand all operation globs and get the list of permissions for an operation
  RBAC.getPermissionsForOperation = (operation) ->
    permissions = []
    # Find all entries that match and collect permissions
    Object.keys(allOperations).forEach (opPattern) ->
      if minimatch(operation, opPattern)
        # Add all permissions for opPattern to the list
        Array.prototype.push.apply(permissions, allOperations[opPattern])
    permissions

  # TODO documentation
  # called like this: fn.call(undefined, user, permission, response, cb)
  RBAC.addPermissionCheck = (cb) ->
    permissionChecks.push cb

  # TODO documentation
  # permissions - list of permissions to check
  # cb(accessIsAllowed) - callback with the final access decision
  RBAC.checkPermissions = (response, permissions, cb) ->
    if permissionChecks.length > 0
      # Execute each permissionCheck in definition order and gradually reduce the list of allowed permissions
      async.reduce(
        permissionChecks
        permissions
        (permissions, permissionCheck, cb) ->
          # Stop executing checks when there are no more permissions left
          permissionCheckComplete = (permissions) ->
            if permissions.length > 0
              cb null, permissions
            else
              cb new Error(), []
          # Execute a single permissionCheck
          permissionCheck.call(
            undefined
            response.message.user
            permissions
            response
            permissionCheckComplete
          )
        # Access is allowed if at least one Permission passed all checks
        (err, result) -> cb (result.length > 0)
      )
    else
      defaultPolicy = RBAC.allowUnknown
      defaultPolicyWord = if defaultPolicy then 'allow' else 'deny'
      response.reply("No authorization policy defined! Falling back to default state for all commands (#{defaultPolicyWord}).")
      cb defaultPolicy

  # Default to the more secure option
  defaultPolicy = process.env.HUBOT_RBAC_DEFAULT_POLICY or 'deny'
  RBAC.allowUnknown = (defaultPolicy == 'allow')

  # Always return the RBAC object
  return RBAC

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

minimatch = require 'minimatch'

module.exports = (robot) ->
  # Only initialize once
  return if robot.rbac?

  robot.rbac = rbac = {}

  # baseNamespace - optional namespace for all permissions and operations
  # permissions - Object mapping Permissions to arrays of OperationPatterns
  # OperationPattern is a glob pattern that matches one or more Operations
  rbac.addPermissions = (baseNamespace, permissions) ->
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

  # map of operations to an array of permissions
  rbac.allOperations = {}

  # adds permission to list of permissions allowing a certain operation
  addPermissionToOperation = (permission, operation) ->
    if !rbac.allOperations.hasOwnProperty operation
      rbac.allOperations[operation] = []
    rbac.allOperations[operation].push permission

  # expand all operation globs and get the list of permissions for an operation
  rbac.getPermissionsForOperation = (operation) ->
    permissions = []
    # Find all entries that match and collect permissions
    Object.keys(rbac.allOperations).forEach (opPattern) ->
      if minimatch(operation, opPattern)
        # Add all permissions for opPattern to the list
        Array.prototype.push.apply(permissions, rbac.allOperations[opPattern])
    permissions

  # Default; should be overridden
  rbac.userHasPermission = (user, permission) ->
    defaultPolicy = rbac.allowUnknown
    defaultPolicyWord = if defaultPolicy then 'allow' else 'deny'
    console.log("No auth policy defined! Falling back to default state for all commands (#{defaultPolicyWord}).")
    return defaultPolicy

  # Default to the more secure option
  defaultPolicy = process.env.HUBOT_RBAC_DEFAULT_POLICY or 'deny'
  rbac.allowUnknown = (defaultPolicy == 'allow')

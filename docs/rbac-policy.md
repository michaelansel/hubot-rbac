hubot-rbac leverages Listener options (specifically, the `id` property) to uniquely address each listener and assign it Permissions.

## Permission Checkers
- Responsible for determining if a user is authorized for any of the permissions associated with the attempted operation
- Executed in order of instantiation
For more information about writing new permission checkers, see the [permission checker docs](./permission-checkers.md).

Built-in Permission Checkers
- [SimpleACL](#SimpleACL): simple mapping of usernames to permissions. Reads the `name` property off the `user` object.
- [BrainACL](#BrainACL): modeled after [hubot-auth](hubot-scripts/hubot-auth), this stores the user-permission mapping in the hubot brain
- [UserConstraints](#UserConstraints): simple framework for ensuring a user meets certain authentication requirements (e.g. user has two-factor authed recently with the bot)

## Default Policy
  # Allow operations with no associated permissions (be careful with this!)
  RBAC.setDefaultPolicy('allow')

# SimpleACL

# BrainACL

# UserConstraints

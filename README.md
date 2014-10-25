# hubot-rbac

RBAC authorization framework for hubot

See [`src/rbac.coffee`](src/rbac.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-rbac --save`

Then add **hubot-rbac** to your `external-scripts.json`:

```json
[
  "hubot-rbac"
]
```

## Supported authorization models

- user-permission mapping stored in the brain
  - permission-operation mapping provided by scripts
- user-operation mapping in the brain?
  - this is what hubot-auth does right now
    - false: hubot-auth has groups between users and operations
- user-permission mapping stored in a script file
  - additional permission-operation mappings could be in script file
- group-permission mapping stored in a script file, user-group mapping in LDAP
  - async lookup of user-group information
- all mappings stored in rolesdb
  - async lookup of everything
  - no explicit distinction between Permissions and Roles
- role activation constraints? (2fa, rsa, etc.)
  - or should these be mapped to the permission level? permission seems a little better, but not proper RBAC
  - could create many roles (role_sre_2fa, role_sre_rsa, role_sre_ldap) and map those to the allowed permissions with an activation constraint on the role -- difficult if you want to require multiple proofs of identity (i.e. 2fa AND rsa)
  - separation of duties enforcement?
- secondary approval (nuclear keys)
  - this could (should?) be done in an independent piece of middleware
  - want to reuse authz logic for who can approve though

## Goals
- standard way for script developers to define groups of operations
  - these groups are a convenience, but bot owners can override (is override **really** necessary?)
  - compromise: allow override, but only in code (not an external datastore)
- simple way for bot owners to "add the authorization"
  - add a small number of modules (1-2) and define config
  - for legacy (non-rackup) bots, this really needs to be a single include
- messaging when access is denied
  - clarity depends on auth model ("you're not authorized" vs "...because X, Y, Z")
- blocks listener execution when access is denied (listener isn't aware of auth)
- extensible asynchronous decision making (to allow approval step)
- LATEST THOUGHT

## Questions
- should there be an explicit distinction between Permissions and Operations?
  - should you be able to tie a user directly to an Operation?

## Internal architecture
- basically a miniature rolesdb w/ callbacks for constraint checking
- operation == permission == role
- roles can have roles
- users can have roles
- roles can have activation constraints
- access is allowed if user has role and constraint passes
- mini-rolesdb should be a submodule (not needed if using real rolesdb)
  - so, what needs to go in the CORE?
  - should there be multiple cores? (i.e. is middleware all that is needed at the core?)
  - maybe just set an interface?
  - would like to have a standard way for script developers to define groups of operations
  - brings us back to users -> (roles==permissions) -> operations
  - set user.applicableRoles = (user.getAllRoles intersect operation.getAllRoles)
  - generic error message if user.applicableRoles is empty ("sorry, you don't have permission")
    - could also list all possible roles ("you must be in one of these roles")
    - that part gets a little tricky ("roles? I'm using LDAP groups, but those 'permissions' aren't real LDAP groups")
  - activation constraints are handled by a deeper piece of middleware!
  - looks like the interface should be:
    - any kind of authz middleware should determine what are the applicable roles for a user-operation combination
    - may have multiple applicable roles (behavior TBD, likely pick the first)
    - rbac-core collects/provides permission/operation mapping; authz middleware can chose to use mapping or go completely rogue
  - flow
    - get all roles for a user-operation combination
      - for simpler setups like just-LDAP, first step could be 'get all LDAP groups'
    - deeper middleware can further restrict the list of applicable roles
    - at the end, if role list is empty, access is denied
  - this flow still seems like it causes problems with messaging about failures
    - could append to a list of reasons why roles were removed from the list, but would probably be way too large for LDAP setup ('removed role_eng because role_eng doesn't have access to acccess_iks')
    - have role selection logic that has simple messaging 'these are the allowed roles for the operation', THEN check constraints (with completely independent messaging)
    - end result is constraint checking is completely independent of role selection

### Execution
- test by walking backwards from Operations (but what about messaging on constraint failures?)
- find a path and THEN test constraints? should only misbehave if there are multiple paths
- require that role graph is a directed minimum spanning tree (c.f. arborescence)
  - that may be difficult to require... (sre gets ops and eng privileges, ops and eng have haproxy access)
  - could require that multi-pathing collapses to a single path with identical constraints
  - could say the behavior is undefined (i.e. which path's constraints will be enforced)
    - might want to build an automated graph validation mechanism ('watch out! shit's gonna be weird!')

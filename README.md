# hubot-rbac

FIX THE LINK
[RBAC](LINK TO RBAC ON WIKIPEDIA) authorization framework for hubot

This README gives a brief overview of hubot-rbac and a quick start guide. For more detailed explanations, see the `docs` directory.

## Quick start

In hubot project repo, run:

`npm install hubot-rbac --save`

Next, add **hubot-rbac** to your `external-scripts.json`:

```json
[
  "hubot-rbac"
]
```

Finally, create an [rbac-policy file](docs/rbac-policy.coffee) (simple example below).

## RBAC Primer

Role-based Access Control is a powerful framework for answer the question of "who can do what". In RBAC, Users are assigned Roles, Roles are given Permissions, and Permissions are mapped to individual Operations.

In hubot-rbac, an Operation is exactly one listener (`hear`/`respond`). Scripts may define common mappings of Permissions to the defined Operations.

In order to provide the most flexibility, the core framework only makes assumptions about Users, Permissions, and Operations. Roles are considered an abstract construct that is managed by permission checkers.

## RBAC Policy

hubot-rbac provides a framework and set of permission checkers to enable bot owners to create an authorization policy that meets their needs. This policy is defined in a standard hubot script (usually called `rbac-policy.coffee`) in the main bot repository.

An RBAC policy file consists of three main components:
- instantiate permission checkers in order of execution
- add additional permission-operation mappings
- configure permission checkers

```coffeescript
# rbac-policy.coffee
module.exports = (robot) ->
  # Instantiate permission checkers
  RBAC = require('hubot-rbac/src/core')(robot)
  SimpleACL = require('hubot-rbac/src/simple-acl')(robot)

  # Assuming the following Operations exist
  # - mysql.explain: Return the explain plan for a raw MySQL query
  # - mysql.profile: Profile a raw MySQL query and return the results
  # - deploy.service.{web,assets,search}: Deploy the latest version of web/assets/search to production

  # Assuming the following Permissions exist (mapped to one or more Operations by a different script)
  # - statuspage.modify: Make changes the public status page
  # - jira.{modify,search}: Interact with JIRA

  # Add additional Permission-Operation mappings
  RBAC.addPermissions({
    'mysql.execute-query': ['mysql.explain', 'mysql.profile']
    'deploy.frontend': ['deploy.service.web', 'deploy.service.assets']
    'deploy.backend': ['deploy.service.search']
  })

  # Associate Users with Permissions
  SimpleACL.addUserPermissions({
    # Steve is a member of Operations
    'Steve': ['mysql.execute-query', 'deploy.*', 'jira.*']

    # John is a frontend developer
    'John': ['deploy.frontend', 'jira.*']

    # Ryan is a member of the Customer Support team
    'Ryan': ['statuspage.modify', 'jira.*']

    # Anyone can search JIRA
    '*': ['jira.search']
  })
```

For more details on creating complex authorization policies, see the [rbac-policy docs](docs/rbac-policy.coffee).

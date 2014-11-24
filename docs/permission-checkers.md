This document is targeted towards developers of new permission checkers. Most users should just need to set up an [rbac-policy file](./rbac-policy.md).

hubot-rbac is built around the idea of stacked permission checkers that each perform one component of user authorization. Isolating authorization logic allows end-users to pick and choose the approprate authorization rules to meet their needs. A permission checker is responsible for filtering down the list of permissions to only those that are allowed. Permission checker execution is similar to that of hubot middleware.

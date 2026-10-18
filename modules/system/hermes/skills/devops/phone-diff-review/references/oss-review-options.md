# OSS review options for no-MR phone review

Decision table for "let me see the diff and comment from my phone without
creating a merge/pull request". Ordered by fit for solo/agent-driven flow.

| Tool | Model | Verdict |
| --- | --- | --- |
| GitLab Compare revisions | Branch must be pushed; comparison page lists commits + per-file diff, creates no MR | Best when pushing the branch is acceptable; zero new infrastructure |
| diff2html (MIT) + thin comment layer (steps 5-6) | Any local diff or commit range rendered to static HTML; on-demand server only | Best for unpushed/agent branches and exact commit pairs |
| Review Board | `rbt post` uploads any diff for review with inline comments, no MR | Conceptually ideal, but a persistent service with a database; justified only at team review volume |
| Gerrit | Patchset-based review, inline comments, 100% open source | Heavyweight Java service that replaces the branch workflow with patchsets; wrong tool for branch-based solo flow |
| Forgejo/Gitea PR review | Needs a repo mirror plus a pull request | Reuses an existing forge, but violates the no-PR constraint |

## The forge-extraction rule

Before proposing to lift "just the diff UI" out of a forge, check two
things: where rendering happens and where the state lives. Server-rendered
markup plus database-coupled state (pull requests, users, permissions) means
extracting the UI means porting the backend. A standalone render library
(diff2html) plus a thin purpose-built comment layer is the thinner
composition, and it is what steps 5-6 implement.

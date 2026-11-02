"""
Repository rule with an archive of the working tree.

The archive contains the files a release archive would contain if the working
tree were committed, including untracked files that aren't ignored. The rule
watches the files and directories and creates a new archive when they change.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

visibility("private")

def _git(rctx, args, environment = {}):
    result = rctx.execute(
        ["git", "-C", str(rctx.workspace_root)] + args,
        environment = environment,
    )
    if result.return_code != 0:
        fail("'git {}' failed:\n{}{}".format(args[0], result.stdout, result.stderr))
    return result.stdout

def _ancestors(path):
    result = []
    for _ in range(path.count("/")):
        path = paths.dirname(path)
        result.append(path)
    return result

def _working_tree(rctx):
    """
    Returns the tree object of the working tree and the files in it.

    Uses a separate index, which leaves the index of the working tree unchanged.
    """
    index = {"GIT_INDEX_FILE": str(rctx.path("index"))}
    _git(rctx, ["add", "--all"], index)
    tree = _git(rctx, ["write-tree"], index).strip()
    files = [f for f in _git(rctx, ["ls-files", "-z"], index).split("\0") if f]
    rctx.delete("index")
    return tree, files

def _archive(rctx, tree, output):
    """
    Writes an archive of a tree object.

    Archives a commit with a fixed date instead of the tree: 'git archive' sets
    the modification time of the files to the commit time, or to the current
    time for a tree.
    """
    commit = _git(
        rctx,
        ["commit-tree", "--no-gpg-sign", "-m", "working tree", tree],
        {
            "GIT_AUTHOR_DATE": "Sat, 01 Jan 2000 00:00:00 +0000",
            "GIT_AUTHOR_EMAIL": "working-tree@localhost",
            "GIT_AUTHOR_NAME": "working tree",
            "GIT_COMMITTER_DATE": "Sat, 01 Jan 2000 00:00:00 +0000",
            "GIT_COMMITTER_EMAIL": "working-tree@localhost",
            "GIT_COMMITTER_NAME": "working tree",
        },
    ).strip()
    _git(rctx, ["archive", "--format=tar", "--output=" + str(output), commit])

def _watch(rctx, files):
    """
    Watches files in the working tree and the entries of their directories.

    A new file changes the entries of an existing directory.
    """
    root = str(rctx.workspace_root)
    for file in files:
        rctx.watch(paths.join(root, file))

    dirs = {
        dir: None
        for file in files
        for dir in _ancestors(file)
    }
    for dir in [""] + dirs.keys():
        rctx.path(paths.join(root, dir)).readdir(watch = "yes")

def _git_archive_impl(rctx):
    tree, files = _working_tree(rctx)
    _archive(rctx, tree, rctx.path("archive.tar"))
    _watch(rctx, files)
    rctx.file("BUILD.bazel", 'exports_files(["archive.tar"])\n')

git_archive = repository_rule(
    implementation = _git_archive_impl,
)

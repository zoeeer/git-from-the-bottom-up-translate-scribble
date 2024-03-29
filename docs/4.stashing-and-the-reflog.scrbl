#lang scribble/manual


@title[#:tag "stashing-and-the-reflog"]{储藏，以及引用日志}

目前为止我们已经描述了blob对象存在于Git的两种形式：首先它们在索引中产生，这时候它既没有树作为父亲也不归哪个提交所有；后来它们被提交到代码仓库中，在这里它们作为叶节点挂在由提交对象持有的树上。但这并不是全部，blob对象还以另外两种形式存在于仓库里。

其中第一种就是Git引用日志（reflog）。它相当于一种元仓库，它以提交的形式记录着你对仓库每一次的改动。也就是说，每当你从索引文件创建出树，并将它存储到提交对象名下（由@code{commit}命令完成）的时候，你同时也在不经意地把该提交添加到引用日志中。用这个命令可以查看：

@verbatim|{
$ git reflog
5f1bc85...  HEAD@{0}: commit (initial): Initial commit
}|

引用日志的妙处在于，它持续存在于代码仓库中，独立于其它的任何变化。也就是说我可以表面上把上面这个提交从仓库中删掉（用@code{reset}），但它还会被引用日志继续保管，30之内不会被垃圾回收清理掉。这就为我争取了一个月的时间，万一我发现真的需要它的话我还可以把这个提交恢复出来。

最后一个blob对象可以存在的地方，尽管是间接地，就是存在于你的工作树自身。我的意思是，比如你修改了一个名叫@code{foo.c}的文件，但还没有向暂存区添加这些改动。这时候Git可能还没有为这个文件创建blob，但这些改动已经存在了，即这些内容是存在的---只不过它们存在于你的文件系统上，而不是Git目录里。该文件甚至还有自己的SHA1哈希值，哪怕并没有真正的blob对象存在。你可以查看这个值：

@verbatim{
$ git hash-object foo.c
<some hash id>
}

这对你有什么用呢？呐，如果你发现自己在工作目录上做了很多事情，现在漫长的一天快要结束了，有个值得培养的好习惯，就是把你的工作储藏（stash）起来：

@verbatim{
$ git stash
}

该操作把你目录下的所有内容---包括工作树和索引---拿过来，为它们创建blob放在git仓库里，创建保存这些blob的树，创建一对储藏提交分别保存工作树和索引，并记录下你创建储藏的时间。

这是一项很好的实践，因为，虽然你第二天会立刻使用@code{stash apply}把这次储藏的内容拉取出来，但你即将拥有一份引用日志，里面包含你在每日结束时储藏起来的工作内容。下面是你在第二天早上回归工作时要做的事情（WIP代表“Work in progress”，即“工作进行中”）：

@verbatim|{
$ git stash list
stash@{0}: WIP on master: 5f1bc85...  Initial commit

$ git reflog show stash # 一样的输出，加上了stash自己的哈希值
2add13e... stash@{0}: WIP on master: 5f1bc85... Initial commit

$ git stash apply
}|

由于储藏起来的工作树存储在提交对象中，因此你可以像使用任意其它分支一样来使用它---无论何时！意味着你可以查看log，查看你是什么时候储藏的，还可以检出过去任意一次储藏时保存的工作树：

@verbatim|{
$ git stash list
stash@{0}: WIP on master: 73ab4c1...  Initial commit
...
stash@{32}: WIP on master: 5f1bc85...  Initial commit
$ git log stash@{32}  # 我什么时候储藏的？
$ git show stash@{32}  # 给我展示我当时在做什么
$ git checkout -b temp stash@{32}  # 来看看当时的工作树吧！
}|

最后一个命令尤其强大：瞧，我正在自己一个月以前并没有提交的工作树上玩耍。我甚至都没有把这些文件添加到暂存区；我只不过在每天下线之前作为权宜之计使用了一下@code{stash}（当然前提是工作目录里确实有改动才储藏），以及重新登入的时候用了@code{stash apply}。

如果你希望清理储藏列表---比如只保存最近30天的活动---不要使用@code{stash clear}，务必使用@code{reflog expire}命令：

@verbatim{
$ git stash clear  # 别！会丢失所有储藏历史
$ git reflog expire --expire=30.days refs/stash
<输出保留下来的储藏记录>
}

@code{stash}的美妙之处在于，它为你的工作进程本身提供了一种低调的版本控制功能：也就是你的工作树日复一日变化的过程。如果你喜欢的话你甚至可以在更广泛的场合使用@code{stash}，比如用类似下面的@code{snapshot}（快照）脚本：

@verbatim{
$ cat <<EOF > /usr/local/bin/git-snapshot
#!/bin/sh
git stash && git stash apply
EOF
$ chmod +x $_
$ git snapshot
}

你完全可以通过@code{cron}计划任务每小时运行它，同时每周或每月定时运行@code{reflog expire}命令。

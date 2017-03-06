#lang scribble/manual

@(require scriblib/footnote)

@(define-footnote notes2-1 footnotes2-1)
@(define-footnote notes2-2 footnotes2-2)


@title{索引（the index）}



@section{索引：见一见中间人}

在你的数据文件（存储在文件系统上）与Git二进制对象（存储在代码仓库里）之间，存在着一位多少有点奇怪的实体：Git索引。这匹怪兽有点难于理解，部分原因是，它有个倒霉名字。因为它指向你用add命令新创建出来的的树与二进制对象的集合，在这个意义上它是一份索引。这些新创建的对象很快就会绑定到一棵新的树上用以进行提交---但在那之前，只有通过“索引”才能索引到它们。这意味着，如果你用reset命令把某个已登记的改动从索引里取消登记了，你等于是造出了一个blob孤儿，它会在未来的某个时间被系统删掉。

索引确实是一个暂存区，为你的下次提交保存一些东西。它有很好的存在理由：它支持这么一种开发模型，该模型可能CVS或者Subversion的用户都没见过，不过对于Darcs@notes2-1{译注}的用户应该再熟悉不过了：它让你能够逐步地构建你的下一次提交。

@image["images/the-index.png"]

我有必要先说一句：你几乎是可以完全忽略索引这件事的，只要你给commit命令加上@code{-a}标志@notes2-1{译注：commit的-a选项告诉git提交所有改动过的文件以及删除动作，但新创建的、没有告诉过Git的文件不会自动提交}。比如我们来看看Subversion的工作方式，做个比较。当你输入@code{svn status}，你会看到一个列表，上面是你现在执行@code{svn commit}的话你的仓库里会发生的动作。一定程度上这个“即将发生的动作清单”也是一种非正式的索引，它由工作树的当前状态与HEAD的状态对比得出。如果文件foo.c改动过了，你下次提交的时候这些改动会被保存。如果一个未知的文件，旁边标着一个问号，它会被忽略；但新文件如果已经用@code{svn add}命令添加过了，就会被添加到仓库里。

上述行为跟@code{commit -a}没有任何区别：新的、未知的文件被忽略，登记过的新文件则会添加进仓库，同时任何现有文件上的改动也都会添加到仓库。这一行为跟Subversion的做法几乎是一模一样的。

真正的区别在于，在Subversion里，你的“即将发生的动作清单”永远是由当前工作树的状态决定的。在Git里，这个“即将发生的动作清单”则是索引里的内容，由它决定哪些内容将变成HEAD的下一个状态。在执行@code{commit}之前你都可以直接操作它们。这就给你增加了一层控制权，让你能通过提前登记改动来决定接下来发生的事情。

如果说得还不够清楚，请再考虑下面的例子：你有一个可信任的源文件，@code{foo.c}，然后你在上面做了两组互不相关的改动。你希望把这些改动拆开来分成两次提交，让它们有各自的描述。在Subversion里你需要这样做：

@verbatim{
$ svn diff foo.c > foo.patch
$ vi foo.patch
<编辑foo.patch，保留我希望晚点提交的内容>
$ patch -p1 -R < foo.patch  # 移除第二组改动
$ svn commit -m "First commit message"
$ patch -p1 < foo.patch  # 把剩下的改动重新加上
$ svn commit -m "Second commit message"
}

好玩吗？那你可以再来几次，找几组复杂的、各不相同的改动，多玩几次吧。下面是Git的版本，用到了索引：

@verbatim{
$ git add --patch foo.c
<选择我想要最先提交的部分>
$ git commit -m "First commit message"
$ git add foo.c  # 添加余下的改动
$ git commit -m "Second commit message"
}

这样简单多了！如果你喜欢Emacs，向你推荐最好的工具@code{gitsum.el}，由Christian Neukirchan编写，给这个原本可能会乏味的过程加上了漂亮的外衣。我最近用它把一组混在一起的改动拆分成11个独立的提交。多谢了，Christian！

@(footnotes2-1)

@section{让索引更进一步}

我想想，索引...通过它你可以提前登记一组改动，如此迭代地构建起一个补丁，最后再提交到仓库。嗯，我好像在哪儿听过这个概念...

如果你想到了“Quilt!@notes2-2{译注：Quilt也是一个可以追踪源码变化的源码管理软件，它把这些变动称为“补丁”。Quilt可以选取任意数量的补丁组合成为一个，其好处是在最终永久保存进源代码之前，能方便地让其它程序员测试不同部分的改动。}”，恭喜你答对了。实际上，索引与Quilt有一点点不同，它增加了这个约束：同一时刻只允许创建一个补丁。

如果，在@code{foo.c}文件里我不是有两组改动，而是有四组呢？用纯的Git，我必须把每一组单独摘出来，提交，然后再摘出下一组。使用索引的话这个过程已经变得容易多了，但如果我在提交之前希望以不同的组合来测试这几组改动呢？就是说，假设我把这几个补丁分别标记为A，B，C，D，现在我希望测试A+B，然后测试A+C，然后是A+D，等等等等，才能最终认为各组改动是真的完成了呢？

在Git里面是没有这种机制让你并行地混编组合出多个改动集的。当然，多个分支可以让你并行地开发，而且索引也允许你把多个改动组合进一系列提交里，但你无法两件事情同时做：注册一系列的补丁，同时为了在最终提交之前验证补丁之间的一致性，选择性地启用或者禁用其中的某一些。想要做类似这样的事情，你需要的是一个允许多重深度提交的索引。这件事情已经由Stacked Git完成了。

下面是我用纯Git提交两个不同的补丁：

@verbatim{
$ git add -i # 选择第一组改动
$ git commit -m "First commit message"
$ git add -i # 选择第二组改动
$ git commit -m "Second commit message"
}

这没问题，但我想单独测试第二个commit，却没办法选择性的“禁用”第一个。我如果非要这么做的话只能这样：

@verbatim{
$ git log # 找到第一个提交的hash id
$ git checkout -b work <first commit’s hash id>
$ git cherry-pick <second commit’s hash id>
<... run tests ...>
$ git checkout master # 回到主“分支”
$ git branch -D work # 移除刚才的临时分支
}

当然必须得有比这更好的办法！用@code{stg}我可以把这两个补丁排成队列，再按照我希望的顺序重新使用它们，用来做独立测试或者组合测试等，都行。下面是用@code{stg}把前面例子中的同样两个补丁做成队列：

@verbatim{
$ stg new patch1
$ git add -i  # 选择第一组改动
$ stg refresh --index
$ stg new patch2
$ git add -i  # 选择第二组改动
$ stg refresh --index
}

现在如果我想禁用第一个补丁，好单独测试第二个的话，就很明朗了：

@verbatim{
$ stg applied
patch1
patch2
<...  测试两个补丁同时存在的情况 ...>
$ stg pop patch1
<...  测试仅补丁2存在的情况 ...>
$ stg pop patch2
$ stg push patch1
<...  测试仅补丁1存在的情况 ...>
$ stg push -a
$ stg commit -a  # 提交所有补丁
}

这绝对比“创建临时分支、用@code{cherry-pick}来选择指定提交的哈希id、最后删除临时分支”要容易多了。

@(footnotes2-2)
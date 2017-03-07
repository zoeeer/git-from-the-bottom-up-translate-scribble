#lang scribble/manual

@title[#:tag "introduction"]{引言}

欢迎来到Git的世界。Git是一个功能强大的内容跟踪系统。希望这份文档能帮助你加深对它的理解，让你感受到它底层设计的那份简洁 --- 哪怕它长长的选项列表看起来挺晕的。

开始之前，先列出一些术语名称，它们将在文中反复出现：

@itemlist[
	@item{
		@bold{代码仓库（repository）}--- 一个@bold{代码仓库}就是一系列@italic{提交（commits）}的集合，也就是一个项目在某个特定时间点的@italic{工作树（working tree）}所呈现的样子，不过工作目录可能在你的机器上，也可能在别人的机器上。仓库还会维护一个HEAD（见下），用来标识当前工作树截止的分支（branch）或提交（commit）位置。最后，仓库还包含所有的分支（branches）和标签（tags），它们用来命名某些特定的提交。
		}
	@item{
		@bold{索引（the index）}--- 与其它的版本管理工具不同，Git在提交代码的时候不是直接把@italic{工作树（working tree）}上的改动提交到仓库里，而是先把改动记录到一个叫做“@bold{索引（the index）}”的地方。你可以把它看成一个在最终提交（commit）之前可以挨个确认每处改动的机制，而提交则会把所有确认过的改动一次性全记录到仓库中。因此有些人把index称为“暂存区（staging area）”，也许更易于理解。
	}
	@item{
		@bold{工作树（working tree）}--- @bold{工作树}是你文件系统上的任意一个与@italic{代码仓库（repository）}关联起来的目录（典型的判断方法是看它是否包含一个名为.git的子目录）。工作树包括该目录里的所有文件及子目录。
	}
	@item{
		@bold{提交（commit）}--- 一个@bold{提交}是你的工作树在某一时间点的快照。产生提交前一刻的HEAD（见下）就变成了当前提交的父节点。“变更历史”就这样产生了。
	}
	@item{
		@bold{分支（branch）}--- 一个@bold{分支}仅仅是某个commit的一个名字（马上会对commits做详细的介绍）。分支也称为引用（reference），它总是指向开发的某一支的最后一个子节点（是一个commit），由该commit开始一个个回溯父commit串联起来的就是这一支的开发历史，这就形成了所谓的“开发的分支”。
	}
	@item{
		@bold{标签（tag）}--- 一个@bold{标签（tag）}也是某个commit的一个名字，与@italic{分支（branch）}差不多，只不过同一个标签总是指向同一个commit（译注：branch指向的是该分支的最后一个commit，在该分支提交新的commit的时候会自动指向这个新的commit），还有就是标签可以带一段描述文字。
	}
	@item{
		@bold{主分支（master）}--- 在大部分仓库里，开发的主线都在一个叫做“@bold{master}”的分支上完成。其实这就是默认分支的名字，没有什么特别的。
	}
	@item{
		@bold{头部（HEAD）}--- HEAD用来标识一个仓库里当前检出（checked out）的内容：
		@itemlist[
			@item{
				如果你检出（checkout）了一个分支（branch），HEAD这个符号就会指向这个分支，并且随后所做的提交会更新到这个分支上，也就是该分支名指向的commit会更新为这个新的commit。
			}
			@item{
				如果你检出（checkout）的是一个特定的提交（commit），HEAD就仅仅指向这个提交了。这时候它称为“分离的@italic{头部}（detached @italic{HEAD}）”。举例来说，当你检出一个标签名的时候就会出现这种情况。
			}
		]
	}
]

@para{
通常的流程是这样的：创建一个仓库，然后在工作树上展开你的工作。一旦你的工作到达了某个重要的点---可能是有个bug修复完成了，可能是一天的工作结束了，可能是所有东西通过了编译---你接连把这些改动添加到索引（the index）里。当索引里包含了你想要提交的全部内容，你就把索引的内容记录到仓库。下面用一个简单的图表来展示典型的项目生命周期：
}

@image["images/lifecycle.png"]

有了这幅基本的图景，接下来的章节将阐述图中各部分分别是怎样在Git中扮演重要角色的。

@bold{LICENSE}: 本文档遵循@hyperlink["https://creativecommons.org/licenses/by/4.0/legalcode"]{Creative Commons BY 4.0 license}许可。若想将本文翻译为其它语言，注明出处即可。

#lang scribble/manual

@(require scriblib/footnote)

@(define-footnote notes footnotes)
@(define-footnote notes2 footnotes2)
@(define-footnote notes3 footnotes3)
@(define-footnote notes4 footnotes4)
@(define-footnote notes5 footnotes5)


@title[#:tag "repository"]{代码仓库（repository）}

@section[#:tag "directory-content-tracking"]{代码仓库：目录里的内容追踪}

前面已经提过，Git做的是一件很原始的事情：为目录里的内容维护一系列快照。确认了这一基本任务，Git的很多内部设计就比较好理解了。

Git代码仓库的设计在多方面看起来都是比照着Unix文件系统的结构来的：@italic{文件系统}从一个根目录展开，根目录包含其它目录，多数目录里还包含叶节点，即@italic{文件}，文件存放着数据。关于文件内容的元数据（meta-data）存储在两类位置：文件名存储在该文件所在的目录文件中；文件的大小、文件类型、权限等信息则存储在指向这个文件的i-node@notes{译注：@hyperlink["https://zh.wikipedia.org/wiki/Inode"]{i-node}是Unix文件系统使用的一种数据结构}中。每个i-node都有一个唯一的编号用来标识它所关联的文件内容。你可能会有多个目录条目指向同一个i-node（即硬链接，hard links），但文件系统上真正“保管”文件内容的是这个i-node。

Git的内部设计与上述结构惊人地相似，尽管有一两个关键的区别。首先，文件的内容存放在一些@italic{二进制对象（blob）}@notes{译注：blob--- Binary Large OBject (BLOB) }中，作为@italic{树结构（tree）}的叶节点，对应于文件系统中的文件。而Git的@italic{树}的跟文件系统的目录结构如出一辙。然后，正如i-node以系统分配的编号来唯一标识，这里的blob是以SHA1算法对其大小和内容计算得到的哈希id来命名。这样做的意图没有别的，就是要生成一个值，就像i-node，但还多了另外两个属性：第一，这个值可以验证blob的内容永远不变；第二，同样的内容永远会由一摸一样的blob来保存，不管它出现在哪儿（比如在不同的commits里，不同的repository里，甚至在互联网上的任何地方）。如果有多棵树引用了同样名字的blob，就相当于是硬连接（hard-linking）：blob不会从你的代码仓库消失，只要还有至少一个链接指向它。

Git的blob和文件系统的文件有一个区别是，blob不存储关于自己内容的元数据（metadata）。所有这类信息都在blob所在的树上。可能有一棵树知道这个blob是一个名为“foo”的文件，它创建于2004年8月，而另一棵树可能认为同样的blob是一个名为“bar”的文件，而且创建时间在5年之后。然而在正常的文件系统里，类似这样的两个内容完全相同但元信息不同的文件一定是以两个独立的文件存在的。为什么会有这样的区别？主要原因是，文件系统设计成这样是为了支持文件的变化，但Git不用。Git仓库里保存的数据都是不可变的@notes{译注：Git保存的都是文件快照}，这一特点导致Git需要不同的设计。而这样设计结果还带来了别的好处，即存储空间大大节省，因为所有拥有同样内容的对象都可以共享同一份存储，不管它出现在仓库的什么位置。


@(footnotes)


@section[#:tag "introducing-the-blob"]{blob的介绍}

基本的图景已经描绘出来了，下面我们来看几个实际的例子。首先我要创建一个Git仓库作为样例，在这个仓库里我将会自底向上地展示Git是怎么工作的。你可以一边阅读一边跟着操作：

@;codeblock{
@verbatim{
$ mkdir sample; cd sample
$ echo 'Hello, world!' > greeting
}

这里我在文件系统上创建了一个名叫“sample”的目录，目录里包含了一个文件，文件内容很无趣，你们已经看出来了。到目前为止我还没有创建代码仓库，但是我已经可以开始使用Git的一些命令了，通过这些命令我们就能理解Git会做些什么。首先，我想要知道Git会给我的greeting文本分配个什么样的hash id：

@verbatim{
$ git hash-object greeting
af5626b4a114abcb82d63db7c8082c3c4756e51b
}

如果你在你的系统上运行这个命令，你会得到跟上面一样的hash id值。尽管我们创建的是两个不同的代码仓库（说不定相隔一个世界呢），这两个仓库里我们的greeting blob却有同一个hash id。我还有可能从你的代码仓库拉取（pull）提交到我的仓库里，这样的话Git会发现我们追踪的是同样的内容---因此只会为它存储一份拷贝！酷。下一步就是初始化一个新的仓库并且把这个文件提交进去。现在我会把这些工作一步完成，待会儿再回来分步骤地再做一次，这样你就明白这里面发生了什么了：

@verbatim{
$ git init
$ git add greeting
$ git commit -m "Added my greeting"
}

到这里我们这个blob应该已经按照我们所期望的在系统里边了，名字用的是上面计算出来的那个hash id。为了方便，Git只要求输入hash id的开头若干位数字，只要足够在当前仓库里足够唯一标识出即可。通常前面六七位就够了：

@verbatim{
$ git cat-file -t af5626b
blob
$ git cat-file blob af5626b
Hello, world!
}

看，就是它了！我还没有查看它是由哪个commit保存，或者是在哪棵树里边，但是仅仅从内容来看我已经可以假定它在那儿了，而它确实在。不管这个代码仓库存在了多长时间，也不管这个文件在仓库里的什么位置，我一定能得到这个一摸一样的id。因此这份特定的内容已经被永久地保护起来了，随时可以验证。

如此，Git里用blob来表示最基本的数据单元，而整个系统实际上就是关于blob的管理。

@section[#:tag "blobs-are-stored-in-trees"]{Blobs存储在树结构中}

你的文件内容存储在blob里，但这些blob基本上没有什么特征。没有文件名，没有结构---毕竟它们只是“二进制对象”。

为了让Git表示出你的文件名称和组织关系，Git把blob作为叶子与树结构挂钩。现在我单凭查看我的blob是找不出它挂在哪棵树（或哪些树）上的，它可能有很多很多所有者。但我可以确定在我刚刚提交的commit里的某个位置一定有它：

$verbatim{
$ git ls-tree HEAD
100644 blob af5626b4a114abcb82d63db7c8082c3c4756e51b greeting
}

找到啦！这是这个仓库的第一个提交，它刚才把我的greeting文件添加到仓库里了。这个commit包含了一棵Git树，这棵树有唯一一个叶节点：greeting文件的内容的blob。

虽然我通过ls-tree命令查看HEAD就已经找到了包含有我的blob的树，但我还没看明白这个树对象是怎么被那个commit索引出来的。这里有另外几个命令可以显明这个树和commit的区别：

@verbatim|{
$ git rev-parse HEAD
588483b99a46342501d99e3f10630cfc1219ea32 # 你的系统上会得到不同的结果

$ git cat-file -t HEAD
commit

$ git cat-file commit HEAD
tree 0563f77d884e4f79ce95117e2d686d7d6e282887
author John Wiegley <johnw@newartisans.com> 1209512110 -0400
committer John Wiegley <johnw@newartisans.com> 1209512110 -0400
Added my greeting
}|

第一个命令反向解析出HEAD这个别名所指向的commit，第二个命令查看其类型，第三个命令展示了该commit底下对应的树的hash id，以及存储在commit对象中的其它信息。我这个仓库里该commit的hash id与你的是不一样的---因为commit信息里包含了作者名字、提交日期等信息---但是这里边树的hash id我和你得到的应该是一样的，因为它包含了同样内容、同样名字的文件的blob。

我们再来验证一下这是同一个树对象：

@verbatim{
$ git ls-tree 0563f77
100644 blob af5626b4a114abcb82d63db7c8082c3c4756e51b greeting
}

如你所见：我的仓库里包含仅一个commit，它指向一棵树，树保管着一个blob---blob包含了我想要记录的内容。下面再运行一个命令，来验证上述情况确实无误：

@verbatim{
$ find .git/objects -type f | sort
.git/objects/05/63f77d884e4f79ce95117e2d686d7d6e282887
.git/objects/58/8483b99a46342501d99e3f10630cfc1219ea32
.git/objects/af/5626b4a114abcb82d63db7c8082c3c4756e51b
}

从这个输出我发现我的整个repo里面包含了3个对象，其中每个对象的hash id都在前面几个例子里出现过了。最后，仅仅为了满足好奇心，让我们再看一眼这些对象分别是什么类型：

@verbatim{
$ git cat-file -t 588483b99a46342501d99e3f10630cfc1219ea32
commit
$ git cat-file -t 0563f77d884e4f79ce95117e2d686d7d6e282887
tree
$ git cat-file -t af5626b4a114abcb82d63db7c8082c3c4756e51b
blob
}

在这个时候我本来可以用git的show命令来查看这每个对象的内容简述，不过还是作为练习留给读者吧。



@section[#:tag "how-trees-are-made"]{树结构如何生成}

每个commit掌管一棵且仅一棵树，不过树是如何生成的？我们知道blob是通过把你的文件内容填进blob来创建的---而树掌管blob---但我们还没看见承载blob的树是如何生成的，或者树是怎样与其父commit链接起来的。

我们来重新创建一个新的样例仓库，但这次要一步一步地手工操作，这样你就能感受到这里面究竟发生了什么：

@verbatim{
$ rm -fr greeting .git
$ echo 'Hello, world!' > greeting
$ git init
$ git add greeting
}

一切都从你第一次向索引（the index）里添加文件开始。先这么说，索引是你用来从文件造出blob的一个地方。我在上面用git add命令添加greeting文件的时候，我的仓库里就产生了一个变化。我暂时还看不见这个变化与commit有什么关系，但用下面的办法我可以看出发生了什么：

@verbatim{
$ git log # 该命令会报错，因为还没有做过提交（commits）
fatal: bad default revision 'HEAD'
$ git ls-files --stage # 列出当前索引（即暂存区）里的内容
100644 af5626b4a114abcb82d63db7c8082c3c4756e51b 0 greeting
}

这是啥？我什么都还没提交（commit），但这儿已经有一个对象生成了。它的hash id跟我最开始得到的那个hash id是一样的，所以我知道它代表着我的greeting文件。这里我可以对这个hash id用cat-file -t来查看其类型，会发现它是一个blob。事实上它就是跟我第一次创建的样例仓库里得到的那个blob完全一样。同样的文件一定会得到同样的blob（总担心强调得不够）。

这个blob目前还没有被哪棵树引用，也不在任何一个commit里。这时候只有一个文件引用了它，就是.git/index，该文件指向那些组成当前索引的blob和树。那现在我们就来创建一棵树，好把我们的blob挂上去：

@verbatim{
$ git write-tree # 将当前索引的内容写入一棵树
0563f77d884e4f79ce95117e2d686d7d6e282887
}

这个值也应该看着眼熟：包含同样blob（以及子树）的树，永远会有同样的hash id。我现在还没有commit对象，但现在这个仓库里已经有一棵树包含着我们的blob了。这个很底层的命令，write-tree，作用是把索引（the index）里包含的内容，不管是些啥，全塞进一棵新的树里，用于创建commit。

直接使用这个树对象，我就能手工创建一个commit对象了，这就是commit-tree命令做的事情：

@verbatim{
$ echo "Initial commit" | git commit-tree 0563f77
5f1bc85745dcccce6121494fdd37658cb4ad441f
}

这个很糙的commit-tree命令，以一棵树的hash id作为入参，生成一个commit对象来持有这棵树。如果我希望这个commit有一个父提交，我需要用 -p 选项把父提交的hash id传给它。另外，注意这里的hash id就跟你机器上出现的不一样了：这是因为我的commit对象包含了我的名字、我创建commit的日期，这两个细节信息一定是与你的不同的。

我们的工作还没完，呐，因为我还没有把这个commit注册为哪个分支（branch）的头部（HEAD）：

@verbatim{
$ echo 5f1bc85745dcccce6121494fdd37658cb4ad441f > .git/refs/heads/master
}

该命令告诉Git：名为“主干（master）”的分支现在应该指向最近的这个提交了。不过，另一个更加安全的做法是用update-ref命令：

@verbatim{
$ git update-ref refs/heads/master 5f1bc857
}

刚才我们创建了@code{master}分支，我们得把它跟当前工作树（working tree）关联起来。正常来说这件事情是在你检出（checkout）一个分支的时候发生的：

@verbatim{
$ git symbolic-ref HEAD refs/heads/master
}

这个命令把HEAD符号与主分支（master branch）关联起来了。这个很重要，因为将来从工作树（working tree）发出的任何提交都可以自动更新@code{refs/heads/master}的值了。

啊，难以置信整件事情我们已经做完了，就这么简单，现在我可以用log命令查看我亲手铸就的commit了：

@verbatim|{
$ git log
commit 5f1bc85745dcccce6121494fdd37658cb4ad441f
Author: John Wiegley <johnw@newartisans.com>
Date:   Mon Apr 14 11:14:58 2008 -0400
        Initial commit
}|

解释一下：如果我没有把@code{refs/heads/master}设置为指向我的新提交，那这个提交是“够不着的”，因为现在没有任何东西指向它，并且它也不是任何一个“可触及的”提交的父提交。如果出现这种情况了，这个commit对象会在某个时候被从仓库里移除掉，同时它所掌管的树以及书上的所有blob都会被移除。（这件事情是一个名为gc@notes2{译注：garbage collection，垃圾回收程序}的命令自动完成的，这个命令基本上不用手工使用）。像我们上面那样把commit链接到@code{refs/heads}里的一个名字，它就成为一个可触及的提交了，也就确保了从现在起它会被好好保存的。


@(footnotes2)


@section[#:tag "the-beauty-of-commits"]{提交之美}

有些版本管理系统把“分支”做成了很神奇的东西，通常把它们跟“主线”或者“树干“明显区分开来，或者把“分支”认为是与commits非常不同的概念。然而在Git里，并没有分支这种专门的实体：只有二进制对象（blobs），树结构（trees）和提交（commits）。由于commit可以有一个或多个父提交，这些父提交还可以有父提交，这种组织关系使得一个单独的commit就可以被看作一个分支：因为它可以回溯出得到这个commit的全部历史信息。

你可以随时查看所有在顶层（top-level）被引用的提交，用@code{branch}命令：

@verbatim{
$ git branch -v
* master 5f1bc85 Initial commit
}

来跟我念：分支不是别的，只不过是对某个commit的命名引用。在这个意义上，分支（branches）与标签（tags）是等价的，唯一的区别是标签可以带有描述信息（正如commit可以带有描述信息）。分支仅仅是名字，但标签是描述性的，呐，“标签”嘛。

但其实别名完全不是必需的。举个例子，如果我愿意，我只需要用commits的hash id就可以索引到仓库里的所有东西了。好，我直接来个最机车的，把我工作树（working tree）的头部（head）重置为某个特定的commit：

@verbatim{
$ git reset --hard 5f1bc85
}

@code{--hard}选项的意思是，清除我当前工作树里现存的所有改动，无视它们是否已注册为要检入（checkin）的内容@notes3{译注：即进入“索引（the index）”，也即暂存区}（稍后还会介绍该命令）。做同样这件事情更安全的办法是用@code{checkout}：

@verbatim{
$ git checkout 5f1bc85
}

区别是当前工作树里改动过的文件会被保留。如果给@code{checkout}加上@code{-f}选项，在这个例子里他就跟@code{reset --hard}的行为一样了，除了checkout仅仅改变工作树，而@code{reset --hard}还会改变当前分支的HEAD，让它指向指定的那个版本。

这个基于提交的系统（commit-based system）还有个令人愉悦的地方：哪怕你遇到最复杂的情况你也可以避开那些繁复的版本管理术语了，现在只用最简单的词汇就能表述。比如，如果一个commit有多个父提交，那么这是一个“合并提交（merged commit）”---因为它把多个commit合并为一个。还有，如果一个commit有多个孩子，就意味着它是某个“分支”的始祖（ancestor of a “branch”），等等。对Git来说这些东西真没什么区别：整个世界不过是一系列commit对象的集合，每个commit掌握一棵树，树又指向其它树和二进制对象（blobs），二进制对象存储着你的数据。任何比这更复杂的都不过是一些所谓命名系统做的事情了。

下面这幅图展示这些碎片是怎么组合到一起的：

@image["images/commits.png"]

@(footnotes3)



@section[#:tag "a-commit-by-any-other-name"]{提交的别名们}


理解提交是掌握Git的关键。当你脑子里只有提交的拓扑结构，而把那些让人困惑的分支啦、标签啦、本地和远端仓库啦，等等统统抛开的时候，你就知道你已到达了智慧的禅之高原。好在这种程度的理解不需要你自断手臂。。。不过你若正在考虑的话我觉得你很可以。

如果commits是钥匙，那怎么称呼commits就是通往大师水平的门道了。有很多很多方法来称呼commits、某个范围的commits、甚至称呼commits底下的某些对象，这些称呼方式能被绝大多数的Git命令接受。这里总结了一些最基本的：

@itemlist[
	@item{
	@bold{分支名（branchname）}---前面已经说了，分支的名字只不过就是该“分支”上最新一个commit的别名。用这个称呼跟该分支检出时候的HEAD效果是一样的。
	}
	@item{
	@bold{标签名}---用标签别名指代一个commit，和用分支别名指代一个commit，在“指代”这个意义上两者是等价的。两者的主要区别在于，标签别名永远不变，而分支别名在每次该分支有新commit检入时会跟着改变。
	}
	@item{
	@bold{HEAD}---当前检出的commit永远叫HEAD。如果你签出了一个特定的commit---而不是一个分支名---那么HEAD就仅仅指向该commit而不指向任何分支。注意这是一个比较特殊的情况，也称为“使用分离的头部（using a detached HEAD)”（我敢说此处应有一个笑话...）@notes4{译注：不知道什么梗，有知道的欢迎告诉我}。
	}
	@item{
	@bold{c82a22c39cbc32...}---一个提交永远可以用它自己的40位完整SHA1哈希id来指代。这通常只在复制粘贴的时候用到，因为一般都会有别的更方便的方法来指代同一个提交。
	}
	@item{
	@bold{c82a22c}---你只需要用hash id的前几位就可以了，位数足以在仓库里唯一标识出你要的东西就行。大部分时候六到七位足够了。
	}
	@item{
	@bold{name^}---用尖号表示任一commit的父提交。如果某个提交有不止一个父提交，尖号索引的是第一个。
	}
	@item{
	@bold{name^^}---尖号可以叠加使用。该别名指向给定名字的提交的“父亲的父亲”。
	}
	@item{
	@bold{name^2}---如果一个提交有多个父提交（比如合并提交），你可以用@code{name^n}来指代第n个父提交。
	}
	@item{
	@bold{name~10}---一个提交的第n级祖先可以用波浪号（~）接一个序号来表示。这类使用在@code{rebase -i}命令里很常见，比如，“给我看看最近的一连串提交”。该别名跟@code{name^^^^^^^^^^}是一样的。
	}
	@item{
	@bold{name:path}---要指代一个提交所包含的树里的某个特定文件，可以在冒号后面指定（带完整路径的）文件名。这在show命令里很有用，或者用来展示一个文件在两个已提交版本之间的diff：
		@verbatim{
		$ git diff HEAD^1:Makefile HEAD^2:Makefile
		}
	}
	@item{
	@bold{name^{tree}}---你可以直接指代commit所掌管的树，略过commit本身。
	}
	@item{
	@bold{name1..name2}---这个别名和下一个都是用来指代@italic{提交范围（commit ranges）}的，这在类似log的命令中相当有用，可以查看某个特定的时间区间里发生了什么。左边的语法指代的是，从@bold{name2}回溯到（但不包含）@bold{name1}，中间所有可触及的提交。如果省略@bold{name1}或者@bold{name2}，省略处自动以HEAD替代。
	}
	@item{
	@bold{name1...name2}---“三连点”表示的范围不同于上面的两点版本。对于像@code{log}这样的命令，它指向@bold{name1}或者@bold{name2}两者引用的所有的提交的集合，但要去掉两者同时引用的那些。它的结果是这两个分支里面包含的所有不交叉的提交。对于像@code{diff}这样的命令，该范围表示的是@bold{name2}和@bold{name1}与@bold{name2}共同祖先之间的那些提交。这与@code{log}的区别在于，由@bold{name1}引入的改动不会显示出来。
	}
	@item{
	@bold{master..}---等价于“@code{master..HEAD}”。尽管前面的例子已经包含了这种情况，我还是把它加到这儿，因为我自己在查看对当前分支的改动的时候一直使用这类别名。
	}
	@item{
	@bold{..master}---和上面类似，在你完成一次@code{fetch}之后、想查看你上次@code{rebase}或@code{merge}之后发生了哪些变化，这时这个别名就非常有用了。
	}
	@item{
	@bold{@code{--since="2 weeks ago"}}---指向某个日期起往后的所有提交。
	}
	@item{
	@bold{@code{--until="1 week ago"}}---指向截止到某个日期往前的所有提交。
	}
	@item{
	@bold{@code{--grep=pattern}}---指向提交信息与正则表达式匹配的所有提交。
	}
	@item{
	@bold{@code{--committer=pattern}}---指向提交者（committer）匹配正则表达式的所有提交。
	}
	@item{
	@bold{@code{--author=pattern}}---指向作者（author）匹配正则表达式的所有提交。commit的作者是指创建该commit中改动的那个人，对于本地开发这个人就是提交者（committer），但在通过电子邮件发送补丁（patches）的时候，“作者”与“提交者”通常是不同的人。
	}
	@item{
	@bold{@code{--no-merges}}---指向所有只有一个父提交的提交，也就是忽略所有合并提交（merge commits）。
	}
]

以上大部分选项都可以组合与匹配使用。下面的例子用来查看满足如下条件的所有日志条目：过去一个月之内，由我自己添加的，在当前分支（从master分出来的一支）做的改动，且commit信息中包含“foo”：

@verbatim{
$ git log --grep='foo' --author='johnw' --since="1 month ago" master..
}

@(footnotes4)



@section[#:tag "branching-and-the-power-of-rebase"]{分支，以及强大的rebase命令}

Git里用来操作commits的命令中，有个名字很不起眼的rebase命令是最厉害的之一。从根本上讲，你开发的每一个分支都有一个或多个“基础提交（base commit）”：分支就是从这个（或若干个）commits开始分出来的。下图是一个很典型的场景。注意箭头是往时间更早的方向指的，因为每个提交里包含其父提交的信息，可以索引出其父提交，而非子提交。所以图中D和Z两个提交代表着各自分支的头部（head）。

@image["images/branching.png"]

按照这个例子，运行branch命令会列出两个“头部”：D和Z，而两个分支的共同祖先是A。@code{show-branch}命令给我们展示的正是上图所示的信息：

@verbatim{
$ git branch
  Z
* D

$ git show-branch
! [Z] Z
 * [D] D
--
 * [D] D
 * [D^] C
 * [D~2] B
+  [Z]Z
+  [Z^]Y
+  [Z~2] X
+  [Z~3] W
+* [D~3] A
}

阅读该输出需要习惯一下，不过本质上它跟上面的示意图没有区别。它告诉我们以下信息：

@itemlist[
	@item{
	当前所在分支最初的分叉点是提交@code{A}（也叫@code{D~3}，甚至@code{Z~4}，只要你愿意）。注意@code{commit^}语法是指向commit的父提交，而@code{commit~3}指向它的第三代父亲，也就是曾祖父。
	}
	@item{
	从底下往上看，左起第一列（那几个加号）表示一个分支Z，分支上有四个提交：W，X，Y，Z。
	}
	@item{
	第二列（那几个星号）表示当前分支上的提交，也就是B，C，D这三个。
	}
	@item{
	输出的顶部---以分割线与底下隔开的部分，标出了各个分支名，以及每个分支的commits分别由哪一列、哪个字符为标志标出。
	}
]

现在我们想做一件事情：把Z重新带回主分支D上，让它跟上D的进度。换句话说，我们想要把B，C，D所做的工作同步到分支Z中。

在别的版本控制系统里类似的事情只能用“分支合并”的方法来完成。在Git里用@code{merge}命令也可以实现分支合并。如果Z是一个已经发布出去的版本，我们不想改变其提交历史，这个时候还是需要用到@code{merge}的：

@verbatim{
$ git checkout Z # 切换到分支Z
$ git merge D # 把B，C，D提交的内容合并到分支Z中
}

执行之后，代码仓库变成这样：

@image["images/branch-merge.png"]

之后我们再检出Z分支，它就已经包含了之前的Z commit（现在应表示为Z^）与D的内容合并后的结果。（但要注意：现实中的merge操作如果D和Z有冲突的话，系统会要求先解决冲突）。

现在新的Z已经包含了D带过来的改动了，但现在出现了一个新的commit专门代表Z与D的合并：即当前表示为Z’的提交。这个提交没有添加任何新东西，仅仅表示完成了把D与Z合并到一起这一工作。某种意义上说它是一个“中继提交（meta-commit）@notes5{译注：类似meta-data是“关于数据的数据”，这里meta-commit可以理解为“关于提交的提交”}”，因为它的内容仅仅属于代码仓库内部完成的事情，并不涉及到工作树（working tree）里的任何工作。

但是，有一个办法，可以把Z分支直接移栽到D上，有效地将它在时间里前移：就用我们强大的rebase命令。下图是我们的目标：

@image["images/rebase.png"]

图示的形态最直接地表明了我们想要完成的事情：我们本地开发的Z分支，要让它变成是在主分支D的基础上做的改动。所以该命令叫做rebase（重新定基），因它改变的是分支所基于的基础提交（base commit）。如果你反复运行该命令，你可以连续得到一系列补丁，它们保证是主分支的最新版本的补丁，而且你不用给你开发中的分支增加额外的合并提交。下面是要运行的命令，请与前面的merge操作进行对比：

@verbatim{
$ git checkout Z # 切换到Z分支
$ git rebase D # 将Z的基础提交指向D
}

为什么该操作只适用于本地分支？因为你每次rebase，都有潜在的可能会改变该分支里的每一个commit。之前，@code{W}是基于@code{A}的，它里面只包含从@code{A}变成@code{W}的变换。然而在rebase之后，@code{W}会被重写，以保证它包含所有从@code{D}到@code{W’}需要的变换。更甚，从@code{W}到@code{X}的变换也变了，因为刚才的@code{A+W+X}现在是@code{D+W’+X’}了---如此等等。假如这是一个其他人也可见的分支，而且你的任何一个下游用户从Z上分出了他自己的的本地分支，那它们的分支现在还指向旧的@code{Z}，而不是新的@code{Z’}。

一般来说，你可以遵循这个规则：当你有一个本地分支、且没有从该分支分出别的分支的时候，用rebase，其它情况都用merge。此外merge还在你要把你的本地分支拉回（pull back）进主分支的时候有用。

@(footnotes5)

@section[#:tag "interactive-rebasing"]{交互式rebase}

上面的例子里运行rebase的时候，它自动重写从@code{W}到@code{Z}的所有提交，以保证Z分支变成以D提交（即D分支的head）为基准的分支。不过，你是可以全权控制该重写过程的。如果给@code{rebase}命令加上@code{-i}选项，系统会弹出一个编辑窗口，让你选择对本地Z分支的每个commit分别做什么操作：

@itemlist[

	@item{
	@bold{选中（pick）}---这是默认行为，如果不进入交互模式的话每个提交都选这个。它表示当前询问的commit需要以它的（已重写的）父提交作为基准来重写。对每个有冲突的提交，@code{rebase}命令会提供机会让你解决冲突。
	}
	@item{
	@bold{挤压（squash）}---一个被“挤压”的提交将把它的内容“折叠”进它的前面一个提交里。可以挤压任意多次。还用上面的例子，如果你挤压所有提交（第一个除外，第一个必须被@bold{选中（pick）}后面才有@bold{挤压（squash）}的地方），那么你得到的新Z分支就仅仅包含一个提交，从@code{D}长出来。适用于你的改动分散在多个提交里、但你希望改写提交历史让这些改动都放在一个提交里。
	}
	@item{
	@bold{编辑（edit）}---若你把某个提交标记为@bold{编辑（edit）}，rebase程序会在该提交处停下来，把当前工作树设置为该提交并且把shell交给你。索引（the index）已经注册上了你运行@code{commit}时需要包含的所有改动。这样你就可以改变任何你想改变的东西：修正一个改动，撤销一个改动，等等；提交之后，你再运行@code{rebase --continue}，该提交就已改写完成，看起来像最初就是这样提交的一样。
	}
	@item{
	@bold{（抛弃）(drop)}---如果你在rebase交互模式的文件中把一个commit移除了，或是注释掉了，很简单，这个commmit就消失了，就像从来没提交过一样。注意这可能会引起merge冲突，如果你后面有提交依赖于这些改动的话。
	}
]

该命令的强大之处你很难一开始就欣赏，但它已经赋予了你对任意分支的形状有无限掌控的能力。你可以用它来：

@itemlist[

	@item{把多个提交缩合为一个提交。}
	@item{改变提交的先后顺序。}
	@item{当你后悔了，移除错误的改动。}
	@item{把你分支的基点更改为@italic{代码仓库中的任一提交}。}
	@item{修改个别提交，在事情发生很久之后修正当时的改动。}

]

推荐大家现在阅读一下@code{rebase}的手册（man page），里面有几个很好的例子，告诉你如何释放出这匹猛兽的真正力量。最后再让你感受一下这一工具的潜力，请看下面这个场景，想一想如果有一天你想把分支@code{L}迁移到@code{Z}上变成@code{Z}的新头部，你会怎么做：

@image["images/rebasing-branches-1.png"]

上图可以这样来看：我们的开发主线是D，在D往前推三个commit的时候开启了一个尝试性的分支，即现在的Z。在这期间的某个时候，当时C和X分别是它们各自分支的头部，这时我们决定启动另一个尝试性分支，即后来的L。现在我们发现L的代码挺好的，但还不足以合并到主线上，所以我们决定把L上面的改动转移到正在开发的分支Z上，让整个改动看起来像是在同一个分支上完成的。噢，我们还想快速地编辑一下J，就改一下版权日期，因为之前做改动的时候忘了时间是2008！下面的命令帮助我们解开这个结：

@verbatim{
$ git checkout L
$ git rebase -i Z
}

可能需要处理一些冲突。最后我们的仓库变成了这样：

@image["images/rebasing-branches-2.png"]

看到了吧，只要是本地开发，rebase让你有无限的控制权，完全地掌控仓库里的commits呈现成什么样子。
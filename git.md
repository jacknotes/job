#Git教程


##一、Git简单操作
####输入帐户信息
1. git config --global user.name "git-name"    --输入帐户名
2. 
git config --global user.email "git-email"   ----输入邮箱名

####创建一个版本库和工作区
1. $ mkdir learngit   --创建一个工作区为learngit目录
2. $ cd learngit ;  $ git init  --初始化learngit目录，使目录下生成.git子目录,.git子目录为版本库，版本库不可随意更改
3. 用Notepad++或者Markdown来代替Windows系统中的word和记事本书写代码和信息，因为windows的东西不能在github上使用

####把文件添加,提交到仓库
1. git add readme.txt  --用命令git add告诉Git，把文件添加到仓库
2. git commit -m "wrote a readme file"   --提交到仓库，并添加提交的文件说明

亦可添加多个文件并提交多个文件，例：
<pre>
$ git add file1.txt
$ git add file2.txt file3.txt
$ git commit -m "add 3 files."
</pre>	

##二、Git版本回退
1. $ git log    --用此命令查看提交的记录日志
	<pre>
	commit 1094adb7b9b3807259d8cb349e7df1d4d6477073 (HEAD -> master)
	Author: Michael Liao <askxuefeng@gmail.com>
	Date:   Fri May 18 21:06:15 2018 +0800
	
	    append GPL
	
	commit e475afc93c209a690c39c13a46716e8fa000c366
	Author: Michael Liao <askxuefeng@gmail.com>
	Date:   Fri May 18 21:03:36 2018 +0800
	
	    add distributed
	
	commit eaadf4e385e865d25c48e7ca9c8395c3f7dfaef0
	Author: Michael Liao <askxuefeng@gmail.com>
	Date:   Fri May 18 20:59:18 2018 +0800
	
	    wrote a readme file
	</pre>
注：如果嫌输出信息太多，看得眼花缭乱的，可以试试加上--pretty=oneline参数：
	<pre>
	$ git log --pretty=oneline
	1094adb7b9b3807259d8cb349e7df1d4d6477073 (HEAD -> master) append GPL
	e475afc93c209a690c39c13a46716e8fa000c366 add distributed
	eaadf4e385e865d25c48e7ca9c8395c3f7dfaef0 wrote a readme file
	</pre>
2. $ git reset --hard HEAD^   --回到上一次提交的版本
3. 只要上面的命令行窗口还没有被关掉，你就可以顺着往上找啊找啊，找到那个append GPL的commit id是1094adb...，于是就可以指定回到未来的某个版本,版本号没必要写全，前几位就可以了，Git会自动去找。当然也不能只写前一两位，因为Git可能会找到多个版本号，就无法确定是哪一个了:	

	`$ git reset --hard 1094a`   
	`HEAD is now at 83b0afe append GPL`
4. Git的版本回退速度非常快，因为Git在内部有个指向当前版本的HEAD指针，当你回退版本的时候，Git仅仅是把HEAD从指向append GPL：
现在，你回退到了某个版本，关掉了电脑，第二天早上就后悔了，想恢复到新版本怎么办？找不到新版本的commit id怎么办？
在Git中，总是有后悔药可以吃的。当你用$ git reset --hard HEAD^回退到add distributed版本时，再想恢复到append GPL，就必须找到append GPL的commit id。Git提供了一个命令git reflog用来记录你的每一次命令：
	<pre>
	$ git reflog
	e475afc HEAD@{1}: reset: moving to HEAD^
	1094adb (HEAD -> master) HEAD@{2}: commit: append GPL
	e475afc HEAD@{3}: commit: add distributed
	eaadf4e HEAD@{4}: commit (initial): wrote a readme file
	</pre>
终于舒了口气，从输出可知，append GPL的commit id是1094adb，现在，你又可以乘坐时光机回到未来了。
######总结：
* HEAD指向的版本就是当前版本，因此，Git允许我们在版本的历史之间穿梭，使用命令git reset --hard commit_id。
* 穿梭前，用git log可以查看提交历史，以便确定要回退到哪个版本。
* 要重返未来，用git reflog查看命令历史，以便确定要回到未来的哪个版本。

##版本库
**说明：**

1. 工作区有一个隐藏目录.git，这个不算工作区，而是Git的版本库。
Git的版本库里存了很多东西，其中最重要的就是称为stage（或者叫index）的暂存区，还有Git为我们自动创建的第一个分支master，以及指向master的一个指针叫HEAD。

2. 前面讲了我们把文件往Git版本库里添加的时候，是分两步执行的：
第一步是用git add把文件添加进去，实际上就是把文件修改添加到暂存区；
第二步是用git commit提交更改，实际上就是把暂存区的所有内容提交到当前分支。
因为我们创建Git版本库时，Git自动为我们创建了唯一一个master分支，所以，现在，git commit就是往master分支上提交更改。
你可以简单理解为，需要提交的文件修改通通放到暂存区，然后，一次性提交暂存区的所有修改。
3. 工作区和暂存区的区别：

.git目录下是版本库，库内有index文件，这个文件是暂存区，是当你合作git add file.name 添加文件后放进去时使用的，当你git commit -m “desctiption” 时，这才把内容提交到当前分支，这个当前分支是当时我们创建Git版本库时，Git就为我们创建了唯一一个master分支，在.git目录的目录就是工作区。

####管理修改：
当你用git add命令后，在工作区的第一次修改被放入暂存区，准备提交，但是，在工作区的第二次修改并没有放入暂存区，所以，git commit只负责把暂存区的修改提交了，也就是第一次的修改被提交了，第二次的修改不会被提交。
提交后，用git diff HEAD -- readme.txt命令可以查看工作区和版本库里面最新版本的区别：
<pre>
$ git diff HEAD -- readme.txt 
diff --git a/readme.txt b/readme.txt
index 76d770f..a9c5755 100644
--- a/readme.txt
+++ b/readme.txt
@@ -1,4 +1,4 @@
 Git is a distributed version control system.
 Git is free software distributed under the GPL.
 Git has a mutable index called stage.
-Git tracks changes.
+Git tracks changes of files.
</pre>可见，第二次修改确实没有被提交。

####撤销修改：
* 场景1：当你改乱了工作区某个文件的内容，想直接丢弃工作区的修改时，用命令git checkout -- file。
* 场景2：当你不但改乱了工作区某个文件的内容，还添加到了暂存区时，想丢弃修改，分两步，第一步用命令git reset HEAD <file>，就回到了场景1，第二步按场景1操作。
* 场景3：已经提交了不合适的修改到版本库时，想要撤销本次提交，参考版本回退一节，不过前提是没有推送到远程库

####删除文件：
另一种情况是删错了，因为版本库里还有呢，所以可以很轻松地把误删的文件恢复到最新版本：

	`$ git checkout -- test.txt`
git checkout其实是用版本库里的版本替换工作区的版本，无论工作区是修改还是删除，都可以“一键还原”。

命令git rm用于删除一个文件。如果一个文件已经被提交到版本库，那么你永远不用担心误删，但是要小心，你只能恢复文件到最新版本，你会丢失最近一次提交后你修改的内容。

##将本地库添加到远程库
1. 首先用ssh-keygen -t rsa 生成用户密钥，然后把生成的公钥信息复制添加到你的github网站帐户上，路径：your profile---edit profile---SSH and GPG keys---New SSH keys
2. 使用命令：连接远程github帐户:
	<pre>git remote add origin git@github.com:jackli5689/learngit.git
	git remote add origin https://github.com/jackli5689/learngit.git
	-----两种方法都可以，ssh协议比http协议更快
	</pre>
3. 使用命令：推送存储库数据到远程库：
	`git push -u origin master`
##从远程库克隆到本地库
<pre>git clone git@github.com:jackli5689/gitskiils.git
cd gitskiils.git
ls</pre>

	注意事项：
		* 要克隆一个仓库，首先必须知道仓库的地址，然后使用git clone命令克隆。
		* 当你直接使用git rm test.txt删除远程库的内容时，这时不会直接更新，当你在下次git push origin master时才会触发更新。

##创建与合并分支
说明：创建与合并分支他们之间的交替主要是指针

####创建分支
1.创建一个分支并切换到新建分支，例如dev
<pre>
$ git checkout -b dev  
Switched to a new branch 'dev'
git checkout命令加上-b参数表示创建并切换，相当于以下两条命令:
$ git branch dev
$ git checkout dev
Switched to branch 'dev'
</pre>
2.用git branch命令查看当前分支：
<pre>
$ git branch
* dev
  master

创建与合并分支
在版本回退里，你已经知道，每次提交，Git都把它们串成一条时间线，这条时间线就是一个分支。截止到目前，只有一条时间线，在Git里，这个分支叫主分支，即master分支。HEAD严格来说不是指向提交，而是指向master，master才是指向提交的，所以，HEAD指向的就是当前分支。

一开始的时候，master分支是一条线，Git用master指向最新的提交，再用HEAD指向master，就能确定当前分支，以及当前分支的提交点：

git-br-initial

每次提交，master分支都会向前移动一步，这样，随着你不断提交，master分支的线也越来越长：

 当我们创建新的分支，例如dev时，Git新建了一个指针叫dev，指向master相同的提交，再把HEAD指向dev，就表示当前分支在dev上：

git-br-create

你看，Git创建一个分支很快，因为除了增加一个dev指针，改改HEAD的指向，工作区的文件都没有任何变化！

不过，从现在开始，对工作区的修改和提交就是针对dev分支了，比如新提交一次后，dev指针往前移动一步，而master指针不变：

git-br-dev-fd

假如我们在dev上的工作完成了，就可以把dev合并到master上。Git怎么合并呢？最简单的方法，就是直接把master指向dev的当前提交，就完成了合并：

git-br-ff-merge

所以Git合并分支也很快！就改改指针，工作区内容也不变！

合并完分支后，甚至可以删除dev分支。删除dev分支就是把dev指针给删掉，删掉后，我们就剩下了一条master分支：

git-br-rm

真是太神奇了，你看得出来有些提交是通过分支完成的吗？

 下面开始实战。

首先，我们创建dev分支，然后切换到dev分支：
$ git checkout -b dev
Switched to a new branch 'dev'

git checkout命令加上-b参数表示创建并切换，相当于以下两条命令：
$ git branch dev     --新建分支
$ git checkout dev   --切换分支
Switched to branch 'dev'

然后，用git branch命令查看当前分支：
$ git branch   --查看分支
* dev
  master

git branch命令会列出所有分支，当前分支前面会标一个*号。
然后，我们就可以在dev分支上正常提交，比如对readme.txt做个修改，加上一行：
Creating a new branch is quick.
然后提交：

$ git add readme.txt 
$ git commit -m "branch test"
[dev b17d20e] branch test
 1 file changed, 1 insertion(+)
现在，dev分支的工作完成，我们就可以切换回master分支：

$ git checkout master
Switched to branch 'master'
切换回master分支后，再查看一个readme.txt文件，刚才添加的内容不见了！因为那个提交是在dev分支上，而master分支此刻的提交点并没有变：
</pre>

####合并分支
现在，我们把dev分支的工作成果合并到master分支上：
<pre>
$ git merge dev
Updating d46f35e..b17d20e
Fast-forward
 readme.txt | 1 +
 1 file changed, 1 insertion(+)

git merge命令用于合并指定分支到当前分支。合并后，再查看readme.txt的内容，就可以看到，和dev分支的最新提交是完全一样的。
注意到上面的Fast-forward信息，Git告诉我们，这次合并是“快进模式”，也就是直接把master指向dev的当前提交，所以合并速度非常快。
当然，也不是每次合并都能Fast-forward，我们后面会讲其他方式的合并。
合并完成后，就可以放心地删除dev分支了：
$ git branch -d dev
Deleted branch dev (was b17d20e).

删除后，查看branch，就只剩下master分支了：
$ git branch
* master
* 因为创建、合并和删除分支非常快，所以Git鼓励你使用分支完成某个任务，合并后再删掉分支，这和直接在master分支上工作效果是一样的，但过程更安全。
</pre>

分支小结:
创建与合并分支
在版本回退里，你已经知道，每次提交，Git都把它们串成一条时间线，这条时间线就是一个分支。截止到目前，只有一条时间线，在Git里，这个分支叫主分支，即master分支。HEAD严格来说不是指向提交，而是指向master，master才是指向提交的，所以，HEAD指向的就是当前分支。


**小结**

Git鼓励大量使用分支：

查看分支：git branch

创建分支：git branch name

切换分支：git checkout name

创建+切换分支：git checkout -b name

合并某分支到当前分支：git merge name

删除分支：git branch -d name

####解决冲突
<pre>
$ git log --graph --pretty=oneline --abbrev-commit
*   5356e1b (HEAD -> master) merge with no-ff
|\
| * 47c7caa (dev) new readme.txt
|/
*   6771e8c (feature1) conflict fixed
|\
| * ce3742a AND simple
* | b199770 & simple
|/
* ab3ab8d branch test
* 2e7ba55 (origin/master) retry readme.txt
* 7a96a6a add jack.txt
* 8f08ae1 add test.txt
* d743dad git tracks changes
* 2693527 append GPL
* 67517e2 wrote a readme file
</pre>
小结

当git无法自动合并分支时，就必须首先解决冲突。解决冲突后，再提交，合并完成。

解决冲突就是把Git的合并失败的文件手动编辑为我们希望的内容，再提交。

用git log --graph命令可以看到分支合并图产品。


####分支管理策略

通常，合并分支时，如果可能，Git会用Fast forward模式，但这种模式下，删除分支后，会丢掉分支信息。

如果要强制禁用Fast forward模式，Git就会在merge时生成一个新的commit，这样，从分支历史上就可以看出分支信息。

<pre>
首先，仍然创建并切换dev分支：

$ git checkout -b dev
Switched to a new branch 'dev'
修改readme.txt文件，并提交一个新的commit：

$ git add readme.txt 
$ git commit -m "add merge"
[dev f52c633] add merge
 1 file changed, 1 insertion(+)
现在，我们切换回master：

$ git checkout master
Switched to branch 'master'
准备合并dev分支，请注意--no-ff参数，表示禁用Fast forward：

$ git merge --no-ff -m "merge with no-ff" dev
Merge made by the 'recursive' strategy.
 readme.txt | 1 +
 1 file changed, 1 insertion(+)
因为本次合并要创建一个新的commit，所以加上-m参数，把commit描述写进去。

合并后，我们用git log看看分支历史：

$ git log --graph --pretty=oneline --abbrev-commit
*   e1e9c68 (HEAD -> master) merge with no-ff
|\  
| * f52c633 (dev) add merge
|/  
*   cf810e4 conflict fixed
...
</pre>


小结

Git分支十分强大，在团队开发中应该充分应用。

合并分支时，加上--no-ff参数就可以用普通模式合并，合并后的历史有分支，能看出来曾经做过合并，而fast forward合并就看不出来曾经做过合并。

###错误分支
<pre>
git stash    --保存当前的工作状态，等需要时可拿出来，
原计划两个小时的缺陷修复只花了5分钟！现在接着回到dev分支干活了！

$ git checkout dev
Switched to branch 'dev'

$ git status
On branch dev
nothing to commit, working tree clean
？工作区是干净的，的刚才工作现场存到哪去了用git stash list命令看看：

$ git stash list
stash@{0}: WIP on dev: f52c633 add merge
工作现场还在，Git的把藏匿内容存在某个地方了，但是需要恢复一下，有两个办法：

用一是git stash apply恢复，但是恢复后，藏匿内容并不删除，需要你用git stash drop来删除;

另一种方式是用git stash pop，恢复的同时把藏匿内容也删了：

$ git stash pop
On branch dev
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

    new file:   hello.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

    modified:   readme.txt

Dropped refs/stash@{0} (5d677e2ee266f39ea296182fb2354265b91b3b2a)
再用git stash list查看，就看不到任何藏匿内容了：

$ git stash list
你可以多次藏匿处，恢复的时候，用先git stash list查看，然后恢复指定的藏匿处，用命令：

$ git stash apply stash@{0}   --恢复指定的保存工作列表

git branch -d branchname    --删除本地分支
git push origin --delete branchname   --删除远端分支

</pre>

小结

修复错误时，我们会通过创建新的错误分支进行修复，然后合并，最后删除;

当手头工作没有完成时，工作先把现场git stash一下，然后去修复的bug，修复后，再git stash pop，回到工作现场。


####多人协作
<pre>
当你从远程仓库克隆时，实际上Git自动把本地的master分支和远程master分支对应起来了，并且，远程仓库的默认名称是origin。

要查看远程库的信息，用git remote：
$ git remote
origin
或者，用git remote -v显示更详细的信息：

$ git remote -v
origin  git@github.com:michaelliao/learngit.git (fetch)
origin  git@github.com:michaelliao/learngit.git (push)
显示上面抓取推送的origin的地址。如果没有推送权限，就看不到推的地址。
</pre>

#####推送分支
<pre>
推送分支，就是把该分支上的所有本地提交推送到远程库时，要指定本地分支，这样，Git的就会把该分支推送到远程库对应的远程分支上：
$ git push origin master

如果要推送其他分支，比如dev，就改成：
$ git push origin dev

但是，并不是一定要把本地分支往远程推送，那么，哪些分支需要推送，哪些不需要呢？

master分支是主分支，因此要时刻与远程同步;

dev分支是开发分支，团队所有成员都需要在上面工作，所以也需要与远程同步;

错误分支只用于在本地修复错误，就没必要推到远程了，除非老板要看看你每周到底修复了几个错误;

设有分支是否推到远程，取决于你是否和你的小伙伴合作在上面开发。

总之，就是在git中，分支完全可以在本地自己藏着玩，是否推送，视你的心情而定！

抓取分支
多人协作时，都会大家往master和dev分支上推送各自的修改。

现在，模拟一个你的小伙伴，可以在另一台电脑（注意要把SSH Key添加到GitHub）或者同一台电脑的另一个目录下克隆：

$ git clone git@github.com:michaelliao/learngit.git
Cloning into 'learngit'...
remote: Counting objects: 40, done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 40 (delta 14), reused 40 (delta 14), pack-reused 0
Receiving objects: 100% (40/40), done.
Resolving deltas: 100% (14/14), done.
当你的小伙伴从远程库的克隆时，默认情况下，你的小伙伴只能看到本地的master分支，不信可以用git branch命令看看：

$ git branch
* master
现在，你的小伙伴要在dev分支上开发，必须就创建远程origin的dev分支到本地，他于是用这个命令创建本地dev分支：
$ git checkout -b dev origin/dev

现在，他就可以在dev上继续修改，然后，时不时地把dev分支push到远程：
$ git add env.txt

$ git commit -m "add env"
[dev 7a5e5dd] add env
 1 file changed, 1 insertion(+)
 create mode 100644 env.txt

$ git push origin dev
Counting objects: 3, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 308 bytes | 308.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To github.com:michaelliao/learngit.git
   f52c633..7a5e5dd  dev -> dev
 的你小伙伴已经向origin/dev分支推送了他的提交，而碰巧你也对同样的文件作了修改，并试图推送：

$ cat env.txt
env

$ git add env.txt

$ git commit -m "add new env"
[dev 7bd91f1] add new env
 1 file changed, 1 insertion(+)
 create mode 100644 env.txt

$ git push origin dev
To github.com:michaelliao/learngit.git
 ! [rejected]        dev -> dev (non-fast-forward)
error: failed to push some refs to 'git@github.com:michaelliao/learngit.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. Integrate the remote changes (e.g.
hint: 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
推送失败，因为你的小伙伴的最新提交和你试图推送的提交有冲突，解决办法也很简单，GIT中已经提示我们，先用git pull把最新的提交从origin/dev抓下来，然后，在本地合并，解决冲突，再推送：

$ git pull
There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> dev
git pull也失败了，原因没有指定本地dev分支与远程origin/dev分支的链接，根据提示，设置dev状语从句：origin/dev的链接：

$ git branch --set-upstream-to=origin/dev dev
Branch 'dev' set up to track remote branch 'dev' from 'origin'.
再拉：

$ git pull
Auto-merging env.txt
CONFLICT (add/add): Merge conflict in env.txt
Automatic merge failed; fix conflicts and then commit the result.
这回git pull成功，但是合并有冲突，需要手动解决，解决的方法：分支管理中的冲突完全一样解决后，提交，再推动：

$ git commit -m "fix env conflict"
[dev 57c53ab] fix env conflict

$ git push origin dev
Counting objects: 6, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (6/6), 621 bytes | 621.00 KiB/s, done.
Total 6 (delta 0), reused 0 (delta 0)
To github.com:michaelliao/learngit.git
   7a5e5dd..57c53ab  dev -> dev

####多人协作流程
* 因此，多人协作的工作模式通常是这样：
* 首先，试图可以用git push origin <branch-name>推送自己的修改;
如果推送失败，则因为远程分支比你的本地更新，先需要用git pull试图合并;
* 如果合并有冲突，则解决冲突，并在本地提交;
* 没有冲突或者解决掉冲突后，再用git push origin <branch-name>推送就能成功！
* 如果git pull提示no tracking information，则说明本地分支和远程分支的链接关系没有创建，用命令git branch --set-upstream-to <branch-name> origin/<branch-name>。

这就是多人协作的工作模式，一旦熟悉了，就非常简单。


小结
查看远程库信息，使用git remote -v;

本地新建的分支如果不推送到远程，对其他人就是不可见的;

从本地推送分支，使用git push origin branch-name，如果推送失败，用先git pull抓取远程的新提交;

在本地创建和远程分支对应的分支，使用git checkout -b branch-name origin/branch-name，本地和远程分支的名称最好一致;

建立本地分支和远程分支的关联，使用git branch --set-upstream branch-name origin/branch-name;

从远程抓取分支，使用git pull，如果有冲突，要先处理冲突。
</pre>

<pre>
##简要步骤
####输入帐户信息
1. git config --global user.name "git-name"    --输入帐户名
2. git config --global user.email "git-email"   ----输入邮箱名
3. $ mkdir learngit   --创建一个工作区为learngit目录
4. $ cd learngit ;  $ git init  --初始化learngit目录，使目录下生成.git子目录,.git子目录为版本库，版本库不可随意更改
5. git add readme.txt  --用命令git add告诉Git，把推送数据到远程库
6. git commit -m "wrote a readme file"   --提交到仓库，并添加提交的文件说明
7. git push origin master  --推送分支
8. git log    --用此命令查看提交的记录日志 
9. git log  --pretty=oneline
10. git reset --hard HEAD^   --回到上一次提交的版本
11. git reset --hard 1094a`  --回到指定的id版本
12. git reflog  --关掉了电脑可用此命令查看日志
13. git diff HEAD -- readme.txt命令可以查看工作区和版本库里面最新版本的区别
14. git checkout -- file  --当你改乱了工作区某个文件的内容，想直接丢弃工作区的修改,可使用指命令回到上一次提交（commit）的版本状态，首先你得提交过版本
15. git reset HEAD <file>当你不但改乱了工作区某个文件的内容，还添加到了暂存区时，想丢弃修改，分两步，第一步用命令git reset HEAD <file>，就回到了场景1，第二步按场景1操作。
16. ##将本地库添加到远程库
1. 首先用ssh-keygen -t rsa 生成用户密钥，然后把生成的公钥信息复制添加到你的github网站帐户上，路径：your profile---edit profile---SSH and GPG keys---New SSH keys
2. 使用命令：连接远程github帐户:
	<pre>git remote add origin git@github.com:jackli5689/learngit.git
	git remote add origin https://github.com/jackli5689/learngit.git </pre>
	-----两种方法都可以，ssh协议比http协议更快
17. git clone git@github.com:jackli5689/gitskiils.git  --克隆仓库
18. 当你直接使用git rm test.txt删除远程库的内容时，这时不会直接更新，当你在下次git push origin master时才会触发更新
19. git checkout -b dev --创建分支并切换分支
20. git branch  --查看当前分支
21. git branch dev  --新建分支
22. git checkout dev  --切换分支
23. git merge dev  --合并分支，合并其他分支的工作内容到当前分支
24. git branch -d dev --删除分支
25. ###解决冲突：当git无法自动合并分支时，就必须首先解决冲突。解决冲突后，再提交，合并完成。
26. 通常，合并分支时，如果可能，Git会用Fast forward模式，但这种模式下，删除分支后，会丢掉分支信息。
如果要强制禁用Fast forward模式，Git就会在merge时生成一个新的commit，这样，从分支历史上就可以看出分支信息
27. git merge --no-ff -m "merge with no-ff" dev  --准备合并dev分支，请注意--no-ff参数，表示禁用Fast forward，因为本次合并要创建一个新的commit，所以加上-m参数，把commit描述写进去。
28.###错误分支
 1. git stash    --保存当前的工作状态，等需要时可拿出来，
 2.  git checkout dev  --切换分支
 3. git status  --回到之前的分支，找回保存的工作状态
 4. git stash list --列出保存的工作状态
 5. git stash apply --恢复，但是恢复后，藏匿内容并不删除，需要你用git stash drop来删除
 6. git stash pop --恢复的同时把藏匿内容也删了
28. git remote --查看远程库的信息
29. git remote -v  --查看详细远程库的信息
30. git pull --用git pull把最新的提交从origin/dev抓下来，然后，在本地合并，解决冲突，再推送
31. git branch --set-upstream-to=origin/dev dev  -------git pull也失败了，原因没有指定本地dev分支与远程origin/dev分支的链接，根据提示，设置dev状语从句：origin/dev的链接
32. git pull   ---这git pull成功，但是合并有冲突，需要手动解决，解决的方法：分支管理中的冲突完全一样解决后，提交，再推动


####多人协作流程
* 因此，多人协作的工作模式通常是这样：
* 首先，试图可以用git push origin <branch-name>推送自己的修改;
如果推送失败，则因为远程分支比你的本地更新，先需要用git pull试图合并;
* 如果合并有冲突，则解决冲突，并在本地提交;
* 没有冲突或者解决掉冲突后，再用git push origin <branch-name>推送就能成功！
* 如果git pull提示no tracking information，则说明本地分支和远程分支的链接关系没有创建，用命令git branch --set-upstream-to <branch-name> origin/<branch-name>。

git branch -a  #查看多个分支
git pull origin release:master  #从远程仓库origin的release分支同步信息到本地的master分支
git push origin dev:release  #从本地当前分支dev推送信息到远程仓库的release分支
#git有两种代码获取认证方式，一种是基于ssh的key，另一种是基于http的用户名和密码。

</pre>

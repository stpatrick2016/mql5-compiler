# Introduction 
VSTS (TFS) build task to compile MQL5 projects and files inside TFS builds.

# How to use
The extension is not published in marketplace (yet), so there are only those options to use it:
* Download the extension from [releases tab](https://github.com/stpatrick2016/mql5-compiler/releases) and upload it into your VSO. You will have to create a publisher account for that (free).
* Write me and tell me your organization name and I will share it with you. This is the one that preceeding @visualstudio.com, for example, if your VSO's url is https://mywork.visualstudio.com, then your organization name is mywork. It is not a secret information (as far as I aware). The advantage of this approach is that you will automatically get updates.

# How to develop VSTS build tasks
To pack the extension (providing all prerequisites are installed, see links below), run this command from command line:
```
tfx extension create --manifest-globs vss-extension.json
```

### Useful links
* [How to create and package build task](https://docs.microsoft.com/en-us/vsts/extend/develop/add-build-task?view=vsts)
* [Example tasks](https://github.com/Microsoft/vsts-tasks/tree/master/Tasks)
* [Creating PowerShell tasks](https://github.com/Microsoft/vsts-task-lib/tree/master/powershell/Docs)

### Shell Data Transfer

Enhancements to Dolphin Smalltalk 7.2 to allow drag & drop and clipboard operations between Dolphin and external applications (Windows Explorer, Outlook etc.)

Based on DH Shell Data Transfer by Louis Sumbery and Steve Waring.

## Getting Started
* Install [Dolphin Smalltalk 7.2](https://github.com/dolphinsmalltalk/Dolphin)
* Download and install [GitHub Package Manager](https://github.com/rko281/GitHub)
* Evaluate:
```smalltalk
GitHubPackageManager install: 'rko281/ShellDataTransfer'.
```
* Example usage:
```smalltalk
"Do it"
ShellDragDropSample show
```
Opens an explorer-type view on a temporary directory of files.

Files can be drag & dropped to/from Windows Explorer or other applications (e.g. an Outlook message).
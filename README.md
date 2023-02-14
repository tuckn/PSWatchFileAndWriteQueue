# PSWatchFileEvent

Watch a directory and write event info on log files.

## Example

Handling an Excel file in OneDrive

```powershell
PS C:\> .\scripts\WatchFileEvent.ps1 -WatchingDir "C:\Users\USERNAME\notebooks\Excel" -FilteredName "*.xls*"
```

### 1. Create a new Book on a OneDrive folder

```powershell
[info] Tha path of log directory is "C:\Users\USERNAME\AppData\Local\Temp\PSWatchFileEvent_GUID"
[info] Start watching for changes to "C:\Users\USERNAME\notebooks\Excel"
....!
[info] 20230207T075931.030340 [Created] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < ""
!
[info] 20230207T075931.030340 [Deleted] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < ""
.!
[info] 20230207T075932.587027 [Created] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < ""
!
[info] 20230207T075933.183403 [Renamed] "C:\Users\USERNAME\notebooks\Excel\{B4849444-26DC-4D89-8B5D-2E4EF261D180}.tmp" < "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx"
!
[info] 20230207T075933.184403 [Renamed] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < "C:\Users\USERNAME\notebooks\Excel\~$Book1.tmp"
....................................!
```

Created 4 log files.

### 2. Close the Book with AutoSave On

```powershell
[info] 20230207T080123.030281 [Changed] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < ""
```

### 3. Open the Book, and edit it with AutoSave On

```powershell
[info] 20230207T080424.085003 [Renamed] "C:\Users\USERNAME\notebooks\Excel\{2368CE5C-DB74-415A-B2A8-6AD5E69778BA}.tmp" < "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx"
!
[info] 20230207T080424.085003 [Renamed] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < "C:\Users\USERNAME\notebooks\Excel\~$Book1.tmp"
```

Created 1 log file.
A save operation didn't use the Changed event. It was treated as two consecutive rename operations.

### 4. Edit the Book and save it without AutoSave Off

```powershell
[info] 20230207T080718.741760 [Renamed] "C:\Users\USERNAME\notebooks\Excel\{17EA83AD-3066-4C08-A7E4-A070927CB7E7}.tmp" < "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx"
!
[info] 20230207T080718.742760 [Renamed] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < "C:\Users\USERNAME\notebooks\Excel\~$Book1.tmp"
```

Created 2 log files.
Even in this case, the save operation did not use the Changed event.

### 5. Close the Book without AutoSave Off

```powershell
[info] 20230207T080814.455450 [Changed] "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx" < ""
```

Somehow the Changed event fired.🤔

### 6. Rename the Book

```powershell
[info] 20230207T080932.664360 [Renamed] "C:\Users\USERNAME\notebooks\Excel\Book1_renamed.xlsx" < "C:\Users\USERNAME\notebooks\Excel\Book1.xlsx"
```

### 7. Move the Book to a subfolder

`-IncludesSubdir` is OFF

```powershell
[info] 20230207T081050.847881 [Deleted] "C:\Users\USERNAME\notebooks\Excel\Book1_renamed.xlsx" < ""
```

`-IncludesSubdir` is ON

```powershell
PS C:\> .\scripts\WatchFileEvent.ps1 -WatchingDir "C:\Users\USERNAME\notebooks\Excel" -FilteredName "*.xls*" -IncludesSubdir
[info] Tha path of log directory is "C:\Users\Tuckn\AppData\Local\Temp\PSWatchFileEvent_GUID"
[info] Start watching for changes to "C:\Users\USERNAME\notebooks\Excel"
....!
[info] 20230207T081309.604496 [Deleted] "C:\Users\USERNAME\notebooks\Excel\Book1_renamed.xlsx" < ""
!
[info] 20230207T081309.605495 [Created] "C:\Users\USERNAME\notebooks\Excel\sub\Book1_renamed.xlsx" < ""
```

Created 2 log files.

### 8. Deleting the Book

```powershell
[info] 20230207T081416.211498 [Deleted] "C:\Users\USERNAME\notebooks\Excel\Book1_renamed.xlsx" < ""
```

# QuickSwitch
**Use opened file manager folders in File dialogs.**

QuickSwitch is an alternative to [Listary's QuickSwitch](https://www.youtube.com/watch?v=9T9-OtRVeUw) as that is abandoned.
<br />
<br />
### What does QuickSwitch do?

When in a file dialog, like Save As .. or Open ... , it can switch that dialog to any folder that is opened in a file manager.
Currently supported file managers: File Explorer, **Directory Opus**, Total Commander and XYPlorer.

QuickSwitch can do that in a couple of different ways:

- **QuickSwitch Menu mode**.
Out of the box, it will show you a list of opened folders to choose from.
When you select one of those, the file dialog will switch to the selected folder.
The menu will not be shown if there are no file manager folders to select from.
- **AutoSwitch mode**.
After selecting AutoSwitch from the menu, the menu will no longer be shown for that specific dialog, for example Notepad's Save As dialog.
From there on, when you Alt-Tab to the file manager and Alt-Tab back to the file dialog, The file dialog will automatically open the folder that was active in that file manager.
When the file manager was active before you open the file dialog, it will even open that folder straight away, without further needed action.
The keyboard shortcut Control-Q will still open the menu if you need it, for example to reconfigure what to do in this dialog.

- There is also an option **Never here**.
Select that setting to 'mute' QuickSwitch in that specific dialog.
Useful for example for webbrowser dialogs, as they already keep track of website/downloadfolder combinations.

- **AutoSwitch Exception**
AutoSwitch "calculates" the number of (hidden/normal) windows between the most recent used file manager and the file dialog. In 95% of the cases, this is 2 windows, like for example (1) Notepad's Open dialog, (2) Notepad itself and (3) File Explorer.
For the remaining 5%, you can follow these steps when AutoSwitch is unable "to do it's thing":
  - Open the unwilling file dialog.
(Nothing will happen as AutoSwitch doesn't understand/ miscalculates)
  - Press 'CTRL + Q'
  - Select *AutoSwitch exception* from the QuickSwitch menu
  - Follow the on-screen steps.

In short, this lets QuickSwitch figure out and learn what the correct "window-distance" is for this specific application/dialog combination.
The next time, that will be used. and AutoSwitch should work again.
<br />
<br />

## QuickSwitch is not finished yet ...
... but it should be fully functional in it's current form.

On the To-Do list for the near future are:
- Support for long paths ( longer than 259 characters)
- A better user interface. There will be a simplified menu with less 'technical' entries.
Suggestions are welcome.
- A different way to 'talk with' Total Commander an XYplorer
- A notification area (/system tray) menu, including icon
- Option to load at startup
<br />
<br />

## Limitations
- Windows 7 and up are supported. QuickSwitch will not run on lower versions.
- Can not get information from file managers that run elevated (as administrator) 
<br />
<br />

## Installation

- Download the QuickSwitch zip-file from the [releases](https://github.com/gepruts/QuickSwitch/releases/latest)
- Extract the zip-file containing QuickSwitch.exe to a folder
Note: QuickSwitch will write it's ini-file to that same folder, so you need write access there.
- That's all
<br />
<br />

## Running QuickSwitch

To start, run QuickSwitch.exe. It will stay quietly in the background, until you open a File Dialog.
To stop using QuickSwitch, right-click it's system tray icon - a white on green "H" - and choose **Exit**


# Motivation Behind The Plugin
I made this plugin to help me read code in big files. I'm sharing it in case it would also benefit someone else. 

# Installation (Godot 4.2)
1. close Godot Studio. Download the zip.
2. Move `addons/Reading Aid` folder from zip to `res://addons`.
3. Start Godot, turn on the plugin `Project Setting` => `Plugins` => check mark to turn it on

# Features
1. code background color
2. custom code fold/unfold in color blocks
3. view all variables, or tags such as TODO, or all enums
4. fold/unfold all func or #region
5. modify the plugin setting

## Code Background Color
To Aid your reading, the code background can be colored.

Color can be added by adding `#n?#` at the beginning of a line.

Format: `# number color #`

![](https://github.com/goatt1167/ReadingAid-Plugin/blob/main/demo/color%20demo.gif)

Examples:
- `#3y#` => YELLOW color for the 3 lines of code below the comment.
- `#4#` => without a color code, *default color* will be displayed
(default color can be changed in settings.gd)
- `y` = `YELLOW`, `g` = `GREEN`, `d` = `DARK`, `t` = `TEAL`, `i` = `INDIGO`, `r` = `RICD`, etc.

## Comment Color Widget
Convenience Widget by Holding down CTRL (Windows) or COMMAND (Mac).

![](https://github.com/goatt1167/ReadingAid-Plugin/blob/main/demo/widget%20demo.gif)

## Fold / Unfold Any Custom Region In Addition To Region Tags
This can be done through the widget

## View Keywords In Isolation (CTRL/META + E => Hotkey)
![](https://github.com/goatt1167/ReadingAid-Plugin/blob/main/demo/popup%20window.png)

You don't have to put variables in one place at the top.

You can instead put them near their related func and still view them in one place by this feature.

You can also place TODO anywhere, too.

### TIP: CTRL/META + Left Click to go to that line in main editor.

Putting related variables and func near to each other helps my memory. Viewing variables all together also helps my memory. Now I can have both.

## WARNING:
The custom fold/unfold will pollute the redo/undo space because it injects tags to the script and then deletes the tags.

## Modify Plugin Setting
The setting is just a GDScript class. You can
- change colors, and import new colors.
- change some behaviors
- future feature: hide buttons that you don't want to use.

# How I Use It
1. Color helps me visually, naturally.
2. Inside a long func, I divide it into sections with color, and collapse them as I read. The first comment line of the collapsed section tells me what that section of code does.
3. I color func signitures to indicate their role, such as helper func, signal func, or public func, etc.
4. As I mentioned before, I like to put variables near their user func, which makes it hard to look up variables as the scatter in the code. So I use the variable viewer to find them. The viewer also gather variable's comments if they are connected.
5. Also, I find TODO viewer quite helpful. Ctrl/Meta + Left Click will take me to the variable or TODO.

# Project State
Unfinished features and bugs exist. Issues and bug reports are welcomed. Suggestions and constructive criticisms are also welcomed. I'll appreciate it.

Have fun and have a productive day!

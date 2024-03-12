# Motivation Behind The Plugin
I made this plugin to help me read code in big files. I'm sharing it in case it would also benefit someone else. 

# Installation
1. download and save the `Reading Aid` folder under `res://addons/`.
2. Then turn on the plugin `Project Setting` => `Plugins` => check mark to turn it on

# Features
1. code background color.
2. custom region fold / unfold.
3. view all variables, or tags such as TODO, or all enums
4. fold/unfold all func or #region
5. modify the plugin setting

## Code Background Color.
To Aid your reading, the code background can be colored.
Color can be added by adding `#n?#` at the beginning of a line.
Format:
- `# number color #`
Examples:
- `#3y#` => YELLOW color for the 3 lines of code below the comment.
- `#4#` => without a color code, *default color* will be displayed
(default color can be changed in settings.gd)

## Comment Color Widget
Holding down CTRL (Windows) or COMMAND (Mac) to access the widget.

## Fold / Unfold Any Custom Region In Addition To Region Tags
This can be done through the widget

## View Keywords In Isolation
You don't have to put variables in one place at the top.
You can instead put them near their related func and still view them in one place by this feature.
You can also place TODO anywhere, too.

Putting related variables and func near to each other helps my memory. Viewing variables all together also help my memory. Now I can have both.

## Modify Plugin Setting
The setting is just a GDScript class. You can
- change colors, and import new colors.
- change some behaviors
- future feature: hide buttons that you don't want to use.

# Fontismo for iOS 2.0.0 #

*Fontismo* provides a means to install a selection of OpenType (`.otf`) and TrueType (`.ttf`) files on an iPad or iPhone. It requires iOS 13.0 or above.

![Fontismo App Store QR Code](qr-code.jpg)

## Usage ##

Please see [this page](https://smittytone.net/fontismo/index.html).

**Note** If you remove *Fontismo* from your iPad, all of the fonts installed by it will be removed by iOS.

## Compiling This App ##

This repo contains the Fontismo source code only. It does not contain assets required to complete the build, or to allow the app to function fully.

## Release Notes ##

- 2.0.0 *12 November 2024*
    - Support iOS 18 icons.
    - Add Filter menu for (iOS 14 and up only) to list fonts by typeface style, whether they are new to Fontismo, installed or uninstalled.
    - Show a non-dynamic preview for uninstalled fonts.
    - Show font creator(s) on the preview page.
    - Add optional automatic installation when an uninstalled font is previewed.
    - Add monospace fonts.
    - Bug fix: stop the main font list view's title from being shifted down on return from viewing a specific font.
    - Bug fix: stop the Help screen flashing white on first load.
    - Bug fix: correctly align the font list table's header text across rotations.
    - Spring clean dates, etc.
    - Re-organise the codebase.
- 1.2.2 *2 November 2023*
    - Fixed a bug in the feedback system preventing feedback being sent.
- 1.2.1 *20 January 2023*
    - Update copyright date.
- 1.2.0 *10 May 2022*
    - Added ten new fonts.
    - Optionally highlight the app’s new fonts. Default: true.
    - Separate help for iPhone and iPad versions.
    - Added a donations screen.
- 1.1.2 *21 February 2021*
    - Added ten new fonts.
    - Replace **Help** button with a menu to support addition of future features.
    - Allow the user to submit bug reports and feedback.
    - Make **Settings** text elements more stylistically consistent.
- 1.1.1 *2 October 2020*
    - Prevent scaling down of custom preview text from reverting to the alphabet and improve scaling code.
    - Add further usage advice to main window.
    - Add occasional App Store review prompts.
- 1.1.0 *25 September 2020*
    - iPhone support added.
    - New font preview UI: scalable sample is editable.
    - Use pinch-to-zoom to scale the sample text.
    - Bug fixes.
- 1.0.0 *May 2020*
    - Initial public release.

## Copyright ##

*Fontismo* is copyright &copy; 2024, Tony Smith.<br />The source code is available under the [MIT licence](LICENSE.md). Visual assets are not included under this licence.

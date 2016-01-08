## Loader.Swift 

This library allows you to easily add an FB style animated loading placeholder to your tableviews or collection views.

![Preview](http://g.recordit.co/xAV7KP5lCz.gif)

## Usage

```swift

Loader.addLoaderToTableView(self.tableView) 		// to add 
Loader.removeLoaderFromTableView(self.tableView)	// to remove

```

## How it works

It adds an animated gradient to the content views of the visible cells. After that it inserts a cutout view wherever all the other views are with "holes" where all the text and image views are. The alphas of all the text and image views are set to zero.

This is undone when you remove the loader.

## Credits

Props to the excellent deconstruction of the news feed loader here:
http://cloudcannon.com/deconstructions/2014/11/15/facebook-content-placeholder-deconstruction.html

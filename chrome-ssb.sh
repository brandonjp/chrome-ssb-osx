#!/bin/bash

## Original script 'chrome-ssb.sh' from https://github.com/lhl/chrome-ssb-osx

# White Space Trimming: http://codesnippets.joyent.com/posts/show/1816
trim() {
  local var=$1
  var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
  var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
  /bin/echo -n "$var"
}


### Get Input
## We'll have Automator return arguments in the order they're prompted
# /bin/echo "What should the Application be called?"
# read inputline
name=`trim "$1"`
# 
# /bin/echo "What is the url (e.g. https://www.google.com/calendar/render)?"
# read inputline
url=`trim "$2"`
# 
# /bin/echo "What is the full path to the icon (e.g. /Users/username/Desktop/icon.png)?"
# read inputline
icon=`trim "$3"`

# Ask user if they want desktop, tablet or mobile version of the site
# if [ "$4" == "3" ] ; then
# 	agent=`--use-mobile-user-agent`
# else if [ "$4" == "4" ] ; then
# 	agent=`--enable-request-tablet-site`
# else
# 	agent=``
# fi			


#### Find Chrome. If its not in the standard spot, try using spotlight.
chromePath="/Applications/Google Chrome.app"
if [ ! -d "$chromePath" ] ; then
    chromePath=`mdfind "kMDItemCFBundleIdentifier == 'com.google.Chrome'" | head -n 1`
    if [ -z "$chromePath" ] ; then
	/bin/echo "ERROR. Where is chrome installed?!?!"
	exit 1
    fi
fi
chromeExecPath="$chromePath/Contents/MacOS/Google Chrome"

# Let's make the app whereever we call the script from...
# appRoot=`/bin/pwd`
# Nah, let's put it on the desktop 
appRoot=`~/Desktop`

# various paths used when creating the app
resourcePath="$appRoot/$name.app/Contents/Resources"
execPath="$appRoot/$name.app/Contents/MacOS" 
profilePath="$appRoot/$name.app/Contents/Profile"
plistPath="$appRoot/$name.app/Contents/Info.plist"
versionsPath="$appRoot/$name.app/Contents/Versions"

# make the directories
/bin/mkdir -p  "$resourcePath" "$execPath" "$profilePath"

# convert the icon and copy into Resources
if [ -f "$icon" ] ; then
    if [ ${icon: -5} == ".icns" ] ; then
        /bin/cp "$icon" "$resourcePath/icon.icns"
    else
        sips -s format tiff "$icon" --out "$resourcePath/icon.tiff" --resampleWidth 128 >& /dev/null
        tiff2icns -noLarge "$resourcePath/icon.tiff" >& /dev/null
    fi
fi

### Create the wrapper executable
/bin/cat >"$execPath/$name" <<EOF
#!/bin/sh
iam="\$0"
profDir=\$(/usr/bin/dirname "\$iam")
profDir=\$(/usr/bin/dirname "\$profDir")
profDir="\$profDir/Profile"
exec '$chromeExecPath' --app="$url" --user-data-dir="\$profDir" "\$@"
EOF
/bin/chmod +x "$execPath/$name"

### create the Info.plist 
/bin/cat > "$plistPath" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" “http://www.apple.com/DTDs/PropertyList-1.0.dtd”>
<plist version=”1.0″>
<dict>
<key>CFBundleExecutable</key>
<string>$name</string>
<key>CFBundleName</key>
<string>$name</string>
<key>CFBundleIconFile</key>
<string>icon.icns</string>
<key>NSHighResolutionCapable</key>
<string>True</string>
</dict>
</plist>
EOF

### link the Versions directory
/bin/ln -s "$chromePath/Contents/Versions" "$versionsPath"

### create a default (en) localization to name the app
/bin/mkdir -p "$resourcePath/en.lproj"
/bin/cat > "$resourcePath/en.lproj/InfoPlist.strings" <<EOF
CFBundleDisplayName = "$name";
CFBundleName = "$name";
EOF

### tell the user where the app is located so that they can move it to
### /Applications if they wish
/bin/cat <<EOF
Finished! The app has been installed in 
$appRoot/$name.app
EOF

#!/bin/sh

# don fernandes
# cbc technologies llc
# oct 10, 2022
# tested on macos catalina 10.15.7

# quit system preferences to allow overwrite
osascript -e 'tell application "System Preferences" to quit'

# vars
endpoint=$(scutil --get ComputerName)
outputDirectory="/Users/Shared/"
transcriptName="$endpoint-auto-update-settings.txt"
outfile="$outputDirectory$transcriptName"
plist_file="/Library/Preferences/com.apple.SoftwareUpdate.plist"

date >> "$outfile"

# set access for current user
echo "\nSettingCurrentUserPrivileges\n" >> "$outfile"
sudo chown -R $(whoami) /usr/local/etc
chmod u+w /usr/local/etc

# install xcode
echo "\nInstalling xcode\n" >> "$outfile"
xcode-select --install

# deprecated installer #
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

## new installer ##
echo "\nInstalling Homebrew\n" >> "$outfile"
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

## apps ##
echo "\nInstalling Apps\n" >> "$outfile"

brew tap homebrew/cask.git
brew tap homebrew/cask
brew upgrade
brew update
brew cask install google-chrome
brew cask install firefox
brew cask install adobe-acrobat-reader
brew cask install vlc
brew cask install slack

## utilities
brew cask install appcleaner
brew cask install bbedit

## dev



## eclectic light tools ##
brew tap sticklerm3/pourhouse

brew cask install 32-bitcheck                 ## check for 32 bit apps
brew cask install bailiff                     ## menubar control of iCloud files
brew cask install blowhole                    ## cmd line write to unified log
brew cask install cirrus                      ## iCloud diagnostic tools
brew cask install deeptools                   ## preserve versioning on copies
brew cask install keychaincheck2              ## keychain diagnostics
brew cask install lockrattler                 ## detailed security checks
brew cask install permissionscanner           ## cmd line security checks
brew cask install signet                      ## scan and check bundle sigs
brew cask install silnite                     ## cmd line security checks
brew cask install systhist                    ## system and security update history

# brew cask install ulbow                       ## log browser
# brew cask install archichect                  ## check for big sur readiness
# brew cask install mints                       ## log toolbox
# brew cask install taccy                       ## privacy troubleshooting

brew cleanup

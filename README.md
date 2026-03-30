General information

#### Macrodroid ####
Install universal helper (note the adb parameter for installing on android 14+)
https://macrodroidforum.com/wiki/index.php/Helper_App

#### [F-Droid](https://f-droid.org/en/) ####  
All android packages related to termux - including termux itself - will need to be installed from F-Droid

#### [Termux](https://f-droid.org/en/packages/com.termux/)
The linux emulation layer that will let us run our ruby scripts. It, along with the subsequent items below, is needed so that scripts in Termux can be called from within MacroDroid.

Once Termux is installed, set up OpenSSH. The [Termux Wiki](https://wiki.termux.com/wiki/Remote_Access) has an excellent walk-thru on how to setup up public key authentication. Look for the section titled "Using the SSH Server"

__Note__, follow the section completely. You will need to set up password authentication fist.

#### Plugins
With Termux installed, we now install the following termux plugins using F-Droid:  
* [Termux API](https://f-droid.org/en/packages/com.termux.api/)
* [Termux Tasker](https://f-droid.org/en/packages/com.termux.tasker/)
 
#### Linux packages
We'll install these additional packages in our linux environment:
* git 
* ruby
* dart
* termux-api (the plugin requies it)
* vim
* wget
* jq

#### References ####
[This git page](https://gist.github.com/txoof/f7670b80e983582f7af6d1a7791c15ab) was a huge help in figuring out what I needed.

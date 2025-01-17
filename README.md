# Snitcher
Snitcher is a script that keeps the local network in check, and if any devices or network access goes offline, it will send a message to your telegram.

# Important
- Download just the Launcher, so it can create a shortcut with the icon configured and a path to use the .xlsx to import data from the devices you want to monitor.

# How to use
 - Create a Telegram Bot by talking to @BotFather
 - Save the token for later use.
 - Change the setting with this two BotFather commands
   
 - /setjoingroups - can your bot be added to groups?
 - /setprivacy - toggle privacy mode in groups
   
 - Send a message to your bot that you just created
 - Use the token that BotFather gave you and insert in the URL to adquire the ChatID https://api.telegram.org/bot[ BOT TOKEN ]/sendMessage and https://api.telegram.org/bot[BOT TOKEN]/getUpdates
 - Copy the Chat ID token
 - Place the Bot Token and Chat ID in the corresponding Variables at the beggining of the code.
 - $botToken = ""
 - $chatID = ""
 - Use the .xlsx to add many devices you want, the script will import those data and start to monitoring those devices. Don't forget to save it before executing the script.
 - Check for results

   # Note
   If the message fails, check Telegram Bot API Documetation, maybe is a missed setting that you must do.

   

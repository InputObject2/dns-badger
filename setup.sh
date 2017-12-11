#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   printf "This installer must be run as root\n" 
   exit 1
fi

printf "\nWelcome to the dns-badger setup!\n"
printf "Thank you for being part of the dnstrace initiative.\n"
printf "  With <3 always, Chris\n\n"

printf "What is the maximum dns-badger throughput? Any integer [5-95]\n"
printf "Here are some tuning suggestions to help you get started.\n"
printf "  [5-20] - You use Google DNS upstream and are running a similar project\n"
printf " [20-45] - You use Google DNS upstream and have several house companions\n"
printf " [45-70] - You do not use Google DNS upstream and want to take it easy\n"
printf " [70-95] - You do not use Google DNS upstream and want to go hard\n"
printf "Selection: "

read input
if [[ "$input" -ge 5 && "$input" -le 95 ]]; then
	echo "$input" > maxThroughput
else
	printf "That's not a number between 5 and 95\n"
	exit
fi

printf "\nWhat OS are we installing dns-badger on?\n"
printf " [1] - Debian/Raspbian\n"
printf " [2] - CentOS\n"
printf "Selection: "

read input
if [[ $input == "1" ]]; then
	printf "\n --- Updating and installing required packages... \n"
	apt-get update
	apt-get install -y php-cli curl php-curl php-json git unzip
elif [[ $input == "2" ]]; then
	printf "Not implemented yet, sorry :c\n"
	exit
else
	printf "Input invalid, please restart installer\n"
	exit
fi

user=$(stat -c '%U' setup.sh)
printf " --- Updating crontab for '$user'\n"

su -c 'crontab -l | { cat; echo "@reboot nohup bash $PWD/init.sh >> /tmp/dnsb-init.log 2>&1 &"; } | crontab -' $user
su -c 'crontab -l | { cat; echo "*/30 * * * * nohup php $PWD/reload.php >> /tmp/dnsb-rld.log 2>&1 &"; } | crontab -' $user

printf " --- Cloning dependencies from GitHub\n"
su -c 'mkdir $PWD/deps && git clone https://github.com/tweedge/phpqueues $PWD/deps/queues' $user

printf " --- Installing other dependencies via Composer\n"
su -c 'cd $PWD/deps && curl -sS https://getcomposer.org/installer | php' $user
su -c 'cd $PWD/deps && php composer.phar require layershifter/tld-extract' $user

printf " --- Creating extra files/folders/etc\n"
su -c 'mkdir $PWD/status' $user

printf " --- Generating and writing nodeID\n"
echo `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1` > nodeID

printf "\nWe're all set on this end. Thanks for waiting!\n"
printf "Please email Chris with the following ID:\n"
printf "  `cat nodeID`\n"
printf "We'll get your node activated ASAP, and send back your extended API key!\n"
printf "You'll need to restart before your node starts. Want to do that now? [y/n] "

read input
if [[ $input == "y" || $input == "Y" ]]; then
	shutdown -r now
else
	printf "Don't forget to do that sometime soon! Your node won't run until then.\n"
fi
printf '\033[0;34m%s\033[0m\n' "Upgrading The Scalora Theme"
cd "$ZSH/custom"
if git pull --rebase --stat origin master
then
  printf '\033[0;32m%s\033[0m\n' '                _                  '
  printf '\033[0;32m%s\033[0m\n' '  ___  ___ __ _| | ___  _ __ __ _  '
  printf '\033[0;32m%s\033[0m\n' ' / __|/ __/ _` | |/ _ \| |__/ _` | '
  printf '\033[0;32m%s\033[0m\n' ' \__ \ ❨_| ❨_| | | ❨_❩ | | | ❨_| | '
  printf '\033[0;32m%s\033[0m\n' ' |___/\___\__,_|_|\___/|_|  \__,_| '
  printf '\033[0;32m%s\033[0m\n' '                                   '
  printf '\033[0;34m%s\033[0m\n' 'Hooray! The scalora theme has been updated and/or is at the current version.'
  printf '\033[0;34m%s\033[1m%s\033[0m\n' 'To keep up on the latest news and updates, follow us on twitter: ' 'http://twitter.com/mscalora'
else
  printf '\033[0;31m%s\033[0m\n' 'There was an error updating. Try again later?'
fi

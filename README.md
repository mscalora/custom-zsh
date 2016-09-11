##Install as a updatable local repository

###Run these commands (after Oh My Zsh is installed)

    git clone https://github.com/mscalora/custom-zsh.git ~/.oh-my-zsh/custom

### To use the theme, in your .zshrc change your ZSH_THEME and then rerun 

    ZSH_THEME="scalora"

### Updates
* Updates are automatic, they are triggered by updates to oh-my-zsh which you are prompted for from time to time
* Manual updates can be run with the command:
    upgrade_custom

## Fork on github so you can modify but also pull updates from upstream
Assuming you are already using the main repo as described above:

1. Login to github, browse to `https://github.com/mscalora/custom-zsh`
1. Fork the repo, see: https://help.github.com/articles/fork-a-repo/
1. Get your fork repo's URL like https://github.com/cooldude71/custom-zsh.git
1. Swap out your fork in the terminal (assumes standard setup):

    1. `cd ~/.oh-my-zsh/custom`
    1. `git remote rename origin upstream`
    1. `git remote add origin https://github.com/cooldude71/custom-zsh.git`

1. Now your installation will keep up to date with whatever is in your repo

## Install a local copy you can customize [ no support for updating or sharing between installations ]

### with the theme name yadayada, use theme commands:

    mkdir ~/.oh-my-zsh/custom/themes
    curl https://raw.githubusercontent.com/mscalora/custom-zsh/master/themes/scalora.zsh-theme >~/.oh-my-zsh/custom/themes/yadayada.zsh-theme

### and set the ZSH_THEME variable to whatever name you gave it

    ZSH_THEME="yadayada"

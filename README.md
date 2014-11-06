#Install as a updatable local repository

###Run these commands (after Oh My Zsh is installed)

    rm -rd ~/.oh-my-zsh/custom
    git clone https://github.com/mscalora/custom-zsh.git ~/.oh-my-zsh/custom

### To use the theme, change you ZSH_THEME

    ZSH_THEME="scalora"

### To update, run these commands

    cd ~/.oh-my-zsh/custom
    git pull

# Install a copy you can customize

### with the theme name yadayada, use theme commands:

    mkdir <span style="background-color: transparent;">~/.oh-my-zsh/custom/themes
    curl https://raw.githubusercontent.com/mscalora/custom-zsh/master/themes/scalora.zsh-theme >~/.oh-my-zsh/custom/themes/yadayada.zsh-theme

### and set the ZSH_THEME variable to whatever name you gave it

    ZSH_THEME="yadayada"

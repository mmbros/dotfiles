# dotfiles
I miei file di configurazione.

## install base system
```
cd ~/Downloads
wget https://github.com/mmbros/dotfiles/archive/master.zip
unzip master.zip
cd dotfiles-master/install/
./install.sh
```

## ssh

1. creare la cartella `$HOME/.ssh`
2. copiarci le chiavi per accedere a rasperrypi
3. editare il file `config`


## git

1. installare git con `sudo apt-get install git`
2. copiare nella cartella `$HOME` i file `.gitconfig` e `.gitcredential`


## vim

1. installare vim con `sudo apt-get install vim`.
2. copiare nella cartella `$HOME/.vim/autoload` il file `plug.vim`
3. copiare nella cartella `$HOME` il file `.vimrc`
4. eseguire vim ed impartire il comando `PlugInstall` per installare i plugin


## beets (su python3)

1. installa il modulo venv `sudo apt-get install python3-venv`
2. crea e si posizione nella cartella `$HOME/code/py3venv`
3. crea il venv per beets con il comando `python3 -m venv beets`
4. entra nella cartella `beets/bin`
5. installa beets con il comando `./pip3 install beets`
6. installa le librerie aggiuntive con `./pip3 discogs_client`
7. crea un simlink a beet in una delle cartelle incluse nel path:
       sudo ln -s $HOME/code/py3venv/beets/bin/beet beet


## git-crypt

### compilazione di git-crypt

1. apt install build-essential libssl-dev
2. git clone https://github.com/AGWA/git-crypt/
3. cd git-crypt
4. make
5. sudo make install PREFIX=/usr/local

### utilizzo di git-crypt

1. cd repository/with/encrypted/files
2. git-crypt unlock /path/to/key


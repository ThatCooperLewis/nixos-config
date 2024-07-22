#######################################################
# load Square specific zshrc; please don't change this bit.
#######################################################
source ~/Development/config_files/square/zshrc
#######################################################

###########################################
# Feel free to make your own changes below.
###########################################

# uncomment to automatically `bundle exec` common ruby commands
# if [[ -f "$SQUARE_HOME/config_files/square/bundler-exec.sh" ]]; then
#   source $SQUARE_HOME/config_files/square/bundler-exec.sh
# fi

# load the aliases in config_files files (optional)
source ~/Development/config_files/square/aliases

[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
[[ -f "$HOME/.localaliases" ]] && source "$HOME/.localaliases"


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
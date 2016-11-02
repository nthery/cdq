#
# Change Directory Quickly.
# Source this file from ~/.bashrc.
#

# The companion perl script should be in same directory.
cdq_core="$(dirname "$(realpath "$BASH_SOURCE")")/cdq.pl"
[[ -x "$cdq_core" ]] || { echo 1>&2 "cdq.pl not found => cdq not enabled"; return; }

# Execute specified command, e.g. "cd /foo/bar" and on success memorise current
# directory.
# Not intended for direct use.  See aliases below.
cdq_cd() {
	command "$@"
	if (( $? == 0 )); then
		"$cdq_core" add
	fi
}

# Re-route all directory changing commands.
alias cd='cdq_cd cd'
alias pushd='cdq_cd pushd'
alias popd='cdq_cd popd'

# Display all directories memorized so far, most frequently used first, and
# prompt user for directory to jump to.
cdq() {
	# Do selection in subshell because we need to change IFS to deal with
	# paths with embedded spaces.
	local selection=$(
		export IFS=$'\n'
		select p in $("$cdq_core" ls); do
			echo $p
			break
		done
	)
	if [[ -n "$selection" ]]; then
		cdq_cd cd "$selection"
	fi
}

#!/usr/bin/env bash

# Pasos:

# Strings:
# -optstr
# -input

# Preprocess:
# 1. Rearrange things
# 2. Assoc array -> f("option|flag") = number of args

# Process args:
# 1. Loop over input (rearranged arguments)
# 2. At the beginning of each iteration, adjust things inside a function

# TODO 1. Done
# Short and long ways to call options available
# (duplicate options in optstr and use OR regular expression)
#

# TODO 2. Remark
# If you specify some option but it is not in the optstr, it will work (with 0 arguments by default)
# "Fix" -> rearrange function should just ignore those flags
#

# TODO 3. Multiargument? (Allowed 2 parameters)
# Future: next expression counts the number of ":" repeated...
# grep -oE ":+" | awk '{ print $0, length}' | cut -f 2- -d ' '
#

# TODO 4. Syntax differences with getopts, for example '\?' doesn't work now...

# TODO 5. Standard long option. If --option=VALUE -> separate VALUE with sed using the first = symbol

# Note: Do NOT access to OPTARG if the option does not have arguments

echo "### Start rearrangement:"

rearrange() { 
    # Get getopts style option string
    local optstr=$1
	shift
    # Loop through arguments and separate out valid options 
    # and their values from AMPL_EXEC-s
    while (($#)); do
    	# Remove preffix
		if [[ -v num_args[${1#"-"}] ]]; then
			opt=${1#"-"}
			echo "The option $opt exists and is a SHORT option."
		elif [[ -v num_args[${1#"--"}] ]]; then
			opt=${1#"--"}
			echo "The option $opt exists and is a LONG option."
		else
			opt=$1
			echo "The option $opt does NOT exist."
		fi
		
		if [[ -v num_args[$opt] ]]; then
			flags+=("$1")
           	for (( i=0 ; i<${num_args[${opt}]}; ++i ))
           	do
                flags+=("$2")
                shift
          	done
		else
			args+=("$1")
		fi 
        shift
    done

    # Define variable that holds rearranged arguments
    # options and values first then AMPL_EXEC-s
    OPTARR=("${flags[@]}" "${args[@]}")
}


init_num_args() {
    # Get getopts style option string
    local optstr=( "$1" )
    # Loop through arguments and separate out valid options 
    # and their values from AMPL_EXEC-s
    for opt in $optstr; do
        echo $opt
        case $opt in
            *::) num_args[${opt%"::"}]=2
		        echo ".*:: $opt ${opt%"::"}"
                ;;
            *:) num_args[${opt%":"}]=1
		        echo ".*: $opt ${opt%":"}"
                ;;
            *) num_args[$opt]=0
		        echo ".* $opt"
                ;;
        esac
    done
}

optstr="aa: bb: s c:: o u k:"
echo "## Testing with optstr: $optstr"
declare -A num_args
init_num_args "$optstr"

# if [[ -v num_args[$opt] ]]; then
#	echo "The option $opt exists and has ${num_args[${opt}]} arguments"
#else
#	echo "The option $opt "
#fi

rearrange "$optstr" "$@"

echo "### POST REARRANGEMENT:"

echo "Flags: ${flags[@]}"
echo "Args: ${args[@]}"

echo "### Getopts"

prepare_opt() {
	option=${OPTARR[OPTIND]}
	# Remove dashes
	if [[ -v num_args[${option#"-"}] ]]; then
		option=${option#"-"}
	elif [[ -v num_args[${option#"--"}] ]]; then
		option=${option#"--"}
	fi

	# Adjust OPTARG and OPTIND
	OPTARG=${OPTARR[OPTIND+1]}
	OPTARGS=${OPTARR[@]:OPTIND+1:num_args[$option]}

	OPTIND=$(( OPTIND + num_args[$option] + 1 ))
}

# N_ARGS=${#OPTARR[@]}
# number of words inside flags
n_flags=${#flags[@]}

# turn off option processing for arguments
# OPTARR is defined in arrange_args() 
set -- "${OPTARR[@]}"

# optstr="aa: a: bb: s c:: o u"

# Process options
# for loop relies on "first flags" from arrange args function
for (( OPTIND=0; OPTIND<n_flags; ))
do  
	echo "Begin iteration"
	prepare_opt
	echo "Prepared: option $option + argument: $OPTARG + all-arguments: $OPTARGS"
	case "$option" in
		    a|aa)
		        echo "A option!"
		        echo $OPTARG
		        ;;

		    bb)
		        echo "B option!"
		        echo $OPTARG
		        ;;

		    s)
		        echo "S option!"
		        echo $OPTARG
		        ;;

		    c)
		        echo "C option!"
		        echo $OPTARG
		        ;;

		    o)
		        echo "O option!"
		        echo $OPTARG
		        ;;

		    u)
		        echo "U option!"
		        echo $OPTARG
		        ;;

		    k)
		        echo "K option!"
		        echo $OPTARG
		        ;;
		     
		    *)
		        echo "Unknown flag $option. available options: $optstr"
	esac
done

exit 0








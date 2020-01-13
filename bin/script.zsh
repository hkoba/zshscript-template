#!/bin/zsh

#----------------------------------------
# Reset options
# zsh の動作オプションを揃える

emulate -L zsh

# set -eu

# setopt YOUR_FAVORITE_OPTIONS_HERE

setopt extended_glob

#----------------------------------------
# Set variables for application directory
# スクリプトをインストール個所に依存させないための変数を用意

# $0            = ~/bin/mytask
# $realScriptFn = /somewhere/myapp/bin/myscript.zsh
# binDir        = /somewhere/myapp/bin
# appDir        = /somewhere/myapp

realScriptFn=$(readlink -f $0); # macOS/BSD の人はここを変更
binDir=$realScriptFn:h
appDir=$binDir:h

#----------------------------------------
# Read application configuration(using anonymous function block to have local variable)
# 設定は zsh の変数代入で
# なお zsh の source には引数を渡せるので、ここで何かを渡す手もある。

() {
    local fn
    for fn in $*; do
        if [[ -r $fn ]]; then source $fn; fi
    done
} $appDir/config.zenv

#----------------------------------------
# Parse primary options
# オプションの解析

o_dryrun=() o_quiet=() o_xtrace=() o_help=()

zparseopts -D -K \
           n=o_dryrun -dry-run=o_dryrun \
           q=o_quiet -quiet=o_quiet \
           x=o_xtrace \
           h=o_help      -help=o_help

if (($#o_xtrace)); then set -x; fi

#----------------------------------------
# Utility functions
# いつも使う関数をここで。(source しても良い)

function x {
    if (($#o_dryrun || !$#o_quiet)); then
        print -R '#' ${(q-)argv}
    fi
    if (($#o_dryrun)); then
        return;
    fi
    "$@" || exit $?
}

function die { echo 1>&2 $*; exit 1 }

#----------------------------------------
# Define subcommands here
# サブコマンドはここで定義する

function cmd_foo { x print -l 'f o o' "$@" "$fooList[@]" }

function cmd_bar { x mkdir -pv $barList $* }


function cmd_help {
    if ((ARGC)); then
        echo 1>&2 $*
    fi
    cat 1>&2 <<EOF
Usage: ${realScriptFn:t} [-h] [-n] SUBCOMMAND ...
EOF
    exit 1
}

#----------------------------------------
# Finally, dispatch given subcommand (or show help)
# 実際の実行

if (($#o_help)) || ! ((ARGC)); then
    cmd_help "$@"
fi

cmd=$1; shift

if (($+functions[cmd_$cmd])); then
    cmd_$cmd "$@"
else
    cmd_help "No such subcommand: $cmd"
fi

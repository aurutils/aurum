#!/bin/nu
const argv0 = 'aurum'
const version = 'AURUM_VERSION'
#const lib_dir = 'AURUM_LIB_DIR'
const lib_dir = '/usr/lib/aurum'

# Append utilities to PATH
if 'AUR_EXEC_PATH' in $env {

} else {

}

def usage [] {
    $"usage: ($argv0) [-d ARG] [-ufCe] [--] ARGS..."
    exit 2
}

def main [
    --info (-i)
    --search (-s)
    --fetch (-F)
    --view (-w)
    --chdir (-C): string
    --repo: string
    --merge
    --rebase
    --reset
    --ff
    --force (-f)
    --continue (-e)
    --upgrades (-u)
    --ignore: string
    --no-confirm (-n)
    --no-check
    --no-provides
    --no-mirror
    --no-ninja
    --no-dialog
    --fm
    ...package: string
] {
    if ($package | length) == 0 and (not $upgrades) {
        usage
    }

    # Default environment variables
    if (not 'XDG_CONFIG_HOME' in $env) {
        let-env XDG_CONFIG_HOME = $"($env.HOME)/.config"
    }
    if (not 'XDG_DATA_HOME' in $env) {
        let-env XDG_DATA_HOME = $"($env.HOME)/.local/share"
    }
    if (not 'XDG_CACHE_HOME' in $env) {
        let-env XDG_CACHE_HOME = $"($env.HOME)/.cache"
    }
    if ($no_mirror) {
        if (not 'AURDEST' in $env) {
            let-env AURDEST = $"($env.XDG_CACHE_HOME)/aurutils/sync-mirror"
        }
        let-env AUR_FETCH_USE_MIRROR = 1       
    } else {
        if (not 'AURDEST' in $env) {
            let-env AURDEST = $"($env.XDG_CACHE_HOME)/aurutils/sync"
        }
        let-env AUR_FETCH_USE_MIRROR = 0
    }

    # Default arguments
    let fetch_args = []
    let repo_args  = []
    let sync_args  = []
    let build_args = []

    # XXX: *_args are not mutable, append value is not assigned
    if $upgrades   { $sync_args  | append '--upgrades' }
    if $merge      { $fetch_args | append '--merge'    }
    if $rebase     { $fetch_args | append '--rebase'   }
    if $reset      { $fetch_args | append '--reset'    }
    if $ff         { $fetch_args | append '-ff'        }
    if $force      { $build_args | append '-f'         }
    if $no_confirm { $build_args | append '-n'         }
    if $no_check   { $build_args | append '--no-check' }
    
    # Exclusive modes
    if ($search) {
        aur search $package
        exit $env.LAST_EXIT_CODE
    } 
    if ($info) {
        aur search --info $package
        exit $env.LAST_EXIT_CODE
    }
    if ($fetch) and (not $upgrades) {
        aur fetch --recurse $fetch_args $package
        exit $env.LAST_EXIT_CODE
    }

    # Exclusive modes with access to local repository
    let $repo = (do -c {
        aur repo $repo_args --status 
    } | lines | parse '{key}:{value}' | transpose --header-row)

    if ($fetch and $upgrades) {
        # XXX: Both pipeline components are required to exit 0
        ( do -c { aur repo --database $repo.repo --upgrades } | 
          do -c { aur fetch $fetch_args '/dev/stdin' }
        )
        exit 0
    }

    # Retrieve and inspect sources in $env.AURDEST
    # TODO: nushell implementation of aur-sync
    # XXX: $sync_args is shadowed
    let $queue = (with-env { AUR_CONFIRM_PAGER: 0, AUR_PAGER: aurum-view-delta } { 
        aur sync --no-build $sync_args $package --database $repo.repo --root $repo.root
    } | lines)
    
    if ($queue | length) == 0 {
        exit 0  # nothing to do
    } 
    else if ($view) {
        $queue | save -a '/dev/stderr'
        exit 0
    }
    else {
        # TODO: in both cases $ret is the empty string (Ctrl+c as alternative?)
        let $ret = (input -s 'Press Return to continue or Ctrl+d to abort')
    }

    # Begin build process
    # XXX: check if `do -c` aborts entire script
    let $tmp = (do -c { mktemp })
    $queue | save $tmp

    do -c { aurum-build-asroot $build_args -a $tmp -d $repo.repo -r $repo.root -U $env.USER }
    rm --permanent $tmp
}
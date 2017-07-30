#!/bin/csh

git clone git@github.com:HardenedBSD/hardenedBSD-playground.git hardenedbsd-playground.git
if ( $? != 0 ) then
	git clone https://github.com/HardenedBSD/hardenedBSD-playground.git hardenedbsd-playground.git
endif

cd hardenedbsd-playground.git

git remote add drm-next https://github.com/FreeBSDDesktop/freebsd-base-graphics
git fetch drm-next

git remote add hardenedbsd https://github.com/HardenedBSD/hardenedBSD.git
git config --add remote.hardenedbsd.fetch '+refs/notes/*:refs/notes/*'
git fetch hardenedbsd

# HardenedBSD upstream repos
git branch --track {,origin/}freebsd/10-stable/master
git branch --track {,origin/}hardened/10-stable/master
git branch --track {,origin/}freebsd/11-stable/master
git branch --track {,origin/}hardened/11-stable/master
git branch --track {,origin/}freebsd/current/master
git branch --track {,origin/}hardened/current/master

# FreeBSD Base Graphics' drm-next branch
git branch --track fbsdbasegraphics/current/drm-next drm-next/drm-next

# Topic branches
git branch --track {,origin/}hardened/current/drm-next

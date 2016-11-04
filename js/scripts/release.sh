#!/bin/bash
set -e

# variables
UTCDATE=`date -u "+%Y%m%d-%H%M%S"`
PACKAGES=( "parity.js" )
BRANCH=$CI_BUILD_REF_NAME
GIT_JS_PRECOMPILED="https://${GITHUB_JS_PRECOMPILED}:@github.com/ethcore/js-precompiled.git"
GIT_PARITY="https://${GITHUB_JS_PRECOMPILED}:@github.com/ethcore/parity.git"
BASEDIR=`dirname $0`
GITLOG=./.git/gitcommand.log

function setup_git_user {
  git config push.default simple
  git config merge.ours.driver true
  git config user.email "$GITHUB_EMAIL"
  git config user.name "GitLab Build Bot"
}

echo "*** Setting up GitHub config for parity"
setup_git_user
git remote set-url origin $GIT_PARITY

echo "*** Finding JS source changes"
JS_CHANGED=$(git --no-pager diff --name-only $BRANCH $(git merge-base $BRANCH origin/master) | grep \.js | wc -l)

if [ "$JS_CHANGED" == "0" ]; then
  echo "*** No JS changes detected, skipping execution"
  exit 0
else
  echo "*** JS changes detected, continuing execution"
  exit 0
fi

echo "*** Setting up GitHub config for js-precompiled"
cd js/.dist
rm -rf ./.git
git init
setup_git_user

echo "*** Checking out $BRANCH branch"
git remote add origin $GIT_JS_PRECOMPILED
git fetch origin 2>$GITLOG
git checkout -b $BRANCH

echo "*** Committing compiled files for $UTCDATE"
git add .
git commit -m "$UTCDATE"

echo "*** Merging remote"
git merge origin/$BRANCH -X ours --commit -m "$UTCDATE [release]"
git push origin HEAD:refs/heads/$BRANCH 2>$GITLOG
PRECOMPILED_HASH=`git rev-parse HEAD`

echo "*** Resetting parity base"
cd ../..
git reset --hard origin/$BRANCH 2>$GITLOG

if [ "$BRANCH" == "master" ]; then
  cd js
  echo "*** Bumping package.json patch version"
  npm --no-git-tag-version version
  npm version patch

  echo "*** Building packages for npmjs"
  echo "$NPM_TOKEN" >> ~/.npmrc
  npm run ci:build:npm

  echo "*** Publishing $PACKAGE to npmjs"
  cd .npmjs
  npm publish --access public
  cd ../..
fi

echo "*** Updating cargo parity-ui-precompiled#$PRECOMPILED_HASH"
cargo update -p parity-ui-precompiled
# --precise "$PRECOMPILED_HASH"

echo "*** Committing updated files"
git add .
git commit -m "[ci skip] js-precompiled $UTCDATE"
git push origin HEAD:refs/heads/$BRANCH 2>$GITLOG

echo "*** Release completed"
exit 0

#!/bin/sh
#
# First-time setup of git repository for deployment
#
# For more info, see: https://github.com/foodcoops/foodcoops.net/issues/5
#

# check
if [ `whoami` != 'git' -a ! "$FORCE" = 1 ]; then
  echo "This should be run as user 'git'. If you're sure, set FORCE=1." 1>&2
  exit 1
fi

# git repository, push to here
REPO_PATH=$HOME/foodcoops.net.git
# work directory, this is where files are checked out for deployment
WORK_PATH=$HOME/foodcoops.net

# set DO=echo for debugging this script
DO=


# create bare git repository and work directory
mkdir $WORK_PATH
git init --bare $REPO_PATH
GIT_DIR=$REPO_PATH git config advice.detachedHead false

# update hook builds or pulls the docker images
cat >$REPO_PATH/hooks/update <<HOOK
#!/bin/sh

if [ "\$1" != "refs/heads/master" ]; then
  echo "Please push to the master branch only" 1>&2
  exit 1
fi

if [ ! -e $WORK_PATH/.env ]; then
  echo "Please put your configuration in $WORK_PATH/.env" 1>&2
  exit 1
fi

GIT_WORK_TREE=$WORK_PATH git checkout --force \$3 &&
cd $WORK_PATH &&
$DO docker-compose build --pull --force-rm
HOOK
chmod a+x $REPO_PATH/hooks/update

# post-receive hook brings up the images juist built
cat >$REPO_PATH/hooks/post-receive <<HOOK
#!/bin/sh

cd $WORK_PATH &&
$DO docker-compose up -d
HOOK
chmod a+x $REPO_PATH/hooks/post-receive


# template sync
A script to easily update a template based project

## Presentation
This script identifies a commit in the template history which is the closest one to your project. 
Then it squashes all the updates into a commit which will be cherry-picked on the top of your working branch.
Therefore you just have to resolve conflicts and work is done!

## Basic Usage
1. Go to your project repository (we recommend to create a new branch)
Copy template-sync.sh at the root of your project

2. The only mandatory argument is the github or gitlab url of your template. 
E.g. `./template-sync.sh https://github.com/dunglas/symfony-docker`

3. In case some files are renamed or moved in the template history, you can modify the threshold where
git thinks two files are identical. Default value for this script is 20% (git's default value is 50%).
E.g. `./template-sync.sh https://github.com/dunglas/symfony-docker --threshold=30`

4. You can run the script in debug mode by adding the `--debug` flag.

5. When conflicts are resolved, don't forget to run `git cherry-pick --continue`
If for any reason you are not satisfied with the result of the script you just have to run `git cherry-pick --abort`
to rollback before the execution of the script.

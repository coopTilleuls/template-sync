# Template Sync

You started a project from a template repository but the template changed since you started the project?
Template Sync will import the changes made to the template to your project in a blink!

## Getting Started

```console
curl -sSL https://raw.githubusercontent.com/mano-lis/template-sync/main/template-sync.sh | sh -s -- <url-of-the-template>
```
If you have some conflicts, resolve them and run `git cherry-pick --continue`.

## Supported Templates

* [GitHub Templates](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
* [GitLab Templates](https://docs.gitlab.com/ee/user/project/pages/getting_started/pages_new_project_template.html)
* [Symfony Docker](https://github.com/dunglas/symfony-docker)
* [API Platform Distribution](https://github.com/api-platform/api-platform)
* [Next.js starters](https://vercel.com/templates/next.js) (templates in monorepo are not working yet, PR welcome!)

## How it works

This script identifies a commit in the template history which is the closest one to your project.
Then it squashes all the updates into a commit which will be cherry-picked on the top of your working branch.
Therefore you just have to resolve conflicts and work is done!

### Advanced

1. Go to your project repository (we recommend to create a new branch)
Copy template-sync.sh at the root of your project

2. The only mandatory argument is the GitHub or gitlab URL of your template.
E.g. `./template-sync.sh https://github.com/dunglas/symfony-docker`. If you want to synchronize your project with a specific version of the template, you can specify the commit you are targeting by adding `--commit=SHA`.

3. In case some files are renamed or moved in the template history, you can modify the threshold where
git thinks two files are identical. Default value for this script is 20% (git's default value is 50%).
E.g. `./template-sync.sh https://github.com/dunglas/symfony-docker --threshold=30`

4. You can run the script in debug mode by adding the `--debug` flag.

5. If for any reason you are not satisfied with the result of the script you just have to run `git cherry-pick --abort` to rollback before the execution of the script.


*Created by [Emmanuel Barat](https://github.com/mano-lis) and [Raphael Marchese](https://github.com/Raphael-Marchese)*

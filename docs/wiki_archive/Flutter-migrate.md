_This refers to a [project](https://github.com/flutter/packages/tree/main/packages/flutter_migrate) that is incomplete and is not currently maintained._

# Flutter migrate tool

Flutter projects that were created with old versions of flutter tend to slowly become outdated and sometimes do not have access to new flutter features.

The `flutter_migrate` tool is a set of commands that helps you migrate legacy flutter projects to modern flutter project templates. This process will typically update your dependencies, add access to new flutter features, and improve resilience and robustness against future updates.

Flutter migrate works best for small to medium sized projects that are primarily implemented in flutter/dart.

The flutter migrate tool will generate a staging directory where you will be able to preview changes and resolve any conflicts before committing the changes to your project.

## Prepare your project for migration

Before running the migrate tool, your project must be set up as a git repository and have no uncommitted changes. This is to ensure that the migration will always be able to be rolled back if needed. The migrate tool itself also requires git to function.

## Start the migration

To start the migration process, enter the root directory of your flutter project and run:

	$ flutter migrate start

It is normal for this command to take a while to run. A staging directory called `migrate_staging_directory` will be created in your flutter project where the suggested changes are located. The staged files are the migrated and merged versions. For some projects, there may be merge conflicts between flutter-generated code changes and your own changes.

To view the status of your current started migration, run:

	$ flutter migrate status

This will display an overview of the diffs, files changed, added, and deleted, as well as any files with merge conflicts.

## Resolve conflicts

Any merge conflicts must be resolved before applying the migration. The status command will list the discovered conflicts in the staging directory. These conflicts should either be fixed manually in the staging directory by directly modifying the staged files or optionally resolved using the resolve-conflicts wizard if one of the versions should be accepted without changes.

The resolve-conflicts wizard helps process routine merge conflicts quickly. Many projects will find that user changes to files like AndroidManifest.xml will be caught as a conflict. In most cases, it is desired to just keep your manual changes instead of reverting to the default template manifest. The wizard can help quickly resolve these types of conflict. Run the resolve-conflicts wizard with:

	$ flutter migrate resolve-conflicts

The wizard will display each conflict and present the option to accept the new template version, keep the existing version, or skip the conflict and resolve it manually later. After each file, the wizard will ask to commit the changes or not.

## Apply the migration

When all conflicts are resolved and the changes are to your liking, the migration should be applied to the project. The contents of the staging directory will be moved into the project itself, overwriting the existing files. To apply, run:


	$ flutter migrate apply

After applying the migration, all changes can be handled via git commands. It is recommended to now build your app for all your target platforms to ensure the migration was successful. Although the migration tool typically produces working apps, it is possible in complex projects for errors to occur when merging or resolving conflicts. If the project is left in a broken state, it is easy to undo the migration by running:

	$ git reset --hard HEAD

Newly added files can be removed with:

	$ git clean -n (preview untracked files to be cleaned)
	$ git clean -f (delete untracked files)

## Aborting a staged migration

If the staged migration is no longer desired, you can abort the migration by running:

	$ flutter migrate abort

This will delete the staging directory and your project will be left untouched.
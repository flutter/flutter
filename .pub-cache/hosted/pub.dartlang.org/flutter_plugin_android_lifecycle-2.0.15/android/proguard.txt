# The point of this package is to specify that a dependent plugin intends to
# use the AndroidX lifecycle classes. Make sure no R8 heuristics shrink classes
# brought in by the embedding's pom.
#
# This isn't strictly needed since by definition, plugins using Android
# lifecycles should implement DefaultLifecycleObserver and therefore keep it
# from being shrunk. But there seems to be an R8 bug so this needs to stay
# https://issuetracker.google.com/issues/142778206.
-keep class androidx.lifecycle.DefaultLifecycleObserver

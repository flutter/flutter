package com.flutter.gradle

import groovy.lang.Closure
import org.gradle.api.Action
import org.gradle.api.DomainObjectCollection
import org.gradle.api.NamedDomainObjectCollectionSchema
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Namer
import org.gradle.api.Rule
import org.gradle.api.Task
import org.gradle.api.provider.Provider
import org.gradle.api.specs.Spec
import org.gradle.api.tasks.TaskCollection
import org.gradle.api.tasks.TaskContainer
import org.gradle.api.tasks.TaskProvider
import java.util.SortedMap
import java.util.SortedSet

open class TaskContainerMock : TaskContainer {
    override fun findByPath(path: String): Task? = notMocked()

    override fun getByPath(path: String): Task = notMocked()

    @Deprecated("Deprecated in Java")
    override fun create(options: Map<String?, *>): Task = notMocked()

    @Deprecated("Deprecated in Java")
    override fun create(
        options: Map<String?, *>,
        configureClosure: Closure<*>
    ): Task = notMocked()

    @Deprecated("Deprecated in Java")
    override fun create(
        name: String,
        configureClosure: Closure<*>
    ): Task = notMocked()

    @Deprecated("Deprecated in Java")
    override fun create(name: String): Task = notMocked()

    @Deprecated("Deprecated in Java")
    override fun <T : Task?> create(
        name: String,
        type: Class<T?>
    ): T & Any = notMocked()

    @Deprecated("Deprecated in Java")
    override fun <T : Task?> create(
        name: String,
        type: Class<T?>,
        vararg constructorArgs: Any?
    ): T & Any = notMocked()

    @Deprecated("Deprecated in Java")
    override fun <T : Task?> create(
        name: String,
        type: Class<T?>,
        configuration: Action<in T>
    ): T & Any = notMocked()

    @Deprecated("Deprecated in Java")
    override fun create(
        name: String,
        configuration: Action<in Task>
    ): Task = notMocked()

    override fun register(
        name: String,
        configurationAction: Action<in Task>
    ): TaskProvider<Task?> = notMocked()

    override fun <T : Task?> register(
        name: String,
        type: Class<T?>,
        configurationAction: Action<in T>
    ): TaskProvider<T?> = notMocked()

    override fun <T : Task?> register(
        name: String,
        type: Class<T?>
    ): TaskProvider<T?> = notMocked()

    override fun <T : Task?> register(
        name: String,
        type: Class<T?>,
        vararg constructorArgs: Any?
    ): TaskProvider<T?> = notMocked()

    override fun register(name: String): TaskProvider<Task?> = notMocked()

    override fun replace(name: String): Task = notMocked()

    override fun <T : Task?> replace(
        name: String,
        type: Class<T?>
    ): T & Any = notMocked()

    override fun named(nameFilter: Spec<String?>): TaskCollection<Task?> = notMocked()

    override fun matching(spec: Spec<in Task>): TaskCollection<Task?> = notMocked()

    override fun matching(closure: Closure<*>): TaskCollection<Task?> = notMocked()

    override fun getByName(
        name: String,
        configureClosure: Closure<*>
    ): Task = notMocked()

    override fun getByName(name: String): Task = notMocked()

    override fun <S : Task?> withType(type: Class<S?>): TaskCollection<S?> = notMocked()

    override fun whenTaskAdded(action: Action<in Task>): Action<in Task> = notMocked()

    override fun whenTaskAdded(closure: Closure<*>) = notMocked()

    override fun getAt(name: String): Task = notMocked()

    override fun named(name: String): TaskProvider<Task> = notMocked()

    override fun named(
        name: String,
        configurationAction: Action<in Task>
    ): TaskProvider<Task?> = notMocked()

    override fun <S : Task?> named(
        name: String,
        type: Class<S?>
    ): TaskProvider<S?> = notMocked()

    override fun <S : Task?> named(
        name: String,
        type: Class<S?>,
        configurationAction: Action<in S>
    ): TaskProvider<S?> = notMocked()

    override fun add(e: Task): Boolean = notMocked()

    override fun addAll(c: Collection<Task?>): Boolean = notMocked()

    override fun getNamer(): Namer<Task?> = notMocked()

    override fun getAsMap(): SortedMap<String?, Task?> = notMocked()

    override fun getNames(): SortedSet<String?> = notMocked()

    override fun findByName(name: String): Task? = notMocked()

    override fun getByName(
        name: String,
        configureAction: Action<in Task>
    ): Task = notMocked()

    override fun addRule(rule: Rule): Rule = notMocked()

    override fun addRule(
        description: String,
        ruleAction: Closure<*>
    ): Rule = notMocked()

    override fun addRule(
        description: String,
        ruleAction: Action<String?>
    ): Rule = notMocked()

    override fun getRules(): List<Rule?> = notMocked()

    override fun getCollectionSchema(): NamedDomainObjectCollectionSchema = notMocked()

    override fun addLater(provider: Provider<out Task?>) = notMocked()

    override fun addAllLater(provider: Provider<out Iterable<Task?>?>) = notMocked()

    override fun <S : Task?> withType(
        type: Class<S?>,
        configureAction: Action<in S>
    ): DomainObjectCollection<S?> = notMocked()

    override fun <S : Task?> withType(
        type: Class<S?>,
        configureClosure: Closure<*>
    ): DomainObjectCollection<S?> = notMocked()

    override fun whenObjectAdded(action: Action<in Task>): Action<in Task> = notMocked()

    override fun whenObjectAdded(action: Closure<*>) = notMocked()

    override fun whenObjectRemoved(action: Action<in Task>): Action<in Task> = notMocked()

    override fun whenObjectRemoved(action: Closure<*>) = notMocked()

    override fun all(action: Action<in Task>) = notMocked()

    override fun all(action: Closure<*>) = notMocked()

    override fun configureEach(action: Action<in Task>) = notMocked()

    override fun findAll(spec: Closure<*>): Set<Task?> = notMocked()

    override fun clear() = notMocked()

    override fun iterator(): MutableIterator<Task?> = notMocked()

    override fun remove(element: Task?): Boolean = notMocked()

    override fun removeAll(elements: Collection<Task?>): Boolean = notMocked()

    override fun retainAll(elements: Collection<Task?>): Boolean = notMocked()

    override val size: Int
        get() = notMocked()

    override fun contains(element: Task?): Boolean = notMocked()

    override fun containsAll(elements: Collection<Task?>): Boolean = notMocked()

    override fun isEmpty(): Boolean = notMocked()

    override fun <U : Task?> maybeCreate(
        name: String,
        type: Class<U?>
    ): U & Any = notMocked()

    override fun <U : Task?> containerWithType(type: Class<U?>): NamedDomainObjectContainer<U?> = notMocked()

    override fun maybeCreate(name: String): Task = notMocked()

    override fun configure(configureClosure: Closure<*>): NamedDomainObjectContainer<Task?> = notMocked()

    private fun notMocked(): Nothing = TODO("Not yet mocked")
}

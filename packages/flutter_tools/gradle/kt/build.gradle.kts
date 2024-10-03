plugins {
    kotlin("jvm") version "1.9.20"
    `java-gradle-plugin`
}

dependencies {
    implementation("com.android.tools.build:gradle:7.4.0")

    testImplementation(kotlin("test"))
    testImplementation("org.mockito:mockito-core:4.8.0")
}

tasks.test {
    useJUnitPlatform()
}

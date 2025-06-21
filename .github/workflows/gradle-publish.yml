# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.
# This workflow will build a package using Gradle and then publish it to GitHub packages when a release is created
# For more information see: https://github.com/actions/setup-java/blob/main/docs/advanced-usage.md#Publishing-using-gradle

name: Gradle Package

on:
  release:
    types: [created]

jobs:
  build:

    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - uses: actions/checkout@v4
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        server-id: github # Value of the distributionManagement/repository/id field of the pom.xml
        settings-path: ${{ github.workspace }} # location for the settings.xml file

    - name: Setup Gradle
      uses: gradle/actions/setup-gradle@af1da67850ed9a4cedd57bfd976089dd991e2582 # v4.0.0

    - name: Build with Gradle
      run: ./gradlew build

    # The USERNAME and TOKEN need to correspond to the credentials environment variables used in
    # the publishing section of your build.gradle
    - name: Publish to GitHub Packages
      run: ./gradlew publish
      env:
        USERNAME: ${{ github.actor }}
        TOKEN: ${{ secrets.GITHUB_TOKEN }}

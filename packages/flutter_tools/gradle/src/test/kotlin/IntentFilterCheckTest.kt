package com.flutter.gradle

import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class IntentFilterCheckTest {

  @Test
  fun canCreateIntentFilterJson() {
    val intentFilterCheck = IntentFilterCheck()
    intentFilterCheck.hasActionView = true
    intentFilterCheck.hasDefaultCategory = true

    val intentJson = intentFilterCheck.toJson()

    assertTrue(intentJson.containsKey("hasAutoVerify"))
    assertTrue(intentJson.containsKey("hasActionView"))
    assertTrue(intentJson.containsKey("hasDefaultCategory"))
    assertTrue(intentJson.containsKey("hasBrowsableCategory"))

    assertEquals("false", intentJson.getOrDefault(key = "hasAutoVerify", defaultValue = true).toString())
    assertEquals("true", intentJson.getOrDefault(key = "hasActionView", defaultValue = false).toString())
    assertEquals("true", intentJson.getOrDefault(key = "hasDefaultCategory", defaultValue = false).toString())
    assertEquals("false", intentJson.getOrDefault(key = "hasBrowsableCategory", defaultValue = true).toString())
  }
}
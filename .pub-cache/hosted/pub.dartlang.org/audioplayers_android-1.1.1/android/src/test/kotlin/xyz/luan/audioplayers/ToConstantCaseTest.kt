package xyz.luan.audioplayers

import org.junit.jupiter.api.Test
import org.assertj.core.api.Assertions.assertThat

internal class ToConstantCaseTest {
    @Test
    fun `convert from sentence case`() {
        assertThat("foo".toConstantCase()).isEqualTo("FOO")
        assertThat("foo bar".toConstantCase()).isEqualTo("FOO_BAR")
    }

    @Test
    fun `convert from camelCase`() {
        assertThat("foo".toConstantCase()).isEqualTo("FOO")
        assertThat("fooBar".toConstantCase()).isEqualTo("FOO_BAR")
    }
}

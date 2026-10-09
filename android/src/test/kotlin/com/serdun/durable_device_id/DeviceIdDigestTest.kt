package com.serdun.durable_device_id

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

class DeviceIdDigestTest {
    @Test
    fun sameInputGivesTheSameIdentifier() {
        assertEquals(
            DeviceIdDigest.of("com.example.app", "9774d56d682e549c"),
            DeviceIdDigest.of("com.example.app", "9774d56d682e549c"),
        )
    }

    @Test
    fun identifierIsSha256InLowercaseHex() {
        // printf 'com.example.app:9774d56d682e549c' | shasum -a 256
        assertEquals(
            "ebd4941a6ac5611797f4315f08d8988ee2ea816977509681c5696b358626cf11",
            DeviceIdDigest.of("com.example.app", "9774d56d682e549c"),
        )
    }

    @Test
    fun anotherAppOnTheSameDeviceGetsAnotherIdentifier() {
        assertNotEquals(
            DeviceIdDigest.of("com.example.app", "9774d56d682e549c"),
            DeviceIdDigest.of("com.example.brand", "9774d56d682e549c"),
        )
    }

    @Test
    fun anotherDeviceGetsAnotherIdentifier() {
        assertNotEquals(
            DeviceIdDigest.of("com.example.app", "9774d56d682e549c"),
            DeviceIdDigest.of("com.example.app", "0000000000000001"),
        )
    }
}

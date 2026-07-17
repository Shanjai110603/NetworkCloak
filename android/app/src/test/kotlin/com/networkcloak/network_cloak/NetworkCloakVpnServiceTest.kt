package com.networkcloak.network_cloak

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import io.mockk.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class NetworkCloakVpnServiceTest {

    private lateinit var service: NetworkCloakVpnService
    private val mockPrefs: SharedPreferences = mockk(relaxed = true)
    private val mockEditor: SharedPreferences.Editor = mockk(relaxed = true)

    @Before
    fun setup() {
        mockkStatic(Log::class)
        every { Log.i(any<String>(), any<String>()) } returns 0
        every { Log.e(any<String>(), any<String>()) } returns 0
        every { Log.d(any<String>(), any<String>()) } returns 0
        every { Log.w(any<String>(), any<String>()) } returns 0

        mockkObject(NativeEventBus)
        every { NativeEventBus.postProtectionStateChanged(any()) } returns Unit
        every { NativeEventBus.createAlertsChannel(any()) } returns Unit

        every { mockPrefs.edit() } returns mockEditor
        every { mockEditor.putString(any(), any()) } returns mockEditor
        every { mockEditor.putBoolean(any(), any()) } returns mockEditor
        every { mockEditor.apply() } returns Unit

        // Instantiate and spy on the service
        val rawService = NetworkCloakVpnService()
        service = spyk<NetworkCloakVpnService>(rawService, recordPrivateCalls = true)

        // Mock base context / shared preferences delegation
        every { service.getSharedPreferences(any(), any()) } returns mockPrefs
        every { service.startForeground(any(), any()) } returns Unit
        every { service.stopForeground(any<Int>()) } returns Unit
        every { service.stopSelf() } returns Unit

        // Mock internal implementation details to prevent Android framework errors
        every { service["createNotificationChannel"]() } returns Unit
        every { service["configureVpn"]() } returns Unit
        every { service["buildNotification"]() } returns mockk<android.app.Notification>(relaxed = true)
        every { service["packetLoop"]() } returns Unit

        // Inject a mock ParcelFileDescriptor so startVpn can establish a TUN context
        val mockPfd = mockk<android.os.ParcelFileDescriptor>(relaxed = true)
        val field = NetworkCloakVpnService::class.java.getDeclaredField("tunInterface")
        field.isAccessible = true
        field.set(service, mockPfd)

        // Ensure clean state before each test
        service.running.set(false)
        NetworkCloakVpnService.currentMode = NetworkCloakVpnService.VpnMode.OFF
        DnsGuardEngine.detach()
    }

    @After
    fun teardown() {
        unmockkAll()
    }

    @Test
    fun `cold start to QUICK_BLOCK starts service without DnsGuardEngine`() {
        val intent = mockk<Intent>()
        every { intent.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START_QUICK_BLOCK

        val result = service.onStartCommand(intent, 0, 1)

        assertEquals(Service.START_STICKY, result)
        assertTrue(service.running.get())
        assertEquals(NetworkCloakVpnService.VpnMode.QUICK_BLOCK, NetworkCloakVpnService.currentMode)
        assertFalse(DnsGuardEngine.isAttached)
        verify { mockEditor.putString("last_vpn_mode", "QUICK_BLOCK") }
    }

    @Test
    fun `upgrade from QUICK_BLOCK to FULL attaches DnsGuardEngine in-place`() {
        // 1. Start in QUICK_BLOCK
        val intentQB = mockk<Intent>()
        every { intentQB.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START_QUICK_BLOCK
        service.onStartCommand(intentQB, 0, 1)
        assertFalse(DnsGuardEngine.isAttached)

        // 2. Send START intent to upgrade
        val intentFull = mockk<Intent>()
        every { intentFull.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START
        val result = service.onStartCommand(intentFull, 0, 2)

        assertEquals(Service.START_STICKY, result)
        assertTrue(service.running.get())
        assertEquals(NetworkCloakVpnService.VpnMode.FULL, NetworkCloakVpnService.currentMode)
        assertTrue(DnsGuardEngine.isAttached)
        verify { mockEditor.putString("last_vpn_mode", "FULL") }
    }

    @Test
    fun `downgrade from FULL to QUICK_BLOCK detaches DnsGuardEngine in-place`() {
        // 1. Start in FULL
        val intentFull = mockk<Intent>()
        every { intentFull.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START
        service.onStartCommand(intentFull, 0, 1)
        assertTrue(DnsGuardEngine.isAttached)

        // 2. Send QUICK_BLOCK intent to downgrade
        val intentQB = mockk<Intent>()
        every { intentQB.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START_QUICK_BLOCK
        service.onStartCommand(intentQB, 0, 2)

        assertTrue(service.running.get())
        assertEquals(NetworkCloakVpnService.VpnMode.QUICK_BLOCK, NetworkCloakVpnService.currentMode)
        assertFalse(DnsGuardEngine.isAttached)
        verify { mockEditor.putString("last_vpn_mode", "QUICK_BLOCK") }
    }

    @Test
    fun `stop intent stops service and clears engine`() {
        // 1. Start in FULL
        val intentFull = mockk<Intent>()
        every { intentFull.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_START
        service.onStartCommand(intentFull, 0, 1)
        assertTrue(DnsGuardEngine.isAttached)

        // 2. Send STOP intent
        val intentStop = mockk<Intent>()
        every { intentStop.getStringExtra(NetworkCloakVpnService.ACTION_KEY) } returns NetworkCloakVpnService.ACTION_STOP
        val result = service.onStartCommand(intentStop, 0, 2)

        assertEquals(Service.START_NOT_STICKY, result)
        assertFalse(service.running.get())
        assertEquals(NetworkCloakVpnService.VpnMode.OFF, NetworkCloakVpnService.currentMode)
        assertFalse(DnsGuardEngine.isAttached)
        verify { mockEditor.putString("last_vpn_mode", "OFF") }
    }
}
